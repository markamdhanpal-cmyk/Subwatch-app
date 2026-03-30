import '../../../domain/entities/message_record.dart';
import '../models/normalized_input_record.dart';

class NormalizedInputMessageRecordBridge {
  const NormalizedInputMessageRecordBridge();

  MessageRecord toMessageRecord(NormalizedInputRecord input) {
    return MessageRecord(
      id: input.canonicalId,
      sourceAddress: input.senderHandle ?? input.origin.sourceLabel,
      body: input.normalizedText,
      receivedAt: input.receivedAt,
    );
  }

  List<MessageRecord> toMessageRecords(
    Iterable<NormalizedInputRecord> inputs,
  ) {
    return List<MessageRecord>.unmodifiable(
      inputs.map(toMessageRecord),
    );
  }
}
