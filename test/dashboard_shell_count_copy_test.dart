import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('subscriptions view keeps section headers compact',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');

    expect(find.text('2 subscriptions'), findsNothing);
    expect(find.text('1 subscription'), findsNothing);
    expect(find.text('1 benefit'), findsNothing);
    expect(
      find.text(
        'Save one on this device when you want to track it yourself.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsWidgets,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('toggle-section-trialsAndBenefits')),
    );
    expect(
      find.byKey(const ValueKey<String>('section-trialsAndBenefits')),
      findsWidgets,
    );
  });

  testWidgets('review destination keeps the summary calm and count-free',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'review');

    expect(find.text('1 review item'), findsNothing);
    expect(find.text('Ready for your decision'), findsWidgets);
  });
}
