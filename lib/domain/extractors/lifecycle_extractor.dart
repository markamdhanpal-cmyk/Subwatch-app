import '../classifiers/lifecycle_event_classifier.dart';
import '../classifiers/weak_signal_review_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';
import 'evidence_extractor.dart';

class LifecycleExtractor implements EvidenceExtractor {
  const LifecycleExtractor({
    LifecycleEventClassifier lifecycleClassifier =
        const LifecycleEventClassifier(),
    WeakSignalReviewClassifier weakSignalClassifier =
        const WeakSignalReviewClassifier(),
  })  : _lifecycleClassifier = lifecycleClassifier,
        _weakSignalClassifier = weakSignalClassifier;

  final LifecycleEventClassifier _lifecycleClassifier;
  final WeakSignalReviewClassifier _weakSignalClassifier;

  @override
  List<SubscriptionEvidence> extract(MessageRecord message) {
    final signals = <ParsedSignal>[
      if (_lifecycleClassifier.classify(message) case final lifecycle?)
        lifecycle,
      if (_weakSignalClassifier.classify(message) case final weak?)
        weak,
    ];

    if (signals.isEmpty) {
      return const <SubscriptionEvidence>[];
    }

    final evidences = <SubscriptionEvidence>[];
    for (final signal in signals) {
      evidences.addAll(
        signal.evidenceFragments
            .map((fragment) => _toEvidence(message, fragment, signal))
            .whereType<SubscriptionEvidence>(),
      );
    }

    return evidences;
  }

  SubscriptionEvidence? _toEvidence(
    MessageRecord message,
    EvidenceFragment fragment,
    ParsedSignal signal,
  ) {
    SubscriptionEvidenceKind? kind;
    switch (fragment.type) {
      case EvidenceFragmentType.renewalHint:
        kind = SubscriptionEvidenceKind.renewalHint;
        break;
      case EvidenceFragmentType.cancellationHint:
      case EvidenceFragmentType.endedLifecycle:
        kind = SubscriptionEvidenceKind.cancellationHint;
        break;
      default:
        kind = null;
        break;
    }

    if (kind == null) {
      return null;
    }

    return SubscriptionEvidence(
      messageId: message.id,
      kind: kind,
      occurredAt: message.receivedAt,
      senderToken: message.sourceAddress,
      explanation: fragment.type == EvidenceFragmentType.endedLifecycle
          ? 'ended_lifecycle'
          : (fragment.note ?? signal.summary),
      confidence: fragment.confidence ?? 0.75,
    );
  }
}
