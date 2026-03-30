import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/models/persisted_service_evidence_bucket.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/stores/json_file_ledger_snapshot_store.dart';
import 'package:sub_killer/application/stores/json_file_service_evidence_bucket_store.dart';
import 'package:sub_killer/application/use_cases/accumulate_service_evidence_buckets_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/contracts/service_evidence_bucket_repository.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/v2/decision/enums/decision_execution_mode.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('Ticket 79 shadow, migration, and performance hardening', () {
    test('shadow compare mode exposes an inspectable comparison report', () async {
      final useCase = LocalIngestionFlowUseCase(
        decisionExecutionMode: DecisionExecutionMode.shadowCompareAndBridge,
      );

      final result = await useCase.executeCanonicalInputs(<CanonicalInput>[
        CanonicalInput.deviceSms(
          id: 'shadow-netflix-1',
          senderHandle: 'BANK',
          textBody: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2026, 3, 29, 10, 0),
        ),
      ]);

      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries.single.state, isNotNull);
      expect(useCase.lastShadowComparison, isNotNull);
      expect(useCase.lastShadowComparison!.legacyEntryCount, 1);
      expect(useCase.lastShadowComparison!.v2EntryCount, 1);
      expect(useCase.lastShadowComparison!.toDebugString(), isNotEmpty);
    });

    test('runtime snapshot persists and restores shadow comparison metadata',
        () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'sub-killer-shadow-rollout-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final ledgerStore = JsonFileLedgerSnapshotStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );

      final freshSnapshot = await LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: _StaticGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 29, 9, 0),
            ),
          ],
        ),
        ledgerSnapshotStore: ledgerStore,
        loadMode: RuntimeLedgerLoadMode.refreshFromSource,
        decisionExecutionMode: DecisionExecutionMode.shadowCompareAndBridge,
        clock: () => DateTime(2026, 3, 29, 11, 0),
      ).execute();

      expect(
        freshSnapshot.provenance.decisionExecutionMode,
        DecisionExecutionMode.shadowCompareAndBridge,
      );
      expect(freshSnapshot.provenance.shadowComparedAt, isNotNull);
      expect(freshSnapshot.shadowComparison, isNotNull);

      final restoredSnapshot = await LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: _StaticGateway(const <RawDeviceSms>[]),
        ledgerSnapshotStore: ledgerStore,
        decisionExecutionMode: DecisionExecutionMode.shadowCompareAndBridge,
        clock: () => DateTime(2026, 3, 29, 12, 0),
      ).execute();

      expect(
        restoredSnapshot.provenance.decisionExecutionMode,
        DecisionExecutionMode.shadowCompareAndBridge,
      );
      expect(
        restoredSnapshot.provenance.shadowDifferenceCount,
        freshSnapshot.provenance.shadowDifferenceCount,
      );
      expect(restoredSnapshot.provenance.shadowComparedAt, isNotNull);
    });

    test('service evidence bucket store migrates legacy list files safely',
        () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'sub-killer-bucket-migration-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final store = JsonFileServiceEvidenceBucketStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileServiceEvidenceBucketStore.defaultFileName}',
      );
      await file.writeAsString(
        jsonEncode(<Object?>[
          PersistedServiceEvidenceBucket.fromDomain(
            ServiceEvidenceBucket(
              serviceKey: const ServiceKey('NETFLIX'),
              firstSeenAt: DateTime(2026, 3, 1, 9, 0),
              lastSeenAt: DateTime(2026, 3, 29, 9, 0),
              sourceKindsSeen: const <ServiceEvidenceSourceKind>[
                ServiceEvidenceSourceKind.deviceSmsInbox,
              ],
              billedCount: 2,
              renewalHintCount: 1,
              amountSeries: const <double>[499, 499],
              evidenceTrail: EvidenceTrail(
                messageIds: const <String>['nf-1'],
                eventIds: const <String>['event-1'],
                notes: const <String>['fragment:billed_success'],
              ),
            ),
          ).toJson(),
        ]),
        flush: true,
      );

      final restored = await store.load();
      expect(restored, hasLength(1));
      expect(restored.single.serviceKey.value, 'NETFLIX');

      await store.save(restored);
      final wrapped = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(wrapped['schemaVersion'], 2);
      expect(wrapped['buckets'], isA<List<dynamic>>());
    });

    test('bucket accumulation batches repository work for large inboxes',
        () async {
      final repository = _CountingBucketRepository();
      final useCase = const AccumulateServiceEvidenceBucketsUseCase();
      final events = List<SubscriptionEvent>.generate(
        250,
        (index) => SubscriptionEvent(
          id: 'event-$index',
          serviceKey: const ServiceKey('NETFLIX'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2026, 3, 1 + (index % 28), 9, 0),
          sourceMessageId: 'message-$index',
          amount: 499,
          evidenceTrail: EvidenceTrail(
            messageIds: <String>['message-$index'],
            eventIds: <String>['event-$index'],
            notes: const <String>['fragment:billed_success'],
          ),
        ),
      );
      final canonicalInputsByMessageId = <String, CanonicalInput>{
        for (var index = 0; index < events.length; index++)
          'message-$index': CanonicalInput.deviceSms(
            id: 'message-$index',
            senderHandle: 'BANK',
            textBody: 'Netflix billed successfully for Rs 499.',
            receivedAt: DateTime(2026, 3, 1 + (index % 28), 9, 0),
          ),
      };

      await useCase.execute(
        events: events,
        canonicalInputsByMessageId: canonicalInputsByMessageId,
        repository: repository,
      );

      expect(repository.listCallCount, 1);
      expect(repository.replaceAllCallCount, 1);
      expect(repository.readCallCount, 0);
      expect(repository.writeCallCount, 0);
      expect(repository.buckets.single.billedCount, 250);
    });
  });
}

class _StaticGateway implements DeviceSmsGateway {
  const _StaticGateway(this.messages);

  final List<RawDeviceSms> messages;

  @override
  Future<List<RawDeviceSms>> readMessages() async => messages;
}

class _CountingBucketRepository implements ServiceEvidenceBucketRepository {
  int readCallCount = 0;
  int writeCallCount = 0;
  int listCallCount = 0;
  int replaceAllCallCount = 0;
  List<ServiceEvidenceBucket> buckets = const <ServiceEvidenceBucket>[];

  @override
  Future<void> clear() async {
    buckets = const <ServiceEvidenceBucket>[];
  }

  @override
  Future<List<ServiceEvidenceBucket>> list() async {
    listCallCount++;
    return buckets;
  }

  @override
  Future<ServiceEvidenceBucket?> read(ServiceKey serviceKey) async {
    readCallCount++;
    for (final bucket in buckets) {
      if (bucket.serviceKey == serviceKey) {
        return bucket;
      }
    }
    return null;
  }

  @override
  Future<void> replaceAll(Iterable<ServiceEvidenceBucket> nextBuckets) async {
    replaceAllCallCount++;
    buckets = nextBuckets.toList(growable: false);
  }

  @override
  Future<void> write(ServiceEvidenceBucket bucket) async {
    writeCallCount++;
    buckets = <ServiceEvidenceBucket>[...buckets, bucket];
  }
}

