import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/gateways/android_local_renewal_reminder_scheduler.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    AndroidLocalRenewalReminderScheduler.defaultChannelName,
  );

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('scheduler sends schedule payload over the reminder method channel',
      () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      capturedCall = call;
      return true;
    });

    const scheduler = AndroidLocalRenewalReminderScheduler();
    final scheduled = await scheduler.schedule(
      LocalRenewalReminderScheduleRequest(
        serviceKey: 'NETFLIX',
        title: 'Netflix renewal coming up',
        body: 'Netflix renews on 20 Mar 2026.',
        scheduledAt: DateTime(2026, 3, 17, 9),
      ),
    );

    expect(scheduled, isTrue);
    expect(
      capturedCall?.method,
      AndroidLocalRenewalReminderScheduler.scheduleReminderMethod,
    );
    expect(capturedCall?.arguments, <String, Object?>{
      'serviceKey': 'NETFLIX',
      'title': 'Netflix renewal coming up',
      'body': 'Netflix renews on 20 Mar 2026.',
      'scheduledAtMillisecondsSinceEpoch':
          DateTime(2026, 3, 17, 9).millisecondsSinceEpoch,
    });
  });

  test('scheduler sends cancel payload over the reminder method channel',
      () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      capturedCall = call;
      return true;
    });

    const scheduler = AndroidLocalRenewalReminderScheduler();
    final cancelled = await scheduler.cancel('NETFLIX');

    expect(cancelled, isTrue);
    expect(
      capturedCall?.method,
      AndroidLocalRenewalReminderScheduler.cancelReminderMethod,
    );
    expect(capturedCall?.arguments, <String, Object?>{
      'serviceKey': 'NETFLIX',
    });
  });
}
