import '../../domain/contracts/event_classifier.dart';
import '../../domain/contracts/service_identity_resolver.dart';
import '../../domain/classifiers/mandate_intent_classifier.dart';
import '../../domain/classifiers/subscription_billed_classifier.dart';
import '../../domain/classifiers/telecom_bundle_classifier.dart';
import '../../domain/classifiers/upi_noise_veto_classifier.dart';
import '../../domain/classifiers/weak_signal_review_classifier.dart';
import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/parsed_signal.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/resolvers/deterministic_service_identity_resolver.dart';

class EventPipelineUseCase {
  EventPipelineUseCase({
    List<EventClassifier>? classifiers,
    ServiceIdentityResolver? serviceIdentityResolver,
  })  : _classifiers = List.unmodifiable(
          classifiers ??
              const <EventClassifier>[
                UpiNoiseVetoClassifier(),
                MandateIntentClassifier(),
                TelecomBundleClassifier(),
                SubscriptionBilledClassifier(),
                WeakSignalReviewClassifier(),
              ],
        ),
        _serviceIdentityResolver =
            serviceIdentityResolver ?? const DeterministicServiceIdentityResolver();

  final List<EventClassifier> _classifiers;
  final ServiceIdentityResolver _serviceIdentityResolver;

  ParsedSignal? classify(MessageRecord message) {
    for (final classifier in _classifiers) {
      final signal = classifier.classify(message);
      if (signal != null) {
        return signal;
      }
    }

    return null;
  }

  List<SubscriptionEvent> execute(List<MessageRecord> messages) {
    final events = <SubscriptionEvent>[];

    for (final message in messages) {
      final signal = classify(message);
      if (signal == null) {
        continue;
      }

      final serviceKey = _serviceIdentityResolver.resolve(
        message: message,
        signal: signal,
      );

      events.add(
        SubscriptionEvent(
          id: '${message.id}:${signal.classifierId}:${signal.eventType.name}',
          serviceKey: serviceKey,
          type: signal.eventType,
          occurredAt: signal.detectedAt ?? message.receivedAt,
          sourceMessageId: message.id,
          amount: signal.amount,
          evidenceTrail: EvidenceTrail(
            messageIds: <String>[message.id],
            notes: <String>[signal.summary, ...signal.capturedTerms],
          ),
        ),
      );
    }

    return List.unmodifiable(events);
  }
}
