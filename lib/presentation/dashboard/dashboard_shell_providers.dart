import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/contracts/problem_report_launcher.dart';
import '../../application/models/dashboard_due_soon_presentation.dart';
import '../../application/models/dashboard_service_view_models.dart';
import '../../application/models/dashboard_renewal_reminder_presentation.dart';
import '../../application/models/dashboard_totals_summary_presentation.dart';
import '../../application/models/dashboard_upcoming_renewals_presentation.dart';
import '../../application/models/local_control_overlay_models.dart';
import '../../application/models/local_renewal_reminder_models.dart';
import '../../application/models/manual_subscription_models.dart';
import '../../application/models/review_item_action_models.dart';
import '../../application/models/runtime_local_message_source_status.dart';
import '../../application/use_cases/build_dashboard_due_soon_use_case.dart';
import '../../application/use_cases/build_dashboard_renewal_reminder_items_use_case.dart';
import '../../application/use_cases/build_dashboard_service_view_use_case.dart';
import '../../application/use_cases/build_dashboard_totals_summary_use_case.dart';
import '../../application/use_cases/build_dashboard_upcoming_renewals_use_case.dart';
import '../../application/use_cases/clear_all_local_data_use_case.dart';
import '../../application/use_cases/complete_sms_onboarding_use_case.dart';
import '../../application/use_cases/handle_local_control_overlay_use_case.dart';
import '../../application/use_cases/handle_local_renewal_reminder_use_case.dart';
import '../../application/use_cases/handle_local_service_presentation_use_case.dart';
import '../../application/use_cases/handle_manual_subscription_use_case.dart';
import '../../application/use_cases/handle_review_item_action_use_case.dart';
import '../../application/use_cases/load_runtime_dashboard_use_case.dart';
import '../../application/use_cases/load_sms_onboarding_progress_use_case.dart';
import '../../application/use_cases/sync_device_sms_use_case.dart';
import '../../application/use_cases/undo_local_control_overlay_use_case.dart';
import '../../application/use_cases/undo_review_item_action_use_case.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/enums/dashboard_bucket.dart';

final dashboardRuntimeUseCaseProvider = Provider<LoadRuntimeDashboardUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardRuntimeUseCaseProvider in DashboardShell.',
  ),
);

final dashboardSyncUseCaseProvider = Provider<SyncDeviceSmsUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardSyncUseCaseProvider in DashboardShell.',
  ),
);

final dashboardHandleReviewActionUseCaseProvider =
    Provider<HandleReviewItemActionUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardHandleReviewActionUseCaseProvider in DashboardShell.',
  ),
);

final dashboardUndoReviewActionUseCaseProvider =
    Provider<UndoReviewItemActionUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardUndoReviewActionUseCaseProvider in DashboardShell.',
  ),
);

final dashboardHandleLocalControlUseCaseProvider =
    Provider<HandleLocalControlOverlayUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardHandleLocalControlUseCaseProvider in DashboardShell.',
  ),
);

final dashboardUndoLocalControlUseCaseProvider =
    Provider<UndoLocalControlOverlayUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardUndoLocalControlUseCaseProvider in DashboardShell.',
  ),
);

final dashboardHandleLocalRenewalReminderUseCaseProvider =
    Provider<HandleLocalRenewalReminderUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardHandleLocalRenewalReminderUseCaseProvider in DashboardShell.',
  ),
);

final dashboardHandleManualSubscriptionUseCaseProvider =
    Provider<HandleManualSubscriptionUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardHandleManualSubscriptionUseCaseProvider in DashboardShell.',
  ),
);

final dashboardHandleLocalServicePresentationUseCaseProvider =
    Provider<HandleLocalServicePresentationUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardHandleLocalServicePresentationUseCaseProvider in DashboardShell.',
  ),
);

final dashboardProblemReportLauncherProvider = Provider<ProblemReportLauncher?>(
  (ref) => null,
);

final dashboardClearAllLocalDataUseCaseProvider =
    Provider<ClearAllLocalDataUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardClearAllLocalDataUseCaseProvider in DashboardShell.',
  ),
);

final dashboardLoadSmsOnboardingProgressUseCaseProvider =
    Provider<LoadSmsOnboardingProgressUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardLoadSmsOnboardingProgressUseCaseProvider in DashboardShell.',
  ),
);

final dashboardCompleteSmsOnboardingUseCaseProvider =
    Provider<CompleteSmsOnboardingUseCase>(
  (ref) => throw UnimplementedError(
    'Override dashboardCompleteSmsOnboardingUseCaseProvider in DashboardShell.',
  ),
);

enum FirstRunPhase {
  /// Still loading onboarding completion state.
  loading,

  /// Show the first-run gate (no permission requested yet).
  gate,

  /// Permission was denied once — show short retry state.
  denied,

  /// Permission permanently denied — show Settings nudge.
  permanentlyDenied,

  /// Permission granted, scan in progress.
  scanning,

  /// First scan completed with zero confirmed paid subscriptions.
  firstResult,

  /// Onboarding complete — show normal Home.
  completed,
}

class FirstRunState {
  const FirstRunState({
    required this.phase,
    this.firstScanSnapshot,
  });

  const FirstRunState.loading() : phase = FirstRunPhase.loading, firstScanSnapshot = null;

  final FirstRunPhase phase;
  final RuntimeDashboardSnapshot? firstScanSnapshot;

  FirstRunState copyWith({
    FirstRunPhase? phase,
    RuntimeDashboardSnapshot? firstScanSnapshot,
  }) {
    return FirstRunState(
      phase: phase ?? this.phase,
      firstScanSnapshot: firstScanSnapshot ?? this.firstScanSnapshot,
    );
  }

  bool get isInFirstRun => phase != FirstRunPhase.completed;
}

class FirstRunController extends StateNotifier<FirstRunState> {
  FirstRunController(this._ref) : super(const FirstRunState.loading());

  final Ref _ref;

  Future<void> initialize() async {
    debugPrint('FirstRunController: initialize starting...');
    final completed = await _ref
        .read(dashboardLocalControlsProvider.notifier)
        .loadSmsOnboardingCompletion();
    debugPrint('FirstRunController: initialize completed=$completed');
    if (completed) {
      state = const FirstRunState(phase: FirstRunPhase.completed);
    } else {
      state = const FirstRunState(phase: FirstRunPhase.gate);
    }
    debugPrint('FirstRunController: initialize finished, state phase=${state.phase}');
  }

  void setPhase(FirstRunPhase phase) {
    state = state.copyWith(phase: phase);
  }

  void setFirstResult(RuntimeDashboardSnapshot snapshot) {
    state = FirstRunState(
      phase: FirstRunPhase.firstResult,
      firstScanSnapshot: snapshot,
    );
  }

  Future<void> markCompleted() async {
    await _ref
        .read(dashboardLocalControlsProvider.notifier)
        .markSmsOnboardingCompleted();
    state = const FirstRunState(phase: FirstRunPhase.completed);
  }

  void reset() {
    state = const FirstRunState(phase: FirstRunPhase.gate);
  }
}

final dashboardFirstRunProvider =
    StateNotifierProvider<FirstRunController, FirstRunState>(
  (ref) => FirstRunController(ref),
);

class DashboardLoadRecoveryState {
  const DashboardLoadRecoveryState({
    required this.title,
    required this.description,
    required this.icon,
    required this.showRetryAction,
  });

  const DashboardLoadRecoveryState.reloading()
      : title = 'Trying again...',
        description = 'Reloading your last saved view.',
        icon = Icons.hourglass_top_rounded,
        showRetryAction = false;

  const DashboardLoadRecoveryState.failed()
      : title = 'Your saved view stayed in place.',
        description = 'SubWatch could not reload it yet.',
        icon = Icons.history_toggle_off_rounded,
        showRetryAction = true;

  final String title;
  final String description;
  final IconData icon;
  final bool showRetryAction;
}

class DashboardSnapshotState {
  const DashboardSnapshotState({
    required this.snapshot,
    required this.isLoading,
    required this.error,
    required this.stackTrace,
    required this.loadRecoveryState,
  });

  const DashboardSnapshotState.initial()
      : snapshot = null,
        isLoading = true,
        error = null,
        stackTrace = null,
        loadRecoveryState = null;

  const DashboardSnapshotState.ready(
    RuntimeDashboardSnapshot snapshot,
  ) : this(
          snapshot: snapshot,
          isLoading: false,
          error: null,
          stackTrace: null,
          loadRecoveryState: null,
        );

  final RuntimeDashboardSnapshot? snapshot;
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;
  final DashboardLoadRecoveryState? loadRecoveryState;

  bool get hasSnapshot => snapshot != null;

  bool get hasFatalError => error != null && snapshot == null && !isLoading;
}

class DashboardSnapshotController extends StateNotifier<DashboardSnapshotState> {
  DashboardSnapshotController(this._ref)
      : super(const DashboardSnapshotState.initial()) {
    loadInitial();
  }

  final Ref _ref;

  Future<void> loadInitial({
    bool clearPreservedSnapshot = false,
  }) async {
    final preservedSnapshot = clearPreservedSnapshot ? null : state.snapshot;
    debugPrint('DashboardSnapshotController: loadInitial starting...');
    state = DashboardSnapshotState(
      snapshot: preservedSnapshot,
      isLoading: true,
      error: null,
      stackTrace: null,
      loadRecoveryState: preservedSnapshot == null
          ? null
          : const DashboardLoadRecoveryState.reloading(),
    );

    try {
      debugPrint('DashboardSnapshotController: executing runtime use case...');
      final snapshot = await _ref.read(dashboardRuntimeUseCaseProvider).execute();
      debugPrint('DashboardSnapshotController: loadInitial success');
      state = DashboardSnapshotState.ready(snapshot);
    } catch (error, stackTrace) {
      debugPrint('DashboardSnapshotController: loadInitial error: $error');
      state = DashboardSnapshotState(
        snapshot: preservedSnapshot,
        isLoading: false,
        error: error,
        stackTrace: stackTrace,
        loadRecoveryState: preservedSnapshot == null
            ? null
            : const DashboardLoadRecoveryState.failed(),
      );
    }
  }

  Future<void> reload({
    bool clearPreservedSnapshot = false,
  }) {
    return loadInitial(clearPreservedSnapshot: clearPreservedSnapshot);
  }

  void setSnapshot(RuntimeDashboardSnapshot snapshot) {
    state = DashboardSnapshotState.ready(snapshot);
  }
}

class DashboardSyncState {
  const DashboardSyncState({
    required this.isSyncing,
  });

  const DashboardSyncState.idle() : isSyncing = false;

  const DashboardSyncState.syncing() : isSyncing = true;

  final bool isSyncing;
}

class DashboardSyncController extends StateNotifier<DashboardSyncState> {
  DashboardSyncController(this._ref) : super(const DashboardSyncState.idle());

  final Ref _ref;

  Future<SyncDeviceSmsResult> sync({
    Duration minimumIndicatorDuration = Duration.zero,
  }) async {
    debugPrint('DashboardSyncController: sync starting...');
    if (state.isSyncing) {
      debugPrint('DashboardSyncController: sync already in progress');
      throw StateError('Sync already in progress.');
    }

    state = const DashboardSyncState.syncing();
    final startedAt = DateTime.now();
    try {
      debugPrint('DashboardSyncController: executing sync use case...');
      final result = await _ref.read(dashboardSyncUseCaseProvider).execute();
      debugPrint('DashboardSyncController: sync use case finished');

      final remaining =
          minimumIndicatorDuration - DateTime.now().difference(startedAt);
      if (remaining > Duration.zero) {
        debugPrint('DashboardSyncController: waiting for minimum indicator duration...');
        await Future<void>.delayed(remaining);
      }
      debugPrint('DashboardSyncController: updating snapshot controller...');
      _ref
          .read(dashboardSnapshotControllerProvider.notifier)
          .setSnapshot(result.snapshot);
      debugPrint('DashboardSyncController: sync success');
      return result;
    } catch (e) {
      debugPrint('DashboardSyncController: sync failed: $e');
      rethrow;
    } finally {
      state = const DashboardSyncState.idle();
    }
  }
}

class DashboardReviewActionsState {
  const DashboardReviewActionsState({
    required this.targetsInFlight,
  });

  const DashboardReviewActionsState.initial()
      : targetsInFlight = const <String>{};

  final Set<String> targetsInFlight;

  DashboardReviewActionsState copyWith({
    Set<String>? targetsInFlight,
  }) {
    return DashboardReviewActionsState(
      targetsInFlight: targetsInFlight ?? this.targetsInFlight,
    );
  }
}

class DashboardReviewActionsController
    extends StateNotifier<DashboardReviewActionsState> {
  DashboardReviewActionsController(this._ref)
      : super(const DashboardReviewActionsState.initial());

  final Ref _ref;

  Future<HandleReviewItemActionResult> executeAction({
    required ReviewItem item,
    required ReviewItemAction action,
  }) async {
    final targetKey = ReviewItemActionDescriptor.fromReviewItem(item).targetKey;
    _setTargetBusy(targetKey, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleReviewActionUseCaseProvider).execute(
                reviewItem: item,
                action: action,
              );
      final snapshot = result.snapshot;
      if (snapshot != null) {
        _ref.read(dashboardSnapshotControllerProvider.notifier).setSnapshot(snapshot);
      }
      return result;
    } finally {
      _setTargetBusy(targetKey, busy: false);
    }
  }

  Future<UndoReviewItemActionResult> undo({
    required String targetKey,
  }) async {
    _setTargetBusy(targetKey, busy: true);
    try {
      final result =
          await _ref.read(dashboardUndoReviewActionUseCaseProvider).execute(
                targetKey: targetKey,
              );
      final snapshot = result.snapshot;
      if (snapshot != null) {
        _ref.read(dashboardSnapshotControllerProvider.notifier).setSnapshot(snapshot);
      }
      return result;
    } finally {
      _setTargetBusy(targetKey, busy: false);
    }
  }

  void _setTargetBusy(String targetKey, {required bool busy}) {
    debugPrint('DashboardReviewActionsController: _setTargetBusy targetKey=$targetKey busy=$busy');
    final nextTargets = state.targetsInFlight.toSet();
    if (busy) {
      nextTargets.add(targetKey);
    } else {
      nextTargets.remove(targetKey);
    }
    state = state.copyWith(targetsInFlight: Set<String>.unmodifiable(nextTargets));
  }
}

const Object _dashboardShellSentinel = Object();

class DashboardLocalControlsState {
  const DashboardLocalControlsState({
    required this.serviceViewControls,
    required this.localControlTargetsInFlight,
    required this.localRenewalReminderTargetsInFlight,
    required this.manualSubscriptionTargetsInFlight,
    required this.localServicePresentationTargetsInFlight,
    required this.isClearingAllData,
    required this.hasCompletedSmsOnboarding,
  });

  const DashboardLocalControlsState.initial()
      : serviceViewControls = const DashboardServiceViewControls(),
        localControlTargetsInFlight = const <String>{},
        localRenewalReminderTargetsInFlight = const <String>{},
        manualSubscriptionTargetsInFlight = const <String>{},
        localServicePresentationTargetsInFlight = const <String>{},
        isClearingAllData = false,
        hasCompletedSmsOnboarding = null;

  final DashboardServiceViewControls serviceViewControls;
  final Set<String> localControlTargetsInFlight;
  final Set<String> localRenewalReminderTargetsInFlight;
  final Set<String> manualSubscriptionTargetsInFlight;
  final Set<String> localServicePresentationTargetsInFlight;
  final bool isClearingAllData;
  final bool? hasCompletedSmsOnboarding;

  DashboardLocalControlsState copyWith({
    DashboardServiceViewControls? serviceViewControls,
    Set<String>? localControlTargetsInFlight,
    Set<String>? localRenewalReminderTargetsInFlight,
    Set<String>? manualSubscriptionTargetsInFlight,
    Set<String>? localServicePresentationTargetsInFlight,
    bool? isClearingAllData,
    Object? hasCompletedSmsOnboarding = _dashboardShellSentinel,
  }) {
    return DashboardLocalControlsState(
      serviceViewControls: serviceViewControls ?? this.serviceViewControls,
      localControlTargetsInFlight:
          localControlTargetsInFlight ?? this.localControlTargetsInFlight,
      localRenewalReminderTargetsInFlight:
          localRenewalReminderTargetsInFlight ??
              this.localRenewalReminderTargetsInFlight,
      manualSubscriptionTargetsInFlight:
          manualSubscriptionTargetsInFlight ??
              this.manualSubscriptionTargetsInFlight,
      localServicePresentationTargetsInFlight:
          localServicePresentationTargetsInFlight ??
              this.localServicePresentationTargetsInFlight,
      isClearingAllData: isClearingAllData ?? this.isClearingAllData,
      hasCompletedSmsOnboarding:
          hasCompletedSmsOnboarding == _dashboardShellSentinel
              ? this.hasCompletedSmsOnboarding
              : hasCompletedSmsOnboarding as bool?,
    );
  }
}

class DashboardLocalControlsController
    extends StateNotifier<DashboardLocalControlsState> {
  DashboardLocalControlsController(this._ref)
      : super(const DashboardLocalControlsState.initial());

  final Ref _ref;

  void setSearchQuery(String query) {
    state = state.copyWith(
      serviceViewControls: state.serviceViewControls.copyWith(searchQuery: query),
    );
  }

  void setSortMode(DashboardServiceSortMode sortMode) {
    state = state.copyWith(
      serviceViewControls: state.serviceViewControls.copyWith(sortMode: sortMode),
    );
  }

  void setFilterMode(DashboardServiceFilterMode filterMode) {
    state = state.copyWith(
      serviceViewControls:
          state.serviceViewControls.copyWith(filterMode: filterMode),
    );
  }

  void clearServiceViewControls() {
    state = state.copyWith(
      serviceViewControls: const DashboardServiceViewControls(),
    );
  }

  Future<bool> loadSmsOnboardingCompletion() async {
    if (state.hasCompletedSmsOnboarding != null) {
      return state.hasCompletedSmsOnboarding!;
    }

    final completed = await _ref
        .read(dashboardLoadSmsOnboardingProgressUseCaseProvider)
        .execute();
    state = state.copyWith(hasCompletedSmsOnboarding: completed);
    return completed;
  }

  Future<void> markSmsOnboardingCompleted() async {
    await _ref.read(dashboardCompleteSmsOnboardingUseCaseProvider).execute();
    state = state.copyWith(hasCompletedSmsOnboarding: true);
  }

  Future<HandleManualSubscriptionResult> createManualSubscription({
    required String targetKey,
    required String serviceName,
    required ManualSubscriptionBillingCycle billingCycle,
    required String amountInput,
    required DateTime? nextRenewalDate,
    required String planLabel,
  }) async {
    _setManualTargetBusy(targetKey, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleManualSubscriptionUseCaseProvider).create(
                serviceName: serviceName,
                billingCycle: billingCycle,
                amountInput: amountInput,
                nextRenewalDate: nextRenewalDate,
                planLabel: planLabel,
              );
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setManualTargetBusy(targetKey, busy: false);
    }
  }

  Future<HandleManualSubscriptionResult> updateManualSubscription({
    required String id,
    required String serviceName,
    required ManualSubscriptionBillingCycle billingCycle,
    required String amountInput,
    required DateTime? nextRenewalDate,
    required String planLabel,
  }) async {
    _setManualTargetBusy(id, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleManualSubscriptionUseCaseProvider).update(
                id: id,
                serviceName: serviceName,
                billingCycle: billingCycle,
                amountInput: amountInput,
                nextRenewalDate: nextRenewalDate,
                planLabel: planLabel,
              );
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setManualTargetBusy(id, busy: false);
    }
  }

  Future<HandleManualSubscriptionResult> deleteManualSubscription({
    required String id,
  }) async {
    _setManualTargetBusy(id, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleManualSubscriptionUseCaseProvider).delete(
                id: id,
              );
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setManualTargetBusy(id, busy: false);
    }
  }

  Future<HandleLocalControlOverlayResult> ignoreCard(DashboardCard card) async {
    final targetKey = 'service::${card.serviceKey.value}';
    _setLocalControlTargetBusy(targetKey, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleLocalControlUseCaseProvider).ignoreCard(
                card,
              );
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalControlTargetBusy(targetKey, busy: false);
    }
  }

  Future<HandleLocalControlOverlayResult> hideCard(DashboardCard card) async {
    final targetKey = 'card::${card.bucket.name}::${card.serviceKey.value}';
    _setLocalControlTargetBusy(targetKey, busy: true);
    try {
      final result =
          await _ref.read(dashboardHandleLocalControlUseCaseProvider).hideCard(
                card,
              );
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalControlTargetBusy(targetKey, busy: false);
    }
  }

  Future<HandleLocalControlOverlayResult> ignoreReviewItem(
    ReviewItem item,
  ) async {
    final targetKey = LocalControlDecision.ignoreReviewItem(
      reviewItem: item,
      decidedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ).targetKey;
    _setLocalControlTargetBusy(targetKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalControlUseCaseProvider)
          .ignoreReviewItem(item);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalControlTargetBusy(targetKey, busy: false);
    }
  }

  Future<UndoLocalControlOverlayResult> undoLocalControl({
    required String targetKey,
  }) async {
    _setLocalControlTargetBusy(targetKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardUndoLocalControlUseCaseProvider)
          .execute(targetKey: targetKey);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalControlTargetBusy(targetKey, busy: false);
    }
  }

  Future<HandleLocalServicePresentationResult> saveLocalLabel({
    required DashboardCard card,
    required String label,
  }) async {
    _setLocalServicePresentationTargetBusy(card.serviceKey.value, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalServicePresentationUseCaseProvider)
          .saveLocalLabel(card: card, label: label);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalServicePresentationTargetBusy(card.serviceKey.value, busy: false);
    }
  }

  Future<HandleLocalServicePresentationResult> resetLocalLabel({
    required String serviceKey,
  }) async {
    _setLocalServicePresentationTargetBusy(serviceKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalServicePresentationUseCaseProvider)
          .resetLocalLabel(serviceKey: serviceKey);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalServicePresentationTargetBusy(serviceKey, busy: false);
    }
  }

  Future<HandleLocalServicePresentationResult> pinService(
    DashboardCard card,
  ) async {
    _setLocalServicePresentationTargetBusy(card.serviceKey.value, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalServicePresentationUseCaseProvider)
          .pinService(card);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalServicePresentationTargetBusy(card.serviceKey.value, busy: false);
    }
  }

  Future<HandleLocalServicePresentationResult> unpinService({
    required String serviceKey,
  }) async {
    _setLocalServicePresentationTargetBusy(serviceKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalServicePresentationUseCaseProvider)
          .unpinService(serviceKey: serviceKey);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setLocalServicePresentationTargetBusy(serviceKey, busy: false);
    }
  }

  Future<HandleLocalRenewalReminderResult> enableReminder({
    required DashboardRenewalReminderItemPresentation item,
    required RenewalReminderLeadTimePreset preset,
  }) async {
    final targetKey = item.renewal.serviceKey;
    _setReminderTargetBusy(targetKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalRenewalReminderUseCaseProvider)
          .enableReminder(item: item, leadTimePreset: preset);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setReminderTargetBusy(targetKey, busy: false);
    }
  }

  Future<HandleLocalRenewalReminderResult> disableReminder({
    required String serviceKey,
  }) async {
    _setReminderTargetBusy(serviceKey, busy: true);
    try {
      final result = await _ref
          .read(dashboardHandleLocalRenewalReminderUseCaseProvider)
          .disableReminder(serviceKey: serviceKey);
      _applySnapshot(result.snapshot);
      return result;
    } finally {
      _setReminderTargetBusy(serviceKey, busy: false);
    }
  }

  Future<ClearAllLocalDataResult> clearAllData() async {
    state = state.copyWith(isClearingAllData: true);
    try {
      final result =
          await _ref.read(dashboardClearAllLocalDataUseCaseProvider).execute();
      state = state.copyWith(
        serviceViewControls: const DashboardServiceViewControls(),
        hasCompletedSmsOnboarding: false,
      );
      await _ref
          .read(dashboardSnapshotControllerProvider.notifier)
          .reload(clearPreservedSnapshot: true);
      return result;
    } finally {
      state = state.copyWith(isClearingAllData: false);
    }
  }

  void _applySnapshot(RuntimeDashboardSnapshot? snapshot) {
    if (snapshot == null) {
      return;
    }
    _ref.read(dashboardSnapshotControllerProvider.notifier).setSnapshot(snapshot);
  }

  void _setManualTargetBusy(String targetKey, {required bool busy}) {
    state = state.copyWith(
      manualSubscriptionTargetsInFlight:
          _nextTargets(state.manualSubscriptionTargetsInFlight, targetKey, busy),
    );
  }

  void _setLocalControlTargetBusy(String targetKey, {required bool busy}) {
    state = state.copyWith(
      localControlTargetsInFlight:
          _nextTargets(state.localControlTargetsInFlight, targetKey, busy),
    );
  }

  void _setReminderTargetBusy(String targetKey, {required bool busy}) {
    state = state.copyWith(
      localRenewalReminderTargetsInFlight: _nextTargets(
        state.localRenewalReminderTargetsInFlight,
        targetKey,
        busy,
      ),
    );
  }

  void _setLocalServicePresentationTargetBusy(
    String targetKey, {
    required bool busy,
  }) {
    state = state.copyWith(
      localServicePresentationTargetsInFlight: _nextTargets(
        state.localServicePresentationTargetsInFlight,
        targetKey,
        busy,
      ),
    );
  }

  Set<String> _nextTargets(Set<String> current, String targetKey, bool busy) {
    final next = current.toSet();
    if (busy) {
      next.add(targetKey);
    } else {
      next.remove(targetKey);
    }
    return Set<String>.unmodifiable(next);
  }
}

const BuildDashboardTotalsSummaryUseCase _buildDashboardTotalsSummaryUseCase =
    BuildDashboardTotalsSummaryUseCase();
const BuildDashboardUpcomingRenewalsUseCase
    _buildDashboardUpcomingRenewalsUseCase =
    BuildDashboardUpcomingRenewalsUseCase();
const BuildDashboardDueSoonUseCase _buildDashboardDueSoonUseCase =
    BuildDashboardDueSoonUseCase();
const BuildDashboardRenewalReminderItemsUseCase
    _buildDashboardRenewalReminderItemsUseCase =
    BuildDashboardRenewalReminderItemsUseCase();
const BuildDashboardServiceViewUseCase _buildDashboardServiceViewUseCase =
    BuildDashboardServiceViewUseCase();

class DashboardShellLoadViewState {
  const DashboardShellLoadViewState({
    required this.showLoading,
    required this.hasFatalError,
    required this.loadRecoveryState,
  });

  final bool showLoading;
  final bool hasFatalError;
  final DashboardLoadRecoveryState? loadRecoveryState;
}

class DashboardHomeScreenData {
  const DashboardHomeScreenData({
    required this.data,
    required this.sourceStatus,
    required this.totalsSummary,
    required this.dueSoon,
    required this.upcomingRenewals,
    required this.renewalReminderItems,
  });

  final RuntimeDashboardSnapshot data;
  final RuntimeLocalMessageSourceStatus sourceStatus;
  final DashboardTotalsSummaryPresentation totalsSummary;
  final DashboardDueSoonPresentation dueSoon;
  final DashboardUpcomingRenewalsPresentation upcomingRenewals;
  final List<DashboardRenewalReminderItemPresentation> renewalReminderItems;
}

class DashboardSubscriptionsScreenData {
  const DashboardSubscriptionsScreenData({
    required this.data,
    required this.serviceView,
    required this.visibleServiceSections,
    required this.upcomingRenewals,
    required this.renewalReminderItems,
  });

  final RuntimeDashboardSnapshot data;
  final DashboardServiceViewResult serviceView;
  final List<DashboardServiceSectionView> visibleServiceSections;
  final DashboardUpcomingRenewalsPresentation upcomingRenewals;
  final List<DashboardRenewalReminderItemPresentation> renewalReminderItems;
}

class DashboardReviewScreenData {
  const DashboardReviewScreenData({
    required this.data,
  });

  final RuntimeDashboardSnapshot data;
}

class DashboardSettingsScreenData {
  const DashboardSettingsScreenData({
    required this.data,
    required this.sourceStatus,
    required this.reminderItems,
  });

  final RuntimeDashboardSnapshot data;
  final RuntimeLocalMessageSourceStatus sourceStatus;
  final List<DashboardRenewalReminderItemPresentation> reminderItems;
}

RuntimeDashboardSnapshot _requireDashboardSnapshot(Ref ref) {
  final snapshot = ref.watch(
    dashboardSnapshotControllerProvider.select(
      (state) => state.snapshot,
    ),
  );
  if (snapshot == null) {
    throw StateError(
      'Dashboard snapshot is not available while a screen is trying to build.',
    );
  }
  return snapshot;
}

bool _dashboardSnapshotHasLocalModifications(RuntimeDashboardSnapshot data) {
  if (data.confirmedReviewItems.isNotEmpty ||
      data.benefitReviewItems.isNotEmpty ||
      data.dismissedReviewItems.isNotEmpty ||
      data.ignoredLocalItems.isNotEmpty ||
      data.hiddenLocalItems.isNotEmpty) {
    return true;
  }

  return data.localServicePresentationStates.values.any(
    (state) => state.hasLocalLabel || state.isPinned,
  );
}

final dashboardSnapshotControllerProvider = StateNotifierProvider<
    DashboardSnapshotController, DashboardSnapshotState>(
  (ref) => DashboardSnapshotController(ref),
);

final dashboardSyncStateProvider =
    StateNotifierProvider<DashboardSyncController, DashboardSyncState>(
  (ref) => DashboardSyncController(ref),
);

final dashboardReviewActionsProvider = StateNotifierProvider<
    DashboardReviewActionsController, DashboardReviewActionsState>(
  (ref) => DashboardReviewActionsController(ref),
);

final dashboardLocalControlsProvider = StateNotifierProvider<
    DashboardLocalControlsController, DashboardLocalControlsState>(
  (ref) => DashboardLocalControlsController(ref),
);

final dashboardShellLoadStateProvider = Provider<DashboardShellLoadViewState>(
  (ref) {
    final snapshotLoadState = ref.watch(
      dashboardSnapshotControllerProvider.select(
        (state) => (
          isLoading: state.isLoading,
          hasSnapshot: state.hasSnapshot,
          hasFatalError: state.hasFatalError,
          loadRecoveryState: state.loadRecoveryState,
        ),
      ),
    );
    return DashboardShellLoadViewState(
      showLoading: snapshotLoadState.isLoading && !snapshotLoadState.hasSnapshot,
      hasFatalError: snapshotLoadState.hasFatalError,
      loadRecoveryState: snapshotLoadState.loadRecoveryState,
    );
  },
);

final dashboardServiceViewControlsProvider = Provider<DashboardServiceViewControls>(
  (ref) => ref.watch(
    dashboardLocalControlsProvider.select(
      (state) => state.serviceViewControls,
    ),
  ),
);

final dashboardSourceStatusProvider = Provider<RuntimeLocalMessageSourceStatus>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return RuntimeLocalMessageSourceStatus.fromSelection(
      snapshot.messageSourceSelection,
      provenance: snapshot.provenance,
      hasLocalModifications: _dashboardSnapshotHasLocalModifications(snapshot),
    );
  },
);

final dashboardTotalsSummaryProvider = Provider<DashboardTotalsSummaryPresentation>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return _buildDashboardTotalsSummaryUseCase.execute(
      cards: snapshot.cards,
      manualSubscriptions: snapshot.manualSubscriptions,
      reviewCount: snapshot.reviewQueue.length,
    );
  },
);

final dashboardUpcomingRenewalsProvider =
    Provider<DashboardUpcomingRenewalsPresentation>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return _buildDashboardUpcomingRenewalsUseCase.execute(
      cards: snapshot.cards,
      manualSubscriptions: snapshot.manualSubscriptions,
      now: snapshot.provenance.recordedAt,
    );
  },
);

final dashboardDueSoonProvider = Provider<DashboardDueSoonPresentation>(
  (ref) {
    final upcomingRenewals = ref.watch(dashboardUpcomingRenewalsProvider);
    return _buildDashboardDueSoonUseCase.execute(
      upcomingRenewals: upcomingRenewals,
    );
  },
);

final dashboardRenewalReminderItemsProvider =
    Provider<List<DashboardRenewalReminderItemPresentation>>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    final upcomingRenewals = ref.watch(dashboardUpcomingRenewalsProvider);
    return _buildDashboardRenewalReminderItemsUseCase.execute(
      upcomingRenewals: upcomingRenewals,
      preferencesByServiceKey: snapshot.localRenewalReminderPreferences,
      now: snapshot.provenance.recordedAt,
    );
  },
);

final dashboardSubscriptionsServiceViewProvider =
    Provider<DashboardServiceViewResult>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    final controls = ref.watch(dashboardServiceViewControlsProvider);
    final subscriptionBrowseCards = snapshot.cards
        .where(
          (card) =>
              card.bucket == DashboardBucket.confirmedSubscriptions ||
              card.bucket == DashboardBucket.trialsAndBenefits,
        )
        .toList(growable: false);
    return _buildDashboardServiceViewUseCase.execute(
      cards: subscriptionBrowseCards,
      localServicePresentationStates: snapshot.localServicePresentationStates,
      controls: controls,
    );
  },
);

final dashboardVisibleServiceSectionsProvider =
    Provider<List<DashboardServiceSectionView>>(
  (ref) {
    final serviceView = ref.watch(dashboardSubscriptionsServiceViewProvider);
    return serviceView.sections
        .where((section) => section.cards.isNotEmpty)
        .toList(growable: false);
  },
);

final dashboardHomeScreenDataProvider = Provider<DashboardHomeScreenData>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return DashboardHomeScreenData(
      data: snapshot,
      sourceStatus: ref.watch(dashboardSourceStatusProvider),
      totalsSummary: ref.watch(dashboardTotalsSummaryProvider),
      dueSoon: ref.watch(dashboardDueSoonProvider),
      upcomingRenewals: ref.watch(dashboardUpcomingRenewalsProvider),
      renewalReminderItems: ref.watch(dashboardRenewalReminderItemsProvider),
    );
  },
);

final dashboardSubscriptionsScreenDataProvider =
    Provider<DashboardSubscriptionsScreenData>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return DashboardSubscriptionsScreenData(
      data: snapshot,
      serviceView: ref.watch(dashboardSubscriptionsServiceViewProvider),
      visibleServiceSections: ref.watch(dashboardVisibleServiceSectionsProvider),
      upcomingRenewals: ref.watch(dashboardUpcomingRenewalsProvider),
      renewalReminderItems: ref.watch(dashboardRenewalReminderItemsProvider),
    );
  },
);

final dashboardReviewScreenDataProvider = Provider<DashboardReviewScreenData>(
  (ref) => DashboardReviewScreenData(
    data: _requireDashboardSnapshot(ref),
  ),
);

final dashboardSettingsScreenDataProvider =
    Provider<DashboardSettingsScreenData>(
  (ref) {
    final snapshot = _requireDashboardSnapshot(ref);
    return DashboardSettingsScreenData(
      data: snapshot,
      sourceStatus: ref.watch(dashboardSourceStatusProvider),
      reminderItems: ref.watch(dashboardRenewalReminderItemsProvider),
    );
  },
);
