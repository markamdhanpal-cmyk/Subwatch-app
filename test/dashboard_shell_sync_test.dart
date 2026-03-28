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

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        clock: () => DateTime(2026, 3, 13, 9, 0),
      ),
      syncDeviceSmsUseCase: syncUseCase,
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
      skipGate: false,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('first-run-get-started-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsOneWidget,
    );
    expect(provider.requestCount, 0);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-rationale-primary-action'),
      ),
    );
    await _pumpPastSyncFeedback(tester);

    expect(provider.requestCount, 1);
    expect(
      find.text('Scan finished. Results updated.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('totals-summary-card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('home-action-strip')), findsNothing);
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

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
      skipGate: false,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('first-run-get-started-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsOneWidget,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-rationale-secondary-action'),
      ),
    );
    await settleDashboard(tester);

    expect(provider.requestCount, 0);
    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('first-run-gate-headline')),
      findsNothing,
    );

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
      skipGate: false,
    );

    expect(
      find.byKey(const ValueKey<String>('first-run-gate-headline')),
      findsNothing,
    );
    expect(provider.requestCount, 0);
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

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
      syncDeviceSmsUseCase: syncUseCase,
    );

    expect(find.text('Turn on SMS access'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('home-action-primary-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsOneWidget);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('sms-permission-rationale-secondary-action'),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('settings-quick-actions-panel')),
      findsOneWidget,
    );
    expect(find.text('Turn on SMS access'), findsWidgets);
  });

  testWidgets(
      'review-heavy snapshot routes to review from the home action surface', (
    tester,
  ) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpConstrainedDashboardShell(
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

    expect(find.byKey(const ValueKey<String>('home-action-strip')),
        findsOneWidget);
    expect(find.text('1 item waiting'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('home-action-primary-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsOneWidget,
    );
    expect(find.textContaining('Google Play'), findsOneWidget);
  });

  testWidgets('fresh empty scan keeps home to the spend hero only',
      (tester) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        clock: () => DateTime(2026, 3, 14, 11, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('totals-summary-card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('home-action-strip')), findsNothing);
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );
  });

  testWidgets('sync with sms hides action surfaces when refresh is unavailable',
      (tester) async {
    final provider = MutableCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalUnavailable,
      requestResult: LocalMessageSourceAccessRequestResult.unavailable,
      refreshedState: LocalMessageSourceAccessState.deviceLocalUnavailable,
    );

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
      ),
    );

    expect(
        find.byKey(const ValueKey<String>('home-action-strip')), findsNothing);
    expect(find.byKey(const ValueKey<String>('sync-with-sms-button')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('totals-summary-card')),
        findsOneWidget);
  });
}

Future<void> _pumpPastSyncFeedback(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await pumpDashboardShellUi(tester);
}
