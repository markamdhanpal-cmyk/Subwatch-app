import 'dart:io';

import 'support/test_temp_dir.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_control_overlay_models.dart';
import 'package:sub_killer/application/models/local_service_presentation_overlay_models.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/json_file_ledger_snapshot_store.dart';
import 'package:sub_killer/application/use_cases/apply_local_service_presentation_overlays_use_case.dart';
import 'package:sub_killer/application/use_cases/handle_local_service_presentation_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('LoadRuntimeDashboardUseCase persistence', () {
    late Directory tempDirectory;
    late JsonFileLedgerSnapshotStore store;

    setUp(() async {
      tempDirectory = await createWorkspaceTempDirectory('sub-killer-runtime');
      store = JsonFileLedgerSnapshotStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'refresh mode persists ledger-backed state and later runtime load restores it without re-reading the source',
      () async {
        final seedGateway = _CountingDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        );

        final seededResult = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: seedGateway,
          ledgerSnapshotStore: store,
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 13, 9, 30),
        ).execute();

        expect(seedGateway.readCount, 1);
        expect(
          seededResult.provenance.kind,
          RuntimeSnapshotProvenanceKind.freshLoad,
        );
        expect(
          seededResult.provenance.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          seededResult.provenance.recordedAt,
          DateTime(2026, 3, 13, 9, 30),
        );
        expect(
          seededResult.cards
              .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
              )
              .map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );

        final restoreGateway = _CountingDeviceSmsGateway(<RawDeviceSms>[]);
        final restoredResult = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: restoreGateway,
          ledgerSnapshotStore: store,
          clock: () => DateTime(2026, 3, 13, 10, 0),
        ).execute();

        expect(restoreGateway.readCount, 0);
        expect(
          restoredResult.provenance.kind,
          RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        );
        expect(
          restoredResult.provenance.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          restoredResult.provenance.recordedAt,
          DateTime(2026, 3, 13, 10, 0),
        );
        expect(
          restoredResult.provenance.refreshedAt,
          DateTime(2026, 3, 13, 9, 30),
        );
        expect(
          restoredResult.cards
              .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
              )
              .map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );
      },
    );

    test(
      'refresh mode overwrites the persisted snapshot with the latest deterministic ledger state',
      () async {
        await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(
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

        final refreshedEmptyResult = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(<RawDeviceSms>[]),
          ledgerSnapshotStore: store,
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 13, 10, 0),
        ).execute();

        expect(refreshedEmptyResult.cards, isEmpty);
        expect(
          refreshedEmptyResult.provenance.recordedAt,
          DateTime(2026, 3, 13, 10, 0),
        );

        final restoredResult = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(
            <RawDeviceSms>[
              RawDeviceSms(
                id: 'should-not-be-read',
                address: 'BANK',
                body: 'Your Netflix subscription has been renewed for Rs 499.',
                receivedAt: DateTime(2026, 3, 12, 13, 0),
              ),
            ],
          ),
          ledgerSnapshotStore: store,
          clock: () => DateTime(2026, 3, 13, 10, 30),
        ).execute();

        expect(await store.hasSnapshot(), isTrue);
        expect(restoredResult.cards, isEmpty);
        expect(restoredResult.reviewQueue, isEmpty);
        expect(
          restoredResult.provenance.kind,
          RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        );
        expect(
          restoredResult.provenance.refreshedAt,
          DateTime(2026, 3, 13, 10, 0),
        );
      },
    );

    test(
      'restore mode ignores malformed persisted state and recomputes cleanly from the selected source',
      () async {
        final snapshotFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${JsonFileLedgerSnapshotStore.defaultFileName}',
        );
        await snapshotFile.writeAsString('{not-valid-json', flush: true);

        final gateway = _CountingDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        );

        final result = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: gateway,
          ledgerSnapshotStore: store,
          clock: () => DateTime(2026, 3, 13, 11, 0),
        ).execute();

        expect(gateway.readCount, 1);
        expect(result.provenance.kind, RuntimeSnapshotProvenanceKind.freshLoad);
        expect(
          result.provenance.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          result.cards
              .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
              )
              .map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );
      },
    );

    test(
      'refresh mode keeps the last persisted snapshot when device SMS cannot be read',
      () async {
        await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(
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

        final deniedRefreshResult = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalDenied,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(<RawDeviceSms>[]),
          ledgerSnapshotStore: store,
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 13, 10, 0),
        ).execute();

        expect(
          deniedRefreshResult.messageSourceSelection.accessState,
          LocalMessageSourceAccessState.deviceLocalDenied,
        );
        expect(
          deniedRefreshResult.provenance.kind,
          RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        );
        expect(
          deniedRefreshResult.provenance.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          deniedRefreshResult.provenance.recordedAt,
          DateTime(2026, 3, 13, 10, 0),
        );
        expect(
          deniedRefreshResult.provenance.refreshedAt,
          DateTime(2026, 3, 13, 9, 30),
        );
        expect(
          deniedRefreshResult.cards
              .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
              )
              .map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );

        final persistedRecord = await store.loadRecord();
        expect(persistedRecord, isNotNull);
        expect(
          persistedRecord!.metadata!.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          persistedRecord.metadata!.refreshedAt,
          DateTime(2026, 3, 13, 9, 30),
        );
      },
    );
    test(
      'refresh mode falls back to the last persisted snapshot when source loading throws',
      () async {
        await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(
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

        final result = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
          ),
          deviceSmsGateway: _ThrowingDeviceSmsGateway(),
          ledgerSnapshotStore: store,
          loadMode: RuntimeLedgerLoadMode.refreshFromSource,
          clock: () => DateTime(2026, 3, 13, 10, 0),
        ).execute();

        expect(
          result.provenance.kind,
          RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        );
        expect(
          result.provenance.sourceKind,
          RuntimeSnapshotSourceKind.deviceSms,
        );
        expect(
          result.provenance.refreshedAt,
          DateTime(2026, 3, 13, 9, 30),
        );
        expect(
          result.cards
              .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
              )
              .map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );
      },
    );
    test(
      'restore sanitizes legacy low-confidence extracted-candidate keys before projection',
      () async {
        await store.saveRecord(
          LedgerSnapshotRecord(
            entries: <ServiceLedgerEntry>[
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('NETFLIX'),
                state: ResolverState.activePaid,
                evidenceTrail: EvidenceTrail(
                  notes: const <String>[
                    'merchant_resolution:exactAlias:high:netflix',
                  ],
                ),
              ),
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('MODI'),
                state: ResolverState.pendingConversion,
                evidenceTrail: EvidenceTrail(
                  notes: const <String>[
                    'merchant_resolution:extractedCandidate:low:modi',
                    'fragment:mandate_created',
                  ],
                ),
              ),
            ],
            metadata: LedgerSnapshotMetadata(
              sourceKind: RuntimeSnapshotSourceKind.deviceSms,
              refreshedAt: DateTime(2026, 3, 13, 9, 30),
            ),
          ),
        );

        final restored = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalDenied,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(const <RawDeviceSms>[]),
          ledgerSnapshotStore: store,
          clock: () => DateTime(2026, 3, 13, 11, 30),
        ).execute();

        expect(
          restored.provenance.kind,
          RuntimeSnapshotProvenanceKind.restoredLocalSnapshot,
        );
        expect(
          restored.cards.map((card) => card.serviceKey.value),
          isNot(contains('MODI')),
        );
        expect(
          restored.cards.map((card) => card.serviceKey.value),
          contains('NETFLIX'),
        );
      },
    );
    test(
      'restored projection keeps unresolved hidden and surfaces only review-eligible states',
      () async {
        await store.saveRecord(
          LedgerSnapshotRecord(
            entries: <ServiceLedgerEntry>[
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('UNRESOLVED'),
                state: ResolverState.pendingConversion,
                evidenceTrail: EvidenceTrail.empty(),
              ),
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('MYSTERY_SUB'),
                state: ResolverState.possibleSubscription,
                evidenceTrail: EvidenceTrail(
                  notes: const <String>['v2:reason=weakRecurringSignalsObserved'],
                ),
              ),
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('JIOHOTSTAR'),
                state: ResolverState.pendingConversion,
                evidenceTrail: EvidenceTrail.empty(),
              ),
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('CRUNCHYROLL'),
                state: ResolverState.verificationOnly,
                evidenceTrail: EvidenceTrail.empty(),
              ),
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('NETFLIX'),
                state: ResolverState.activePaid,
                evidenceTrail: EvidenceTrail.empty(),
                totalBilled: 499,
              ),
            ],
            metadata: LedgerSnapshotMetadata(
              sourceKind: RuntimeSnapshotSourceKind.deviceSms,
              refreshedAt: DateTime(2026, 3, 13, 9, 30),
            ),
          ),
        );

        final restored = await LoadRuntimeDashboardUseCase(
          capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
            accessState: LocalMessageSourceAccessState.deviceLocalDenied,
          ),
          deviceSmsGateway: _CountingDeviceSmsGateway(const <RawDeviceSms>[]),
          ledgerSnapshotStore: store,
          clock: () => DateTime(2026, 3, 13, 12, 0),
        ).execute();

        expect(
          restored.cards.map((card) => card.serviceKey.value),
          isNot(contains('UNRESOLVED')),
        );
        final mysteryCard = restored.cards.firstWhere(
          (card) => card.serviceKey.value == 'MYSTERY_SUB',
        );
        expect(mysteryCard.bucket, DashboardBucket.hidden);
        expect(
          restored.reviewQueue.map((item) => item.serviceKey.value),
          <String>['CRUNCHYROLL', 'JIOHOTSTAR'],
        );
        final pending = restored.reviewQueue.firstWhere(
          (item) => item.serviceKey.value == 'JIOHOTSTAR',
        );
        expect(
          pending.reasonLine,
          'A recurring setup was found, but billing is still missing',
        );
        final verification = restored.reviewQueue.firstWhere(
          (item) => item.serviceKey.value == 'CRUNCHYROLL',
        );
        expect(
          verification.detailsBullets,
          contains(
            'Tiny verification charges do not prove an active paid subscription.',
          ),
        );
      },
    );
    test(
      'refresh persistence writes low-confidence extracted candidates as UNRESOLVED',
      () async {
        await store.saveRecord(
          LedgerSnapshotRecord(
            entries: <ServiceLedgerEntry>[
              ServiceLedgerEntry(
                serviceKey: const ServiceKey('MODI'),
                state: ResolverState.pendingConversion,
                evidenceTrail: EvidenceTrail(
                  notes: const <String>[
                    'merchant_resolution:extractedCandidate:low:modi',
                    'fragment:mandate_created',
                  ],
                ),
              ),
            ],
            metadata: LedgerSnapshotMetadata(
              sourceKind: RuntimeSnapshotSourceKind.deviceSms,
              refreshedAt: DateTime(2026, 3, 13, 9, 0),
            ),
          ),
        );

        final snapshotFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${JsonFileLedgerSnapshotStore.defaultFileName}',
        );
        final raw = await snapshotFile.readAsString();

        expect(raw, contains('"UNRESOLVED"'));
        expect(raw, isNot(contains('"MODI"')));
      },
    );
    test(
      'local service presentation overlays relabel cards locally and keep pinned services first',
      () async {
        final localServicePresentationOverlayStore =
            InMemoryLocalServicePresentationOverlayStore();
        await localServicePresentationOverlayStore.save(
          LocalServicePresentationOverlay(
            serviceKey: 'YOUTUBE_PREMIUM',
            localLabel: 'Family Video',
            pinnedAt: DateTime(2026, 3, 14, 10, 0),
          ),
        );

        final result = await ApplyLocalServicePresentationOverlaysUseCase(
          localServicePresentationOverlayStore:
              localServicePresentationOverlayStore,
        ).execute(
          cards: const <DashboardCard>[
            DashboardCard(
              serviceKey: ServiceKey('NETFLIX'),
              bucket: DashboardBucket.confirmedSubscriptions,
              title: 'Netflix',
              subtitle: 'Confirmed paid subscription - \u20B9499',
              state: ResolverState.activePaid,
            ),
            DashboardCard(
              serviceKey: ServiceKey('YOUTUBE_PREMIUM'),
              bucket: DashboardBucket.confirmedSubscriptions,
              title: 'YouTube Premium',
              subtitle: 'Confirmed paid subscription - \u20B9129',
              state: ResolverState.activePaid,
            ),
          ],
        );

        expect(
          result.cards.map((card) => card.title).toList(growable: false),
          <String>['Family Video', 'Netflix'],
        );
        expect(
          result.servicePresentationStates['YOUTUBE_PREMIUM']!.originalTitle,
          'YouTube Premium',
        );
        expect(
          result.servicePresentationStates['YOUTUBE_PREMIUM']!.displayTitle,
          'Family Video',
        );
        expect(
          result.servicePresentationStates['YOUTUBE_PREMIUM']!.isPinned,
          isTrue,
        );
      },
    );

    test(
      'local service presentation controls stay reversible and presentation only',
      () async {
        final localServicePresentationOverlayStore =
            InMemoryLocalServicePresentationOverlayStore();
        Future<RuntimeDashboardSnapshot> loadSnapshot() {
          return LoadRuntimeDashboardUseCase(
            localServicePresentationOverlayStore:
                localServicePresentationOverlayStore,
            clock: () => DateTime(2026, 3, 14, 9, 30),
          ).execute();
        }

        final useCase = HandleLocalServicePresentationUseCase(
          localServicePresentationOverlayStore:
              localServicePresentationOverlayStore,
          loadRuntimeDashboard: loadSnapshot,
          clock: () => DateTime(2026, 3, 14, 10, 0),
        );

        final seedSnapshot = await loadSnapshot();
        final netflixCard = seedSnapshot.cards.firstWhere(
          (card) => card.serviceKey.value == 'NETFLIX',
        );

        final relabeledResult = await useCase.saveLocalLabel(
          card: netflixCard,
          label: 'Family streaming',
        );
        expect(
          relabeledResult.snapshot!.cards.map((card) => card.title),
          contains('Family streaming'),
        );
        expect(
          relabeledResult.snapshot!
              .localServicePresentationStates['NETFLIX']!
              .originalTitle,
          'Netflix',
        );

        final resetResult = await useCase.resetLocalLabel(serviceKey: 'NETFLIX');
        expect(
          resetResult.snapshot!.cards.map((card) => card.title),
          contains('Netflix'),
        );
        expect(
          resetResult.snapshot!
              .localServicePresentationStates['NETFLIX']!
              .hasLocalLabel,
          isFalse,
        );

        final pinResult = await useCase.pinService(netflixCard);
        expect(
          pinResult.snapshot!
              .localServicePresentationStates['NETFLIX']!
              .isPinned,
          isTrue,
        );

        final unpinResult = await useCase.unpinService(serviceKey: 'NETFLIX');
        expect(
          unpinResult.snapshot!
              .localServicePresentationStates['NETFLIX']!
              .isPinned,
          isFalse,
        );
      },
    );

    test(
      'local control overlays suppress cards and review items without mutating runtime truth',
      () async {
        final localControlOverlayStore = InMemoryLocalControlOverlayStore();
        final seedSnapshot = await LoadRuntimeDashboardUseCase(
          clock: () => DateTime(2026, 3, 14, 9, 30),
        ).execute();
        expect(seedSnapshot.reviewQueue, isNotEmpty);
        final reviewItem = seedSnapshot.reviewQueue.first;

        await localControlOverlayStore.save(
          LocalControlDecision.ignoreService(
            card: DashboardCard(
              serviceKey: const ServiceKey('NETFLIX'),
              bucket: DashboardBucket.confirmedSubscriptions,
              title: 'Netflix',
              subtitle: 'Confirmed paid subscription - \u20B9499',
              state: ResolverState.activePaid,
            ),
            decidedAt: DateTime(2026, 3, 14, 10, 0),
          ),
        );
        await localControlOverlayStore.save(
          LocalControlDecision.ignoreReviewItem(
            reviewItem: reviewItem,
            decidedAt: DateTime(2026, 3, 14, 10, 5),
          ),
        );

        final result = await LoadRuntimeDashboardUseCase(
          localControlOverlayStore: localControlOverlayStore,
          clock: () => DateTime(2026, 3, 14, 11, 0),
        ).execute();

        expect(
          result.cards.map((card) => card.serviceKey.value),
          isNot(contains('NETFLIX')),
        );
        expect(
          result.reviewQueue.map((item) => item.title),
          isNot(contains(reviewItem.title)),
        );
        expect(
          result.ignoredLocalItems.map((item) => item.title),
          containsAll(<String>['Netflix', reviewItem.title]),
        );
        expect(result.hiddenLocalItems, isEmpty);
      },
    );
  });
}

class _ThrowingDeviceSmsGateway implements DeviceSmsGateway {
  @override
  Future<List<RawDeviceSms>> readMessages() async {
    throw Exception('source read failed');
  }
}

class _CountingDeviceSmsGateway implements DeviceSmsGateway {
  _CountingDeviceSmsGateway(this.messages);

  final List<RawDeviceSms> messages;
  int readCount = 0;

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    readCount++;
    return messages;
  }
}


