import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  const fontScales = [1.0, 1.15, 1.3, 1.5];
  const narrowHandset = Size(320, 640);

  for (final scale in fontScales) {
    group('Accessibility Regression - Font Scale ${scale}x', () {
      testWidgets('Home hero stays readable and actionable', (tester) async {
        await _setupAccessibilityTest(tester, scale, narrowHandset);
        
        // Verify Home hero elements
        expect(find.text('Monthly spend estimate'), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('spend-hero-amount')), findsOneWidget);
        
        final syncButton = find.byKey(const ValueKey<String>('app-bar-sync-button'));
        await scrollDashboardUntilVisible(tester, syncButton);
        expect(syncButton, findsOneWidget);
        
        // Overflow check (Flutter will throw if RenderFlex overflows during pump)
        expect(tester.takeException(), isNull);
      });

      testWidgets('Subscription list items stay readable', (tester) async {
        final harness = DashboardShellReviewHarness();
        await _setupAccessibilityTest(tester, scale, narrowHandset, harness: harness);
        
        await openDashboardDestination(tester, 'subscriptions');
        await settleDashboard(tester);

        final confirmedSection =
            find.byKey(const ValueKey<String>('section-confirmedSubscriptions'));
        await scrollDashboardUntilVisible(tester, confirmedSection);
        expect(confirmedSection, findsOneWidget);
        
        expect(tester.takeException(), isNull);
      });

      testWidgets('Review queue items stay readable', (tester) async {
        // Use the default setup which has SampleDemo data including review items
        await _setupAccessibilityTest(tester, scale, narrowHandset);
        
        await openDashboardDestination(tester, 'review');
        await settleDashboard(tester);

        final reviewQueue =
            find.byKey(const ValueKey<String>('section-reviewQueue'));
        await scrollDashboardUntilVisible(tester, reviewQueue);
        expect(reviewQueue, findsOneWidget);
        
        expect(tester.takeException(), isNull);
      });

      testWidgets('Settings rows stay readable', (tester) async {
        await _setupAccessibilityTest(tester, scale, narrowHandset);
        
        await openDashboardDestination(tester, 'settings');
        
        await scrollDashboardUntilVisible(tester, find.text('Actions'));
        expect(find.text('Actions'), findsOneWidget);
        
        await scrollDashboardUntilVisible(tester, find.text('Clear all data'));
        expect(find.text('Clear all data'), findsOneWidget);
        
        expect(tester.takeException(), isNull);
      });
    });
  }
}

Future<void> _setupAccessibilityTest(
  WidgetTester tester,
  double textScale,
  Size viewport, {
  DashboardShellReviewHarness? harness,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final provider = MutableCapabilityProvider(
    initialState: LocalMessageSourceAccessState.sampleDemo,
    requestResult: LocalMessageSourceAccessRequestResult.granted,
    refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
  );
  
  final runtimeUseCase = harness?.runtimeUseCase ?? LoadRuntimeDashboardUseCase(
    capabilityProvider: provider,
    clock: () => DateTime(2026, 3, 13, 9, 0),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: buildDashboardTestTheme(
        typeScale: const DashboardTypeScale(
          display: TextStyle(fontSize: 40),
          heading: TextStyle(fontSize: 22),
          subheading: TextStyle(fontSize: 18),
          body: TextStyle(fontSize: 16),
          caption: TextStyle(fontSize: 13),
          label: TextStyle(fontSize: 13),
          button: TextStyle(fontSize: 14),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        );
      },
      home: DashboardShell(
        runtimeUseCase: runtimeUseCase,
        handleReviewItemActionUseCase: harness?.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness?.undoReviewItemActionUseCase,
        handleManualSubscriptionUseCase: harness?.handleManualSubscriptionUseCase,
        handleLocalControlOverlayUseCase: harness?.handleLocalControlOverlayUseCase,
        undoLocalControlOverlayUseCase: harness?.undoLocalControlOverlayUseCase,
        handleLocalServicePresentationUseCase: harness?.handleLocalServicePresentationUseCase,
        loadSmsOnboardingProgressUseCase: harness?.loadSmsOnboardingProgressUseCase ?? LoadSmsOnboardingProgressUseCase(store: InMemorySmsOnboardingProgressStore()..writeCompleted(true)),
        completeSmsOnboardingUseCase: harness?.completeSmsOnboardingUseCase ?? CompleteSmsOnboardingUseCase(store: InMemorySmsOnboardingProgressStore()..writeCompleted(true)),
      ),
    ),
  );
  
  await pumpDashboardShellLoad(tester);
}






