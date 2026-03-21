import '../contracts/ledger_snapshot_store.dart';
import '../contracts/local_manual_subscription_store.dart';
import '../models/manual_subscription_models.dart';
import '../stores/json_file_ledger_snapshot_store.dart';
import '../stores/json_file_local_manual_subscription_store.dart';
import 'load_runtime_dashboard_use_case.dart';

enum HandleManualSubscriptionOutcome {
  created,
  updated,
  deleted,
  invalid,
  notFound,
}

class HandleManualSubscriptionResult {
  const HandleManualSubscriptionResult({
    required this.outcome,
    this.snapshot,
    this.errorMessage,
  });

  final HandleManualSubscriptionOutcome outcome;
  final RuntimeDashboardSnapshot? snapshot;
  final String? errorMessage;
}

class HandleManualSubscriptionUseCase {
  factory HandleManualSubscriptionUseCase.persistent({
    LedgerSnapshotStore? ledgerSnapshotStore,
    LocalManualSubscriptionStore? localManualSubscriptionStore,
    Future<RuntimeDashboardSnapshot> Function()? loadRuntimeDashboard,
    DateTime Function()? clock,
  }) {
    final resolvedLedgerSnapshotStore =
        ledgerSnapshotStore ?? JsonFileLedgerSnapshotStore.applicationSupport();
    final resolvedManualStore = localManualSubscriptionStore ??
        JsonFileLocalManualSubscriptionStore.applicationSupport();

    return HandleManualSubscriptionUseCase(
      localManualSubscriptionStore: resolvedManualStore,
      loadRuntimeDashboard: loadRuntimeDashboard ??
          () => LoadRuntimeDashboardUseCase.persistent(
                ledgerSnapshotStore: resolvedLedgerSnapshotStore,
                localManualSubscriptionStore: resolvedManualStore,
              ).execute(),
      clock: clock,
    );
  }

  HandleManualSubscriptionUseCase({
    required LocalManualSubscriptionStore localManualSubscriptionStore,
    required Future<RuntimeDashboardSnapshot> Function() loadRuntimeDashboard,
    DateTime Function()? clock,
  })  : _localManualSubscriptionStore = localManualSubscriptionStore,
        _loadRuntimeDashboard = loadRuntimeDashboard,
        _clock = clock ?? DateTime.now;

  final LocalManualSubscriptionStore _localManualSubscriptionStore;
  final Future<RuntimeDashboardSnapshot> Function() _loadRuntimeDashboard;
  final DateTime Function() _clock;

  Future<HandleManualSubscriptionResult> create({
    required String serviceName,
    required ManualSubscriptionBillingCycle billingCycle,
    String amountInput = '',
    DateTime? nextRenewalDate,
    String planLabel = '',
  }) async {
    final normalized = _normalize(
      serviceName: serviceName,
      amountInput: amountInput,
      nextRenewalDate: nextRenewalDate,
      planLabel: planLabel,
    );
    if (normalized.errorMessage != null) {
      return HandleManualSubscriptionResult(
        outcome: HandleManualSubscriptionOutcome.invalid,
        errorMessage: normalized.errorMessage,
      );
    }

    final now = _clock();
    await _localManualSubscriptionStore.save(
      ManualSubscriptionEntry(
        id: 'manual_${now.microsecondsSinceEpoch}',
        serviceName: normalized.serviceName!,
        amountInMinorUnits: normalized.amountInMinorUnits,
        billingCycle: billingCycle,
        nextRenewalDate: normalized.nextRenewalDate,
        planLabel: normalized.planLabel,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return HandleManualSubscriptionResult(
      outcome: HandleManualSubscriptionOutcome.created,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleManualSubscriptionResult> update({
    required String id,
    required String serviceName,
    required ManualSubscriptionBillingCycle billingCycle,
    String amountInput = '',
    DateTime? nextRenewalDate,
    String planLabel = '',
  }) async {
    final existing = await _existingEntry(id);
    if (existing == null) {
      return const HandleManualSubscriptionResult(
        outcome: HandleManualSubscriptionOutcome.notFound,
      );
    }

    final normalized = _normalize(
      serviceName: serviceName,
      amountInput: amountInput,
      nextRenewalDate: nextRenewalDate,
      planLabel: planLabel,
    );
    if (normalized.errorMessage != null) {
      return HandleManualSubscriptionResult(
        outcome: HandleManualSubscriptionOutcome.invalid,
        errorMessage: normalized.errorMessage,
      );
    }

    await _localManualSubscriptionStore.save(
      existing.copyWith(
        serviceName: normalized.serviceName,
        amountInMinorUnits: normalized.amountInMinorUnits,
        clearAmount: normalized.amountInMinorUnits == null,
        billingCycle: billingCycle,
        nextRenewalDate: normalized.nextRenewalDate,
        clearNextRenewalDate: normalized.nextRenewalDate == null,
        planLabel: normalized.planLabel,
        clearPlanLabel: normalized.planLabel == null,
        updatedAt: _clock(),
      ),
    );

    return HandleManualSubscriptionResult(
      outcome: HandleManualSubscriptionOutcome.updated,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<HandleManualSubscriptionResult> delete({
    required String id,
  }) async {
    final removed = await _localManualSubscriptionStore.remove(id);
    if (!removed) {
      return const HandleManualSubscriptionResult(
        outcome: HandleManualSubscriptionOutcome.notFound,
      );
    }

    return HandleManualSubscriptionResult(
      outcome: HandleManualSubscriptionOutcome.deleted,
      snapshot: await _loadRuntimeDashboard(),
    );
  }

  Future<ManualSubscriptionEntry?> _existingEntry(String id) async {
    final entries = await _localManualSubscriptionStore.list();
    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  ({
    String? serviceName,
    int? amountInMinorUnits,
    DateTime? nextRenewalDate,
    String? planLabel,
    String? errorMessage,
  }) _normalize({
    required String serviceName,
    required String amountInput,
    required DateTime? nextRenewalDate,
    required String planLabel,
  }) {
    final normalizedServiceName = serviceName.trim();
    if (normalizedServiceName.isEmpty) {
      return (
        serviceName: null,
        amountInMinorUnits: null,
        nextRenewalDate: nextRenewalDate,
        planLabel: null,
        errorMessage: 'Enter a service name.',
      );
    }

    final normalizedPlanLabel = planLabel.trim().isEmpty ? null : planLabel.trim();
    final normalizedAmountInput = amountInput.trim();
    if (normalizedAmountInput.isEmpty) {
      return (
        serviceName: normalizedServiceName,
        amountInMinorUnits: null,
        nextRenewalDate: nextRenewalDate,
        planLabel: normalizedPlanLabel,
        errorMessage: null,
      );
    }

    final cleanedInput = normalizedAmountInput
        .replaceAll(',', '')
        .replaceAll(RegExp(r'rs\.?', caseSensitive: false), '')
        .replaceAll(RegExp(r'inr', caseSensitive: false), '')
        .trim();
    final amountMatch = RegExp(r'^\d+(\.\d{1,2})?$').firstMatch(cleanedInput);
    if (amountMatch == null) {
      return (
        serviceName: normalizedServiceName,
        amountInMinorUnits: null,
        nextRenewalDate: nextRenewalDate,
        planLabel: normalizedPlanLabel,
        errorMessage: 'Enter a valid amount or leave it blank.',
      );
    }

    final parts = cleanedInput.split('.');
    final wholeUnits = int.parse(parts.first);
    final fraction = parts.length == 2 ? parts.last.padRight(2, '0') : '00';
    final amountInMinorUnits = (wholeUnits * 100) + int.parse(fraction);
    if (amountInMinorUnits <= 0) {
      return (
        serviceName: normalizedServiceName,
        amountInMinorUnits: null,
        nextRenewalDate: nextRenewalDate,
        planLabel: normalizedPlanLabel,
        errorMessage: 'Enter an amount above zero or leave it blank.',
      );
    }

    return (
      serviceName: normalizedServiceName,
      amountInMinorUnits: amountInMinorUnits,
      nextRenewalDate: nextRenewalDate,
      planLabel: normalizedPlanLabel,
      errorMessage: null,
    );
  }
}
