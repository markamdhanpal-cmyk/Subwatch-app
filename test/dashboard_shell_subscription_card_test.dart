import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('subscription cards show amount renewal and frequency fallbacks',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
    );

    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>('subscription-meta-amount-NETFLIX'),
            ),
          )
          .data,
      'Rs 499',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>('subscription-meta-renewal-NETFLIX'),
            ),
          )
          .data,
      'Date not clear yet',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>('subscription-meta-frequency-NETFLIX'),
            ),
          )
          .data,
      'Cycle not clear yet',
    );

    await scrollDashboardUntilVisible(
      tester,
      find.text('Google Gemini Pro'),
    );

    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>(
                'subscription-meta-amount-GOOGLE_GEMINI_PRO',
              ),
            ),
          )
          .data,
      'Not a paid charge',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>(
                'subscription-meta-frequency-GOOGLE_GEMINI_PRO',
              ),
            ),
          )
          .data,
      'Benefit access',
    );
  });
}
