import '../classifiers/upi_noise_veto_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';
import 'evidence_extractor.dart';

class OneTimePaymentExtractor implements EvidenceExtractor {
  const OneTimePaymentExtractor({
    UpiNoiseVetoClassifier classifier = const UpiNoiseVetoClassifier(),
  }) : _classifier = classifier;

  final UpiNoiseVetoClassifier _classifier;

  @override
  List<SubscriptionEvidence> extract(MessageRecord message) {
    final signal = _classifier.classify(message);
    if (signal == null) {
      return const <SubscriptionEvidence>[];
    }

    return signal.evidenceFragments
        .map(
          (fragment) => _toEvidence(
            message,
            fragment,
            fallbackSummary: signal.summary,
            fallbackAmount: signal.amount,
          ),
        )
        .whereType<SubscriptionEvidence>()
        .toList(growable: false);
  }

  SubscriptionEvidence? _toEvidence(
    MessageRecord message,
    EvidenceFragment fragment,
    {
    required String fallbackSummary,
    required double? fallbackAmount,
  }
  ) {
    SubscriptionEvidenceKind? kind;
    switch (fragment.type) {
      case EvidenceFragmentType.oneTimePaymentNoise:
      case EvidenceFragmentType.ignoreNoise:
        kind = SubscriptionEvidenceKind.upiOneTime;
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
      amount: fragment.amount ?? fallbackAmount,
      senderToken: message.sourceAddress,
      explanation: fragment.note ?? fallbackSummary,
      confidence: fragment.confidence ?? 0.9,
    );
  }
}
