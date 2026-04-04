import '../classifiers/lifecycle_event_classifier.dart';
import '../classifiers/weak_signal_review_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
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
    final evidences = <SubscriptionEvidence>[];
    final lifecycleSignal = _lifecycleClassifier.classify(message);
    if (lifecycleSignal != null) {
      evidences.addAll(
        lifecycleSignal.evidenceFragments
            .map(
              (fragment) => _toEvidence(
                message,
                fragment,
                fallbackSummary: lifecycleSignal.summary,
              ),
            )
            .whereType<SubscriptionEvidence>(),
      );
    }

    final weakSignal = _weakSignalClassifier.classify(message);
    if (weakSignal != null) {
      evidences.addAll(
        weakSignal.evidenceFragments
            .map(
              (fragment) => _toEvidence(
                message,
                fragment,
                fallbackSummary: weakSignal.summary,
              ),
            )
            .whereType<SubscriptionEvidence>(),
      );
    }

    return evidences;
  }

  SubscriptionEvidence? _toEvidence(
    MessageRecord message,
    EvidenceFragment fragment,
    {
    required String fallbackSummary,
  }
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
          : (fragment.note ?? fallbackSummary),
      confidence: fragment.confidence ?? 0.75,
    );
  }
}
