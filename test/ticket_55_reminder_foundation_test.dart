import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/dashboard_upcoming_renewals_presentation.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_renewal_reminder_items_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/project_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/project_review_queue_use_case.dart';
import 'package:sub_killer/domain/contracts/dashboard_projection.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/entities/review_item.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  final now = DateTime(2026, 3, 14, 9);

  test(
      'reminder presentation keeps only safe lead times and expired selections stay honest',
      () {
    final useCase = BuildDashboardRenewalReminderItemsUseCase(
      clock: () => now,
    );

    final result = useCase.execute(
      upcomingRenewals: DashboardUpcomingRenewalsPresentation(
        items: <DashboardUpcomingRenewalItemPresentation>[
          DashboardUpcomingRenewalItemPresentation(
            serviceKey: 'NETFLIX',
            serviceTitle: 'Netflix',
            renewalDate: DateTime(2026, 3, 20),
            renewalDateLabel: '20 Mar 2026',
            amountLabel: 'Rs 499',
          ),
          DashboardUpcomingRenewalItemPresentation(
            serviceKey: 'ADOBE',
            serviceTitle: 'Adobe',
            renewalDate: DateTime(2026, 3, 15),
            renewalDateLabel: '15 Mar 2026',
          ),
        ],
      ),
      preferencesByServiceKey: const <String, LocalRenewalReminderPreference>{
        'ADOBE': LocalRenewalReminderPreference(
          serviceKey: 'ADOBE',
          leadTimePreset: RenewalReminderLeadTimePreset.threeDays,
        ),
      },
    );

    expect(
      result.first.availablePresets,
      <RenewalReminderLeadTimePreset>[
        RenewalReminderLeadTimePreset.oneDay,
        RenewalReminderLeadTimePreset.threeDays,
      ],
    );
    expect(result.first.statusLabel, 'Reminder off');
    expect(result.first.canConfigureReminder, isTrue);

    expect(result.last.availablePresets, isEmpty);
    expect(result.last.selectedPreset, RenewalReminderLeadTimePreset.threeDays);
    expect(result.last.statusLabel, 'Reminder not scheduled for this cycle');
    expect(result.last.canConfigureReminder, isTrue);
  });

  testWidgets(
    'settings owns reminder controls while home stays summary-only for renewals',
    (tester) async {
      final reminderStore = InMemoryLocalRenewalReminderStore();
      await reminderStore.save(
        const LocalRenewalReminderPreference(
          serviceKey: 'NETFLIX',
          leadTimePreset: RenewalReminderLeadTimePreset.threeDays,
        ),
      );
      final repository = InMemoryLedgerRepository();
      final projection = _StaticDashboardProjection(
        cards: <DashboardCard>[
          DashboardCard(
            serviceKey: const ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle:
                'Confirmed paid subscription - Renews on 20 Mar 2026 - Rs 499',
            state: ResolverState.activePaid,
          ),
        ],
      );
      final runtimeUseCase = LoadRuntimeDashboardUseCase(
        capabilityProvider: MutableCapabilityProvider(
          initialState: LocalMessageSourceAccessState.deviceLocalAvailable,
          requestResult: LocalMessageSourceAccessRequestResult.granted,
          refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ledgerRepository: repository,
        localRenewalReminderStore: reminderStore,
        projectDashboardUseCase: ProjectDashboardUseCase(
          ledgerRepository: repository,
          dashboardProjection: projection,
        ),
        projectReviewQueueUseCase: ProjectReviewQueueUseCase(
          ledgerRepository: repository,
          dashboardProjection: projection,
        ),
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
        clock: () => now,
      );

      await pumpDashboardShellApp(
        tester,
        runtimeUseCase: runtimeUseCase,
      );

      await scrollDashboardUntilVisible(
        tester,
        find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      );

      expect(find.textContaining('3 days before'), findsWidgets);
      expect(
        find
            .byKey(
              const ValueKey<String>('open-renewal-reminder-controls-NETFLIX'),
            )
            .hitTestable(),
        findsNothing,
      );

      await openDashboardDestination(tester, 'settings');
      await scrollDashboardUntilVisible(
        tester,
        find.byKey(
          const ValueKey<String>('settings-renewal-reminder-NETFLIX'),
        ),
      );

      expect(find.text('Reminders'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('settings-renewal-reminder-NETFLIX'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('3 days before'), findsWidgets);

      await tapAndPumpDashboardShell(
        tester,
        find.byKey(
          const ValueKey<String>('open-renewal-reminder-controls-NETFLIX'),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('renewal-reminder-controls-sheet-NETFLIX'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('enable-reminder-NETFLIX-oneDay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('enable-reminder-NETFLIX-threeDays')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('enable-reminder-NETFLIX-sevenDays')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('disable-reminder-NETFLIX')),
        findsOneWidget,
      );
    },
  );
}

class _StaticDashboardProjection implements DashboardProjection {
  const _StaticDashboardProjection({
    required this.cards,
  });

  final List<DashboardCard> cards;

  @override
  List<DashboardCard> buildCards(Iterable<ServiceLedgerEntry> entries) => cards;

  @override
  List<ReviewItem> buildReviewQueue(Iterable<ServiceLedgerEntry> entries) {
    return const <ReviewItem>[];
  }
}
