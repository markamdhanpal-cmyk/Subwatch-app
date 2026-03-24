import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/local_renewal_reminder_scheduler.dart';
import 'package:sub_killer/application/message_sources/sample_local_message_source.dart';
import 'package:sub_killer/application/models/dashboard_renewal_reminder_presentation.dart';
import 'package:sub_killer/application/models/dashboard_upcoming_renewals_presentation.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/use_cases/handle_local_renewal_reminder_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/select_local_message_source_use_case.dart';

void main() {
  final now = DateTime(2026, 3, 14, 9);

  test('enable reminder persists preference and schedules a local reminder',
      () async {
    final store = InMemoryLocalRenewalReminderStore();
    final scheduler = _FakeLocalRenewalReminderScheduler();
    var reloadCount = 0;
    final useCase = HandleLocalRenewalReminderUseCase(
      localRenewalReminderStore: store,
      localRenewalReminderScheduler: scheduler,
      loadRuntimeDashboard: () async {
        reloadCount += 1;
        return _snapshot(now);
      },
      clock: () => now,
    );

    final result = await useCase.enableReminder(
      item: _item(
        renewalDate: DateTime(2026, 3, 20),
        availablePresets: const <RenewalReminderLeadTimePreset>[
          RenewalReminderLeadTimePreset.oneDay,
          RenewalReminderLeadTimePreset.threeDays,
        ],
      ),
      leadTimePreset: RenewalReminderLeadTimePreset.threeDays,
    );

    expect(result.outcome, LocalRenewalReminderOutcome.enabled);
    expect(reloadCount, 1);
    expect(scheduler.scheduledRequests, hasLength(1));
    expect(scheduler.scheduledRequests.single.serviceKey, 'NETFLIX');
    expect(
      scheduler.scheduledRequests.single.scheduledAt,
      DateTime(2026, 3, 17, 9),
    );

    final preferences = await store.list();
    expect(preferences, hasLength(1));
    expect(
      preferences.single.leadTimePreset,
      RenewalReminderLeadTimePreset.threeDays,
    );
  });

  test('enable reminder fails when the preset is not safe for the renewal',
      () async {
    final scheduler = _FakeLocalRenewalReminderScheduler();
    final useCase = HandleLocalRenewalReminderUseCase(
      localRenewalReminderStore: InMemoryLocalRenewalReminderStore(),
      localRenewalReminderScheduler: scheduler,
      loadRuntimeDashboard: () async => _snapshot(now),
      clock: () => now,
    );

    final result = await useCase.enableReminder(
      item: _item(
        renewalDate: DateTime(2026, 3, 20),
        availablePresets: const <RenewalReminderLeadTimePreset>[
          RenewalReminderLeadTimePreset.oneDay,
        ],
      ),
      leadTimePreset: RenewalReminderLeadTimePreset.sevenDays,
    );

    expect(result.outcome, LocalRenewalReminderOutcome.failed);
    expect(scheduler.scheduledRequests, isEmpty);
  });

  test('disable reminder cancels the local reminder and removes the preference',
      () async {
    final store = InMemoryLocalRenewalReminderStore();
    await store.save(
      const LocalRenewalReminderPreference(
        serviceKey: 'NETFLIX',
        leadTimePreset: RenewalReminderLeadTimePreset.oneDay,
      ),
    );
    final scheduler = _FakeLocalRenewalReminderScheduler();
    var reloadCount = 0;
    final useCase = HandleLocalRenewalReminderUseCase(
      localRenewalReminderStore: store,
      localRenewalReminderScheduler: scheduler,
      loadRuntimeDashboard: () async {
        reloadCount += 1;
        return _snapshot(now);
      },
      clock: () => now,
    );

    final result = await useCase.disableReminder(serviceKey: 'NETFLIX');

    expect(result.outcome, LocalRenewalReminderOutcome.disabled);
    expect(reloadCount, 1);
    expect(scheduler.cancelledServiceKeys, <String>['NETFLIX']);
    expect(await store.list(), isEmpty);
  });
}

DashboardRenewalReminderItemPresentation _item({
  required DateTime renewalDate,
  required List<RenewalReminderLeadTimePreset> availablePresets,
  RenewalReminderLeadTimePreset? selectedPreset,
}) {
  return DashboardRenewalReminderItemPresentation(
    renewal: DashboardUpcomingRenewalItemPresentation(
      serviceKey: 'NETFLIX',
      serviceTitle: 'Netflix',
      renewalDate: renewalDate,
      renewalDateLabel: '20 Mar 2026',
      amountLabel: '\u20B9499',
    ),
    availablePresets: availablePresets,
    selectedPreset: selectedPreset,
    statusLabel: 'Reminder off',
    canConfigureReminder: true,
  );
}

RuntimeDashboardSnapshot _snapshot(DateTime recordedAt) {
  return RuntimeDashboardSnapshot(
    cards: const [],
    reviewQueue: const [],
    messageSourceSelection: const LocalMessageSourceSelection(
      accessState: LocalMessageSourceAccessState.sampleDemo,
      resolution: LocalMessageSourceResolution.sampleLocal,
      messageSource: SampleLocalMessageSource(),
    ),
    provenance: RuntimeSnapshotProvenance(
      kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
      sourceKind: RuntimeSnapshotSourceKind.sampleDemo,
      recordedAt: recordedAt,
      refreshedAt: recordedAt,
    ),
    confirmedReviewItems: const [],
    benefitReviewItems: const [],
    dismissedReviewItems: const [],
    ignoredLocalItems: const [],
    hiddenLocalItems: const [],
    manualSubscriptions: const [],
    localServicePresentationStates: const {},
    localRenewalReminderPreferences: const {},
  );
}

class _FakeLocalRenewalReminderScheduler
    implements LocalRenewalReminderScheduler {
  final List<LocalRenewalReminderScheduleRequest> scheduledRequests =
      <LocalRenewalReminderScheduleRequest>[];
  final List<String> cancelledServiceKeys = <String>[];

  @override
  Future<bool> schedule(LocalRenewalReminderScheduleRequest request) async {
    scheduledRequests.add(request);
    return true;
  }

  @override
  Future<bool> cancel(String serviceKey) async {
    cancelledServiceKeys.add(serviceKey);
    return true;
  }
}


