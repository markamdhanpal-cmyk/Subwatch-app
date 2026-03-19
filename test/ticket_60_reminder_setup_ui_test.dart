import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'manual subscriptions with renewal dates show reminders and appear in upcoming cards',
    (tester) async {
      final now = DateTime(2026, 3, 18, 10, 0);
      final harness = DashboardShellReviewHarness(
        clock: () => now,
      );

      // 1. Add a manual subscription with a date 7 days out
      final tomorrow = now.add(const Duration(days: 7));
      final entry = ManualSubscriptionEntry(
        id: 'manual-1',
        serviceName: 'Manual Gym',
        billingCycle: ManualSubscriptionBillingCycle.monthly,
        nextRenewalDate: tomorrow,
        amountInMinorUnits: 50000, // Rs 500
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

      // Wait explicitly for any internal state updates/animations
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Ensure it's scrolled into view
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      );

      // Verify it shows up in Home "Upcoming" card
      expect(find.text('Upcoming renewals'), findsOneWidget);
      expect(find.text('Manual Gym'), findsOneWidget);
      expect(find.text('Rs 500'), findsOneWidget);

      // 2. Open Subscriptions tab
      await openDashboardDestination(tester, 'subscriptions');
      expect(find.text('Manual Gym'), findsOneWidget);

      // 3. Open Popup Menu and verify "Reminder" option exists
      final actionButton = find.byKey(
        const ValueKey<String>('manual-subscription-actions-manual-1'),
      );
      await tester.ensureVisible(actionButton);
      await tapAndPumpDashboardShell(tester, actionButton);
      
      expect(find.text('Reminder'), findsOneWidget);

      // 4. Open Reminder controls from Popup Menu
      await tapAndPumpDashboardShell(tester, find.text('Reminder'));
      
      // Wait for bottom sheet animation
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Local reminder'), findsOneWidget);
      expect(find.text('1 day before'), findsOneWidget);
      
      // Close sheet
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 5. Open Details via Tap and verify Reminder button exists
      // Wait for the sheet to be fully gone before tapping again
      await tester.pumpAndSettle();
      await tapAndPumpDashboardShell(tester, find.text('Manual Gym').first);
      expect(find.text('Set local reminder'), findsOneWidget);

      // 6. Set a reminder from Details
      await tapAndPumpDashboardShell(tester, find.text('Set local reminder'));
      expect(find.text('Local reminder'), findsOneWidget);
      
      final threeDaysBtn = find.widgetWithText(FilledButton, '3 days before');
      await tester.ensureVisible(threeDaysBtn);
      await tapAndPumpDashboardShell(tester, threeDaysBtn);

      // Verify persistence
      final prefs = await harness.localRenewalReminderStore.list();
      expect(prefs.length, 1);
      expect(prefs.first.serviceKey, 'manual-1');
      expect(prefs.first.leadTimePreset.name, 'threeDays');
    },
  );
}
