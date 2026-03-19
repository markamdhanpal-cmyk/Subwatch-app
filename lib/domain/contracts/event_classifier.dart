import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';

abstract interface class EventClassifier {
  ParsedSignal? classify(MessageRecord message);
}
