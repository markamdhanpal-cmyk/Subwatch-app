import '../models/raw_device_sms.dart';

abstract interface class DeviceSmsGateway {
  Future<List<RawDeviceSms>> readMessages();
}
