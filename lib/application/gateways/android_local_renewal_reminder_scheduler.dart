import 'package:flutter/services.dart';

import '../contracts/local_renewal_reminder_scheduler.dart';
import '../models/local_renewal_reminder_models.dart';

class AndroidLocalRenewalReminderScheduler
    implements LocalRenewalReminderScheduler {
  static const String defaultChannelName =
      'sub_killer/local_renewal_reminder_scheduler';
  static const String scheduleReminderMethod = 'scheduleReminder';
  static const String cancelReminderMethod = 'cancelReminder';

  const AndroidLocalRenewalReminderScheduler({
    MethodChannel methodChannel = const MethodChannel(defaultChannelName),
  }) : _methodChannel = methodChannel;

  final MethodChannel _methodChannel;

  @override
  Future<bool> schedule(LocalRenewalReminderScheduleRequest request) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        scheduleReminderMethod,
        <String, Object?>{
          'serviceKey': request.serviceKey,
          'title': request.title,
          'body': request.body,
          'scheduledAtMillisecondsSinceEpoch':
              request.scheduledAt.millisecondsSinceEpoch,
        },
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> cancel(String serviceKey) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        cancelReminderMethod,
        <String, Object?>{
          'serviceKey': serviceKey,
        },
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
