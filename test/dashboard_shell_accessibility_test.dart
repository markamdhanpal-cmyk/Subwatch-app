import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets(
    'subscription and review rows expose concise summaries and contextual more labels',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final harness = DashboardShellReviewHarness();

        await pumpDashboardShellApp(
          tester,
          runtimeUseCase: harness.runtimeUseCase,
          handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
          undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
        );

        await openDashboardDestination(tester, 'subscriptions');
        await scrollDashboardUntilVisible(tester, find.text('Netflix'));

        expect(find.byTooltip('More actions for Netflix'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(
              'Netflix\\. Confirmed\\. Amount \\u20B9499\\. Cycle not clear yet\\. Double tap for details\\.',
            ),
          ),
          findsOneWidget,
        );


        await scrollDashboardUntilVisible(
            tester, find.text('Google Gemini Pro'));
        expect(
          find.bySemanticsLabel(
            RegExp(
              r'Google Gemini Pro\. Separate access\. Bundled with another plan - no separate charge\. Double tap for details\.',
            ),
          ),
          findsOneWidget,
        );


        await openDashboardDestination(tester, 'review');
        await scrollDashboardUntilVisible(tester, find.text('Jiohotstar'));

        expect(find.byTooltip('More actions for Jiohotstar'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(
              r'Jiohotstar\. Needs your review\. Looks recurring, but not confirmed yet\. Double tap for details\.',
            ),
          ),
          findsOneWidget,
        );

      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'manual rows and bottom-sheet actions expose contextual labels',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final harness = DashboardShellReviewHarness();
        const manualServiceName = 'Disney+ Hotstar Family Annual Plan';

        await harness.handleManualSubscriptionUseCase.create(
          serviceName: manualServiceName,
          billingCycle: ManualSubscriptionBillingCycle.yearly,
          amountInput: '1499',
          nextRenewalDate: DateTime(2026, 4, 14),
          planLabel: 'Premium yearly',
        );
        final manualEntry =
            (await harness.localManualSubscriptionStore.list()).single;

        await pumpDashboardShellApp(
          tester,
          runtimeUseCase: harness.runtimeUseCase,
          handleManualSubscriptionUseCase:
              harness.handleManualSubscriptionUseCase,
        );

        await openDashboardDestination(tester, 'subscriptions');
        await scrollDashboardUntilVisible(tester, find.text(manualServiceName));

        expect(
          find.byTooltip('More actions for $manualServiceName'),
          findsOneWidget,
        );
        final rowSemantics = tester.getSemantics(
          find.byKey(
              ValueKey<String>('manual-row-semantics-${manualEntry.id}')),
        );
        expect(rowSemantics.label, contains(manualServiceName));

        expect(rowSemantics.label, contains('Added by you'));
        expect(rowSemantics.label, contains('Amount \u20B91,499'));
        expect(rowSemantics.label, contains('Yearly'));
        expect(rowSemantics.label, contains('Double tap for details'));


        await tapAndPumpDashboardShell(
          tester,
          find.text(manualServiceName).first,
        );

        expect(
          find.bySemanticsLabel('Edit manual entry for $manualServiceName'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Remove manual entry for $manualServiceName'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Set a local reminder for $manualServiceName'),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets('home action button exposes a clean semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('sync-with-sms-button')),
      );

      expect(semantics.label, contains('Scan your messages'));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('error recovery retry action has a clear semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _AlwaysThrowingGateway(),
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      expect(
        find.bySemanticsLabel('Try again to open your saved view'),
        findsOneWidget,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('settings rows expose merged support semantics', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'settings');

      expect(
        find.bySemanticsLabel(
          'Help & privacy. What stays local. How scans work..',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'About SubWatch. What SubWatch tracks..',
        ),
        findsOneWidget,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('overflow and close controls keep safe tap target sizes', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness();

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(tester, find.text('Netflix'));

    final overflowButton = find.byTooltip('More actions for Netflix');
    final overflowSize = tester.getSize(overflowButton);
    expect(overflowSize.width, greaterThanOrEqualTo(48));
    expect(overflowSize.height, greaterThanOrEqualTo(48));

    await tapAndPumpDashboardShell(tester, find.text('Netflix').first);

    final closeButton = find.byTooltip('Close').first;
    final closeSize = tester.getSize(closeButton);
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
  });
}

class _AlwaysThrowingGateway implements DeviceSmsGateway {
  @override
  Future<List<RawDeviceSms>> readMessages() async {
    throw Exception('still broken');
  }
}







