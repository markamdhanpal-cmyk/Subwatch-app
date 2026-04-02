import '../../domain/contracts/event_classifier.dart';
import '../../domain/classifiers/hard_prefilter_classifier.dart';
import '../../domain/contracts/service_identity_resolver.dart';
import '../../domain/classifiers/mandate_intent_classifier.dart';
import '../../domain/classifiers/subscription_billed_classifier.dart';
import '../../domain/classifiers/telecom_bundle_classifier.dart';
import '../../domain/classifiers/upi_noise_veto_classifier.dart';
import '../../domain/classifiers/weak_signal_review_classifier.dart';
import '../../domain/classifiers/lifecycle_event_classifier.dart';
import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/evidence_fragment.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/parsed_signal.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/enums/subscription_event_type.dart';
import '../../domain/resolvers/deterministic_service_identity_resolver.dart';

class EventPipelineUseCase {
  EventPipelineUseCase({
    List<EventClassifier>? classifiers,
    ServiceIdentityResolver? serviceIdentityResolver,
    bool includeWeakReviewSignals = false,
  })  : _classifiers = List.unmodifiable(
          classifiers ?? _buildDefaultClassifiers(includeWeakReviewSignals),
        ),
        _serviceIdentityResolver = serviceIdentityResolver ??
            const DeterministicServiceIdentityResolver();

  final List<EventClassifier> _classifiers;
  final ServiceIdentityResolver _serviceIdentityResolver;

  static List<EventClassifier> _buildDefaultClassifiers(
    bool includeWeakReviewSignals,
  ) {
    final classifiers = <EventClassifier>[
      const HardPrefilterClassifier(),
      const SubscriptionBilledClassifier(),
      const UpiNoiseVetoClassifier(),
      const LifecycleEventClassifier(),
      const MandateIntentClassifier(),
      const TelecomBundleClassifier(),
    ];

    if (includeWeakReviewSignals) {
      classifiers.add(const WeakSignalReviewClassifier());
    }

    return classifiers;
  }

  ParsedSignal? classify(MessageRecord message) {
    final signals = <ParsedSignal>[];
    for (final classifier in _classifiers) {
      final signal = classifier.classify(message);
      if (signal != null) {
        signals.add(signal);
      }
    }

    if (signals.isEmpty) {
      return null;
    }
    if (signals.length == 1) {
      return signals.single;
    }

    final prioritizedSignals = signals.toList(growable: false)
      ..sort(
        (left, right) => _priorityForSignal(right).compareTo(
          _priorityForSignal(left),
        ),
      );
    final primary = prioritizedSignals.first;

    final mergedTerms = <String>{
      ...primary.capturedTerms,
      ...signals.expand((signal) => signal.capturedTerms),
    }.toList(growable: false);

    final fragmentKeys = <String>{};
    final mergedFragments = <EvidenceFragment>[];
    for (final signal in signals) {
      for (final fragment in signal.evidenceFragments) {
        final key =
            '${fragment.type.name}|${fragment.classifierId}|${fragment.sourceMessageId}';
        if (fragmentKeys.add(key)) {
          mergedFragments.add(fragment);
        }
      }
    }

    return ParsedSignal(
      classifierId: 'merged_event_pipeline',
      eventType: primary.eventType,
      summary:
          'Merged evidence from ${signals.length} classifiers; primary=${primary.classifierId}.',
      detectedAt: primary.detectedAt ?? message.receivedAt,
      amount: _mergedAmount(signals, primary: primary),
      capturedTerms: mergedTerms,
      evidenceFragments: List.unmodifiable(mergedFragments),
    );
  }

  double? _mergedAmount(
    List<ParsedSignal> signals, {
    required ParsedSignal primary,
  }) {
    if (primary.amount != null) {
      return primary.amount;
    }

    for (final signal in signals) {
      if (signal.amount != null) {
        return signal.amount;
      }
    }

    return null;
  }

  int _priorityForSignal(ParsedSignal signal) {
    switch (signal.eventType) {
      case SubscriptionEventType.subscriptionBilled:
        return 110;
      case SubscriptionEventType.subscriptionCancelled:
        return 100;
      case SubscriptionEventType.bundleActivated:
        return 90;
      case SubscriptionEventType.mandateCreated:
      case SubscriptionEventType.autopaySetup:
        return 80;
      case SubscriptionEventType.mandateExecutedMicro:
        return 70;
      case SubscriptionEventType.unknownReview:
        return 40;
      case SubscriptionEventType.oneTimePayment:
        return 30;
      case SubscriptionEventType.ignore:
        return 20;
    }
  }

  List<SubscriptionEvent> execute(List<MessageRecord> messages) {
    final events = <SubscriptionEvent>[];

    for (final message in messages) {
      final signal = classify(message);
      if (signal == null) {
        continue;
      }

      final merchantResolution = _serviceIdentityResolver.resolveMerchant(
        message: message,
        signal: signal,
      );
      final serviceKey = merchantResolution.resolvedServiceKey;

      events.add(
        SubscriptionEvent(
          id: '${message.id}:${signal.classifierId}:${signal.eventType.name}',
          serviceKey: serviceKey,
          type: signal.eventType,
          occurredAt: signal.detectedAt ?? message.receivedAt,
          sourceMessageId: message.id,
          amount: signal.amount,
          merchantResolution: merchantResolution,
          evidenceFragments: signal.evidenceFragments,
          evidenceTrail: EvidenceTrail(
            messageIds: <String>[message.id],
            notes: <String>[
              signal.summary,
              merchantResolution.traceNote,
              ...signal.capturedTerms,
              ...signal.evidenceFragments.map((fragment) => fragment.traceNote),
              ...signal.evidenceFragments
                  .map((fragment) => fragment.note)
                  .whereType<String>(),
            ],
          ),
        ),
      );
    }

    return List.unmodifiable(events);
  }
}
