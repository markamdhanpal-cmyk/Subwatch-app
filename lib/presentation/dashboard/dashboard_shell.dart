// ignore_for_file: invalid_use_of_protected_member, unused_element, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/contracts/problem_report_launcher.dart';
import '../../application/gateways/android_problem_report_launcher.dart';
import '../../application/models/contextual_explanation_presentation.dart';
import '../../application/models/dashboard_completion_presentation.dart';
import '../../application/models/dashboard_due_soon_presentation.dart';
import '../../application/models/dashboard_renewal_reminder_presentation.dart';
import '../../application/models/dashboard_service_view_models.dart';
import '../../application/models/dashboard_totals_summary_presentation.dart';
import '../../application/models/dashboard_upcoming_renewals_presentation.dart';
import '../../application/models/local_control_overlay_models.dart';
import '../../application/models/local_message_source_access_state.dart';
import '../../application/models/local_renewal_reminder_models.dart';
import '../../application/models/local_service_presentation_overlay_models.dart';
import '../../application/models/manual_subscription_models.dart';
import '../../application/models/review_item_action_models.dart';
import '../../application/models/review_queue_item_presentation.dart';
import '../../application/models/runtime_local_message_source_status.dart';
import '../../application/models/runtime_snapshot_provenance.dart';
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
import 'components/dashboard_section_components.dart';
import 'components/dashboard_settings_components.dart';
import 'components/dashboard_sheet_components.dart';
import 'components/lazy_indexed_stack.dart';
import 'dashboard_primitives.dart';
import 'dashboard_shell_providers.dart';
import 'popular_service_catalog.dart';
import 'service_icon_registry.dart';

part 'dashboard_shell_members.dart';
part 'dashboard_shell_shared.dart';
part 'screens/home_screen.dart';
part 'screens/review_screen.dart';
part 'screens/settings_screen.dart';
part 'screens/subscriptions_screen.dart';

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
    ProblemReportLauncher? problemReportLauncher,
    ClearAllLocalDataUseCase? clearAllLocalDataUseCase,
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
        _problemReportLauncher = problemReportLauncher,
        _clearAllLocalDataUseCase = clearAllLocalDataUseCase,
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
  final ProblemReportLauncher? _problemReportLauncher;
  final ClearAllLocalDataUseCase? _clearAllLocalDataUseCase;
  final LoadSmsOnboardingProgressUseCase? _loadSmsOnboardingProgressUseCase;
  final CompleteSmsOnboardingUseCase? _completeSmsOnboardingUseCase;

  @override
  State<DashboardShell> createState() => _DashboardShellScopeState();
}

class _DashboardShellScopeState extends State<DashboardShell> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        dashboardRuntimeUseCaseProvider.overrideWithValue(
          widget._runtimeUseCase ?? LoadRuntimeDashboardUseCase.persistent(),
        ),
        dashboardSyncUseCaseProvider.overrideWithValue(
          widget._syncDeviceSmsUseCase ??
              SyncDeviceSmsUseCase.persistentAndroid(),
        ),
        dashboardHandleReviewActionUseCaseProvider.overrideWithValue(
          widget._handleReviewItemActionUseCase ??
              HandleReviewItemActionUseCase.persistent(),
        ),
        dashboardUndoReviewActionUseCaseProvider.overrideWithValue(
          widget._undoReviewItemActionUseCase ??
              UndoReviewItemActionUseCase.persistent(),
        ),
        dashboardHandleLocalControlUseCaseProvider.overrideWithValue(
          widget._handleLocalControlOverlayUseCase ??
              HandleLocalControlOverlayUseCase.persistent(),
        ),
        dashboardUndoLocalControlUseCaseProvider.overrideWithValue(
          widget._undoLocalControlOverlayUseCase ??
              UndoLocalControlOverlayUseCase.persistent(),
        ),
        dashboardHandleLocalRenewalReminderUseCaseProvider.overrideWithValue(
          widget._handleLocalRenewalReminderUseCase ??
              HandleLocalRenewalReminderUseCase.persistent(),
        ),
        dashboardHandleManualSubscriptionUseCaseProvider.overrideWithValue(
          widget._handleManualSubscriptionUseCase ??
              HandleManualSubscriptionUseCase.persistent(),
        ),
        dashboardHandleLocalServicePresentationUseCaseProvider
            .overrideWithValue(
          widget._handleLocalServicePresentationUseCase ??
              HandleLocalServicePresentationUseCase.persistent(),
        ),
        dashboardProblemReportLauncherProvider.overrideWithValue(
          widget._problemReportLauncher,
        ),
        dashboardClearAllLocalDataUseCaseProvider.overrideWithValue(
          widget._clearAllLocalDataUseCase ??
              ClearAllLocalDataUseCase.persistent(),
        ),
        dashboardLoadSmsOnboardingProgressUseCaseProvider.overrideWithValue(
          widget._loadSmsOnboardingProgressUseCase ??
              LoadSmsOnboardingProgressUseCase.persistent(),
        ),
        dashboardCompleteSmsOnboardingUseCaseProvider.overrideWithValue(
          widget._completeSmsOnboardingUseCase ??
              CompleteSmsOnboardingUseCase.persistent(),
        ),
      ],
      child: const _DashboardShellView(),
    );
  }
}

class _DashboardShellView extends ConsumerStatefulWidget {
  const _DashboardShellView();

  @override
  ConsumerState<_DashboardShellView> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<_DashboardShellView> {
  static const String _problemReportRecipient = 'support@subwatch.app';
  static const List<DashboardServiceFilterMode> _subscriptionsFilterModes =
      <DashboardServiceFilterMode>[
    DashboardServiceFilterMode.allVisible,
    DashboardServiceFilterMode.confirmedOnly,
    DashboardServiceFilterMode.separateAccessOnly,
  ];
  late final ScrollController _homeScrollController;
  late final TextEditingController _serviceSearchController;
  _DashboardDestination _selectedDestination = _DashboardDestination.home;

  bool _selectedDestinationInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('DashboardShell: initState');
    _homeScrollController = ScrollController();
    _serviceSearchController = TextEditingController()
      ..addListener(_handleServiceSearchChanged);

    ref.read(dashboardFirstRunProvider.notifier).initialize();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _serviceSearchController
      ..removeListener(_handleServiceSearchChanged)
      ..dispose();
    super.dispose();
  }

  DashboardServiceViewControls get _serviceViewControls =>
      ref.read(dashboardLocalControlsProvider).serviceViewControls;

  bool get _isSyncing => ref.read(dashboardSyncStateProvider).isSyncing;

  bool get _isClearingAllData =>
      ref.read(dashboardLocalControlsProvider).isClearingAllData;

  Set<String> get _reviewActionTargetsInFlight =>
      ref.read(dashboardReviewActionsProvider).targetsInFlight;

  Set<String> get _localControlTargetsInFlight =>
      ref.read(dashboardLocalControlsProvider).localControlTargetsInFlight;

  Set<String> get _localRenewalReminderTargetsInFlight => ref
      .read(dashboardLocalControlsProvider)
      .localRenewalReminderTargetsInFlight;

  Set<String> get _manualSubscriptionTargetsInFlight => ref
      .read(dashboardLocalControlsProvider)
      .manualSubscriptionTargetsInFlight;

  Set<String> get _localServicePresentationTargetsInFlight => ref
      .read(dashboardLocalControlsProvider)
      .localServicePresentationTargetsInFlight;

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(dashboardShellLoadStateProvider);
    final firstRunState = ref.watch(dashboardFirstRunProvider);
    final reduceMotion = shouldReduceMotion(context);

    final bool isInFirstRun = firstRunState.isInFirstRun;
    debugPrint(
        'DashboardShell: build loadState.showLoading=${loadState.showLoading} isInFirstRun=$isInFirstRun (phase=${firstRunState.phase})');

    final destinationTitle =
        isInFirstRun ? 'SubWatch' : _destinationTitle(_selectedDestination);
    final destinationSubtitle =
        isInFirstRun ? null : _destinationSubtitle(_selectedDestination);

    Widget body;
    if (loadState.showLoading) {
      body = const _DashboardLoadingState();
    } else if (loadState.hasFatalError) {
      body = _DashboardErrorState(
        onRetry: _reloadSnapshot,
      );
    } else if (isInFirstRun) {
      body = _FirstRunSurface(
        shell: this,
        phase: firstRunState.phase,
        firstScanSnapshot: firstRunState.firstScanSnapshot,
      );
    } else {
      body = _buildDashboardContent(
        loadRecoveryState: loadState.loadRecoveryState,
      );
    }

    // Guard against watching providers that require a snapshot before it's ready.
    final sourceStatus =
        (loadState.showLoading || loadState.hasFatalError || isInFirstRun)
            ? null
            : ref.watch(dashboardSourceStatusProvider);

    final type = Theme.of(context).extension<DashboardTypeScale>();

    return Scaffold(
      appBar: isInFirstRun
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      destinationTitle,
                      style: type?.heading ??
                          Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (destinationSubtitle != null)
                    Text(
                      destinationSubtitle,
                      style: (type?.caption ??
                              Theme.of(context).textTheme.bodySmall)
                          ?.copyWith(
                        color: DashboardShellPalette.mutedInk,
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                if (!isInFirstRun &&
                    _selectedDestination == _DashboardDestination.home &&
                    sourceStatus != null &&
                    sourceStatus.isActionEnabled)
                  IconButton(
                    key: const ValueKey<String>('app-bar-sync-button'),
                    onPressed: () => _handleSyncEntry(sourceStatus),
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: sourceStatus.actionLabel,
                  ),
              ],
            ),
      body: DashboardBackdrop(child: body),
      floatingActionButton: (!isInFirstRun &&
              _selectedDestination == _DashboardDestination.subscriptions)
          ? FloatingActionButton(
              key: const ValueKey<String>('open-manual-subscription-form'),
              onPressed: _showCreateManualSubscriptionForm,
              backgroundColor: DashboardShellPalette.accent,
              foregroundColor: DashboardShellPalette.canvas,
              child: const Icon(Icons.add_rounded),
              tooltip: 'Add subscription',
            )
          : null,
      bottomNavigationBar: isInFirstRun
          ? null
          : NavigationBar(
              key: const ValueKey<String>('top-level-navigation'),
              selectedIndex: _selectedDestination.index,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
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
        return null;
      case _DashboardDestination.settings:
        return null;
    }
  }

  Widget _buildDashboardContent({
    DashboardLoadRecoveryState? loadRecoveryState,
  }) {
    Widget content = LazyIndexedStack(
      index: _selectedDestination.index,
      itemBuilders: <LazyIndexedStackItemBuilder>[
        (_) => _DashboardHomeScreen(shell: this),
        (_) => _DashboardSubscriptionsScreen(shell: this),
        (_) => _DashboardReviewScreen(shell: this),
        (_) => _DashboardSettingsScreen(shell: this),
      ],
    );

    if (loadRecoveryState != null) {
      content = Column(
        children: <Widget>[
          _DashboardLoadRecoveryNotice(
            state: loadRecoveryState,
            onRetry: loadRecoveryState.showRetryAction ? _reloadSnapshot : null,
          ),
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}
