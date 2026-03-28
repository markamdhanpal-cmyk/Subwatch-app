import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('DeterministicResolver', () {
    const resolver = DeterministicResolver();
    final occurredAt = DateTime(2026, 3, 12, 21, 0);

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

    ServiceLedgerEntry resolveAll(List<SubscriptionEvent> events) {
      ServiceLedgerEntry? current;
      for (final nextEvent in events) {
        current = resolver.resolve(event: nextEvent, currentEntry: current);
      }
      return current!;
    }

    test('one-time payment stays one-time', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'one-1',
          service: 'SHOPPING',
          type: SubscriptionEventType.oneTimePayment,
          amount: 149,
        ),
        event(
          id: 'one-2',
          service: 'SHOPPING',
          type: SubscriptionEventType.oneTimePayment,
          amount: 199,
        ),
      ]);

      expect(entry.state, ResolverState.oneTimeOnly);
      expect(entry.totalBilled, 0);
    });

    test('mandate created becomes pendingConversion', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'mandate-1',
          service: 'JIOHOTSTAR',
          type: SubscriptionEventType.mandateCreated,
        ),
      ]);

      expect(entry.state, ResolverState.pendingConversion);
    });

    test('micro execution becomes verificationOnly', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'micro-1',
          service: 'CRUNCHYROLL',
          type: SubscriptionEventType.mandateExecutedMicro,
          amount: 1,
        ),
      ]);

      expect(entry.state, ResolverState.verificationOnly);
    });

    test('setup path plus billed event becomes activePaid', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'setup-1',
          service: 'ADOBE_SYSTEMS',
          type: SubscriptionEventType.autopaySetup,
        ),
        event(
          id: 'bill-1',
          service: 'ADOBE_SYSTEMS',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 799,
        ),
      ]);

      expect(entry.state, ResolverState.activePaid);
      expect(entry.totalBilled, 799);
    });

    test('billed event alone becomes activePaid', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'bill-2',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 499,
        ),
      ]);

      expect(entry.state, ResolverState.activePaid);
      expect(entry.totalBilled, 499);
    });

    test('bundle event becomes activeBundled', () {
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'bundle-1',
          service: 'AIRTEL_BUNDLE',
          type: SubscriptionEventType.bundleActivated,
        ),
      ]);

      expect(entry.state, ResolverState.activeBundled);
    });
  });
}
