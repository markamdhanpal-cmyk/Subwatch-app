import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
      'subscription cards show a compact paid line and positive bundled summary',
      (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await pumpDashboardShellUi(tester);
    await scrollDashboardUntilVisible(
      tester,
      find.textContaining('Netflix'),
    );



    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>('subscription-meta-amount-NETFLIX'),
            ),
          )
          .data,
      '\u20B9499',
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
      find.byKey(
        const ValueKey<String>('subscription-meta-frequency-NETFLIX'),
      ),
      findsNothing,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.textContaining('Google Gemini Pro'),
    );


    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey<String>(
                'subscription-meta-summary-GOOGLE_GEMINI_PRO',
              ),
            ),
          )
          .data,
      'Bundled with another plan - no separate charge.',
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'subscription-meta-amount-GOOGLE_GEMINI_PRO',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'subscription-meta-renewal-GOOGLE_GEMINI_PRO',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'subscription-meta-frequency-GOOGLE_GEMINI_PRO',
        ),
      ),
      findsNothing,
    );
  });
}
