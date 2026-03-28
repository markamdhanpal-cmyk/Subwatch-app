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
        final harness = DashboardShellReviewHarness(
          deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
            RawDeviceSms(
              id: 'confirmed-netflix',
              address: 'NETFLIX',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 10, 0),
            ),
            RawDeviceSms(
              id: 'review-jiohotstar',
              address: 'JIOHOTSTAR',
              body: 'Your Jiohotstar subscription may renew shortly.',
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

        await openDashboardDestination(tester, 'subscriptions');
        await scrollDashboardUntilVisible(tester, find.text('Netflix'));

        expect(find.byTooltip('More actions for Netflix'), findsOneWidget);
        final netflixSemantics = tester.getSemantics(
          find.byKey(const ValueKey<String>('subscription-row-semantics-NETFLIX')),
        );
        expect(netflixSemantics.label, contains('Netflix'));
        expect(netflixSemantics.label, contains('Confirmed'));
        expect(netflixSemantics.label, contains('499'));
        expect(netflixSemantics.label, contains('Double tap for details'));

        await openDashboardDestination(tester, 'review');
        await scrollDashboardUntilVisible(tester, find.text('Jiohotstar'));

        expect(
          find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR')),
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

        await pumpConstrainedDashboardShell(
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
          find.byKey(ValueKey<String>('manual-row-semantics-${manualEntry.id}')),
        );
        expect(rowSemantics.label, contains(manualServiceName));
        expect(rowSemantics.label, contains('Added by you'));
        expect(rowSemantics.label, contains('1499'));
        expect(rowSemantics.label, contains('Yearly'));
        expect(rowSemantics.label, contains('Double tap for details'));

        await tapAndPumpDashboardShell(
          tester,
          find.text(manualServiceName).first,
        );

        expect(
          find.bySemanticsLabel(
              'Edit subscription you added for $manualServiceName'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
              'Remove subscription you added for $manualServiceName'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Set a reminder for $manualServiceName'),
          findsOneWidget,
        );
      } finally {
        handle.dispose();
      }
  });

  testWidgets('error recovery retry action has a clear semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpConstrainedDashboardShell(
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

  testWidgets('settings rows expose merged trust and support semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
      );

      await openDashboardDestination(tester, 'settings');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('settings-open-about')),
      );

      expect(
        find.bySemanticsLabel(
          'Private on this phone. Your messages are checked on-device.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('How SubWatch works.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Privacy.'),
        findsOneWidget,
      );
      final aboutSemantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('settings-open-about')),
      );
      expect(aboutSemantics.label, contains('About SubWatch'));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('overflow and close controls keep safe tap target sizes', (
    tester,
  ) async {
    final harness = DashboardShellReviewHarness(
      deviceSmsGateway: FakeDeviceSmsGateway(<RawDeviceSms>[
        RawDeviceSms(
          id: 'confirmed-netflix',
          address: 'NETFLIX',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2026, 3, 12, 10, 0),
        ),
      ]),
    );

    await pumpConstrainedDashboardShell(
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
