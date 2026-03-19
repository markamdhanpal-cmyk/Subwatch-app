import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('confirmed subscriptions render separately from review items', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 13, 9, 0),
      ),
    );

    final confirmedSection = find.byKey(
      const ValueKey<String>('section-confirmedSubscriptions'),
    );
    final reviewQueueSection = find.byKey(
      const ValueKey<String>('section-reviewQueue'),
    );

    expect(
      find.byKey(const ValueKey<String>('snapshot-certificate-card')),
      findsOneWidget,
    );
    expect(find.text('SubWatch'), findsOneWidget);
    expect(find.text('Scan messages'), findsOneWidget);
    final sourceLabel = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-source-label')),
    );
    expect(sourceLabel.data, 'Sample');
    expect(
      find.text('Showing the sample view prepared on 13 Mar 2026, 09:00.'),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey<String>('section-confirmedByYou')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-hiddenFromReview')),
      findsNothing,
    );
    expect(
      find.text('Scan your messages to replace the sample view.'),
      findsOneWidget,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('product-guidance-panel')),
    );
    expect(
      find.byKey(const ValueKey<String>('product-guidance-panel')),
      findsOneWidget,
    );
    expect(find.text('Sample preview'), findsOneWidget);
    expect(
      find.text('See what SubWatch can surface before your first scan'),
      findsOneWidget,
    );
    expect(find.text('Estimated monthly total'), findsOneWidget);
    expect(find.text('Rs 648'), findsWidgets);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Needs review'), findsWidgets);
    expect(find.text('Trial or benefit'), findsOneWidget);
    expect(find.text('What this sample is showing'), findsOneWidget);
    expect(
      find.text('Netflix and Spotify show up as paid subscriptions.'),
      findsOneWidget,
    );
    expect(find.text('Due soon'), findsOneWidget);
    expect(
      find.text(
        'Example: Netflix on 18 Mar for Rs 499 once the next renewal date is clear.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
          'Jiohotstar stay separate until you review them.'),
      findsOneWidget,
    );
    expect(
      find.text('Google Gemini Pro stays separate from paid subscriptions.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-review-summary-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('product-guidance-primary-action')),
      findsNothing,
    );

    await openDashboardDestination(tester, 'review');
    expect(find.text('Review'), findsWidgets);
    expect(
      find.descendant(
        of: reviewQueueSection,
        matching: find.text('Unresolved'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: reviewQueueSection,
        matching: find.text('Jiohotstar'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reviewQueueSection,
        matching: find.text('Needs review'),
      ),
      findsWidgets,
    );
    expect(
      find.text(
        'This looks recurring enough to keep visible, but not safe enough to auto-confirm.',
      ),
      findsOneWidget,
    );
    expect(find.text('Short reason'), findsWidgets);
    expect(
      find.textContaining('Setup intent seen'),
      findsOneWidget,
    );
    expect(find.text('Review details'), findsWidgets);
    expect(find.text('Not a subscription'), findsWidgets);
    expect(find.text('Confirm as paid'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'confirm-review-action-UNRESOLVED::sample-review',
        ),
      ),
      findsNothing,
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
    );
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsWidgets,
    );
    expect(
      find.descendant(of: confirmedSection, matching: find.text('Netflix')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: confirmedSection, matching: find.text('Spotify')),
      findsOneWidget,
    );
  });

  testWidgets('demo state opens the trust and how-it-works sheet', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-trust-sheet')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-trust-sheet')),
    );

    expect(
      find.byKey(const ValueKey<String>('trust-how-it-works-sheet')),
      findsOneWidget,
    );
    expect(find.text('How SubWatch works'), findsWidgets);
    expect(find.text('Trust-first by default'), findsOneWidget);
    expect(find.text('What refresh does'), findsOneWidget);
    expect(find.text('What to expect'), findsOneWidget);
  });

  testWidgets(
      'settings destination groups support recovery and reminders clearly', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');

    expect(
      find.byKey(const ValueKey<String>('settings-overview-panel')),
      findsOneWidget,
    );
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('settings-support-panel')),
      findsWidgets,
    );
    expect(find.text('Help & privacy'), findsWidgets);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('settings-app-info-panel')),
        findsNothing);

    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -500),
    );
    await pumpDashboardShellUi(tester);

    expect(find.text('Recovery'), findsWidgets);
    expect(find.text('Reminders'), findsWidgets);
  });

  testWidgets('settings destination opens help and privacy sheets', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-help')),
    );

    expect(find.byKey(const ValueKey<String>('help-sheet')), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Confirmed vs observed'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey<String>('help-sheet'))),
    ).pop();
    await pumpDashboardShellUi(tester);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-privacy')),
    );

    expect(
      find.byKey(const ValueKey<String>('privacy-local-data-sheet')),
      findsOneWidget,
    );
    expect(find.text('What stays local'), findsOneWidget);
    expect(find.text('When SMS is read'), findsOneWidget);
    expect(find.text('What you control'), findsOneWidget);
  });

  testWidgets('settings destination opens about and feedback sheets', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-feedback')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-feedback')),
    );

    expect(
      find.byKey(const ValueKey<String>('feedback-sheet')),
      findsOneWidget,
    );
    expect(find.text('What helps'), findsOneWidget);
    expect(find.text('How to share it'), findsOneWidget);
    expect(
      find.text(
        'You do not need to copy raw SMS unless someone specifically asks for it.',
      ),
      findsOneWidget,
    );

    Navigator.of(
      tester.element(find.byKey(const ValueKey<String>('feedback-sheet'))),
    ).pop();
    await pumpDashboardShellUi(tester);

    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -700),
    );
    await pumpDashboardShellUi(tester);
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-about')),
    );

    expect(
      find.byKey(const ValueKey<String>('about-subwatch-sheet')),
      findsOneWidget,
    );
    expect(find.text('What it is'), findsOneWidget);
    expect(find.text('What it is not'), findsOneWidget);
  });

  testWidgets(
      'snapshot explanation clarifies demo versus fresh and restored state', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('open-snapshot-explanation-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('contextual-explanation-sheet')),
      findsOneWidget,
    );
    expect(find.text('Why the sample view is showing'), findsOneWidget);
    expect(find.text('Why SubWatch shows this'), findsOneWidget);
    expect(
      find.text(
        'Fresh and restored local snapshots are labeled separately so the current state stays honest.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('review explanation clarifies why an item stays separate', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    const targetKey = 'JIOHOTSTAR';

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
      find.byKey(const ValueKey<String>('open-review-explanation-$targetKey')),
    );

    expect(
      find.byKey(const ValueKey<String>('contextual-explanation-sheet')),
      findsOneWidget,
    );
    expect(find.text('Why this item is in review'), findsOneWidget);
    expect(
      find.text(
        'This item is not counted as active paid until you make an explicit decision.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('service explanations cover active and bundled states', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
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
          'open-card-explanation-confirmedSubscriptions-Netflix',
        ),
      ),
    );

    expect(find.text('Why this is listed'), findsOneWidget);

    Navigator.of(
      tester.element(
        find.byKey(const ValueKey<String>('contextual-explanation-sheet')),
      ),
    ).pop();
    await pumpDashboardShellUi(tester);

    await scrollDashboardUntilVisible(
      tester,
      find.text('Google Gemini Pro'),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>(
          'service-card-actions-trialsAndBenefits-GOOGLE_GEMINI_PRO',
        ),
      ),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(
        const ValueKey<String>(
          'open-card-explanation-trialsAndBenefits-Google Gemini Pro',
        ),
      ),
    );

    expect(
      find.text('Why this is separate'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Bundled or free access is not counted as an active paid subscription.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('local service controls open and save a local label', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleLocalServicePresentationUseCase:
          harness.handleLocalServicePresentationUseCase,
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
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
          'open-local-service-controls-confirmedSubscriptions-NETFLIX',
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('local-service-controls-sheet-NETFLIX'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Only changes how this service looks on this device. It does not change the subscription itself.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('local-label-input-NETFLIX')),
      'Family streaming',
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('save-local-label-NETFLIX')),
    );

    expect(find.text('Family streaming'), findsOneWidget);
  });
}
