import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/ledger_snapshot_store.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/contracts/local_renewal_reminder_scheduler.dart';
import 'package:sub_killer/application/models/local_control_overlay_models.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/local_service_presentation_overlay_models.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'package:sub_killer/application/models/review_item_action_models.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_manual_subscription_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/use_cases/clear_all_local_data_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';

void main() {
  test('clear all local data removes persisted local state and cancels reminders',
      () async {
    final ledgerSnapshotStore = _MemoryLedgerSnapshotStore();
    final reviewActionStore = InMemoryReviewActionStore();
    final localControlOverlayStore = InMemoryLocalControlOverlayStore();
    final localManualSubscriptionStore = InMemoryLocalManualSubscriptionStore();
    final localRenewalReminderStore = InMemoryLocalRenewalReminderStore();
    final localServicePresentationOverlayStore =
        InMemoryLocalServicePresentationOverlayStore();
    final smsOnboardingProgressStore = InMemorySmsOnboardingProgressStore();
    final reminderScheduler = _RecordingReminderScheduler();

    await ledgerSnapshotStore.save(const <ServiceLedgerEntry>[]);
    await reviewActionStore.save(
      ReviewItemDecision(
        targetKey: 'NETFLIX',
        serviceKey: 'NETFLIX',
        title: 'Netflix',
        action: ReviewItemAction.confirmSubscription,
        decidedAt: DateTime(2026, 3, 20),
      ),
    );
    await localControlOverlayStore.save(
      LocalControlDecision(
        targetKey: 'service::NETFLIX',
        actionKind: LocalControlActionKind.ignore,
        targetKind: LocalControlTargetKind.service,
        title: 'Netflix',
        serviceKey: 'NETFLIX',
        bucketName: 'confirmedSubscriptions',
        decidedAt: DateTime(2026, 3, 20),
      ),
    );
    await localManualSubscriptionStore.save(
      ManualSubscriptionEntry(
        id: 'manual-netflix',
        serviceName: 'Netflix',
        billingCycle: ManualSubscriptionBillingCycle.monthly,
        createdAt: DateTime(2026, 3, 20),
        updatedAt: DateTime(2026, 3, 20),
      ),
    );
    await localRenewalReminderStore.save(
      const LocalRenewalReminderPreference(
        serviceKey: 'NETFLIX',
        leadTimePreset: RenewalReminderLeadTimePreset.threeDays,
      ),
    );
    await localServicePresentationOverlayStore.save(
      const LocalServicePresentationOverlay(
        serviceKey: 'NETFLIX',
        localLabel: 'Movie nights',
      ),
    );
    await smsOnboardingProgressStore.writeCompleted(true);

    final useCase = ClearAllLocalDataUseCase(
      ledgerSnapshotStore: ledgerSnapshotStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localRenewalReminderScheduler: reminderScheduler,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      smsOnboardingProgressStore: smsOnboardingProgressStore,
    );

    final result = await useCase.execute();

    expect(result.outcome, ClearAllLocalDataOutcome.cleared);
    expect(await ledgerSnapshotStore.hasSnapshot(), isFalse);
    expect(await reviewActionStore.list(), isEmpty);
    expect(await localControlOverlayStore.list(), isEmpty);
    expect(await localManualSubscriptionStore.list(), isEmpty);
    expect(await localRenewalReminderStore.list(), isEmpty);
    expect(await localServicePresentationOverlayStore.list(), isEmpty);
    expect(await smsOnboardingProgressStore.readCompleted(), isFalse);
    expect(reminderScheduler.cancelledServiceKeys, <String>['NETFLIX']);
  });
}

class _MemoryLedgerSnapshotStore implements LedgerSnapshotStore {
  LedgerSnapshotRecord? _record;

  @override
  Future<void> clear() async {
    _record = null;
  }

  @override
  Future<bool> hasSnapshot() async => _record != null;

  @override
  Future<List<ServiceLedgerEntry>> load() async {
    return _record?.entries ?? const <ServiceLedgerEntry>[];
  }

  @override
  Future<LedgerSnapshotRecord?> loadRecord() async => _record;

  @override
  Future<void> save(List<ServiceLedgerEntry> entries) async {
    _record = LedgerSnapshotRecord(entries: entries);
  }

  @override
  Future<void> saveRecord(LedgerSnapshotRecord record) async {
    _record = record;
  }
}

class _RecordingReminderScheduler implements LocalRenewalReminderScheduler {
  final List<String> cancelledServiceKeys = <String>[];

  @override
  Future<bool> cancel(String serviceKey) async {
    cancelledServiceKeys.add(serviceKey);
    return true;
  }

  @override
  Future<bool> schedule(LocalRenewalReminderScheduleRequest request) async {
    return true;
  }
}

