import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'confirm review action can be undone and restores review visibility',
    (tester) async {
      final harness = DashboardShellReviewHarness();

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
      );

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('confirm-review-action-JIOHOTSTAR')),
      );
      await tester.pumpAndSettle();

      await openDashboardDestination(tester, 'settings');
      await scrollDashboardUntilVisible(tester, find.text('Confirmed'));
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Confirmed by your review'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
        findsWidgets,
      );

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
      );
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('undo-review-action-JIOHOTSTAR')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('section-confirmedByYou')),
        findsNothing,
      );
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

  testWidgets('dismiss review action can be undone safely', (tester) async {
    final harness = DashboardShellReviewHarness();
    const targetKey = 'JIOHOTSTAR';

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
    );

    await openDashboardDestination(tester, 'review');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(
        const ValueKey<String>('dismiss-review-action-$targetKey'),
      ),
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('dismiss-review-action-$targetKey'),
      ),
    );
    await tester.pumpAndSettle();

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(tester, find.text('Not subscriptions'));
    expect(find.text('Not subscriptions'), findsOneWidget);
    expect(find.text('Marked as not a subscription'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey<String>('undo-review-action-$targetKey'),
      ),
      findsWidgets,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(
        const ValueKey<String>('undo-review-action-$targetKey'),
      ),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>('undo-review-action-$targetKey'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('section-hiddenFromReview')),
      findsNothing,
    );
    await openDashboardDestination(tester, 'review');
    await scrollDashboardUntilVisible(tester, find.text('Jiohotstar'));
    expect(
      find.byKey(
        const ValueKey<String>('review-item-$targetKey'),
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'review destination stays calm when no decisions are pending',
    (tester) async {
      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: FakeDeviceSmsGateway(
            <RawDeviceSms>[
              RawDeviceSms(
                id: 'raw-netflix',
                address: 'BANK',
                body: 'Your Netflix subscription has been renewed for Rs 499.',
                receivedAt: DateTime(2026, 3, 12, 13, 0),
              ),
            ],
          ),
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'review');

      expect(find.text('Needs attention'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('section-reviewQueue')),
        findsWidgets,
      );
      expect(find.text('Nothing to review right now'), findsOneWidget);
      expect(
        find.text(
          'SubWatch only uses Review for items that still look uncertain. If later evidence still needs your decision, it will appear here again.',
        ),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey<String>('service-search-input')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-overview-panel')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
        findsNothing,
      );
    },
  );

  testWidgets('hide card can be undone from local recovery', (tester) async {
    final harness = DashboardShellReviewHarness();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      handleLocalControlOverlayUseCase:
          harness.handleLocalControlOverlayUseCase,
      undoLocalControlOverlayUseCase: harness.undoLocalControlOverlayUseCase,
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(
        const ValueKey<String>(
          'service-card-actions-confirmedSubscriptions-NETFLIX',
        ),
      ),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>(
          'service-card-actions-confirmedSubscriptions-NETFLIX',
        ),
      ),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>(
          'hide-card-action-confirmedSubscriptions-NETFLIX',
        ),
      ),
    );

    expect(find.text('Netflix hidden locally.'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(tester, find.text('Hidden items'));
    expect(find.text('Hidden on this device'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>(
          'undo-review-action-card::confirmedSubscriptions::NETFLIX',
        ),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
    );
    expect(find.text('Netflix'), findsOneWidget);
  });

  testWidgets('ignore review item can be undone from local recovery', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();
    const targetKey = 'JIOHOTSTAR';

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      handleLocalControlOverlayUseCase:
          harness.handleLocalControlOverlayUseCase,
      undoLocalControlOverlayUseCase: harness.undoLocalControlOverlayUseCase,
    );

    await openDashboardDestination(tester, 'review');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('review-card-actions-$targetKey')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('review-card-actions-$targetKey')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        ValueKey<String>('ignore-review-item-action-$targetKey'),
      ),
    );

    expect(find.text('Jiohotstar hidden on this device.'), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('review-item-$targetKey')),
      findsNothing,
    );

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(tester, find.text('Hidden items'));
    expect(find.text('Hidden on this device'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        ValueKey<String>('undo-review-action-service::$targetKey'),
      ),
    );

    await openDashboardDestination(tester, 'review');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(ValueKey<String>('review-item-$targetKey')),
    );
    expect(
      find.byKey(ValueKey<String>('review-item-$targetKey')),
      findsWidgets,
    );
  });

  testWidgets(
    'review details explain uncertainty and can mark an item as benefit',
    (tester) async {
      final harness = DashboardShellReviewHarness();

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');
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
          const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR'),
        ),
        findsWidgets,
      );
      expect(find.text('What SubWatch saw'), findsWidgets);
      expect(find.text('What stood out'), findsOneWidget);
      expect(find.text('Why it stays separate'), findsOneWidget);
      expect(find.text('Best next step'), findsOneWidget);

      await _scrollSheetUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('review-details-benefit-JIOHOTSTAR')),
      );
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('review-details-benefit-JIOHOTSTAR')),
      );
      await tester.pumpAndSettle();

      await openDashboardDestination(tester, 'subscriptions');
      await scrollDashboardUntilVisible(tester, find.text('Jiohotstar'));
      expect(find.text('Jiohotstar'), findsWidgets);
      expect(
        find.text('Kept separate as a benefit by your review'),
        findsWidgets,
      );

      await openDashboardDestination(tester, 'settings');
      await scrollDashboardUntilVisible(tester, find.text('Separate access'));
      expect(
        find.byKey(const ValueKey<String>('section-benefitsByYou')),
        findsWidgets,
      );
      expect(find.text('Kept separate as a benefit'), findsWidgets);
    },
  );

  testWidgets('review details can seed the manual editor safely', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      handleManualSubscriptionUseCase: harness.handleManualSubscriptionUseCase,
    );

    await openDashboardDestination(tester, 'review');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
    );
    await _scrollSheetUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('review-details-edit-JIOHOTSTAR')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('review-details-edit-JIOHOTSTAR')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
      findsOneWidget,
    );
    final serviceField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('manual-service-name-input')),
    );
    expect(serviceField.controller!.text, 'Jiohotstar');
  });
}

Future<void> _scrollSheetUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pump();
}
