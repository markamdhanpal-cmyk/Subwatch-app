import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/repositories/in_memory_service_evidence_bucket_repository.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';
import 'package:sub_killer/v2/decision/enums/decision_execution_mode.dart';
import 'package:sub_killer/v2/decision/use_cases/apply_v2_decision_snapshots_use_case.dart';

void main() {
  group('V2 decision ledger bridge', () {
    test('bridges confirmed paid snapshot into active paid ledger entry',
        () async {
      final bucketRepository = InMemoryServiceEvidenceBucketRepository();
      final ledgerRepository = InMemoryLedgerRepository();
      const useCase = ApplyV2DecisionSnapshotsUseCase();

      await bucketRepository.write(
        ServiceEvidenceBucket(
          serviceKey: const ServiceKey('NETFLIX'),
          firstSeenAt: DateTime(2026, 3, 1, 9),
          lastSeenAt: DateTime(2026, 4, 1, 9),
          lastBilledAt: DateTime(2026, 4, 1, 9),
          sourceKindsSeen: const <ServiceEvidenceSourceKind>[
            ServiceEvidenceSourceKind.deviceSmsInbox,
          ],
          billedCount: 2,
          renewalHintCount: 2,
          amountSeries: const <double>[499, 499],
          intervalHintsInDays: const <int>[31],
          evidenceTrail: EvidenceTrail(
            messageIds: <String>['nf-1', 'nf-2'],
            eventIds: <String>['event-1', 'event-2'],
            notes: <String>['fragment:billed_success'],
          ),
        ),
      );

      await ledgerRepository.write(
        ServiceLedgerEntry(
          serviceKey: const ServiceKey('NETFLIX'),
          state: ResolverState.activePaid,
          evidenceTrail: EvidenceTrail.empty(),
          totalBilled: 998,
        ),
      );

      final snapshots = await useCase.execute(
        bucketRepository: bucketRepository,
        ledgerRepository: ledgerRepository,
        mode: DecisionExecutionMode.bridgeToLedger,
      );

      expect(snapshots.single.serviceKey.value, 'NETFLIX');
      final entry = await ledgerRepository.read(const ServiceKey('NETFLIX'));
      expect(entry, isNotNull);
      expect(entry!.state, ResolverState.activePaid);
      expect(entry.totalBilled, 998);
      expect(entry.evidenceTrail.notes, contains('v2:band=confirmedPaid'));
    });

    test('shadow mode computes snapshots without mutating ledger', () async {
      final bucketRepository = InMemoryServiceEvidenceBucketRepository();
      final ledgerRepository = InMemoryLedgerRepository();
      const useCase = ApplyV2DecisionSnapshotsUseCase();

      await bucketRepository.write(
        ServiceEvidenceBucket(
          serviceKey: const ServiceKey('GOOGLE_PLAY'),
          firstSeenAt: DateTime(2026, 3, 1, 9),
          lastSeenAt: DateTime(2026, 3, 1, 9),
          sourceKindsSeen: const <ServiceEvidenceSourceKind>[
            ServiceEvidenceSourceKind.deviceSmsInbox,
          ],
          weakRecurringHintCount: 1,
          unknownReviewCount: 1,
          evidenceTrail: EvidenceTrail.empty(),
        ),
      );

      final snapshots = await useCase.execute(
        bucketRepository: bucketRepository,
        ledgerRepository: ledgerRepository,
        mode: DecisionExecutionMode.shadowOnly,
      );

      expect(snapshots.single.serviceKey.value, 'GOOGLE_PLAY');
      expect(await ledgerRepository.list(), isEmpty);
    });
  });
}

