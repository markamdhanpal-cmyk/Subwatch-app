import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/request_device_sms_access_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
      'first-run sync shows onboarding before requesting SMS access and completes a granted flow',
      (
    tester,
  ) async {
    final onboardingUseCases = buildMemorySmsOnboardingUseCases();
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.sampleDemo,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
        clock: () => DateTime(2026, 3, 13, 13, 0),
      ).execute(),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        clock: () => DateTime(2026, 3, 13, 9, 0),
      ),
      syncDeviceSmsUseCase: syncUseCase,
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      findsOneWidget,
    );
    expect(find.text('Find recurring payments from your SMS'), findsOneWidget);
    expect(provider.requestCount, 0);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-next-action'),
      ),
    );
    expect(find.text('Everything stays on your phone'), findsOneWidget);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-next-action'),
      ),
    );
    expect(find.text('Trust-first by default'), findsOneWidget);
    expect(
      find.text(
        'It will not catch every subscription perfectly on the first pass.',
      ),
      findsOneWidget,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-continue-action'),
      ),
    );
    await _pumpPastSyncFeedback(tester);

    expect(provider.requestCount, 1);
    expect(
        find.text('Finished checking SMS. Results updated.'), findsOneWidget);
    expect(find.text('From your messages'), findsWidgets);
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets('sync shows a clear in-progress checking state', (tester) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final pendingSnapshot = Completer<RuntimeDashboardSnapshot>();
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => pendingSnapshot.future,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
    await tester.pump();

    expect(find.text('Checking device SMS'), findsOneWidget);
    expect(find.text('Checking SMS...'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sync-progress-indicator')),
      findsOneWidget,
    );
    expect(find.text('Scanning messages on this phone'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('sync-progress-description')),
      findsOneWidget,
    );
    expect(
      find.text(
        'SubWatch is reading local SMS history and looking for recurring billing signals.',
      ),
      findsOneWidget,
    );
    expect(find.text('Runs only on this phone'), findsOneWidget);
    expect(
      find.text('You can keep browsing while this scan finishes.'),
      findsOneWidget,
    );

    pendingSnapshot.complete(
      LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );
    await _pumpPastSyncFeedback(tester);
  });

  testWidgets('slow sync updates copy without pretending exact progress', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final pendingSnapshot = Completer<RuntimeDashboardSnapshot>();
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => pendingSnapshot.future,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
    await tester.pump();

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('Sorting confirmed, review, and benefit items'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('Still working through a larger message history'),
      findsOneWidget,
    );

    pendingSnapshot.complete(
      LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );
    await _pumpPastSyncFeedback(tester);
  });

  testWidgets('fast sync stays visible briefly and then clears cleanly', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsNothing,
    );
    expect(
      find.text('Finished checking SMS. Nothing was confirmed yet.'),
      findsOneWidget,
    );
  });

  testWidgets('sync progress clears and shows calm feedback on failure', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final pendingSnapshot = Completer<RuntimeDashboardSnapshot>();
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => pendingSnapshot.future,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsOneWidget,
    );

    pendingSnapshot.completeError(Exception('scan failed'));
    await tester.pump(const Duration(milliseconds: 700));
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('sync-progress-panel')),
      findsNothing,
    );
    expect(
      find.text('Device SMS refresh failed. Current snapshot was kept.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'first-run onboarding lets people browse first and does not repeat', (
    tester,
  ) async {
    final onboardingUseCases = buildMemorySmsOnboardingUseCases();
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.sampleDemo,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      findsOneWidget,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-browse-action'),
      ),
    );

    expect(provider.requestCount, 0);
    expect(
      find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      findsNothing,
    );
    expect(find.text('Scan messages'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('product-guidance-primary-action')),
      findsNothing,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );
    await _pumpPastSyncFeedback(tester);

    expect(
      find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      findsNothing,
    );
    expect(provider.requestCount, 1);
    expect(find.text('From your messages'), findsWidgets);
  });

  testWidgets('deny state shows a retry rationale and can open settings', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalDenied,
      requestResult: LocalMessageSourceAccessRequestResult.denied,
      refreshedState: LocalMessageSourceAccessState.deviceLocalDenied,
    );
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    expect(find.text('Turn on SMS access'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('product-guidance-primary-action')),
      findsNothing,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsOneWidget,
    );
    expect(find.text('Turn on SMS access when you are ready'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(provider.requestCount, 0);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-rationale-secondary-action'),
      ),
    );

    expect(provider.requestCount, 0);
    expect(
      find.byKey(const ValueKey<String>('settings-overview-panel')),
      findsOneWidget,
    );
    expect(find.text('On this device'), findsOneWidget);
  });

  testWidgets(
      'retry rationale keeps a calm denied state visible when access is denied again',
      (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalDenied,
      requestResult: LocalMessageSourceAccessRequestResult.denied,
      refreshedState: LocalMessageSourceAccessState.deviceLocalDenied,
    );
    final syncUseCase = SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: provider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
      ).execute(),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-rationale-primary-action'),
      ),
    );
    await _pumpPastSyncFeedback(tester);

    expect(provider.requestCount, 1);
    expect(
      find.text(
        'Device SMS access was not granted. You can keep browsing and try again later.',
      ),
      findsOneWidget,
    );
    expect(find.text('SMS access is off'), findsOneWidget);
    expect(find.text('Turn on SMS access'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('product-guidance-primary-action')),
      findsNothing,
    );
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets(
      'fresh low-result snapshot stays honest about having no confirmed subscriptions',
      (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
      findsNothing,
    );
    expect(find.text('From your messages'), findsWidgets);
    expect(find.text('Checked recently'), findsWidgets);
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets('zero-confirmed learn action opens the trust sheet', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-secondary-action')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-secondary-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('trust-how-it-works-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('review-heavy snapshot keeps uncertain items in Review', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-review',
              address: 'HDFCBK',
              body:
                  'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
    );

    await openDashboardDestination(tester, 'review');
    expect(find.text('Needs review'), findsWidgets);
    expect(find.textContaining('Google Play'), findsOneWidget);
  });

  testWidgets('zero-confirmed rescue can open manual add flow', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
      handleManualSubscriptionUseCase: harness.handleManualSubscriptionUseCase,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-add-manually-action')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-add-manually-action')),
    );
    // The popular service picker now appears first; tap "Custom entry".
    final customEntry = find.text('Custom entry');
    if (customEntry.evaluate().isNotEmpty) {
      await tester.ensureVisible(customEntry);
      await tester.tap(customEntry);
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
      findsOneWidget,
    );
  });

  testWidgets('sync with sms handles unavailable results safely',
      (tester) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalUnavailable,
      requestResult: LocalMessageSourceAccessRequestResult.unavailable,
      refreshedState: LocalMessageSourceAccessState.deviceLocalUnavailable,
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
    );

    expect(find.text('SMS refresh unavailable'), findsOneWidget);
    expect(
      find.text(
        'Safe local results stay active.',
      ),
      findsOneWidget,
    );
    expect(find.text('SMS unavailable'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
    );
    expect(button.onPressed, isNull);
  });
}

Future<void> _pumpPastSyncFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await pumpDashboardShellUi(tester);
}
