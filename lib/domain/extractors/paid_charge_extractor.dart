import '../classifiers/subscription_billed_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';
import 'evidence_extractor.dart';

class PaidChargeExtractor implements EvidenceExtractor {
  const PaidChargeExtractor({
    SubscriptionBilledClassifier classifier = const SubscriptionBilledClassifier(),
  }) : _classifier = classifier;

  final SubscriptionBilledClassifier _classifier;

  @override
  List<SubscriptionEvidence> extract(MessageRecord message) {
    final signal = _classifier.classify(message);
    if (signal == null) {
      return const <SubscriptionEvidence>[];
    }

    final evidences = _fromSignal(message, signal)
        .where((evidence) => evidence.kind == SubscriptionEvidenceKind.paidCharge)
        .toList(growable: false);
    return evidences;
  }

  List<SubscriptionEvidence> _fromSignal(
    MessageRecord message,
    ParsedSignal signal,
  ) {
    return signal.evidenceFragments
        .map((fragment) => _toEvidence(message, fragment, signal))
        .whereType<SubscriptionEvidence>()
        .toList(growable: false);
  }

  SubscriptionEvidence? _toEvidence(
    MessageRecord message,
    EvidenceFragment fragment,
    ParsedSignal signal,
  ) {
    SubscriptionEvidenceKind? kind;
    switch (fragment.type) {
      case EvidenceFragmentType.billedSuccess:
        kind = SubscriptionEvidenceKind.paidCharge;
        break;
      case EvidenceFragmentType.renewalHint:
        kind = SubscriptionEvidenceKind.renewalHint;
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
      amount: fragment.amount ?? signal.amount,
      senderToken: message.sourceAddress,
      explanation: fragment.note ?? signal.summary,
      confidence: fragment.confidence ?? 0.9,
    );
  }
}
