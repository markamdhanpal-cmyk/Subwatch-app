import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/app/subscription_killer_app.dart';
import 'package:sub_killer/application/contracts/ledger_snapshot_store.dart';
import 'package:sub_killer/application/models/local_control_overlay_models.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
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
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('settings offers a confirmed clear-all-data flow',
      (tester) async {
    final ledgerSnapshotStore = _MemoryLedgerSnapshotStore();
    final reviewActionStore = InMemoryReviewActionStore();
    final localControlOverlayStore = InMemoryLocalControlOverlayStore();
    final localManualSubscriptionStore = InMemoryLocalManualSubscriptionStore();
    final localRenewalReminderStore = InMemoryLocalRenewalReminderStore();
    final localServicePresentationOverlayStore =
        InMemoryLocalServicePresentationOverlayStore();
    final smsOnboardingProgressStore = InMemorySmsOnboardingProgressStore();

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

    final runtimeUseCase = LoadRuntimeDashboardUseCase(
      ledgerSnapshotStore: ledgerSnapshotStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      clock: () => DateTime(2026, 3, 20, 9),
    );
    final clearAllLocalDataUseCase = ClearAllLocalDataUseCase(
      ledgerSnapshotStore: ledgerSnapshotStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localRenewalReminderScheduler: const NoOpLocalRenewalReminderScheduler(),
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      smsOnboardingProgressStore: smsOnboardingProgressStore,
    );

    await tester.pumpWidget(
      SubKillerApp(
        runtimeUseCase: runtimeUseCase,
        clearAllLocalDataUseCase: clearAllLocalDataUseCase,
        loadSmsOnboardingProgressUseCase:
            LoadSmsOnboardingProgressUseCase(store: smsOnboardingProgressStore),
        completeSmsOnboardingUseCase:
            CompleteSmsOnboardingUseCase(store: smsOnboardingProgressStore),
        textScaler: const TextScaler.linear(1.0),
      ),
    );
    await pumpDashboardShellLoad(tester);

    await openDashboardDestination(tester, 'settings');
    final clearAllLabel = find.descendant(
      of: find.byKey(const ValueKey<String>('settings-clear-all-data')),
      matching: find.text('Clear all data'),
    );
    await scrollDashboardUntilVisible(
      tester,
      clearAllLabel,
    );
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -160),
    );
    await pumpDashboardShellUi(tester);
    await tester.ensureVisible(clearAllLabel);
    await tester.tap(clearAllLabel);
    await pumpDashboardShellUi(tester);

    expect(find.text('Clear all data?'), findsOneWidget);
    expect(
      find.text(
        'This removes saved subscriptions, review decisions, reminders, and labels from this phone.',
      ),
      findsOneWidget,
    );

    await tapAndPumpDashboardShell(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Clear all data'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Local data cleared from this phone.'), findsOneWidget);
    expect(await reviewActionStore.list(), isEmpty);
    expect(await localControlOverlayStore.list(), isEmpty);
    expect(await localManualSubscriptionStore.list(), isEmpty);
    expect(await localRenewalReminderStore.list(), isEmpty);
    expect(await localServicePresentationOverlayStore.list(), isEmpty);
    expect(await smsOnboardingProgressStore.readCompleted(), isFalse);
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
