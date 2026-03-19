import 'dart:io';

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
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('LoadRuntimeDashboardUseCase persistence', () {
    late Directory tempDirectory;
    late JsonFileLedgerSnapshotStore store;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'sub-killer-runtime-',
      );
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
              subtitle: 'Confirmed paid subscription - Rs 499',
              state: ResolverState.activePaid,
            ),
            DashboardCard(
              serviceKey: ServiceKey('YOUTUBE_PREMIUM'),
              bucket: DashboardBucket.confirmedSubscriptions,
              title: 'YouTube Premium',
              subtitle: 'Confirmed paid subscription - Rs 129',
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
        final unresolvedReview = seedSnapshot.reviewQueue.firstWhere(
          (item) => item.serviceKey.value == 'UNRESOLVED',
        );

        await localControlOverlayStore.save(
          LocalControlDecision.ignoreService(
            card: DashboardCard(
              serviceKey: const ServiceKey('NETFLIX'),
              bucket: DashboardBucket.confirmedSubscriptions,
              title: 'Netflix',
              subtitle: 'Confirmed paid subscription - Rs 499',
              state: ResolverState.activePaid,
            ),
            decidedAt: DateTime(2026, 3, 14, 10, 0),
          ),
        );
        await localControlOverlayStore.save(
          LocalControlDecision.ignoreReviewItem(
            reviewItem: unresolvedReview,
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
          isNot(contains('Unresolved')),
        );
        expect(
          result.ignoredLocalItems.map((item) => item.title),
          containsAll(<String>['Netflix', 'Unresolved']),
        );
        expect(result.hiddenLocalItems, isEmpty);
      },
    );
  });
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


