import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import '../contracts/device_sms_gateway.dart';
import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../contracts/local_manual_subscription_store.dart';
import '../contracts/local_message_source_capability_provider.dart';
import '../contracts/local_renewal_reminder_store.dart';
import '../contracts/local_service_presentation_overlay_store.dart';
import '../contracts/review_action_store.dart';
import '../contracts/service_evidence_bucket_store.dart';
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
import '../repositories/in_memory_service_evidence_bucket_repository.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import '../stores/json_file_local_manual_subscription_store.dart';
import '../stores/json_file_local_renewal_reminder_store.dart';
import '../stores/json_file_local_service_presentation_overlay_store.dart';
import '../stores/json_file_review_action_store.dart';
import '../stores/json_file_service_evidence_bucket_store.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/projections/deterministic_dashboard_projection.dart';
import '../../v2/detection/contracts/canonical_input_source.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/models/shadow_decision_comparison.dart';
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
    this.shadowComparison,
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
  final ShadowDecisionComparison? shadowComparison;
}

class LoadRuntimeDashboardUseCase {
  static LocalMessageSourcePlatformBinding _defaultPlatformBinding() {
    final isFlutterTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isFlutterTest) {
      return LocalMessageSourcePlatformBinding.sampleDemo();
    }

    if (!kIsWeb && Platform.isAndroid) {
      return LocalMessageSourcePlatformBinding.android();
    }

    return LocalMessageSourcePlatformBinding.sampleDemo();
  }

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
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
    ProjectDashboardUseCase? projectDashboardUseCase,
    ProjectReviewQueueUseCase? projectReviewQueueUseCase,
    DateTime Function()? clock,
  }) {
    final repository = ledgerRepository ?? InMemoryLedgerRepository();
    final evidenceBucketRepository = InMemoryServiceEvidenceBucketRepository();
    const projection = DeterministicDashboardProjection();
    final binding = platformBinding ?? _defaultPlatformBinding();

    return LoadRuntimeDashboardUseCase._(
      ledgerRepository: repository,
      ledgerSnapshotStore: ledgerSnapshotStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      serviceEvidenceBucketStore: serviceEvidenceBucketStore,
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
          LocalIngestionFlowUseCase(
            ledgerRepository: repository,
            serviceEvidenceBucketRepository: evidenceBucketRepository,
            decisionExecutionMode: decisionExecutionMode,
          ),
      serviceEvidenceBucketRepository: evidenceBucketRepository,
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
      decisionExecutionMode: decisionExecutionMode,
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
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
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
      serviceEvidenceBucketStore: serviceEvidenceBucketStore ??
          JsonFileServiceEvidenceBucketStore.applicationSupport(),
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalControlOverlaysUseCase: applyLocalControlOverlaysUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      decisionExecutionMode: decisionExecutionMode,
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
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
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
      serviceEvidenceBucketStore: serviceEvidenceBucketStore,
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      decisionExecutionMode: decisionExecutionMode,
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
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
    RuntimeLedgerLoadMode loadMode =
        RuntimeLedgerLoadMode.restorePersistedOrRefreshSource,
    ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    LocalIngestionFlowUseCase? ingestionUseCase,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
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
      serviceEvidenceBucketStore: serviceEvidenceBucketStore,
      loadMode: loadMode,
      applyReviewItemActionsUseCase: applyReviewItemActionsUseCase,
      applyLocalServicePresentationOverlaysUseCase:
          applyLocalServicePresentationOverlaysUseCase,
      ingestionUseCase: ingestionUseCase,
      decisionExecutionMode: decisionExecutionMode,
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
    required ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
    required RuntimeLedgerLoadMode loadMode,
    required DateTime Function() clock,
    required ApplyReviewItemActionsUseCase? applyReviewItemActionsUseCase,
    required ApplyLocalControlOverlaysUseCase? applyLocalControlOverlaysUseCase,
    required ApplyLocalServicePresentationOverlaysUseCase?
        applyLocalServicePresentationOverlaysUseCase,
    required SelectLocalMessageSourceUseCase selectLocalMessageSourceUseCase,
    required LocalIngestionFlowUseCase ingestionUseCase,
    required ServiceEvidenceBucketRepository serviceEvidenceBucketRepository,
    required ProjectDashboardUseCase projectDashboardUseCase,
    required ProjectReviewQueueUseCase projectReviewQueueUseCase,
    required DecisionExecutionMode decisionExecutionMode,
  })  : _ledgerRepository = ledgerRepository,
        _ledgerSnapshotStore = ledgerSnapshotStore,
        _localManualSubscriptionStore = localManualSubscriptionStore,
        _localRenewalReminderStore = localRenewalReminderStore,
        _serviceEvidenceBucketStore = serviceEvidenceBucketStore,
        _loadMode = loadMode,
        _clock = clock,
        _applyReviewItemActionsUseCase = applyReviewItemActionsUseCase,
        _applyLocalControlOverlaysUseCase = applyLocalControlOverlaysUseCase,
        _applyLocalServicePresentationOverlaysUseCase =
            applyLocalServicePresentationOverlaysUseCase,
        _selectLocalMessageSourceUseCase = selectLocalMessageSourceUseCase,
        _ingestionUseCase = ingestionUseCase,
        _serviceEvidenceBucketRepository = serviceEvidenceBucketRepository,
        _projectDashboardUseCase = projectDashboardUseCase,
        _projectReviewQueueUseCase = projectReviewQueueUseCase,
        _decisionExecutionMode = decisionExecutionMode;

  final InMemoryLedgerRepository _ledgerRepository;
  final LedgerSnapshotStore? _ledgerSnapshotStore;
  final LocalManualSubscriptionStore? _localManualSubscriptionStore;
  final LocalRenewalReminderStore? _localRenewalReminderStore;
  final ServiceEvidenceBucketStore? _serviceEvidenceBucketStore;
  final RuntimeLedgerLoadMode _loadMode;
  final DateTime Function() _clock;
  final ApplyReviewItemActionsUseCase? _applyReviewItemActionsUseCase;
  final ApplyLocalControlOverlaysUseCase? _applyLocalControlOverlaysUseCase;
  final ApplyLocalServicePresentationOverlaysUseCase?
      _applyLocalServicePresentationOverlaysUseCase;
  final SelectLocalMessageSourceUseCase _selectLocalMessageSourceUseCase;
  final LocalIngestionFlowUseCase _ingestionUseCase;
  final ServiceEvidenceBucketRepository _serviceEvidenceBucketRepository;
  final ProjectDashboardUseCase _projectDashboardUseCase;
  final ProjectReviewQueueUseCase _projectReviewQueueUseCase;
  final DecisionExecutionMode _decisionExecutionMode;

  Future<RuntimeDashboardSnapshot> execute() async {
    final messageSourceSelection =
        await _selectLocalMessageSourceUseCase.execute();
    final snapshotStore = _ledgerSnapshotStore;
    final now = _clock();
    final persistedRecord =
        snapshotStore == null ? null : await snapshotStore.loadRecord();

    if (_loadMode == RuntimeLedgerLoadMode.restorePersistedOrRefreshSource &&
        persistedRecord != null) {
      await _restorePersistedEvidenceBuckets();
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
      await _restorePersistedEvidenceBuckets();
      return _restorePersistedSnapshot(
        messageSourceSelection,
        persistedRecord: persistedRecord,
        recordedAt: now,
      );
    }

    try {
      await _ledgerRepository.replaceAll(const <ServiceLedgerEntry>[]);
      await _serviceEvidenceBucketRepository.clear();
      final messageSource = messageSourceSelection.messageSource;
      final ({
        List<SubscriptionEvent> events,
        List<ServiceLedgerEntry> ledgerEntries
      }) ingestionResult;
      if (messageSource is CanonicalInputSource) {
        ingestionResult = await _executeCanonicalIngestion(
          messageSource as CanonicalInputSource,
        );
      } else {
        ingestionResult = await _ingestionUseCase.execute(
          await messageSource.loadMessages(),
        );
      }
      await _persistEvidenceBuckets();
      await snapshotStore?.saveRecord(
        LedgerSnapshotRecord(
          entries: ingestionResult.ledgerEntries,
          metadata: LedgerSnapshotMetadata(
            sourceKind: _sourceKindForSelection(messageSourceSelection),
            refreshedAt: now,
            decisionExecutionMode: _decisionExecutionMode,
            shadowDifferenceCount:
                _ingestionUseCase.lastShadowComparison?.driftCount,
            shadowComparedAt:
                _ingestionUseCase.lastShadowComparison?.comparedAt,
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
          decisionExecutionMode: _decisionExecutionMode,
          shadowDifferenceCount:
              _ingestionUseCase.lastShadowComparison?.driftCount,
          shadowComparedAt: _ingestionUseCase.lastShadowComparison?.comparedAt,
        ),
      );
    } catch (_) {
      if (persistedRecord != null) {
        await _restorePersistedEvidenceBuckets();
        return _restorePersistedSnapshot(
          messageSourceSelection,
          persistedRecord: persistedRecord,
          recordedAt: now,
        );
      }
      rethrow;
    }
  }

  Future<RuntimeDashboardSnapshot> _restorePersistedSnapshot(
    LocalMessageSourceSelection messageSourceSelection, {
    required LedgerSnapshotRecord persistedRecord,
    required DateTime recordedAt,
  }) async {
    final sanitizedEntries = _sanitizePersistedEntries(persistedRecord.entries);
    await _ledgerRepository.replaceAll(sanitizedEntries);
    final metadata = _sanitizePersistedMetadata(persistedRecord.metadata);

    return _projectSnapshot(
      messageSourceSelection,
      provenance: RuntimeSnapshotProvenance(
        kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        sourceKind: metadata?.sourceKind ?? RuntimeSnapshotSourceKind.unknown,
        recordedAt: recordedAt,
        refreshedAt: metadata?.refreshedAt,
        decisionExecutionMode: metadata?.decisionExecutionMode,
        shadowDifferenceCount: metadata?.shadowDifferenceCount,
        shadowComparedAt: metadata?.shadowComparedAt,
      ),
    );
  }

  List<ServiceLedgerEntry> _sanitizePersistedEntries(
    List<ServiceLedgerEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const <ServiceLedgerEntry>[];
    }

    final dedupedByServiceKey = <String, ServiceLedgerEntry>{};
    for (final entry in entries) {
      dedupedByServiceKey[entry.serviceKey.value] = entry;
    }

    final sanitized = dedupedByServiceKey.values.toList(growable: false)
      ..sort(
        (left, right) =>
            left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    return List<ServiceLedgerEntry>.unmodifiable(sanitized);
  }

  LedgerSnapshotMetadata? _sanitizePersistedMetadata(
    LedgerSnapshotMetadata? metadata,
  ) {
    if (metadata == null) {
      return null;
    }

    final decisionMode =
        metadata.decisionExecutionMode ?? _decisionExecutionMode;
    final allowShadowMetadata =
        decisionMode == DecisionExecutionMode.shadowCompareAndBridge;

    return LedgerSnapshotMetadata(
      sourceKind: metadata.sourceKind,
      refreshedAt: metadata.refreshedAt,
      schemaVersion: metadata.schemaVersion,
      decisionExecutionMode: decisionMode,
      shadowDifferenceCount:
          allowShadowMetadata ? metadata.shadowDifferenceCount : null,
      shadowComparedAt: allowShadowMetadata ? metadata.shadowComparedAt : null,
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
      shadowComparison: _ingestionUseCase.lastShadowComparison,
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

  Future<void> _restorePersistedEvidenceBuckets() async {
    final store = _serviceEvidenceBucketStore;
    if (store == null) {
      await _serviceEvidenceBucketRepository.clear();
      return;
    }

    final persistedBuckets = await store.load();
    await _serviceEvidenceBucketRepository.replaceAll(persistedBuckets);
  }

  Future<void> _persistEvidenceBuckets() async {
    final store = _serviceEvidenceBucketStore;
    if (store == null) {
      return;
    }

    final buckets = await _serviceEvidenceBucketRepository.list()
      ..sort((left, right) =>
          left.serviceKey.value.compareTo(right.serviceKey.value));
    await store.save(buckets);
  }

  Future<
      ({
        List<SubscriptionEvent> events,
        List<ServiceLedgerEntry> ledgerEntries
      })> _executeCanonicalIngestion(
    CanonicalInputSource messageSource,
  ) async {
    final canonicalInputs = await messageSource.loadCanonicalInputs();
    return _ingestionUseCase.executeCanonicalInputs(canonicalInputs);
  }
}
