import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('dashboard shell renders the SubWatch title', (tester) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(find.text('SubWatch'), findsOneWidget);
  });
}
