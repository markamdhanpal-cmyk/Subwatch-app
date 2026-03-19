import '../contracts/device_sms_gateway.dart';
import '../models/raw_device_sms.dart';
import '../../domain/contracts/local_message_source.dart';
import '../../domain/entities/message_record.dart';

class DeviceLocalSmsMessageSource implements LocalMessageSource {
  DeviceLocalSmsMessageSource({
    required DeviceSmsGateway gateway,
  }) : _gateway = gateway;

  final DeviceSmsGateway _gateway;

  @override
  Future<List<MessageRecord>> loadMessages() async {
    final rawMessages = await _gateway.readMessages();

    return List<MessageRecord>.unmodifiable(
      rawMessages.map(_mapToMessageRecord),
    );
  }

  MessageRecord _mapToMessageRecord(RawDeviceSms message) {
    return MessageRecord(
      id: message.id,
      sourceAddress: message.address,
      body: message.body,
      receivedAt: message.receivedAt,
    );
  }
}

class StubDeviceSmsGateway implements DeviceSmsGateway {
  const StubDeviceSmsGateway();

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    return const <RawDeviceSms>[];
  }
}
