import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/message_sources/sample_local_message_source.dart';
import 'package:sub_killer/application/models/dashboard_completion_presentation.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/local_service_presentation_overlay_models.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_totals_summary_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/select_local_message_source_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  const useCase = BuildDashboardTotalsSummaryUseCase();

  test(
    'totals build a partial monthly estimate from visible confirmed amounts',
    () {
      final summary = useCase.execute(
        cards: <DashboardCard>[
          _card(
            key: 'NETFLIX',
            bucket: DashboardBucket.confirmedSubscriptions,
            state: ResolverState.activePaid,
            subtitle: 'Confirmed paid subscription - Rs 499',
          ),
          _card(
            key: 'YOUTUBE',
            bucket: DashboardBucket.confirmedSubscriptions,
            state: ResolverState.activePaid,
            subtitle: 'Confirmed paid subscription',
          ),
          _card(
            key: 'JIOHOTSTAR',
            bucket: DashboardBucket.needsReview,
            state: ResolverState.possibleSubscription,
            subtitle: 'Needs confirmation - Rs 149',
          ),
        ],
      );

      expect(summary.activePaidCount, 2);
      expect(summary.reviewCount, 1);
      expect(summary.includedInMonthlyTotalCount, 1);
      expect(summary.excludedWithoutTrustedAmountCount, 1);
      expect(summary.monthlyTotalAmount, 499);
      expect(summary.estimateBadgeLabel, 'Partial estimate');
      expect(
        summary.summaryCopy,
        'Estimate excludes subscriptions without a visible amount.',
      );
    },
  );

  test('totals convert annual, quarterly, and yearly manual values monthly',
      () {
    final summary = useCase.execute(
      cards: <DashboardCard>[
        _card(
          key: 'ANNUAL',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription - Annual plan - Rs 1,200',
        ),
        _card(
          key: 'QUARTERLY',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription - Quarterly - Rs 300',
        ),
        _card(
          key: 'MONTHLY',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription - Monthly - Rs 150',
        ),
      ],
      manualSubscriptions: <ManualSubscriptionEntry>[
        ManualSubscriptionEntry(
          id: 'manual-yearly',
          serviceName: 'Prime Lite',
          amountInMinorUnits: 120000,
          billingCycle: ManualSubscriptionBillingCycle.yearly,
          createdAt: DateTime(2026, 3, 14, 9, 0),
          updatedAt: DateTime(2026, 3, 14, 9, 0),
        ),
      ],
    );

    expect(summary.activePaidCount, 3);
    expect(summary.includedInMonthlyTotalCount, 3);
    expect(summary.manualEntriesIncludedCount, 1);
    expect(summary.cadenceConvertedCount, 3);
    expect(summary.monthlyTotalAmount, 450);
    expect(
      summary.summaryCopy,
      'Annual or quarterly plans are shown as monthly equivalents here.',
    );
  });

  test('totals stay honest when no trusted billed amount is visible', () {
    final summary = useCase.execute(
      cards: <DashboardCard>[
        _card(
          key: 'NETFLIX',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription',
        ),
      ],
    );

    expect(summary.showSummary, isTrue);
    expect(summary.activePaidCount, 1);
    expect(summary.includedInMonthlyTotalCount, 0);
    expect(summary.monthlyTotalValueLabel, 'Amount not available yet');
    expect(summary.estimateBadgeLabel, 'Amount pending');
    expect(
      summary.monthlyTotalCaption,
      'Shown when a billed or manual amount is available',
    );
  });

  test(
    'totals review count follows surfaced review items when unresolved signals stay out of Review',
    () {
      final summary = useCase.execute(
        cards: <DashboardCard>[
          _card(
            key: 'UNRESOLVED',
            bucket: DashboardBucket.needsReview,
            state: ResolverState.possibleSubscription,
            subtitle: 'Needs confirmation',
          ),
          _card(
            key: 'AIRTEL_GEMINI',
            bucket: DashboardBucket.trialsAndBenefits,
            state: ResolverState.activeBundled,
            subtitle: 'Bundled benefit',
          ),
        ],
        reviewCount: 0,
      );

      expect(summary.reviewCount, 0);
      expect(summary.reviewValueLabel, '0');
    },
  );

  testWidgets('dashboard renders the top home spend summary and explainer', (
    tester,
  ) async {
    final runtimeUseCase = LoadRuntimeDashboardUseCase(
      capabilityProvider: MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      ),
      deviceSmsGateway: FakeDeviceSmsGateway(
        <RawDeviceSms>[
          RawDeviceSms(
            id: 'sms-1',
            address: 'NETFLIX',
            body: 'Your Netflix subscription has been renewed for Rs 499.',
            receivedAt: DateTime(2026, 3, 14, 8, 0),
          ),
        ],
      ),
      loadMode: RuntimeLedgerLoadMode.refreshFromSource,
      clock: () => DateTime(2026, 3, 14, 9, 0),
    );

    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: runtimeUseCase,
    );

    expect(
      find.byKey(const ValueKey<String>('totals-summary-card')),
      findsOneWidget,
    );
    expect(find.text('What SubWatch found'), findsOneWidget);
    expect(find.text('Monthly spend estimate'), findsOneWidget);
    expect(find.text('Rs 499'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Needs review'), findsWidgets);
    expect(find.text('Current view'), findsOneWidget);
    expect(find.text('How totals work'), findsOneWidget);

    // Accessibility: Verify information button has a descriptive semantics label
    final infoButton =
        find.byKey(const ValueKey<String>('open-totals-explanation-button'));
    expect(infoButton, findsOneWidget);

    final SemanticsHandle handle = tester.ensureSemantics();
    // Ensure the button is accessible to screen readers with a clear purpose
    expect(find.bySemanticsLabel('Open spend estimate explanation'),
        findsOneWidget);

    await tapAndPumpDashboardShell(
      tester,
      infoButton,
    );
    handle.dispose();

    expect(
      find.byKey(const ValueKey<String>('totals-explanation-sheet')),
      findsOneWidget,
    );
    expect(find.text('What totals include'), findsOneWidget);
    expect(
      find.text(
        'Only confirmed paid subscriptions with visible amounts are counted automatically.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Annual and quarterly amounts are converted into monthly equivalents.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'This is an estimated subscription view, not an exact bank-spend dashboard.',
      ),
      findsOneWidget,
    );
  });

  test(
    'completion copy follows surfaced review items when unresolved signals stay out of Review',
    () {
      final snapshot = RuntimeDashboardSnapshot(
        cards: <DashboardCard>[
          _card(
            key: 'UNRESOLVED',
            bucket: DashboardBucket.needsReview,
            state: ResolverState.possibleSubscription,
            subtitle: 'Needs confirmation',
          ),
          _card(
            key: 'AIRTEL_GEMINI',
            bucket: DashboardBucket.trialsAndBenefits,
            state: ResolverState.activeBundled,
            subtitle: 'Bundled benefit',
          ),
        ],
        reviewQueue: const [],
        messageSourceSelection: LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.freshLoad,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 14, 9, 0),
          refreshedAt: DateTime(2026, 3, 14, 9, 0),
        ),
        confirmedReviewItems: const [],
        benefitReviewItems: const [],
        dismissedReviewItems: const [],
        ignoredLocalItems: const [],
        hiddenLocalItems: const [],
        manualSubscriptions: const [],
        localServicePresentationStates: const <String, LocalServicePresentationState>{},
        localRenewalReminderPreferences: const <String, LocalRenewalReminderPreference>{},
      );

      final presentation = DashboardCompletionPresentation.fromSnapshot(
        snapshot,
      );

      expect(presentation.title, 'No paid subscriptions confirmed yet');
      expect(
        presentation.description,
        'SubWatch found access or benefit signals, but nothing strong enough to confirm as a paid subscription yet.',
      );
    },
  );
}

DashboardCard _card({
  required String key,
  required DashboardBucket bucket,
  required ResolverState state,
  required String subtitle,
}) {
  return DashboardCard(
    serviceKey: ServiceKey(key),
    bucket: bucket,
    title: key,
    subtitle: subtitle,
    state: state,
  );
}
