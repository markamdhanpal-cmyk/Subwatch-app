import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/repositories/in_memory_service_evidence_bucket_repository.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('Service evidence bucket accumulation', () {
    test('accumulates repeated paid evidence for one service deterministically',
        () async {
      final repository = InMemoryServiceEvidenceBucketRepository();
      final useCase = LocalIngestionFlowUseCase(
        serviceEvidenceBucketRepository: repository,
      );

      await useCase.executeCanonicalInputs(<CanonicalInput>[
        CanonicalInput.deviceSms(
          id: 'nf-1',
          senderHandle: 'BANK',
          textBody: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2026, 3, 1, 8, 0),
        ),
        CanonicalInput.deviceSms(
          id: 'nf-2',
          senderHandle: 'BANK',
          textBody: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2026, 4, 1, 8, 0),
        ),
      ]);

      final buckets = await repository.list();

      expect(buckets, hasLength(1));
      expect(buckets.single.serviceKey.value, 'NETFLIX');
      expect(buckets.single.billedCount, 2);
      expect(buckets.single.renewalHintCount, 2);
      expect(buckets.single.amountSeries, <double>[499, 499]);
      expect(buckets.single.intervalHintsInDays, <int>[31]);
      expect(
        buckets.single.sourceKindsSeen,
        <ServiceEvidenceSourceKind>[ServiceEvidenceSourceKind.deviceSmsInbox],
      );
      expect(
        buckets.single.evidenceTrail.notes,
        contains('fragment:billed_success'),
      );
      expect(
        buckets.single.evidenceTrail.messageIds,
        containsAll(<String>['nf-1', 'nf-2']),
      );
    });

    test('tracks contradictions instead of erasing conflicting evidence',
        () async {
      final repository = InMemoryServiceEvidenceBucketRepository();
      final useCase = LocalIngestionFlowUseCase(
        serviceEvidenceBucketRepository: repository,
      );

      await useCase.executeCanonicalInputs(<CanonicalInput>[
        CanonicalInput.deviceSms(
          id: 'jh-paid-1',
          senderHandle: 'BANK',
          textBody: 'Your JioHotstar subscription has been renewed for Rs 299.',
          receivedAt: DateTime(2026, 3, 10, 9, 0),
        ),
        CanonicalInput.deviceSms(
          id: 'jh-bundle-1',
          senderHandle: 'TELCO',
          textBody:
              'Your 1-month JioHotstar subscription is now activated. Your recent recharge has unlocked this benefit.',
          receivedAt: DateTime(2026, 3, 12, 9, 0),
        ),
      ]);

      final bucket = (await repository.list()).single;

      expect(bucket.serviceKey.value, 'JIOHOTSTAR');
      expect(bucket.billedCount, 1);
      expect(bucket.bundleCount, 1);
      expect(bucket.contradictions, contains('paid_vs_bundle'));
    });
  });
}
