import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'manual subscriptions with renewal dates show reminders and appear in the home renewals zone',
    (tester) async {
      final now = DateTime(2026, 3, 18, 10, 0);
      final harness = DashboardShellReviewHarness(
        clock: () => now,
      );

      final tomorrow = now.add(const Duration(days: 7));
      final entry = ManualSubscriptionEntry(
        id: 'manual-1',
        serviceName: 'Manual Gym',
        billingCycle: ManualSubscriptionBillingCycle.monthly,
        nextRenewalDate: tomorrow,
        amountInMinorUnits: 50000,
        createdAt: now,
        updatedAt: now,
      );
      await harness.localManualSubscriptionStore.save(entry);

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleManualSubscriptionUseCase:
            harness.handleManualSubscriptionUseCase,
        handleLocalRenewalReminderUseCase:
            harness.handleLocalRenewalReminderUseCase,
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('home-renewals-zone')),
      );

      expect(find.text('Renewals'), findsOneWidget);
      expect(find.text('Manual Gym'), findsOneWidget);
      expect(find.text('\u20B9500'), findsOneWidget);

      await openDashboardDestination(tester, 'subscriptions');
      expect(find.text('Manual Gym'), findsOneWidget);

      final actionButton = find.byKey(
        const ValueKey<String>('manual-subscription-actions-manual-1'),
      );
      await tester.ensureVisible(actionButton);
      await tapAndPumpDashboardShell(tester, actionButton);

      expect(find.text('Reminder'), findsOneWidget);

      await tapAndPumpDashboardShell(tester, find.text('Reminder'));

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Local reminder'), findsOneWidget);
      expect(find.text('1 day before'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();
      await tapAndPumpDashboardShell(tester, find.text('Manual Gym').first);
      expect(find.text('Set reminder'), findsOneWidget);

      await tapAndPumpDashboardShell(tester, find.text('Set reminder'));
      expect(find.text('Local reminder'), findsOneWidget);

      final threeDaysBtn = find.widgetWithText(FilledButton, '3 days before');
      await tester.ensureVisible(threeDaysBtn);
      await tapAndPumpDashboardShell(tester, threeDaysBtn);

      final prefs = await harness.localRenewalReminderStore.list();
      expect(prefs.length, 1);
      expect(prefs.first.serviceKey, 'manual-1');
      expect(prefs.first.leadTimePreset.name, 'threeDays');
    },
  );
}

