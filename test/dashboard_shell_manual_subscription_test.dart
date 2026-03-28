import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'manual subscriptions can be added, edited, deleted, and kept separate from detected items',
    (tester) async {
      final harness = DashboardShellReviewHarness(
        deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
          RawDeviceSms(
            id: 'confirmed-netflix',
            address: 'NETFLIX',
            body: 'Your Netflix subscription has been renewed for Rs 499.',
            receivedAt: DateTime(2026, 3, 12, 10, 0),
          ),
        ]),
      );

      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleManualSubscriptionUseCase:
            harness.handleManualSubscriptionUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        handleLocalControlOverlayUseCase:
            harness.handleLocalControlOverlayUseCase,
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

      await _fillManualEditor(
        tester,
        serviceName: 'Gym Club',
        amount: '999',
        planLabel: 'Family plan',
      );
      await _saveManualEditor(tester);

      await scrollDashboardUntilVisible(tester, find.text('Gym Club'));
      expect(
        find.byKey(const ValueKey<String>('section-manualSubscriptions')),
        findsWidgets,
      );
      expect(find.text('Added by you'), findsWidgets);
      expect(find.text('Gym Club'), findsOneWidget);

      await _openManualEditor(tester);
      await _fillManualEditor(
        tester,
        serviceName: 'Disney+ Hotstar',
        amount: '1499',
        billingCycle: 'Yearly',
      );
      await _saveManualEditor(tester);

      await scrollDashboardUntilVisible(tester, find.text('Disney+ Hotstar'));
      expect(find.text('Disney+ Hotstar'), findsOneWidget);

      final gymClubCard = find
          .ancestor(
            of: find.text('Gym Club').first,
            matching: find.byType(InkWell),
          )
          .first;
      final gymClubRow = tester.widget<InkWell>(gymClubCard);
      expect(gymClubRow.onTap, isNotNull);
      gymClubRow.onTap!.call();
      await pumpDashboardShellUi(tester);
      expect(find.text('Saved on this phone and kept separate from scans.'),
          findsOneWidget);
      expect(find.text('Added by you'), findsWidgets);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Plan label'), findsOneWidget);
      expect(find.text('Family plan'), findsOneWidget);

      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(FilledButton, 'Edit details'),
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

      final disneyCard = find
          .ancestor(
            of: find.text('Disney+ Hotstar').first,
            matching: find.byType(InkWell),
          )
          .first;
      final disneyRow = tester.widget<InkWell>(disneyCard);
      expect(disneyRow.onTap, isNotNull);
      disneyRow.onTap!.call();
      await pumpDashboardShellUi(tester);
      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(TextButton, 'Remove from list'),
      );
      expect(find.text('Remove added subscription?'), findsOneWidget);
      await tapAndPumpDashboardShell(
        tester,
        find.widgetWithText(FilledButton, 'Remove'),
      );

      expect(find.text('Disney+ Hotstar'), findsNothing);
      expect(find.text('Gym Club Plus'), findsOneWidget);
    },
  );
}

Future<void> _openManualEditor(WidgetTester tester) async {
  await scrollDashboardUntilVisible(
    tester,
    find.byKey(const ValueKey<String>('open-manual-subscription-form')),
  );
  await tapAndPumpDashboardShell(
    tester,
    find.byKey(const ValueKey<String>('open-manual-subscription-form')),
  );
  final customEntry = find.text('Something else');
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
