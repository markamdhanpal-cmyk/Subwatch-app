import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/providers/android_local_message_source_capability_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/android_local_message_source_capability');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
      'android capability provider is compile-safe and returns deterministic placeholder state when not wired',
      () async {
    final provider = AndroidLocalMessageSourceCapabilityProvider(
      methodChannel: channel,
    );

    final accessState = await provider.getAccessState();

    expect(accessState, LocalMessageSourceAccessState.deviceLocalUnavailable);
  });

  test('android capability provider maps platform state into access state',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(
        call.method,
        AndroidLocalMessageSourceCapabilityProvider.getAccessStateMethod,
      );

      return 'deviceLocalAvailable';
    });

    final provider = AndroidLocalMessageSourceCapabilityProvider(
      methodChannel: channel,
    );

    final accessState = await provider.getAccessState();

    expect(accessState, LocalMessageSourceAccessState.deviceLocalAvailable);
  });

  test('android capability provider maps requestAccess into request result',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(
        call.method,
        AndroidLocalMessageSourceCapabilityProvider.requestAccessMethod,
      );

      return 'granted';
    });

    final provider = AndroidLocalMessageSourceCapabilityProvider(
      methodChannel: channel,
    );

    final result = await provider.requestAccess();

    expect(result, LocalMessageSourceAccessRequestResult.granted);
  });
}
