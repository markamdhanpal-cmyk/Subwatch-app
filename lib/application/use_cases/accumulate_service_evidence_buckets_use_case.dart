import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/evidence_fragment.dart';
import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/service_evidence_bucket.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/enums/evidence_fragment_type.dart';
import '../../domain/enums/service_evidence_source_kind.dart';
import '../../domain/value_objects/service_key.dart';
import '../../v2/detection/models/canonical_input.dart';

class AccumulateServiceEvidenceBucketsUseCase {
  const AccumulateServiceEvidenceBucketsUseCase();

  static const int _maxAmountSeriesLength = 24;
  static const int _maxIntervalHintLength = 12;
  static const ServiceKey _unresolvedServiceKey = ServiceKey('UNRESOLVED');

  Future<void> execute({
    required List<SubscriptionEvent> events,
    required Map<String, CanonicalInput> canonicalInputsByMessageId,
    required ServiceEvidenceBucketRepository repository,
  }) async {
    if (events.isEmpty) {
      return;
    }

    final bucketsByKey = <String, ServiceEvidenceBucket>{
      for (final bucket in await repository.list()) bucket.serviceKey.value: bucket,
    };

    for (final event in events) {
      if (event.serviceKey == _unresolvedServiceKey) {
        continue;
      }

      final sourceKind = _sourceKindFor(
        canonicalInputsByMessageId[event.sourceMessageId],
      );
      final current = bucketsByKey[event.serviceKey.value] ??
          ServiceEvidenceBucket.seed(
            serviceKey: event.serviceKey,
            seenAt: event.occurredAt,
            sourceKind: sourceKind,
          );
      bucketsByKey[event.serviceKey.value] = _accumulate(
        current,
        event,
        sourceKind: sourceKind,
      );
    }

    await repository.replaceAll(
      bucketsByKey.values.toList(growable: false)
        ..sort(
          (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
        ),
    );
  }

  ServiceEvidenceBucket _accumulate(
    ServiceEvidenceBucket current,
    SubscriptionEvent event, {
    required ServiceEvidenceSourceKind sourceKind,
  }) {
    final fragments = event.evidenceFragments.isNotEmpty
        ? event.evidenceFragments
        : _fallbackFragments(event);
    var billedCount = current.billedCount;
    var renewalHintCount = current.renewalHintCount;
    var mandateCount = current.mandateCount;
    var autopaySetupCount = current.autopaySetupCount;
    var microChargeCount = current.microChargeCount;
    var bundleCount = current.bundleCount;
    var promoCount = current.promoCount;
    var cancellationHintCount = current.cancellationHintCount;
    var weakRecurringHintCount = current.weakRecurringHintCount;
    var unknownReviewCount = current.unknownReviewCount;
    var oneTimePaymentNoiseCount = current.oneTimePaymentNoiseCount;
    var ignoreNoiseCount = current.ignoreNoiseCount;
    var lastBilledAt = current.lastBilledAt;

    final contradictions = <String>{...current.contradictions};
    final amounts = <double>[...current.amountSeries];
    final intervalHints = <int>[...current.intervalHintsInDays];
    final sourceKinds = <ServiceEvidenceSourceKind>{
      ...current.sourceKindsSeen,
      sourceKind,
    };

    final eventAmounts = <double>{
      if (event.amount != null) event.amount!,
      ...fragments
          .where((fragment) => fragment.amount != null)
          .map((fragment) => fragment.amount!),
    };
    for (final amount in eventAmounts) {
      amounts.add(amount);
    }
    if (amounts.length > _maxAmountSeriesLength) {
      amounts.removeRange(0, amounts.length - _maxAmountSeriesLength);
    }

    final hadPaidEvidence = current.billedCount > 0;
    final hadBundleEvidence = current.bundleCount > 0;
    final hadSetupEvidence =
        current.mandateCount > 0 || current.autopaySetupCount > 0;
    final hadMicroEvidence = current.microChargeCount > 0;

    for (final fragment in fragments) {
      switch (fragment.type) {
        case EvidenceFragmentType.billedSuccess:
          billedCount++;
          if (hadBundleEvidence) {
            contradictions.add('paid_vs_bundle');
          }
          if (hadSetupEvidence) {
            contradictions.add('paid_after_setup');
          }
          if (hadMicroEvidence) {
            contradictions.add('paid_after_micro');
          }
          if (lastBilledAt != null && event.occurredAt.isAfter(lastBilledAt)) {
            final diffDays = event.occurredAt.difference(lastBilledAt).inDays;
            if (diffDays > 0) {
              intervalHints.add(diffDays);
            }
          }
          lastBilledAt = event.occurredAt;
          break;
        case EvidenceFragmentType.renewalHint:
          renewalHintCount++;
          break;
        case EvidenceFragmentType.mandateCreated:
          mandateCount++;
          if (hadPaidEvidence) {
            contradictions.add('setup_after_paid');
          }
          break;
        case EvidenceFragmentType.autopaySetup:
          autopaySetupCount++;
          if (hadPaidEvidence) {
            contradictions.add('setup_after_paid');
          }
          break;
        case EvidenceFragmentType.microCharge:
          microChargeCount++;
          if (hadPaidEvidence) {
            contradictions.add('micro_after_paid');
          }
          break;
        case EvidenceFragmentType.bundledBenefit:
          bundleCount++;
          if (hadPaidEvidence) {
            contradictions.add('paid_vs_bundle');
          }
          break;
        case EvidenceFragmentType.promoOnly:
          promoCount++;
          break;
        case EvidenceFragmentType.cancellationHint:
          cancellationHintCount++;
          break;
        case EvidenceFragmentType.weakRecurringHint:
          weakRecurringHintCount++;
          break;
        case EvidenceFragmentType.unknownReview:
          unknownReviewCount++;
          break;
        case EvidenceFragmentType.oneTimePaymentNoise:
          oneTimePaymentNoiseCount++;
          break;
        case EvidenceFragmentType.ignoreNoise:
          ignoreNoiseCount++;
          break;
      }
    }

    if (intervalHints.length > _maxIntervalHintLength) {
      intervalHints.removeRange(0, intervalHints.length - _maxIntervalHintLength);
    }

    return current.copyWith(
      firstSeenAt: event.occurredAt.isBefore(current.firstSeenAt)
          ? event.occurredAt
          : current.firstSeenAt,
      lastSeenAt: event.occurredAt.isAfter(current.lastSeenAt)
          ? event.occurredAt
          : current.lastSeenAt,
      lastBilledAt: lastBilledAt,
      sourceKindsSeen: sourceKinds.toList(growable: false)
        ..sort((left, right) => left.name.compareTo(right.name)),
      billedCount: billedCount,
      renewalHintCount: renewalHintCount,
      mandateCount: mandateCount,
      autopaySetupCount: autopaySetupCount,
      microChargeCount: microChargeCount,
      bundleCount: bundleCount,
      promoCount: promoCount,
      cancellationHintCount: cancellationHintCount,
      weakRecurringHintCount: weakRecurringHintCount,
      unknownReviewCount: unknownReviewCount,
      oneTimePaymentNoiseCount: oneTimePaymentNoiseCount,
      ignoreNoiseCount: ignoreNoiseCount,
      amountSeries: amounts,
      intervalHintsInDays: intervalHints,
      contradictions: contradictions.toList(growable: false)
        ..sort((left, right) => left.compareTo(right)),
      evidenceTrail: _mergeEvidence(current.evidenceTrail, event),
    );
  }

  EvidenceTrail _mergeEvidence(
    EvidenceTrail current,
    SubscriptionEvent event,
  ) {
    final messageIds = <String>{
      ...current.messageIds,
      event.sourceMessageId,
      ...event.evidenceTrail.messageIds,
    };
    final eventIds = <String>{
      ...current.eventIds,
      event.id,
      ...event.evidenceTrail.eventIds,
    };
    final notes = <String>{
      ...current.notes,
      ...event.evidenceTrail.notes,
    };

    return EvidenceTrail(
      messageIds: messageIds.toList(growable: false),
      eventIds: eventIds.toList(growable: false),
      notes: notes.toList(growable: false),
    );
  }

  List<EvidenceFragment> _fallbackFragments(SubscriptionEvent event) {
    final type = switch (event.type.name) {
      'subscriptionBilled' => EvidenceFragmentType.billedSuccess,
      'mandateCreated' => EvidenceFragmentType.mandateCreated,
      'autopaySetup' => EvidenceFragmentType.autopaySetup,
      'mandateExecutedMicro' => EvidenceFragmentType.microCharge,
      'bundleActivated' => EvidenceFragmentType.bundledBenefit,
      'unknownReview' => EvidenceFragmentType.unknownReview,
      'oneTimePayment' => EvidenceFragmentType.oneTimePaymentNoise,
      _ => EvidenceFragmentType.ignoreNoise,
    };

    return <EvidenceFragment>[
      EvidenceFragment(
        type: type,
        sourceMessageId: event.sourceMessageId,
        classifierId: 'subscription_event_fallback',
        strength: EvidenceFragmentStrength.medium,
        amount: event.amount,
      ),
    ];
  }

  ServiceEvidenceSourceKind _sourceKindFor(CanonicalInput? input) {
    switch (input?.origin.kind) {
      case CanonicalInputOriginKind.deviceSmsInbox:
        return ServiceEvidenceSourceKind.deviceSmsInbox;
      case CanonicalInputOriginKind.deviceMmsInbox:
        return ServiceEvidenceSourceKind.deviceMmsInbox;
      case CanonicalInputOriginKind.deviceRcsInbox:
        return ServiceEvidenceSourceKind.deviceRcsInbox;
      case CanonicalInputOriginKind.emailReceiptImport:
        return ServiceEvidenceSourceKind.emailReceiptImport;
      case CanonicalInputOriginKind.googlePlayRecord:
        return ServiceEvidenceSourceKind.googlePlayRecord;
      case CanonicalInputOriginKind.appleAppStoreRecord:
        return ServiceEvidenceSourceKind.appleAppStoreRecord;
      case CanonicalInputOriginKind.bankConnectorSync:
        return ServiceEvidenceSourceKind.bankConnectorSync;
      case CanonicalInputOriginKind.sampleSeedData:
        return ServiceEvidenceSourceKind.sampleSeedData;
      case CanonicalInputOriginKind.manualEntry:
        return ServiceEvidenceSourceKind.manualEntry;
      case CanonicalInputOriginKind.manualReceiptEntry:
        return ServiceEvidenceSourceKind.manualReceiptEntry;
      case CanonicalInputOriginKind.csvImport:
        return ServiceEvidenceSourceKind.csvImport;
      case CanonicalInputOriginKind.legacyMessageRecordBridge:
      case null:
        return ServiceEvidenceSourceKind.legacyMessageRecordBridge;
    }
  }
}
