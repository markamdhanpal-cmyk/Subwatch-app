import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_control_overlay_models.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('restored local snapshot now surfaces a saved-view refresh action', (
    tester,
  ) async {
    final store = MemoryLedgerSnapshotStore();

    await LoadRuntimeDashboardUseCase(
      capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
      ),
      deviceSmsGateway: FakeDeviceSmsGateway(
        <RawDeviceSms>[
          RawDeviceSms(
            id: 'raw-netflix',
            address: 'BANK',
            body: 'Your Netflix subscription has been renewed for Rs 499.',
            receivedAt: DateTime(2026, 3, 12, 13, 0),
          ),
        ],
      ),
      ledgerSnapshotStore: store,
      loadMode: RuntimeLedgerLoadMode.refreshFromSource,
      clock: () => DateTime(2026, 3, 13, 9, 30),
    ).execute();

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ledgerSnapshotStore: store,
        clock: () => DateTime(2026, 3, 13, 10, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('home-action-strip')), findsOneWidget);
    expect(find.text('Last results'), findsOneWidget);
    expect(find.text('Check again'), findsWidgets);

    await openDashboardDestination(tester, 'settings');
    expect(find.text('Scan again'), findsOneWidget);
  });

  testWidgets('stale restored snapshots still keep the saved-view action visible', (
    tester,
  ) async {
    final store = MemoryLedgerSnapshotStore();

    await store.saveRecord(
      LedgerSnapshotRecord(
        entries: <ServiceLedgerEntry>[],
        metadata: LedgerSnapshotMetadata(
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          refreshedAt: DateTime(2026, 3, 9, 9, 30),
        ),
      ),
    );

    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
        ledgerSnapshotStore: store,
        clock: () => DateTime(2026, 3, 13, 10, 0),
      ),
    );

    expect(find.byKey(const ValueKey<String>('home-action-strip')), findsOneWidget);
    expect(find.text('Last results'), findsOneWidget);
    expect(find.text('Check again'), findsWidgets);
  });

  testWidgets(
    'restored snapshots with on-device adjustments still keep settings actions available',
    (tester) async {
      final store = MemoryLedgerSnapshotStore();
      final localControlOverlayStore = InMemoryLocalControlOverlayStore();

      await LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
        ledgerSnapshotStore: store,
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
        clock: () => DateTime(2026, 3, 13, 9, 30),
      ).execute();

      await localControlOverlayStore.save(
        LocalControlDecision.ignoreService(
          card: const DashboardCard(
            serviceKey: ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle: 'Confirmed paid subscription - \u20B9499',
            state: ResolverState.activePaid,
          ),
          decidedAt: DateTime(2026, 3, 13, 9, 45),
        ),
      );

      await pumpConstrainedDashboardShell(
        tester,
        runtimeUseCase: LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: const FakeDeviceSmsGateway(<RawDeviceSms>[]),
          ledgerSnapshotStore: store,
          localControlOverlayStore: localControlOverlayStore,
          clock: () => DateTime(2026, 3, 13, 10, 0),
        ),
      );

      await openDashboardDestination(tester, 'settings');
      expect(
        find.byKey(const ValueKey<String>('settings-source-action')),
        findsOneWidget,
      );
      expect(find.text('Scan again'), findsOneWidget);
    },
  );
}


