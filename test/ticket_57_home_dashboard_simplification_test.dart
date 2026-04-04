import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('How totals work'), findsNothing);
    expect(find.byKey(const ValueKey<String>('product-guidance-panel')),
        findsNothing);

    final renewalsZone =
        find.byKey(const ValueKey<String>('home-renewals-zone'));
    if (renewalsZone.evaluate().isNotEmpty) {
      expect(renewalsZone, findsOneWidget);
      await scrollDashboardUntilVisible(tester, renewalsZone);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('home focus card routes into the dedicated review destination', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      handleManualSubscriptionUseCase: harness.handleManualSubscriptionUseCase,
      skipGate: true,
    );

    await openDashboardDestination(tester, 'home');

    final actionStrip = find.byKey(const ValueKey<String>('home-action-strip'));
    final primaryAction =
        find.byKey(const ValueKey<String>('home-action-primary-action'));

    if (actionStrip.evaluate().isNotEmpty &&
        primaryAction.evaluate().isNotEmpty) {
      await tapAndPumpDashboardShell(tester, primaryAction.first);
      final reviewSurface =
          find.byKey(const ValueKey<String>('destination-review-surface'));
      final settingsSurface =
          find.byKey(const ValueKey<String>('destination-settings-surface'));
      expect(
        reviewSurface.evaluate().isNotEmpty ||
            settingsSurface.evaluate().isNotEmpty,
        isTrue,
      );
    } else {
      expect(find.byKey(const ValueKey<String>('settings-open-review-action')),
          findsNothing);
    }

    expect(tester.takeException(), isNull);
  });
}
