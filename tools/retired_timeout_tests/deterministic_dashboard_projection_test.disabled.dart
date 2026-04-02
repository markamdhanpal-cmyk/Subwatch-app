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
      final card = projection
          .buildCards(<ServiceLedgerEntry>[
            entry(
              key: 'NETFLIX',
              state: ResolverState.activePaid,
              totalBilled: 499,
            ),
          ])
          .single;

      expect(card.bucket, DashboardBucket.confirmedSubscriptions);
    });

    test('does not surface unresolved service keys as dashboard cards', () {
      final cards = projection.buildCards(<ServiceLedgerEntry>[
        entry(key: 'UNRESOLVED', state: ResolverState.pendingConversion),
        entry(key: 'NETFLIX', state: ResolverState.activePaid, totalBilled: 499),
      ]);

      expect(cards.map((card) => card.serviceKey.value), <String>['NETFLIX']);
    });

    test('projects mixed entries into expected buckets', () async {
      final repository = InMemoryLedgerRepository();
      await repository.write(
        entry(key: 'NETFLIX', state: ResolverState.activePaid, totalBilled: 499),
      );
      await repository.write(
        entry(key: 'JIOHOTSTAR', state: ResolverState.pendingConversion),
      );
      await repository.write(
        entry(key: 'AIRTEL_BUNDLE', state: ResolverState.activeBundled),
      );

      final result = await ProjectDashboardUseCase(
        ledgerRepository: repository,
        dashboardProjection: projection,
      ).execute();

      final byKey = <String, DashboardBucket>{
        for (final card in result.cards) card.serviceKey.value: card.bucket,
      };

      expect(byKey['NETFLIX'], DashboardBucket.confirmedSubscriptions);
      expect(byKey['JIOHOTSTAR'], DashboardBucket.needsReview);
      expect(byKey['AIRTEL_BUNDLE'], DashboardBucket.trialsAndBenefits);
    });
  });
}