import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../contracts/local_manual_subscription_store.dart';
import '../contracts/local_renewal_reminder_scheduler.dart';
import '../contracts/local_renewal_reminder_store.dart';
import '../contracts/local_service_presentation_overlay_store.dart';
import '../contracts/review_action_store.dart';
import '../contracts/sms_onboarding_progress_store.dart';
import '../gateways/android_local_renewal_reminder_scheduler.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import '../stores/json_file_local_manual_subscription_store.dart';
import '../stores/json_file_local_renewal_reminder_store.dart';
import '../stores/json_file_local_service_presentation_overlay_store.dart';
import '../stores/json_file_review_action_store.dart';
import '../stores/json_file_sms_onboarding_progress_store.dart';

enum ClearAllLocalDataOutcome {
  cleared,
  clearedWithReminderWarning,
}

class ClearAllLocalDataResult {
  const ClearAllLocalDataResult({
    required this.outcome,
  });

  final ClearAllLocalDataOutcome outcome;
}

class ClearAllLocalDataUseCase {
  factory ClearAllLocalDataUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalRenewalReminderScheduler? localRenewalReminderScheduler,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    SmsOnboardingProgressStore? smsOnboardingProgressStore,
  }) {
    return ClearAllLocalDataUseCase(
      ledgerSnapshotStore:
          ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport(),
      reviewActionStore:
          reviewActionStore ?? JsonFileReviewActionStore.applicationSupport(),
      localControlOverlayStore: localControlOverlayStore ??
          JsonFileLocalControlOverlayStore.applicationSupport(),
      localManualSubscriptionStore: localManualSubscriptionStore ??
          JsonFileLocalManualSubscriptionStore.applicationSupport(),
      localRenewalReminderStore: localRenewalReminderStore ??
          JsonFileLocalRenewalReminderStore.applicationSupport(),
      localRenewalReminderScheduler:
          localRenewalReminderScheduler ??
              const AndroidLocalRenewalReminderScheduler(),
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore ??
              JsonFileLocalServicePresentationOverlayStore.applicationSupport(),
      smsOnboardingProgressStore: smsOnboardingProgressStore ??
          JsonFileSmsOnboardingProgressStore.applicationSupport(),
    );
  }

  const ClearAllLocalDataUseCase({
    required LedgerSnapshotStore ledgerSnapshotStore,
    required ReviewActionStore reviewActionStore,
    required LocalControlOverlayStore localControlOverlayStore,
    required LocalManualSubscriptionStore localManualSubscriptionStore,
    required LocalRenewalReminderStore localRenewalReminderStore,
    required LocalRenewalReminderScheduler localRenewalReminderScheduler,
    required LocalServicePresentationOverlayStore
        localServicePresentationOverlayStore,
    required SmsOnboardingProgressStore smsOnboardingProgressStore,
  })  : _ledgerSnapshotStore = ledgerSnapshotStore,
        _reviewActionStore = reviewActionStore,
        _localControlOverlayStore = localControlOverlayStore,
        _localManualSubscriptionStore = localManualSubscriptionStore,
        _localRenewalReminderStore = localRenewalReminderStore,
        _localRenewalReminderScheduler = localRenewalReminderScheduler,
        _localServicePresentationOverlayStore =
            localServicePresentationOverlayStore,
        _smsOnboardingProgressStore = smsOnboardingProgressStore;

  final LedgerSnapshotStore _ledgerSnapshotStore;
  final ReviewActionStore _reviewActionStore;
  final LocalControlOverlayStore _localControlOverlayStore;
  final LocalManualSubscriptionStore _localManualSubscriptionStore;
  final LocalRenewalReminderStore _localRenewalReminderStore;
  final LocalRenewalReminderScheduler _localRenewalReminderScheduler;
  final LocalServicePresentationOverlayStore
      _localServicePresentationOverlayStore;
  final SmsOnboardingProgressStore _smsOnboardingProgressStore;

  Future<ClearAllLocalDataResult> execute() async {
    var reminderCancellationFailed = false;
    final reminders = await _localRenewalReminderStore.list();
    for (final reminder in reminders) {
      final cancelled = await _localRenewalReminderScheduler.cancel(
        reminder.serviceKey,
      );
      if (!cancelled) {
        reminderCancellationFailed = true;
      }
    }

    await _ledgerSnapshotStore.clear();
    await _reviewActionStore.clear();
    await _localControlOverlayStore.clear();
    await _localManualSubscriptionStore.clear();
    await _localRenewalReminderStore.clear();
    await _localServicePresentationOverlayStore.clear();
    await _smsOnboardingProgressStore.clear();

    return ClearAllLocalDataResult(
      outcome: reminderCancellationFailed
          ? ClearAllLocalDataOutcome.clearedWithReminderWarning
          : ClearAllLocalDataOutcome.cleared,
    );
  }
}
