import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
      'bottom navigation switches between focused top-level destinations', (
    tester,
  ) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('top-level-navigation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('destination-review')),
      findsNothing,
    );
    expect(find.text('Overview'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('totals-summary-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('snapshot-certificate-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('service-search-input')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-overview-panel')),
      findsNothing,
    );

    await openDashboardDestination(tester, 'subscriptions');
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('service-search-input')),

      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('totals-summary-card')),
      findsNothing,
    );
    await openDashboardDestination(tester, 'settings');

    expect(find.text('On this device'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('settings-quick-actions-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsNothing,
    );
  });

  testWidgets('home stays focused on summary and attention surfaces only', (
    tester,
  ) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('totals-summary-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-renewals-zone')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('snapshot-certificate-card')),
      findsNothing,
    );
    expect(find.text('Overview'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('service-search-input')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-overview-panel')),
      findsNothing,
    );
  });
}

