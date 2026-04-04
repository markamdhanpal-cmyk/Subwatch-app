import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/app/subscription_killer_app.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/contracts/ledger_snapshot_store.dart';
import 'package:sub_killer/application/contracts/local_message_source_capability_provider.dart';
import 'package:sub_killer/application/contracts/local_renewal_reminder_scheduler.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_renewal_reminder_models.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_manual_subscription_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/use_cases/handle_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_renewal_reminder_use_case.dart';
import 'package:sub_killer/application/contracts/local_manual_subscription_store.dart';
import 'package:sub_killer/application/contracts/local_renewal_reminder_store.dart';
import 'package:sub_killer/application/contracts/review_action_store.dart';
import 'package:sub_killer/application/contracts/local_control_overlay_store.dart';
import 'package:sub_killer/application/contracts/local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/use_cases/undo_local_control_overlay_use_case.dart';
import 'package:sub_killer/application/use_cases/undo_review_item_action_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_shell_providers.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_review_item_action_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_manual_subscription_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_service_presentation_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/presentation/dashboard/dashboard_primitives.dart';

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

  Completer<LocalMessageSourceAccessRequestResult>? delayRequest;

  @override
  Future<LocalMessageSourceAccessState> getAccessState() async => _state;

  @override
  Future<LocalMessageSourceAccessRequestResult> requestAccess() async {
    requestCount += 1;
    final result = await (delayRequest?.future ?? Future.value(requestResult));
    _state = refreshedState;
    return result;
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
    required this.loadSmsOnboardingProgressUseCase,
    required this.completeSmsOnboardingUseCase,
    required this.localManualSubscriptionStore,
    required this.localRenewalReminderStore,
    required this.reviewActionStore,
    required this.localControlOverlayStore,
    required this.localServicePresentationOverlayStore,
    required this.onboardingStore,
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
    final onboardingStore = InMemorySmsOnboardingProgressStore()
      ..writeCompleted(true);

    final runtimeUseCase = LoadRuntimeDashboardUseCase(
      ledgerRepository: ledgerRepository,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      deviceSmsGateway: deviceSmsGateway,
      unavailableDeviceSmsGateway: deviceSmsGateway,
      capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
      ),
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
        localRenewalReminderScheduler:
            const NoOpLocalRenewalReminderScheduler(),
        loadRuntimeDashboard: () => runtimeUseCase.execute(),
      ),
      loadSmsOnboardingProgressUseCase: LoadSmsOnboardingProgressUseCase(
        store: onboardingStore,
      ),
      completeSmsOnboardingUseCase: CompleteSmsOnboardingUseCase(
        store: onboardingStore,
      ),
      localManualSubscriptionStore: localManualSubscriptionStore,
      localRenewalReminderStore: localRenewalReminderStore,
      reviewActionStore: reviewActionStore,
      localControlOverlayStore: localControlOverlayStore,
      localServicePresentationOverlayStore:
          localServicePresentationOverlayStore,
      onboardingStore: onboardingStore,
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
  final LoadSmsOnboardingProgressUseCase loadSmsOnboardingProgressUseCase;
  final CompleteSmsOnboardingUseCase completeSmsOnboardingUseCase;

  final LocalManualSubscriptionStore localManualSubscriptionStore;
  final LocalRenewalReminderStore localRenewalReminderStore;
  final ReviewActionStore reviewActionStore;
  final LocalControlOverlayStore localControlOverlayStore;
  final LocalServicePresentationOverlayStore
      localServicePresentationOverlayStore;
  final InMemorySmsOnboardingProgressStore onboardingStore;
}

ThemeData buildDashboardTestTheme({
  DashboardTypeScale typeScale = const DashboardTypeScale(
    display: TextStyle(fontSize: 40),
    heading: TextStyle(fontSize: 22),
    subheading: TextStyle(fontSize: 18),
    body: TextStyle(fontSize: 16),
    caption: TextStyle(fontSize: 13),
    label: TextStyle(fontSize: 13),
    button: TextStyle(fontSize: 14),
  ),
  DashboardColorTokens colorTokens = DashboardColorTokens.light,
  Brightness brightness = Brightness.light,
}) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Figtree',
  );
  final colorScheme = brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: colorTokens.accent,
          onPrimary: colorTokens.accentInk,
          secondary: colorTokens.statusBlue,
          onSecondary: colorTokens.ink,
          error: colorTokens.caution,
          onError: colorTokens.accentInk,
          surface: colorTokens.paper,
          onSurface: colorTokens.ink,
        )
      : ColorScheme.light(
          primary: colorTokens.accent,
          onPrimary: colorTokens.accentInk,
          secondary: colorTokens.statusBlue,
          onSecondary: colorTokens.ink,
          error: colorTokens.caution,
          onError: colorTokens.accentInk,
          surface: colorTokens.paper,
          onSurface: colorTokens.ink,
        );

  return baseTheme.copyWith(
    colorScheme: colorScheme.copyWith(
      outline: colorTokens.outline,
      outlineVariant: colorTokens.outlineStrong,
      shadow: colorTokens.shadow,
      scrim: colorTokens.scrim,
    ),
    scaffoldBackgroundColor: colorTokens.canvas,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorTokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(
      color: colorTokens.ink,
    ),
    extensions: <ThemeExtension<dynamic>>[
      typeScale,
      colorTokens,
    ],
  );
}

Future<void> pumpConstrainedDashboardShell(
  WidgetTester tester, {
  double textScale = 1.0,
  bool skipGate = true,
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
  final fallbackStore = InMemorySmsOnboardingProgressStore()
    ..writeCompleted(true);
  final actualLoadSmsOnboarding = loadSmsOnboardingProgressUseCase ??
      LoadSmsOnboardingProgressUseCase(store: fallbackStore);
  final actualCompleteSmsOnboarding = completeSmsOnboardingUseCase ??
      CompleteSmsOnboardingUseCase(store: fallbackStore);
  // Increase surface size to ensure bottom navigation is hit-testable.
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    SubKillerApp(
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
      loadSmsOnboardingProgressUseCase: actualLoadSmsOnboarding,
      completeSmsOnboardingUseCase: actualCompleteSmsOnboarding,
      textScaler: TextScaler.linear(textScale),
    ),
  );
  await pumpDashboardShellLoad(tester, skipGate: skipGate);
}

Future<void> pumpDashboardShellLoad(
  WidgetTester tester, {
  bool skipGate = true,
}) async {
  // 1. Wait for FirstRunController.initialize() and snapshot loading to finish.
  // We pump in a loop because pumpAndSettle might return pre-emptively if
  // animations are disabled or if the future isn't tracked by the microtask queue.
  int retries = 0;
  while (retries < 50) {
    await tester.runAsync(() async {
      await tester.pump(const Duration(milliseconds: 50));
    });

    // Check if we've reached a stable state (either gate or home)
    final getStartedFinder =
        find.byKey(const ValueKey<String>('first-run-get-started-button'));
    final isGate = getStartedFinder.evaluate().isNotEmpty;

    final isHome = find
        .byKey(const ValueKey<String>('totals-summary-card'))
        .evaluate()
        .isNotEmpty;
    final isScanning =
        find.text('Looking for subscriptions').evaluate().isNotEmpty;
    final isSnapshotLoading =
        find.text('Preparing your view...').evaluate().isNotEmpty;

    final container = findProviderContainer(tester);
    final phase = container.read(dashboardFirstRunProvider).phase;
    final isDenied = phase == FirstRunPhase.denied;
    final isPermanentlyDenied = phase == FirstRunPhase.permanentlyDenied;
    final isFirstResult = phase == FirstRunPhase.firstResult;

    final isSyncing = container.read(dashboardSyncStateProvider).isSyncing;
    debugPrint(
        'pumpDashboardShellLoad [it=$retries]: phase=$phase isSyncing=$isSyncing isGate=$isGate isHome=$isHome isScanning=$isScanning isSnapshotLoading=$isSnapshotLoading');

    if (isGate && skipGate && !isSyncing) {
      debugPrint('pumpDashboardShellLoad: Clicking Get Started gate...');
      await tapAndPumpDashboardShell(tester, getStartedFinder);

      final rationalePrimaryActionFinder = find.byKey(
        const ValueKey<String>('sms-permission-rationale-primary-action'),
      );
      if (rationalePrimaryActionFinder.evaluate().isNotEmpty) {
        debugPrint(
            'pumpDashboardShellLoad: Clicking Rationale primary action...');
        await tapAndPumpDashboardShell(tester, rationalePrimaryActionFinder);
      }
    }

    if (isFirstResult && skipGate && !isSyncing) {
      debugPrint('pumpDashboardShellLoad: Clicking First Result done...');
      final doneFinder =
          find.byKey(const ValueKey<String>('first-run-done-button'));
      await tester.dragUntilVisible(
        doneFinder,
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tapAndPumpDashboardShell(tester, doneFinder);
    }

    final canBreak = isHome ||
        isDenied ||
        isPermanentlyDenied ||
        (isScanning && !skipGate) ||
        (isFirstResult && !skipGate);
    if (canBreak && !isSnapshotLoading) {
      debugPrint(
          'pumpDashboardShellLoad: Breaking on phase=$phase (isHome=$isHome, isDenied=$isDenied, isPermanentlyDenied=$isPermanentlyDenied, isScanning=$isScanning, isFirstResult=$isFirstResult)');
      break;
    }
    retries++;
  }

  // Final settle
  await settleDashboard(tester);
}

/// Bounded settle: pumps frames until no more frames are scheduled, or up to
/// [maxIterations] × 50 ms.  Avoids the infinite hang that bare
/// `pumpAndSettle` causes when internal Flutter widgets keep animating.
Future<void> settleDashboard(WidgetTester tester,
    {int maxIterations = 10}) async {
  for (int i = 0; i < maxIterations; i++) {
    await tester.runAsync(() async {
      await tester.pump(const Duration(milliseconds: 100));
    });
  }
  final scrollables = find.byType(Scrollable).evaluate().length;
  debugPrint('settleDashboard: finished. Found $scrollables Scrollables.');
}

ProviderContainer findProviderContainer(WidgetTester tester) {
  for (final element in tester.allElements) {
    if (element is StatefulElement && element.widget is ProviderScope) {
      return (element.state as dynamic).container as ProviderContainer;
    }
  }
  throw StateError('No ProviderScope found in the entire element tree.');
}

Future<void> pumpDashboardShellUi(WidgetTester tester) async {
  debugPrint('pumpDashboardShellUi: Waiting for UI to settle...');
  await settleDashboard(tester);
  final container = findProviderContainer(tester);
  while (container.read(dashboardShellLoadStateProvider).showLoading) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleDashboard(tester);
}

Future<void> pumpDashboardUntilSyncIdle(WidgetTester tester) async {
  debugPrint('pumpDashboardUntilSyncIdle: Waiting for sync to complete...');
  await settleDashboard(tester);
  final container = findProviderContainer(tester);
  while (container.read(dashboardSyncStateProvider).isSyncing) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleDashboard(tester);
}

Future<void> openDashboardDestination(
    WidgetTester tester, String destination) async {
  final label = switch (destination) {
    'home' => 'Home',
    'subscriptions' => 'Subscriptions',
    'review' => 'Review',
    'settings' => 'Settings',
    _ => destination,
  };

  final keyFinder = find.byKey(ValueKey<String>("destination-$destination"));
  final textFinder = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  final surfaceFinder = switch (destination) {
    'home' =>
      find.byKey(const PageStorageKey<String>('destination-home-surface')),
    _ => find.byKey(ValueKey<String>("destination-$destination-surface")),
  };
  bool isSurfaceVisible() => surfaceFinder.hitTestable().evaluate().isNotEmpty;

  final tapCandidates = <Finder>[
    keyFinder.hitTestable(),
    keyFinder,
    textFinder.hitTestable(),
    textFinder,
  ];

  for (final candidate in tapCandidates) {
    if (candidate.evaluate().isEmpty) {
      continue;
    }
    await tapAndPumpDashboardShell(tester, candidate.first);
    if (isSurfaceVisible()) {
      return;
    }
  }

  if (destination == 'review') {
    final reviewActionFinder =
        find.byKey(const ValueKey<String>('settings-open-review-action'));

    await openDashboardDestination(tester, 'settings');
    await scrollDashboardUntilVisible(tester, reviewActionFinder);

    if (reviewActionFinder.evaluate().isNotEmpty) {
      await tapAndPumpDashboardShell(tester, reviewActionFinder.first);
      if (isSurfaceVisible()) {
        return;
      }
    }
  }

  await settleDashboard(tester);
}

Future<void> tapAndPumpDashboardShell(
    WidgetTester tester, Finder finder) async {
  final element = finder.evaluate();
  if (element.isEmpty) {
    debugPrint(
        'Warning: tapAndPumpDashboardShell called for missing finder: $finder');
    return;
  }
  debugPrint('Tapping: $finder');
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 50));
  final hitTestableFinder = finder.hitTestable();
  final tapTarget = hitTestableFinder.evaluate().isNotEmpty
      ? hitTestableFinder.first
      : finder.first;
  await tester.tap(tapTarget, warnIfMissed: false);
  await settleDashboard(tester);
}

Future<void> scrollDashboardUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 100.0,
}) async {
  await settleDashboard(tester);
  final scrollableFinder = find.byType(Scrollable);
  final allScrollables = scrollableFinder.evaluate();
  debugPrint('SCROLL: found ${allScrollables.length} scrollables');

  if (allScrollables.isEmpty) {
    debugPrint(
        'Widgets types in tree: ${tester.allWidgets.map((w) => w.runtimeType).toSet().toList()}');
    return;
  }
  final int retriesLimit = 30;
  int retries = 0;
  while (retries < retriesLimit) {
    if (finder.evaluate().isNotEmpty) {
      if (tester.any(finder)) {
        try {
          await tester.ensureVisible(finder.first);
          return;
        } catch (_) {
          // Keep scrolling
        }
      }
    }

    final visibleScrollables = find.byType(Scrollable).hitTestable();
    final scrollable = visibleScrollables.evaluate().isNotEmpty
        ? visibleScrollables.first
        : scrollableFinder.first;
    await tester.drag(scrollable, Offset(0, -delta * 2));
    await tester.pump(const Duration(milliseconds: 50));
    retries++;
  }
  await settleDashboard(tester);
}

(LoadSmsOnboardingProgressUseCase, CompleteSmsOnboardingUseCase)
    buildMemorySmsOnboardingUseCases() {
  final store = InMemorySmsOnboardingProgressStore();
  return (
    LoadSmsOnboardingProgressUseCase(store: store),
    CompleteSmsOnboardingUseCase(store: store),
  );
}

Future<void> debug_dump_app(WidgetTester tester) async {
  // ignore: avoid_print
  print('--- WIDGET DUMP START ---');
  for (final w in tester.allWidgets) {
    String extra = '';
    if (w is Text) {
      extra = ' text="${w.data}"';
    } else if (w is RichText) {
      extra = ' text="${w.text.toPlainText()}"';
    }
    // ignore: avoid_print
    print('WIDGET: ${w.runtimeType} key=${w.key}$extra');
  }
  // ignore: avoid_print
  print('--- WIDGET DUMP END ---');
}
