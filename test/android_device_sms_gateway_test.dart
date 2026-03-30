import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/gateways/android_device_sms_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/android_device_sms_gateway');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
      'android device sms gateway is compile-safe and returns deterministic placeholder output when not wired',
      () async {
    final gateway = AndroidDeviceSmsGateway(
      methodChannel: channel,
      clock: () => DateTime(2026, 3, 30, 9, 0),
    );

    final messages = await gateway.readMessages();

    expect(messages, isEmpty);
  });

  test('android device sms gateway requests rolling backfill window by default',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, AndroidDeviceSmsGateway.readMessagesMethod);
      expect(
        call.arguments,
        <String, Object?>{
          'earliestAllowedMillisecondsSinceEpoch':
              DateTime(2024, 9, 28, 9, 0).millisecondsSinceEpoch,
          'maxMessageCount': AndroidDeviceSmsGateway.defaultMaxMessageCount,
        },
      );

      return null;
    });

    final gateway = AndroidDeviceSmsGateway(
      methodChannel: channel,
      clock: () => DateTime(2026, 3, 30, 9, 0),
    );

    final messages = await gateway.readMessages();

    expect(messages, isEmpty);
  });

  test('android device sms gateway maps platform payload into raw sms',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, AndroidDeviceSmsGateway.readMessagesMethod);

      return <Object?>[
        <Object?, Object?>{
          'id': 'android-1',
          'address': 'BANK',
          'body': 'Your Netflix subscription has been renewed for Rs 499.',
          'receivedAtMillisecondsSinceEpoch':
              DateTime(2026, 3, 12, 13, 0).millisecondsSinceEpoch,
        },
      ];
    });

    final gateway = AndroidDeviceSmsGateway(methodChannel: channel);

    final messages = await gateway.readMessagesInWindow(
      earliestAllowed: DateTime(2026, 3, 1),
      maxMessageCount: 10,
    );

    expect(messages, hasLength(1));
    expect(messages.single.id, 'android-1');
    expect(messages.single.address, 'BANK');
    expect(messages.single.body,
        'Your Netflix subscription has been renewed for Rs 499.');
  });

  test('android device sms gateway forwards explicit query window arguments',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, AndroidDeviceSmsGateway.readMessagesMethod);
      expect(
        call.arguments,
        <String, Object?>{
          'sinceMillisecondsSinceEpoch':
              DateTime(2026, 3, 1).millisecondsSinceEpoch,
          'earliestAllowedMillisecondsSinceEpoch':
              DateTime(2025, 10, 1).millisecondsSinceEpoch,
          'maxMessageCount': 900,
        },
      );

      return const <Object?>[];
    });

    final gateway = AndroidDeviceSmsGateway(methodChannel: channel);

    final messages = await gateway.readMessagesInWindow(
      since: DateTime(2026, 3, 1),
      earliestAllowed: DateTime(2025, 10, 1),
      maxMessageCount: 900,
    );

    expect(messages, isEmpty);
  });
}
