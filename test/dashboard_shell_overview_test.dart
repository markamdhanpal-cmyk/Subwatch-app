import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/contracts/problem_report_launcher.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

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

    expect(find.byKey(const ValueKey<String>('snapshot-certificate-card')),
        findsNothing);
    expect(find.text('SubWatch'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('totals-summary-card')),
        findsOneWidget);
    expect(find.text('Monthly spend'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-action-strip')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('product-guidance-panel')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('home-renewals-zone')),
        findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);

    await openDashboardDestination(tester, 'review');
    expect(find.text('Review'), findsWidgets);
    expect(
      find.descendant(
        of: reviewQueueSection,
        matching: find.text('Jiohotstar'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Looks recurring, but not confirmed yet.',
      ),
      findsOneWidget,
    );

    await openDashboardDestination(tester, 'subscriptions');
    final reviewSection = find.byKey(
      const ValueKey<String>('section-needsReview'),
    );
    await scrollDashboardUntilVisible(
      tester,
      find.text('Netflix'),
    );
    expect(reviewSection, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsWidgets,
    );
    expect(
      tester.getTopLeft(reviewSection).dy,
      lessThan(tester.getTopLeft(confirmedSection).dy),
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

  testWidgets('settings stays compact when nothing can be restored', (
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
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('destination-settings-surface'),

        ),
        matching: find.text('Settings'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-settings-recovery')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('settings-open-help')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings-open-about')),
      findsOneWidget,
    );
  });

  testWidgets('demo state opens the consolidated help sheet', (
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
      find.byKey(const ValueKey<String>('settings-open-help')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-help')),
    );

    expect(
      find.byKey(const ValueKey<String>('help-privacy-sheet')),
      findsOneWidget,
    );
    expect(find.text('Help & privacy'), findsWidgets);
    expect(find.text('Scans'), findsOneWidget);
    expect(find.text('Paid subscriptions'), findsOneWidget);
    expect(find.text('Review & benefits'), findsOneWidget);
  });

  testWidgets('report a problem opens the launcher path', (tester) async {
    final launcher = _FakeProblemReportLauncher();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardShell(
          runtimeUseCase: LoadRuntimeDashboardUseCase(
            clock: () => DateTime(2026, 3, 14, 9, 0),
          ),
          problemReportLauncher: launcher,
        ),
      ),
    );
    await pumpDashboardShellLoad(tester);

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-report-problem')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-report-problem')),
    );

    expect(launcher.openCount, 1);
    expect(launcher.lastSubject, 'SubWatch problem report');
    expect(launcher.lastBody, contains('Issue summary:'));
    expect(launcher.lastBody, contains('Visible state:'));
  });

  testWidgets('review explanation clarifies why an item stays separate', (
    tester,
  ) async {
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
      findsOneWidget,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.text('Why SubWatch flagged this'),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('review-evidence-panel')),
    );
    expect(find.text('What we saw'), findsWidgets);
    expect(find.text('Why it stays separate'), findsOneWidget);
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

    expect(find.text('Your view is not ready yet.'), findsOneWidget);
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

    expect(find.text('Your view is not ready yet.'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('retry-load-dashboard')),
      findsNothing,
    );
  });
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

class _FakeProblemReportLauncher implements ProblemReportLauncher {
  int openCount = 0;
  String? lastRecipient;
  String? lastSubject;
  String? lastBody;

  @override
  Future<bool> open({
    required String recipient,
    required String subject,
    required String body,
  }) async {
    openCount += 1;
    lastRecipient = recipient;
    lastSubject = subject;
    lastBody = body;
    return true;
  }
}






