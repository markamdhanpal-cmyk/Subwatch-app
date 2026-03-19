import '../contracts/local_renewal_reminder_scheduler.dart';
import '../contracts/local_renewal_reminder_store.dart';
import '../gateways/android_local_renewal_reminder_scheduler.dart';
import '../models/dashboard_renewal_reminder_presentation.dart';
import '../models/local_renewal_reminder_models.dart';
import '../stores/json_file_local_renewal_reminder_store.dart';
import 'load_runtime_dashboard_use_case.dart';

enum LocalRenewalReminderOutcome {
  enabled,
  disabled,
  unchanged,
  failed,
}

class HandleLocalRenewalReminderResult {
  const HandleLocalRenewalReminderResult({
    required this.outcome,
    this.snapshot,
  });

  final LocalRenewalReminderOutcome outcome;
  final RuntimeDashboardSnapshot? snapshot;
}

class HandleLocalRenewalReminderUseCase {
  factory HandleLocalRenewalReminderUseCase.persistent({
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalRenewalReminderScheduler? localRenewalReminderScheduler,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
    DateTime Function()? clock,
  }) {
    final resolvedStore = localRenewalReminderStore ??
        JsonFileLocalRenewalReminderStore.applicationSupport();
    return HandleLocalRenewalReminderUseCase(
      localRenewalReminderStore: resolvedStore,
      localRenewalReminderScheduler: localRenewalReminderScheduler ??
          const AndroidLocalRenewalReminderScheduler(),
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                localRenewalReminderStore: resolvedStore,
              ).execute(),
      clock: clock,
    );
  }

  HandleLocalRenewalReminderUseCase({
    required LocalRenewalReminderStore localRenewalReminderStore,
    required LocalRenewalReminderScheduler localRenewalReminderScheduler,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
    DateTime Function()? clock,
  })  : _localRenewalReminderStore = localRenewalReminderStore,
        _localRenewalReminderScheduler = localRenewalReminderScheduler,
        _loadRuntimeDashboard = loadRuntimeDashboard,
        _clock = clock ?? DateTime.now;

  final LocalRenewalReminderStore _localRenewalReminderStore;
  final LocalRenewalReminderScheduler _localRenewalReminderScheduler;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;
  final DateTime Function() _clock;

  Future<HandleLocalRenewalReminderResult> enableReminder({
    required DashboardRenewalReminderItemPresentation item,
    required RenewalReminderLeadTimePreset leadTimePreset,
  }) async {
    if (!item.availablePresets.contains(leadTimePreset)) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.failed,
      );
    }

    final existing = await _existingPreference(item.renewal.serviceKey);
    if (existing?.leadTimePreset == leadTimePreset) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.unchanged,
      );
    }

    final scheduledAt = leadTimePreset.scheduledAt(item.renewal.renewalDate);
    if (!scheduledAt.isAfter(_clock())) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.failed,
      );
    }

    final scheduled = await _localRenewalReminderScheduler.schedule(
      LocalRenewalReminderScheduleRequest(
        serviceKey: item.renewal.serviceKey,
        title: '${item.renewal.serviceTitle} renewal coming up',
        body: '${item.renewal.serviceTitle} renews on ${item.renewal.renewalDateLabel}.',
        scheduledAt: scheduledAt,
      ),
    );
    if (!scheduled) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.failed,
      );
    }

    await _localRenewalReminderStore.save(
      LocalRenewalReminderPreference(
        serviceKey: item.renewal.serviceKey,
        leadTimePreset: leadTimePreset,
      ),
    );

    return HandleLocalRenewalReminderResult(
      outcome: LocalRenewalReminderOutcome.enabled,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalRenewalReminderResult> disableReminder({
    required String serviceKey,
  }) async {
    final existing = await _existingPreference(serviceKey);
    if (existing == null) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.unchanged,
      );
    }

    final cancelled = await _localRenewalReminderScheduler.cancel(serviceKey);
    if (!cancelled) {
      return const HandleLocalRenewalReminderResult(
        outcome: LocalRenewalReminderOutcome.failed,
      );
    }

    await _localRenewalReminderStore.remove(serviceKey);
    return HandleLocalRenewalReminderResult(
      outcome: LocalRenewalReminderOutcome.disabled,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<LocalRenewalReminderPreference?> _existingPreference(
    String serviceKey,
  ) async {
    final preferences = await _localRenewalReminderStore.list();
    for (final preference in preferences) {
      if (preference.serviceKey == serviceKey) {
        return preference;
      }
    }
    return null;
  }
}
