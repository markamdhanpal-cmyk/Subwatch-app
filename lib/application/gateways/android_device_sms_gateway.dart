import 'package:flutter/services.dart';

import '../contracts/device_sms_gateway.dart';
import '../models/raw_device_sms.dart';

class AndroidDeviceSmsGateway implements DeviceSmsGateway {
  static const String defaultChannelName = 'sub_killer/device_sms_gateway';
  static const String readMessagesMethod = 'readMessages';

  const AndroidDeviceSmsGateway({
    MethodChannel methodChannel = const MethodChannel(defaultChannelName),
  }) : _methodChannel = methodChannel;

  final MethodChannel _methodChannel;

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    try {
      final payload = await _methodChannel.invokeMethod<List<Object?>>(
        readMessagesMethod,
      );

      if (payload == null) {
        return const <RawDeviceSms>[];
      }

      return List<RawDeviceSms>.unmodifiable(
        payload.whereType<Map<Object?, Object?>>().map(_mapRawMessage),
      );
    } on MissingPluginException {
      return const <RawDeviceSms>[];
    } on PlatformException {
      return const <RawDeviceSms>[];
    }
  }

  RawDeviceSms _mapRawMessage(Map<Object?, Object?> rawMessage) {
    final receivedAtMilliseconds =
        rawMessage['receivedAtMillisecondsSinceEpoch'] as int? ?? 0;

    return RawDeviceSms(
      id: rawMessage['id'] as String? ?? '',
      address: rawMessage['address'] as String? ?? '',
      body: rawMessage['body'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtMilliseconds),
    );
  }
}
