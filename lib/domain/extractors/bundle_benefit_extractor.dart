import '../classifiers/telecom_bundle_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../entities/subscription_evidence.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_evidence_kind.dart';
import 'evidence_extractor.dart';

class BundleBenefitExtractor implements EvidenceExtractor {
  const BundleBenefitExtractor({
    TelecomBundleClassifier classifier = const TelecomBundleClassifier(),
  }) : _classifier = classifier;

  final TelecomBundleClassifier _classifier;

  @override
  List<SubscriptionEvidence> extract(MessageRecord message) {
    final signal = _classifier.classify(message);
    if (signal == null) {
      return const <SubscriptionEvidence>[];
    }

    return _fromSignal(message, signal)
        .where((evidence) => evidence.kind == SubscriptionEvidenceKind.bundleBenefit)
        .toList(growable: false);
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
    if (fragment.type != EvidenceFragmentType.bundledBenefit) {
      return null;
    }

    return SubscriptionEvidence(
      messageId: message.id,
      kind: SubscriptionEvidenceKind.bundleBenefit,
      occurredAt: message.receivedAt,
      senderToken: message.sourceAddress,
      explanation: fragment.note ?? signal.summary,
      confidence: fragment.confidence ?? 0.9,
    );
  }
}
