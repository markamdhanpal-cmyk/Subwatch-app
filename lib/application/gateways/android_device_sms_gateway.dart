import 'package:flutter/services.dart';

import '../contracts/device_sms_gateway.dart';
import '../models/raw_device_sms.dart';

class AndroidDeviceSmsGateway implements DeviceSmsGateway {
  static const String defaultChannelName = 'sub_killer/device_sms_gateway';
  static const String readMessagesMethod = 'readMessages';
  static const Duration defaultBackfillDuration = Duration(days: 548);
  static const int defaultMaxMessageCount = 5000;

  const AndroidDeviceSmsGateway({
    MethodChannel methodChannel = const MethodChannel(defaultChannelName),
    DateTime Function()? clock,
  })  : _methodChannel = methodChannel,
        _clock = clock ?? DateTime.now;

  final MethodChannel _methodChannel;
  final DateTime Function() _clock;

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    return readMessagesInWindow(
      earliestAllowed: _clock().subtract(defaultBackfillDuration),
      maxMessageCount: defaultMaxMessageCount,
    );
  }

  Future<List<RawDeviceSms>> readMessagesInWindow({
    DateTime? since,
    DateTime? earliestAllowed,
    int? maxMessageCount,
  }) async {
    try {
      final payload = await _methodChannel.invokeMethod<List<Object?>>(
        readMessagesMethod,
        <String, Object?>{
          if (since != null)
            'sinceMillisecondsSinceEpoch': since.millisecondsSinceEpoch,
          if (earliestAllowed != null)
            'earliestAllowedMillisecondsSinceEpoch':
                earliestAllowed.millisecondsSinceEpoch,
          if (maxMessageCount != null) 'maxMessageCount': maxMessageCount,
        },
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
