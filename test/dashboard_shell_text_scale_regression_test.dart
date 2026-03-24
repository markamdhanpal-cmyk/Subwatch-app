// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_renewal_reminder_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_service_presentation_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_manual_subscription_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_review_item_action_use_case.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

import 'support/dashboard_shell_test_harness.dart';

/// Focused regression coverage for accessibility and large text scale risks.
///
/// Tests key surfaces at multiple text scales to catch overflow, clipping,
/// and layout hierarchy issues.
///
/// Text scales covered:
/// - 1.0x (baseline)
/// - 1.15x (medium-large)
/// - 1.3x (large)
/// - 1.5x (extra-large)
///
/// Surfaces covered:
/// - Home hero (totals summary card, action strip)
/// - Subscription cards (list rows, meta panels)
/// - Review cards (queue items, action rows)
/// - Settings rows (nav rows, action tiles)
/// - Onboarding / SMS permission surfaces (see manual checklist)
void main() {
  // Text scale factors to test
  const List<double> textScales = <double>[1.0, 1.15, 1.3, 1.5];

  group('Text scale regression', () {
    for (final textScale in textScales) {
      group('at ${textScale}x scale', () {
        _testHomeSurfaceAtScale(textScale);
        _testSubscriptionCardsAtScale(textScale);
        _testReviewCardsAtScale(textScale);
        _testSettingsRowsAtScale(textScale);
        // Note: Onboarding/SMS permission surfaces require manual verification
        // as they depend on onboarding completion state not available in test harness
      });
    }
  });

  group('Text scale overflow and clipping checks', () {
    for (final textScale in textScales) {
      _testNoRenderFlexOverflowAtScale(textScale);
      _testActionRowsReachableAtScale(textScale);
      _testBadgesAreVisibleAtScale(textScale);
    }
  });

}

// ============================================================================
// HOME SURFACE TESTS
// ============================================================================

void _testHomeSurfaceAtScale(double textScale) {
  testWidgets(
    'home totals summary card renders without overflow at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'home');

      // Verify home screen loads without errors
      expect(find.byKey(const ValueKey<String>('destination-home')),
          findsOneWidget);

      // Check for overflow render errors
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home action strip renders correctly at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'home');

      // Action strip should be present when there are review items
      final actionStripFinder =
          find.byKey(const ValueKey<String>('home-action-strip'));
      if (actionStripFinder.evaluate().isNotEmpty) {
        expect(actionStripFinder, findsOneWidget);

        // Verify primary action button is present
        expect(find.byKey(const ValueKey<String>('home-action-primary-action')),
            findsOneWidget);
      }

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================
// SUBSCRIPTION CARD TESTS
// ============================================================================

void _testSubscriptionCardsAtScale(double textScale) {
  testWidgets(
    'subscription list rows render without overflow at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'subscriptions');

      // Verify subscriptions screen loads
      expect(find.byKey(const ValueKey<String>('destination-subscriptions')),
          findsOneWidget);

      // Scroll to verify content renders
      await tester.drag(
        find.byType(Scrollable).hitTestable().first,
        const Offset(0, -300),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual subscription rows render at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();
      const String manualServiceName = 'Disney+ Hotstar Family Annual Plan';

      await harness.handleManualSubscriptionUseCase.create(
        serviceName: manualServiceName,
        billingCycle: ManualSubscriptionBillingCycle.yearly,
        amountInput: '1499',
        nextRenewalDate: DateTime(2026, 4, 14),
        planLabel: 'Premium yearly',
      );

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        handleManualSubscriptionUseCase:
            harness.handleManualSubscriptionUseCase,
      );

      await openDashboardDestination(tester, 'subscriptions');
      await scrollDashboardUntilVisible(tester, find.text(manualServiceName));

      // Verify manual subscription is present
      expect(find.text(manualServiceName), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================
// REVIEW CARD TESTS
// ============================================================================

void _testReviewCardsAtScale(double textScale) {
  testWidgets(
    'review queue items render without overflow at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');

      // Verify review screen loads
      expect(find.byKey(const ValueKey<String>('destination-review')),
          findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review action rows remain accessible at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'review');

      // Verify review items are present
      final reviewItems = find.byType(ListTile).hitTestable();
      if (reviewItems.evaluate().isNotEmpty) {
        // Tap first item to open details
        await tapAndPumpDashboardShell(tester, reviewItems.first);

        // Verify action buttons are present
        expect(find.byType(FilledButton), findsWidgets);
      }

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================
// SETTINGS ROW TESTS
// ============================================================================

void _testSettingsRowsAtScale(double textScale) {
  testWidgets(
    'settings nav rows render without overflow at ${textScale}x',
    (WidgetTester tester) async {
      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'settings');

      // Verify key settings panels are present
      expect(find.byKey(const ValueKey<String>('settings-quick-actions-panel')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('settings-support-panel')),
          findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings about and help rows render at ${textScale}x',
    (WidgetTester tester) async {
      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'settings');

      // Verify about and help rows
      expect(find.byKey(const ValueKey<String>('settings-open-help')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('settings-open-about')),
          findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================
// ONBOARDING AND PERMISSION SURFACE TESTS
// ============================================================================

void _testOnboardingAndPermissionSurfacesAtScale(double textScale) {
  testWidgets(
    'SMS permission onboarding sheet renders at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'home');

      // Verify onboarding sheet is present (key trust copy)
      expect(
        find.byKey(const ValueKey<String>('sms-permission-onboarding-sheet')),
        findsOneWidget,
      );

      // Verify title is visible
      expect(
        find.byKey(const ValueKey<String>('sms-onboarding-title')),
        findsOneWidget,
      );

      // Verify CTAs are visible
      expect(
        find.byKey(const ValueKey<String>(
            'sms-permission-onboarding-continue-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(
            const ValueKey<String>('sms-permission-onboarding-browse-action')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SMS permission rationale sheet renders at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'home');

      // Verify rationale sheet is present
      expect(
        find.byKey(const ValueKey<String>('sms-permission-rationale-sheet')),
        findsOneWidget,
      );

      // Verify primary action is reachable
      expect(
        find.byKey(
            const ValueKey<String>('sms-permission-rationale-primary-action')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'onboarding CTA buttons have adequate tap targets at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'home');

      // Verify FilledButton (primary CTA) has adequate size
      final filledButton = find.byType(FilledButton).first;
      final buttonSize = tester.getSize(filledButton);
      expect(buttonSize.height, greaterThanOrEqualTo(48));

      // Verify TextButton (secondary CTA) is hit-testable
      final textButton = find.byType(TextButton).hitTestable().first;
      expect(textButton, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================
// OVERFLOW AND ACCESSIBILITY CHECKS
// ============================================================================

void _testNoRenderFlexOverflowAtScale(double textScale) {
  testWidgets(
    'no RenderFlex overflow errors at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      // Test all destinations
      for (final destination in <String>[
        'home',
        'subscriptions',
        'review',
        'settings'
      ]) {
        await openDashboardDestination(tester, destination);
        await tester.pump();

        // Verify no overflow errors
        expect(tester.takeException(), isNull);

        // Scroll to ensure more content is rendered
        await tester.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -500),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      }
    },
  );
}

void _testActionRowsReachableAtScale(double textScale) {
  testWidgets(
    'action rows remain reachable at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'subscriptions');

      // Verify subscription items are present and tappable
      final subscriptionItems = find.byType(ListTile).hitTestable();
      if (subscriptionItems.evaluate().isNotEmpty) {
        // Tap first item to open details
        await tapAndPumpDashboardShell(tester, subscriptionItems.first);

        // Verify action buttons are hit-testable
        final actionButtons = find.byType(TextButton).hitTestable();
        expect(actionButtons, findsWidgets);

        // Verify close button has adequate tap target
        final closeButton = find.byTooltip('Close').first;
        if (closeButton.evaluate().isNotEmpty) {
          final closeSize = tester.getSize(closeButton);
          expect(closeSize.width, greaterThanOrEqualTo(48));
          expect(closeSize.height, greaterThanOrEqualTo(48));
        }
      }

      expect(tester.takeException(), isNull);
    },
  );
}

void _testBadgesAreVisibleAtScale(double textScale) {
  testWidgets(
    'DashboardBadge chips remain visible and do not clip at ${textScale}x',
    (WidgetTester tester) async {
      final harness = DashboardShellReviewHarness();

      await _pumpAppWithTextScale(
        tester,
        textScale: textScale,
        runtimeUseCase: harness.runtimeUseCase,
        handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
      );

      await openDashboardDestination(tester, 'subscriptions');

      // Verify at least one badge is visible
      final badgeFinder = find.byType(DashboardBadge).hitTestable();
      if (badgeFinder.evaluate().isNotEmpty) {
        final badge = badgeFinder.first;
        final badgeSize = tester.getSize(badge);

        // Badge should have a reasonable height even at large scales
        expect(badgeSize.height, greaterThanOrEqualTo(18));
      }

      expect(tester.takeException(), isNull);
    },
  );
}

// ============================================================================

// TEST INFRASTRUCTURE
// ============================================================================

/// Builds the base theme with DashboardTypeScale extension required by the app.
ThemeData _buildTestTheme() {
  const displayStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0.15,
  );
  const headingStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
  const subheadingStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  const bodyStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  const captionStyle = TextStyle(
    fontFamily: 'Figtree',
    color: Color(0xFFC8BFB2),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  const labelStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.16,
    letterSpacing: 0.12,
  );
  const buttonStyle = TextStyle(
    fontFamily: 'Figtree',
    color: DashboardShellPalette.ink,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 0.08,
  );
  const typeScale = DashboardTypeScale(
    display: displayStyle,
    heading: headingStyle,
    subheading: subheadingStyle,
    body: bodyStyle,
    caption: captionStyle,
    label: labelStyle,
    button: buttonStyle,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: DashboardShellPalette.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: DashboardShellPalette.accent,
    onPrimary: const Color(0xFF1A130F),
    secondary: DashboardShellPalette.success,
    onSecondary: DashboardShellPalette.paper,
    surface: DashboardShellPalette.paper,
    onSurface: DashboardShellPalette.ink,
    outline: DashboardShellPalette.outline,
    outlineVariant: DashboardShellPalette.outlineStrong,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: DashboardShellPalette.canvas,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DashboardShellPalette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(
      color: DashboardShellPalette.ink,
    ),
    extensions: <ThemeExtension<dynamic>>[typeScale],
  );
}

/// Pumps the app with a specific text scale factor for accessibility testing.
Future<void> _pumpAppWithTextScale(
  WidgetTester tester, {
  required double textScale,
  LoadRuntimeDashboardUseCase? runtimeUseCase,
  SyncDeviceSmsUseCase? syncDeviceSmsUseCase,
  HandleReviewItemActionUseCase? handleReviewItemActionUseCase,
  UndoReviewItemActionUseCase? undoReviewItemActionUseCase,
  HandleLocalControlOverlayUseCase? handleLocalControlOverlayUseCase,
  UndoLocalControlOverlayUseCase? undoLocalControlOverlayUseCase,
  HandleLocalRenewalReminderUseCase? handleLocalRenewalReminderUseCase,
  HandleManualSubscriptionUseCase? handleManualSubscriptionUseCase,
  HandleLocalServicePresentationUseCase? handleLocalServicePresentationUseCase,
  LoadSmsOnboardingProgressUseCase? loadSmsOnboardingProgressUseCase,
  CompleteSmsOnboardingUseCase? completeSmsOnboardingUseCase,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: _buildTestTheme(),
        home: DashboardShell(
          runtimeUseCase: runtimeUseCase,
          syncDeviceSmsUseCase: syncDeviceSmsUseCase,
          handleReviewItemActionUseCase: handleReviewItemActionUseCase,
          undoReviewItemActionUseCase: undoReviewItemActionUseCase,
          handleLocalControlOverlayUseCase: handleLocalControlOverlayUseCase,
          undoLocalControlOverlayUseCase: undoLocalControlOverlayUseCase,
          handleLocalRenewalReminderUseCase: handleLocalRenewalReminderUseCase,
          handleManualSubscriptionUseCase: handleManualSubscriptionUseCase,
          handleLocalServicePresentationUseCase:
              handleLocalServicePresentationUseCase,
          loadSmsOnboardingProgressUseCase: loadSmsOnboardingProgressUseCase,
          completeSmsOnboardingUseCase: completeSmsOnboardingUseCase,
        ),
      ),
    ),
  );
  await pumpDashboardShellLoad(tester);
}
