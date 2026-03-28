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
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase.deviceLocalStub(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')),
        findsNothing);
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
    expect(find.text('Monthly spend estimate'), findsOneWidget);
    expect(find.text('How totals work'), findsNothing);
    expect(find.byKey(const ValueKey<String>('home-action-strip')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('product-guidance-panel')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('home-renewals-zone')),
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
      'home focus card routes into the dedicated review destination', (
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
      find.byKey(const ValueKey<String>('home-action-strip')),
    );
    expect(find.byKey(const ValueKey<String>('home-action-strip')),
        findsOneWidget);
    expect(find.text('1 item waiting'), findsWidgets);
    final totalsTop = tester
        .getTopLeft(find.byKey(const ValueKey<String>('totals-summary-card')))
        .dy;
    final focusTop = tester
        .getTopLeft(find.byKey(const ValueKey<String>('home-action-strip')))
        .dy;
    expect(totalsTop, lessThan(focusTop));

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('home-action-primary-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsOneWidget,
    );
  });
}



