import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_ledger_repository.dart';
import 'package:sub_killer/application/use_cases/project_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/projections/deterministic_dashboard_projection.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('DeterministicDashboardProjection', () {
    const projection = DeterministicDashboardProjection();

    ServiceLedgerEntry entry({
      required String key,
      required ResolverState state,
      double totalBilled = 0,
    }) {
      return ServiceLedgerEntry(
        serviceKey: ServiceKey(key),
        state: state,
        evidenceTrail: EvidenceTrail.empty(),
        totalBilled: totalBilled,
      );
    }

    test('maps activePaid to confirmedSubscriptions', () {
      final card = projection.buildCards(<ServiceLedgerEntry>[
        entry(
            key: 'NETFLIX', state: ResolverState.activePaid, totalBilled: 499),
      ]).single;

      expect(card.bucket, DashboardBucket.confirmedSubscriptions);
    });

    test('maps pendingConversion to needsReview', () {
      final card = projection.buildCards(<ServiceLedgerEntry>[
        entry(key: 'JIOHOTSTAR', state: ResolverState.pendingConversion),
      ]).single;

      expect(card.bucket, DashboardBucket.needsReview);
    });

    test('maps verificationOnly to needsReview', () {
      final card = projection.buildCards(<ServiceLedgerEntry>[
        entry(key: 'CRUNCHYROLL', state: ResolverState.verificationOnly),
      ]).single;

      expect(card.bucket, DashboardBucket.needsReview);
    });

    test('maps activeBundled to trialsAndBenefits', () {
      final card = projection.buildCards(<ServiceLedgerEntry>[
        entry(key: 'AIRTEL_BUNDLE', state: ResolverState.activeBundled),
      ]).single;

      expect(card.bucket, DashboardBucket.trialsAndBenefits);
    });

    test('maps ignored oneTimeOnly and cancelled to hidden', () {
      final cards = projection.buildCards(<ServiceLedgerEntry>[
        entry(key: 'IGNORED', state: ResolverState.ignored),
        entry(key: 'SHOPPING', state: ResolverState.oneTimeOnly),
        entry(key: 'OLD_SUB', state: ResolverState.cancelled),
      ]);

      expect(
          cards.every((card) => card.bucket == DashboardBucket.hidden), isTrue);
    });

    test('projects multiple ledger entries into correct grouped buckets',
        () async {
      final repository = InMemoryLedgerRepository();
      await repository.write(
        entry(
            key: 'NETFLIX', state: ResolverState.activePaid, totalBilled: 499),
      );
      await repository.write(
        entry(key: 'JIOHOTSTAR', state: ResolverState.pendingConversion),
      );
      await repository.write(
        entry(key: 'CRUNCHYROLL', state: ResolverState.verificationOnly),
      );
      await repository.write(
        entry(key: 'AIRTEL_BUNDLE', state: ResolverState.activeBundled),
      );
      await repository.write(
        entry(key: 'SHOPPING', state: ResolverState.oneTimeOnly),
      );

      final result = await ProjectDashboardUseCase(
        ledgerRepository: repository,
        dashboardProjection: projection,
      ).execute();

      expect(
        result.cards
            .where(
                (card) => card.bucket == DashboardBucket.confirmedSubscriptions)
            .map((card) => card.serviceKey.value),
        <String>['NETFLIX'],
      );
      expect(
        result.cards
            .where((card) => card.bucket == DashboardBucket.needsReview)
            .map((card) => card.serviceKey.value),
        containsAll(<String>['CRUNCHYROLL', 'JIOHOTSTAR']),
      );
      expect(
        result.cards
            .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
            .map((card) => card.serviceKey.value),
        <String>['AIRTEL_BUNDLE'],
      );
      expect(
        result.cards
            .where((card) => card.bucket == DashboardBucket.hidden)
            .map((card) => card.serviceKey.value),
        <String>['SHOPPING'],
      );
    });
  });
}
