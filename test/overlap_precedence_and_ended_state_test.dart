import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('Overlap Precedence and Ended State Regression', () {
    const resolver = DeterministicResolver();
    const projection = DeterministicDashboardProjection();
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

    test('activePaid takes precedence over activeBundled (Paid Wins)', () {
      // Scenario: User has a bundled benefit but then starts paying directly.
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'bundle-1',
          service: 'JIOHOTSTAR',
          type: SubscriptionEventType.bundleActivated,
        ),
        event(
          id: 'bill-1',
          service: 'JIOHOTSTAR',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 149,
        ),
      ]);

      expect(entry.state, ResolverState.activePaid);
      expect(entry.totalBilled, 149);
      expect(projection.bucketForState(entry.state), DashboardBucket.confirmedSubscriptions);
    });

    test('activePaid stays activePaid even if bundle event arrives later', () {
      // Scenario: User is already paying, and a bundle signal arrives (duplicate or late).
      // Paid should still win to ensure it stays in Confirmed bucket.
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'bill-1',
          service: 'JIOHOTSTAR',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 149,
        ),
        event(
          id: 'bundle-1',
          service: 'JIOHOTSTAR',
          type: SubscriptionEventType.bundleActivated,
        ),
      ]);

      expect(entry.state, ResolverState.activePaid);
      expect(projection.bucketForState(entry.state), DashboardBucket.confirmedSubscriptions);
    });

    test('subscriptionCancelled moves state to cancelled (Ended Bucket)', () {
      // Scenario: Active subscription is cancelled.
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'bill-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionBilled,
          amount: 499,
        ),
        event(
          id: 'cancel-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionCancelled,
        ),
      ]);

      expect(entry.state, ResolverState.cancelled);
      expect(projection.bucketForState(entry.state), DashboardBucket.endedSubscriptions);
    });

    test('cancelled state persists even if bundle signals arrive after cancellation', () {
      // Scenario: Subscription ended, but some system still sends automated bundle notifications.
      final entry = resolveAll(<SubscriptionEvent>[
        event(
          id: 'cancel-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.subscriptionCancelled,
        ),
        event(
          id: 'bundle-1',
          service: 'NETFLIX',
          type: SubscriptionEventType.bundleActivated,
        ),
      ]);

      expect(entry.state, ResolverState.cancelled);
    });

    test('Needs Review items map to Review bucket and are hidden from primary list', () {
      // verified via domain mapping
      expect(projection.bucketForState(ResolverState.verificationOnly), DashboardBucket.needsReview);
      expect(projection.bucketForState(ResolverState.pendingConversion), DashboardBucket.needsReview);
    });
  });
}
