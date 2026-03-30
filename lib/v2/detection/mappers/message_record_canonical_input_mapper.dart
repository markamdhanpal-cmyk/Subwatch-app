import '../../../domain/entities/message_record.dart';
import '../models/canonical_input.dart';

class MessageRecordCanonicalInputMapper {
  const MessageRecordCanonicalInputMapper();

  CanonicalInput map(
    MessageRecord message, {
    required CanonicalInputOrigin origin,
    CanonicalInputKind kind = CanonicalInputKind.sms,
  }) {
    return CanonicalInput(
      id: message.id,
      kind: kind,
      origin: origin,
      receivedAt: message.receivedAt,
      senderHandle: message.sourceAddress,
      textBody: message.body,
    );
  }
}
