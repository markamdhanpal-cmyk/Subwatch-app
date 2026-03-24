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
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'first-run onboarding sheet stays readable on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      final onboardingUseCases = buildMemorySmsOnboardingUseCases();
      final provider = MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.sampleDemo,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
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
        ).execute(),
      );

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
          clock: () => DateTime(2026, 3, 13, 9, 0),
        ),
        syncDeviceSmsUseCase: syncUseCase,
        loadSmsOnboardingProgressUseCase: onboardingUseCases.$1,
        completeSmsOnboardingUseCase: onboardingUseCases.$2,
      );

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );

      expect(
        find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
        findsOneWidget,
      );
      expect(find.text('Find subscriptions in your messages'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(
          const ValueKey<String>('sms-permission-onboarding-continue-action'),
        ),
      );
      await tester.ensureVisible(
        find.byKey(
          const ValueKey<String>('sms-permission-onboarding-browse-action'),
        ),
      );
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
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
        ),
        syncDeviceSmsUseCase: syncUseCase,
      );

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );
      await tapAndPumpDashboardShell(
        tester,
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );

      expect(
        find.text('SMS access is off'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Open Settings'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scan working state and zero-confirmed rescue stay readable on a narrow handset',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

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
      );

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

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('home-action-strip')),
      );

      expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')),
          findsNothing);
      expect(find.text('Scan your messages'), findsWidgets);
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

      expect(
          find.text(
              'Gym Club added to your list. It now shows in spend.'),
          findsOneWidget);
      await scrollDashboardUntilVisible(tester, find.text('Gym Club'));
      expect(find.text('Gym Club'), findsOneWidget);
      expect(find.text('Added by you'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'subscriptions controls keep Add manually visible on a typical handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(392, 850));

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.3,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'subscriptions');
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('open-manual-subscription-form')),
      );

      expect(find.byTooltip('Add manually'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home totals metrics stack cleanly on a narrow handset with larger text',
    (tester) async {
      await _setSmallHandsetViewport(tester, const Size(320, 640));

      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.3,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      final confirmedMetric = find.byKey(
        const ValueKey<String>('spend-hero-confirmed-chip'),
      );
      final reviewMetric = find.byKey(
        const ValueKey<String>('home-action-strip'),
      );

      expect(confirmedMetric, findsOneWidget);
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

      final harness = DashboardShellReviewHarness();
      await _pumpConstrainedDashboardShell(
        tester,
        textScale: 1.2,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        handleManualSubscriptionUseCase:
            harness.handleManualSubscriptionUseCase,
      );
      
      debugDumpApp();

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
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('review-details-edit-JIOHOTSTAR')),
      );
      await tapAndPumpDashboardShell(
          tester, find.byKey(const ValueKey<String>('review-evidence-panel')));
      expect(find.text('What we saw'), findsWidgets);
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
}) async {
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
          ),
          child: child!,
        );
      },
      home: DashboardShell(
        runtimeUseCase: runtimeUseCase,
        syncDeviceSmsUseCase: syncDeviceSmsUseCase,
        handleReviewItemActionUseCase: handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: undoReviewItemActionUseCase,
        handleLocalControlOverlayUseCase: handleLocalControlOverlayUseCase,
        undoLocalControlOverlayUseCase: undoLocalControlOverlayUseCase,
        handleManualSubscriptionUseCase: handleManualSubscriptionUseCase,
        handleLocalServicePresentationUseCase:
            handleLocalServicePresentationUseCase,
        loadSmsOnboardingProgressUseCase: loadSmsOnboardingProgressUseCase,
        completeSmsOnboardingUseCase: completeSmsOnboardingUseCase,
      ),
    ),
  );
  await pumpDashboardShellLoad(tester);
}

