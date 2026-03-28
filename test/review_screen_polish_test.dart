import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('review app bar and card stay calm and decision-first', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      final harness = _reviewHarness();

      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');
      await settleDashboard(tester);

      expect(find.text('Review'), findsWidgets);
      expect(find.text('Needs attention'), findsNothing);
      expect(find.text('Items for your review'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('review-queue-summary-card')),
        findsNothing,
      );

      await scrollDashboardUntilVisible(tester, find.text('Jiohotstar'));

      expect(find.text('Looks recurring, but still uncertain'), findsOneWidget);
      expect(find.text('Confirm'), findsWidgets);
      expect(find.text('Bundle'), findsWidgets);
      expect(find.text('Not mine'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Why SubWatch flagged Jiohotstar'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Jiohotstar\. Looks recurring, but still uncertain\. Review actions below\.',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('review details keep evidence on demand without lecture copy', (
    tester,
  ) async {
    final harness = _reviewHarness();

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
      find.byKey(const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR')),
      findsOneWidget,
    );
    expect(find.text('Why SubWatch flagged this'), findsOneWidget);
    expect(find.text('A recurring-looking signal was found.'), findsOneWidget);
    expect(
      find.text('The evidence is still too weak to confirm it automatically.'),
      findsOneWidget,
    );
    expect(find.text('How to decide'), findsNothing);
    expect(find.text('What we saw'), findsNothing);
    expect(find.text('Why it stays separate'), findsNothing);
    expect(find.text('Hide on this phone'), findsOneWidget);
  });

  testWidgets('review empty state stays quiet', (tester) async {
    final harness = DashboardShellReviewHarness(
      deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
        RawDeviceSms(
          id: 'confirmed-1',
          address: 'BANK',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
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

    expect(find.text('Nothing to review right now'), findsOneWidget);
    expect(find.text('New uncertain items show up here.'), findsNothing);
  });

  for (final scale in <double>[1.0, 1.15, 1.3, 1.5]) {
    testWidgets('review action row stays readable at ${scale}x on a narrow handset', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = _reviewHarness();

      await pumpConstrainedDashboardShell(
        tester,
        textScale: scale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );
      await openDashboardDestination(tester, 'review');
      await settleDashboard(tester);
      await scrollDashboardUntilVisible(tester, find.text('Confirm').first);

      expect(find.text('Confirm'), findsWidgets);
      expect(find.text('Bundle'), findsWidgets);
      expect(find.text('Not mine'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

DashboardShellReviewHarness _reviewHarness() {
  return DashboardShellReviewHarness(
    deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
      RawDeviceSms(
        id: 'msg-1',
        address: 'JIOHOTSTAR',
        body: 'Your Jiohotstar subscription may renew shortly.',
        receivedAt: DateTime(2026, 3, 12, 13, 0),
      ),
    ]),
  );
}
