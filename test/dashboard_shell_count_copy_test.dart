import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('subscriptions view uses explicit bucket-specific count copy',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('service-view-visible-count')),
          )
          .data,
      '3 items in this list',
    );
    expect(find.text('2 subscriptions'), findsOneWidget);

    await scrollDashboardUntilVisible(
      tester,
      find.text('Google Gemini Pro'),
    );
    expect(find.text('1 benefit'), findsOneWidget);
  });

  testWidgets('review destination count copy says review items',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'review');

    expect(find.text('1 review item'), findsOneWidget);
  });
}
