import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
      'home keeps only summary surfaces and removes the old overview stack', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase.deviceLocalStub(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('registry-register')), findsNothing);
    expect(find.byKey(const ValueKey<String>('service-search-input')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('section-reviewQueue')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('settings-overview-panel')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('totals-summary-card')),
        findsOneWidget);

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('product-guidance-panel')),
    );
    expect(find.byKey(const ValueKey<String>('product-guidance-panel')),
        findsOneWidget);

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('due-soon-card')),
    );
    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsOneWidget);

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
    );
    expect(find.byKey(const ValueKey<String>('upcoming-renewals-card')),
        findsOneWidget);
  });

  testWidgets(
      'home review summary routes into the dedicated review destination', (
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
              id: 'netflix-confirmed',
              address: 'NETFLIX',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 14, 8, 0),
            ),
            RawDeviceSms(
              id: 'google-play-review',
              address: 'HDFCBK',
              body:
                  'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
              receivedAt: DateTime(2026, 3, 14, 8, 5),
            ),
          ],
        ),
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('home-review-summary-card')),
    );
    expect(find.byKey(const ValueKey<String>('home-review-summary-card')),
        findsOneWidget);
    expect(find.text('Review'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('home-open-review-summary')),
    );

    expect(find.text('Needs review'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('section-reviewQueue')),
        findsWidgets);
  });
}
