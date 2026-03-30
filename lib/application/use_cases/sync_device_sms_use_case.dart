import 'package:flutter/foundation.dart';
import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_control_overlay_store.dart';
import '../contracts/local_renewal_reminder_store.dart';
import '../contracts/local_service_presentation_overlay_store.dart';
import '../contracts/review_action_store.dart';
import '../contracts/service_evidence_bucket_store.dart';
import '../models/local_message_source_access_state.dart';
import '../models/local_message_source_platform_binding.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_control_overlay_store.dart';
import '../stores/json_file_local_renewal_reminder_store.dart';
import '../stores/json_file_local_service_presentation_overlay_store.dart';
import '../stores/json_file_review_action_store.dart';
import '../stores/json_file_service_evidence_bucket_store.dart';
import 'load_runtime_dashboard_use_case.dart';
import 'request_device_sms_access_use_case.dart';

class SyncDeviceSmsResult {
  const SyncDeviceSmsResult({
    required this.requestResult,
    required this.snapshot,
  });

  final LocalMessageSourceAccessRequestResult requestResult;
  final RuntimeDashboardSnapshot snapshot;
}

class SyncDeviceSmsUseCase {
  factory SyncDeviceSmsUseCase.android({
    LocalMessageSourcePlatformBinding? platformBinding,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
  }) {
    final binding =
        platformBinding ?? LocalMessageSourcePlatformBinding.android();

    return SyncDeviceSmsUseCase(
      requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
        capabilityProvider: binding.capabilityProvider,
      ),
      loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
        platformBinding: binding,
        ledgerSnapshotStore: ledgerSnapshotStore,
        reviewActionStore: reviewActionStore,
        localControlOverlayStore: localControlOverlayStore,
        localRenewalReminderStore: localRenewalReminderStore,
        localServicePresentationOverlayStore:
            localServicePresentationOverlayStore,
        serviceEvidenceBucketStore: serviceEvidenceBucketStore,
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
      ).execute(),
    );
  }

  factory SyncDeviceSmsUseCase.persistentAndroid({
    LocalMessageSourcePlatformBinding? platformBinding,
    LedgerSnapshotStore? ledgerSnapshotStore,
    ReviewActionStore? reviewActionStore,
    LocalControlOverlayStore? localControlOverlayStore,
    LocalRenewalReminderStore? localRenewalReminderStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    ServiceEvidenceBucketStore? serviceEvidenceBucketStore,
  }) {
    return SyncDeviceSmsUseCase.android(
      platformBinding: platformBinding,
      ledgerSnapshotStore: ledgerSnapshotStore ??
          JsonFileLedgerSnapshotStore.applicationSupport(),
      reviewActionStore:
          reviewActionStore ?? JsonFileReviewActionStore.applicationSupport(),
      localControlOverlayStore: localControlOverlayStore ??
          JsonFileLocalControlOverlayStore.applicationSupport(),
      localRenewalReminderStore: localRenewalReminderStore ??
          JsonFileLocalRenewalReminderStore.applicationSupport(),
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore ??
              JsonFileLocalServicePresentationOverlayStore.applicationSupport(),
      serviceEvidenceBucketStore: serviceEvidenceBucketStore ??
          JsonFileServiceEvidenceBucketStore.applicationSupport(),
    );
  }

  SyncDeviceSmsUseCase({
    required RequestDeviceSmsAccessUseCase requestDeviceSmsAccessUseCase,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
  })  : _requestDeviceSmsAccessUseCase = requestDeviceSmsAccessUseCase,
        _loadRuntimeDashboard = loadRuntimeDashboard;

  final RequestDeviceSmsAccessUseCase _requestDeviceSmsAccessUseCase;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;

  Future<SyncDeviceSmsResult> execute() async {
    debugPrint('SyncDeviceSmsUseCase: execute starting...');
    final accessResult = await _requestDeviceSmsAccessUseCase.execute();
    debugPrint(
        'SyncDeviceSmsUseCase: accessResult=${accessResult.requestResult}');

    debugPrint('SyncDeviceSmsUseCase: loading runtime dashboard...');
    final snapshot = await _loadRuntimeDashboard();
    debugPrint('SyncDeviceSmsUseCase: execute success');

    return SyncDeviceSmsResult(
      requestResult: accessResult.requestResult,
      snapshot: snapshot,
    );
  }
}
