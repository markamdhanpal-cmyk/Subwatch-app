import '../entities/message_record.dart';
import '../entities/subscription_evidence.dart';

abstract interface class EvidenceExtractor {
  List<SubscriptionEvidence> extract(MessageRecord message);
}
