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
    expect(
      find.text('Why SubWatch asks before checking SMS'),
      findsOneWidget,
    );
    expect(provider.requestCount, 0);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-next-action'),
      ),
    );
    expect(find.text('Kept on this device'), findsOneWidget);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-onboarding-next-action'),
      ),
    );
    expect(find.text('Careful by default'), findsOneWidget);
    expect(
      find.text(
        'A quiet scan can still be correct when the proof is limited.',
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
      find.text('Finished checking SMS. Results updated.'),
      findsOneWidget,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    final provenanceTitle = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(provenanceTitle.data, 'Checked');
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

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('sync-with-sms-button')),
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
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    final provenanceTitle = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(provenanceTitle.data, 'Checked');
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

    expect(find.text('Turn on SMS access'), findsWidgets);
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
    expect(
      find.text('Turn on SMS access only when you are ready'),
      findsOneWidget,
    );
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
      find.byKey(const ValueKey<String>('settings-quick-actions-panel')),
      findsOneWidget,
    );
    expect(find.text('On this device'), findsOneWidget);
    expect(find.text('Turn on SMS access'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-source-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsOneWidget,
    );
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
    expect(find.text('Turn on SMS access'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('product-guidance-primary-action')),
      findsNothing,
    );
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets(
      'fresh empty scan shows a zero-confirmed rescue without dead empty sections',
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

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
    );
    expect(
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
      findsOneWidget,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    final provenanceTitle = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(provenanceTitle.data, 'Checked');
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );
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

  testWidgets('review-heavy snapshot gives Review the primary rescue action', (
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

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
    );
    expect(
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
      findsOneWidget,
    );
    expect(find.text('Review 1 item'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );

    expect(find.text('Items for your review'), findsOneWidget);
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
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );
    final customEntry = find.text('Something else');
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

  testWidgets(
      'benefit-only zero-confirmed rescue routes to subscriptions with honest copy',
      (tester) async {
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
              id: 'raw-bundle',
              address: 'AIRTEL',
              body:
                  'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
    );
    expect(
      find.byKey(const ValueKey<String>('home-zero-confirmed-rescue')),
      findsOneWidget,
    );
    expect(find.text('See what was found'), findsOneWidget);
    expect(find.text('Trials & benefits'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('zero-confirmed-primary-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('section-trialsAndBenefits')),
      findsWidgets,
    );
    expect(find.text('Google Gemini Pro'), findsOneWidget);
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
        'This device cannot provide a fresh SMS check, so the current local view stays in place.',
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
