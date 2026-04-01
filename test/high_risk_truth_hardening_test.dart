import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_totals_summary_use_case.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/billing_cadence.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('High-Risk Truth Hardening Pass', () {
    final eventPipeline = EventPipelineUseCase();
    const resolver = DeterministicResolver();
    const projection = DeterministicDashboardProjection();
    const totalsUseCase = BuildDashboardTotalsSummaryUseCase();

    test('Annual Recovery: Lone message Hotstar 1499 triggers activePaid', () {
      final message = MessageRecord(
        id: 'msg1',
        sourceAddress: 'AD-HOTSTR',
        body: 'Success! Your Hotstar Super annual plan has been renewed for Rs. 1499. Enjoy!',
        receivedAt: DateTime(2024, 3, 1),
      );

      final events = eventPipeline.execute([message]);
      expect(events, hasLength(1));
      expect(events.first.type, SubscriptionEventType.subscriptionBilled);
      expect(events.first.amount, 1499.0);

      final entry = resolver.resolve(event: events.first);
      expect(entry.state, ResolverState.activePaid);
      expect(entry.billingCadence, BillingCadence.annual);

      final cards = projection.buildCards([entry]);
      expect(cards.first.bucket, DashboardBucket.confirmedSubscriptions);
      expect(cards.first.structuredCadence, BillingCadence.annual);
    });

    test('Shadowing & Vetoes: UPI QR noise is NOT incorrectly caught as Billed', () {
      final message = MessageRecord(
        id: 'msg2',
        sourceAddress: 'HDFCBK',
        body: 'Paid Rs. 149 to NETFLIX via UPI QR at Merchant Store. Ref: 12345.',
        receivedAt: DateTime(2024, 3, 2),
      );

      final events = eventPipeline.execute([message]);
      
      // Should either be null (ignored) or marked as one-time/ignore, 
      // but NOT SubscriptionEventType.subscriptionBilled.
      if (events.isNotEmpty) {
        expect(events.first.type, isNot(SubscriptionEventType.subscriptionBilled));
      }
    });

    test('Shadowing & Vetoes: Legitimate Billed via UPI is caught despite noise', () {
      final message = MessageRecord(
        id: 'msg3',
        sourceAddress: 'V-PROCES',
        body: 'Your Netflix monthly subscription for Rs. 199 has been processed via UPI Autopay successfully.',
        receivedAt: DateTime(2024, 3, 3),
      );

      final events = eventPipeline.execute([message]);
      expect(events, hasLength(1));
      expect(events.first.type, SubscriptionEventType.subscriptionBilled);
      expect(events.first.amount, 199.0);
    });

    test('Cadence Totals: Weekly equivalents are calculated correctly (Amount * 4.33)', () {
      final cards = <DashboardCard>[
        DashboardCard(
          serviceKey: const ServiceKey('WEEKLY_TEST'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'Weekly Sub',
          subtitle: 'Confirmed',
          state: ResolverState.activePaid,
          structuredAmount: 100,
          structuredCadence: BillingCadence.weekly,
        ),
      ];
      
      final totals = totalsUseCase.execute(cards: cards);
      expect(totals.monthlyTotalAmount, closeTo(433.0, 0.01));
    });

    test('Cadence Totals: Quarterly, Semi-Annual, and Annual are pro-rated correctly', () {
      final cards = <DashboardCard>[
        const DashboardCard(
          serviceKey: ServiceKey('Q'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'Q',
          subtitle: 'Q',
          state: ResolverState.activePaid,
          structuredAmount: 300,
          structuredCadence: BillingCadence.quarterly,
        ),
        const DashboardCard(
          serviceKey: ServiceKey('S'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'S',
          subtitle: 'S',
          state: ResolverState.activePaid,
          structuredAmount: 600,
          structuredCadence: BillingCadence.semiAnnual,
        ),
        const DashboardCard(
          serviceKey: ServiceKey('A'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'A',
          subtitle: 'A',
          state: ResolverState.activePaid,
          structuredAmount: 1200,
          structuredCadence: BillingCadence.annual,
        ),
      ];
      
      final totals = totalsUseCase.execute(cards: cards);
      // Q (300/3 = 100) + S (600/6 = 100) + A (1200/12 = 100) = 300
      expect(totals.monthlyTotalAmount, 300.0);
      expect(totals.cadenceConvertedCount, 3);
    });

    test('Ended State: Unsubscribed signal moves to Ended Bucket and persists', () {
      final b1 = MessageRecord(
        id: 'b1',
        sourceAddress: 'AD-YOUTUB',
        body: 'Success! Your Youtube Premium subscription for Rs. 129 has been processed.',
        receivedAt: DateTime(2024, 1, 1),
      );
      final c1 = MessageRecord(
        id: 'c1',
        sourceAddress: 'AD-YOUTUB',
        body: 'You have successfully unsubscribed from Youtube Premium. We look forward to seeing you again.',
        receivedAt: DateTime(2024, 1, 2),
      );

      final e1 = eventPipeline.execute([b1]).first;
      final e2 = eventPipeline.execute([c1]).first;

      final entry1 = resolver.resolve(event: e1);
      final entry2 = resolver.resolve(event: e2, currentEntry: entry1);

      expect(entry2.state, ResolverState.cancelled);
      
      final cards = projection.buildCards([entry2]);
      expect(cards.first.bucket, DashboardBucket.endedSubscriptions);
      
      // Late bundle signal shouldn't resurrect it
      final b2 = MessageRecord(
        id: 'b2',
        sourceAddress: 'AD-YOUTUB',
        body: 'Enjoy your Hotstar bundle benefit enabled by your Jio recharge.',
        receivedAt: DateTime(2024, 1, 3),
      );
      final e3 = eventPipeline.execute([b2]).first;
      final entry3 = resolver.resolve(event: e3, currentEntry: entry2);
      expect(entry3.state, ResolverState.cancelled);
    });
  });
}
