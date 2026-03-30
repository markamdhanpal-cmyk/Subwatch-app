import 'evidence_fragment.dart';
import '../enums/subscription_event_type.dart';

class ParsedSignal {
  ParsedSignal({
    required this.classifierId,
    required this.eventType,
    required this.summary,
    DateTime? detectedAt,
    this.amount,
    List<String> capturedTerms = const <String>[],
    List<EvidenceFragment> evidenceFragments = const <EvidenceFragment>[],
  })  : detectedAt = detectedAt,
        capturedTerms = List.unmodifiable(capturedTerms),
        evidenceFragments = List<EvidenceFragment>.unmodifiable(
          evidenceFragments,
        );

  final String classifierId;
  final SubscriptionEventType eventType;
  final String summary;
  final DateTime? detectedAt;
  final double? amount;
  final List<String> capturedTerms;
  final List<EvidenceFragment> evidenceFragments;
}
