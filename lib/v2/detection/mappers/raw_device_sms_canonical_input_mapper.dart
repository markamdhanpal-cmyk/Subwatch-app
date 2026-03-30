import '../../../application/models/raw_device_sms.dart';
import '../models/canonical_input.dart';

class RawDeviceSmsCanonicalInputMapper {
  const RawDeviceSmsCanonicalInputMapper();

  CanonicalInput map(RawDeviceSms message) {
    return CanonicalInput.deviceSms(
      id: message.id,
      senderHandle: message.address,
      textBody: message.body,
      receivedAt: message.receivedAt,
    );
  }
}
