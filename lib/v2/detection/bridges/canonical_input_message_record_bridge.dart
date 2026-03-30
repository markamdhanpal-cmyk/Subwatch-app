import '../../../domain/entities/message_record.dart';
import '../models/canonical_input.dart';

class CanonicalInputMessageRecordBridge {
  const CanonicalInputMessageRecordBridge();

  MessageRecord toMessageRecord(CanonicalInput input) {
    return MessageRecord(
      id: input.id,
      sourceAddress: input.senderHandle ?? input.origin.sourceLabel,
      body: input.textBody,
      receivedAt: input.receivedAt,
    );
  }

  List<MessageRecord> toMessageRecords(Iterable<CanonicalInput> inputs) {
    return List<MessageRecord>.unmodifiable(
      inputs.map(toMessageRecord),
    );
  }
}
