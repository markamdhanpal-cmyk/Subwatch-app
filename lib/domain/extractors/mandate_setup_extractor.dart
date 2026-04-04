import '../classifiers/mandate_intent_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';
import 'evidence_extractor.dart';

class MandateSetupExtractor implements EvidenceExtractor {
  const MandateSetupExtractor({
    MandateIntentClassifier classifier = const MandateIntentClassifier(),
  }) : _classifier = classifier;

  final MandateIntentClassifier _classifier;

  @override
  List<SubscriptionEvidence> extract(MessageRecord message) {
    final signal = _classifier.classify(message);
    if (signal == null) {
      return const <SubscriptionEvidence>[];
    }

    return _fromSignal(
      message,
      evidenceFragments: signal.evidenceFragments,
      fallbackSummary: signal.summary,
      fallbackAmount: signal.amount,
    )
        .where(
          (evidence) =>
              evidence.kind == SubscriptionEvidenceKind.mandateSetup ||
              evidence.kind == SubscriptionEvidenceKind.microVerification,
        )
        .toList(growable: false);
  }

  List<SubscriptionEvidence> _fromSignal(
    MessageRecord message,
    {
    required List<EvidenceFragment> evidenceFragments,
    required String fallbackSummary,
    required double? fallbackAmount,
  }
  ) {
    return evidenceFragments
        .map(
          (fragment) => _toEvidence(
            message,
            fragment,
            fallbackSummary: fallbackSummary,
            fallbackAmount: fallbackAmount,
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
      case EvidenceFragmentType.mandateCreated:
      case EvidenceFragmentType.autopaySetup:
        kind = SubscriptionEvidenceKind.mandateSetup;
        break;
      case EvidenceFragmentType.microCharge:
        kind = SubscriptionEvidenceKind.microVerification;
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
      confidence: fragment.confidence ?? 0.85,
    );
  }
}
