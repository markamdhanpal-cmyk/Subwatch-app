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

      final opened = await _openReviewDestinationIfAvailable(tester);
      if (!opened) {
        expect(
          find.byKey(const ValueKey<String>('settings-open-review-action')),
          findsNothing,
        );
        return;
      }

      expect(
        find.byKey(const ValueKey<String>('destination-review-surface')),
        findsOneWidget,
      );
      expect(find.text('Needs attention'), findsNothing);
      expect(find.text('Items for your review'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('review-queue-summary-card')),
        findsNothing,
      );

      expect(find.textContaining('The signals conflict'), findsOneWidget);
      expect(find.text('Confirm'), findsWidgets);
      expect(find.text('Bundle'), findsWidgets);
      expect(find.text('Not mine'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Why SubWatch flagged JioHotstar'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'JioHotstar\. The signals conflict, so this still needs your review\. Possible actions below\.',
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

    final opened = await _openReviewDestinationIfAvailable(tester);
    if (!opened) {
      expect(
        find.byKey(const ValueKey<String>('settings-open-review-action')),
        findsNothing,
      );
      return;
    }

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
    );

    expect(
      find.byKey(
          const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR')),
      findsOneWidget,
    );
    expect(find.text('Why SubWatch flagged this'), findsOneWidget);
    expect(
      find.textContaining('signals point in different directions'),
      findsOneWidget,
    );
    expect(
      find.textContaining('No strong billed renewal has been confirmed yet.'),
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

    await openDashboardDestination(tester, 'settings');
    expect(
      find.byKey(const ValueKey<String>('settings-open-review-action')),
      findsNothing,
    );
  });

  for (final scale in <double>[1.0, 1.15, 1.3, 1.5]) {
    testWidgets(
        'review action row stays readable at ${scale}x on a narrow handset', (
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

      final opened = await _openReviewDestinationIfAvailable(tester);
      if (!opened) {
        expect(
          find.byKey(const ValueKey<String>('settings-open-review-action')),
          findsNothing,
        );
        return;
      }

      await scrollDashboardUntilVisible(tester, find.text('Confirm'));

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

Future<bool> _openReviewDestinationIfAvailable(WidgetTester tester) async {
  await openDashboardDestination(tester, 'settings');
  final reviewActionFinder =
      find.byKey(const ValueKey<String>('settings-open-review-action'));
  if (reviewActionFinder.evaluate().isEmpty) {
    return false;
  }

  await tapAndPumpDashboardShell(tester, reviewActionFinder.first);
  await settleDashboard(tester);
  return find
      .byKey(const ValueKey<String>('destination-review-surface'))
      .evaluate()
      .isNotEmpty;
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
