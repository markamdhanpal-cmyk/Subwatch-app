import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('android back dismisses dashboard bottom sheets', (tester) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-add-manual-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('popular-service-picker')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('popular-service-picker')),
      findsNothing,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
    );

    expect(
      find.byKey(const ValueKey<String>('how-subwatch-works-sheet')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('how-subwatch-works-sheet')),
      findsNothing,
    );
  });
}
