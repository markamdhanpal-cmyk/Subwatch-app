import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_service_presentation_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_manual_subscription_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/application/use_cases/request_device_sms_access_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_review_item_action_use_case.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_manual_subscription_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'first-run onboarding sheet stays readable on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final onboardingStore = InMemorySmsOnboardingProgressStore();
      final loadOnboardingUseCase =
          LoadSmsOnboardingProgressUseCase(store: onboardingStore);
      final completeOnboardingUseCase =
          CompleteSmsOnboardingUseCase(store: onboardingStore);
      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.sampleDemo,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      provider.delayRequest =
          Completer<LocalMessageSourceAccessRequestResult>();
      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
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
        ).execute(),
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        skipGate: false,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
          clock: () => DateTime(2026, 3, 13, 9, 0),
        ),
        syncDeviceSmsUseCase: syncUseCase,
        loadSmsOnboardingProgressUseCase: loadOnboardingUseCase,
        completeSmsOnboardingUseCase: completeOnboardingUseCase,
      );

      // Verify the Gate is readable
      expect(find.byKey(const ValueKey<String>('first-run-gate-headline')),
          findsOneWidget);

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('first-run-get-started-button')),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await pumpDashboardShellUi(tester);

      expect(
        find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
        findsOneWidget,
      );
      expect(find.text('Start with SMS permission'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(
          const ValueKey<String>('sms-permission-rationale-primary-action'),
        ),
      );

      // Complete the request - this triggers the transition to next phase
      provider.delayRequest!
          .complete(LocalMessageSourceAccessRequestResult.granted);
      await settleDashboard(tester);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'denied recovery sheet stays readable on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalDenied,
        requestResult: LocalMessageSourceAccessRequestResult.denied,
        refreshedState: LocalMessageSourceAccessState.deviceLocalDenied,
      );
      provider.delayRequest =
          Completer<LocalMessageSourceAccessRequestResult>();
      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ).execute(),
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        skipGate: false,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ),
        syncDeviceSmsUseCase: syncUseCase,
      );

      // Handle the Gate
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('first-run-get-started-button')),
      );

      // Now we should be at rationale, click it to reach 'denied' phase
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(
            const ValueKey<String>('sms-permission-rationale-primary-action')),
      );
      provider.delayRequest!
          .complete(LocalMessageSourceAccessRequestResult.denied);
      await pumpDashboardUntilSyncIdle(tester);

      expect(
        find.byKey(const ValueKey<String>('first-run-denied')),
        findsOneWidget,
      );
      expect(
        find.text('SubWatch needs SMS access to find your subscriptions.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Try again'));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scan working state and zero-confirmed rescue stay readable on a narrow handset',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final onboardingStore = InMemorySmsOnboardingProgressStore();
      await onboardingStore.writeCompleted(true);
      final loadOnboardingUseCase =
          LoadSmsOnboardingProgressUseCase(store: onboardingStore);
      final completeOnboardingUseCase =
          CompleteSmsOnboardingUseCase(store: onboardingStore);

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      final pendingSnapshot = Completer<RuntimeDashboardSnapshot>();
      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => pendingSnapshot.future,
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ),
        syncDeviceSmsUseCase: syncUseCase,
        loadSmsOnboardingProgressUseCase: loadOnboardingUseCase,
        completeSmsOnboardingUseCase: completeOnboardingUseCase,
      );

      await pumpDashboardShellUi(tester);

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );
      await tester
          .tap(find.byKey(const ValueKey<String>('sync-with-sms-button')));
      await tester.pump(const Duration(milliseconds: 100));
      await pumpDashboardShellUi(tester);

      expect(tester.takeException(), isNull);

      pendingSnapshot.complete(
        LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
          clock: () => DateTime(2026, 3, 14, 11, 0),
        ).execute(),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await pumpDashboardShellUi(tester);

      expect(
        find.byKey(const ValueKey<String>('sync-progress-panel')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'sample preview stays readable on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.sampleDemo,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.sampleDemo,
      );
      final syncUseCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
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
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ).execute(),
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        skipGate: false,
        syncDeviceSmsUseCase: syncUseCase,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: FakeDeviceSmsGateway(
            <RawDeviceSms>[
              RawDeviceSms(
                id: 'raw-netflix',
                address: 'BANK',
                body: 'Your Netflix subscription has been renewed for Rs 499.',
                receivedAt: DateTime(2026, 3, 14, 9, 0),
              ),
            ],
          ),
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await pumpDashboardShellUi(tester);

      expect(find.textContaining('Find subscriptions'), findsOneWidget);
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('first-run-get-started-button')),
      );

      await pumpDashboardShellLoad(tester, skipGate: true);
      await pumpDashboardShellUi(tester);

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('home-action-strip')),
      );

      expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')),
          findsNothing);
      expect(find.textContaining('Scan your messages'), findsWidgets);
      expect(
        find.text('No scan yet'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('product-guidance-panel')),
          findsNothing);
      expect(tester.takeException(), isNull);

      final harness = DashboardShellReviewHarness();
      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        skipGate: true,
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
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('open-manual-subscription-form')),
      );
      // The popular service picker now appears first; tap "Custom entry".
      final customEntry = find.text('Something else');
      if (customEntry.evaluate().isNotEmpty) {
        await tester.ensureVisible(customEntry);
        await tapAndPumpDashboardShell(tester, customEntry);
      }

      expect(
        find.byKey(const ValueKey<String>('manual-subscription-editor-new')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('manual-service-name-input')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('manual-service-name-input')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('manual-service-name-input')),
        'Gym Club',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('manual-amount-input')),
        '999',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('manual-plan-label-input')),
        'Family',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('save-manual-subscription')),
      );
      expect(tester.takeException(), isNull);

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('save-manual-subscription')),
      );

      expect(find.text('Gym Club added to your list. It now shows in spend.'),
          findsOneWidget);
      await scrollDashboardUntilVisible(tester, find.text('Gym Club'));
      expect(find.text('Gym Club'), findsOneWidget);
      expect(find.text('Added by you'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'subscriptions controls keep Add subscription visible on a typical handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(392, 850));

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.3,
        skipGate: true,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'subscriptions');
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('open-manual-subscription-form')),
      );

      expect(find.byTooltip('Add subscription'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home totals metrics stack cleanly on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.3,
        skipGate: true,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          deviceSmsGateway: FakeDeviceSmsGateway(
            <RawDeviceSms>[
              RawDeviceSms(
                id: 'raw-netflix',
                address: 'BANK',
                body: 'Your Netflix subscription has been renewed for Rs 499.',
                receivedAt: DateTime(2026, 3, 14, 8, 0),
              ),
              RawDeviceSms(
                id: 'raw-amazon',
                address: 'BANK',
                body: 'You have set up an autopay mandate for Amazon Prime.',
                receivedAt: DateTime(2026, 3, 14, 8, 30),
              ),
            ],
          ),
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
        clock: () => DateTime(2026, 3, 14, 9, 0),
      );

      final confirmedMetric = find.byKey(
        const ValueKey<String>('spend-hero-confirmed-chip'),
      );
      final reviewMetric = find.byKey(
        const ValueKey<String>('home-action-strip'),
      );

      expect(
        confirmedMetric,
        findsOneWidget,
      );
      expect(reviewMetric, findsOneWidget);
      expect(
        tester.getTopLeft(reviewMetric).dy,
        greaterThan(tester.getTopLeft(confirmedMetric).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review details sheet stays readable on a narrow handset',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

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
      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        skipGate: true,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        handleManualSubscriptionUseCase:
            harness.handleManualSubscriptionUseCase,
      );

      await openDashboardDestination(tester, 'review');
      final detailsButton =
          find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR'));
      await tester.dragUntilVisible(
        detailsButton,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await settleDashboard(tester);
      await tester.tap(detailsButton);
      await settleDashboard(tester);

      expect(
        find.byKey(
          const ValueKey<String>('review-item-details-sheet-JIOHOTSTAR'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('review-details-confirm-JIOHOTSTAR')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('review-evidence-panel')),
      );
      expect(
          find.text('A recurring-looking signal was found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _setSmallHandsetViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpConstrainedDashboardShell(
  WidgetTester tester, {
  double textScale = 1.0,
  bool skipGate = false,
  LocalMessageSourceAccessState initialAccessState =
      LocalMessageSourceAccessState.sampleDemo,
  LoadRuntimeDashboardUseCase? runtimeUseCase,
  SyncDeviceSmsUseCase? syncDeviceSmsUseCase,
  HandleReviewItemActionUseCase? handleReviewItemActionUseCase,
  UndoReviewItemActionUseCase? undoReviewItemActionUseCase,
  HandleLocalControlOverlayUseCase? handleLocalControlOverlayUseCase,
  UndoLocalControlOverlayUseCase? undoLocalControlOverlayUseCase,
  HandleManualSubscriptionUseCase? handleManualSubscriptionUseCase,
  HandleLocalServicePresentationUseCase? handleLocalServicePresentationUseCase,
  LoadSmsOnboardingProgressUseCase? loadSmsOnboardingProgressUseCase,
  CompleteSmsOnboardingUseCase? completeSmsOnboardingUseCase,
  DateTime Function()? clock,
}) async {
  final onboardingStore = InMemorySmsOnboardingProgressStore()
    ..writeCompleted(skipGate);
  final provider = MutableCapabilityProvider(
    initialState: initialAccessState,
    requestResult: LocalMessageSourceAccessRequestResult.granted,
    refreshedState: initialAccessState,
  );
  final effectiveRuntimeUseCase = runtimeUseCase ??
      LoadRuntimeDashboardUseCase(
        capabilityProvider: provider,
        ledgerSnapshotStore: MemoryLedgerSnapshotStore(),
        reviewActionStore: InMemoryReviewActionStore(),
        localControlOverlayStore: InMemoryLocalControlOverlayStore(),
        localManualSubscriptionStore: InMemoryLocalManualSubscriptionStore(),
        localRenewalReminderStore: InMemoryLocalRenewalReminderStore(),
        localServicePresentationOverlayStore:
            InMemoryLocalServicePresentationOverlayStore(),
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        clock: clock,
      );
  final defaultSyncDeviceSmsUseCase = SyncDeviceSmsUseCase(
    requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
      capabilityProvider: provider,
    ),
    loadRuntimeDashboard: effectiveRuntimeUseCase.execute,
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          DashboardTypeScale(
            display: TextStyle(fontSize: 40),
            heading: TextStyle(fontSize: 22),
            subheading: TextStyle(fontSize: 18),
            body: TextStyle(fontSize: 16),
            caption: TextStyle(fontSize: 13),
            label: TextStyle(fontSize: 13),
            button: TextStyle(fontSize: 14),
          ),
        ],
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        );
      },
      home: DashboardShell(
        runtimeUseCase: effectiveRuntimeUseCase,
        syncDeviceSmsUseCase:
            syncDeviceSmsUseCase ?? defaultSyncDeviceSmsUseCase,
        handleReviewItemActionUseCase: handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: undoReviewItemActionUseCase,
        handleLocalControlOverlayUseCase: handleLocalControlOverlayUseCase,
        undoLocalControlOverlayUseCase: undoLocalControlOverlayUseCase,
        handleManualSubscriptionUseCase: handleManualSubscriptionUseCase,
        handleLocalServicePresentationUseCase:
            handleLocalServicePresentationUseCase,
        loadSmsOnboardingProgressUseCase: loadSmsOnboardingProgressUseCase ??
            LoadSmsOnboardingProgressUseCase(
              store: onboardingStore,
            ),
        completeSmsOnboardingUseCase: completeSmsOnboardingUseCase ??
            CompleteSmsOnboardingUseCase(
              store: onboardingStore,
            ),
      ),
    ),
  );
  await pumpDashboardShellLoad(tester, skipGate: skipGate);
}
