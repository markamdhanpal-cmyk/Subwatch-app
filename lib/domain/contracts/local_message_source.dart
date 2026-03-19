import '../entities/message_record.dart';

abstract interface class LocalMessageSource {
  Future<List<MessageRecord>> loadMessages();
}
