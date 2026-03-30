import '../entities/merchant_resolution.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../value_objects/service_key.dart';

abstract interface class ServiceIdentityResolver {
  MerchantResolution resolveMerchant({
    required MessageRecord message,
    required ParsedSignal signal,
  });

  ServiceKey resolve({
    required MessageRecord message,
    required ParsedSignal signal,
  });
}
