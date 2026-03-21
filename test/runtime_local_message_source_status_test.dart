import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/message_sources/sample_local_message_source.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/runtime_local_message_source_status.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/use_cases/select_local_message_source_use_case.dart';

void main() {
  group('RuntimeLocalMessageSourceStatus', () {
    test('builds trust-first sample provenance copy', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.sampleDemo,
          resolution: LocalMessageSourceResolution.sampleLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.freshLoad,
          sourceKind: RuntimeSnapshotSourceKind.sampleDemo,
          recordedAt: DateTime(2026, 3, 13, 9, 0),
          refreshedAt: DateTime(2026, 3, 13, 9, 0),
        ),
      );

      expect(status.title, 'Sample view');
      expect(
        status.description,
        'This is a sample layout until you scan messages on this device.',
      );
      expect(status.provenanceTitle, 'Sample view');
      expect(
        status.provenanceDescription,
        'Showing the sample view prepared on 13 Mar 2026, 09:00.',
      );
      expect(status.freshnessLabel, 'Sample view');
      expect(
        status.freshnessDescription,
        'This sample stays fixed until you scan messages on this device.',
      );
      expect(status.actionLabel, 'Scan messages');
      expect(
        status.permissionRationaleVariant,
        RuntimeLocalMessageSourcePermissionRationaleVariant.firstRun,
      );
    });

    test('builds fresh device snapshot freshness copy', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.freshLoad,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 13, 10, 0),
          refreshedAt: DateTime(2026, 3, 13, 10, 0),
        ),
        clock: () => DateTime(2026, 3, 13, 10, 5),
      );

      expect(status.title, 'From your messages');
      expect(
        status.description,
        'Showing what SubWatch found from messages on this device.',
      );
      expect(status.provenanceTitle, 'Checked');
      expect(
        status.provenanceDescription,
        'Checked your messages on 13 Mar 2026, 10:00.',
      );
      expect(status.freshnessLabel, 'Checked recently');
      expect(
        status.freshnessDescription,
        'Based on a recent message check on this device.',
      );
      expect(status.actionLabel, 'Check again');
      expect(status.permissionRationaleVariant, isNull);
    });

    test('builds restored provenance copy without pretending it is fresh', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 13, 10, 0),
          refreshedAt: DateTime(2026, 3, 13, 9, 30),
        ),
        clock: () => DateTime(2026, 3, 13, 15, 0),
      );

      expect(status.provenanceTitle, 'Saved view');
      expect(
        status.provenanceDescription,
        'Opened the saved view from 13 Mar 2026, 10:00. It was last checked on 13 Mar 2026, 09:30 from your messages.',
      );
      expect(status.freshnessLabel, 'Still recent');
      expect(
        status.freshnessDescription,
        'The last message check on this device is still recent.',
      );
    });

    test('builds stale restored snapshot freshness copy', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 13, 10, 0),
          refreshedAt: DateTime(2026, 3, 9, 9, 30),
        ),
        clock: () => DateTime(2026, 3, 13, 15, 0),
      );

      expect(status.provenanceTitle, 'Saved view');
      expect(status.freshnessLabel, 'May be out of date');
      expect(
        status.freshnessDescription,
        'This saved view may be out of date.',
      );
    });

    test(
      'keeps backward-compatible restored snapshots honest when timing details are missing',
      () {
        final status = RuntimeLocalMessageSourceStatus.fromSelection(
          LocalMessageSourceSelection(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
            resolution: LocalMessageSourceResolution.deviceLocal,
            messageSource: const SampleLocalMessageSource(),
          ),
          provenance: RuntimeSnapshotProvenance(
            kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
            sourceKind: RuntimeSnapshotSourceKind.unknown,
            recordedAt: DateTime(2026, 3, 13, 10, 0),
          ),
        );

        expect(
          status.provenanceDescription,
          'Opened the saved view from 13 Mar 2026, 10:00.',
        );
        expect(status.freshnessLabel, 'Timing unavailable');
        expect(
          status.freshnessDescription,
          'This saved view does not include recent check timing.',
        );
      },
    );

    test('keeps denied-state copy honest when showing a restored snapshot', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalDenied,
          resolution: LocalMessageSourceResolution.deviceLocalStub,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 13, 10, 0),
          refreshedAt: DateTime(2026, 3, 13, 9, 30),
        ),
      );

      expect(status.title, 'Saved view');
      expect(
        status.description,
        'Showing the last saved view on this device. It is not a new SMS check.',
      );
      expect(status.provenanceTitle, 'Saved view');
      expect(status.actionLabel, 'Turn on SMS access');
      expect(
        status.permissionRationaleVariant,
        RuntimeLocalMessageSourcePermissionRationaleVariant.retry,
      );
    });

    test('flags on-device changes without hiding the saved provenance state', () {
      final status = RuntimeLocalMessageSourceStatus.fromSelection(
        LocalMessageSourceSelection(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: const SampleLocalMessageSource(),
        ),
        provenance: RuntimeSnapshotProvenance(
          kind: RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
          sourceKind: RuntimeSnapshotSourceKind.deviceSms,
          recordedAt: DateTime(2026, 3, 13, 10, 0),
          refreshedAt: DateTime(2026, 3, 13, 9, 30),
        ),
        hasLocalModifications: true,
      );

      expect(status.provenanceTitle, 'Saved view');
      expect(status.hasLocalModifications, isTrue);
      expect(status.localModificationsLabel, 'Adjusted on this device');
    });
  });
}
