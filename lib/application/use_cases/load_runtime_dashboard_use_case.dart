import '../contracts/device_sms_gateway.dart';
import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../contracts/local_manual_subscription_store.dart';
import '../contracts/local_message_source_capability_provider.dart';
import '../contracts/local_renewal_reminder_store.dart';
import '../contracts/local_service_presentation_overlay_store.dart';
import '../contracts/review_action_store.dart';
import '../models/manual_subscription_models.dart';
import '../models/local_control_overlay_models.dart';
import '../models/local_message_source_access_state.dart';
import '../models/local_message_source_platform_binding.dart';
import '../models/local_renewal_reminder_models.dart';
import '../models/local_service_presentation_overlay_models.dart';
import '../models/review_item_action_models.dart';
import '../models/runtime_snapshot_provenance.dart';
import '../providers/stub_local_message_source_capability_provider.dart';
import '../repositories/in_memory_ledger_repository.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import '../stores/json_file_local_manual_subscription_store.dart';
import '../stores/json_file_local_renewal_reminder_store.dart';
import '../stores/json_file_local_service_presentation_overlay_store.dart';
import '../stores/json_file_review_action_store.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/projections/deterministic_dashboard_projection.dart';
import 'apply_local_control_overlays_use_case.dart';
import 'apply_local_service_presentation_overlays_use_case.dart';
import 'apply_review_item_actions_use_case.dart';
import 'local_ingestion_flow_use_case.dart';
import 'project_dashboard_use_case.dart';
import 'project_review_queue_use_case.dart';
import 'select_local_message_source_use_case.dart';

enum RuntimeLedgerLoadMode {
  restorePersistedOrRefreshSource,
  refreshFromSource,
}

class RuntimeDashboardSnapshot {
  const RuntimeDashboardSnapshot({
    required this.cards,
    required this.reviewQueue,
    required this.messageSourceSelection,
    required this.provenance,
    required this.confirmedReviewItems,
    required this.benefitReviewItems,
    required this.dismissedReviewItems,
    required this.ignoredLocalItems,
    required this.hiddenLocalItems,
    required this.manualSubscriptions,
    required this.localServicePresentationStates,
    required this.localRenewalReminderPreferences,
  });

  final List<DashboardCard> cards;
  final List<ReviewItem> reviewQueue;
  final LocalMessageSourceSelection messageSourceSelection;
  final RuntimeSnapshotProvenance provenance;
  final List<UserConfirmedReviewItem> confirmedReviewItems;
  final List<UserBenefitReviewItem> benefitReviewItems;
  final List<UserDismissedReviewItem> dismissedReviewItems;
  final List<UserIgnoredLocalItem> ignoredLocalItems;
  final List<UserHiddenLocalItem> hiddenLocalItems;
  final List<ManualSubscriptionEntry> manualSubscriptions;
  final Map<String, LocalServicePresentationState>
      localServicePresentationStates;
  final Map<String, LocalRenewalReminderPreference>
      localRenewalReminderPreferences;
}

class LoadRuntimeDashboardUseCase {
  factory LoadRuntimeDashboardUseCase({
    LocalMessageSourcePlatformBinding? platformBinding,
    LocalMessageSourceCapabilityProvider? capabilityProvider,
    DeviceSmsGateway? deviceSmsGateway,
    DeviceSmsGateway? unavailableDeviceSmsGateway,
    SelectLocalMessageSourceUseCase? selectLocalMessageSourceUseCase,
    InMemoryLedgerRepository? ledgerRepository,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    ProjectDashboardUseCase? projectDashboardUseCase,
    ProjectReviewQueueUseCase? projectReviewQueueUseCase,
    DateTime Function()? clock,
  }) {
    final repository = ledgerRepository ?? InMemoryLedgerRepository();
    const projection = DeterministicDashboardProjection();
    final binding =
        platformBinding ?? LocalMessageSourcePlatformBinding.sampleDemo();

    return LoadRuntimeDashboardUseCase._(
      ledgerRepository: repository,
      ledgerSnapshotStore: ledgerSnapshotStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      loadMode: loadMode,
      clock: clock ?? DateTime.now,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase ??
          (reviewActionStore == null
              ? null
              : ApplyReviewItemActionsUseCase(
                  reviewActionStore: reviewActionStore,
                )),
      applyLocalControlOverlaysUseCase: applyLocalControlOverlaysUseCase ??
          (localControlOverlayStore == null
              ? null
              : ApplyLocalControlOverlaysUseCase(
                  localControlOverlayStore: localControlOverlayStore,
                )),
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase ??
              (localServicePresentationOverlayStore == null
                  ? null
                  : ApplyLocalServicePresentationOverlaysUseCase(
                      localServicePresentationOverlayStore:
                          localServicePresentationOverlayStore,
                    )),
      selectLocalMessageSourceUseCase: selectLocalMessageSourceUseCase ??
          SelectLocalMessageSourceUseCase(
            capabilityProvider:
                capabilityProvider ?? binding.capabilityProvider,
            deviceSmsGateway: deviceSmsGateway ?? binding.deviceSmsGateway,
            unavailableDeviceSmsGateway: unavailableDeviceSmsGateway ??
                binding.unavailableDeviceSmsGateway,
          ),
      ingestionUseCase: ingestionUseCase ??
          LocalIngestionFlowUseCase(ledgerRepository: repository),
      projectDashboardUseCase: projectDashboardUseCase ??
          ProjectDashboardUseCase(
            ledgerRepository: repository,
            dashboardProjection: projection,
          ),
      projectReviewQueueUseCase: projectReviewQueueUseCase ??
          ProjectReviewQueueUseCase(
            ledgerRepository: repository,
            dashboardProjection: projection,
          ),
    );
  }

  factory LoadRuntimeDashboardUseCase.persistent({
    LocalMessageSourcePlatformBinding? platformBinding,
    LocalMessageSourceCapabilityProvider? capabilityProvider,
    DeviceSmsGateway? deviceSmsGateway,
    DeviceSmsGateway? unavailableDeviceSmsGateway,
    SelectLocalMessageSourceUseCase? selectLocalMessageSourceUseCase,
    InMemoryLedgerRepository? ledgerRepository,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    ProjectDashboardUseCase? projectDashboardUseCase,
    ProjectReviewQueueUseCase? projectReviewQueueUseCase,
    DateTime Function()? clock,
  }) {
    return LoadRuntimeDashboardUseCase(
      platformBinding: platformBinding,
      capabilityProvider: capabilityProvider,
      deviceSmsGateway: deviceSmsGateway,
      unavailableDeviceSmsGateway: unavailableDeviceSmsGateway,
      selectLocalMessageSourceUseCase: selectLocalMessageSourceUseCase,
      ledgerRepository: ledgerRepository,
      ledgerSnapshotStore: ledgerSnapshotStore ??
          JsonFileLedgerSnapshotStore.applicationSupport(),
      reviewActionStore:
          reviewActionStore ?? JsonFileReviewActionStore.applicationSupport(),
      localControlOverlayStore: localControlOverlayStore ??
          JsonFileLocalControlOverlayStore.applicationSupport(),
      localManualSubscriptionStore: localManualSubscriptionStore ??
          JsonFileLocalManualSubscriptionStore.applicationSupport(),
      localRenewalReminderStore: localRenewalReminderStore ??
          JsonFileLocalRenewalReminderStore.applicationSupport(),
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore ??
              JsonFileLocalServicePresentationOverlayStore.applicationSupport(),
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalControlOverlaysUseCase: applyLocalControlOverlaysUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      projectDashboardUseCase: projectDashboardUseCase,
      projectReviewQueueUseCase: projectReviewQueueUseCase,
      clock: clock,
    );
  }

  factory LoadRuntimeDashboardUseCase.android({
    LocalMessageSourcePlatformBinding? platformBinding,
    InMemoryLedgerRepository? ledgerRepository,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    ProjectDashboardUseCase? projectDashboardUseCase,
    ProjectReviewQueueUseCase? projectReviewQueueUseCase,
    DateTime Function()? clock,
  }) {
    return LoadRuntimeDashboardUseCase(
      platformBinding:
          platformBinding ?? LocalMessageSourcePlatformBinding.android(),
      ledgerRepository: ledgerRepository,
      ledgerSnapshotStore: ledgerSnapshotStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      projectDashboardUseCase: projectDashboardUseCase,
      projectReviewQueueUseCase: projectReviewQueueUseCase,
      clock: clock,
    );
  }

  factory LoadRuntimeDashboardUseCase.deviceLocalStub({
    DeviceSmsGateway? gateway,
    InMemoryLedgerRepository? ledgerRepository,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    ProjectDashboardUseCase? projectDashboardUseCase,
    ProjectReviewQueueUseCase? projectReviewQueueUseCase,
    DateTime Function()? clock,
  }) {
    return LoadRuntimeDashboardUseCase(
      platformBinding: LocalMessageSourcePlatformBinding.stubDeviceLocal(),
      capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.deviceLocalUnavailable,
      ),
      unavailableDeviceSmsGateway: gateway,
      ledgerRepository: ledgerRepository,
      ledgerSnapshotStore: ledgerSnapshotStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      projectDashboardUseCase: projectDashboardUseCase,
      projectReviewQueueUseCase: projectReviewQueueUseCase,
      clock: clock,
    );
  }

  const LoadRuntimeDashboardUseCase._({
    required InMemoryLedgerRepository ledgerRepository,
    required LedgerSnapshotStore? ledgerSnapshotStore,
    required LocalManualSubscriptionStore? localManualSubscriptionStore,
    required LocalRenewalReminderStore? localRenewalReminderStore,
    required RuntimeLedgerLoadMode loadMode,
    required DateTime Function() clock,
    required ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    required ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    required ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    required SelectLocalMessageSourceUseCase selectLocalMessageSourceUseCase,
    required LocalIngestionFlowUseCase ingestionUseCase,
    required ProjectDashboardUseCase projectDashboardUseCase,
    required ProjectReviewQueueUseCase projectReviewQueueUseCase,
  })  : _ledgerRepository = ledgerRepository,
        _ledgerSnapshotStore = ledgerSnapshotStore,
        _localManualSubscriptionStore = localManualSubscriptionStore,
        _localRenewalReminderStore = localRenewalReminderStore,
        _loadMode = loadMode,
        _clock = clock,
        _applyReviewItemActionsUseCase = applyReviewItemActionsUseCase,
        _applyLocalControlOverlaysUseCase = applyLocalControlOverlaysUseCase,
        _applyLocalServicePresentationOverlaysUseCase =
            applyLocalServicePresentationOverlaysUseCase,
        _selectLocalMessageSourceUseCase = selectLocalMessageSourceUseCase,
        _ingestionUseCase = ingestionUseCase,
        _projectDashboardUseCase = projectDashboardUseCase,
        _projectReviewQueueUseCase = projectReviewQueueUseCase;

  final InMemoryLedgerRepository _ledgerRepository;
  final LedgerSnapshotStore? _ledgerSnapshotStore;
  final LocalManualSubscriptionStore? _localManualSubscriptionStore;
  final LocalRenewalReminderStore? _localRenewalReminderStore;
  final RuntimeLedgerLoadMode _loadMode;
  final DateTime Function() _clock;
  final ApplyReviewItemActionsUseCase? _applyReviewItemActionsUseCase;
  final ApplyLocalControlOverlaysUseCase? _applyLocalControlOverlaysUseCase;
  final ApplyLocalServicePresentationOverlaysUseCase?
      _applyLocalServicePresentationOverlaysUseCase;
  final SelectLocalMessageSourceUseCase _selectLocalMessageSourceUseCase;
  final LocalIngestionFlowUseCase _ingestionUseCase;
  final ProjectDashboardUseCase _projectDashboardUseCase;
  final ProjectReviewQueueUseCase _projectReviewQueueUseCase;

  Future<RuntimeDashboardSnapshot> execute() async {
    final messageSourceSelection =
        await _selectLocalMessageSourceUseCase.execute();
    final snapshotStore = _ledgerSnapshotStore;
    final now = _clock();
    final persistedRecord =
        snapshotStore == null ? null : await snapshotStore.loadRecord();

    if (_loadMode == RuntimeLedgerLoadMode.restorePersistedOrRefreshSource &&
        persistedRecord != null) {
      return _restorePersistedSnapshot(
        messageSourceSelection,
        persistedRecord: persistedRecord,
        recordedAt: now,
      );
    }

    if (_loadMode == RuntimeLedgerLoadMode.refreshFromSource &&
        messageSourceSelection.resolution ==
            LocalMessageSourceResolution.deviceLocalStub &&
        persistedRecord != null) {
      return _restorePersistedSnapshot(
        messageSourceSelection,
        persistedRecord: persistedRecord,
        recordedAt: now,
      );
    }

    await _ledgerRepository.replaceAll(const <ServiceLedgerEntry>[]);
    final messages = await messageSourceSelection.messageSource.loadMessages();
    final ingestionResult = await _ingestionUseCase.execute(messages);
    await snapshotStore?.saveRecord(
      LedgerSnapshotRecord(
        entries: ingestionResult.ledgerEntries,
        metadata: LedgerSnapshotMetadata(
          sourceKind: _sourceKindForSelection(messageSourceSelection),
          refreshedAt: now,
        ),
      ),
    );

    return _projectSnapshot(
      messageSourceSelection,
      provenance: RuntimeSnapshotProvenance(
        kind: RuntimeSnapshotProvenanceKind.freshLoad,
        sourceKind: _sourceKindForSelection(messageSourceSelection),
        recordedAt: now,
        refreshedAt: now,
      ),
    );
  }

  Future<RuntimeDashboardSnapshot> _restorePersistedSnapshot(
    LocalMessageSourceSelection messageSourceSelection, {
    required LedgerSnapshotRecord persistedRecord,
    required DateTime recordedAt,
  }) async {
    await _ledgerRepository.replaceAll(persistedRecord.entries);

    return _projectSnapshot(
      messageSourceSelection,
      provenance: RuntimeSnapshotProvenance(
        kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        sourceKind: persistedRecord.metadata?.sourceKind ??
            RuntimeSnapshotSourceKind.unknown,
        recordedAt: recordedAt,
        refreshedAt: persistedRecord.metadata?.refreshedAt,
      ),
    );
  }

  Future<RuntimeDashboardSnapshot> _projectSnapshot(
    LocalMessageSourceSelection messageSourceSelection, {
    required RuntimeSnapshotProvenance provenance,
  }) async {
    final dashboard = await _projectDashboardUseCase.execute();
    final reviewQueue = await _projectReviewQueueUseCase.execute();
    final appliedReviewActions = _applyReviewItemActionsUseCase == null
        ? AppliedReviewActionsResult(
            cards: dashboard.cards,
            reviewQueue: reviewQueue,
            confirmedReviewItems: const <UserConfirmedReviewItem>[],
            benefitReviewItems: const <UserBenefitReviewItem>[],
            dismissedReviewItems: const <UserDismissedReviewItem>[],
          )
        : await _applyReviewItemActionsUseCase!.execute(
            cards: dashboard.cards,
            reviewQueue: reviewQueue,
          );
    final appliedLocalControls = _applyLocalControlOverlaysUseCase == null
        ? AppliedLocalControlOverlaysResult(
            cards: appliedReviewActions.cards,
            reviewQueue: appliedReviewActions.reviewQueue,
            ignoredItems: const <UserIgnoredLocalItem>[],
            hiddenItems: const <UserHiddenLocalItem>[],
            confirmedReviewItems: appliedReviewActions.confirmedReviewItems,
            benefitReviewItems: appliedReviewActions.benefitReviewItems,
            dismissedReviewItems: appliedReviewActions.dismissedReviewItems,
          )
        : await _applyLocalControlOverlaysUseCase!.execute(
            cards: appliedReviewActions.cards,
            reviewQueue: appliedReviewActions.reviewQueue,
            confirmedReviewItems: appliedReviewActions.confirmedReviewItems,
            benefitReviewItems: appliedReviewActions.benefitReviewItems,
            dismissedReviewItems: appliedReviewActions.dismissedReviewItems,
          );
    final appliedLocalServicePresentation =
        _applyLocalServicePresentationOverlaysUseCase == null
            ? AppliedLocalServicePresentationOverlaysResult(
                cards: appliedLocalControls.cards,
                servicePresentationStates:
                    Map<String, LocalServicePresentationState>.unmodifiable(
                  {
                    for (final card in appliedLocalControls.cards)
                      card.serviceKey.value:
                          LocalServicePresentationState.fromDashboardCard(card),
                  },
                ),
              )
            : await _applyLocalServicePresentationOverlaysUseCase!.execute(
                cards: appliedLocalControls.cards,
              );

    return RuntimeDashboardSnapshot(
      cards: appliedLocalServicePresentation.cards,
      reviewQueue: appliedLocalControls.reviewQueue,
      messageSourceSelection: messageSourceSelection,
      provenance: provenance,
      confirmedReviewItems: appliedLocalControls.confirmedReviewItems,
      benefitReviewItems: appliedLocalControls.benefitReviewItems,
      dismissedReviewItems: appliedLocalControls.dismissedReviewItems,
      ignoredLocalItems: appliedLocalControls.ignoredItems,
      hiddenLocalItems: appliedLocalControls.hiddenItems,
      manualSubscriptions: await _loadManualSubscriptions(),
      localServicePresentationStates:
          appliedLocalServicePresentation.servicePresentationStates,
      localRenewalReminderPreferences:
          await _loadLocalRenewalReminderPreferences(),
    );
  }

  Future<List<ManualSubscriptionEntry>> _loadManualSubscriptions() async {
    if (_localManualSubscriptionStore == null) {
      return const <ManualSubscriptionEntry>[];
    }

    final entries = await _localManualSubscriptionStore!.list();
    return List<ManualSubscriptionEntry>.unmodifiable(entries);
  }

  Future<Map<String, LocalRenewalReminderPreference>>
      _loadLocalRenewalReminderPreferences() async {
    if (_localRenewalReminderStore == null) {
      return const <String, LocalRenewalReminderPreference>{};
    }

    final preferences = await _localRenewalReminderStore!.list();
    return Map<String, LocalRenewalReminderPreference>.unmodifiable(
      {
        for (final preference in preferences) preference.serviceKey: preference,
      },
    );
  }

  RuntimeSnapshotSourceKind _sourceKindForSelection(
    LocalMessageSourceSelection selection,
  ) {
    switch (selection.resolution) {
      case LocalMessageSourceResolution.sampleLocal:
        return RuntimeSnapshotSourceKind.sampleDemo;
      case LocalMessageSourceResolution.deviceLocal:
        return RuntimeSnapshotSourceKind.deviceSms;
      case LocalMessageSourceResolution.deviceLocalStub:
        return RuntimeSnapshotSourceKind.safeLocalFallback;
    }
  }
}
