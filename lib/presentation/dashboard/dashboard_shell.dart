import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/models/dashboard_due_soon_presentation.dart';
import '../../application/models/dashboard_renewal_reminder_presentation.dart';
import '../../application/models/dashboard_service_view_models.dart';
import '../../application/models/dashboard_totals_summary_presentation.dart';
import '../../application/models/dashboard_upcoming_renewals_presentation.dart';
import '../../application/models/local_message_source_access_state.dart';
import '../../application/models/manual_subscription_models.dart';
import '../../application/models/local_renewal_reminder_models.dart';
import '../../application/models/contextual_explanation_presentation.dart';
import '../../application/models/dashboard_completion_presentation.dart';
import '../../application/models/local_control_overlay_models.dart';
import '../../application/models/local_service_presentation_overlay_models.dart';
import '../../application/models/review_queue_item_presentation.dart';
import '../../application/models/review_item_action_models.dart';
import '../../application/models/runtime_local_message_source_status.dart';
import '../../application/models/runtime_snapshot_provenance.dart';
import '../../application/use_cases/build_dashboard_due_soon_use_case.dart';
import '../../application/use_cases/build_dashboard_renewal_reminder_items_use_case.dart';
import '../../application/use_cases/build_dashboard_service_view_use_case.dart';
import '../../application/use_cases/build_dashboard_totals_summary_use_case.dart';
import '../../application/use_cases/build_dashboard_upcoming_renewals_use_case.dart';
import '../../application/use_cases/complete_sms_onboarding_use_case.dart';
import '../../application/use_cases/handle_local_control_overlay_use_case.dart';
import '../../application/use_cases/handle_manual_subscription_use_case.dart';
import '../../application/use_cases/handle_local_renewal_reminder_use_case.dart';
import '../../application/use_cases/handle_local_service_presentation_use_case.dart';
import '../../application/use_cases/handle_review_item_action_use_case.dart';
import '../../application/use_cases/load_sms_onboarding_progress_use_case.dart';
import '../../application/use_cases/load_runtime_dashboard_use_case.dart';
import '../../application/use_cases/sync_device_sms_use_case.dart';
import '../../application/use_cases/undo_local_control_overlay_use_case.dart';
import '../../application/use_cases/undo_review_item_action_use_case.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/enums/dashboard_bucket.dart';
import 'dashboard_primitives.dart';
import 'popular_service_catalog.dart';
import 'service_icon_registry.dart';

enum _DashboardDestination {
  home,
  subscriptions,
  review,
  settings,
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    LoadRuntimeDashboardUseCase? runtimeUseCase,
    SyncDeviceSmsUseCase? syncDeviceSmsUseCase,
    HandleReviewItemActionUseCase? handleReviewItemActionUseCase,
    UndoReviewItemActionUseCase? undoReviewItemActionUseCase,
    HandleLocalControlOverlayUseCase? handleLocalControlOverlayUseCase,
    UndoLocalControlOverlayUseCase? undoLocalControlOverlayUseCase,
    HandleLocalRenewalReminderUseCase? handleLocalRenewalReminderUseCase,
    HandleManualSubscriptionUseCase? handleManualSubscriptionUseCase,
    HandleLocalServicePresentationUseCase?
        handleLocalServicePresentationUseCase,
    LoadSmsOnboardingProgressUseCase? loadSmsOnboardingProgressUseCase,
    CompleteSmsOnboardingUseCase? completeSmsOnboardingUseCase,
  })  : _runtimeUseCase = runtimeUseCase,
        _syncDeviceSmsUseCase = syncDeviceSmsUseCase,
        _handleReviewItemActionUseCase = handleReviewItemActionUseCase,
        _undoReviewItemActionUseCase = undoReviewItemActionUseCase,
        _handleLocalControlOverlayUseCase = handleLocalControlOverlayUseCase,
        _undoLocalControlOverlayUseCase = undoLocalControlOverlayUseCase,
        _handleLocalRenewalReminderUseCase = handleLocalRenewalReminderUseCase,
        _handleManualSubscriptionUseCase = handleManualSubscriptionUseCase,
        _handleLocalServicePresentationUseCase =
            handleLocalServicePresentationUseCase,
        _loadSmsOnboardingProgressUseCase = loadSmsOnboardingProgressUseCase,
        _completeSmsOnboardingUseCase = completeSmsOnboardingUseCase;

  final LoadRuntimeDashboardUseCase? _runtimeUseCase;
  final SyncDeviceSmsUseCase? _syncDeviceSmsUseCase;
  final HandleReviewItemActionUseCase? _handleReviewItemActionUseCase;
  final UndoReviewItemActionUseCase? _undoReviewItemActionUseCase;
  final HandleLocalControlOverlayUseCase? _handleLocalControlOverlayUseCase;
  final UndoLocalControlOverlayUseCase? _undoLocalControlOverlayUseCase;
  final HandleLocalRenewalReminderUseCase? _handleLocalRenewalReminderUseCase;
  final HandleManualSubscriptionUseCase? _handleManualSubscriptionUseCase;
  final HandleLocalServicePresentationUseCase?
      _handleLocalServicePresentationUseCase;
  final LoadSmsOnboardingProgressUseCase? _loadSmsOnboardingProgressUseCase;
  final CompleteSmsOnboardingUseCase? _completeSmsOnboardingUseCase;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  static const Duration _minimumSyncIndicatorDuration = Duration(
    milliseconds: 600,
  );
  static const Duration _syncProgressTick = Duration(seconds: 1);
  static const Duration _polishMotionDuration = Duration(milliseconds: 180);
  late Future<RuntimeDashboardSnapshot> _snapshotFuture;
  RuntimeDashboardSnapshot? _lastSuccessfulSnapshot;
  bool _isSyncing = false;
  final ValueNotifier<Duration> _syncElapsedNotifier =
      ValueNotifier(Duration.zero);
  Timer? _syncProgressTimer;
  final Set<String> _reviewActionTargetsInFlight = <String>{};
  final Set<String> _localControlTargetsInFlight = <String>{};
  final Set<String> _localRenewalReminderTargetsInFlight = <String>{};
  final Set<String> _manualSubscriptionTargetsInFlight = <String>{};
  final Set<String> _localServicePresentationTargetsInFlight = <String>{};
  bool? _hasCompletedSmsOnboarding;
  final BuildDashboardServiceViewUseCase _buildDashboardServiceViewUseCase =
      const BuildDashboardServiceViewUseCase();
  final BuildDashboardTotalsSummaryUseCase _buildDashboardTotalsSummaryUseCase =
      const BuildDashboardTotalsSummaryUseCase();
  final BuildDashboardUpcomingRenewalsUseCase
      _buildDashboardUpcomingRenewalsUseCase =
      const BuildDashboardUpcomingRenewalsUseCase();
  final BuildDashboardDueSoonUseCase _buildDashboardDueSoonUseCase =
      const BuildDashboardDueSoonUseCase();
  final BuildDashboardRenewalReminderItemsUseCase
      _buildDashboardRenewalReminderItemsUseCase =
      const BuildDashboardRenewalReminderItemsUseCase();
  late final TextEditingController _serviceSearchController;
  _DashboardDestination _selectedDestination = _DashboardDestination.home;
  static const List<DashboardServiceFilterMode> _subscriptionsFilterModes =
      <DashboardServiceFilterMode>[
    DashboardServiceFilterMode.allVisible,
    DashboardServiceFilterMode.confirmedOnly,
    DashboardServiceFilterMode.separateAccessOnly,
  ];
  DashboardServiceViewControls _serviceViewControls =
      const DashboardServiceViewControls();

  @override
  void initState() {
    super.initState();
    _serviceSearchController = TextEditingController()
      ..addListener(_handleServiceSearchChanged);
    _snapshotFuture = _loadInitialSnapshot();
  }

  @override
  void dispose() {
    _syncProgressTimer?.cancel();
    _syncElapsedNotifier.dispose();
    _serviceSearchController
      ..removeListener(_handleServiceSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<RuntimeDashboardSnapshot> _loadInitialSnapshot() {
    return (widget._runtimeUseCase ?? LoadRuntimeDashboardUseCase()).execute();
  }

  void _reloadSnapshot() {
    setState(() {
      _snapshotFuture = _loadInitialSnapshot();
    });
  }

  void _handleServiceSearchChanged() {
    final nextQuery = _serviceSearchController.text;
    if (nextQuery == _serviceViewControls.searchQuery) {
      return;
    }

    setState(() {
      _serviceViewControls =
          _serviceViewControls.copyWith(searchQuery: nextQuery);
    });
  }

  void _setServiceSortMode(DashboardServiceSortMode sortMode) {
    if (sortMode == _serviceViewControls.sortMode) {
      return;
    }

    setState(() {
      _serviceViewControls = _serviceViewControls.copyWith(sortMode: sortMode);
    });
  }

  void _setServiceFilterMode(DashboardServiceFilterMode filterMode) {
    if (filterMode == _serviceViewControls.filterMode) {
      return;
    }

    setState(() {
      _serviceViewControls =
          _serviceViewControls.copyWith(filterMode: filterMode);
    });
  }

  void _clearServiceViewControls() {
    if (!_serviceViewControls.hasActiveControls &&
        _serviceSearchController.text.isEmpty) {
      return;
    }

    setState(() {
      _serviceViewControls = const DashboardServiceViewControls();
    });
    _serviceSearchController.clear();
  }

  void _selectDestination(_DashboardDestination destination) {
    if (destination == _selectedDestination) {
      return;
    }

    setState(() {
      _selectedDestination = destination;
    });
  }

  String _localIgnoreTargetKeyForReviewItem(ReviewItem item) {
    return LocalControlDecision.ignoreReviewItem(
      reviewItem: item,
      decidedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ).targetKey;
  }

  Future<void> _handleSyncWithSms() async {
    _syncProgressTimer?.cancel();
    _syncElapsedNotifier.value = Duration.zero;
    setState(() {
      _isSyncing = true;
    });
    _syncProgressTimer = Timer.periodic(_syncProgressTick, (_) {
      if (!mounted || !_isSyncing) {
        return;
      }
      _syncElapsedNotifier.value += _syncProgressTick;
    });

    try {
      final result =
          await (widget._syncDeviceSmsUseCase ?? SyncDeviceSmsUseCase.android())
              .execute();
      if (!mounted) {
        return;
      }

      await _completeSyncFeedbackWindow();
      if (!mounted) {
        return;
      }

      _syncElapsedNotifier.value = Duration.zero;
      setState(() {
        _snapshotFuture =
            Future<RuntimeDashboardSnapshot>.value(result.snapshot);
        _isSyncing = false;
      });
      _showFeedbackSnackBar(
        _syncMessage(result.requestResult, result.snapshot),
        action:
            result.requestResult == LocalMessageSourceAccessRequestResult.denied
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: _openSettingsDestination,
                  )
                : null,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _completeSyncFeedbackWindow();
      if (!mounted) {
        return;
      }

      _syncElapsedNotifier.value = Duration.zero;
      setState(() {
        _isSyncing = false;
      });
      _showFeedbackSnackBar(
        'Device SMS refresh failed. Current snapshot was kept.',
      );
    }
  }

  Future<void> _completeSyncFeedbackWindow() async {
    final remaining =
        _minimumSyncIndicatorDuration - _syncElapsedNotifier.value;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    _syncProgressTimer?.cancel();
    _syncProgressTimer = null;
  }

  Future<void> _handleSyncEntry(
    RuntimeLocalMessageSourceStatus status,
  ) async {
    if (status.permissionRationaleVariant == null) {
      return _handleSyncWithSms();
    }

    if (status.permissionRationaleVariant ==
        RuntimeLocalMessageSourcePermissionRationaleVariant.firstRun) {
      final hasCompletedOnboarding = await _readSmsOnboardingCompletion();
      if (hasCompletedOnboarding) {
        return _handleSyncWithSms();
      }

      _showSmsPermissionOnboarding();
      return;
    }

    _showSmsPermissionRationale(status.permissionRationaleVariant!);
  }

  Future<bool> _readSmsOnboardingCompletion() async {
    if (_hasCompletedSmsOnboarding != null) {
      return _hasCompletedSmsOnboarding!;
    }

    final completed = await (widget._loadSmsOnboardingProgressUseCase ??
            LoadSmsOnboardingProgressUseCase.persistent())
        .execute();
    _hasCompletedSmsOnboarding = completed;
    return completed;
  }

  Future<void> _markSmsOnboardingCompleted() async {
    _hasCompletedSmsOnboarding = true;
    await (widget._completeSmsOnboardingUseCase ??
            CompleteSmsOnboardingUseCase.persistent())
        .execute();
  }

  Future<bool> _handleCreateManualSubscription(
    _ManualSubscriptionFormValue value,
  ) async {
    const targetKey = 'manual-create';
    setState(() {
      _manualSubscriptionTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleManualSubscriptionUseCase ??
              HandleManualSubscriptionUseCase.persistent())
          .create(
        serviceName: value.serviceName,
        billingCycle: value.billingCycle,
        amountInput: value.amountInput,
        nextRenewalDate: value.nextRenewalDate,
        planLabel: value.planLabel,
      );
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: _manualMutationSuccessMessage(
          serviceName: value.serviceName.trim(),
          verb: 'added to your list',
          amountInput: value.amountInput,
          nextRenewalDate: value.nextRenewalDate,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _manualSubscriptionTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Added item could not be saved. Visible state was kept.',
      );
      return false;
    }
  }

  Future<bool> _handleUpdateManualSubscription(
    String id,
    _ManualSubscriptionFormValue value,
  ) async {
    final targetKey = id;
    setState(() {
      _manualSubscriptionTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleManualSubscriptionUseCase ??
              HandleManualSubscriptionUseCase.persistent())
          .update(
        id: id,
        serviceName: value.serviceName,
        billingCycle: value.billingCycle,
        amountInput: value.amountInput,
        nextRenewalDate: value.nextRenewalDate,
        planLabel: value.planLabel,
      );
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: _manualMutationSuccessMessage(
          serviceName: value.serviceName.trim(),
          verb: 'updated in your list',
          amountInput: value.amountInput,
          nextRenewalDate: value.nextRenewalDate,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _manualSubscriptionTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Added item could not be updated. Visible state was kept.',
      );
      return false;
    }
  }

  Future<bool> _handleDeleteManualSubscription(
    ManualSubscriptionEntry entry,
  ) async {
    final targetKey = entry.id;
    setState(() {
      _manualSubscriptionTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleManualSubscriptionUseCase ??
              HandleManualSubscriptionUseCase.persistent())
          .delete(id: entry.id);
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: '${entry.serviceName} removed from your list.',
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _manualSubscriptionTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Added item could not be removed. Visible state was kept.',
      );
      return false;
    }
  }

  Future<bool> _finishManualSubscriptionMutation({
    required String targetKey,
    required HandleManualSubscriptionResult result,
    required String successMessage,
  }) async {
    if (!mounted) {
      return false;
    }

    setState(() {
      _manualSubscriptionTargetsInFlight.remove(targetKey);
      if (result.snapshot != null) {
        _snapshotFuture =
            Future<RuntimeDashboardSnapshot>.value(result.snapshot);
      }
    });

    switch (result.outcome) {
      case HandleManualSubscriptionOutcome.created:
      case HandleManualSubscriptionOutcome.updated:
      case HandleManualSubscriptionOutcome.deleted:
        _showFeedbackSnackBar(successMessage);
        return true;
      case HandleManualSubscriptionOutcome.invalid:
        _showFeedbackSnackBar(
          result.errorMessage ?? 'Please check the added item and try again.',
        );
        return false;
      case HandleManualSubscriptionOutcome.notFound:
        _showFeedbackSnackBar(
          'Nothing changed. The manual entry was not available.',
        );
        return false;
    }
  }

  String _manualMutationSuccessMessage({
    required String serviceName,
    required String verb,
    required String amountInput,
    required DateTime? nextRenewalDate,
  }) {
    final hasAmount = amountInput.trim().isNotEmpty;
    final hasRenewalDate = nextRenewalDate != null;
    if (hasAmount && hasRenewalDate) {
      return '$serviceName $verb. It can now contribute to your estimate and renewals.';
    }
    if (hasAmount) {
      return '$serviceName $verb. It can now contribute to your estimate.';
    }
    if (hasRenewalDate) {
      return '$serviceName $verb. It can now appear in renewals and reminders.';
    }
    return '$serviceName $verb.';
  }

  Future<void> _handleReviewItemAction(
    ReviewItem item,
    ReviewItemAction action,
  ) async {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
    setState(() {
      _reviewActionTargetsInFlight.add(descriptor.targetKey);
    });

    try {
      final result = await (widget._handleReviewItemActionUseCase ??
              HandleReviewItemActionUseCase.persistent())
          .execute(reviewItem: item, action: action);
      if (!mounted) {
        return;
      }

      setState(() {
        _reviewActionTargetsInFlight.remove(descriptor.targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showReviewActionResult(
        outcome: result.outcome,
        title: item.title,
        targetKey: descriptor.targetKey,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reviewActionTargetsInFlight.remove(descriptor.targetKey);
      });
      _showFeedbackSnackBar(
        'Review update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleUndoReviewItemAction({
    required String targetKey,
    required String title,
  }) async {
    setState(() {
      _reviewActionTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._undoReviewItemActionUseCase ??
              UndoReviewItemActionUseCase.persistent())
          .execute(targetKey: targetKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _reviewActionTargetsInFlight.remove(targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showUndoReviewActionResult(result.outcome, title);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reviewActionTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar('Undo failed. Visible review state was kept.');
    }
  }

  Future<void> _handleIgnoreCard(DashboardCard card) async {
    final targetKey = 'service::${card.serviceKey.value}';
    setState(() {
      _localControlTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleLocalControlOverlayUseCase ??
              HandleLocalControlOverlayUseCase.persistent())
          .ignoreCard(card);
      if (!mounted) {
        return;
      }

      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        '${card.title} ignored locally.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: card.title,
              restoredLabel: 'returned to the dashboard',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Local control update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleHideCard(DashboardCard card) async {
    final targetKey = 'card::${card.bucket.name}::${card.serviceKey.value}';
    setState(() {
      _localControlTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleLocalControlOverlayUseCase ??
              HandleLocalControlOverlayUseCase.persistent())
          .hideCard(card);
      if (!mounted) {
        return;
      }

      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        '${card.title} hidden locally.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: card.title,
              restoredLabel: 'returned to the dashboard',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Local control update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleIgnoreReviewItem(ReviewItem item) async {
    final targetKey = _localIgnoreTargetKeyForReviewItem(item);
    setState(() {
      _localControlTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._handleLocalControlOverlayUseCase ??
              HandleLocalControlOverlayUseCase.persistent())
          .ignoreReviewItem(item);
      if (!mounted) {
        return;
      }

      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        '${item.title} hidden on this device.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: item.title,
              restoredLabel: 'returned to review on this device',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Local control update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleUndoLocalControlOverlay({
    required String targetKey,
    required String title,
    required String restoredLabel,
  }) async {
    setState(() {
      _localControlTargetsInFlight.add(targetKey);
    });

    try {
      final result = await (widget._undoLocalControlOverlayUseCase ??
              UndoLocalControlOverlayUseCase.persistent())
          .execute(targetKey: targetKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      final message = switch (result.outcome) {
        LocalControlUndoOutcome.restored => '$title $restoredLabel.',
        LocalControlUndoOutcome.notFound =>
          'Nothing changed. No local control was removed.',
      };
      _showFeedbackSnackBar(message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localControlTargetsInFlight.remove(targetKey);
      });
      _showFeedbackSnackBar(
        'Undo failed. Visible local controls were kept.',
      );
    }
  }

  Future<void> _handleSaveLocalLabel({
    required DashboardCard card,
    required String label,
    required String originalTitle,
  }) async {
    final serviceKey = card.serviceKey.value;
    setState(() {
      _localServicePresentationTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalServicePresentationUseCase ??
              HandleLocalServicePresentationUseCase.persistent())
          .saveLocalLabel(card: card, label: label);
      if (!mounted) {
        return;
      }

      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar('$originalTitle label updated locally.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Local organization update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleResetLocalLabel({
    required String serviceKey,
    required String originalTitle,
  }) async {
    setState(() {
      _localServicePresentationTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalServicePresentationUseCase ??
              HandleLocalServicePresentationUseCase.persistent())
          .resetLocalLabel(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle label reset to the detected name.'
            : 'Nothing changed. No local label was reset.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Local organization update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handlePinService({
    required DashboardCard card,
    required String originalTitle,
  }) async {
    final serviceKey = card.serviceKey.value;
    setState(() {
      _localServicePresentationTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalServicePresentationUseCase ??
              HandleLocalServicePresentationUseCase.persistent())
          .pinService(card);
      if (!mounted) {
        return;
      }

      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle pinned locally.'
            : 'Nothing changed. This service was already pinned.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Local organization update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleUnpinService({
    required String serviceKey,
    required String originalTitle,
  }) async {
    setState(() {
      _localServicePresentationTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalServicePresentationUseCase ??
              HandleLocalServicePresentationUseCase.persistent())
          .unpinService(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle unpinned locally.'
            : 'Nothing changed. This service was not pinned.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localServicePresentationTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Local organization update failed. Visible state did not change.',
      );
    }
  }

  Future<void> _handleEnableRenewalReminder({
    required DashboardRenewalReminderItemPresentation item,
    required RenewalReminderLeadTimePreset preset,
  }) async {
    final serviceKey = item.renewal.serviceKey;
    setState(() {
      _localRenewalReminderTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalRenewalReminderUseCase ??
              HandleLocalRenewalReminderUseCase.persistent())
          .enableReminder(item: item, leadTimePreset: preset);
      if (!mounted) {
        return;
      }

      setState(() {
        _localRenewalReminderTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      switch (result.outcome) {
        case LocalRenewalReminderOutcome.enabled:
          _showFeedbackSnackBar(
            '${item.renewal.serviceTitle} reminder set for ${preset.label}.',
          );
          break;
        case LocalRenewalReminderOutcome.unchanged:
          _showFeedbackSnackBar(
            'Nothing changed. That reminder was already set.',
          );
          break;
        case LocalRenewalReminderOutcome.failed:
        case LocalRenewalReminderOutcome.disabled:
          _showFeedbackSnackBar(
            'Reminder could not be scheduled from the current renewal timing.',
          );
          break;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localRenewalReminderTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Reminder update failed. Local reminder state did not change.',
      );
    }
  }

  Future<void> _handleDisableRenewalReminder({
    required String serviceKey,
    required String serviceTitle,
  }) async {
    setState(() {
      _localRenewalReminderTargetsInFlight.add(serviceKey);
    });

    try {
      final result = await (widget._handleLocalRenewalReminderUseCase ??
              HandleLocalRenewalReminderUseCase.persistent())
          .disableReminder(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }

      setState(() {
        _localRenewalReminderTargetsInFlight.remove(serviceKey);
        if (result.snapshot != null) {
          _snapshotFuture = Future<RuntimeDashboardSnapshot>.value(
            result.snapshot,
          );
        }
      });
      switch (result.outcome) {
        case LocalRenewalReminderOutcome.disabled:
          _showFeedbackSnackBar('$serviceTitle reminder removed locally.');
          break;
        case LocalRenewalReminderOutcome.unchanged:
          _showFeedbackSnackBar('Nothing changed. No reminder was removed.');
          break;
        case LocalRenewalReminderOutcome.failed:
        case LocalRenewalReminderOutcome.enabled:
          _showFeedbackSnackBar(
            'Reminder could not be removed from the current local state.',
          );
          break;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localRenewalReminderTargetsInFlight.remove(serviceKey);
      });
      _showFeedbackSnackBar(
        'Reminder update failed. Local reminder state did not change.',
      );
    }
  }

  void _showRenewalReminderControls(
    DashboardRenewalReminderItemPresentation item,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _RenewalReminderControlsSheet(
        item: item,
        isBusy: _localRenewalReminderTargetsInFlight.contains(
          item.renewal.serviceKey,
        ),
        onSelectPreset: (preset) {
          Navigator.of(sheetContext).pop();
          return _handleEnableRenewalReminder(
            item: item,
            preset: preset,
          );
        },
        onDisable: item.selectedPreset == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                return _handleDisableRenewalReminder(
                  serviceKey: item.renewal.serviceKey,
                  serviceTitle: item.renewal.serviceTitle,
                );
              },
      ),
    );
  }

  void _showLocalServiceControls(
    DashboardCard card,
    LocalServicePresentationState servicePresentationState,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _LocalServiceControlsSheet(
        card: card,
        servicePresentationState: servicePresentationState,
        isBusy: _localServicePresentationTargetsInFlight.contains(
          card.serviceKey.value,
        ),
        onSaveLabel: (label) {
          Navigator.of(sheetContext).pop();
          return _handleSaveLocalLabel(
            card: card,
            label: label,
            originalTitle: servicePresentationState.originalTitle,
          );
        },
        onResetLabel: servicePresentationState.hasLocalLabel
            ? () {
                Navigator.of(sheetContext).pop();
                return _handleResetLocalLabel(
                  serviceKey: card.serviceKey.value,
                  originalTitle: servicePresentationState.originalTitle,
                );
              }
            : null,
        onTogglePin: () {
          Navigator.of(sheetContext).pop();
          return servicePresentationState.isPinned
              ? _handleUnpinService(
                  serviceKey: card.serviceKey.value,
                  originalTitle: servicePresentationState.originalTitle,
                )
              : _handlePinService(
                  card: card,
                  originalTitle: servicePresentationState.originalTitle,
                );
        },
      ),
    );
  }

  void _showSubscriptionDetails(
    DashboardCard card,
    DashboardBucket bucket,
    LocalServicePresentationState servicePresentationState,
    DashboardUpcomingRenewalItemPresentation? renewal,
    List<DashboardRenewalReminderItemPresentation> renewalReminderItems,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (context) => _SubscriptionDetailsSheet(
        card: card,
        bucket: bucket,
        servicePresentationState: servicePresentationState,
        metadata: _SubscriptionCardMetadata.fromCard(
          card,
          renewal: renewal,
        ),
        renewal: renewal,
        onExplain: () {
          Navigator.of(context).pop();
          _showContextualExplanation(
            ContextualExplanationPresentation.forDashboardCard(card),
          );
        },
        onOpenLocalServiceControls: () {
          Navigator.of(context).pop();
          _showLocalServiceControls(card, servicePresentationState);
        },
        onOpenRenewalReminderControls: renewal == null
            ? null
            : () {
                final reminderItem = renewalReminderItems.firstWhere(
                  (item) => item.renewal.serviceKey == renewal.serviceKey,
                );
                Navigator.of(context).pop();
                _showRenewalReminderControls(reminderItem);
              },
      ),
    );
  }

  String _syncMessage(
    LocalMessageSourceAccessRequestResult result,
    RuntimeDashboardSnapshot snapshot,
  ) {
    final keptRestoredSnapshot = snapshot.provenance.kind ==
        RuntimeSnapshotProvenanceKind.restoredLocalSnapshot;
    final confirmedCount = snapshot.cards
        .where(
          (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
        )
        .length;
    return switch (result) {
      LocalMessageSourceAccessRequestResult.granted =>
        snapshot.reviewQueue.isNotEmpty && confirmedCount == 0
            ? 'Finished checking SMS. Some items are still in Review.'
            : confirmedCount == 0
                ? 'Finished checking SMS. No paid subscriptions were confirmed yet.'
                : 'Finished checking SMS. Results updated.',
      LocalMessageSourceAccessRequestResult.denied => keptRestoredSnapshot
          ? 'SMS access was not granted. Keeping the last saved results on this device.'
          : 'Device SMS access was not granted. You can keep browsing and try again later.',
      LocalMessageSourceAccessRequestResult.unavailable => keptRestoredSnapshot
          ? 'SMS refresh is unavailable on this device. Keeping the last saved results.'
          : 'SMS refresh is unavailable on this device.',
    };
  }

  void _showReviewActionResult({
    required ReviewItemActionOutcome outcome,
    required String title,
    required String targetKey,
  }) {
    final message = switch (outcome) {
      ReviewItemActionOutcome.confirmed =>
        '$title added to confirmed subscriptions.',
      ReviewItemActionOutcome.markedAsBenefit =>
        '$title kept separate as a benefit.',
      ReviewItemActionOutcome.dismissed =>
        '$title marked as not a subscription.',
      ReviewItemActionOutcome.notAllowed =>
        'SubWatch still needs clearer service details before this can be confirmed.',
    };

    _showFeedbackSnackBar(
      message,
      action: switch (outcome) {
        ReviewItemActionOutcome.confirmed ||
        ReviewItemActionOutcome.markedAsBenefit ||
        ReviewItemActionOutcome.dismissed =>
          SnackBarAction(
            label: 'Undo',
            onPressed: () {
              _handleUndoReviewItemAction(
                targetKey: targetKey,
                title: title,
              );
            },
          ),
        ReviewItemActionOutcome.notAllowed => null,
      },
    );
  }

  void _showUndoReviewActionResult(
    ReviewItemUndoOutcome outcome,
    String title,
  ) {
    final message = switch (outcome) {
      ReviewItemUndoOutcome.restored => '$title returned to review.',
      ReviewItemUndoOutcome.notFound =>
        'Nothing changed. No review item was restored.',
    };

    _showFeedbackSnackBar(message);
  }

  void _showFeedbackSnackBar(
    String message, {
    SnackBarAction? action,
  }) {
    final reduceMotion = _shouldReduceMotion(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      ),
      snackBarAnimationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 190),
              reverseDuration: Duration(milliseconds: 150),
            ),
    );
  }

  AnimationStyle _dashboardSheetAnimationStyle() {
    return _shouldReduceMotion(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 240),
            reverseDuration: Duration(milliseconds: 190),
          );
  }

  Future<T?> _showDashboardBottomSheet<T>({
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      sheetAnimationStyle: _dashboardSheetAnimationStyle(),
      builder: builder,
    );
  }

  void _showContextualExplanation(
    ContextualExplanationPresentation presentation,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (context) =>
          _ContextualExplanationSheet(presentation: presentation),
    );
  }

  void _showReviewItemDetails(
    ReviewItem item,
    ReviewItemActionDescriptor descriptor,
    ReviewQueueItemPresentation presentation,
    ContextualExplanationPresentation explanation,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ReviewItemDetailsSheet(
        item: item,
        descriptor: descriptor,
        presentation: presentation,
        explanation: explanation,
        isBusy: _reviewActionTargetsInFlight.contains(descriptor.targetKey),
        onConfirm: descriptor.canConfirm
            ? () {
                Navigator.of(sheetContext).pop();
                _handleReviewItemAction(
                  item,
                  ReviewItemAction.confirmSubscription,
                );
              }
            : null,
        onMarkAsBenefit: presentation.benefitLabel == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _handleReviewItemAction(
                  item,
                  ReviewItemAction.markAsBenefit,
                );
              },
        onDismiss: () {
          Navigator.of(sheetContext).pop();
          _handleReviewItemAction(
            item,
            ReviewItemAction.dismissNotSubscription,
          );
        },
        onEditDetails: () {
          final initialServiceName = descriptor.canConfirm ? item.title : null;
          const String? initialPlanLabel = null;
          Navigator.of(sheetContext).pop();
          _showCreateManualSubscriptionForm(
            initialServiceName: initialServiceName,
            initialPlanLabel: initialPlanLabel,
          );
        },
        onExplain: () {
          Navigator.of(sheetContext).pop();
          _showContextualExplanation(explanation);
        },
      ),
    );
  }

  void _showTotalsExplanation(
    DashboardTotalsSummaryPresentation presentation,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (context) => _TotalsExplanationSheet(
        presentation: presentation,
      ),
    );
  }

  Future<void> _openReviewDestination() async {
    _selectDestination(_DashboardDestination.review);
  }

  Future<void> _openSubscriptionsDestination() async {
    _selectDestination(_DashboardDestination.subscriptions);
  }

  void _openSettingsDestination() {
    _selectDestination(_DashboardDestination.settings);
  }

  void _showSmsPermissionOnboarding() {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _SmsPermissionOnboardingSheet(
        onBrowseFirst: () async {
          await _markSmsOnboardingCompleted();
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
        onContinue: () async {
          await _markSmsOnboardingCompleted();
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
          return _handleSyncWithSms();
        },
      ),
    );
  }

  void _showSmsPermissionRationale(
    RuntimeLocalMessageSourcePermissionRationaleVariant variant,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _SmsPermissionRationaleSheet(
        variant: variant,
        onContinue: () {
          Navigator.of(sheetContext).pop();
          return _handleSyncWithSms();
        },
        onSecondaryAction: () {
          Navigator.of(sheetContext).pop();
          if (variant ==
              RuntimeLocalMessageSourcePermissionRationaleVariant.retry) {
            _openSettingsDestination();
          }
        },
      ),
    );
  }

  void _showTrustHowItWorksSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _TrustHowItWorksSheet(),
    );
  }

  void _showPrivacyLocalDataSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _PrivacyLocalDataSheet(),
    );
  }

  void _showHelpSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _HelpSheet(),
    );
  }

  void _showAboutSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _AboutSubWatchSheet(),
    );
  }

  void _showFeedbackSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _FeedbackSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinationTitle = _destinationTitle(_selectedDestination);
    final destinationSubtitle = _destinationSubtitle(_selectedDestination);
    final reduceMotion = _shouldReduceMotion(context);

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : _polishMotionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            final position = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: position,
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey<String>(
              'destination-title-$destinationTitle-${destinationSubtitle ?? ''}',
            ),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  destinationTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (destinationSubtitle != null)
                Text(
                  destinationSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
            ],
          ),
        ),
      ),
      body: DashboardBackdrop(
        child: FutureBuilder<RuntimeDashboardSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final preservedSnapshot = snapshot.data ?? _lastSuccessfulSnapshot;

            if (snapshot.connectionState != ConnectionState.done) {
              if (preservedSnapshot != null) {
                return _buildDashboardContent(
                  preservedSnapshot,
                  loadRecoveryState: const _LoadRecoveryState.reloading(),
                );
              }
              return const _DashboardLoadingState();
            }

            if (snapshot.hasError) {
              if (preservedSnapshot != null) {
                return _buildDashboardContent(
                  preservedSnapshot,
                  loadRecoveryState: const _LoadRecoveryState.failed(),
                );
              }
              return _DashboardErrorState(
                onRetry: _reloadSnapshot,
              );
            }

            return _buildDashboardContent(snapshot.data!);
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey<String>('top-level-navigation'),
        selectedIndex: _selectedDestination.index,
        onDestinationSelected: (index) {
          _selectDestination(_DashboardDestination.values[index]);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            key: ValueKey<String>('destination-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey<String>('destination-subscriptions'),
            icon: Icon(Icons.subscriptions_outlined),
            selectedIcon: Icon(Icons.subscriptions_rounded),
            label: 'Subscriptions',
          ),
          NavigationDestination(
            key: ValueKey<String>('destination-review'),
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Review',
          ),
          NavigationDestination(
            key: ValueKey<String>('destination-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _destinationTitle(_DashboardDestination destination) {
    switch (destination) {
      case _DashboardDestination.home:
        return 'SubWatch';
      case _DashboardDestination.subscriptions:
        return 'Subscriptions';
      case _DashboardDestination.review:
        return 'Review';
      case _DashboardDestination.settings:
        return 'Settings';
    }
  }

  String? _destinationSubtitle(_DashboardDestination destination) {
    switch (destination) {
      case _DashboardDestination.home:
        return null;
      case _DashboardDestination.subscriptions:
        return 'Your list';
      case _DashboardDestination.review:
        return 'Needs attention';
      case _DashboardDestination.settings:
        return 'On this device';
    }
  }

  Widget _buildHomeDestination({
    required RuntimeDashboardSnapshot data,
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required DashboardCompletionPresentation completion,
    required DashboardTotalsSummaryPresentation totalsSummary,
    required DashboardDueSoonPresentation dueSoon,
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required List<DashboardRenewalReminderItemPresentation>
        renewalReminderItems,
  }) {
    final isZeroConfirmedRescue =
        completion.kind == DashboardCompletionKind.zeroConfirmedRescue;
    final showHomeFocus = !isZeroConfirmedRescue &&
        sourceStatus.tone != RuntimeLocalMessageSourceTone.demo;
    final showDueSoon =
        sourceStatus.tone != RuntimeLocalMessageSourceTone.demo &&
            (!isZeroConfirmedRescue || dueSoon.hasItems);
    final showUpcomingRenewals =
        !isZeroConfirmedRescue || upcomingRenewals.hasItems;
    final showStatusFirst =
        _isSyncing || sourceStatus.tone != RuntimeLocalMessageSourceTone.fresh;
    final completionPanel = completion.showPanel
        ? switch (completion.kind) {
            DashboardCompletionKind.zeroConfirmedRescue =>
              _ZeroConfirmedRescuePanel(
                completion: completion,
                rescueState: _ZeroConfirmedRescueState.fromSnapshot(
                  data,
                  sourceStatus: sourceStatus,
                ),
                onOpenReview: _openReviewDestination,
                onOpenSubscriptions: _openSubscriptionsDestination,
                onAddManually: _showCreateManualSubscriptionForm,
                onOpenTrustSheet: _showTrustHowItWorksSheet,
              ),
            DashboardCompletionKind.standard => _ProductGuidancePanel(
                completion: completion,
                samplePreview:
                    sourceStatus.tone == RuntimeLocalMessageSourceTone.demo
                        ? _SampleHomePreviewState.fromSnapshot(
                            data,
                            totalsSummary: totalsSummary,
                            dueSoon: dueSoon,
                          )
                        : null,
                onPrimaryAction: switch (completion.primaryAction) {
                  DashboardCompletionPrimaryAction.sync =>
                    sourceStatus.isActionEnabled && !_isSyncing
                        ? () => _handleSyncEntry(sourceStatus)
                        : null,
                  DashboardCompletionPrimaryAction.review =>
                    _openReviewDestination,
                  DashboardCompletionPrimaryAction.learn => () async =>
                      _showTrustHowItWorksSheet(),
                  DashboardCompletionPrimaryAction.none => null,
                },
                onOpenTrustSheet: completion.showLearnMoreAction
                    ? _showTrustHowItWorksSheet
                    : null,
              ),
          }
        : null;
    final sourceStatusCard = _SourceStatusCard(
      status: sourceStatus,
      isSyncing: _isSyncing,
      syncElapsed: _syncElapsedNotifier,
      onSync: () => _handleSyncEntry(sourceStatus),
      onExplain: () => _showContextualExplanation(
        ContextualExplanationPresentation.forRuntimeStatus(
          sourceStatus,
        ),
      ),
    );
    final homeChildren = <Widget>[
      if (showStatusFirst) ...<Widget>[
        sourceStatusCard,
        const SizedBox(height: 12),
      ],
      if (showHomeFocus) ...<Widget>[
        _HomeFocusCard(
          sourceStatus: sourceStatus,
          reviewCount: data.reviewQueue.length,
          dueSoon: dueSoon,
          upcomingRenewals: upcomingRenewals,
          onReview: _openReviewDestination,
          onSync: () => _handleSyncEntry(sourceStatus),
        ),
        const SizedBox(height: 12),
      ],
      if (isZeroConfirmedRescue && completionPanel != null) ...<Widget>[
        completionPanel,
        const SizedBox(height: 12),
      ],
      _TotalsSummaryCard(
        presentation: totalsSummary,
        sourceStatus: sourceStatus,
        onExplain: () => _showTotalsExplanation(totalsSummary),
      ),
      if (!showStatusFirst) ...<Widget>[
        const SizedBox(height: 12),
        sourceStatusCard,
      ],
      if (!isZeroConfirmedRescue && completionPanel != null) ...<Widget>[
        const SizedBox(height: 12),
        completionPanel,
      ],
      if (showDueSoon) ...<Widget>[
        const SizedBox(height: 12),
        _DueSoonCard(
          presentation: dueSoon,
        ),
      ],
      if (showUpcomingRenewals) ...<Widget>[
        const SizedBox(height: 16),
        _UpcomingRenewalsCard(
          presentation: upcomingRenewals,
          reminderItems: renewalReminderItems,
          showReminderControls: false,
          onOpenReminderControls: _showRenewalReminderControls,
          reminderTargetsInFlight: _localRenewalReminderTargetsInFlight,
        ),
      ],
    ];

    return ListView(
      key: const PageStorageKey<String>('destination-home-surface'),
      cacheExtent: 2000,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: homeChildren,
    );
  }

  bool _snapshotHasLocalModifications(RuntimeDashboardSnapshot data) {
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

  Widget _buildDashboardContent(
    RuntimeDashboardSnapshot data, {
    _LoadRecoveryState? loadRecoveryState,
  }) {
    _lastSuccessfulSnapshot = data;

    final sourceStatus = RuntimeLocalMessageSourceStatus.fromSelection(
      data.messageSourceSelection,
      provenance: data.provenance,
      hasLocalModifications: _snapshotHasLocalModifications(data),
    );
    final completion = DashboardCompletionPresentation.fromSnapshot(data);
    final totalsSummary = _buildDashboardTotalsSummaryUseCase.execute(
      cards: data.cards,
      manualSubscriptions: data.manualSubscriptions,
      reviewCount: data.reviewQueue.length,
    );
    final upcomingRenewals = _buildDashboardUpcomingRenewalsUseCase.execute(
      cards: data.cards,
      manualSubscriptions: data.manualSubscriptions,
      now: data.provenance.recordedAt,
    );
    final dueSoon = _buildDashboardDueSoonUseCase.execute(
      upcomingRenewals: upcomingRenewals,
    );
    final renewalReminderItems =
        _buildDashboardRenewalReminderItemsUseCase.execute(
      upcomingRenewals: upcomingRenewals,
      preferencesByServiceKey: data.localRenewalReminderPreferences,
      now: data.provenance.recordedAt,
    );
    final subscriptionBrowseCards = data.cards
        .where(
          (card) =>
              card.bucket == DashboardBucket.confirmedSubscriptions ||
              card.bucket == DashboardBucket.trialsAndBenefits,
        )
        .toList(growable: false);
    final serviceView = _buildDashboardServiceViewUseCase.execute(
      cards: subscriptionBrowseCards,
      localServicePresentationStates: data.localServicePresentationStates,
      controls: _serviceViewControls,
    );
    final visibleServiceSections = serviceView.sections
        .where((section) => section.cards.isNotEmpty)
        .toList(growable: false);

    final content = IndexedStack(
      index: _selectedDestination.index,
      children: <Widget>[
        _buildHomeDestination(
          data: data,
          sourceStatus: sourceStatus,
          completion: completion,
          totalsSummary: totalsSummary,
          dueSoon: dueSoon,
          upcomingRenewals: upcomingRenewals,
          renewalReminderItems: renewalReminderItems,
        ),
        _buildSubscriptionsDestination(
          data: data,
          serviceView: serviceView,
          visibleServiceSections: visibleServiceSections,
          upcomingRenewals: upcomingRenewals,
          renewalReminderItems: renewalReminderItems,
        ),
        _buildReviewDestination(data: data),
        _buildSettingsDestination(
          data: data,
          sourceStatus: sourceStatus,
          reminderItems: renewalReminderItems,
        ),
      ],
    );

    if (loadRecoveryState == null) {
      return content;
    }

    return Column(
      children: <Widget>[
        _DashboardLoadRecoveryNotice(
          state: loadRecoveryState,
          onRetry: loadRecoveryState.showRetryAction ? _reloadSnapshot : null,
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSubscriptionsDestination({
    required RuntimeDashboardSnapshot data,
    required DashboardServiceViewResult serviceView,
    required List<DashboardServiceSectionView> visibleServiceSections,
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required List<DashboardRenewalReminderItemPresentation>
        renewalReminderItems,
  }) {
    final visibleManualSubscriptions = _visibleManualSubscriptions(
      data.manualSubscriptions,
      _serviceViewControls,
    );
    final showManualSection =
        _shouldShowManualSubscriptions(_serviceViewControls.filterMode) &&
            visibleManualSubscriptions.isNotEmpty;
    final showSingleEmptySection =
        visibleServiceSections.isEmpty && !showManualSection;
    final emptyBucket = _emptyStateBucketForFilter(
      serviceView.controls.filterMode,
    );

    return ListView(
      key: const PageStorageKey<String>('destination-subscriptions-surface'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: <Widget>[
        _ServiceViewControlsPanel(
          searchController: _serviceSearchController,
          controls: _serviceViewControls,
          availableFilterModes: _subscriptionsFilterModes,
          visibleCountLabel: _serviceViewVisibleCountLabel(
            serviceView.totalVisibleCount + visibleManualSubscriptions.length,
          ),
          onAddManual: _showCreateManualSubscriptionForm,
          onSortChanged: _setServiceSortMode,
          onFilterChanged: _setServiceFilterMode,
          onClear: _clearServiceViewControls,
        ),
        const SizedBox(height: 10),
        if (serviceView.controls.restrictsResults &&
            !serviceView.hasMatches &&
            visibleManualSubscriptions.isEmpty) ...<Widget>[
          _ServiceViewEmptyState(
            onClear: _clearServiceViewControls,
          ),
        ] else ...<Widget>[
          if (showManualSection)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DashboardSection(
                key: const ValueKey<String>('section-manualSubscriptions'),
                title: 'Added by you',
                countLabel: _manualEntryCountLabel(
                  visibleManualSubscriptions.length,
                ),
                caption:
                    'Added by you on this device. Use this when a scan is limited or you want something tracked right away without changing detected results.',
                children: _buildManualSubscriptionRows(
                  visibleManualSubscriptions,
                  upcomingRenewals,
                  renewalReminderItems,
                ),
              ),
            ),
          ...visibleServiceSections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DashboardSection(
                key: ValueKey<String>('section-${section.bucket.name}'),
                title: _serviceSectionTitle(section.bucket),
                countLabel: _bucketCountLabel(section.bucket, section.count),
                caption: _serviceSectionCaption(section.bucket),
                children: _buildSubscriptionSectionChildren(
                  section.cards,
                  data.localServicePresentationStates,
                  section.bucket,
                  upcomingRenewals: upcomingRenewals,
                  renewalReminderItems: renewalReminderItems,
                  emptyTitle: _serviceSectionEmptyTitle(section.bucket),
                  emptyMessage: _serviceSectionEmptyMessage(section.bucket),
                ),
              ),
            ),
          ),
          if (showSingleEmptySection)
            _DashboardSection(
              key: ValueKey<String>('section-${emptyBucket.name}'),
              title: _serviceSectionTitle(emptyBucket),
              countLabel: _bucketCountLabel(emptyBucket, 0),
              caption: _serviceSectionCaption(emptyBucket),
              children: <Widget>[
                _EmptySectionText(
                  title: _serviceSectionEmptyTitle(emptyBucket),
                  message: _serviceSectionEmptyMessage(emptyBucket),
                  icon: _emptyStateIcon(emptyBucket),
                ),
              ],
            ),
        ],
      ],
    );
  }

  bool _shouldShowManualSubscriptions(
    DashboardServiceFilterMode filterMode,
  ) {
    return filterMode == DashboardServiceFilterMode.allVisible ||
        filterMode == DashboardServiceFilterMode.confirmedOnly;
  }

  DashboardBucket _emptyStateBucketForFilter(
    DashboardServiceFilterMode filterMode,
  ) {
    switch (filterMode) {
      case DashboardServiceFilterMode.allVisible:
      case DashboardServiceFilterMode.confirmedOnly:
        return DashboardBucket.confirmedSubscriptions;
      case DashboardServiceFilterMode.observedOnly:
        return DashboardBucket.needsReview;
      case DashboardServiceFilterMode.separateAccessOnly:
        return DashboardBucket.trialsAndBenefits;
    }
  }

  List<ManualSubscriptionEntry> _visibleManualSubscriptions(
    List<ManualSubscriptionEntry> entries,
    DashboardServiceViewControls controls,
  ) {
    if (!_shouldShowManualSubscriptions(controls.filterMode)) {
      return const <ManualSubscriptionEntry>[];
    }

    final normalizedQuery = controls.normalizedSearchQuery.toLowerCase();
    final filtered = entries
        .where(
          (entry) =>
              normalizedQuery.isEmpty ||
              entry.serviceName.toLowerCase().contains(normalizedQuery) ||
              (entry.planLabel?.toLowerCase().contains(normalizedQuery) ??
                  false),
        )
        .toList(growable: false);
    final sorted = filtered.toList(growable: false)
      ..sort((left, right) {
        switch (controls.sortMode) {
          case DashboardServiceSortMode.currentOrder:
            return right.updatedAt.compareTo(left.updatedAt);
          case DashboardServiceSortMode.nameAscending:
            return left.serviceName
                .toLowerCase()
                .compareTo(right.serviceName.toLowerCase());
          case DashboardServiceSortMode.nameDescending:
            return right.serviceName
                .toLowerCase()
                .compareTo(left.serviceName.toLowerCase());
        }
      });
    return sorted;
  }

  Widget _buildReviewDestination({
    required RuntimeDashboardSnapshot data,
  }) {
    return ListView(
      key: const PageStorageKey<String>('destination-review-surface'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: <Widget>[
        _ReviewQueueSummaryCard(
          reviewCount: data.reviewQueue.length,
        ),
        const SizedBox(height: 12),
        _DashboardSection(
          key: const ValueKey<String>('section-reviewQueue'),
          title: 'Items for your review',
          countLabel: _reviewItemCountLabel(data.reviewQueue.length),
          caption: data.reviewQueue.isEmpty
              ? 'Nothing is waiting for your decision right now.'
              : 'These items stay separate by design until you decide. Every choice stays local to this device and can be undone later.',
          children: _buildReviewRows(
            data.reviewQueue,
            emptyTitle: 'Nothing to review right now',
            emptyMessage:
                'SubWatch only uses Review for items that still look uncertain. If later evidence still needs your decision, it will appear here again.',
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsDestination({
    required RuntimeDashboardSnapshot data,
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required List<DashboardRenewalReminderItemPresentation> reminderItems,
  }) {
    final hasRecovery = data.confirmedReviewItems.isNotEmpty ||
        data.benefitReviewItems.isNotEmpty ||
        data.dismissedReviewItems.isNotEmpty ||
        data.ignoredLocalItems.isNotEmpty ||
        data.hiddenLocalItems.isNotEmpty;
    final recoveryCount = data.confirmedReviewItems.length +
        data.benefitReviewItems.length +
        data.dismissedReviewItems.length +
        data.ignoredLocalItems.length +
        data.hiddenLocalItems.length;
    final quickActions = <Widget>[
      _SettingsNavRow(
        tileKey: const ValueKey<String>('settings-source-action'),
        icon: _settingsSourceActionIcon(sourceStatus),
        title: _isSyncing
            ? 'Checking messages'
            : _settingsSourceActionTitle(sourceStatus),
        subtitle: _isSyncing
            ? 'A message check is already running on this device.'
            : _settingsSourceActionSubtitle(sourceStatus),
        onTap: _isSyncing
            ? null
            : () {
                if (sourceStatus.isActionEnabled) {
                  _handleSyncEntry(sourceStatus);
                  return;
                }
                _showContextualExplanation(
                  ContextualExplanationPresentation.forRuntimeStatus(
                    sourceStatus,
                  ),
                );
              },
        trailing: _isSyncing
            ? Text(
                'Working...',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
              )
            : null,
      ),
    ];
    if (data.reviewQueue.isNotEmpty) {
      quickActions.add(const _SettingsGroupDivider());
      quickActions.add(
        _SettingsNavRow(
          tileKey: const ValueKey<String>('settings-open-review-action'),
          icon: Icons.rule_folder_outlined,
          title: data.reviewQueue.length == 1
              ? 'Review 1 item'
              : 'Review ${data.reviewQueue.length} items',
          subtitle: 'Confirm, keep separate, or dismiss uncertain items.',
          onTap: () {
            _openReviewDestination();
          },
        ),
      );
    }
    quickActions.add(const _SettingsGroupDivider());
    quickActions.add(
      _SettingsNavRow(
        tileKey: const ValueKey<String>('settings-add-manual-action'),
        icon: Icons.add_circle_outline_rounded,
        title: 'Add manually',
        subtitle:
            'Track one yourself when a scan is limited or something you pay for is missing.',
        onTap: () {
          _showCreateManualSubscriptionForm();
        },
      ),
    );
    final settingsPanels = <Widget>[
      _SettingsGroupPanel(
        key: const ValueKey<String>('settings-quick-actions-panel'),
        title: 'Actions',
        subtitle:
            'Refresh this view, open Review when something needs a decision, or add one yourself.',
        children: quickActions,
      ),
    ];
    if (reminderItems.isNotEmpty) {
      settingsPanels.add(const SizedBox(height: 12));
      settingsPanels.add(
        _SettingsGroupPanel(
          key: const ValueKey<String>('section-renewalReminders'),
          title: 'Renewal reminders',
          subtitle:
              'Stored on this device and shown only when a renewal date is clear enough to trust.',
          children: reminderItems
              .map(
                (item) => _SettingsReminderRow(
                  key: ValueKey<String>(
                    'settings-renewal-reminder-${item.renewal.serviceKey}',
                  ),
                  item: item,
                  isBusy: _localRenewalReminderTargetsInFlight.contains(
                    item.renewal.serviceKey,
                  ),
                  onOpenReminderControls: item.canConfigureReminder
                      ? () => _showRenewalReminderControls(item)
                      : null,
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    if (hasRecovery) {
      settingsPanels.add(const SizedBox(height: 12));
      settingsPanels.add(
        _SettingsGroupPanel(
          key: const ValueKey<String>('section-settings-recovery'),
          title: 'Recent changes (${_countLabel(recoveryCount)})',
          subtitle:
              'Undo recent review and local view changes on this device.',
          children: _buildSettingsRecoveryChildren(data),
        ),
      );
    }
    settingsPanels.add(const SizedBox(height: 12));
    settingsPanels.add(
      _SettingsGroupPanel(
        key: const ValueKey<String>('settings-support-panel'),
        title: 'Help, privacy & about',
        subtitle:
            'Plain-language guidance, on-device privacy details, and app information.',
        children: <Widget>[
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-trust-sheet'),
            icon: Icons.shield_outlined,
            title: 'How SubWatch works',
            subtitle: 'Why SubWatch stays careful',
            onTap: _showTrustHowItWorksSheet,
          ),
          const _SettingsGroupDivider(),
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-help'),
            icon: Icons.menu_book_outlined,
            title: 'Using SubWatch',
            subtitle: 'Scans, review, and saved views',
            onTap: _showHelpSheet,
          ),
          const _SettingsGroupDivider(),
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-privacy'),
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & local data',
            subtitle: 'What stays on this device and when SMS is read',
            onTap: _showPrivacyLocalDataSheet,
          ),
          const _SettingsGroupDivider(),
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-about'),
            icon: Icons.info_outline_rounded,
            title: 'About SubWatch',
            subtitle: 'What it is designed to do',
            onTap: _showAboutSheet,
          ),
          const _SettingsGroupDivider(),
          _SettingsNavRow(
            tileKey: const ValueKey<String>('settings-open-feedback'),
            icon: Icons.bug_report_outlined,
            title: 'Report a problem',
            subtitle: 'What to include if something looks wrong',
            onTap: _showFeedbackSheet,
          ),
        ],
      ),
    );

    return ListView(
      key: const PageStorageKey<String>('destination-settings-surface'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: settingsPanels,
    );
  }

  List<Widget> _buildSettingsRecoveryChildren(RuntimeDashboardSnapshot data) {
    final children = <Widget>[];

    if (data.confirmedReviewItems.isNotEmpty) {
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-confirmedByYou'),
          title: 'Confirmed',
          caption: 'Subscriptions you confirmed yourself.',
          children: _buildConfirmedReviewRows(data.confirmedReviewItems),
        ),
      );
    }

    if (data.dismissedReviewItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-hiddenFromReview'),
          title: 'Not subscriptions',
          caption: 'Items you chose not to keep as subscriptions.',
          children: _buildDismissedReviewRows(data.dismissedReviewItems),
        ),
      );
    }

    if (data.benefitReviewItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-benefitsByYou'),
          title: 'Separate access',
          caption: 'Items you chose to keep separate from paid subscriptions.',
          children: _buildBenefitReviewRows(data.benefitReviewItems),
        ),
      );
    }

    if (data.ignoredLocalItems.isNotEmpty || data.hiddenLocalItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-localControls'),
          title: 'Hidden items',
          caption: 'Only this device view changes.',
          children: <Widget>[
            ..._buildIgnoredLocalRows(data.ignoredLocalItems),
            ..._buildHiddenLocalRows(data.hiddenLocalItems),
          ],
        ),
      );
    }

    return children;
  }

  String _countLabel(int count) {
    if (count == 1) {
      return '1 item';
    }
    return '$count items';
  }

  String _bucketCountLabel(DashboardBucket bucket, int count) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return count == 1 ? '1 subscription' : '$count subscriptions';
      case DashboardBucket.needsReview:
        return _reviewItemCountLabel(count);
      case DashboardBucket.trialsAndBenefits:
        return count == 1 ? '1 trial or benefit' : '$count trials or benefits';
      case DashboardBucket.hidden:
        return count == 1 ? '1 hidden item' : '$count hidden items';
    }
  }

  String _manualEntryCountLabel(int count) {
    return count == 1 ? '1 manual entry' : '$count manual entries';
  }

  String _reviewItemCountLabel(int count) {
    return count == 1 ? '1 review item' : '$count review items';
  }

  String _serviceViewVisibleCountLabel(int count) {
    return count == 1 ? '1 item in this list' : '$count items in this list';
  }

  String _settingsSourceActionTitle(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return 'Scan messages';
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return 'Check messages again';
      case RuntimeLocalMessageSourceTone.caution:
        return 'Turn on SMS access';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'About this view';
    }
  }

  String _settingsSourceActionSubtitle(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return 'Replace the sample view with results from this device.';
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return 'Refresh this view from SMS on this device.';
      case RuntimeLocalMessageSourceTone.caution:
        return 'Grant access when you want a fresh SMS check.';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'This device cannot refresh from SMS. Review what the current state means.';
    }
  }

  IconData _settingsSourceActionIcon(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return Icons.sms_outlined;
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return Icons.sync_rounded;
      case RuntimeLocalMessageSourceTone.caution:
        return Icons.lock_open_rounded;
      case RuntimeLocalMessageSourceTone.unavailable:
        return Icons.info_outline_rounded;
    }
  }

  String _serviceSectionTitle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Subscriptions';
      case DashboardBucket.needsReview:
        return 'Needs review';
      case DashboardBucket.trialsAndBenefits:
        return 'Trials & benefits';
      case DashboardBucket.hidden:
        return 'Hidden items';
    }
  }

  String? _serviceSectionCaption(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Paid subscriptions with strong enough billing proof.';
      case DashboardBucket.needsReview:
        return 'Items that still need your decision before they can move into confirmed subscriptions.';
      case DashboardBucket.trialsAndBenefits:
        return 'Separate access such as trials, bundled benefits, and recharge-linked perks.';
      case DashboardBucket.hidden:
        return null;
    }
  }

  String _serviceSectionEmptyTitle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'No confirmed subscriptions yet';
      case DashboardBucket.needsReview:
        return 'Nothing to review';
      case DashboardBucket.trialsAndBenefits:
        return 'No trials or benefits';
      case DashboardBucket.hidden:
        return 'Nothing hidden';
    }
  }

  String _serviceSectionEmptyMessage(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Confirmed subscriptions appear here when the evidence is strong enough. If something you pay for is missing, you can still add it manually.';
      case DashboardBucket.needsReview:
        return 'Nothing needs review right now.';
      case DashboardBucket.trialsAndBenefits:
        return 'No trials or benefits right now.';
      case DashboardBucket.hidden:
        return 'No hidden items here.';
    }
  }

  List<Widget> _buildSubscriptionSectionChildren(
    List<DashboardCard> cards,
    Map<String, LocalServicePresentationState> localServicePresentationStates,
    DashboardBucket bucket, {
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required List<DashboardRenewalReminderItemPresentation>
        renewalReminderItems,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (cards.isEmpty) {
      return <Widget>[
        _EmptySectionText(
          title: emptyTitle,
          message: emptyMessage,
          icon: _emptyStateIcon(bucket),
        ),
      ];
    }

    final style = _bucketStyle(bucket);
    final renewalByServiceKey =
        <String, DashboardUpcomingRenewalItemPresentation>{
      for (final item in upcomingRenewals.items) item.serviceKey: item,
    };

    final rows = cards.map(
      (card) {
        final explanation =
            ContextualExplanationPresentation.forDashboardCard(card);
        final servicePresentationState =
            localServicePresentationStates[card.serviceKey.value] ??
                LocalServicePresentationState.fromDashboardCard(card);
        final localControlBusy = _localControlTargetsInFlight.contains(
              'card::${bucket.name}::${card.serviceKey.value}',
            ) ||
            _localControlTargetsInFlight.contains(
              'service::${card.serviceKey.value}',
            );
        final localPresentationBusy =
            _localServicePresentationTargetsInFlight.contains(
          card.serviceKey.value,
        );
        return _SubscriptionListRow(
          key: ValueKey<String>('passport-card-${bucket.name}-${card.title}'),
          card: card,
          metadata: _SubscriptionCardMetadata.fromCard(
            card,
            renewal: renewalByServiceKey[card.serviceKey.value],
          ),
          style: style,
          servicePresentationState: servicePresentationState,
          onTap: () => _showSubscriptionDetails(
            card,
            bucket,
            servicePresentationState,
            renewalByServiceKey[card.serviceKey.value],
            renewalReminderItems,
          ),
          trailing: _SubscriptionCardOverflowButton(
            bucket: bucket,
            card: card,
            explanation: explanation,
            servicePresentationState: servicePresentationState,
            localControlBusy: localControlBusy,
            localPresentationBusy: localPresentationBusy,
            onExplain: () => _showContextualExplanation(explanation),
            onOpenLocalServiceControls: () => _showLocalServiceControls(
              card,
              servicePresentationState,
            ),
            onHide: () => _handleHideCard(card),
            onIgnore: () => _handleIgnoreCard(card),
          ),
        );
      },
    ).toList(growable: false);

    return <Widget>[
      _InsetListGroup(children: rows),
    ];
  }

  List<Widget> _buildManualSubscriptionRows(
    List<ManualSubscriptionEntry> entries,
    DashboardUpcomingRenewalsPresentation upcomingRenewals,
    List<DashboardRenewalReminderItemPresentation> reminderItems,
  ) {
    if (entries.isEmpty) {
      return const <Widget>[
        _EmptySectionText(
          title: 'No manual subscriptions yet',
          message:
              'Add one you already know so it stays visible without changing the current scan result.',
          icon: Icons.edit_note_rounded,
        ),
      ];
    }

    final rows = entries
        .map(
          (entry) => _ManualSubscriptionRow(
            key: ValueKey<String>('manual-subscription-${entry.id}'),
            entry: entry,
            isBusy: _manualSubscriptionTargetsInFlight.contains(entry.id),
            onTap: () => _showManualSubscriptionDetails(entry, reminderItems),
            onEdit: () => _showEditManualSubscriptionForm(entry),
            onDelete: () => _confirmDeleteManualSubscription(entry),
            onOpenReminderControls: (reminderItems
                        .any((item) => item.renewal.serviceKey == entry.id)) ==
                    false
                ? null
                : () => _showRenewalReminderControls(
                      reminderItems.firstWhere(
                        (item) => item.renewal.serviceKey == entry.id,
                      ),
                    ),
          ),
        )
        .toList(growable: false);
    return <Widget>[
      _InsetListGroup(children: rows),
    ];
  }

  Future<void> _showCreateManualSubscriptionForm({
    String? initialServiceName,
    String? initialPlanLabel,
    int? initialAmountInMinorUnits,
    ManualSubscriptionBillingCycle? initialBillingCycle,
  }) async {
    if (initialServiceName != null) {
      await _showDashboardBottomSheet<void>(
        builder: (sheetContext) => _ManualSubscriptionEditorSheet(
          initialServiceName: initialServiceName,
          initialPlanLabel: initialPlanLabel,
          initialAmountInMinorUnits: initialAmountInMinorUnits,
          initialBillingCycle: initialBillingCycle,
          onSubmit: _handleCreateManualSubscription,
        ),
      );
      return;
    }

    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualAddFlowSheet(
        onSubmit: _handleCreateManualSubscription,
      ),
    );
  }

  Future<void> _showEditManualSubscriptionForm(
    ManualSubscriptionEntry entry,
  ) async {
    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualSubscriptionEditorSheet(
        existingEntry: entry,
        onSubmit: (value) => _handleUpdateManualSubscription(entry.id, value),
        onDelete: () => _confirmDeleteManualSubscription(entry),
      ),
    );
  }

  Future<void> _showManualSubscriptionDetails(
    ManualSubscriptionEntry entry,
    List<DashboardRenewalReminderItemPresentation> reminderItems,
  ) async {
    final reminderItem =
        reminderItems.any((item) => item.renewal.serviceKey == entry.id)
            ? reminderItems
                .firstWhere((item) => item.renewal.serviceKey == entry.id)
            : null;

    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualSubscriptionDetailsSheet(
        entry: entry,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          _showEditManualSubscriptionForm(entry);
        },
        onDelete: () async {
          final deleted = await _confirmDeleteManualSubscription(entry);
          if (deleted && mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
        onOpenReminderControls: reminderItem == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _showRenewalReminderControls(reminderItem);
              },
      ),
    );
  }

  Future<bool> _confirmDeleteManualSubscription(
    ManualSubscriptionEntry entry,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove manual subscription?'),
            content: Text(
              'Remove ${entry.serviceName} from your manual subscriptions on this device?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final deleted = await _handleDeleteManualSubscription(entry);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(deleted);
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<Widget> _buildConfirmedReviewRows(
    List<UserConfirmedReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-confirmedByYou-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Confirmed by your review',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildDismissedReviewRows(
    List<UserDismissedReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-hiddenFromReview-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Marked as not a subscription',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildBenefitReviewRows(
    List<UserBenefitReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-benefitsByYou-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Kept separate as a benefit',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildIgnoredLocalRows(
    List<UserIgnoredLocalItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-ignoredLocal-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Hidden on this device',
            isBusy: _localControlTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoLocalControlOverlay(
              targetKey: item.targetKey,
              title: item.title,
              restoredLabel: 'returned to this device view',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildHiddenLocalRows(
    List<UserHiddenLocalItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key:
                ValueKey<String>('passport-card-hiddenLocal-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Hidden on this device',
            isBusy: _localControlTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoLocalControlOverlay(
              targetKey: item.targetKey,
              title: item.title,
              restoredLabel: 'returned to this device view',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildReviewRows(
    List<ReviewItem> reviewQueue, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (reviewQueue.isEmpty) {
      return <Widget>[
        _EmptySectionText(
          title: emptyTitle,
          message: emptyMessage,
          icon: Icons.shield_moon_outlined,
        ),
      ];
    }

    return reviewQueue.map(
      (item) {
        final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
        final presentation = ReviewQueueItemPresentation.fromReviewItem(item);
        final explanation = ContextualExplanationPresentation.forReviewItem(
          item,
        );
        final isBusy = _reviewActionTargetsInFlight.contains(
          descriptor.targetKey,
        );

        return Padding(
          key: ValueKey<String>('review-item-${descriptor.targetKey}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ReviewDecisionPassportCard(
            item: item,
            descriptor: descriptor,
            presentation: presentation,
            explanation: explanation,
            isBusy: isBusy,
            onOpenDetails: () => _showReviewItemDetails(
              item,
              descriptor,
              presentation,
              explanation,
            ),
            onExplain: () => _showContextualExplanation(explanation),
            onIgnore: () => _handleIgnoreReviewItem(item),
            onConfirm: descriptor.canConfirm
                ? () => _handleReviewItemAction(
                      item,
                      ReviewItemAction.confirmSubscription,
                    )
                : null,
            onDismiss: () => _handleReviewItemAction(
              item,
              ReviewItemAction.dismissNotSubscription,
            ),
          ),
        );
      },
    ).toList(growable: false);
  }

  IconData _emptyStateIcon(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return Icons.verified_outlined;
      case DashboardBucket.needsReview:
        return Icons.shield_moon_outlined;
      case DashboardBucket.trialsAndBenefits:
        return Icons.card_giftcard_outlined;
      case DashboardBucket.hidden:
        return Icons.visibility_off_outlined;
    }
  }

  _BucketStyle _bucketStyle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return const _BucketStyle(
          badgeLabel: 'Confirmed',
          background: DashboardShellPalette.successSoft,
          border: Color(0xFF355344),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.success,
        );
      case DashboardBucket.needsReview:
        return const _BucketStyle(
          badgeLabel: 'Needs review',
          background: DashboardShellPalette.elevatedPaper,
          border: DashboardShellPalette.outlineStrong,
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.mutedInk,
        );
      case DashboardBucket.trialsAndBenefits:
        return const _BucketStyle(
          badgeLabel: 'Separate access',
          background: Color(0xFF18211C),
          border: Color(0xFF314339),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.accent,
        );
      case DashboardBucket.hidden:
        return const _BucketStyle(
          badgeLabel: 'Hidden',
          background: DashboardShellPalette.recoverySoft,
          border: Color(0xFF394556),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.recovery,
        );
    }
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _shouldReduceMotion(context);
    return Center(
      child: DashboardPanel(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0, 1),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SubWatchBrandMark(size: 84),
              const SizedBox(height: 16),
              Text(
                'SubWatch',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preparing your local view...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Subscriptions, review items, and recent checks are being prepared from local data on this device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DashboardPanel(
          backgroundColor: DashboardShellPalette.recoverySoft,
          borderColor: const Color(0xFF435062),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.refresh_rounded,
                color: DashboardShellPalette.recovery,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                'This local view is not ready yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'SubWatch could not open the current local view just yet. No fresh scan is being claimed. Try again to reload what is already on this device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              const SizedBox(height: 14),
              _ContextualActionSemantics(
                label: 'Try again to open the current local view',
                child: FilledButton.icon(
                  key: const ValueKey<String>('retry-load-dashboard'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadRecoveryNotice extends StatelessWidget {
  const _DashboardLoadRecoveryNotice({
    required this.state,
    required this.onRetry,
  });

  final _LoadRecoveryState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DashboardPanel(
        key: const ValueKey<String>('dashboard-load-recovery-notice'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        backgroundColor: DashboardShellPalette.recoverySoft,
        borderColor: const Color(0xFF435062),
        radius: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              state.icon,
              color: DashboardShellPalette.recovery,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.28,
                        ),
                  ),
                ],
              ),
            ),
            if (state.showRetryAction && onRetry != null) ...<Widget>[
              const SizedBox(width: 12),
              _ContextualActionSemantics(
                label: 'Try again to reload the current local view',
                child: TextButton(
                  key: const ValueKey<String>('retry-load-dashboard'),
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadRecoveryState {
  const _LoadRecoveryState({
    required this.title,
    required this.description,
    required this.icon,
    required this.showRetryAction,
  });

  const _LoadRecoveryState.reloading()
      : title = 'Trying again...',
        description =
            'SubWatch is reloading this local view. The last trusted view on this device stays visible in the meantime.',
        icon = Icons.hourglass_top_rounded,
        showRetryAction = false;

  const _LoadRecoveryState.failed()
      : title = 'Current view stayed in place.',
        description =
            'SubWatch could not reload this local view just yet, so the last trusted view on this device is still showing. No fresh scan is being claimed.',
        icon = Icons.history_toggle_off_rounded,
        showRetryAction = true;

  final String title;
  final String description;
  final IconData icon;
  final bool showRetryAction;
}

class _TotalsSummaryCard extends StatelessWidget {
  const _TotalsSummaryCard({
    required this.presentation,
    required this.sourceStatus,
    required this.onExplain,
  });

  final DashboardTotalsSummaryPresentation presentation;
  final RuntimeLocalMessageSourceStatus sourceStatus;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    final stackedMetrics =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.18;
    return DashboardPanel(
      key: const ValueKey<String>('totals-summary-card'),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFF8F1E6),
          DashboardShellPalette.paper,
        ],
      ),
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'What SubWatch found',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (stackedHeader)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Monthly spend estimate',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  presentation.monthlyTotalValueLabel,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  presentation.monthlyTotalCaption,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Open spend estimate explanation',
                  container: true,
                  button: true,
                  child: TextButton(
                    key: const ValueKey<String>('open-totals-explanation-button'),
                    onPressed: onExplain,
                    child: const Text('How totals work'),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          'Monthly spend estimate',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: DashboardShellPalette.mutedInk,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.monthlyTotalValueLabel,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.monthlyTotalCaption,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Open spend estimate explanation',
                  container: true,
                  button: true,
                  child: TextButton(
                    key: const ValueKey<String>('open-totals-explanation-button'),
                    onPressed: onExplain,
                    child: const Text('How totals work'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          if (stackedMetrics)
            Column(
              children: <Widget>[
                _CompactMetricTile(
                  key: const ValueKey<String>('totals-summary-confirmed-metric'),
                  label: 'Confirmed',
                  value: presentation.activePaidValueLabel,
                  valueKey: const ValueKey<String>(
                    'totals-summary-confirmed-value',
                  ),
                  caption: presentation.activePaidCaption,
                  accent: DashboardShellPalette.success,
                ),
                const SizedBox(height: 8),
                _CompactMetricTile(
                  key: const ValueKey<String>('totals-summary-review-metric'),
                  label: 'Needs review',
                  value: presentation.reviewValueLabel,
                  valueKey:
                      const ValueKey<String>('totals-summary-review-value'),
                  caption: presentation.reviewCaption,
                  accent: DashboardShellPalette.caution,
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: _CompactMetricTile(
                    key:
                        const ValueKey<String>('totals-summary-confirmed-metric'),
                    label: 'Confirmed',
                    value: presentation.activePaidValueLabel,
                    valueKey: const ValueKey<String>(
                      'totals-summary-confirmed-value',
                    ),
                    caption: presentation.activePaidCaption,
                    accent: DashboardShellPalette.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactMetricTile(
                    key: const ValueKey<String>('totals-summary-review-metric'),
                    label: 'Needs review',
                    value: presentation.reviewValueLabel,
                    valueKey:
                        const ValueKey<String>('totals-summary-review-value'),
                    caption: presentation.reviewCaption,
                    accent: DashboardShellPalette.caution,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          DashboardPanel(
            backgroundColor: DashboardShellPalette.elevatedPaper,
            borderColor: DashboardShellPalette.outline,
            radius: 18,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Current view',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  sourceStatus.provenanceDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.ink,
                        height: 1.28,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            presentation.summaryCopy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.28,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.accent,
    this.valueKey,
  });

  final String label;
  final String value;
  final String caption;
  final Color accent;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label. $value. $caption.',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                key: valueKey,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.24,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsetListGroup extends StatelessWidget {
  const _InsetListGroup({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardShellPalette.elevatedPaper.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DashboardShellPalette.outline.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        children: children
            .expand(
              (child) => <Widget>[
                child,
                if (child != children.last)
                  const Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: DashboardShellPalette.outline,
                  ),
              ],
            )
            .toList(growable: false),
      ),
    );
  }
}

class _HomeFocusCard extends StatelessWidget {
  const _HomeFocusCard({
    required this.sourceStatus,
    required this.reviewCount,
    required this.dueSoon,
    required this.upcomingRenewals,
    required this.onReview,
    required this.onSync,
  });

  final RuntimeLocalMessageSourceStatus sourceStatus;
  final int reviewCount;
  final DashboardDueSoonPresentation dueSoon;
  final DashboardUpcomingRenewalsPresentation upcomingRenewals;
  final Future<void> Function() onReview;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final nextRenewal =
        upcomingRenewals.hasItems ? upcomingRenewals.items.first : null;
    final copy = _HomeFocusCopy.fromState(
      sourceStatus: sourceStatus,
      reviewCount: reviewCount,
      dueSoon: dueSoon,
      nextRenewal: nextRenewal,
    );
    final primaryActionLabel = switch (copy.primaryActionKind) {
      _HomeFocusPrimaryActionKind.sync => sourceStatus.actionLabel,
      _HomeFocusPrimaryActionKind.review => _reviewActionLabel(reviewCount),
      _HomeFocusPrimaryActionKind.none => null,
    };
    final showSecondaryReviewAction = reviewCount > 0 &&
        copy.primaryActionKind != _HomeFocusPrimaryActionKind.review;

    return DashboardPanel(
      key: const ValueKey<String>('home-focus-card'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: copy.eyebrowLabel,
                icon: copy.eyebrowIcon,
                backgroundColor: copy.eyebrowBackgroundColor,
                foregroundColor: copy.eyebrowForegroundColor,
              ),
              if (dueSoon.hasItems)
                DashboardBadge(
                  label: _dueSoonBadgeLabel(dueSoon.items.length),
                  icon: Icons.schedule_outlined,
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  foregroundColor: DashboardShellPalette.caution,
                )
              else if (nextRenewal != null)
                DashboardBadge(
                  label: 'Next: ${nextRenewal.serviceTitle}',
                  icon: Icons.event_repeat_outlined,
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  foregroundColor: DashboardShellPalette.accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'What to do next',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            copy.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.ink,
                  height: 1.28,
                ),
          ),
          if (copy.supportingCopy != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              copy.supportingCopy!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
          ],
          if (primaryActionLabel != null ||
              showSecondaryReviewAction) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if (primaryActionLabel != null)
                  FilledButton.icon(
                    key: const ValueKey<String>('home-focus-primary-action'),
                    onPressed: switch (copy.primaryActionKind) {
                      _HomeFocusPrimaryActionKind.sync =>
                        sourceStatus.isActionEnabled ? onSync : null,
                      _HomeFocusPrimaryActionKind.review => onReview,
                      _HomeFocusPrimaryActionKind.none => null,
                    },
                    icon: Icon(
                      switch (copy.primaryActionKind) {
                        _HomeFocusPrimaryActionKind.sync => Icons.sync_rounded,
                        _HomeFocusPrimaryActionKind.review =>
                          Icons.rule_folder_outlined,
                        _HomeFocusPrimaryActionKind.none =>
                          Icons.arrow_forward_rounded,
                      },
                    ),
                    label: Text(primaryActionLabel),
                  ),
                if (showSecondaryReviewAction)
                  TextButton.icon(
                    key: const ValueKey<String>('home-focus-review-action'),
                    onPressed: onReview,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_reviewActionLabel(reviewCount)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _dueSoonBadgeLabel(int count) {
    final renewalLabel = count == 1 ? 'due soon' : 'due soon';
    return '$count $renewalLabel';
  }

  String _reviewActionLabel(int count) {
    final itemLabel = count == 1 ? 'item' : 'items';
    return 'Review $count $itemLabel';
  }
}

enum _HomeFocusPrimaryActionKind {
  none,
  review,
  sync,
}

class _HomeFocusCopy {
  const _HomeFocusCopy({
    required this.eyebrowLabel,
    required this.eyebrowIcon,
    required this.eyebrowBackgroundColor,
    required this.eyebrowForegroundColor,
    required this.summary,
    required this.supportingCopy,
    required this.primaryActionKind,
  });

  factory _HomeFocusCopy.fromState({
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required int reviewCount,
    required DashboardDueSoonPresentation dueSoon,
    required DashboardUpcomingRenewalItemPresentation? nextRenewal,
  }) {
    final followUp = _followUpCopy(
      reviewCount: reviewCount,
      dueSoon: dueSoon,
      nextRenewal: nextRenewal,
    );

    switch (sourceStatus.tone) {
      case RuntimeLocalMessageSourceTone.caution:
        return _HomeFocusCopy(
          eyebrowLabel: 'Needs refresh',
          eyebrowIcon: Icons.sms_failed_outlined,
          eyebrowBackgroundColor: DashboardShellPalette.cautionSoft,
          eyebrowForegroundColor: DashboardShellPalette.caution,
          summary:
              'SMS access is off, so SubWatch cannot run a fresh check until you turn it back on.',
          supportingCopy: followUp ??
              'Saved local results stay visible until you are ready to check again.',
          primaryActionKind: sourceStatus.isActionEnabled
              ? _HomeFocusPrimaryActionKind.sync
              : _HomeFocusPrimaryActionKind.none,
        );
      case RuntimeLocalMessageSourceTone.unavailable:
        return _HomeFocusCopy(
          eyebrowLabel: 'Saved view',
          eyebrowIcon: Icons.inventory_2_outlined,
          eyebrowBackgroundColor: DashboardShellPalette.recoverySoft,
          eyebrowForegroundColor: DashboardShellPalette.recovery,
          summary:
              'This device cannot provide a fresh SMS check, so SubWatch is holding on to the safest local view available.',
          supportingCopy: followUp ??
              'Confirmed subscriptions and manual entries stay visible, but new detections require a device that can read SMS locally.',
          primaryActionKind: _HomeFocusPrimaryActionKind.none,
        );
      case RuntimeLocalMessageSourceTone.restored:
        return _HomeFocusCopy(
          eyebrowLabel: 'Saved view',
          eyebrowIcon: Icons.history_toggle_off_rounded,
          eyebrowBackgroundColor: DashboardShellPalette.recoverySoft,
          eyebrowForegroundColor: DashboardShellPalette.recovery,
          summary:
              'SubWatch is showing the last saved view on this device. A fresh check is the fastest way to surface new subscriptions or updated review items.',
          supportingCopy: followUp ??
              'Until then, this dashboard stays anchored to the last saved local result.',
          primaryActionKind: sourceStatus.isActionEnabled
              ? _HomeFocusPrimaryActionKind.sync
              : _HomeFocusPrimaryActionKind.none,
        );
      case RuntimeLocalMessageSourceTone.demo:
        return const _HomeFocusCopy(
          eyebrowLabel: 'Sample',
          eyebrowIcon: Icons.auto_awesome_outlined,
          eyebrowBackgroundColor: DashboardShellPalette.accentSoft,
          eyebrowForegroundColor: DashboardShellPalette.accent,
          summary: 'Sample view',
          supportingCopy: null,
          primaryActionKind: _HomeFocusPrimaryActionKind.none,
        );
      case RuntimeLocalMessageSourceTone.fresh:
        if (dueSoon.hasItems && reviewCount > 0) {
          final countLabel = reviewCount == 1
              ? '1 item still needs'
              : '$reviewCount items still need';
          return _HomeFocusCopy(
            eyebrowLabel: 'Needs attention',
            eyebrowIcon: Icons.notifications_active_outlined,
            eyebrowBackgroundColor: DashboardShellPalette.cautionSoft,
            eyebrowForegroundColor: DashboardShellPalette.caution,
            summary: dueSoon.summaryCopy,
            supportingCopy:
                '$countLabel your decision before it can move into confirmed subscriptions.',
            primaryActionKind: _HomeFocusPrimaryActionKind.none,
          );
        }
        if (dueSoon.hasItems) {
          return _HomeFocusCopy(
            eyebrowLabel: 'Due soon',
            eyebrowIcon: Icons.schedule_outlined,
            eyebrowBackgroundColor: DashboardShellPalette.cautionSoft,
            eyebrowForegroundColor: DashboardShellPalette.caution,
            summary: dueSoon.summaryCopy,
            supportingCopy: nextRenewal == null
                ? null
                : 'Next renewal: ${nextRenewal.serviceTitle} on ${nextRenewal.renewalDateLabel}.',
            primaryActionKind: _HomeFocusPrimaryActionKind.none,
          );
        }
        if (reviewCount > 0) {
          final itemLabel =
              reviewCount == 1 ? 'item still needs' : 'items still need';
          return _HomeFocusCopy(
            eyebrowLabel: 'Needs review',
            eyebrowIcon: Icons.rule_folder_outlined,
            eyebrowBackgroundColor: DashboardShellPalette.cautionSoft,
            eyebrowForegroundColor: DashboardShellPalette.caution,
            summary:
                '$reviewCount $itemLabel your decision before it can move into confirmed subscriptions.',
            supportingCopy:
                'SubWatch keeps weak or unclear evidence out of confirmed subscriptions on purpose.',
            primaryActionKind: _HomeFocusPrimaryActionKind.review,
          );
        }
        if (nextRenewal != null) {
          return _HomeFocusCopy(
            eyebrowLabel: 'Next renewal',
            eyebrowIcon: Icons.event_repeat_outlined,
            eyebrowBackgroundColor: DashboardShellPalette.accentSoft,
            eyebrowForegroundColor: DashboardShellPalette.accent,
            summary:
                'Next renewal: ${nextRenewal.serviceTitle} on ${nextRenewal.renewalDateLabel}.',
            supportingCopy:
                'Renewal dates stay visible here so the dashboard remains useful between scans.',
            primaryActionKind: _HomeFocusPrimaryActionKind.none,
          );
        }
        return const _HomeFocusCopy(
          eyebrowLabel: 'Quiet for now',
          eyebrowIcon: Icons.verified_outlined,
          eyebrowBackgroundColor: DashboardShellPalette.successSoft,
          eyebrowForegroundColor: DashboardShellPalette.success,
          summary:
              'Nothing urgent stands out today. New review items, confirmed subscriptions, and renewal dates will show up here after a fresh check.',
          supportingCopy:
              'SubWatch stays useful by keeping the next decision or renewal visible without turning into a finance dashboard.',
          primaryActionKind: _HomeFocusPrimaryActionKind.none,
        );
    }
  }

  final String eyebrowLabel;
  final IconData eyebrowIcon;
  final Color eyebrowBackgroundColor;
  final Color eyebrowForegroundColor;
  final String summary;
  final String? supportingCopy;
  final _HomeFocusPrimaryActionKind primaryActionKind;

  static String? _followUpCopy({
    required int reviewCount,
    required DashboardDueSoonPresentation dueSoon,
    required DashboardUpcomingRenewalItemPresentation? nextRenewal,
  }) {
    if (reviewCount > 0) {
      final itemLabel =
          reviewCount == 1 ? 'item still needs' : 'items still need';
      return '$reviewCount $itemLabel your decision before it can move into confirmed subscriptions.';
    }
    if (dueSoon.hasItems) {
      return dueSoon.summaryCopy;
    }
    if (nextRenewal != null) {
      return 'Next renewal: ${nextRenewal.serviceTitle} on ${nextRenewal.renewalDateLabel}.';
    }
    return null;
  }
}

class _UpcomingRenewalsCard extends StatelessWidget {
  const _UpcomingRenewalsCard({
    required this.presentation,
    required this.reminderItems,
    required this.showReminderControls,
    required this.onOpenReminderControls,
    required this.reminderTargetsInFlight,
  });

  final DashboardUpcomingRenewalsPresentation presentation;
  final List<DashboardRenewalReminderItemPresentation> reminderItems;
  final bool showReminderControls;
  final ValueChanged<DashboardRenewalReminderItemPresentation>
      onOpenReminderControls;
  final Set<String> reminderTargetsInFlight;

  @override
  Widget build(BuildContext context) {
    final countLabel = presentation.hasItems
        ? presentation.items.length == 1
            ? '1 date'
            : '${presentation.items.length} dates'
        : null;

    return Column(
      key: const ValueKey<String>('upcoming-renewals-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardSectionFrame(
          title: 'Upcoming renewals',
          caption: presentation.summaryCopy,
          countLabel: countLabel,
          children: <Widget>[
            if (!presentation.hasItems)
              _EmptySectionText(
                title: presentation.emptyTitle,
                message: presentation.emptyMessage,
                icon: Icons.event_repeat_outlined,
              )
            else
              _InsetListGroup(
                children: reminderItems
                    .map(
                      (item) => _ReminderRenewalItemTile(
                        key: ValueKey<String>(
                          'upcoming-renewal-item-${item.renewal.serviceTitle}',
                        ),
                        item: item,
                        isBusy: reminderTargetsInFlight.contains(
                          item.renewal.serviceKey,
                        ),
                        showReminderControls: showReminderControls,
                        onOpenReminderControls:
                            showReminderControls && item.canConfigureReminder
                                ? () => onOpenReminderControls(item)
                                : null,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _DueSoonCard extends StatelessWidget {
  const _DueSoonCard({
    required this.presentation,
  });

  final DashboardDueSoonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final countLabel = presentation.hasItems
        ? presentation.items.length == 1
            ? '1 renewal'
            : '${presentation.items.length} renewals'
        : null;

    return Column(
      key: const ValueKey<String>('due-soon-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardSectionFrame(
          title: 'Due soon',
          caption: presentation.summaryCopy,
          countLabel: countLabel,
          children: <Widget>[
            if (!presentation.hasItems)
              _EmptySectionText(
                title: presentation.emptyTitle,
                message: presentation.emptyMessage,
                icon: Icons.schedule_outlined,
              )
            else
              _InsetListGroup(
                children: presentation.items
                    .map(
                      (item) => _RenewalItemTile(
                        key: ValueKey<String>(
                          'due-soon-item-${item.serviceTitle}',
                        ),
                        item: item,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _RenewalItemTile extends StatelessWidget {
  const _RenewalItemTile({
    super.key,
    required this.item,
  });

  final DashboardUpcomingRenewalItemPresentation item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.serviceTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.renewalDateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
              ],
            ),
          ),
          if (item.amountLabel != null)
            DashboardBadge(
              label: item.amountLabel!,
              backgroundColor: DashboardShellPalette.paper,
              foregroundColor: DashboardShellPalette.accent,
            ),
        ],
      ),
    );
  }
}

class _ReminderRenewalItemTile extends StatelessWidget {
  const _ReminderRenewalItemTile({
    super.key,
    required this.item,
    required this.isBusy,
    this.showReminderControls = true,
    required this.onOpenReminderControls,
  });

  final DashboardRenewalReminderItemPresentation item;
  final bool isBusy;
  final bool showReminderControls;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.renewal.serviceTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.renewal.renewalDateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                  ],
                ),
              ),
              if (item.renewal.amountLabel != null)
                DashboardBadge(
                  label: item.renewal.amountLabel!,
                  backgroundColor: DashboardShellPalette.paper,
                  foregroundColor: DashboardShellPalette.accent,
                ),
            ],
          ),
          if (showReminderControls) ...<Widget>[
            const SizedBox(height: 6),
            TextButton.icon(
              key: ValueKey<String>(
                'open-renewal-reminder-controls-${item.renewal.serviceKey}',
              ),
              onPressed: isBusy ? null : onOpenReminderControls,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Reminder'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionCardMetadata {
  const _SubscriptionCardMetadata({
    required this.amountLabel,
    required this.renewalLabel,
    required this.frequencyLabel,
  });

  factory _SubscriptionCardMetadata.fromCard(
    DashboardCard card, {
    DashboardUpcomingRenewalItemPresentation? renewal,
  }) {
    return _SubscriptionCardMetadata(
      amountLabel: card.amountLabel ?? _fallbackAmountLabel(card.bucket),
      renewalLabel:
          renewal?.renewalDateLabel ?? _fallbackRenewalLabel(card.bucket),
      frequencyLabel:
          card.frequencyLabel ?? _fallbackFrequencyLabel(card.bucket),
    );
  }

  final String amountLabel;
  final String renewalLabel;
  final String frequencyLabel;
}

class _SubscriptionInfoChip extends StatelessWidget {
  const _SubscriptionInfoChip({
    required this.valueKey,
    required this.title,
    required this.value,
    required this.width,
  });

  final Key valueKey;
  final String title;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DashboardShellPalette.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.18,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  key: valueKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionMetaPanel extends StatelessWidget {
  const _SubscriptionMetaPanel({
    required this.amountValueKey,
    required this.amountLabel,
    required this.renewalValueKey,
    required this.renewalLabel,
    required this.frequencyValueKey,
    required this.frequencyLabel,
  });

  final Key amountValueKey;
  final String amountLabel;
  final Key renewalValueKey;
  final String renewalLabel;
  final Key frequencyValueKey;
  final String frequencyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardShellPalette.outline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 240;
          final amountBlock = _SubscriptionMetaBlock(
            label: 'Amount',
            value: amountLabel,
            valueKey: amountValueKey,
            emphasize: true,
          );
          final renewalBlock = _SubscriptionMetaBlock(
            label: 'Next renewal',
            value: renewalLabel,
            valueKey: renewalValueKey,
          );
          final frequencyBlock = _SubscriptionMetaBlock(
            label: 'Frequency',
            value: frequencyLabel,
            valueKey: frequencyValueKey,
          );

          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                amountBlock,
                const SizedBox(height: 10),
                renewalBlock,
                const SizedBox(height: 10),
                frequencyBlock,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: amountBlock),
                  const SizedBox(width: 12),
                  Expanded(child: renewalBlock),
                ],
              ),
              const SizedBox(height: 10),
              frequencyBlock,
            ],
          );
        },
      ),
    );
  }
}

class _SubscriptionMetaBlock extends StatelessWidget {
  const _SubscriptionMetaBlock({
    required this.label,
    required this.value,
    required this.valueKey,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.18,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              key: valueKey,
              maxLines: emphasize ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: (emphasize
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.bodySmall)
                  ?.copyWith(
                    color: DashboardShellPalette.ink,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineCardStatus extends StatelessWidget {
  const _InlineCardStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SubscriptionListRow extends StatelessWidget {
  const _SubscriptionListRow({
    super.key,
    required this.card,
    required this.metadata,
    required this.style,
    required this.servicePresentationState,
    required this.onTap,
    required this.trailing,
  });

  final DashboardCard card;
  final _SubscriptionCardMetadata metadata;
  final _BucketStyle style;
  final LocalServicePresentationState servicePresentationState;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final displayTitle = servicePresentationState.displayTitle;
    final identity = _identityStyle(
      displayTitle,
      accentColor: style.badgeForeground,
    );
    final summary = _subscriptionRowSemantics(
      card,
      metadata: metadata,
      style: style,
      servicePresentationState: servicePresentationState,
    );

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Semantics(
              key: ValueKey<String>(
                'subscription-row-semantics-${card.serviceKey.value}',
              ),
              button: true,
              label: summary,
              hint: 'Opens service details',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  splashColor: style.badgeForeground.withValues(alpha: 0.08),
                  highlightColor: style.badgeForeground.withValues(alpha: 0.04),
                  hoverColor: style.badgeForeground.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 0, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          key:
                              ValueKey<String>('passport-avatar-${card.title}'),
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          serviceKey: card.serviceKey.value,
                          sealColor: style.badgeForeground,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                             children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      displayTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DashboardBadge(
                                    label: style.badgeLabel,
                                    backgroundColor: style.badgeBackground,
                                    foregroundColor: style.badgeForeground,
                                  ),
                                ],
                              ),
                              if (servicePresentationState.hasLocalLabel) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  servicePresentationState.originalTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                card.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (servicePresentationState.isPinned ||
                                  servicePresentationState.hasLocalLabel) ...<Widget>[
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    if (servicePresentationState.isPinned)
                                      const _InlineCardStatus(
                                        icon: Icons.push_pin_rounded,
                                        label: 'Pinned on this device',
                                        color: DashboardShellPalette.accent,
                                      ),
                                    if (servicePresentationState.hasLocalLabel)
                                      const _InlineCardStatus(
                                        icon: Icons.edit_note_rounded,
                                        label: 'Custom label',
                                        color: DashboardShellPalette.mutedInk,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              _SubscriptionMetaPanel(
                                amountValueKey: ValueKey<String>(
                                  'subscription-meta-amount-${card.serviceKey.value}',
                                ),
                                amountLabel: metadata.amountLabel,
                                renewalValueKey: ValueKey<String>(
                                  'subscription-meta-renewal-${card.serviceKey.value}',
                                ),
                                renewalLabel: metadata.renewalLabel,
                                frequencyValueKey: ValueKey<String>(
                                  'subscription-meta-frequency-${card.serviceKey.value}',
                                ),
                                frequencyLabel: metadata.frequencyLabel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 11, 8, 11),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionDetailsSheet extends StatelessWidget {
  const _SubscriptionDetailsSheet({
    required this.card,
    required this.bucket,
    required this.servicePresentationState,
    required this.metadata,
    this.renewal,
    required this.onExplain,
    required this.onOpenLocalServiceControls,
    required this.onOpenRenewalReminderControls,
  });

  final DashboardCard card;
  final DashboardBucket bucket;
  final LocalServicePresentationState servicePresentationState;
  final _SubscriptionCardMetadata metadata;
  final DashboardUpcomingRenewalItemPresentation? renewal;
  final VoidCallback onExplain;
  final VoidCallback onOpenLocalServiceControls;
  final VoidCallback? onOpenRenewalReminderControls;

  @override
  Widget build(BuildContext context) {
    final style = switch (bucket) {
      DashboardBucket.confirmedSubscriptions => const _BucketStyle(
          badgeLabel: 'Confirmed',
          background: DashboardShellPalette.successSoft,
          border: Color(0xFF355344),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.success,
        ),
      DashboardBucket.needsReview => const _BucketStyle(
          badgeLabel: 'Needs review',
          background: DashboardShellPalette.elevatedPaper,
          border: DashboardShellPalette.outlineStrong,
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.mutedInk,
        ),
      DashboardBucket.trialsAndBenefits => const _BucketStyle(
          badgeLabel: 'Separate access',
          background: Color(0xFF18211C),
          border: Color(0xFF314339),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.accent,
        ),
      DashboardBucket.hidden => const _BucketStyle(
          badgeLabel: 'Hidden',
          background: DashboardShellPalette.recoverySoft,
          border: Color(0xFF394556),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.recovery,
        ),
    };
    final identity =
        _identityStyle(card.title, accentColor: style.badgeForeground);
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
              'subscription-details-sheet-${card.serviceKey.value}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 10),
              if (stackedHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          serviceKey: card.serviceKey.value,
                          sealColor: style.badgeForeground,
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                card.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DashboardServiceAvatar(
                      monogram: identity.monogram,
                      foregroundColor: identity.foreground,
                      backgroundColor: identity.background,
                      borderColor: identity.border,
                      serviceKey: card.serviceKey.value,
                      sealColor: style.badgeForeground,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            card.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  DashboardBadge(
                    label: style.badgeLabel,
                    backgroundColor: style.badgeBackground,
                    foregroundColor: style.badgeForeground,
                  ),
                  if (servicePresentationState.isPinned)
                    const DashboardBadge(
                      label: 'Pinned',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.accent,
                    ),
                  if (servicePresentationState.hasLocalLabel)
                    const DashboardBadge(
                      label: 'Custom label',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.ink,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-amount-${card.serviceKey.value}',
                    ),
                    title: 'Amount',
                    value: metadata.amountLabel,
                    width: 148,
                  ),
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-renewal-${card.serviceKey.value}',
                    ),
                    title: 'Next renewal',
                    value: metadata.renewalLabel,
                    width: 148,
                  ),
                  _SubscriptionInfoChip(
                    valueKey: ValueKey<String>(
                      'subscription-details-meta-frequency-${card.serviceKey.value}',
                    ),
                    title: 'Frequency',
                    value: metadata.frequencyLabel,
                    width: 148,
                  ),
                ],
              ),
              if (servicePresentationState.hasLocalLabel ||
                  servicePresentationState.originalTitle !=
                      card.title) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Original name',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  servicePresentationState.originalTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExplain,
                      child: const Text('Why this'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpenLocalServiceControls,
                      child: const Text('Manage device'),
                    ),
                  ),
                ],
              ),
              if (onOpenRenewalReminderControls != null) ...<Widget>[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey<String>(
                      'details-open-renewal-reminder-controls-${card.serviceKey.value}',
                    ),
                    onPressed: onOpenRenewalReminderControls,
                    icon: const Icon(Icons.alarm_rounded),
                    label: const Text('Set local reminder'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncProgressPresentation {
  const _SyncProgressPresentation({
    required this.title,
    required this.description,
  });

  factory _SyncProgressPresentation.fromElapsed(Duration elapsed) {
    if (elapsed >= const Duration(seconds: 5)) {
      return const _SyncProgressPresentation(
        title: 'Still working through a larger message history',
        description:
            'Longer scans are normal on phones with more SMS. SubWatch is still sorting what looks paid, what needs review, and what stays separate.',
      );
    }
    if (elapsed >= const Duration(seconds: 2)) {
      return const _SyncProgressPresentation(
        title: 'Sorting confirmed, review, and benefit items',
        description:
            'SubWatch is separating stronger paid signals from items that still need a decision.',
      );
    }
    return const _SyncProgressPresentation(
      title: 'Scanning messages on this phone',
      description:
          'SubWatch is reading local SMS history for recurring billing clues on this device.',
    );
  }

  final String title;
  final String description;
}

class _SourceStatusCard extends StatelessWidget {
  const _SourceStatusCard({
    required this.status,
    required this.isSyncing,
    required this.syncElapsed,
    required this.onSync,
    required this.onExplain,
  });

  final RuntimeLocalMessageSourceStatus status;
  final bool isSyncing;
  final ValueNotifier<Duration> syncElapsed;
  final Future<void> Function() onSync;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _shouldReduceMotion(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: syncElapsed,
      builder: (context, elapsed, child) {
        final syncProgress = _SyncProgressPresentation.fromElapsed(elapsed);
        final title = isSyncing ? 'Checking device SMS' : status.title;
        final description = isSyncing
            ? 'SubWatch is checking messages on this device. Nothing leaves your phone during this scan.'
            : status.description;
        final actionLabel = isSyncing ? 'Checking SMS...' : status.actionLabel;

        return LayoutBuilder(
          builder: (context, constraints) {
            final useStackedAction = constraints.maxWidth < 360;
            final actionButton = FilledButton.icon(
              key: const ValueKey<String>('sync-with-sms-button'),
              onPressed: isSyncing || !status.isActionEnabled ? null : onSync,
              icon: Icon(
                isSyncing ? Icons.hourglass_top : Icons.sync_rounded,
              ),
              label: Text(actionLabel),
            );

            return Container(
              key: const ValueKey<String>('snapshot-certificate-card'),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: DashboardShellPalette.paper.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: DashboardShellPalette.outline.withValues(alpha: 0.72),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (useStackedAction) ...<Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: actionButton,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        actionButton,
                      ],
                    ),
                  if (isSyncing) ...<Widget>[
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : _DashboardShellState._polishMotionDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        final position = Tween<Offset>(
                          begin: const Offset(0, -0.04),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: position,
                            child: child,
                          ),
                        );
                      },
                      child: DashboardPanel(
                        key: const ValueKey<String>('sync-progress-panel'),
                        backgroundColor: DashboardShellPalette.elevatedPaper,
                        borderColor: DashboardShellPalette.outlineStrong,
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                const DashboardBadge(
                                  label: 'On-device scan',
                                  backgroundColor: DashboardShellPalette.paper,
                                  foregroundColor: DashboardShellPalette.accent,
                                ),
                                Text(
                                  'Runs only on this phone',
                                  key: const ValueKey<String>(
                                    'sync-progress-privacy-label',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.mutedInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                key: ValueKey<String>('sync-progress-indicator'),
                                minHeight: 6,
                                backgroundColor:
                                    DashboardShellPalette.nestedPaper,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DashboardShellPalette.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : _DashboardShellState._polishMotionDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                syncProgress.title,
                                key: ValueKey<String>(
                                  'sync-progress-title-${syncProgress.title}',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : _DashboardShellState._polishMotionDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                syncProgress.description,
                                key: ValueKey<String>(
                                  'sync-progress-description-${syncProgress.description}',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You can keep browsing while this scan finishes.',
                              key: ValueKey<String>('sync-progress-hint'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    status.provenanceDescription,
                    key: const ValueKey<String>(
                        'runtime-provenance-description'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _SourceStatusMetadataCluster(status: status),
                      TextButton(
                        key: const ValueKey<String>(
                            'open-snapshot-explanation-button'),
                        onPressed: onExplain,
                        child: const Text('Why this view'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductGuidancePanel extends StatelessWidget {
  const _ProductGuidancePanel({
    required this.completion,
    required this.samplePreview,
    required this.onPrimaryAction,
    required this.onOpenTrustSheet,
  });

  final DashboardCompletionPresentation completion;
  final _SampleHomePreviewState? samplePreview;
  final Future<void> Function()? onPrimaryAction;
  final VoidCallback? onOpenTrustSheet;

  @override
  Widget build(BuildContext context) {
    if (samplePreview != null) {
      final stackedPreviewHeader =
          MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.1;
      final stackedPreviewMetrics =
          MediaQuery.sizeOf(context).width < 360 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.08;
      return DashboardPanel(
        key: const ValueKey<String>('product-guidance-panel'),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF9F2E8),
            DashboardShellPalette.paper,
          ],
        ),
        borderColor: const Color(0xFF7F654D),
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DashboardBadge(
                  label: completion.eyebrow,
                  icon: Icons.auto_awesome_outlined,
                  backgroundColor: DashboardShellPalette.registerPaper,
                  foregroundColor: DashboardShellPalette.accent,
                ),
                const DashboardBadge(
                  label: 'Your first scan replaces this preview',
                  icon: Icons.sms_rounded,
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  foregroundColor: DashboardShellPalette.mutedInk,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stackedPreviewHeader)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SubWatchBrandMark(size: 48, showBase: true),
                  const SizedBox(height: 10),
                  Text(
                    completion.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    completion.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.32,
                        ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          completion.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          completion.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.32,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SubWatchBrandMark(size: 54, showBase: true),
                ],
              ),
            const SizedBox(height: 14),
            if (stackedPreviewMetrics)
              Column(
                children: <Widget>[
                  _CompactMetricTile(
                    label: 'Monthly spend estimate',
                    value: samplePreview!.monthlyTotalLabel,
                    caption: samplePreview!.monthlyTotalCaption,
                    accent: DashboardShellPalette.accent,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Confirmed',
                    value: samplePreview!.confirmedCountLabel,
                    caption: 'Paid subscriptions',
                    accent: DashboardShellPalette.success,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Needs review',
                    value: samplePreview!.reviewCountLabel,
                    caption: 'Kept separate',
                    accent: DashboardShellPalette.caution,
                  ),
                  const SizedBox(height: 8),
                  _CompactMetricTile(
                    label: 'Trials & benefits',
                    value: samplePreview!.trialCountLabel,
                    caption: 'Separate access',
                    accent: DashboardShellPalette.accent,
                  ),
                ],
              )
            else ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Monthly spend estimate',
                      value: samplePreview!.monthlyTotalLabel,
                      caption: samplePreview!.monthlyTotalCaption,
                      accent: DashboardShellPalette.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Confirmed',
                      value: samplePreview!.confirmedCountLabel,
                      caption: 'Paid subscriptions',
                      accent: DashboardShellPalette.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Needs review',
                      value: samplePreview!.reviewCountLabel,
                      caption: 'Kept separate',
                      accent: DashboardShellPalette.caution,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetricTile(
                      label: 'Trials & benefits',
                      value: samplePreview!.trialCountLabel,
                      caption: 'Separate access',
                      accent: DashboardShellPalette.accent,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            DashboardPanel(
              key: const ValueKey<String>('sample-preview-details-panel'),
              backgroundColor: DashboardShellPalette.elevatedPaper,
              borderColor: DashboardShellPalette.outline,
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What this preview shows',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _InsetListGroup(
                    children: samplePreview!.highlights
                        .map(
                          (highlight) => _SamplePreviewHighlightRow(
                            highlight: highlight,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              completion.bullets[1],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
            if (onOpenTrustSheet != null) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey<String>(
                      'product-guidance-open-trust-sheet'),
                  onPressed: onOpenTrustSheet,
                  child: Text(completion.learnMoreActionLabel),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey<String>('product-guidance-panel'),
      child: DashboardPanel(
        backgroundColor: DashboardShellPalette.elevatedPaper,
        borderColor: DashboardShellPalette.outline,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (completion.eyebrow.isNotEmpty) ...<Widget>[
              DashboardBadge(
                label: completion.eyebrow,
                icon: Icons.info_outline_rounded,
                backgroundColor: DashboardShellPalette.paper,
                foregroundColor: DashboardShellPalette.accent,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              completion.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              completion.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
            if (completion.bullets.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              _InsetListGroup(
                children: completion.bullets
                    .map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: DashboardShellPalette.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bullet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.ink,
                                      height: 1.24,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (onPrimaryAction != null || onOpenTrustSheet != null) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  if (onPrimaryAction != null)
                    FilledButton(
                      key: const ValueKey<String>(
                        'product-guidance-primary-action',
                      ),
                      onPressed: () {
                        onPrimaryAction!();
                      },
                      child: Text(completion.primaryActionLabel),
                    ),
                  if (onOpenTrustSheet != null)
                    TextButton(
                      key: const ValueKey<String>(
                        'product-guidance-open-trust-sheet',
                      ),
                      onPressed: onOpenTrustSheet,
                      child: Text(completion.learnMoreActionLabel),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SampleHomePreviewState {
  const _SampleHomePreviewState({
    required this.monthlyTotalLabel,
    required this.monthlyTotalCaption,
    required this.confirmedCountLabel,
    required this.reviewCountLabel,
    required this.trialCountLabel,
    required this.highlights,
  });

  factory _SampleHomePreviewState.fromSnapshot(
    RuntimeDashboardSnapshot snapshot, {
    required DashboardTotalsSummaryPresentation totalsSummary,
    required DashboardDueSoonPresentation dueSoon,
  }) {
    final confirmedCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.confirmedSubscriptions)
        .toList(growable: false);
    final trialCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .toList(growable: false);
    final reviewItems = snapshot.reviewQueue;

    final confirmedTitles = confirmedCards
        .map((card) => card.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);
    final reviewTitles = reviewItems
        .map((item) => item.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);
    final trialTitles = trialCards
        .map((card) => card.title)
        .where((title) => title.trim().isNotEmpty)
        .toList(growable: false);

    return _SampleHomePreviewState(
      monthlyTotalLabel: totalsSummary.monthlyTotalValueLabel,
      monthlyTotalCaption: totalsSummary.includedInMonthlyTotalCount == 0
          ? 'Shown once billed amounts are visible'
          : 'From ${totalsSummary.includedInMonthlyTotalCount} paid renewals',
      confirmedCountLabel: confirmedCards.length.toString(),
      reviewCountLabel: reviewItems.length.toString(),
      trialCountLabel: trialCards.length.toString(),
      highlights: <_SamplePreviewHighlight>[
        _SamplePreviewHighlight(
          icon: Icons.verified_rounded,
          title: 'Confirmed subscriptions',
          badgeLabel: _previewCountLabel(confirmedCards.length),
          description: confirmedTitles.isEmpty
              ? 'Paid subscriptions appear here when billing evidence is strong enough.'
              : '${_joinPreviewTitles(confirmedTitles)} appear as paid subscriptions here.',
        ),
        _SamplePreviewHighlight(
          icon: Icons.schedule_rounded,
          title: 'Due soon',
          badgeLabel: dueSoon.hasItems ? 'Shown in preview' : 'Preview example',
          description: dueSoon.hasItems
              ? _dueSoonPreviewDescription(
                  dueSoon.items.first.serviceTitle,
                  dueSoon.items.first.renewalDateLabel,
                  dueSoon.items.first.amountLabel,
                )
              : _demoDueSoonFallback(
                  confirmedCards,
                  snapshot.provenance.recordedAt,
                ),
        ),
        _SamplePreviewHighlight(
          icon: Icons.rule_folder_outlined,
          title: 'Needs review',
          badgeLabel: _previewCountLabel(reviewItems.length),
          description: reviewTitles.isEmpty
              ? 'Unclear recurring signals stay separate until you decide.'
              : '${_joinPreviewTitles(reviewTitles)} stay separate until you decide.',
        ),
        _SamplePreviewHighlight(
          icon: Icons.workspace_premium_outlined,
          title: 'Trials & benefits',
          badgeLabel: _previewCountLabel(trialCards.length),
          description: trialTitles.isEmpty
              ? 'Bundled access stays visible without being counted as paid.'
              : '${trialTitles.first} stays visible as separate access.',
        ),
      ],
    );
  }

  final String monthlyTotalLabel;
  final String monthlyTotalCaption;
  final String confirmedCountLabel;
  final String reviewCountLabel;
  final String trialCountLabel;
  final List<_SamplePreviewHighlight> highlights;
}

class _SamplePreviewHighlight {
  const _SamplePreviewHighlight({
    required this.icon,
    required this.title,
    required this.badgeLabel,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String badgeLabel;
  final String description;
}

class _SamplePreviewHighlightRow extends StatelessWidget {
  const _SamplePreviewHighlightRow({
    required this.highlight,
  });

  final _SamplePreviewHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.08;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DashboardShellPalette.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DashboardShellPalette.outline.withValues(alpha: 0.7),
              ),
            ),
            child: Icon(
              highlight.icon,
              size: 18,
              color: DashboardShellPalette.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        highlight.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      DashboardBadge(
                        label: highlight.badgeLabel,
                        backgroundColor: DashboardShellPalette.paper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          highlight.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      DashboardBadge(
                        label: highlight.badgeLabel,
                        backgroundColor: DashboardShellPalette.paper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Text(
                  highlight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        height: 1.28,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeroConfirmedRescuePanel extends StatelessWidget {
  const _ZeroConfirmedRescuePanel({
    required this.completion,
    required this.rescueState,
    required this.onOpenReview,
    required this.onOpenSubscriptions,
    required this.onAddManually,
    required this.onOpenTrustSheet,
  });

  final DashboardCompletionPresentation completion;
  final _ZeroConfirmedRescueState rescueState;
  final Future<void> Function() onOpenReview;
  final Future<void> Function() onOpenSubscriptions;
  final Future<void> Function() onAddManually;
  final VoidCallback onOpenTrustSheet;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      key: const ValueKey<String>('home-zero-confirmed-rescue'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardBadge(
            label: completion.eyebrow,
            icon: Icons.verified_outlined,
            backgroundColor: DashboardShellPalette.successSoft,
            foregroundColor: DashboardShellPalette.success,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: rescueState.sourceLabel,
                icon: rescueState.sourceIcon,
                backgroundColor: DashboardShellPalette.elevatedPaper,
                foregroundColor: DashboardShellPalette.ink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            completion.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            completion.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.28,
                ),
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            key: const ValueKey<String>('home-zero-confirmed-education'),
            backgroundColor: DashboardShellPalette.elevatedPaper,
            borderColor: DashboardShellPalette.outline,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rescueState.explanationTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  rescueState.explanationBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.ink,
                        height: 1.28,
                      ),
                ),
                if (rescueState.supportingExplanationBody != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    rescueState.supportingExplanationBody!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.28,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (rescueState.visibleFindings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            DashboardPanel(
              key: const ValueKey<String>('home-zero-confirmed-findings'),
              backgroundColor: DashboardShellPalette.elevatedPaper,
              borderColor: DashboardShellPalette.outline,
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What stayed visible',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ..._buildFindingRows(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'What you can do next',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              FilledButton(
                key: const ValueKey<String>('zero-confirmed-primary-action'),
                onPressed: switch (rescueState.primaryActionKind) {
                  _ZeroConfirmedPrimaryActionKind.review => onOpenReview,
                  _ZeroConfirmedPrimaryActionKind.subscriptions =>
                    onOpenSubscriptions,
                  _ZeroConfirmedPrimaryActionKind.manualAdd => onAddManually,
                },
                child: Text(rescueState.primaryActionLabel),
              ),
              if (rescueState.primaryActionKind !=
                  _ZeroConfirmedPrimaryActionKind.manualAdd)
                OutlinedButton(
                  key: const ValueKey<String>(
                      'zero-confirmed-add-manually-action'),
                  onPressed: onAddManually,
                  child: const Text('Add manually'),
                ),
              TextButton(
                key: const ValueKey<String>('zero-confirmed-secondary-action'),
                onPressed: onOpenTrustSheet,
                child: const Text('Why the list is still empty'),
              ),
            ],
          ),
          if (rescueState.actionHint != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              rescueState.actionHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardShellPalette.mutedInk,
                    height: 1.28,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFindingRows() {
    return rescueState.visibleFindings
        .map(
          (summary) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ZeroConfirmedFindingRow(summary: summary),
          ),
        )
        .toList(growable: false);
  }
}

class _ZeroConfirmedRescueState {
  const _ZeroConfirmedRescueState({
    required this.sourceLabel,
    required this.sourceIcon,
    required this.explanationTitle,
    required this.explanationBody,
    required this.supportingExplanationBody,
    required this.reviewSummary,
    required this.trialSummary,
    required this.manualCount,
  });

  factory _ZeroConfirmedRescueState.fromSnapshot(
    RuntimeDashboardSnapshot snapshot, {
    required RuntimeLocalMessageSourceStatus sourceStatus,
  }) {
    final trialCards = snapshot.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .toList(growable: false);
    final reviewItems = snapshot.reviewQueue;
    final manualEntries = snapshot.manualSubscriptions;
    final hasReviewItems = reviewItems.isNotEmpty;
    final hasTrialCards = trialCards.isNotEmpty;

    final explanationTitle = hasReviewItems || hasTrialCards
        ? 'Why the confirmed list is still empty'
        : 'Why nothing is confirmed yet';
    final explanationBody = hasReviewItems
        ? 'Possible recurring items were kept in Review so SubWatch does not count them as paid too early.'
        : hasTrialCards
            ? 'This scan found trial or bundled access signals, and those stay separate from paid subscriptions.'
            : 'This scan did not surface recurring paid billing proof strong enough to confirm yet.';
    final supportingExplanationBody = hasReviewItems
        ? 'You can review each item yourself, add something manually, or wait for a later billing message to make the picture clearer.'
        : hasTrialCards
            ? 'Recharges, bundled access, and free benefits do not get counted as paid subscriptions. If you already know one you pay for directly, you can still add it manually.'
            : 'One-time payments, mandate setup, recharges, and bundled access are kept out of confirmed subscriptions on purpose. If you already know one you pay for, you can still add it manually.';

    return _ZeroConfirmedRescueState(
      sourceLabel: sourceStatus.title,
      sourceIcon: _sourceIconForTone(sourceStatus.tone),
      explanationTitle: explanationTitle,
      explanationBody: explanationBody,
      supportingExplanationBody: supportingExplanationBody,
      reviewSummary: _ZeroConfirmedFindingSummary(
        key: 'review',
        icon: Icons.rule_folder_outlined,
        title: 'Needs review',
        count: reviewItems.length,
        description: reviewItems.isEmpty
            ? 'No uncertain items were surfaced this time.'
            : _summarizeFindingTitles(
                reviewItems.map((item) => item.title),
                singularLabel: 'item waiting for a decision',
                pluralLabel: 'items waiting for a decision',
              ),
      ),
      trialSummary: _ZeroConfirmedFindingSummary(
        key: 'trialsBenefits',
        icon: Icons.workspace_premium_outlined,
        title: 'Trials & benefits',
        count: trialCards.length,
        description: trialCards.isEmpty
            ? 'No bundled or trial access stood out in this scan.'
            : _summarizeFindingTitles(
                trialCards.map((card) => card.title),
                singularLabel: 'separate access item found',
                pluralLabel: 'separate access items found',
              ),
      ),
      manualCount: manualEntries.length,
    );
  }

  final String sourceLabel;
  final IconData sourceIcon;
  final String explanationTitle;
  final String explanationBody;
  final String? supportingExplanationBody;
  final _ZeroConfirmedFindingSummary reviewSummary;
  final _ZeroConfirmedFindingSummary trialSummary;
  final int manualCount;

  List<_ZeroConfirmedFindingSummary> get visibleFindings =>
      <_ZeroConfirmedFindingSummary>[
        if (reviewSummary.count > 0) reviewSummary,
        if (trialSummary.count > 0) trialSummary,
      ];

  _ZeroConfirmedPrimaryActionKind get primaryActionKind {
    if (reviewSummary.count > 0) {
      return _ZeroConfirmedPrimaryActionKind.review;
    }
    if (trialSummary.count > 0 || manualCount > 0) {
      return _ZeroConfirmedPrimaryActionKind.subscriptions;
    }
    return _ZeroConfirmedPrimaryActionKind.manualAdd;
  }

  String get primaryActionLabel {
    switch (primaryActionKind) {
      case _ZeroConfirmedPrimaryActionKind.review:
        return reviewSummary.count == 1
            ? 'Review 1 item'
            : 'Review ${reviewSummary.count} items';
      case _ZeroConfirmedPrimaryActionKind.subscriptions:
        return trialSummary.count > 0
            ? 'See what was found'
            : 'Open subscriptions';
      case _ZeroConfirmedPrimaryActionKind.manualAdd:
        return 'Add manually';
    }
  }

  String? get actionHint {
    if (manualCount > 0) {
      return manualCount == 1
          ? '1 manual entry already stays separate in your subscriptions list.'
          : '$manualCount manual entries already stay separate in your subscriptions list.';
    }
    if (primaryActionKind == _ZeroConfirmedPrimaryActionKind.manualAdd) {
      return 'If you already know one you pay for, you can track it manually without changing this scan result.';
    }
    return null;
  }
}

enum _ZeroConfirmedPrimaryActionKind {
  review,
  subscriptions,
  manualAdd,
}

class _ZeroConfirmedFindingSummary {
  const _ZeroConfirmedFindingSummary({
    required this.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.description,
  });

  final String key;
  final IconData icon;
  final String title;
  final int count;
  final String description;
}

class _ZeroConfirmedFindingRow extends StatelessWidget {
  const _ZeroConfirmedFindingRow({
    required this.summary,
  });

  final _ZeroConfirmedFindingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey<String>('zero-confirmed-row-${summary.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: DashboardShellPalette.nestedPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.9),
            ),
          ),
          child: Icon(
            summary.icon,
            size: 16,
            color: DashboardShellPalette.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      summary.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    summary.count.toString(),
                    key:
                        ValueKey<String>('zero-confirmed-count-${summary.key}'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                summary.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      height: 1.22,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmsPermissionOnboardingSheet extends StatefulWidget {
  const _SmsPermissionOnboardingSheet({
    required this.onBrowseFirst,
    required this.onContinue,
  });

  final Future<void> Function() onBrowseFirst;
  final Future<void> Function() onContinue;

  @override
  State<_SmsPermissionOnboardingSheet> createState() =>
      _SmsPermissionOnboardingSheetState();
}

class _SmsPermissionOnboardingSheetState
    extends State<_SmsPermissionOnboardingSheet> {
  static const List<_SmsOnboardingPageContent> _pages =
      <_SmsOnboardingPageContent>[
    _SmsOnboardingPageContent(
      icon: Icons.search_rounded,
      title: 'Why SubWatch asks before checking SMS',
      description:
          'SubWatch looks for recurring billing, renewal, and plan clues only after you choose to continue.',
      stamps: <String>[
        'You choose when',
        'Sample view first',
      ],
      highlights: <String>[
        'You can keep browsing the sample view before deciding about SMS access.',
        'If billed amounts are visible, SubWatch can estimate monthly spend without claiming perfect coverage.',
      ],
    ),
    _SmsOnboardingPageContent(
      icon: Icons.lock_outline_rounded,
      title: 'Kept on this device',
      description:
          'SMS is read only when you start a scan. The subscription view and your review actions stay on this device.',
      stamps: <String>[
        'On this device',
        'No cloud account',
      ],
      highlights: <String>[
        'SubWatch does not upload your SMS inbox to build this view.',
        'No cloud account is required to use SubWatch.',
        'You can browse first and grant access only when you are ready.',
      ],
    ),
    _SmsOnboardingPageContent(
      icon: Icons.rule_folder_outlined,
      title: 'Careful by default',
      description:
          'Paid subscriptions, Review items, and separate access stay in different places.',
      stamps: <String>[
        'No auto-confirming',
        'Bundles stay separate',
      ],
      highlights: <String>[
        'Recharge-linked perks, telecom bundles, OTT access, and trials stay separate from paid subscriptions.',
        'If SubWatch is unsure, it keeps the item in Review instead of guessing.',
        'A quiet scan can still be correct when the proof is limited.',
      ],
    ),
  ];

  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];
    final isLastPage = _pageIndex == _pages.length - 1;
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('sms-permission-onboarding-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const DashboardBadge(
                        label: 'Before SMS permission',
                        icon: Icons.auto_awesome_outlined,
                        backgroundColor: DashboardShellPalette.registerPaper,
                        foregroundColor: DashboardShellPalette.accent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        page.title,
                        key: ValueKey<String>(
                          'sms-onboarding-page-$_pageIndex',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        page.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 10),
                      DashboardBadge(
                        label: '${_pageIndex + 1} of ${_pages.length}',
                        backgroundColor: DashboardShellPalette.elevatedPaper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const DashboardBadge(
                              label: 'Before SMS permission',
                              icon: Icons.auto_awesome_outlined,
                              backgroundColor:
                                  DashboardShellPalette.registerPaper,
                              foregroundColor: DashboardShellPalette.accent,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              page.title,
                              key: ValueKey<String>(
                                'sms-onboarding-page-$_pageIndex',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              page.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      DashboardBadge(
                        label: '${_pageIndex + 1} of ${_pages.length}',
                        backgroundColor: DashboardShellPalette.elevatedPaper,
                        foregroundColor: DashboardShellPalette.mutedInk,
                      ),
                    ],
                  ),
                if (page.stamps.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: page.stamps
                        .map(
                          (stamp) => DashboardBadge(
                            label: stamp,
                            backgroundColor: DashboardShellPalette.elevatedPaper,
                            foregroundColor: DashboardShellPalette.mutedInk,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DashboardShellPalette.paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: DashboardShellPalette.outline,
                              ),
                            ),
                            child: Icon(
                              page.icon,
                              color: DashboardShellPalette.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'What to expect',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...page.highlights.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: DashboardShellPalette.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.ink,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List<Widget>.generate(
                    _pages.length,
                    (index) => Container(
                      width: index == _pageIndex ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: index == _pageIndex
                            ? DashboardShellPalette.accent
                            : DashboardShellPalette.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: ValueKey<String>(
                    isLastPage
                        ? 'sms-permission-onboarding-continue-action'
                        : 'sms-permission-onboarding-next-action',
                  ),
                  onPressed: () async {
                    if (isLastPage) {
                      await widget.onContinue();
                      return;
                    }

                    setState(() {
                      _pageIndex += 1;
                    });
                  },
                  child: Text(
                    isLastPage ? 'Continue to SMS permission' : 'Next',
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey<String>(
                    'sms-permission-onboarding-browse-action',
                  ),
                  onPressed: () async {
                    await widget.onBrowseFirst();
                  },
                  child: const Text('Browse first'),
                ),
                const SizedBox(height: 4),
                Text(
                  'No SMS access is requested until you continue.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmsOnboardingPageContent {
  const _SmsOnboardingPageContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.stamps,
    required this.highlights,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> stamps;
  final List<String> highlights;
}

class _SmsPermissionRationaleSheet extends StatelessWidget {
  const _SmsPermissionRationaleSheet({
    required this.variant,
    required this.onContinue,
    required this.onSecondaryAction,
  });

  final RuntimeLocalMessageSourcePermissionRationaleVariant variant;
  final Future<void> Function() onContinue;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final content = _SmsPermissionRationaleContent.forVariant(variant);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('sms-permission-rationale-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            content.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'What to expect',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...content.bullets.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: DashboardShellPalette.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: DashboardShellPalette.ink,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey<String>(
                    'sms-permission-rationale-primary-action',
                  ),
                  onPressed: () {
                    onContinue();
                  },
                  child: Text(content.primaryActionLabel),
                ),
                const SizedBox(height: 6),
                TextButton(
                  key: const ValueKey<String>(
                    'sms-permission-rationale-secondary-action',
                  ),
                  onPressed: onSecondaryAction,
                  child: Text(content.secondaryActionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmsPermissionRationaleContent {
  const _SmsPermissionRationaleContent({
    required this.title,
    required this.description,
    required this.bullets,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
  });

  factory _SmsPermissionRationaleContent.forVariant(
    RuntimeLocalMessageSourcePermissionRationaleVariant variant,
  ) {
    switch (variant) {
      case RuntimeLocalMessageSourcePermissionRationaleVariant.firstRun:
        return const _SmsPermissionRationaleContent(
          title: 'Before Android asks for SMS access',
          description:
              'SubWatch only checks messages after you choose to continue. Android shows the SMS permission next.',
          bullets: <String>[
            'SubWatch reads SMS only to build the current subscription view on this device.',
            'Recharge perks, bundled access, and anything uncertain stay separate instead of being counted too early.',
            'You can browse first if you want to see the app before deciding.',
          ],
          primaryActionLabel: 'Continue to SMS permission',
          secondaryActionLabel: 'Browse first',
        );
      case RuntimeLocalMessageSourcePermissionRationaleVariant.retry:
        return const _SmsPermissionRationaleContent(
          title: 'Turn on SMS access only when you are ready',
          description:
              'Without SMS access, SubWatch can keep showing sample or saved local results, but it will not claim a fresh message check.',
          bullets: <String>[
            'If you continue, Android shows the SMS permission again.',
            'SubWatch reads SMS only for a refresh on this device.',
            'Privacy details and on-device limits stay available in Settings before you decide.',
          ],
          primaryActionLabel: 'Try device SMS again',
          secondaryActionLabel: 'Open Settings',
        );
    }
  }

  final String title;
  final String description;
  final List<String> bullets;
  final String primaryActionLabel;
  final String secondaryActionLabel;
}

class _ReviewQueueSummaryCard extends StatelessWidget {
  const _ReviewQueueSummaryCard({
    required this.reviewCount,
  });

  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final countLabel = reviewCount == 1 ? '1 item' : '$reviewCount items';
    final isEmpty = reviewCount == 0;

    return DashboardPanel(
      key: const ValueKey<String>('review-queue-summary-card'),
      backgroundColor: DashboardShellPalette.paper,
      borderColor: DashboardShellPalette.outlineStrong,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              DashboardBadge(
                label: isEmpty ? 'Clear for now' : '$countLabel kept separate',
                icon: isEmpty
                    ? Icons.verified_outlined
                    : Icons.rule_folder_outlined,
                backgroundColor: isEmpty
                    ? DashboardShellPalette.successSoft
                    : DashboardShellPalette.cautionSoft,
                foregroundColor: isEmpty
                    ? DashboardShellPalette.success
                    : DashboardShellPalette.caution,
              ),
              const DashboardBadge(
                label: 'Decisions stay reversible',
                icon: Icons.restore_rounded,
                backgroundColor: DashboardShellPalette.elevatedPaper,
                foregroundColor: DashboardShellPalette.mutedInk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEmpty
                ? 'Review is clear for now'
                : 'Review protects the confirmed list',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty
                ? 'SubWatch only places uncertain recurring-looking items here. A blank Review screen means nothing currently needs your decision.'
                : 'These items looked recurring, but SubWatch kept them out of confirmed subscriptions until the evidence or your decision makes the picture clearer.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.ink,
                  height: 1.28,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isEmpty
                ? 'Confirmed subscriptions, benefits, and past decisions stay in their own places.'
                : 'You can confirm something paid, keep bundled access separate, or mark it as not a subscription. Every choice stays reversible later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  height: 1.28,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupPanel extends StatelessWidget {
  const _SettingsGroupPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                ),
          ),
          const SizedBox(height: 6),
        ] else
          const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: DashboardShellPalette.paper.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.55),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsSubsection extends StatelessWidget {
  const _SettingsSubsection({
    super.key,
    required this.title,
    required this.caption,
    required this.children,
  });

  final String title;
  final String caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardShellPalette.mutedInk,
              ),
        ),
        const SizedBox(height: 8),
        _InsetListGroup(children: children),
      ],
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('help-sheet'),
      title: 'Using SubWatch',
      subtitle:
          'How scans, review, saved views, and separate access work in SubWatch.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'Refresh & source',
          items: <String>[
            'SubWatch reads SMS only when you start a refresh.',
            'The current view is labeled as sample, fresh, or saved so you know what you are seeing.',
            'If access is denied or unavailable, SubWatch says so instead of pretending a fresh scan happened.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Review',
          items: <String>[
            'Review holds items that looked recurring but are not safe to auto-confirm.',
            'Confirm only the subscriptions you recognise as paid.',
            'If something is bundled, free, or wrong, keep it separate or dismiss it. Undo remains available later.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'Confirmed, Review, separate access',
          items: <String>[
            'Confirmed subscriptions need stronger proof than a payment-like SMS alone.',
            'Review is for uncertain recurring signals.',
            'Trials and bundled benefits stay separate from direct paid subscriptions.',
          ],
        ),
      ],
    );
  }
}

class _PrivacyLocalDataSheet extends StatelessWidget {
  const _PrivacyLocalDataSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('privacy-local-data-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Privacy & local data',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'What SubWatch reads, what it keeps on this device, and what it deliberately does not do.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TrustSheetSection(
                  title: 'What stays local',
                  items: <String>[
                    'Current and saved subscription views, review decisions, and manual changes stay on this device.',
                    'SMS is read during a refresh and is not kept as an in-app inbox.',
                    'Sample, fresh, and saved views stay labeled separately so the current state stays honest.',
                  ],
                ),
                const SizedBox(height: 14),
                const _TrustSheetSection(
                  title: 'When SMS is read',
                  items: <String>[
                    'SubWatch reads device SMS only after you start a refresh.',
                    'Denied or unavailable access never pretends a fresh scan happened.',
                    'Another refresh replaces the current subscription view instead of building a hidden message history in the app.',
                  ],
                ),
                const SizedBox(height: 14),
                const _TrustSheetSection(
                  title: 'What SubWatch does not do',
                  items: <String>[
                    'It does not upload your SMS inbox to create your subscription view.',
                    'It does not run passive background monitoring.',
                    'It does not turn every payment, mandate, or micro-charge into a subscription.',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSubWatchSheet extends StatelessWidget {
  const _AboutSubWatchSheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('about-subwatch-sheet'),
      title: 'About SubWatch',
      subtitle:
          'What SubWatch is designed to do, and where it stays deliberately narrow.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'What it is',
          items: <String>[
            'SubWatch helps you spot likely subscriptions from messages on this device.',
            'It separates confirmed subscriptions from uncertain recurring-looking signals.',
            'It keeps bundled benefits and trials distinct from paid subscriptions.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'What it is not',
          items: <String>[
            'It is not a payments inbox or spending tracker.',
            'It does not treat every payment, mandate, or micro-charge as a subscription.',
            'It does not rely on cloud accounts or passive background monitoring.',
          ],
        ),
      ],
    );
  }
}

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailSheet(
      sheetKey: const ValueKey<String>('feedback-sheet'),
      title: 'Report a problem',
      subtitle:
          'If something looks wrong, use this guide to share the issue clearly.',
      children: const <Widget>[
        _TrustSheetSection(
          title: 'What helps',
          items: <String>[
            'What you expected to happen and what looked wrong instead.',
            'Whether it happened after checking messages, reviewing, undoing, or restoring.',
            'Your phone model, Android version, and whether SMS access was on.',
          ],
        ),
        SizedBox(height: 14),
        _TrustSheetSection(
          title: 'How to share it',
          items: <String>[
            'Use the same channel where you received SubWatch, or contact the person who gave you access.',
            'Include screenshots of the visible state when possible.',
            'Screenshots are usually enough. Share message text only if someone specifically asks for it.',
          ],
        ),
      ],
    );
  }
}

class _TrustHowItWorksSheet extends StatelessWidget {
  const _TrustHowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('trust-how-it-works-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outline,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'How SubWatch works',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'How SubWatch stays conservative when it reads device SMS.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TrustSheetSection(
                  title: 'What SubWatch confirms',
                  items: <String>[
                    'Confirmed subscriptions appear only when recurring billing proof is strong enough.',
                    'Single payments, mandate setup, and tiny verification charges are not enough by themselves.',
                    'If the signal is still weak, the item stays separate.',
                  ],
                ),
                const SizedBox(height: 14),
                const _TrustSheetSection(
                  title: 'What stays separate',
                  items: <String>[
                    'Review is for items that may be subscriptions but still need a decision.',
                    'Trials, bundles, and free access stay outside paid subscriptions.',
                    'Local hide or ignore actions do not rewrite what the scan actually found.',
                  ],
                ),
                const SizedBox(height: 14),
                const _TrustSheetSection(
                  title: 'What refresh means',
                  items: <String>[
                    'Refresh recomputes the current view from device SMS when available.',
                    'Saved views and limited-access states stay labeled separately from fresh checks.',
                    'Another refresh can replace this view when stronger evidence appears.',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDetailSheet extends StatelessWidget {
  const _SettingsDetailSheet({
    required this.sheetKey,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final Key sheetKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: sheetKey,
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $subtitle.',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: tileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: DashboardShellPalette.accent.withValues(alpha: 0.08),
            highlightColor:
                DashboardShellPalette.accent.withValues(alpha: 0.04),
            hoverColor: DashboardShellPalette.accent.withValues(alpha: 0.03),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      icon,
                      color: DashboardShellPalette.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  height: 1.26,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        Icon(
                          onTap == null
                              ? Icons.hourglass_top_rounded
                              : Icons.chevron_right_rounded,
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRecoveryRow extends StatelessWidget {
  const _SettingsRecoveryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.isBusy,
    required this.actionKey,
    required this.onUndo,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final bool isBusy;
  final Key actionKey;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final stackedAction =
        MediaQuery.sizeOf(context).width < 390 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.12;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.26,
              ),
        ),
        if (statusLabel != subtitle) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ],
    );
    final action = TextButton(
      key: actionKey,
      onPressed: isBusy ? null : onUndo,
      child: Text(isBusy ? 'Working...' : 'Undo'),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: stackedAction
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                details,
                const SizedBox(height: 8),
                action,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: details),
                const SizedBox(width: 10),
                action,
              ],
            ),
    );
  }
}

class _SettingsReminderRow extends StatelessWidget {
  const _SettingsReminderRow({
    super.key,
    required this.item,
    required this.isBusy,
    required this.onOpenReminderControls,
  });

  final DashboardRenewalReminderItemPresentation item;
  final bool isBusy;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final stackedAction =
        MediaQuery.sizeOf(context).width < 390 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.12;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.renewal.serviceTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          item.renewal.renewalDateLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.26,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          item.statusLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: DashboardShellPalette.mutedInk,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
    final action = TextButton(
      key: ValueKey<String>(
        'open-renewal-reminder-controls-${item.renewal.serviceKey}',
      ),
      onPressed: isBusy ? null : onOpenReminderControls,
      child: Text(isBusy ? 'Working...' : 'Reminder'),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: stackedAction
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                details,
                const SizedBox(height: 8),
                action,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: details),
                const SizedBox(width: 10),
                action,
              ],
            ),
    );
  }
}

class _SettingsGroupDivider extends StatelessWidget {
  const _SettingsGroupDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 28),
      height: 1,
      color: DashboardShellPalette.outline.withValues(alpha: 0.6),
    );
  }
}

class _TrustSheetSection extends StatelessWidget {
  const _TrustSheetSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outline,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: DashboardShellPalette.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.ink,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    super.key,
    required this.title,
    required this.children,
    this.countLabel,
    this.caption,
  });

  final String title;
  final List<Widget> children;
  final String? countLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return DashboardSectionFrame(
      key: key,
      title: title,
      countLabel: countLabel,
      caption: caption,
      children: children,
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashboardEmptyState(
      title: title,
      message: message,
      icon: icon,
    );
  }
}

class _ServiceViewControlsPanel extends StatelessWidget {
  const _ServiceViewControlsPanel({
    required this.searchController,
    required this.controls,
    required this.availableFilterModes,
    required this.visibleCountLabel,
    required this.onAddManual,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final DashboardServiceViewControls controls;
  final List<DashboardServiceFilterMode> availableFilterModes;
  final String visibleCountLabel;
  final Future<void> Function() onAddManual;
  final ValueChanged<DashboardServiceSortMode> onSortChanged;
  final ValueChanged<DashboardServiceFilterMode> onFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('service-view-controls-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: DashboardShellPalette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardShellPalette.outline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final useStackedActions =
              constraints.maxWidth < 340 ||
              textScale > 1.12 ||
              (controls.hasActiveControls && constraints.maxWidth < 420);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (useStackedActions) ...<Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      visibleCountLabel,
                      key: const ValueKey<String>('service-view-visible-count'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (controls.hasActiveControls)
                      Text(
                        'Filtered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.caution,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key:
                        const ValueKey<String>('open-manual-subscription-form'),
                    onPressed: onAddManual,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add manually'),
                  ),
                ),
                if (controls.hasActiveControls) ...<Widget>[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key:
                          const ValueKey<String>('reset-service-view-controls'),
                      onPressed: onClear,
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      visibleCountLabel,
                      key: const ValueKey<String>('service-view-visible-count'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (controls.hasActiveControls) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        'Filtered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.caution,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const Spacer(),
                    FilledButton.icon(
                      key: const ValueKey<String>(
                          'open-manual-subscription-form'),
                      onPressed: onAddManual,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add manually'),
                    ),
                    if (controls.hasActiveControls) const SizedBox(width: 8),
                    if (controls.hasActiveControls)
                      TextButton(
                        key: const ValueKey<String>(
                            'reset-service-view-controls'),
                        onPressed: onClear,
                        child: const Text('Reset'),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('service-search-input'),
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search subscriptions',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controls.isSearchActive
                      ? IconButton(
                          key: const ValueKey<String>('clear-service-search'),
                          tooltip: 'Clear search',
                          onPressed: () => searchController.clear(),
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final controlWidth = compact ? constraints.maxWidth : 210.0;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: controlWidth,
                        child:
                            DropdownButtonFormField<DashboardServiceSortMode>(
                          key: const ValueKey<String>('service-sort-dropdown'),
                          isExpanded: true,
                          initialValue: controls.sortMode,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Order',
                          ),
                          items: DashboardServiceSortMode.values
                              .map(
                                (mode) =>
                                    DropdownMenuItem<DashboardServiceSortMode>(
                                  value: mode,
                                  child: Text(
                                    _sortLabel(mode),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (mode) {
                            if (mode != null) {
                              onSortChanged(mode);
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: controlWidth,
                        child:
                            DropdownButtonFormField<DashboardServiceFilterMode>(
                          key:
                              const ValueKey<String>('service-filter-dropdown'),
                          isExpanded: true,
                          initialValue: controls.filterMode,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Show',
                          ),
                          items: availableFilterModes
                              .map(
                                (mode) => DropdownMenuItem<
                                    DashboardServiceFilterMode>(
                                  value: mode,
                                  child: Text(
                                    _filterLabel(mode),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (mode) {
                            if (mode != null) {
                              onFilterChanged(mode);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _sortLabel(DashboardServiceSortMode mode) {
    switch (mode) {
      case DashboardServiceSortMode.currentOrder:
        return 'Default';
      case DashboardServiceSortMode.nameAscending:
        return 'Name A-Z';
      case DashboardServiceSortMode.nameDescending:
        return 'Name Z-A';
    }
  }

  String _filterLabel(DashboardServiceFilterMode mode) {
    switch (mode) {
      case DashboardServiceFilterMode.allVisible:
        return 'All';
      case DashboardServiceFilterMode.confirmedOnly:
        return 'Subscriptions';
      case DashboardServiceFilterMode.observedOnly:
        return 'Needs review';
      case DashboardServiceFilterMode.separateAccessOnly:
        return 'Trials & benefits';
    }
  }
}

class _ServiceViewEmptyState extends StatelessWidget {
  const _ServiceViewEmptyState({
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('service-view-empty-state'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EmptySectionText(
          title: 'Nothing matches this view',
          message:
              'Try another search or reset the filters. If something is still missing, you can add it manually.',
          icon: Icons.search_off_rounded,
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          key: const ValueKey<String>('reset-service-view-controls-empty'),
          onPressed: onClear,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class _TotalsExplanationSheet extends StatelessWidget {
  const _TotalsExplanationSheet({
    required this.presentation,
  });

  final DashboardTotalsSummaryPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('totals-explanation-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            presentation.explainerTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            presentation.summaryCopy,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                ...presentation.explainerBullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: DashboardShellPalette.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: DashboardShellPalette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenewalReminderControlsSheet extends StatelessWidget {
  const _RenewalReminderControlsSheet({
    required this.item,
    required this.isBusy,
    required this.onSelectPreset,
    required this.onDisable,
  });

  final DashboardRenewalReminderItemPresentation item;
  final bool isBusy;
  final Future<void> Function(RenewalReminderLeadTimePreset preset)
      onSelectPreset;
  final Future<void> Function()? onDisable;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            'renewal-reminder-controls-sheet-${item.renewal.serviceKey}',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Local reminder',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reminders stay on this device and only appear when the renewal date is clear enough to trust.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.renewal.serviceTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Renews on ${item.renewal.renewalDateLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      if (item.renewal.amountLabel != null) ...<Widget>[
                        const SizedBox(height: 8),
                        DashboardBadge(
                          label: item.renewal.amountLabel!,
                          backgroundColor: DashboardShellPalette.paper,
                          foregroundColor: DashboardShellPalette.accent,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Remind me',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (item.availablePresets.isEmpty)
                  Text(
                    'No safe reminder time is left for this cycle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: item.availablePresets
                        .map(
                          (preset) => FilledButton(
                            key: ValueKey<String>(
                              'enable-reminder-${item.renewal.serviceKey}-${preset.name}',
                            ),
                            onPressed:
                                isBusy ? null : () => onSelectPreset(preset),
                            child: Text(
                              item.selectedPreset == preset
                                  ? '${preset.label} selected'
                                  : preset.label,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                if (onDisable != null) ...<Widget>[
                  const SizedBox(height: 12),
                  TextButton(
                    key: ValueKey<String>(
                      'disable-reminder-${item.renewal.serviceKey}',
                    ),
                    onPressed: isBusy ? null : onDisable,
                    child: const Text('Remove reminder'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualSubscriptionRow extends StatelessWidget {
  const _ManualSubscriptionRow({
    super.key,
    required this.entry,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenReminderControls,
  });

  final ManualSubscriptionEntry entry;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final amountLabel = _formatManualSubscriptionAmount(entry.amountInMinorUnits) ??
        'Amount not added';
    final renewalLabel = entry.hasNextRenewalDate
        ? _formatManualDate(entry.nextRenewalDate!)
        : 'No renewal date';
    final frequencyLabel = entry.billingCycle ==
            ManualSubscriptionBillingCycle.monthly
        ? 'Monthly'
        : 'Yearly';
    final identity = _identityStyle(
      entry.serviceName,
      accentColor: DashboardShellPalette.accent,
    );
    final summary = _manualSubscriptionRowSemantics(entry);
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.1;
    final expandedSubtitle =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Semantics(
              key: ValueKey<String>('manual-row-semantics-${entry.id}'),
              button: true,
              label: summary,
              hint: 'Opens manual entry details',
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  splashColor:
                      DashboardShellPalette.accent.withValues(alpha: 0.08),
                  highlightColor:
                      DashboardShellPalette.accent.withValues(alpha: 0.04),
                  hoverColor:
                      DashboardShellPalette.accent.withValues(alpha: 0.03),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 0, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DashboardServiceAvatar(
                          monogram: identity.monogram,
                          foregroundColor: identity.foreground,
                          backgroundColor: identity.background,
                          borderColor: identity.border,
                          sealColor: DashboardShellPalette.accent,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (stackedHeader)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      entry.serviceName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    const DashboardBadge(
                                      label: 'Added by you',
                                      backgroundColor:
                                          DashboardShellPalette.registerPaper,
                                      foregroundColor:
                                          DashboardShellPalette.accent,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        entry.serviceName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const DashboardBadge(
                                      label: 'Added by you',
                                      backgroundColor:
                                          DashboardShellPalette.registerPaper,
                                      foregroundColor:
                                          DashboardShellPalette.accent,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _manualSubscriptionSubtitle(entry),
                                maxLines: expandedSubtitle ? null : 2,
                                overflow: expandedSubtitle
                                    ? null
                                    : TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _SubscriptionMetaPanel(
                                amountValueKey: ValueKey<String>(
                                  'manual-meta-amount-${entry.id}',
                                ),
                                amountLabel: amountLabel,
                                renewalValueKey: ValueKey<String>(
                                  'manual-meta-renewal-${entry.id}',
                                ),
                                renewalLabel: renewalLabel,
                                frequencyValueKey: ValueKey<String>(
                                  'manual-meta-frequency-${entry.id}',
                                ),
                                frequencyLabel: frequencyLabel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 11, 8, 11),
            child: SizedBox.square(
              dimension: 48,
              child: PopupMenuButton<String>(
                key: ValueKey<String>('manual-subscription-actions-${entry.id}'),
                enabled: !isBusy,
                tooltip: 'More actions for ${entry.serviceName}',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'reminder':
                      onOpenReminderControls?.call();
                      break;
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit details'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Remove from list'),
                ),
                if (onOpenReminderControls != null)
                  const PopupMenuItem<String>(
                    value: 'reminder',
                    child: Text('Set local reminder'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualSubscriptionDetailsSheet extends StatelessWidget {
  const _ManualSubscriptionDetailsSheet({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenReminderControls,
  });

  final ManualSubscriptionEntry entry;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final VoidCallback? onOpenReminderControls;

  @override
  Widget build(BuildContext context) {
    final identity = _identityStyle(
      entry.serviceName,
      accentColor: DashboardShellPalette.accent,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>('manual-subscription-details-${entry.id}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DashboardServiceAvatar(
                      monogram: identity.monogram,
                      foregroundColor: identity.foreground,
                      backgroundColor: identity.background,
                      borderColor: identity.border,
                      sealColor: DashboardShellPalette.accent,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.serviceName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Added by you on this device. It stays separate from detected subscriptions and gives you a fallback when a scan is limited.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    const DashboardBadge(
                      label: 'Added by you',
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.accent,
                    ),
                    DashboardBadge(
                      label: entry.billingCycle ==
                              ManualSubscriptionBillingCycle.monthly
                          ? 'Monthly'
                          : 'Yearly',
                      backgroundColor: DashboardShellPalette.paper,
                      foregroundColor: DashboardShellPalette.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!entry.hasAmount || !entry.hasNextRenewalDate) ...<Widget>[
                  DashboardPanel(
                    backgroundColor: DashboardShellPalette.elevatedPaper,
                    borderColor: DashboardShellPalette.outline,
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Make this entry more useful',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _manualEntryImprovementCopy(entry),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                    height: 1.28,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _ManualSubscriptionDetailBlock(
                  title: 'Billing',
                  value: _manualSubscriptionBillingSummary(entry),
                ),
                if (entry.hasPlanLabel) ...<Widget>[
                  const SizedBox(height: 10),
                  _ManualSubscriptionDetailBlock(
                    title: 'Plan label',
                    value: entry.planLabel!,
                  ),
                ],
                if (entry.hasNextRenewalDate) ...<Widget>[
                  const SizedBox(height: 10),
                  _ManualSubscriptionDetailBlock(
                    title: 'Next renewal',
                    value: _formatManualDate(entry.nextRenewalDate!),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _ContextualActionSemantics(
                      label: 'Edit manual entry for ${entry.serviceName}',
                      child: FilledButton(
                        key: ValueKey<String>(
                            'edit-manual-subscription-${entry.id}'),
                        onPressed: onEdit,
                        child: const Text('Edit details'),
                      ),
                    ),
                    _ContextualActionSemantics(
                      label: 'Remove manual entry for ${entry.serviceName}',
                      child: TextButton(
                        key: ValueKey<String>(
                            'delete-manual-subscription-${entry.id}'),
                        onPressed: onDelete,
                        child: const Text('Remove from list'),
                      ),
                    ),
                    if (onOpenReminderControls != null)
                      _ContextualActionSemantics(
                        label: 'Set a local reminder for ${entry.serviceName}',
                        child: TextButton.icon(
                          key: ValueKey<String>(
                              'open-reminder-manual-subscription-${entry.id}'),
                          onPressed: onOpenReminderControls,
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                          ),
                          label: const Text('Set local reminder'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualSubscriptionDetailBlock extends StatelessWidget {
  const _ManualSubscriptionDetailBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: DashboardShellPalette.outline,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: DashboardShellPalette.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardShellPalette.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class _ManualAddFlowSheet extends StatefulWidget {
  const _ManualAddFlowSheet({required this.onSubmit});

  final Future<bool> Function(_ManualSubscriptionFormValue value) onSubmit;

  @override
  State<_ManualAddFlowSheet> createState() => _ManualAddFlowSheetState();
}

class _ManualAddFlowSheetState extends State<_ManualAddFlowSheet> {
  PopularServiceEntry? _pickedEntry;
  bool _showEditor = false;

  void _onPickService(PopularServiceEntry entry) {
    setState(() {
      _pickedEntry = entry;
      _showEditor = true;
    });
  }

  void _onCustomEntry() {
    setState(() {
      _pickedEntry = null;
      _showEditor = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showEditor) {
      return _ManualSubscriptionEditorSheet(
        initialServiceName: _pickedEntry?.name,
        initialPlanLabel: _pickedEntry?.planLabel,
        initialAmountInMinorUnits: _pickedEntry?.suggestedAmountInMinorUnits,
        initialBillingCycle: _pickedEntry?.billingCycle,
        onSubmit: widget.onSubmit,
      );
    }

    return _PopularServicePickerInline(
      onPickService: _onPickService,
      onCustomEntry: _onCustomEntry,
    );
  }
}

class _PopularServicePickerInline extends StatefulWidget {
  const _PopularServicePickerInline({
    required this.onPickService,
    required this.onCustomEntry,
  });

  final void Function(PopularServiceEntry entry) onPickService;
  final VoidCallback onCustomEntry;

  @override
  State<_PopularServicePickerInline> createState() =>
      _PopularServicePickerInlineState();
}

class _PopularServicePickerInlineState
    extends State<_PopularServicePickerInline> {
  final TextEditingController _searchController = TextEditingController();
  List<PopularServiceEntry> _filteredEntries = PopularServiceCatalog.entries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredEntries = PopularServiceCatalog.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('popular-service-picker'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Add a subscription you already know',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    DashboardBadge(
                      label: 'Added by you',
                      icon: Icons.edit_note_rounded,
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.accent,
                    ),
                    DashboardBadge(
                      label: 'Does not change scan results',
                      icon: Icons.verified_outlined,
                      backgroundColor: DashboardShellPalette.elevatedPaper,
                      foregroundColor: DashboardShellPalette.mutedInk,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('popular-service-search'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search popular services',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    filled: true,
                    fillColor: DashboardShellPalette.elevatedPaper,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final entry in _filteredEntries)
                      _PopularServiceChip(
                        entry: entry,
                        onTap: () {
                          widget.onPickService(entry);
                        },
                      ),
                    _CustomEntryChip(
                      onTap: widget.onCustomEntry,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularServicePickerSheet extends StatefulWidget {
  const _PopularServicePickerSheet();

  @override
  State<_PopularServicePickerSheet> createState() =>
      _PopularServicePickerSheetState();
}

class _PopularServicePickerSheetState
    extends State<_PopularServicePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PopularServiceEntry> _filteredEntries = PopularServiceCatalog.entries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredEntries = PopularServiceCatalog.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('popular-service-picker'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Add a subscription you already know',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start with a popular service or add your own. Manual entries stay marked as added by you.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const <Widget>[
                    DashboardBadge(
                      label: 'Added by you',
                      icon: Icons.edit_note_rounded,
                      backgroundColor: DashboardShellPalette.registerPaper,
                      foregroundColor: DashboardShellPalette.accent,
                    ),
                    DashboardBadge(
                      label: 'Does not change scan results',
                      icon: Icons.verified_outlined,
                      backgroundColor: DashboardShellPalette.elevatedPaper,
                      foregroundColor: DashboardShellPalette.mutedInk,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('popular-service-search'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search popular services',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: DashboardShellPalette.outline,
                      ),
                    ),
                    filled: true,
                    fillColor: DashboardShellPalette.elevatedPaper,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final entry in _filteredEntries)
                      _PopularServiceChip(
                        entry: entry,
                        onTap: () {
                          Navigator.of(context).pop(entry);
                        },
                      ),
                    _CustomEntryChip(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularServiceChip extends StatelessWidget {
  const _PopularServiceChip({
    required this.entry,
    required this.onTap,
  });

  final PopularServiceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brandEntry = ServiceIconRegistry.lookup(entry.serviceKey);
    final identity = _identityStyle(
      entry.name,
      accentColor: brandEntry?.brandColor ?? DashboardShellPalette.accent,
    );

    final amountLabel = entry.suggestedAmountInMinorUnits == null
        ? null
        : _formatChipAmount(entry.suggestedAmountInMinorUnits!);
    final cycleLabel =
        entry.billingCycle == ManualSubscriptionBillingCycle.yearly
            ? '/yr'
            : '/mo';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: (brandEntry?.brandColor ?? DashboardShellPalette.accent)
            .withValues(alpha: 0.08),
        highlightColor: (brandEntry?.brandColor ?? DashboardShellPalette.accent)
            .withValues(alpha: 0.04),
        hoverColor: (brandEntry?.brandColor ?? DashboardShellPalette.accent)
            .withValues(alpha: 0.03),
        child: Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardShellPalette.outline.withValues(alpha: 0.78),
            ),
          ),
          child: Row(
            children: <Widget>[
              DashboardServiceAvatar(
                monogram: identity.monogram,
                foregroundColor: identity.foreground,
                backgroundColor: identity.background,
                borderColor: identity.border,
                serviceKey: entry.serviceKey,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (amountLabel != null)
                      Text(
                        '$amountLabel$cycleLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomEntryChip extends StatelessWidget {
  const _CustomEntryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: DashboardShellPalette.accent.withValues(alpha: 0.08),
        highlightColor: DashboardShellPalette.accent.withValues(alpha: 0.04),
        hoverColor: DashboardShellPalette.accent.withValues(alpha: 0.03),
        child: Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: DashboardShellPalette.elevatedPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DashboardShellPalette.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DashboardShellPalette.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DashboardShellPalette.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: DashboardShellPalette.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Something else',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DashboardShellPalette.accent,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatChipAmount(int amountInMinorUnits) {
  final whole = amountInMinorUnits ~/ 100;
  return 'Rs $whole';
}

class _ManualSubscriptionEditorSheet extends StatefulWidget {
  const _ManualSubscriptionEditorSheet({
    required this.onSubmit,
    this.existingEntry,
    this.onDelete,
    this.initialServiceName,
    this.initialPlanLabel,
    this.initialAmountInMinorUnits,
    this.initialBillingCycle,
  });

  final ManualSubscriptionEntry? existingEntry;
  final Future<bool> Function(_ManualSubscriptionFormValue value) onSubmit;
  final Future<bool> Function()? onDelete;
  final String? initialServiceName;
  final String? initialPlanLabel;
  final int? initialAmountInMinorUnits;
  final ManualSubscriptionBillingCycle? initialBillingCycle;

  @override
  State<_ManualSubscriptionEditorSheet> createState() =>
      _ManualSubscriptionEditorSheetState();
}

class _ManualSubscriptionEditorSheetState
    extends State<_ManualSubscriptionEditorSheet> {
  late final TextEditingController _serviceNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _planLabelController;
  late ManualSubscriptionBillingCycle _billingCycle;
  DateTime? _nextRenewalDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(
      text:
          widget.existingEntry?.serviceName ?? widget.initialServiceName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingEntry?.amountInMinorUnits == null
          ? (widget.initialAmountInMinorUnits == null
              ? ''
              : _formatManualAmountInput(widget.initialAmountInMinorUnits!))
          : _formatManualAmountInput(widget.existingEntry!.amountInMinorUnits!),
    );
    _planLabelController = TextEditingController(
      text: widget.existingEntry?.planLabel ?? widget.initialPlanLabel ?? '',
    );
    _billingCycle = widget.existingEntry?.billingCycle ??
        widget.initialBillingCycle ??
        ManualSubscriptionBillingCycle.monthly;
    _nextRenewalDate = widget.existingEntry?.nextRenewalDate;
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _planLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;
    final canSave = !_isSaving && _serviceNameController.text.trim().isNotEmpty;
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            isEditing
                ? 'manual-subscription-editor-${widget.existingEntry!.id}'
                : 'manual-subscription-editor-new',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Edit manual entry'
                            : 'Add a manual subscription',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Added by you on this device. Use this when a scan is limited or you want something tracked right away without changing detected results.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              isEditing
                                  ? 'Edit manual entry'
                                  : 'Add a manual subscription',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Added by you on this device. Use this when a scan is limited or you want something tracked right away without changing detected results.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: DashboardShellPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                DashboardPanel(
                  key: const ValueKey<String>('manual-subscription-guidance'),
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'How this helps',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manual entries are a fallback path when a scan is sparse or something is missing. Add an amount to improve your estimate, and add a renewal date to show it in renewals and reminders.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                              height: 1.28,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('manual-service-name-input'),
                  controller: _serviceNameController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Service name',
                    hintText: 'Netflix, Adobe, Gym membership',
                    helperText: 'Use the name you want to recognise later.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('manual-amount-input'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (optional)',
                    hintText: '499',
                    helperText: 'Adds this entry to your estimate when filled.',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ManualSubscriptionBillingCycle>(
                  key: const ValueKey<String>('manual-billing-cycle-input'),
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(
                    labelText: 'Billing cycle',
                    helperText: 'Used with the amount you enter.',
                  ),
                  items: const <DropdownMenuItem<
                      ManualSubscriptionBillingCycle>>[
                    DropdownMenuItem<ManualSubscriptionBillingCycle>(
                      value: ManualSubscriptionBillingCycle.monthly,
                      child: Text('Monthly'),
                    ),
                    DropdownMenuItem<ManualSubscriptionBillingCycle>(
                      value: ManualSubscriptionBillingCycle.yearly,
                      child: Text('Yearly'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _billingCycle = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey<String>('manual-plan-label-input'),
                  controller: _planLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Plan label (optional)',
                    hintText: 'Family, Premium, Annual plan',
                    helperText: 'Helps you recognise this entry later.',
                  ),
                ),
                const SizedBox(height: 10),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outline,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Next renewal (optional)',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _nextRenewalDate == null
                            ? 'Not set'
                            : _formatManualDate(_nextRenewalDate!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a date to show this entry in renewals and local reminders.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton(
                            key: const ValueKey<String>(
                                'manual-pick-renewal-date'),
                            onPressed: _pickNextRenewalDate,
                            child: Text(
                              _nextRenewalDate == null
                                  ? 'Add date'
                                  : 'Change date',
                            ),
                          ),
                          if (_nextRenewalDate != null)
                            TextButton(
                              key: const ValueKey<String>(
                                  'manual-clear-renewal-date'),
                              onPressed: () {
                                setState(() {
                                  _nextRenewalDate = null;
                                });
                              },
                              child: const Text('Clear date'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton(
                      key: const ValueKey<String>('save-manual-subscription'),
                      onPressed: canSave ? _submit : null,
                      child:
                          Text(isEditing ? 'Save changes' : 'Add to your list'),
                    ),
                    if (widget.onDelete != null)
                      TextButton(
                        key: const ValueKey<String>(
                            'delete-manual-subscription'),
                        onPressed: _isSaving ? null : _delete,
                        child: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
    });

    final saved = await widget.onSubmit(
      _ManualSubscriptionFormValue(
        serviceName: _serviceNameController.text,
        amountInput: _amountController.text,
        billingCycle: _billingCycle,
        nextRenewalDate: _nextRenewalDate,
        planLabel: _planLabelController.text,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (saved) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    setState(() {
      _isSaving = true;
    });

    final deleted = await widget.onDelete!();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (deleted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickNextRenewalDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRenewalDate ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _nextRenewalDate = picked;
    });
  }
}

class _ManualSubscriptionFormValue {
  const _ManualSubscriptionFormValue({
    required this.serviceName,
    required this.amountInput,
    required this.billingCycle,
    required this.nextRenewalDate,
    required this.planLabel,
  });

  final String serviceName;
  final String amountInput;
  final ManualSubscriptionBillingCycle billingCycle;
  final DateTime? nextRenewalDate;
  final String planLabel;
}

class _LocalServiceControlsSheet extends StatefulWidget {
  const _LocalServiceControlsSheet({
    required this.card,
    required this.servicePresentationState,
    required this.isBusy,
    required this.onSaveLabel,
    required this.onResetLabel,
    required this.onTogglePin,
  });

  final DashboardCard card;
  final LocalServicePresentationState servicePresentationState;
  final bool isBusy;
  final Future<void> Function(String label) onSaveLabel;
  final Future<void> Function()? onResetLabel;
  final Future<void> Function() onTogglePin;

  @override
  State<_LocalServiceControlsSheet> createState() =>
      _LocalServiceControlsSheetState();
}

class _LocalServiceControlsSheetState
    extends State<_LocalServiceControlsSheet> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.servicePresentationState.localLabel ?? '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedLabel = _labelController.text.trim();
    final canSaveLabel = !widget.isBusy &&
        normalizedLabel.isNotEmpty &&
        normalizedLabel != widget.servicePresentationState.displayTitle;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
            'local-service-controls-sheet-${widget.card.serviceKey.value}',
          ),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'On this device',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only changes how this service looks on this device. It does not change the subscription itself.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DashboardShellPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.elevatedPaper,
                  borderColor: DashboardShellPalette.outlineStrong,
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Detected name',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.servicePresentationState.originalTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Name in app',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: ValueKey<String>(
                          'local-label-input-${widget.card.serviceKey.value}',
                        ),
                        controller: _labelController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rename on this device',
                          filled: true,
                          fillColor: DashboardShellPalette.nestedPaper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.outlineStrong,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.outlineStrong,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: DashboardShellPalette.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton(
                            key: ValueKey<String>(
                              'save-local-label-${widget.card.serviceKey.value}',
                            ),
                            onPressed: canSaveLabel
                                ? () => widget.onSaveLabel(normalizedLabel)
                                : null,
                            child: const Text('Save name'),
                          ),
                          if (widget.onResetLabel != null)
                            TextButton(
                              key: ValueKey<String>(
                                'reset-local-label-${widget.card.serviceKey.value}',
                              ),
                              onPressed:
                                  widget.isBusy ? null : widget.onResetLabel,
                              child: const Text('Clear name'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'List position',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: DashboardShellPalette.mutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.servicePresentationState.isPinned
                            ? 'Pinned items stay near the top on this device.'
                            : 'Pin to keep this item near the top on this device.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        key: ValueKey<String>(
                          widget.servicePresentationState.isPinned
                              ? 'unpin-service-${widget.card.serviceKey.value}'
                              : 'pin-service-${widget.card.serviceKey.value}',
                        ),
                        onPressed: widget.isBusy ? null : widget.onTogglePin,
                        child: Text(
                          widget.servicePresentationState.isPinned
                              ? 'Unpin'
                              : 'Pin near top',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.title,
    required this.subtitle,
    required this.stampLabel,
    required this.accentColor,
    required this.stampBackgroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.identity,
    this.serviceKey,
    this.secondaryStampLabel,
    this.secondaryStampBackgroundColor,
    this.secondaryStampForegroundColor,
    this.evidenceLabel,
    this.evidenceText,
    this.footer,
    this.headerTrailing,
  });

  final String title;
  final String subtitle;
  final String stampLabel;
  final Color accentColor;
  final Color stampBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final _PassportIdentityStyle identity;
  final String? serviceKey;
  final String? secondaryStampLabel;
  final Color? secondaryStampBackgroundColor;
  final Color? secondaryStampForegroundColor;
  final String? evidenceLabel;
  final String? evidenceText;
  final Widget? footer;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 14.0;
    const topPadding = 14.0;
    const bottomPadding = 12.0;
    const accentBarWidth = 5.0;
    const accentBarHeight = 52.0;
    const avatarSize = 44.0;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return DashboardPanel(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(
            Colors.white.withValues(alpha: 0.02),
            backgroundColor,
          ),
          Color.alphaBlend(
            Colors.black.withValues(alpha: 0.16),
            backgroundColor,
          ),
        ],
      ),
      borderColor: borderColor,
      radius: 22,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: accentBarWidth,
                height: accentBarHeight,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              DashboardServiceAvatar(
                key: ValueKey<String>('passport-avatar-$title'),
                monogram: identity.monogram,
                foregroundColor: identity.foreground,
                backgroundColor: identity.background,
                borderColor: identity.border,
                serviceKey: serviceKey,
                sealColor: accentColor,
                size: avatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardShellPalette.mutedInk,
                          ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        DashboardBadge(
                          label: stampLabel,
                          backgroundColor: stampBackgroundColor,
                          foregroundColor: accentColor,
                        ),
                        if (secondaryStampLabel != null)
                          DashboardBadge(
                            label: secondaryStampLabel!,
                            backgroundColor: secondaryStampBackgroundColor ??
                                DashboardShellPalette.paper,
                            foregroundColor:
                                secondaryStampForegroundColor ?? accentColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (headerTrailing != null) ...<Widget>[
                const SizedBox(width: 8),
                headerTrailing!,
              ],
            ],
          ),
          if (evidenceLabel != null && evidenceText != null) ...<Widget>[
            const SizedBox(height: 10),
            DashboardPanel(
              backgroundColor: DashboardShellPalette.nestedPaper,
              borderColor: accentColor.withValues(alpha: 0.2),
              radius: 16,
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    evidenceLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evidenceText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardShellPalette.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: borderColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

enum _SubscriptionCardMenuAction {
  explain,
  organize,
  hide,
  ignore,
}

enum _ReviewCardMenuAction {
  explain,
  ignore,
}

class _SubscriptionCardOverflowButton extends StatelessWidget {
  const _SubscriptionCardOverflowButton({
    required this.bucket,
    required this.card,
    required this.explanation,
    required this.servicePresentationState,
    required this.localControlBusy,
    required this.localPresentationBusy,
    required this.onExplain,
    required this.onOpenLocalServiceControls,
    required this.onHide,
    required this.onIgnore,
  });

  final DashboardBucket bucket;
  final DashboardCard card;
  final ContextualExplanationPresentation explanation;
  final LocalServicePresentationState servicePresentationState;
  final bool localControlBusy;
  final bool localPresentationBusy;
  final VoidCallback onExplain;
  final VoidCallback onOpenLocalServiceControls;
  final VoidCallback onHide;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: PopupMenuButton<_SubscriptionCardMenuAction>(
        key: ValueKey<String>(
          'service-card-actions-${bucket.name}-${card.serviceKey.value}',
        ),
        enabled: !(localControlBusy || localPresentationBusy),
        tooltip: 'More actions for ${card.title}',
        padding: EdgeInsets.zero,
        color: DashboardShellPalette.elevatedPaper,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(Icons.more_horiz_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DashboardShellPalette.outlineStrong),
        ),
        onSelected: (action) {
        switch (action) {
          case _SubscriptionCardMenuAction.explain:
            onExplain();
            break;
          case _SubscriptionCardMenuAction.organize:
            onOpenLocalServiceControls();
            break;
          case _SubscriptionCardMenuAction.hide:
            onHide();
            break;
          case _SubscriptionCardMenuAction.ignore:
            onIgnore();
            break;
        }
        },
        itemBuilder: (context) => <PopupMenuEntry<_SubscriptionCardMenuAction>>[
        PopupMenuItem<_SubscriptionCardMenuAction>(
          key: ValueKey<String>(
            'open-card-explanation-${bucket.name}-${card.title}',
          ),
          value: _SubscriptionCardMenuAction.explain,
          child: Row(
            children: <Widget>[
              const Icon(Icons.help_outline_rounded, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(explanation.actionLabel)),
            ],
          ),
        ),
        PopupMenuItem<_SubscriptionCardMenuAction>(
          key: ValueKey<String>(
            'open-local-service-controls-${bucket.name}-${card.serviceKey.value}',
          ),
          value: _SubscriptionCardMenuAction.organize,
          child: Row(
            children: <Widget>[
              Icon(
                servicePresentationState.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Organize')),
            ],
          ),
        ),
        PopupMenuItem<_SubscriptionCardMenuAction>(
          key: ValueKey<String>(
            'hide-card-action-${bucket.name}-${card.serviceKey.value}',
          ),
          value: _SubscriptionCardMenuAction.hide,
          child: const Row(
            children: <Widget>[
              Icon(Icons.visibility_off_outlined, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Hide')),
            ],
          ),
        ),
        PopupMenuItem<_SubscriptionCardMenuAction>(
          key: ValueKey<String>(
            'ignore-card-action-${card.serviceKey.value}',
          ),
          value: _SubscriptionCardMenuAction.ignore,
          child: const Row(
            children: <Widget>[
              Icon(Icons.do_not_disturb_on_outlined, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Ignore')),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _ReviewDecisionPassportCard extends StatelessWidget {
  const _ReviewDecisionPassportCard({
    required this.item,
    required this.descriptor,
    required this.presentation,
    required this.explanation,
    required this.isBusy,
    required this.onOpenDetails,
    required this.onExplain,
    required this.onIgnore,
    required this.onConfirm,
    required this.onDismiss,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback onOpenDetails;
  final VoidCallback onExplain;
  final VoidCallback onIgnore;
  final VoidCallback? onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final identity = _identityStyle(
      item.title,
      accentColor: DashboardShellPalette.caution,
    );
    final summary = _reviewCardSemantics(
      item,
      presentation: presentation,
      descriptor: descriptor,
    );

    return Semantics(
      container: true,
      label: summary,
      child: _PassportCard(
        title: item.title,
        subtitle: presentation.explanationDescription,
        stampLabel:
            descriptor.canConfirm ? 'Needs your review' : 'Needs a clearer service',
        secondaryStampLabel: presentation.stampLabel,
        accentColor: DashboardShellPalette.caution,
        stampBackgroundColor: DashboardShellPalette.paper,
        secondaryStampBackgroundColor: DashboardShellPalette.paper,
        secondaryStampForegroundColor: DashboardShellPalette.mutedInk,
        backgroundColor: DashboardShellPalette.elevatedPaper,
        borderColor: DashboardShellPalette.outlineStrong,
        identity: identity,
        serviceKey: item.serviceKey.value,
        evidenceLabel: presentation.rationaleLabel,
        evidenceText: presentation.cardRationale,
        headerTrailing: _ReviewActionOverflowButton(
          title: item.title,
          descriptor: descriptor,
          explanation: explanation,
          isBusy: isBusy,
          onExplain: onExplain,
          onIgnore: onIgnore,
        ),
        footer: _ReviewDecisionActionsBlock(
          title: descriptor.canConfirm
              ? 'Choose what fits'
              : 'Choose how to handle it',
          helper:
              'Every decision stays local to this device and can be undone later.',
          children: <Widget>[
            _ContextualActionSemantics(
              label: descriptor.canConfirm
                  ? 'See why ${item.title} is in review'
                  : 'See details for ${item.title}',
              enabled: !isBusy,
              child: OutlinedButton(
                key: ValueKey<String>(
                  'open-review-details-${descriptor.targetKey}',
                ),
                onPressed: isBusy ? null : onOpenDetails,
                child: Text(
                  isBusy
                      ? 'Working...'
                      : descriptor.canConfirm
                          ? 'See why'
                          : 'See details',
                ),
              ),
            ),
            if (descriptor.canConfirm)
              _ContextualActionSemantics(
                label: 'Confirm ${item.title} as a paid subscription',
                enabled: !isBusy,
                child: FilledButton(
                  key: ValueKey<String>(
                    'confirm-review-action-${descriptor.targetKey}',
                  ),
                  onPressed: isBusy ? null : onConfirm,
                  child: Text(
                    isBusy ? 'Working...' : presentation.confirmLabel!,
                  ),
                ),
              ),
            _ContextualActionSemantics(
              label: 'Mark ${item.title} as not a subscription',
              enabled: !isBusy,
              child: OutlinedButton(
                key: ValueKey<String>(
                  'dismiss-review-action-${descriptor.targetKey}',
                ),
                onPressed: isBusy ? null : onDismiss,
                child: Text(
                  isBusy ? 'Working...' : presentation.dismissLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItemDetailsSheet extends StatelessWidget {
  const _ReviewItemDetailsSheet({
    required this.item,
    required this.descriptor,
    required this.presentation,
    required this.explanation,
    required this.isBusy,
    required this.onDismiss,
    required this.onEditDetails,
    required this.onExplain,
    this.onConfirm,
    this.onMarkAsBenefit,
  });

  final ReviewItem item;
  final ReviewItemActionDescriptor descriptor;
  final ReviewQueueItemPresentation presentation;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onMarkAsBenefit;
  final VoidCallback onDismiss;
  final VoidCallback onEditDetails;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final accentColor = DashboardShellPalette.caution;
    final stampLabel =
        descriptor.canConfirm ? 'Needs your review' : 'Needs a clearer service';
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: ValueKey<String>(
              'review-item-details-sheet-${descriptor.targetKey}'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                if (stackedHeader)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SheetCloseButton(
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.explanationDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardShellPalette.mutedInk,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          DashboardBadge(
                            label: stampLabel,
                            backgroundColor: DashboardShellPalette.elevatedPaper,
                            foregroundColor: accentColor,
                          ),
                          const DashboardBadge(
                            label: 'Reversible',
                            backgroundColor: DashboardShellPalette.elevatedPaper,
                            foregroundColor: DashboardShellPalette.mutedInk,
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              presentation.explanationDescription,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                DashboardBadge(
                                  label: stampLabel,
                                  backgroundColor:
                                      DashboardShellPalette.elevatedPaper,
                                  foregroundColor: accentColor,
                                ),
                                const DashboardBadge(
                                  label: 'Reversible',
                                  backgroundColor:
                                      DashboardShellPalette.elevatedPaper,
                                  foregroundColor:
                                      DashboardShellPalette.mutedInk,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _SheetCloseButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _ReviewDetailsInfoCard(
                  title: presentation.rationaleLabel,
                  body: presentation.rationale,
                  icon: Icons.receipt_long_outlined,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 10),
                _ReviewDetailsInfoCard(
                  title: presentation.whyFlaggedTitle,
                  body: presentation.whyFlagged,
                  icon: Icons.flag_outlined,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 10),
                _ReviewDetailsInfoCard(
                  title: presentation.whyNotConfirmedTitle,
                  body: presentation.whyNotConfirmed,
                  icon: Icons.verified_outlined,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 10),
                _ReviewDetailsInfoCard(
                  title: presentation.actionHintTitle,
                  body: presentation.actionHint,
                  icon: Icons.touch_app_outlined,
                  accentColor: DashboardShellPalette.accent,
                ),
                const SizedBox(height: 10),
                DashboardPanel(
                  backgroundColor: DashboardShellPalette.nestedPaper,
                  borderColor: accentColor.withValues(alpha: 0.18),
                  radius: 18,
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: DashboardShellPalette.mutedInk,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          explanation.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardShellPalette.mutedInk,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ReviewDecisionActionsBlock(
                  framed: true,
                  title: descriptor.canConfirm
                      ? 'Choose what fits'
                      : 'Choose how to handle it',
                  helper:
                      'Every decision stays local to this device and can be undone later.',
                  accentColor: accentColor,
                  children: <Widget>[
                    if (onConfirm != null)
                      _ContextualActionSemantics(
                        label: 'Confirm ${item.title} as a paid subscription',
                        enabled: !isBusy,
                        child: FilledButton(
                          key: ValueKey<String>(
                            'review-details-confirm-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onConfirm,
                          child: Text(
                            isBusy ? 'Working...' : presentation.confirmLabel!,
                          ),
                        ),
                      ),
                    if (onConfirm == null)
                      _ContextualActionSemantics(
                        label: 'Edit review details for ${item.title}',
                        enabled: !isBusy,
                        child: FilledButton(
                          key: ValueKey<String>(
                            'review-details-edit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onEditDetails,
                          child: Text(
                            isBusy ? 'Working...' : presentation.editLabel,
                          ),
                        ),
                      ),
                    if (onMarkAsBenefit != null)
                      _ContextualActionSemantics(
                        label:
                            'Keep ${item.title} separate as a benefit or bundle',
                        enabled: !isBusy,
                        child: OutlinedButton(
                          key: ValueKey<String>(
                            'review-details-benefit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onMarkAsBenefit,
                          child: Text(
                            isBusy ? 'Working...' : presentation.benefitLabel!,
                          ),
                        ),
                      ),
                    _ContextualActionSemantics(
                      label: 'Mark ${item.title} as not a subscription',
                      enabled: !isBusy,
                      child: OutlinedButton(
                        key: ValueKey<String>(
                          'review-details-dismiss-${descriptor.targetKey}',
                        ),
                        onPressed: isBusy ? null : onDismiss,
                        child: Text(
                          isBusy ? 'Working...' : presentation.dismissLabel,
                        ),
                      ),
                    ),
                    if (onConfirm != null)
                      _ContextualActionSemantics(
                        label: 'Edit review details for ${item.title}',
                        enabled: !isBusy,
                        child: TextButton(
                          key: ValueKey<String>(
                            'review-details-edit-${descriptor.targetKey}',
                          ),
                          onPressed: isBusy ? null : onEditDetails,
                          child: Text(
                            isBusy ? 'Working...' : presentation.editLabel,
                          ),
                        ),
                      ),
                    _ContextualActionSemantics(
                      label: 'Explain why ${item.title} is in review',
                      enabled: !isBusy,
                      child: TextButton(
                        key: ValueKey<String>(
                          'review-details-explain-${descriptor.targetKey}',
                        ),
                        onPressed: isBusy ? null : onExplain,
                        child: Text(explanation.actionLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewDetailsInfoCard extends StatelessWidget {
  const _ReviewDetailsInfoCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      backgroundColor: DashboardShellPalette.elevatedPaper,
      borderColor: accentColor.withValues(alpha: 0.18),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDecisionActionsBlock extends StatelessWidget {
  const _ReviewDecisionActionsBlock({
    required this.title,
    required this.helper,
    required this.children,
    this.framed = false,
    this.accentColor = DashboardShellPalette.caution,
  });

  final String title;
  final String helper;
  final List<Widget> children;
  final bool framed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DashboardShellPalette.mutedInk,
                height: 1.24,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children,
        ),
      ],
    );

    if (!framed) {
      return content;
    }

    return DashboardPanel(
      backgroundColor: DashboardShellPalette.nestedPaper,
      borderColor: accentColor.withValues(alpha: 0.18),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      child: content,
    );
  }
}

class _ReviewActionOverflowButton extends StatelessWidget {
  const _ReviewActionOverflowButton({
    required this.title,
    required this.descriptor,
    required this.explanation,
    required this.isBusy,
    required this.onExplain,
    required this.onIgnore,
  });

  final String title;
  final ReviewItemActionDescriptor descriptor;
  final ContextualExplanationPresentation explanation;
  final bool isBusy;
  final VoidCallback onExplain;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: PopupMenuButton<_ReviewCardMenuAction>(
        key: ValueKey<String>('review-card-actions-${descriptor.targetKey}'),
        enabled: !isBusy,
        tooltip: 'More actions for $title',
        padding: EdgeInsets.zero,
        color: DashboardShellPalette.elevatedPaper,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(Icons.more_horiz_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DashboardShellPalette.outlineStrong),
        ),
        onSelected: (action) {
        switch (action) {
          case _ReviewCardMenuAction.explain:
            onExplain();
            break;
          case _ReviewCardMenuAction.ignore:
            onIgnore();
            break;
        }
        },
        itemBuilder: (context) => <PopupMenuEntry<_ReviewCardMenuAction>>[
        PopupMenuItem<_ReviewCardMenuAction>(
          key: ValueKey<String>(
              'open-review-explanation-${descriptor.targetKey}'),
          value: _ReviewCardMenuAction.explain,
          child: Row(
            children: <Widget>[
              const Icon(Icons.help_outline_rounded, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(explanation.actionLabel)),
            ],
          ),
        ),
        PopupMenuItem<_ReviewCardMenuAction>(
          key: ValueKey<String>(
              'ignore-review-item-action-${descriptor.targetKey}'),
          value: _ReviewCardMenuAction.ignore,
          child: const Row(
            children: <Widget>[
              Icon(Icons.do_not_disturb_on_outlined, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Hide on this device')),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _ContextualExplanationSheet extends StatelessWidget {
  const _ContextualExplanationSheet({
    required this.presentation,
  });

  final ContextualExplanationPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: DashboardPanel(
          key: const ValueKey<String>('contextual-explanation-sheet'),
          backgroundColor: DashboardShellPalette.paper,
          borderColor: DashboardShellPalette.outlineStrong,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            presentation.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            presentation.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: DashboardShellPalette.mutedInk,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ],
                ),
                const SizedBox(height: 14),
                _TrustSheetSection(
                  title: 'Why SubWatch shows this',
                  items: presentation.bullets,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: 'Close',
        padding: EdgeInsets.zero,
        splashRadius: 24,
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: DashboardShellPalette.mutedInk.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _StatusMetaBadge extends StatelessWidget {
  const _StatusMetaBadge({
    required this.label,
    required this.valueKey,
  });

  final String label;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardShellPalette.nestedPaper.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DashboardShellPalette.mutedInk.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        key: valueKey,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DashboardShellPalette.mutedInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
            ),
      ),
    );
  }
}

class _SourceStatusMetadataCluster extends StatelessWidget {
  const _SourceStatusMetadataCluster({
    required this.status,
  });

  final RuntimeLocalMessageSourceStatus status;

  @override
  Widget build(BuildContext context) {
    final showFreshnessLabel =
        status.freshnessLabel.trim() != status.provenanceTitle.trim();
    final labels = <String>[
      'Current view ${status.provenanceTitle}',
      if (showFreshnessLabel) 'Freshness ${status.freshnessLabel}',
      if (status.hasLocalModifications &&
          status.localModificationsLabel != null)
        status.localModificationsLabel!,
    ];

    return Semantics(
      key: const ValueKey<String>('runtime-source-metadata-semantics'),
      label: labels.join('. '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 10,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (showFreshnessLabel) ...<Widget>[
              Text(
                '\u2022',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                    ),
              ),
              Text(
                status.freshnessLabel,
                key: const ValueKey<String>('runtime-freshness-label'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DashboardShellPalette.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            _StatusMetaBadge(
              label: status.provenanceTitle,
              valueKey: const ValueKey<String>('runtime-provenance-title'),
            ),
            if (status.hasLocalModifications &&
                status.localModificationsLabel != null)
              _StatusMetaBadge(
                label: status.localModificationsLabel!,
                valueKey: const ValueKey<String>(
                  'runtime-local-state-label',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextualActionSemantics extends StatelessWidget {
  const _ContextualActionSemantics({
    required this.label,
    this.enabled = true,
    required this.child,
  });

  final String label;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}

class _BucketStyle {
  const _BucketStyle({
    required this.badgeLabel,
    required this.background,
    required this.border,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final String badgeLabel;
  final Color background;
  final Color border;
  final Color badgeBackground;
  final Color badgeForeground;
}

class _PassportIdentityStyle {
  const _PassportIdentityStyle({
    required this.monogram,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String monogram;
  final Color background;
  final Color foreground;
  final Color border;
}

_PassportIdentityStyle _identityStyle(
  String title, {
  required Color accentColor,
}) {
  const palettes = <(Color, Color, Color)>[
    (Color(0xFF243028), Color(0xFF9BD4BC), Color(0xFF395247)),
    (Color(0xFF26232F), Color(0xFFBDC7DD), Color(0xFF413D50)),
    (Color(0xFF30231D), Color(0xFFE4B27B), Color(0xFF4A372C)),
    (Color(0xFF25291F), Color(0xFFB9C98B), Color(0xFF3C4530)),
    (Color(0xFF312327), Color(0xFFD7A7AE), Color(0xFF4A363A)),
  ];
  final index =
      title.runes.fold<int>(0, (sum, rune) => sum + rune) % palettes.length;
  final palette = palettes[index];
  return _PassportIdentityStyle(
    monogram: _monogramForTitle(title),
    background: palette.$1,
    foreground: palette.$2,
    border: Color.alphaBlend(
      accentColor.withValues(alpha: 0.12),
      palette.$3,
    ),
  );
}

IconData _sourceIconForTone(RuntimeLocalMessageSourceTone tone) {
  switch (tone) {
    case RuntimeLocalMessageSourceTone.demo:
      return Icons.visibility_outlined;
    case RuntimeLocalMessageSourceTone.fresh:
      return Icons.sms_rounded;
    case RuntimeLocalMessageSourceTone.restored:
      return Icons.history_rounded;
    case RuntimeLocalMessageSourceTone.caution:
      return Icons.lock_outline_rounded;
    case RuntimeLocalMessageSourceTone.unavailable:
      return Icons.portable_wifi_off_rounded;
  }
}

String _summarizeFindingTitles(
  Iterable<String> titles, {
  required String singularLabel,
  required String pluralLabel,
}) {
  final normalizedTitles = titles
      .map((title) => title.trim())
      .where((title) => title.isNotEmpty)
      .toList(growable: false);

  if (normalizedTitles.isEmpty) {
    return '';
  }

  if (normalizedTitles.length == 1) {
    return '${normalizedTitles.first} ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· 1 $singularLabel.';
  }

  if (normalizedTitles.length == 2) {
    return '${normalizedTitles.first} and ${normalizedTitles.last} ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· 2 $pluralLabel.';
  }

  return '${normalizedTitles.first}, ${normalizedTitles[1]}, and ${normalizedTitles.length - 2} more ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· ${normalizedTitles.length} $pluralLabel.';
}

String _previewCountLabel(int count) {
  return count == 1 ? '1 item' : '$count items';
}

String _joinPreviewTitles(List<String> titles) {
  if (titles.isEmpty) {
    return 'Sample items';
  }
  if (titles.length == 1) {
    return titles.first;
  }
  return '${titles.first} and ${titles[1]}';
}

String _fallbackAmountLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
      return 'Not found yet';
    case DashboardBucket.needsReview:
      return 'Not visible yet';
    case DashboardBucket.trialsAndBenefits:
      return 'Not a paid charge';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _fallbackRenewalLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
    case DashboardBucket.needsReview:
      return 'Date not clear yet';
    case DashboardBucket.trialsAndBenefits:
      return 'No renewal date';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _fallbackFrequencyLabel(DashboardBucket bucket) {
  switch (bucket) {
    case DashboardBucket.confirmedSubscriptions:
    case DashboardBucket.needsReview:
      return 'Cycle not clear yet';
    case DashboardBucket.trialsAndBenefits:
      return 'Benefit access';
    case DashboardBucket.hidden:
      return 'Not available';
  }
}

String _dueSoonPreviewDescription(
  String serviceTitle,
  String renewalDateLabel,
  String? amountLabel,
) {
  if (amountLabel == null) {
    return '$serviceTitle appears here once the next renewal date is clear on $renewalDateLabel.';
  }
  return '$serviceTitle appears here once the next renewal date is clear on $renewalDateLabel for $amountLabel.';
}

String _demoDueSoonFallback(
  List<DashboardCard> confirmedCards,
  DateTime recordedAt,
) {
  if (confirmedCards.isEmpty) {
    return 'Renewals with clear dates appear here before they are due.';
  }

  final previewCard = confirmedCards.first;
  final previewDate =
      _formatPreviewDate(recordedAt.add(const Duration(days: 5)));
  final amountLabel = _extractVisibleAmountLabel(previewCard.subtitle);
  if (amountLabel == null) {
    return 'Example: ${previewCard.title} would appear here around $previewDate once a renewal date is clear.';
  }
  return 'Example: ${previewCard.title} on $previewDate for $amountLabel once the next renewal date is clear.';
}

String? _extractVisibleAmountLabel(String subtitle) {
  final match = RegExp(
    r'\bRs\s+([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)\b',
    caseSensitive: false,
  ).firstMatch(subtitle);
  if (match == null) {
    return null;
  }
  return 'Rs ${match.group(1)!}';
}

String _formatPreviewDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String _subscriptionRowSemantics(
  DashboardCard card, {
  required _SubscriptionCardMetadata metadata,
  required _BucketStyle style,
  required LocalServicePresentationState servicePresentationState,
}) {
  final visibleTitle = servicePresentationState.displayTitle;
  final parts = <String>[
    visibleTitle,
    style.badgeLabel,
    card.subtitle,
    'Amount ${metadata.amountLabel}',
    'Next renewal ${metadata.renewalLabel}',
    'Frequency ${metadata.frequencyLabel}',
    if (servicePresentationState.isPinned) 'Pinned on this device',
    if (servicePresentationState.hasLocalLabel)
      'Original name ${servicePresentationState.originalTitle}',
  ];
  return '${parts.join('. ')}.';
}

String _manualSubscriptionRowSemantics(ManualSubscriptionEntry entry) {
  final parts = <String>[
    entry.serviceName,
    'Added by you',
    _manualSubscriptionSemanticsSummary(entry),
  ];
  return '${parts.join('. ')}.';
}

String _reviewCardSemantics(
  ReviewItem item, {
  required ReviewQueueItemPresentation presentation,
  required ReviewItemActionDescriptor descriptor,
}) {
  final statusLabel =
      descriptor.canConfirm ? 'Needs your review' : 'Needs a clearer service';
  final parts = <String>[
    item.title,
    statusLabel,
    presentation.explanationDescription,
    presentation.cardRationale,
  ];
  if (presentation.stampLabel.isNotEmpty) {
    parts.add(presentation.stampLabel);
  }
  return '${parts.join('. ')}.';
}

bool _shouldReduceMotion(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  if (mediaQuery == null) {
    return false;
  }
  return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
}

String _manualSubscriptionSubtitle(ManualSubscriptionEntry entry) {
  final parts = <String>[
    entry.billingCycle == ManualSubscriptionBillingCycle.monthly
        ? 'Monthly'
        : 'Yearly',
  ];
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount != null) {
    parts.add(amount);
  }
  if (entry.hasNextRenewalDate) {
    parts.add('Renews ${_formatManualDate(entry.nextRenewalDate!)}');
  }
  if (entry.hasPlanLabel) {
    parts.add(entry.planLabel!);
  }
  return parts.join(' ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ ');
}

String _manualSubscriptionSemanticsSummary(ManualSubscriptionEntry entry) {
  final parts = <String>[
    entry.billingCycle == ManualSubscriptionBillingCycle.monthly
        ? 'Monthly'
        : 'Yearly',
  ];
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount != null) {
    parts.add(amount);
  }
  if (entry.hasNextRenewalDate) {
    parts.add('Renews ${_formatManualDate(entry.nextRenewalDate!)}');
  }
  if (entry.hasPlanLabel) {
    parts.add(entry.planLabel!);
  }
  return parts.join(', ');
}

String _manualSubscriptionBillingSummary(ManualSubscriptionEntry entry) {
  final cycle = entry.billingCycle == ManualSubscriptionBillingCycle.monthly
      ? 'Monthly'
      : 'Yearly';
  final amount = _formatManualSubscriptionAmount(entry.amountInMinorUnits);
  if (amount == null) {
    return cycle;
  }
  return '$cycle ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ $amount';
}

String _manualEntryImprovementCopy(ManualSubscriptionEntry entry) {
  if (!entry.hasAmount && !entry.hasNextRenewalDate) {
    return 'Add an amount if you want this entry included in your estimate, and add a renewal date if you want it to appear in renewals and reminders.';
  }
  if (!entry.hasAmount) {
    return 'Add an amount if you want this entry included in your estimate.';
  }
  return 'Add a renewal date if you want this entry to appear in renewals and reminders.';
}

String? _formatManualSubscriptionAmount(int? amountInMinorUnits) {
  if (amountInMinorUnits == null) {
    return null;
  }

  final wholeUnits = amountInMinorUnits ~/ 100;
  final fractionalUnits = amountInMinorUnits % 100;
  if (fractionalUnits == 0) {
    return 'Rs $wholeUnits';
  }
  final fraction = fractionalUnits.toString().padLeft(2, '0');
  return 'Rs $wholeUnits.$fraction';
}

String _formatManualAmountInput(int amountInMinorUnits) {
  final wholeUnits = amountInMinorUnits ~/ 100;
  final fractionalUnits = amountInMinorUnits % 100;
  if (fractionalUnits == 0) {
    return wholeUnits.toString();
  }
  return '$wholeUnits.${fractionalUnits.toString().padLeft(2, '0')}';
}

String _formatManualDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[value.month - 1];
  return '${value.day} $month ${value.year}';
}

String _monogramForTitle(String title) {
  final parts = title
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'SK';
  }
  if (parts.length == 1) {
    final word = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (word.length >= 2) {
      return word.substring(0, 2).toUpperCase();
    }
    return word.toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
