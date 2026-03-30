import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/app_store_subscription_source.dart';
import 'package:sub_killer/application/contracts/receipt_like_input_source.dart';
import 'package:sub_killer/application/models/receipt_adapter_models.dart';
import 'package:sub_killer/application/repositories/in_memory_service_evidence_bucket_repository.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/v2/detection/bridges/app_store_subscription_canonical_input_source_adapter.dart';
import 'package:sub_killer/v2/detection/bridges/receipt_like_canonical_input_source_adapter.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('Receipt and app store adapter foundation', () {
    test('receipt adapter maps email and manual receipt inputs to canonical inputs',
        () async {
      final adapter = ReceiptLikeCanonicalInputSourceAdapter(
        source: _FakeReceiptLikeInputSource(
          <ReceiptLikeInputRecord>[
            ReceiptLikeInputRecord(
              id: 'receipt-email-1',
              kind: ReceiptLikeInputKind.emailReceipt,
              receivedAt: DateTime(2026, 3, 21, 8, 30),
              subject: 'Netflix receipt',
              body: 'Your Netflix subscription renewed successfully for Rs 499.',
              senderHandle: 'billing@netflix.com',
              sourceLabel: 'gmail_receipts',
              batchId: 'receipt-batch-1',
              receiptReference: 'NFX-123',
              serviceHint: 'NETFLIX',
              attachmentCount: 1,
              captureConfidence: CanonicalInputCaptureConfidence.high,
              extractedTextSegments: <String>['Renewed successfully'],
            ),
            ReceiptLikeInputRecord(
              id: 'receipt-manual-1',
              kind: ReceiptLikeInputKind.manualReceipt,
              receivedAt: DateTime(2026, 3, 22, 10, 0),
              subject: 'Manual receipt note',
              body: 'Receipt for monthly plan from a music service.',
              sourceLabel: 'manual_form',
              captureConfidence: CanonicalInputCaptureConfidence.low,
            ),
          ],
        ),
      );

      final canonicalInputs = await adapter.loadCanonicalInputs();

      expect(canonicalInputs, hasLength(2));
      expect(canonicalInputs.first.kind, CanonicalInputKind.receipt);
      expect(
        canonicalInputs.first.origin.kind,
        CanonicalInputOriginKind.emailReceiptImport,
      );
      expect(
        canonicalInputs.first.origin.captureConfidence,
        CanonicalInputCaptureConfidence.high,
      );
      expect(canonicalInputs.first.attachmentCount, 1);
      expect(canonicalInputs.last.kind, CanonicalInputKind.receipt);
      expect(
        canonicalInputs.last.origin.kind,
        CanonicalInputOriginKind.manualReceiptEntry,
      );
      expect(
        canonicalInputs.last.origin.captureConfidence,
        CanonicalInputCaptureConfidence.low,
      );
    });

    test('app store adapter maps store records to canonical inputs with provenance',
        () async {
      final adapter = AppStoreSubscriptionCanonicalInputSourceAdapter(
        source: _FakeAppStoreSubscriptionSource(
          <AppStoreSubscriptionRecord>[
            AppStoreSubscriptionRecord(
              id: 'gp-1',
              provider: AppStoreProvider.googlePlay,
              observedAt: DateTime(2026, 3, 23, 11, 0),
              serviceName: 'YouTube Premium',
              productName: 'YouTube Premium Monthly',
              stateLabel: 'renewed successfully',
              amount: 149,
              billingPeriodLabel: 'monthly',
              orderId: 'GPA.1234-5678',
              batchId: 'gp-batch-1',
              captureConfidence: CanonicalInputCaptureConfidence.high,
            ),
          ],
        ),
      );

      final canonicalInputs = await adapter.loadCanonicalInputs();

      expect(canonicalInputs, hasLength(1));
      expect(canonicalInputs.single.kind, CanonicalInputKind.appStore);
      expect(
        canonicalInputs.single.origin.kind,
        CanonicalInputOriginKind.googlePlayRecord,
      );
      expect(
        canonicalInputs.single.origin.captureConfidence,
        CanonicalInputCaptureConfidence.high,
      );
      expect(canonicalInputs.single.senderHandle, 'google_play');
      expect(
        canonicalInputs.single.textBody,
        contains('Google Play subscription for YouTube Premium'),
      );
    });

    test('strong app store renewal record reuses shared v2 pipeline', () async {
      final source = AppStoreSubscriptionCanonicalInputSourceAdapter(
        source: _FakeAppStoreSubscriptionSource(
          <AppStoreSubscriptionRecord>[
            AppStoreSubscriptionRecord(
              id: 'gp-2',
              provider: AppStoreProvider.googlePlay,
              observedAt: DateTime(2026, 3, 24, 9, 0),
              serviceName: 'YouTube Premium',
              productName: 'YouTube Premium Monthly',
              stateLabel: 'renewed successfully',
              amount: 149,
              billingPeriodLabel: 'monthly',
              rawSummary: 'Auto-renew payment completed.',
            ),
          ],
        ),
      );
      final bucketRepository = InMemoryServiceEvidenceBucketRepository();
      final useCase = LocalIngestionFlowUseCase(
        serviceEvidenceBucketRepository: bucketRepository,
      );

      final result = await useCase.executeCanonicalInputs(
        await source.loadCanonicalInputs(),
      );
      final buckets = await bucketRepository.list();

      expect(result.events, hasLength(1));
      expect(result.events.single.serviceKey.value, 'YOUTUBE_PREMIUM');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(buckets, hasLength(1));
      expect(
        buckets.single.sourceKindsSeen,
        contains(ServiceEvidenceSourceKind.googlePlayRecord),
      );
    });

    test('weak manual receipt hint does not auto-confirm paid truth', () async {
      final source = ReceiptLikeCanonicalInputSourceAdapter(
        source: _FakeReceiptLikeInputSource(
          <ReceiptLikeInputRecord>[
            ReceiptLikeInputRecord(
              id: 'receipt-manual-weak-1',
              kind: ReceiptLikeInputKind.manualReceipt,
              receivedAt: DateTime(2026, 3, 25, 12, 0),
              subject: 'Manual note',
              body: 'Receipt for a monthly plan from Apple.',
              sourceLabel: 'manual_form',
              captureConfidence: CanonicalInputCaptureConfidence.low,
            ),
          ],
        ),
      );
      final useCase = LocalIngestionFlowUseCase();

      final result = await useCase.executeCanonicalInputs(
        await source.loadCanonicalInputs(),
      );

      expect(
        result.ledgerEntries
            .any((entry) => entry.state == ResolverState.activePaid),
        isFalse,
      );
    });
  });
}

class _FakeReceiptLikeInputSource implements ReceiptLikeInputSource {
  const _FakeReceiptLikeInputSource(this.records);

  final List<ReceiptLikeInputRecord> records;

  @override
  Future<List<ReceiptLikeInputRecord>> loadReceiptLikeInputs() async {
    return records;
  }
}

class _FakeAppStoreSubscriptionSource implements AppStoreSubscriptionSource {
  const _FakeAppStoreSubscriptionSource(this.records);

  final List<AppStoreSubscriptionRecord> records;

  @override
  Future<List<AppStoreSubscriptionRecord>> loadSubscriptionRecords() async {
    return records;
  }
}
