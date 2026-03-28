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

      expect(status.title, 'Preview');
      expect(
        status.description,
        'Showing sample data until you scan.',
      );
      expect(status.provenanceTitle, 'Preview');
      expect(
        status.provenanceDescription,
        'Sample prepared on 13 Mar 2026, 09:00.',
      );
      expect(status.freshnessLabel, 'Preview');
      expect(
        status.freshnessDescription,
        'Stays until you scan.',
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
        'Showing results from your messages.',
      );
      expect(status.provenanceTitle, 'Checked');
      expect(
        status.provenanceDescription,
        'Scanned messages on 13 Mar 2026, 10:00.',
      );
      expect(status.freshnessLabel, 'Last scan: today');
      expect(
        status.freshnessDescription,
        'From a recent scan.',
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

      expect(status.provenanceTitle, 'Last results');
      expect(
        status.provenanceDescription,
        'Saved on 13 Mar 2026, 10:00. Last scan 13 Mar 2026, 09:30 from your messages.',
      );
      expect(status.freshnessLabel, 'Last scan: today');
      expect(
        status.freshnessDescription,
        'Last scan is still recent.',
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

      expect(status.provenanceTitle, 'Last results');
      expect(status.freshnessLabel, 'Last scan: 9 Mar');
      expect(
        status.freshnessDescription,
        'This saved view may be old.',
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
          'Opened saved view from 13 Mar 2026, 10:00.',
        );
        expect(status.freshnessLabel, 'Last scan unavailable');
        expect(
          status.freshnessDescription,
          'No recent scan time is available.',
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

      expect(status.title, 'Last results');
      expect(
        status.description,
        'Showing your last saved results.',
      );
      expect(status.provenanceTitle, 'Last results');
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

      expect(status.provenanceTitle, 'Last results');
      expect(status.hasLocalModifications, isTrue);
      expect(status.localModificationsLabel, 'Changed on this phone');
    });
  });
}











