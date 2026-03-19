import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_service_presentation_overlay_store.dart';
import '../models/local_service_presentation_overlay_models.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_service_presentation_overlay_store.dart';
import '../../domain/entities/dashboard_card.dart';
import 'load_runtime_dashboard_use_case.dart';

class HandleLocalServicePresentationResult {
  const HandleLocalServicePresentationResult({
    required this.changed,
    this.snapshot,
  });

  final bool changed;
  final RuntimeDashboardSnapshot? snapshot;
}

class HandleLocalServicePresentationUseCase {
  factory HandleLocalServicePresentationUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    LocalServicePresentationOverlayStore? localServicePresentationOverlayStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
    DateTime Function()? clock,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedOverlayStore = localServicePresentationOverlayStore ??
        JsonFileLocalServicePresentationOverlayStore.applicationSupport();

    return HandleLocalServicePresentationUseCase(
      localServicePresentationOverlayStore: resolvedOverlayStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                localServicePresentationOverlayStore: resolvedOverlayStore,
              ).execute(),
      clock: clock,
    );
  }

  HandleLocalServicePresentationUseCase({
    required LocalServicePresentationOverlayStore localServicePresentationOverlayStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
    DateTime Function()? clock,
  })  : _localServicePresentationOverlayStore =
            localServicePresentationOverlayStore,
        _loadRuntimeDashboard = loadRuntimeDashboard,
        _clock = clock ?? DateTime.now;

  final LocalServicePresentationOverlayStore _localServicePresentationOverlayStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;
  final DateTime Function() _clock;

  Future<HandleLocalServicePresentationResult> saveLocalLabel({
    required DashboardCard card,
    required String label,
  }) async {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      return const HandleLocalServicePresentationResult(changed: false);
    }

    final existing = await _existingOverlay(card.serviceKey.value);
    final nextOverlay = (existing ??
            LocalServicePresentationOverlay(serviceKey: card.serviceKey.value))
        .copyWith(localLabel: normalizedLabel);
    await _persistOverlay(nextOverlay);
    return HandleLocalServicePresentationResult(
      changed: true,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalServicePresentationResult> resetLocalLabel({
    required String serviceKey,
  }) async {
    final existing = await _existingOverlay(serviceKey);
    if (existing == null || !existing.hasLocalLabel) {
      return const HandleLocalServicePresentationResult(changed: false);
    }

    final nextOverlay = existing.copyWith(localLabel: null);
    await _persistOverlay(nextOverlay);
    return HandleLocalServicePresentationResult(
      changed: true,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalServicePresentationResult> pinService(
    DashboardCard card,
  ) async {
    final existing = await _existingOverlay(card.serviceKey.value);
    if (existing?.isPinned == true) {
      return const HandleLocalServicePresentationResult(changed: false);
    }

    final nextOverlay = (existing ??
            LocalServicePresentationOverlay(serviceKey: card.serviceKey.value))
        .copyWith(pinnedAt: _clock());
    await _persistOverlay(nextOverlay);
    return HandleLocalServicePresentationResult(
      changed: true,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleLocalServicePresentationResult> unpinService({
    required String serviceKey,
  }) async {
    final existing = await _existingOverlay(serviceKey);
    if (existing == null || !existing.isPinned) {
      return const HandleLocalServicePresentationResult(changed: false);
    }

    final nextOverlay = existing.copyWith(pinnedAt: null);
    await _persistOverlay(nextOverlay);
    return HandleLocalServicePresentationResult(
      changed: true,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<LocalServicePresentationOverlay?> _existingOverlay(
    String serviceKey,
  ) async {
    final overlays = await _localServicePresentationOverlayStore.list();
    for (final overlay in overlays) {
      if (overlay.serviceKey == serviceKey) {
        return overlay;
      }
    }
    return null;
  }

  Future<void> _persistOverlay(LocalServicePresentationOverlay overlay) async {
    if (overlay.isEmpty) {
      await _localServicePresentationOverlayStore.remove(overlay.serviceKey);
      return;
    }

    await _localServicePresentationOverlayStore.save(overlay);
  }
}
