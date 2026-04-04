import 'dart:convert';
import 'dart:io';

import '../../test/support/test_temp_dir.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/persisted_service_ledger_entry.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/stores/json_file_ledger_snapshot_store.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('JsonFileLedgerSnapshotStore', () {
    late Directory tempDirectory;
    late JsonFileLedgerSnapshotStore store;

    setUp(() async {
      tempDirectory = await createWorkspaceTempDirectory('sub-killer-ledger-store');
      store = JsonFileLedgerSnapshotStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('returns no snapshot when the snapshot file does not exist', () async {
      expect(await store.hasSnapshot(), isFalse);
      expect(await store.load(), isEmpty);
      expect(await store.loadRecord(), isNull);
    });

    test('saves and loads persisted ledger entries deterministically',
        () async {
      await store.saveRecord(
        LedgerSnapshotRecord(
          entries: <ServiceLedgerEntry>[
            _entry(
              serviceKey: 'YOUTUBE_PREMIUM',
              state: ResolverState.activePaid,
              lastEventType: SubscriptionEventType.subscriptionBilled,
              lastEventAt: DateTime(2026, 3, 13, 9, 30),
              totalBilled: 149,
              evidenceTrail: EvidenceTrail(
                messageIds: const <String>['yt-1'],
                eventIds: const <String>['yt-event-1'],
                notes: const <String>['billed'],
              ),
            ),
            _entry(
              serviceKey: 'NETFLIX',
              state: ResolverState.activePaid,
              lastEventType: SubscriptionEventType.subscriptionBilled,
              lastEventAt: DateTime(2026, 3, 13, 9, 0),
              totalBilled: 499,
              evidenceTrail: EvidenceTrail(
                messageIds: const <String>['nf-1'],
                eventIds: const <String>['nf-event-1'],
                notes: const <String>['renewed'],
              ),
            ),
          ],
          metadata: LedgerSnapshotMetadata(
            sourceKind: RuntimeSnapshotSourceKind.deviceSms,
            refreshedAt: DateTime(2026, 3, 13, 9, 35),
          ),
        ),
      );

      final restoredRecord = await store.loadRecord();
      final restoredEntries = await store.load();

      expect(await store.hasSnapshot(), isTrue);
      expect(restoredRecord, isNotNull);
      expect(restoredRecord!.metadata, isNotNull);
      expect(
        restoredRecord.metadata!.sourceKind,
        RuntimeSnapshotSourceKind.deviceSms,
      );
      expect(
        restoredRecord.metadata!.refreshedAt,
        DateTime(2026, 3, 13, 9, 35),
      );
      expect(restoredEntries, hasLength(2));
      expect(
        restoredEntries.map((entry) => entry.serviceKey.value),
        <String>['NETFLIX', 'YOUTUBE_PREMIUM'],
      );
      expect(restoredEntries.first.totalBilled, 499);
      expect(
        restoredEntries.first.lastEventType,
        SubscriptionEventType.subscriptionBilled,
      );
      expect(restoredEntries.first.evidenceTrail.messageIds, <String>['nf-1']);
      expect(restoredEntries.last.totalBilled, 149);
    });

    test('returns an empty snapshot when the persisted file is malformed',
        () async {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileLedgerSnapshotStore.defaultFileName}',
      );
      await file.writeAsString('{not-json}', flush: true);

      expect(await store.hasSnapshot(), isTrue);
      expect(await store.load(), isEmpty);
      expect(await store.loadRecord(), isNull);
    });
    test('demotes legacy low-confidence extracted-candidate keys on load',
        () async {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileLedgerSnapshotStore.defaultFileName}',
      );
      await file.writeAsString(
        jsonEncode(<Object?>[
          PersistedServiceLedgerEntry.fromDomain(
            _entry(
              serviceKey: 'MODI',
              state: ResolverState.pendingConversion,
              evidenceTrail: EvidenceTrail(
                notes: const <String>[
                  'merchant_resolution:extractedCandidate:low:modi',
                ],
              ),
            ),
          ).toJson(),
        ]),
        flush: true,
      );

      final restoredEntries = await store.load();

      expect(restoredEntries, hasLength(1));
      expect(restoredEntries.single.serviceKey.value, 'UNRESOLVED');
    });

    test('loads legacy entry-only snapshot files without metadata', () async {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileLedgerSnapshotStore.defaultFileName}',
      );
      await file.writeAsString(
        jsonEncode(<Object?>[
          PersistedServiceLedgerEntry.fromDomain(
            _entry(
              serviceKey: 'NETFLIX',
              state: ResolverState.activePaid,
              lastEventType: SubscriptionEventType.subscriptionBilled,
              lastEventAt: DateTime(2026, 3, 13, 9, 0),
              totalBilled: 499,
              evidenceTrail: EvidenceTrail(
                messageIds: const <String>['nf-1'],
                eventIds: const <String>['nf-event-1'],
                notes: const <String>['renewed'],
              ),
            ),
          ).toJson(),
        ]),
        flush: true,
      );

      final restoredRecord = await store.loadRecord();

      expect(restoredRecord, isNotNull);
      expect(restoredRecord!.metadata, isNull);
      expect(restoredRecord.entries, hasLength(1));
      expect(restoredRecord.entries.single.serviceKey.value, 'NETFLIX');
    });
  });
}

ServiceLedgerEntry _entry({
  required String serviceKey,
  required ResolverState state,
  required EvidenceTrail evidenceTrail,
  SubscriptionEventType? lastEventType,
  DateTime? lastEventAt,
  double totalBilled = 0,
}) {
  return ServiceLedgerEntry(
    serviceKey: ServiceKey(serviceKey),
    state: state,
    evidenceTrail: evidenceTrail,
    lastEventType: lastEventType,
    lastEventAt: lastEventAt,
    totalBilled: totalBilled,
  );
}

