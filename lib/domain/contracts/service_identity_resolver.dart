import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../value_objects/service_key.dart';

abstract interface class ServiceIdentityResolver {
  ServiceKey resolve({
    required MessageRecord message,
    required ParsedSignal signal,
  });
}
