import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/application/use_cases/request_device_sms_access_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  group('Large SMS Inbox Performance', () {
    testWidgets('sync and projection remain responsive with exactly 1000 messages',
        (tester) async {
      final now = DateTime(2026, 3, 24, 10, 0);
      
      // Generate exactly 1000 messages.
      final messages = List.generate(1000, (index) {
        if (index % 100 == 0) {
          return RawDeviceSms(
            id: 'msg-$index',
            address: 'BANK-SMS',
            body: 'Your subscription for Service $index has been renewed for Rs 199.',
            receivedAt: now.subtract(Duration(days: index % 30)),
          );
        }
        return RawDeviceSms(
          id: 'msg-$index',
          address: 'FRIEND',
          body: 'Hey, how are you? Message $index',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );

      final gateway = FakeDeviceSmsGateway(messages);
      
      final runtimeUseCase = LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: gateway,
        clock: () => now,
      );

      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      );

      // Measure execution time
      final stopwatch = Stopwatch()..start();
      await runtimeUseCase.execute();
      stopwatch.stop();
      
      print('Large Inbox Projection (1000 msgs) took: ${stopwatch.elapsedMilliseconds}ms');
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
          reason: 'Projection took too long for 1000 messages');

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: runtimeUseCase,
        syncDeviceSmsUseCase: syncUseCase,
      );

      await tester.pumpAndSettle();
      
      await tester.tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
      await tester.pump();
      // Wait for the minimum duration (600ms) plus some buffer for the sync operation
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      
      expect(find.textContaining('Scan finished.'), findsOneWidget);
    });

    testWidgets('sync and projection remain responsive with 2000+ messages',
        (tester) async {
      final now = DateTime(2026, 3, 24, 10, 0);
      
      // Generate 2000 messages. Most are noise, some are subscriptions.
      final messages = List.generate(2000, (index) {
        if (index % 100 == 0) {
          return RawDeviceSms(
            id: 'msg-$index',
            address: 'BANK-SMS',
            body: 'Your subscription for Service $index has been renewed for Rs 199.',
            receivedAt: now.subtract(Duration(days: index % 30)),
          );
        }
        return RawDeviceSms(
          id: 'msg-$index',
          address: 'FRIEND',
          body: 'Hey, how are you? Message $index',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );

      final gateway = FakeDeviceSmsGateway(messages);
      
      final runtimeUseCase = LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: gateway,
        clock: () => now,
      );

      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      );

      // Measure execution time of the pure logic
      final stopwatch = Stopwatch()..start();
      await runtimeUseCase.execute();
      stopwatch.stop();
      
      print('Large Inbox Projection (2000 msgs) took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Requirement: Should be reasonably fast even in tests (which are slower than release).
      // We expect < 1000ms in a test environment for 2000 messages.
      expect(stopwatch.elapsedMilliseconds, lessThan(2000), 
          reason: 'Projection took too long for 2000 messages');

      // Now verify UI responsiveness
      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: runtimeUseCase,
        syncDeviceSmsUseCase: syncUseCase,
      );

      await tester.pumpAndSettle();
      
      await tester.tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      
      // Ensure sync completes and results are shown
      expect(find.textContaining('Scan finished.'), findsOneWidget);
      expect(find.text('Service 0'), findsWidgets);
      expect(find.text('Service 100'), findsWidgets);
    });

    testWidgets('extreme stress test with 5000+ messages', (tester) async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final messages = List.generate(5000, (index) {
        return RawDeviceSms(
          id: 'msg-$index',
          address: index % 50 == 0 ? 'BANK' : 'OTHER',
          body: index % 50 == 0 
            ? 'Order status for ID $index: Paid Rs 500'
            : 'Spam message $index with random text content to increase size.',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );

      final runtimeUseCase = LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: FakeDeviceSmsGateway(messages),
        clock: () => now,
      );

      final stopwatch = Stopwatch()..start();
      await runtimeUseCase.execute();
      stopwatch.stop();
      
      print('Extreme Inbox Projection (5000 msgs) took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Even with 5000 messages, we want it to be under 5 seconds in test mode.
      expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
          reason: 'Extreme projection took too long for 5000 messages');
    });
  });
}
