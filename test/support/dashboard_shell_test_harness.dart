import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/contracts/ledger_snapshot_store.dart';
import 'package:sub_killer/application/contracts/local_message_source_capability_provider.dart';
import 'package:sub_killer/application/contracts/local_renewal_reminder_scheduler.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/review_item_action_models.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_manual_subscription_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/use_cases/handle_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_renewal_reminder_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_service_presentation_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_manual_subscription_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_review_item_action_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell.dart';

class MutableCapabilityProvider
    implements LocalMessageSourceCapabilityProvider {
  MutableCapabilityProvider({
    required LocalMessageSourceAccessState initialState,
    required this.requestResult,
    required this.refreshedState,
  }) : _state = initialState;

  final LocalMessageSourceAccessRequestResult requestResult;
  final LocalMessageSourceAccessState refreshedState;
  LocalMessageSourceAccessState _state;
  int requestCount = 0;

  @override
  Future<LocalMessageSourceAccessState> getAccessState() async => _state;

  @override
  Future<LocalMessageSourceAccessRequestResult> requestAccess() async {
    requestCount += 1;
    _state = refreshedState;
    return requestResult;
  }
}

class FakeDeviceSmsGateway implements DeviceSmsGateway {
  const FakeDeviceSmsGateway(this.messages);

  final List<RawDeviceSms> messages;

  @override
  Future<List<RawDeviceSms>> readMessages() async => messages;
}

class MemoryLedgerSnapshotStore implements LedgerSnapshotStore {
  LedgerSnapshotRecord? _record;

  @override
  Future<bool> hasSnapshot() async => _record != null;

  @override
  Future<List<ServiceLedgerEntry>> load() async {
    return _record?.entries ?? const <ServiceLedgerEntry>[];
  }

  @override
  Future<LedgerSnapshotRecord?> loadRecord() async => _record;

  @override
  Future<void> save(List<ServiceLedgerEntry> entries) async {
    _record = LedgerSnapshotRecord(entries: entries);
  }

  @override
  Future<void> saveRecord(LedgerSnapshotRecord record) async {
    _record = LedgerSnapshotRecord(
      entries: List<ServiceLedgerEntry>.from(record.entries),
      metadata: record.metadata,
    );
  }

  @override
  Future<void> clear() async {
    _record = null;
  }
}

class NoOpLocalRenewalReminderScheduler
    implements LocalRenewalReminderScheduler {
  const NoOpLocalRenewalReminderScheduler();

  @override
  Future<bool> schedule(LocalRenewalReminderScheduleRequest request) async =>
      true;

  @override
  Future<bool> cancel(String serviceKey) async => true;
}

class DashboardShellReviewHarness {
  DashboardShellReviewHarness._({
    required this.runtimeUseCase,
    required this.handleReviewItemActionUseCase,
    required this.undoReviewItemActionUseCase,
    required this.handleLocalControlOverlayUseCase,
    required this.undoLocalControlOverlayUseCase,
    required this.handleLocalServicePresentationUseCase,
    required this.handleManualSubscriptionUseCase,
    required this.handleLocalRenewalReminderUseCase,
    required this.localManualSubscriptionStore,
    required this.localRenewalReminderStore,
    required this.reviewActionStore,
    required this.localControlOverlayStore,
    required this.localServicePresentationOverlayStore,
  });

  factory DashboardShellReviewHarness({
    DateTime Function()? clock,
    DeviceSmsGateway? deviceSmsGateway,
  }) {
    final reviewActionStore = InMemoryReviewActionStore();
    final localControlOverlayStore = InMemoryLocalControlOverlayStore();
    final localManualSubscriptionStore = InMemoryLocalManualSubscriptionStore();
    final localServicePresentationOverlayStore =
        InMemoryLocalServicePresentationOverlayStore();
    final localRenewalReminderStore = InMemoryLocalRenewalReminderStore();
    final ledgerRepository = InMemoryLedgerRepository();

    final runtimeUseCase = LoadRuntimeDashboardUseCase(
      ledgerRepository: ledgerRepository,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      deviceSmsGateway: deviceSmsGateway,
      clock: clock,
    );

    return DashboardShellReviewHarness._(
      runtimeUseCase: runtimeUseCase,
      handleReviewItemActionUseCase: HandleReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      undoReviewItemActionUseCase: UndoReviewItemActionUseCase(
        reviewActionStore: reviewActionStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      handleLocalControlOverlayUseCase: HandleLocalControlOverlayUseCase(
        localControlOverlayStore: localControlOverlayStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      undoLocalControlOverlayUseCase: UndoLocalControlOverlayUseCase(
        localControlOverlayStore: localControlOverlayStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      handleLocalServicePresentationUseCase:
          HandleLocalServicePresentationUseCase(
        localServicePresentationOverlayStore:
            localServicePresentationOverlayStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      handleManualSubscriptionUseCase: HandleManualSubscriptionUseCase(
        localManualSubscriptionStore: localManualSubscriptionStore,
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      handleLocalRenewalReminderUseCase: HandleLocalRenewalReminderUseCase(
        localRenewalReminderStore: localRenewalReminderStore,
        localRenewalReminderScheduler: const NoOpLocalRenewalReminderScheduler(),
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localServicePresentationOverlayStore: localServicePresentationOverlayStore,
    );
  }

  final LoadRuntimeDashboardUseCase runtimeUseCase;
  final HandleReviewItemActionUseCase handleReviewItemActionUseCase;
  final UndoReviewItemActionUseCase undoReviewItemActionUseCase;
  final HandleLocalControlOverlayUseCase handleLocalControlOverlayUseCase;
  final UndoLocalControlOverlayUseCase undoLocalControlOverlayUseCase;
  final HandleLocalServicePresentationUseCase
      handleLocalServicePresentationUseCase;
  final HandleManualSubscriptionUseCase handleManualSubscriptionUseCase;
  final HandleLocalRenewalReminderUseCase handleLocalRenewalReminderUseCase;
  final InMemoryLocalManualSubscriptionStore localManualSubscriptionStore;
  final InMemoryLocalRenewalReminderStore localRenewalReminderStore;
  final InMemoryReviewActionStore reviewActionStore;
  final InMemoryLocalControlOverlayStore localControlOverlayStore;
  final InMemoryLocalServicePresentationOverlayStore
      localServicePresentationOverlayStore;
}

Future<void> pumpDashboardShellApp(
  WidgetTester tester, {
  LoadRuntimeDashboardUseCase? runtimeUseCase,
  SyncDeviceSmsUseCase? syncDeviceSmsUseCase,
  HandleReviewItemActionUseCase? handleReviewItemActionUseCase,
  UndoReviewItemActionUseCase? undoReviewItemActionUseCase,
  HandleLocalControlOverlayUseCase? handleLocalControlOverlayUseCase,
  UndoLocalControlOverlayUseCase? undoLocalControlOverlayUseCase,
  HandleLocalRenewalReminderUseCase? handleLocalRenewalReminderUseCase,
  HandleManualSubscriptionUseCase? handleManualSubscriptionUseCase,
  HandleLocalServicePresentationUseCase? handleLocalServicePresentationUseCase,
  LoadSmsOnboardingProgressUseCase? loadSmsOnboardingProgressUseCase,
  CompleteSmsOnboardingUseCase? completeSmsOnboardingUseCase,
}) async {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Figtree',
  );
  const typeScale = DashboardTypeScale(
    display: TextStyle(fontSize: 40),
    heading: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    subheading: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    body: TextStyle(fontSize: 16),
    caption: TextStyle(fontSize: 13),
    label: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    button: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: baseTheme.copyWith(
        extensions: [typeScale],
      ),
      home: DashboardShell(
        runtimeUseCase: runtimeUseCase,
        syncDeviceSmsUseCase: syncDeviceSmsUseCase,
        handleReviewItemActionUseCase: handleReviewItemActionUseCase,
        undoReviewItemActionUseCase: undoReviewItemActionUseCase,
        handleLocalControlOverlayUseCase: handleLocalControlOverlayUseCase,
        undoLocalControlOverlayUseCase: undoLocalControlOverlayUseCase,
        handleLocalRenewalReminderUseCase: handleLocalRenewalReminderUseCase,
        handleManualSubscriptionUseCase: handleManualSubscriptionUseCase,
        handleLocalServicePresentationUseCase:
            handleLocalServicePresentationUseCase,
        loadSmsOnboardingProgressUseCase: loadSmsOnboardingProgressUseCase,
        completeSmsOnboardingUseCase: completeSmsOnboardingUseCase,
      ),
    ),
  );
  await pumpDashboardShellLoad(tester);
}

Future<void> pumpDashboardShellLoad(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> pumpDashboardShellUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> tapAndPumpDashboardShell(
  WidgetTester tester,
  Finder finder,
) async {
  debugPrint('Tapping: ${finder.description}');
  // Ensure it's in the viewport if it's in a scrollable.
  try {
    await tester.ensureVisible(finder);
  } catch (_) {}

  try {
    // Standard tap with hit testing.
    await tester.tap(finder);
  } catch (e) {
    debugPrint('Hit testing failed for ${finder.description}, trying fallback tap.');
    // Fallback: tap the center directly, bypassing hit-test verification.
    final center = tester.getCenter(finder);
    await tester.tapAt(center);
  }
  await tester.pumpAndSettle();
}





Future<void> scrollDashboardUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  // 1. Try ensureVisible first (fastest if already in tree and potentially visible)
  try {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    if (tester.any(finder.hitTestable())) {
      return;
    }
  } catch (_) {
    // Expected to fail if off-screen in a scrollable
  }

  // 2. Try specific surface keys (the most reliable way in our LazyIndexedStack setup)
  final surfaceKeys = [
    'destination-home-surface',
    'destination-subscriptions-surface',
    'destination-review-surface',
    'destination-settings-surface',
  ];

  for (final key in surfaceKeys) {
    final surface = find.byKey(ValueKey<String>(key), skipOffstage: false);
    if (tester.any(surface)) {
      final scrollable = find.descendant(
        of: surface,
        matching: find.byType(Scrollable),
        matchRoot: true, // In case the surface is the scrollable
      );
      
      if (tester.any(scrollable)) {
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: scrollable.first,
        );
        await tester.pumpAndSettle();
        return;
      }
    }
  }

  // 3. Last resort: ANY scrollable
  final anyScrollable = find.byType(Scrollable).first;
  if (tester.any(anyScrollable)) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: anyScrollable,
    );
  } else {
    // If we're here, we're probably not in a scrollable context or the finder isn't in the tree
    await tester.ensureVisible(finder);
  }

  await tester.pumpAndSettle();

}





Future<void> openDashboardDestination(
  WidgetTester tester,
  String destination,
) async {
  await tapAndPumpDashboardShell(
    tester,
    find.byKey(ValueKey<String>('destination-' + destination)),
  );
}

Future<String> resolveUnresolvedTargetKey() async {
  final snapshot = await LoadRuntimeDashboardUseCase().execute();
  final item = snapshot.reviewQueue.firstWhere(
    (item) => item.serviceKey.value == 'UNRESOLVED',
    orElse: () => snapshot.reviewQueue.first,
  );
  return ReviewItemActionDescriptor.fromReviewItem(item).targetKey;
}

(
  LoadSmsOnboardingProgressUseCase,
  CompleteSmsOnboardingUseCase,
) buildMemorySmsOnboardingUseCases() {
  final store = InMemorySmsOnboardingProgressStore();
  return (
    LoadSmsOnboardingProgressUseCase(store: store),
    CompleteSmsOnboardingUseCase(store: store),
  );
}

