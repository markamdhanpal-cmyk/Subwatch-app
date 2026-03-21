import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
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
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(sourceLabel.data, 'Sample view');
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
      find.text('This is a sample layout until you scan messages on this device.'),
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
    expect(find.text('Before your first scan'), findsOneWidget);
    expect(
      find.text('See how SubWatch stays careful before your first scan'),
      findsOneWidget,
    );
    expect(find.text('Your first scan replaces this preview'), findsOneWidget);
    expect(find.text('Monthly spend estimate'), findsOneWidget);
    expect(find.text('Rs 648'), findsWidgets);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Needs review'), findsWidgets);
    expect(find.text('Trials & benefits'), findsWidgets);
    expect(find.text('What this preview shows'), findsOneWidget);
    expect(
      find.text('Netflix and Spotify appear as paid subscriptions here.'),
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
          'Jiohotstar stay separate until you decide.'),
      findsOneWidget,
    );
    expect(
      find.text('Google Gemini Pro stays visible as separate access.'),
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
        matching: find.text('Needs your review'),
      ),
      findsWidgets,
    );
    expect(
      find.text(
        'This may be recurring, but SubWatch is waiting for stronger proof before it counts it as paid.',
      ),
      findsOneWidget,
    );
    expect(find.text('What SubWatch saw'), findsWidgets);
    expect(
      find.textContaining('Setup intent seen'),
      findsOneWidget,
    );
    expect(find.text('See why'), findsWidgets);
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
    expect(find.text('What SubWatch confirms'), findsOneWidget);
    expect(find.text('What stays separate'), findsOneWidget);
    expect(find.text('What refresh means'), findsOneWidget);
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
      find.byKey(const ValueKey<String>('settings-quick-actions-panel')),
      findsOneWidget,
    );
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('settings-support-panel')),
      findsWidgets,
    );
    expect(find.text('Help, privacy & about'), findsWidgets);
    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Using SubWatch'), findsOneWidget);
    expect(find.text('Privacy & local data'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('settings-app-info-panel')),
        findsNothing);

    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -500),
    );
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('section-settings-recovery')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-renewalReminders')),
      findsNothing,
    );
  });

  testWidgets('settings quick actions open scan onboarding and manual add', (
    tester,
  ) async {
    final onboardingUseCases = buildMemorySmsOnboardingUseCases();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
      loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
      completeSmsOnboardingUseCase: onboardingUseCases.$2,
    );

    await openDashboardDestination(tester, 'settings');

    expect(find.byKey(const ValueKey<String>('settings-quick-actions-panel')), findsWidgets);
    expect(find.text('Scan messages'), findsOneWidget);
    expect(find.text('Review 1 item'), findsOneWidget);
    expect(find.text('Add manually'), findsWidgets);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-source-action')),
    );
    expect(
      find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      findsOneWidget,
    );

    Navigator.of(
      tester.element(
        find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
      ),
    ).pop();
    await pumpDashboardShellUi(tester);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-add-manual-action')),
    );
    expect(
      find.byKey(const ValueKey<String>('popular-service-picker')),
      findsOneWidget,
    );
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
    expect(find.text('Refresh & source'), findsOneWidget);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Confirmed, Review, separate access'), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey<String>('help-sheet'))),
    ).pop();
    await pumpDashboardShellUi(tester);

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-privacy')),
    );
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
    expect(find.text('What SubWatch does not do'), findsOneWidget);
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
        'Screenshots are usually enough. Share message text only if someone specifically asks for it.',
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
        'Fresh and saved views stay labeled separately so the current state stays honest.',
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
        'Any decision you make stays local to this device and can be undone later.',
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
      find.text('Why this stays separate'),
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


  testWidgets('startup load keeps a saved local view when refresh loading fails', (
    tester,
  ) async {
    final store = MemoryLedgerSnapshotStore();

    await LoadRuntimeDashboardUseCase(
      capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
      ),
      deviceSmsGateway: FakeDeviceSmsGateway(
        <RawDeviceSms>[
          RawDeviceSms(
            id: 'seed-netflix',
            address: 'BANK',
            body: 'Your Netflix subscription has been renewed for Rs 499.',
            receivedAt: DateTime(2026, 3, 12, 13, 0),
          ),
        ],
      ),
      ledgerSnapshotStore: store,
      loadMode: RuntimeLedgerLoadMode.refreshFromSource,
      clock: () => DateTime(2026, 3, 14, 8, 30),
    ).execute();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: _AlwaysThrowingGateway(),
        ledgerSnapshotStore: store,
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')), findsOneWidget);
    expect(find.text('This local view is not ready yet.'), findsNothing);
    expect(find.text('Saved view'), findsWidgets);
  });
  testWidgets('load error offers a retry path back into the dashboard', (
    tester,
  ) async {
    final gateway = _FlakyGateway();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: gateway,
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    expect(find.text('This local view is not ready yet.'), findsOneWidget);
    expect(find.textContaining('could not open the current local view just yet'), findsOneWidget);
    expect(find.text('Exception: boom'), findsNothing);
    expect(find.text('boom'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('retry-load-dashboard')),
      findsOneWidget,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('retry-load-dashboard')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('This local view is not ready yet.'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('retry-load-dashboard')),
      findsNothing,
    );
  });
}

class _AlwaysThrowingGateway implements DeviceSmsGateway {
  @override
  Future<List<RawDeviceSms>> readMessages() async {
    throw Exception('still broken');
  }
}

class _FlakyGateway implements DeviceSmsGateway {
  int _calls = 0;

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    _calls += 1;
    if (_calls == 1) {
      throw Exception('boom');
    }

    return <RawDeviceSms>[
      RawDeviceSms(
        id: 'retry-netflix',
        address: 'BANK',
        body: 'Your Netflix subscription has been renewed for Rs 499.',
        receivedAt: DateTime(2026, 3, 12, 13, 0),
      ),
    ];
  }
}
