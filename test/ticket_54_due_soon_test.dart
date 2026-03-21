import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/dashboard_upcoming_renewals_presentation.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_due_soon_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  final useCase = BuildDashboardDueSoonUseCase(
    clock: () => DateTime(2026, 3, 14, 9, 0),
  );

  test('due soon keeps only near-term renewal-capable items nearest first', () {
    final upcomingRenewals = DashboardUpcomingRenewalsPresentation(
      items: <DashboardUpcomingRenewalItemPresentation>[
        DashboardUpcomingRenewalItemPresentation(
          serviceKey: 'NETFLIX',
          serviceTitle: 'Netflix',
          renewalDate: DateTime(2026, 3, 20),
          renewalDateLabel: '20 Mar 2026',
          amountLabel: 'Rs 499',
        ),
        DashboardUpcomingRenewalItemPresentation(
          serviceKey: 'YOUTUBE',
          serviceTitle: 'YouTube Premium',
          renewalDate: DateTime(2026, 3, 16),
          renewalDateLabel: '16 Mar 2026',
        ),
        DashboardUpcomingRenewalItemPresentation(
          serviceKey: 'ADOBE',
          serviceTitle: 'Adobe',
          renewalDate: DateTime(2026, 3, 23),
          renewalDateLabel: '23 Mar 2026',
          amountLabel: 'Rs 799',
        ),
      ],
    );

    final result = useCase.execute(upcomingRenewals: upcomingRenewals);

    expect(result.items, hasLength(2));
    expect(result.items.first.serviceTitle, 'YouTube Premium');
    expect(result.items.last.serviceTitle, 'Netflix');
    expect(result.items.last.amountLabel, 'Rs 499');
  });

  test('due soon excludes items outside the near-term window', () {
    final upcomingRenewals = DashboardUpcomingRenewalsPresentation(
      items: <DashboardUpcomingRenewalItemPresentation>[
        DashboardUpcomingRenewalItemPresentation(
          serviceKey: 'NETFLIX',
          serviceTitle: 'Netflix',
          renewalDate: DateTime(2026, 3, 25),
          renewalDateLabel: '25 Mar 2026',
          amountLabel: 'Rs 499',
        ),
      ],
    );

    final result = useCase.execute(upcomingRenewals: upcomingRenewals);

    expect(result.hasItems, isFalse);
    expect(
      result.summaryCopy,
      'Nothing due in the next 7 days.',
    );
  });

  testWidgets('dashboard shows honest empty due soon state', (tester) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase.deviceLocalStub(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('due-soon-card')),
    );

    expect(find.byKey(const ValueKey<String>('due-soon-card')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('due-soon-card')),
        matching: find.text('Due soon'),
      ),
      findsOneWidget,
    );
    expect(find.text('Nothing due soon'), findsOneWidget);
    expect(
      find.text(
        'Only confirmed subscriptions or manual entries with a clear renewal date appear here.',
      ),
      findsOneWidget,
    );
  });
}
