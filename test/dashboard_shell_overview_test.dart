import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/app/subscription_killer_app.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/contracts/problem_report_launcher.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('confirmed subscriptions render separately from review items', (
    tester,
  ) async {
    await pumpConstrainedDashboardShell(
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
    expect(find.text('Monthly spend estimate'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('home-action-strip')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('home-renewals-zone')),
        findsOneWidget);
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('home-trust-row')),
    );
    expect(find.byKey(const ValueKey<String>('home-trust-row')),
        findsOneWidget);
    expect(find.text('Sample preview'), findsWidgets);

    await openDashboardDestination(tester, 'review');
    expect(find.text('Review'), findsWidgets);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'JioHotstar\. The signals conflict, so this still needs your review\. Review actions below\.',
          ),
        ),
        findsOneWidget,
      );
    expect(find.textContaining('The signals conflict'), findsOneWidget);

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
      tester.getTopLeft(confirmedSection).dy,
      lessThan(tester.getTopLeft(reviewSection).dy),
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
    await pumpConstrainedDashboardShell(
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
    expect(
      find.byKey(const ValueKey<String>('settings-trust-panel')),
      findsOneWidget,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
    );
    expect(
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-open-privacy')),
      findsOneWidget,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-about')),
    );
    expect(
      find.byKey(const ValueKey<String>('settings-open-about')),
      findsOneWidget,
    );
  });

  testWidgets('settings opens the how SubWatch works sheet', (
    tester,
  ) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('settings-open-how-it-works')),
    );

    expect(
      find.byKey(const ValueKey<String>('how-subwatch-works-sheet')),
      findsOneWidget,
    );
    expect(find.text('How SubWatch works'), findsWidgets);
    expect(find.text('Paid subscriptions'), findsOneWidget);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Included with your plan'), findsOneWidget);
  });

  testWidgets('report a problem opens the launcher path', (tester) async {
    final launcher = _FakeProblemReportLauncher();

    await tester.pumpWidget(
      SubKillerApp(
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 0),
        ),
        problemReportLauncher: launcher,
        loadSmsOnboardingProgressUseCase: LoadSmsOnboardingProgressUseCase(
          store: InMemorySmsOnboardingProgressStore()..writeCompleted(true),
        ),
        completeSmsOnboardingUseCase: CompleteSmsOnboardingUseCase(
          store: InMemorySmsOnboardingProgressStore()..writeCompleted(true),
        ),
        textScaler: const TextScaler.linear(1.0),
      ),
    );
    await pumpDashboardShellLoad(tester);

    await openDashboardDestination(tester, 'settings');
    final reportProblemFinder =
        find.byKey(const ValueKey<String>('settings-report-problem'));
    await scrollDashboardUntilVisible(
      tester,
      reportProblemFinder,
    );
    await tester.ensureVisible(reportProblemFinder);
    final reportProblemRow = tester.widget<InkWell>(reportProblemFinder);
    reportProblemRow.onTap!.call();
    await pumpDashboardShellUi(tester);

    expect(launcher.openCount, 1);
    expect(launcher.lastSubject, 'SubWatch problem report');
    expect(launcher.lastBody, contains('Issue summary:'));
    expect(launcher.lastBody, contains('Visible state:'));
  });

  testWidgets('review explanation clarifies why an item stays separate', (
    tester,
  ) async {
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

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: harness.runtimeUseCase,
      handleReviewItemActionUseCase: harness.handleReviewItemActionUseCase,
      undoReviewItemActionUseCase: harness.undoReviewItemActionUseCase,
    );

    await openDashboardDestination(tester, 'review');
    final reviewDetailsFinder =
        find.byKey(const ValueKey<String>('open-review-details-JIOHOTSTAR'));
    await scrollDashboardUntilVisible(
      tester,
      reviewDetailsFinder,
    );
    await tapAndPumpDashboardShell(
      tester,
      reviewDetailsFinder.first,
    );
    await pumpDashboardShellUi(tester);

    expect(find.text('Why SubWatch flagged this'), findsOneWidget);
    await tapAndPumpDashboardShell(
      tester,
      find.text('Why SubWatch flagged this'),
    );
    expect(find.textContaining('wording that suggests recurring access'), findsNothing);
    expect(find.textContaining('signals point in different directions'), findsOneWidget);
    expect(
      find.textContaining('signals that do not agree with each other'),
      findsOneWidget,
    );
  });

  testWidgets('load error offers a retry path back into the dashboard', (
    tester,
  ) async {
    final gateway = _FlakyGateway();

    await pumpConstrainedDashboardShell(
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

