import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'confirm review action can be undone and restores review visibility',
    (tester) async {
      final harness = DashboardShellReviewHarness(
        deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
          RawDeviceSms(
            id: 'msg-1',
            address: 'JIOHOTSTAR',
            body: 'Your Jiohotstar subscription may renew shortly.',
            receivedAt: DateTime(2026, 3, 12, 13, 0),
          ),
        ]),
      );

      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');
      await settleDashboard(tester);
      

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
      );

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR')),
          matching: find.text('Jiohotstar'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR')),
          matching: find.text('Confirm'),
        ),
      );
      await settleDashboard(tester);
      expect(
        find.text('Jiohotstar added to your subscriptions.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Undo'));
      await settleDashboard(tester);

      expect(
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
        findsOneWidget,
      );
    },
  );
}



