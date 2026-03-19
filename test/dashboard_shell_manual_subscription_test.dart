import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'manual subscriptions can be added, edited, deleted, and kept separate from detected items',
    (tester) async {
      final harness = DashboardShellReviewHarness();

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleManualSubscriptionUseCase: harness.handleManualSubscriptionUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        handleLocalControlOverlayUseCase: harness.handleLocalControlOverlayUseCase,
        undoLocalControlOverlayUseCase: harness.undoLocalControlOverlayUseCase,
        handleLocalServicePresentationUseCase:
            harness.handleLocalServicePresentationUseCase,
      );

      await openDashboardDestination(tester, 'subscriptions');
      expect(
        find.byKey(const ValueKey<String>('open-manual-subscription-form')),
        findsOneWidget,
      );
      expect(find.text('Netflix'), findsOneWidget);

      await _openManualEditor(tester);
      expect(
        find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
        findsOneWidget,
      );
      expect(
        find.text('Manual entries stay clearly marked as added by you.'),
        findsOneWidget,
      );

      await _fillManualEditor(
        tester,
        serviceName: 'Gym Club',
        amount: '999',
        planLabel: 'Family plan',
      );
      await _saveManualEditor(tester);

      expect(
        find.byKey(const ValueKey<String>('section-manualSubscriptions')),
        findsWidgets,
      );
      expect(find.text('Added by you'), findsOneWidget);
      expect(find.text('Gym Club'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(
        find.text('Manual entries stay clearly separate from detected subscriptions.'),
        findsOneWidget,
      );
      expect(find.text('Netflix'), findsOneWidget);

      await _openManualEditor(tester);
      await _fillManualEditor(
        tester,
        serviceName: 'Disney+ Hotstar',
        amount: '1499',
        billingCycle: 'Yearly',
      );
      await _saveManualEditor(tester);

      expect(find.text('Disney+ Hotstar'), findsOneWidget);
      expect(find.text('Yearly'), findsWidgets);

      await tapAndPumpDashboardShell(tester, find.text('Gym Club').first);
      expect(find.text('Added by you on this device.'), findsOneWidget);
      expect(find.text('Manual entry'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Plan label'), findsOneWidget);
      expect(find.text('Family plan'), findsOneWidget);

      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(FilledButton, 'Edit'),
      );
      expect(
        find.byKey(const ValueKey<String>('manual-service-name-input')),
        findsOneWidget,
      );

      await _fillManualEditor(
        tester,
        serviceName: 'Gym Club Plus',
        amount: '1099',
        planLabel: 'Family plan',
      );
      await _saveManualEditor(tester);

      expect(find.text('Gym Club Plus'), findsOneWidget);
      expect(find.text('Gym Club'), findsNothing);

      await tapAndPumpDashboardShell(
        tester,
        find.text('Disney+ Hotstar').first,
      );
      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(TextButton, 'Delete'),
      );
      expect(find.text('Delete manual subscription?'), findsOneWidget);
      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(FilledButton, 'Delete'),
      );

      expect(find.text('Disney+ Hotstar'), findsNothing);
      expect(find.text('Gym Club Plus'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    },
  );
}

Future<void> _openManualEditor(WidgetTester tester) async {
  await tapAndPumpDashboardShell(
    tester,
    find.byKey(const ValueKey<String>('open-manual-subscription-form')),
  );
  // The popular service picker now appears first; tap "Custom entry" to
  // proceed to the blank manual editor form.
  final customEntry = find.text('Custom entry');
  if (customEntry.evaluate().isNotEmpty) {
    await tester.ensureVisible(customEntry);
    await tapAndPumpDashboardShell(tester, customEntry);
  }
}

Future<void> _fillManualEditor(
  WidgetTester tester, {
  required String serviceName,
  String amount = '',
  String planLabel = '',
  String billingCycle = 'Monthly',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('manual-service-name-input')),
    serviceName,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('manual-amount-input')),
    amount,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('manual-plan-label-input')),
    planLabel,
  );
  await pumpDashboardShellUi(tester);

  if (billingCycle != 'Monthly') {
    final dropdown = find.byKey(
      const ValueKey<String>('manual-billing-cycle-input'),
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pump();
    await tester.tap(find.text(billingCycle).last);
    await pumpDashboardShellUi(tester);
  }
}

Future<void> _saveManualEditor(WidgetTester tester) async {
  final saveButton = find.byKey(
    const ValueKey<String>('save-manual-subscription'),
  );
  await tester.ensureVisible(saveButton);
  await tapAndPumpDashboardShell(tester, saveButton);
}
