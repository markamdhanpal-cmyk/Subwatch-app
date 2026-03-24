import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('android back dismisses dashboard bottom sheets', (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-help')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-help')),
    );

    expect(
      find.byKey(const ValueKey<String>('help-privacy-sheet')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('help-privacy-sheet')),
      findsNothing,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-add-manual-action')),
    );

    expect(
      find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
      findsNothing,
    );
  });
}

