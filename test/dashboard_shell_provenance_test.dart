import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  testWidgets('restored local snapshot provenance renders honestly', (
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

    await pumpDashboardShellApp(
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

    final provenanceTitle = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(provenanceTitle.data, 'Saved view');
    expect(
      find.text(
        'Opened the saved view from 13 Mar 2026, 10:00. It was last checked on 13 Mar 2026, 09:30 from your messages.',
      ),
      findsWidgets,
    );

    final freshnessLabel = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-freshness-label')),
    );
    const expectedFreshnessStates = <String>{
      'Still recent',
      'Check again soon',
      'May be out of date',
    };
    expect(expectedFreshnessStates.contains(freshnessLabel.data), isTrue);
  });

  testWidgets('stale restored snapshot freshness renders honestly', (
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

    await pumpDashboardShellApp(
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

    final provenanceTitle = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-provenance-title')),
    );
    expect(provenanceTitle.data, 'Saved view');
    final freshnessLabel = tester.widget<Text>(
      find.byKey(const ValueKey<String>('runtime-freshness-label')),
    );
    expect(freshnessLabel.data, 'May be out of date');
  });
}
