import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';

/// Legacy parsed-signal classifier contract.
///
/// Live runtime truth is produced by the evidence-first v3 ingestion path.
@Deprecated(
  'Compatibility-only contract. Prefer evidence extractors and '
  'SubscriptionEvidence in the v3 runtime.',
)
abstract interface class EventClassifier {
  ParsedSignal? classify(MessageRecord message);
}
