import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/resolver_pipeline_use_case.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('ResolverPipelineUseCase', () {
    late InMemoryLedgerRepository ledgerRepository;
    late ResolverPipelineUseCase useCase;
    final occurredAt = DateTime(2026, 3, 12, 21, 30);

    SubscriptionEvent event({
      required String id,
      required String service,
      required SubscriptionEventType type,
      double? amount,
    }) {
      return SubscriptionEvent(
        id: id,
        serviceKey: ServiceKey(service),
        type: type,
        occurredAt: occurredAt,
        sourceMessageId: 'msg-$id',
        amount: amount,
        evidenceTrail: EvidenceTrail(
          messageIds: <String>['msg-$id'],
          eventIds: <String>[id],
          notes: <String>[type.name],
        ),
      );
    }

    setUp(() {
      ledgerRepository = InMemoryLedgerRepository();
      useCase = ResolverPipelineUseCase(
        resolver: const DeterministicResolver(),
        ledgerRepository: ledgerRepository,
      );
    });

    test('creates a new ledger entry from the first event', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'first-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 499,
        ),
      ]);

      final entry = await ledgerRepository.read(const ServiceKey('NETFLIX'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.activePaid);
      expect(entry.totalBilled, 499);
    });

    test('updates an existing entry from a later event', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'update-1',
          service: 'ADOBE_SYSTEMS',
          type: SubscriptionEventType.mandateCreated,
        ),
      ]);

      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'update-2',
          service: 'ADOBE_SYSTEMS',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 799,
        ),
      ]);

      final entry = await ledgerRepository.read(const ServiceKey('ADOBE_SYSTEMS'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.activePaid);
      expect(entry.totalBilled, 799);
      expect(entry.evidenceTrail.eventIds, containsAll(<String>['update-1', 'update-2']));
    });

    test('mandate path followed by billed event becomes activePaid', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'path-1',
          service: 'CRUNCHYROLL',
          type: SubscriptionEventType.autopaySetup,
        ),
        event(
          id: 'path-2',
          service: 'CRUNCHYROLL',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 99,
        ),
      ]);

      final entry = await ledgerRepository.read(const ServiceKey('CRUNCHYROLL'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.activePaid);
    });

    test('one-time payment remains non-paid', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'one-time-1',
          service: 'SHOPPING',
          type: SubscriptionEventType.oneTimePayment,
          amount: 149,
        ),
      ]);

      final entry = await ledgerRepository.read(const ServiceKey('SHOPPING'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.oneTimeOnly);
      expect(entry.totalBilled, 0);
    });

    test('bundle event becomes activeBundled', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'bundle-1',
          service: 'AIRTEL_BUNDLE',
          type: SubscriptionEventType.bundleActivated,
        ),
      ]);

      final entry = await ledgerRepository.read(const ServiceKey('AIRTEL_BUNDLE'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.activeBundled);
    });

    test('separate service keys do not merge', () async {
      await useCase.execute(<SubscriptionEvent>[
        event(
          id: 'separate-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 499,
        ),
        event(
          id: 'separate-2',
          service: 'YOUTUBE_PREMIUM',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 149,
        ),
      ]);

      final entries = await ledgerRepository.list();
      expect(entries, hasLength(2));
      expect(entries.map((entry) => entry.serviceKey.value), containsAll(<String>[
        'NETFLIX',
        'YOUTUBE_PREMIUM',
      ]));
      expect(entries.firstWhere((entry) => entry.serviceKey.value == 'NETFLIX').totalBilled, 499);
      expect(
        entries.firstWhere((entry) => entry.serviceKey.value == 'YOUTUBE_PREMIUM').totalBilled,
        149,
      );
    });
  });
}
