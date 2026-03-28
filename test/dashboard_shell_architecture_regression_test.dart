import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'tabs lazy-load on first visit and keep visited destinations mounted',
    (tester) async {
      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      expect(_destinationSurface('home'), findsOneWidget);
      expect(_destinationSurface('subscriptions'), findsNothing);
      expect(_destinationSurface('review'), findsNothing);
      expect(_destinationSurface('settings'), findsNothing);

      await openDashboardDestination(tester, 'subscriptions');

      expect(_destinationSurface('home'), findsOneWidget);
      expect(_destinationSurface('subscriptions'), findsOneWidget);
      expect(_destinationSurface('review'), findsNothing);
      expect(_destinationSurface('settings'), findsNothing);

      await openDashboardDestination(tester, 'settings');

      expect(_destinationSurface('home'), findsOneWidget);
      expect(_destinationSurface('subscriptions'), findsOneWidget);
      expect(_destinationSurface('settings'), findsOneWidget);
      expect(_destinationSurface('review'), findsNothing);
    },
  );

  testWidgets(
    'subscriptions search state survives tab switching after first build',
    (tester) async {
      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'subscriptions');

      await tester.enterText(
        find.byKey(const ValueKey<String>('service-search-input')),
        'Netflix',
      );
      await pumpDashboardShellUi(tester);

      expect(_serviceSearchText(tester), 'Netflix');
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Spotify'), findsNothing);

      await openDashboardDestination(tester, 'home');
      await openDashboardDestination(tester, 'settings');
      await openDashboardDestination(tester, 'subscriptions');

      expect(_serviceSearchText(tester), 'Netflix');
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Spotify'), findsNothing);
    },
  );

  testWidgets(
    'review actions still flow across lazily built review and settings tabs',
    (tester) async {
      final harness = DashboardShellReviewHarness();

      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      expect(_destinationSurface('review'), findsNothing);
      expect(_destinationSurface('settings'), findsNothing);

      await openDashboardDestination(tester, 'review');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
      );
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
      );
      await settleDashboard(tester);

      expect(_destinationSurface('review'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
        findsNothing,
      );

      await openDashboardDestination(tester, 'settings');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
      );

      expect(_destinationSurface('settings'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('section-confirmedByYou')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
        findsWidgets,
      );

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
      );
      await settleDashboard(tester);

      await openDashboardDestination(tester, 'review');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
      );

      expect(
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
        findsWidgets,
      );
    },
  );
}

Finder _destinationSurface(String destination) {
  final key = switch (destination) {
    'home' => const ValueKey<String>('destination-home-surface'),
    'subscriptions' =>
      const ValueKey<String>('destination-subscriptions-surface'),
    'review' => const ValueKey<String>('destination-review-surface'),
    'settings' => const ValueKey<String>('destination-settings-surface'),

    _ => throw ArgumentError.value(destination, 'destination'),
  };
  return find.byKey(key, skipOffstage: false);
}

String _serviceSearchText(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.byKey(const ValueKey<String>('service-search-input')),
  );
  return field.controller?.text ?? '';
}
