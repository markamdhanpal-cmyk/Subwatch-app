import '../../domain/knowledge/merchant_knowledge_base.dart';
import '../contracts/device_sms_gateway.dart';
import '../models/raw_device_sms.dart';
import '../../domain/contracts/local_message_source.dart';
import '../../domain/entities/message_record.dart';
import '../../v2/detection/bridges/canonical_input_message_record_bridge.dart';
import '../../v2/detection/contracts/canonical_input_source.dart';
import '../../v2/detection/mappers/raw_device_sms_canonical_input_mapper.dart';
import '../../v2/detection/models/canonical_input.dart';

class DeviceLocalSmsMessageSource
    implements LocalMessageSource, CanonicalInputSource {
  DeviceLocalSmsMessageSource({
    required DeviceSmsGateway gateway,
    RawDeviceSmsCanonicalInputMapper? canonicalInputMapper,
    CanonicalInputMessageRecordBridge? messageRecordBridge,
  })  : _gateway = gateway,
        _canonicalInputMapper =
            canonicalInputMapper ?? const RawDeviceSmsCanonicalInputMapper(),
        _messageRecordBridge =
            messageRecordBridge ?? const CanonicalInputMessageRecordBridge();

  final DeviceSmsGateway _gateway;
  final RawDeviceSmsCanonicalInputMapper _canonicalInputMapper;
  final CanonicalInputMessageRecordBridge _messageRecordBridge;

  @override
  Future<List<MessageRecord>> loadMessages() async {
    final canonicalInputs = await loadCanonicalInputs();
    return _messageRecordBridge.toMessageRecords(canonicalInputs);
  }

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final rawMessages = await _gateway.readMessages();

    final validMessages = rawMessages.where((msg) {
      if (msg.body.trim().isEmpty) {
        return false;
      }

      final senderLower = msg.address.toLowerCase();
      if (senderLower.endsWith('.rcs.google.com') ||
          senderLower.contains('@bot.rcs.google.com')) {
        return false;
      }

      final senderToken = MerchantKnowledgeBase.extractSenderToken(msg.address);
      for (final prefix in MerchantKnowledgeBase.suppressedSenderPrefixes) {
        if (senderToken == prefix.toUpperCase()) {
          return false;
        }
      }

      return true;
    });

    return List<CanonicalInput>.unmodifiable(
      validMessages.map(_canonicalInputMapper.map),
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
