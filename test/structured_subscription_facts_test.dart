import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/enums/billing_cadence.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_totals_summary_use_case.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_upcoming_renewals_use_case.dart';
import 'package:sub_killer/v2/decision/bridges/decision_snapshot_ledger_bridge.dart';
import 'package:sub_killer/v2/decision/enums/decision_band.dart';
import 'package:sub_killer/v2/decision/models/decision_snapshot.dart';
import 'package:sub_killer/v2/scoring/models/subscription_score.dart';

void main() {
  group('Phase 1: Structured subscription facts', () {
    group('BillingCadence enum', () {
      test('has all expected values', () {
        expect(BillingCadence.values, containsAll([
          BillingCadence.weekly,
          BillingCadence.monthly,
          BillingCadence.quarterly,
          BillingCadence.semiAnnual,
          BillingCadence.annual,
          BillingCadence.unknown,
        ]));
      });

      test('fromIntervalDays infers correct cadence', () {
        expect(BillingCadence.fromIntervalDays(7), BillingCadence.weekly);
        expect(BillingCadence.fromIntervalDays(30), BillingCadence.monthly);
        expect(BillingCadence.fromIntervalDays(90), BillingCadence.quarterly);
        expect(BillingCadence.fromIntervalDays(180), BillingCadence.semiAnnual);
        expect(BillingCadence.fromIntervalDays(365), BillingCadence.annual);
        expect(BillingCadence.fromIntervalDays(15), BillingCadence.unknown);
      });

      test('fromNotes infers correct cadence', () {
        expect(BillingCadence.fromNotes(['annual plan']), BillingCadence.annual);
        expect(BillingCadence.fromNotes(['monthly renewal']), BillingCadence.monthly);
        expect(BillingCadence.fromNotes(['every 3 months']), BillingCadence.quarterly);
        expect(BillingCadence.fromNotes(['none']), BillingCadence.unknown);
      });
    });

    group('ServiceLedgerEntry structured fields', () {
      test('defaults lastBilledAmount to null and cadence to unknown', () {
        final entry = ServiceLedgerEntry(
          serviceKey: const ServiceKey('TEST'),
          state: ResolverState.activePaid,
          evidenceTrail: EvidenceTrail.empty(),
        );
        expect(entry.lastBilledAmount, isNull);
        expect(entry.billingCadence, BillingCadence.unknown);
      });

      test('carries structured amount, cadence and renewal through copyWith', () {
        final entry = ServiceLedgerEntry(
          serviceKey: const ServiceKey('TEST'),
          state: ResolverState.activePaid,
          evidenceTrail: EvidenceTrail.empty(),
          lastBilledAmount: 499,
          billingCadence: BillingCadence.monthly,
          nextRenewalDate: DateTime(2024, 4, 15),
        );
        final copied = entry.copyWith(billingCadence: BillingCadence.annual);
        expect(copied.lastBilledAmount, 499);
        expect(copied.billingCadence, BillingCadence.annual);
        expect(copied.nextRenewalDate, DateTime(2024, 4, 15));
      });
    });

    group('DashboardCard structured fields', () {
      test('defaults structuredCadence to unknown', () {
        const card = DashboardCard(
          serviceKey: ServiceKey('TEST'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'Test',
          subtitle: 'Test sub',
          state: ResolverState.activePaid,
        );
        expect(card.structuredAmount, isNull);
        expect(card.structuredCadence, BillingCadence.unknown);
      });

      test('carries structured fields when constructed', () {
        final card = DashboardCard(
          serviceKey: const ServiceKey('TEST'),
          bucket: DashboardBucket.confirmedSubscriptions,
          title: 'Test',
          subtitle: 'Confirmed',
          state: ResolverState.activePaid,
          structuredAmount: 1499,
          structuredCadence: BillingCadence.annual,
          structuredNextRenewalDate: DateTime(2024, 5, 20),
        );
        expect(card.structuredAmount, 1499);
        expect(card.structuredCadence, BillingCadence.annual);
        expect(card.structuredNextRenewalDate, DateTime(2024, 5, 20));
      });
    });

    group('DeterministicResolver structured fact wiring', () {
      const resolver = DeterministicResolver();

      test('sets lastBilledAmount from billed event', () {
        final event = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('NETFLIX'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 3, 15),
          sourceMessageId: 'm1',
          amount: 649,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final result = resolver.resolve(event: event);
        expect(result.lastBilledAmount, 649);
        expect(result.state, ResolverState.activePaid);
      });

      test('does not set lastBilledAmount for non-billed events', () {
        final event = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('SOMETHING'),
          type: SubscriptionEventType.mandateCreated,
          occurredAt: DateTime(2024, 3, 15),
          sourceMessageId: 'm1',
          amount: 500,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final result = resolver.resolve(event: event);
        expect(result.lastBilledAmount, isNull);
      });

      test('infers monthly cadence from 30-day intervals', () {
        final first = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('NETFLIX'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 1, 15),
          sourceMessageId: 'm1',
          amount: 649,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final firstEntry = resolver.resolve(event: first);

        final second = SubscriptionEvent(
          id: 'e2',
          serviceKey: const ServiceKey('NETFLIX'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 2, 14),
          sourceMessageId: 'm2',
          amount: 649,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final result = resolver.resolve(event: second, currentEntry: firstEntry);
        expect(result.billingCadence, BillingCadence.monthly);
        expect(result.lastBilledAmount, 649);
      });

      test('infers annual cadence from 365-day intervals', () {
        final first = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('HOTSTAR'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2023, 3, 15),
          sourceMessageId: 'm1',
          amount: 1499,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final firstEntry = resolver.resolve(event: first);

        final second = SubscriptionEvent(
          id: 'e2',
          serviceKey: const ServiceKey('HOTSTAR'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 3, 15),
          sourceMessageId: 'm2',
          amount: 1499,
          evidenceTrail: EvidenceTrail.empty(),
        );
        final result = resolver.resolve(event: second, currentEntry: firstEntry);
        expect(result.billingCadence, BillingCadence.annual);
      });

      test('infers cadence from evidence trail notes', () {
        final event = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('YOUTUBE'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 3, 15),
          sourceMessageId: 'm1',
          amount: 1290,
          evidenceTrail: EvidenceTrail(
            messageIds: const ['m1'],
            notes: const ['annual plan renewed'],
          ),
        );
        final result = resolver.resolve(event: event);
        expect(result.billingCadence, BillingCadence.annual);
      });

      test('calculates next renewal date from cadence', () {
        final event = SubscriptionEvent(
          id: 'e1',
          serviceKey: const ServiceKey('NETFLIX'),
          type: SubscriptionEventType.subscriptionBilled,
          occurredAt: DateTime(2024, 3, 15),
          sourceMessageId: 'm1',
          amount: 649,
          evidenceTrail: EvidenceTrail(
            messageIds: const ['m1'],
            notes: const ['monthly'],
          ),
        );
        final result = resolver.resolve(event: event);
        expect(result.nextRenewalDate, DateTime(2024, 4, 15));
      });
    });

    group('DeterministicDashboardProjection structured wiring', () {
      const projection = DeterministicDashboardProjection();

      test('passes structured fields from ledger entry to card', () {
        final entry = ServiceLedgerEntry(
          serviceKey: const ServiceKey('NETFLIX'),
          state: ResolverState.activePaid,
          evidenceTrail: EvidenceTrail.empty(),
          totalBilled: 1298,
          lastBilledAmount: 649,
          billingCadence: BillingCadence.monthly,
        );
        final cards = projection.buildCards([entry]);
        expect(cards, hasLength(1));
        expect(cards.first.structuredAmount, 649);
        expect(cards.first.structuredCadence, BillingCadence.monthly);
      });
    });

    group('BuildDashboardTotalsSummaryUseCase uses structured data', () {
      const useCase = BuildDashboardTotalsSummaryUseCase();

      test('totals use structured amount instead of subtitle parsing', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle: 'Confirmed paid subscription',
            state: ResolverState.activePaid,
            structuredAmount: 649,
            structuredCadence: BillingCadence.monthly,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, 649);
        expect(result.includedInMonthlyTotalCount, 1);
        expect(result.excludedWithoutTrustedAmountCount, 0);
      });

      test('does not try to parse subtitle string for amount', () {
        // This card has an amount in the subtitle but NO structured amount.
        // The use case must NOT extract from the subtitle.
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('TEST'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Test',
            subtitle: 'Confirmed paid subscription - \u20B9999',
            state: ResolverState.activePaid,
            // No structuredAmount => excluded
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, 0);
        expect(result.excludedWithoutTrustedAmountCount, 1);
      });

      test('converts annual cadence to monthly equivalent', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('HOTSTAR'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Hotstar',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 1499,
            structuredCadence: BillingCadence.annual,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, closeTo(1499 / 12, 0.01));
        expect(result.cadenceConvertedCount, 1);
      });

      test('converts quarterly cadence to monthly equivalent', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('SERVICE'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Service',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 900,
            structuredCadence: BillingCadence.quarterly,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, 300);
        expect(result.cadenceConvertedCount, 1);
      });

      test('converts semi-annual cadence to monthly equivalent', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('SERVICE'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Service',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 1200,
            structuredCadence: BillingCadence.semiAnnual,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, 200);
        expect(result.cadenceConvertedCount, 1);
      });

      test('treats unknown cadence as inferred monthly', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('SERVICE'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Service',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 199,
            structuredCadence: BillingCadence.unknown,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, 199);
        expect(result.inferredMonthlyCount, 1);
      });

      test('multiple subscriptions with mixed cadences', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 649,
            structuredCadence: BillingCadence.monthly,
          ),
          const DashboardCard(
            serviceKey: ServiceKey('HOTSTAR'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Hotstar',
            subtitle: 'Confirmed',
            state: ResolverState.activePaid,
            structuredAmount: 1499,
            structuredCadence: BillingCadence.annual,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.monthlyTotalAmount, closeTo(649 + 1499 / 12, 0.01));
        expect(result.includedInMonthlyTotalCount, 2);
        expect(result.cadenceConvertedCount, 1);
      });
    });

    group('DecisionSnapshotLedgerBridge inference', () {
      const bridge = DecisionSnapshotLedgerBridge();

      test('infers cadence from bucket interval hints', () {
        final snapshot = DecisionSnapshot(
          serviceKey: const ServiceKey('NETFLIX'),
          band: DecisionBand.confirmedPaid,
          decidedAt: DateTime(2024, 3, 15),
          lastBilledAt: DateTime(2024, 3, 15),
          reasonCodes: const [],
          notes: const [],
          evidenceTrail: EvidenceTrail.empty(),
          subscriptionScore: SubscriptionScore(
            modelVersion: 'v1',
            featureSchemaVersion: 1,
            subscriptionProbability: 1.0,
            reviewPriorityScore: 0.0,
          ),
          sourceBucket: ServiceEvidenceBucket(
            serviceKey: const ServiceKey('NETFLIX'),
            firstSeenAt: DateTime(2024, 1, 1),
            lastSeenAt: DateTime(2024, 3, 15),
            sourceKindsSeen: const [],
            evidenceTrail: EvidenceTrail.empty(),
            intervalHintsInDays: const [30],
          ),
        );
        final result = bridge.map(snapshot: snapshot);
        expect(result.billingCadence, BillingCadence.monthly);
        expect(result.nextRenewalDate, DateTime(2024, 4, 15));
      });

      test('infers cadence from snapshot notes with priority over intervals', () {
        final snapshot = DecisionSnapshot(
          serviceKey: const ServiceKey('NETFLIX'),
          band: DecisionBand.confirmedPaid,
          decidedAt: DateTime(2024, 3, 15),
          lastBilledAt: DateTime(2024, 3, 15),
          reasonCodes: const [],
          notes: const ['annual plan'],
          evidenceTrail: EvidenceTrail.empty(),
          subscriptionScore: SubscriptionScore(
            modelVersion: 'v1',
            featureSchemaVersion: 1,
            subscriptionProbability: 1.0,
            reviewPriorityScore: 0.0,
          ),
          sourceBucket: ServiceEvidenceBucket(
            serviceKey: const ServiceKey('NETFLIX'),
            firstSeenAt: DateTime(2024, 1, 1),
            lastSeenAt: DateTime(2024, 3, 15),
            sourceKindsSeen: const [],
            evidenceTrail: EvidenceTrail.empty(),
            intervalHintsInDays: const [30],
          ),
        );
        final result = bridge.map(snapshot: snapshot);
        expect(result.billingCadence, BillingCadence.annual);
        expect(result.nextRenewalDate, DateTime(2025, 3, 15));
      });
    });

    group('BuildDashboardUpcomingRenewalsUseCase structured fact priority', () {
      final useCase = BuildDashboardUpcomingRenewalsUseCase(
        clock: () => DateTime(2024, 3, 14),
      );

      test('uses structuredNextRenewalDate when available', () {
        final cards = <DashboardCard>[
          DashboardCard(
            serviceKey: const ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle: 'Confirmed', // No date in subtitle
            state: ResolverState.activePaid,
            structuredNextRenewalDate: DateTime(2024, 3, 15),
            structuredAmount: 649,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.items, hasLength(1));
        expect(result.items.first.renewalDate, DateTime(2024, 3, 15));
        expect(result.items.first.amountLabel, '\u20B9649');
      });

      test('falls back to subtitle parsing if structured date is missing', () {
        final cards = <DashboardCard>[
          const DashboardCard(
            serviceKey: ServiceKey('NETFLIX'),
            bucket: DashboardBucket.confirmedSubscriptions,
            title: 'Netflix',
            subtitle: 'Confirmed - Renews on 20 Mar 2024',
            state: ResolverState.activePaid,
            structuredAmount: 649,
          ),
        ];
        final result = useCase.execute(cards: cards);
        expect(result.items, hasLength(1));
        expect(result.items.first.renewalDate, DateTime(2024, 3, 20));
      });
    });
  });
}
