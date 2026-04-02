import '../classifiers/hard_prefilter_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';

class MessagePrefilterResult {
  const MessagePrefilterResult({
    required this.isHardNoise,
    required this.evidences,
  });

  final bool isHardNoise;
  final List<SubscriptionEvidence> evidences;
}

class MessagePrefilter {
  const MessagePrefilter({
    HardPrefilterClassifier classifier = const HardPrefilterClassifier(),
  }) : _classifier = classifier;

  final HardPrefilterClassifier _classifier;

  MessagePrefilterResult inspect(MessageRecord message) {
    final signal = _classifier.classify(message);
    if (signal == null) {
      return const MessagePrefilterResult(
        isHardNoise: false,
        evidences: <SubscriptionEvidence>[],
      );
    }

    final evidences = signal.evidenceFragments
        .map((fragment) => _toEvidence(message, fragment))
        .whereType<SubscriptionEvidence>()
        .toList(growable: false);

    if (evidences.isEmpty) {
      return const MessagePrefilterResult(
        isHardNoise: false,
        evidences: <SubscriptionEvidence>[],
      );
    }

    return MessagePrefilterResult(
      isHardNoise: true,
      evidences: evidences,
    );
  }

  SubscriptionEvidence? _toEvidence(
    MessageRecord message,
    EvidenceFragment fragment,
  ) {
    SubscriptionEvidenceKind? kind;
    switch (fragment.type) {
      case EvidenceFragmentType.otpNoise:
        kind = SubscriptionEvidenceKind.otpNoise;
        break;
      case EvidenceFragmentType.telecomRechargeNoise:
        kind = SubscriptionEvidenceKind.telecomRechargeNoise;
        break;
      case EvidenceFragmentType.promoOnly:
      case EvidenceFragmentType.ignoreNoise:
        kind = SubscriptionEvidenceKind.promoNoise;
        break;
      case EvidenceFragmentType.oneTimePaymentNoise:
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
      amount: fragment.amount,
      senderToken: message.sourceAddress,
      explanation: fragment.note ?? fragment.traceNote,
      confidence: fragment.confidence ?? 0.95,
    );
  }
}
