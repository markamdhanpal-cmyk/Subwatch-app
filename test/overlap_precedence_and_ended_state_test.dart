import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('Overlap Precedence and Ended State Regression', () {
    late LocalIngestionFlowUseCase useCase;
    const projection = DeterministicDashboardProjection();

    setUp(() {
      useCase = LocalIngestionFlowUseCase();
    });

    test('subscriptionCancelled moves state to cancelled (Ended Bucket)',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: 'bill-1',
          sourceAddress: 'AD-NETFLX',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2024, 1, 1),
        ),
        MessageRecord(
          id: 'cancel-1',
          sourceAddress: 'AD-NETFLX',
          body: 'You have cancelled your Netflix subscription successfully.',
          receivedAt: DateTime(2024, 1, 2),
        ),
      ]);

      final entry = result.ledgerEntries
          .firstWhere((candidate) => candidate.serviceKey.value == 'NETFLIX');
      expect(entry.state, ResolverState.cancelled);
      expect(
        projection.bucketForState(entry.state),
        DashboardBucket.endedSubscriptions,
      );
    });

    test('cancelled state persists across later weak lifecycle reminders',
        () async {
      await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: 'bill-2',
          sourceAddress: 'AD-NETFLX',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2024, 2, 1),
        ),
        MessageRecord(
          id: 'cancel-2',
          sourceAddress: 'AD-NETFLX',
          body: 'You have cancelled your Netflix subscription successfully.',
          receivedAt: DateTime(2024, 2, 2),
        ),
      ]);

      final secondPass = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: 'weak-1',
          sourceAddress: 'AD-NETFLX',
          body: 'Your subscription may renew shortly.',
          receivedAt: DateTime(2024, 2, 3),
        ),
      ]);

      final entry = secondPass.ledgerEntries
          .firstWhere((candidate) => candidate.serviceKey.value == 'NETFLIX');
      expect(entry.state, ResolverState.cancelled);
    });

    test('Needs Review items map to Review bucket and stay off primary list', () {
      final pending = ServiceLedgerEntry(
        serviceKey: const ServiceKey('JIOHOTSTAR'),
        state: ResolverState.pendingConversion,
        evidenceTrail: EvidenceTrail.empty(),
      );
      final verification = ServiceLedgerEntry(
        serviceKey: const ServiceKey('CRUNCHYROLL'),
        state: ResolverState.verificationOnly,
        evidenceTrail: EvidenceTrail.empty(),
      );

      expect(
        projection.bucketForState(pending.state),
        DashboardBucket.needsReview,
      );
      expect(
        projection.bucketForState(verification.state),
        DashboardBucket.needsReview,
      );
    });
  });
}

