import 'package:flutter/services.dart';

import '../contracts/problem_report_launcher.dart';

class AndroidProblemReportLauncher implements ProblemReportLauncher {
  const AndroidProblemReportLauncher({
    MethodChannel methodChannel = const MethodChannel(defaultChannelName),
  }) : _methodChannel = methodChannel;

  static const String defaultChannelName = 'sub_killer/problem_report_launcher';
  static const String openProblemReportMethod = 'openProblemReport';

  final MethodChannel _methodChannel;

  @override
  Future<bool> open({
    required String recipient,
    required String subject,
    required String body,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        openProblemReportMethod,
        <String, Object?>{
          'recipient': recipient,
          'subject': subject,
          'body': body,
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
