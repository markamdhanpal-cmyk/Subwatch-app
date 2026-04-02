import '../../domain/contracts/ledger_repository.dart';
import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/evidence_fragment.dart';
import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../domain/entities/subscription_evidence.dart';
import '../../domain/enums/evidence_fragment_type.dart';
import '../../domain/enums/subscription_event_type.dart';
import '../../domain/enums/subscription_evidence_kind.dart';
import '../../domain/extractors/bundle_benefit_extractor.dart';
import '../../domain/extractors/evidence_extractor.dart';
import '../../domain/extractors/lifecycle_extractor.dart';
import '../../domain/extractors/mandate_setup_extractor.dart';
import '../../domain/extractors/one_time_payment_extractor.dart';
import '../../domain/extractors/paid_charge_extractor.dart';
import '../../domain/services/message_prefilter.dart';
import '../../domain/services/service_key_resolver_v2.dart';
import '../../v2/detection/bridges/normalized_input_message_record_bridge.dart';
import '../../v2/detection/models/canonical_input.dart';
import '../../v2/detection/use_cases/canonical_input_normalization_use_case.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/use_cases/apply_v2_decision_snapshots_use_case.dart';
import 'accumulate_service_evidence_buckets_use_case.dart';

class ScanSubscriptionsV3Result {
  const ScanSubscriptionsV3Result({
    required this.events,
    required this.ledgerEntries,
  });

  final List<SubscriptionEvent> events;
  final List<ServiceLedgerEntry> ledgerEntries;
}

class ScanSubscriptionsV3UseCase {
  ScanSubscriptionsV3UseCase({
    required LedgerRepository ledgerRepository,
    required ServiceEvidenceBucketRepository serviceEvidenceBucketRepository,
    MessagePrefilter prefilter = const MessagePrefilter(),
    List<EvidenceExtractor>? extractors,
    ServiceKeyResolverV2 resolver = const ServiceKeyResolverV2(),
    AccumulateServiceEvidenceBucketsUseCase accumulateBucketsUseCase =
        const AccumulateServiceEvidenceBucketsUseCase(),
    ApplyV2DecisionSnapshotsUseCase applyDecisionSnapshotsUseCase =
        const ApplyV2DecisionSnapshotsUseCase(),
    CanonicalInputNormalizationUseCase normalizationUseCase =
        const CanonicalInputNormalizationUseCase(),
    NormalizedInputMessageRecordBridge normalizedInputMessageRecordBridge =
        const NormalizedInputMessageRecordBridge(),
  })  : _ledgerRepository = ledgerRepository,
        _serviceEvidenceBucketRepository = serviceEvidenceBucketRepository,
        _prefilter = prefilter,
        _extractors = List<EvidenceExtractor>.unmodifiable(
          extractors ??
              const <EvidenceExtractor>[
                PaidChargeExtractor(),
                MandateSetupExtractor(),
                BundleBenefitExtractor(),
                LifecycleExtractor(),
                OneTimePaymentExtractor(),
              ],
        ),
        _resolver = resolver,
        _accumulateBucketsUseCase = accumulateBucketsUseCase,
        _applyDecisionSnapshotsUseCase = applyDecisionSnapshotsUseCase,
        _normalizationUseCase = normalizationUseCase,
        _normalizedInputMessageRecordBridge = normalizedInputMessageRecordBridge;

  final LedgerRepository _ledgerRepository;
  final ServiceEvidenceBucketRepository _serviceEvidenceBucketRepository;
  final MessagePrefilter _prefilter;
  final List<EvidenceExtractor> _extractors;
  final ServiceKeyResolverV2 _resolver;
  final AccumulateServiceEvidenceBucketsUseCase _accumulateBucketsUseCase;
  final ApplyV2DecisionSnapshotsUseCase _applyDecisionSnapshotsUseCase;
  final CanonicalInputNormalizationUseCase _normalizationUseCase;
  final NormalizedInputMessageRecordBridge _normalizedInputMessageRecordBridge;

  Future<ScanSubscriptionsV3Result> executeMessages(
    List<MessageRecord> messages, {
    DecisionExecutionMode mode = DecisionExecutionMode.bridgeToLedger,
  }) async {
    final canonicalByMessageId = <String, CanonicalInput>{
      for (final message in messages)
        message.id: CanonicalInput(
          id: message.id,
          kind: CanonicalInputKind.sms,
          origin: const CanonicalInputOrigin.legacyMessageRecordBridge(),
          receivedAt: message.receivedAt,
          senderHandle: message.sourceAddress,
          textBody: message.body,
        ),
    };
    return _execute(
      messages: messages,
      canonicalInputsByMessageId: canonicalByMessageId,
      mode: mode,
    );
  }

  Future<ScanSubscriptionsV3Result> executeCanonicalInputs(
    List<CanonicalInput> inputs, {
    DecisionExecutionMode mode = DecisionExecutionMode.bridgeToLedger,
  }) async {
    final normalizedInputs = _normalizationUseCase.normalizeAll(inputs);
    final messages =
        _normalizedInputMessageRecordBridge.toMessageRecords(normalizedInputs);
    final canonicalByMessageId = <String, CanonicalInput>{
      for (final input in inputs) input.id: input,
    };
    return _execute(
      messages: messages,
      canonicalInputsByMessageId: canonicalByMessageId,
      mode: mode,
    );
  }

  Future<ScanSubscriptionsV3Result> _execute({
    required List<MessageRecord> messages,
    required Map<String, CanonicalInput> canonicalInputsByMessageId,
    required DecisionExecutionMode mode,
  }) async {
    final events = <SubscriptionEvent>[];
    for (final message in messages) {
      final prefilterResult = _prefilter.inspect(message);
      if (prefilterResult.isHardNoise) {
        events.addAll(
          _eventsFromEvidence(
            message: message,
            evidences: prefilterResult.evidences,
          ),
        );
        continue;
      }

      final extractedEvidence = <SubscriptionEvidence>[];
      for (final extractor in _extractors) {
        extractedEvidence.addAll(extractor.extract(message));
      }
      if (extractedEvidence.isEmpty) {
        continue;
      }

      events.addAll(
        _eventsFromEvidence(
          message: message,
          evidences: extractedEvidence,
        ),
      );
    }

    await _accumulateBucketsUseCase.execute(
      events: events,
      canonicalInputsByMessageId: canonicalInputsByMessageId,
      repository: _serviceEvidenceBucketRepository,
    );

    await _applyDecisionSnapshotsUseCase.execute(
      bucketRepository: _serviceEvidenceBucketRepository,
      ledgerRepository: _ledgerRepository,
      mode: mode == DecisionExecutionMode.shadowCompareAndBridge
          ? DecisionExecutionMode.bridgeToLedger
          : mode,
    );

    return ScanSubscriptionsV3Result(
      events: List<SubscriptionEvent>.unmodifiable(events),
      ledgerEntries: await _ledgerRepository.list(),
    );
  }

  List<SubscriptionEvent> _eventsFromEvidence({
    required MessageRecord message,
    required List<SubscriptionEvidence> evidences,
  }) {
    final events = <SubscriptionEvent>[];
    for (var index = 0; index < evidences.length; index += 1) {
      final evidence = evidences[index];
      final resolution = _resolver.resolve(message: message, evidence: evidence);
      final fragment = _fragmentFor(evidence, message.id);
      final eventType = _eventTypeFor(evidence);
      events.add(
        SubscriptionEvent(
          id: '${message.id}:${evidence.kind.name}:$index',
          serviceKey: resolution.resolvedServiceKey,
          type: eventType,
          occurredAt: evidence.occurredAt ?? message.receivedAt,
          sourceMessageId: message.id,
          amount: evidence.amount,
          merchantResolution: resolution,
          evidenceFragments: <EvidenceFragment>[fragment],
          evidenceTrail: EvidenceTrail(
            messageIds: <String>[message.id],
            notes: <String>[
              'scan_v3:evidence=${evidence.kind.name}',
              if (evidence.explanation != null) evidence.explanation!,
              resolution.traceNote,
              fragment.traceNote,
            ],
          ),
        ),
      );
    }
    return events;
  }

  EvidenceFragment _fragmentFor(
    SubscriptionEvidence evidence,
    String sourceMessageId,
  ) {
    late final EvidenceFragmentType type;
    switch (evidence.kind) {
      case SubscriptionEvidenceKind.paidCharge:
        type = EvidenceFragmentType.billedSuccess;
        break;
      case SubscriptionEvidenceKind.mandateSetup:
        type = EvidenceFragmentType.mandateCreated;
        break;
      case SubscriptionEvidenceKind.microVerification:
        type = EvidenceFragmentType.microCharge;
        break;
      case SubscriptionEvidenceKind.bundleBenefit:
        type = EvidenceFragmentType.bundledBenefit;
        break;
      case SubscriptionEvidenceKind.renewalHint:
        type = EvidenceFragmentType.renewalHint;
        break;
      case SubscriptionEvidenceKind.cancellationHint:
        type = evidence.explanation == 'ended_lifecycle'
            ? EvidenceFragmentType.endedLifecycle
            : EvidenceFragmentType.cancellationHint;
        break;
      case SubscriptionEvidenceKind.promoNoise:
        type = EvidenceFragmentType.promoOnly;
        break;
      case SubscriptionEvidenceKind.otpNoise:
        type = EvidenceFragmentType.otpNoise;
        break;
      case SubscriptionEvidenceKind.upiOneTime:
        type = EvidenceFragmentType.oneTimePaymentNoise;
        break;
      case SubscriptionEvidenceKind.telecomRechargeNoise:
        type = EvidenceFragmentType.telecomRechargeNoise;
        break;
    }

    return EvidenceFragment(
      type: type,
      sourceMessageId: sourceMessageId,
      classifierId: 'scan_subscriptions_v3',
      strength: EvidenceFragmentStrength.medium,
      confidence: evidence.confidence,
      amount: evidence.amount,
      note: evidence.explanation,
    );
  }

  SubscriptionEventType _eventTypeFor(SubscriptionEvidence evidence) {
    switch (evidence.kind) {
      case SubscriptionEvidenceKind.paidCharge:
        return SubscriptionEventType.subscriptionBilled;
      case SubscriptionEvidenceKind.mandateSetup:
        return SubscriptionEventType.mandateCreated;
      case SubscriptionEvidenceKind.microVerification:
        return SubscriptionEventType.mandateExecutedMicro;
      case SubscriptionEvidenceKind.bundleBenefit:
        return SubscriptionEventType.bundleActivated;
      case SubscriptionEvidenceKind.renewalHint:
        return SubscriptionEventType.unknownReview;
      case SubscriptionEvidenceKind.cancellationHint:
        return evidence.explanation == 'ended_lifecycle'
            ? SubscriptionEventType.subscriptionCancelled
            : SubscriptionEventType.unknownReview;
      case SubscriptionEvidenceKind.promoNoise:
      case SubscriptionEvidenceKind.otpNoise:
      case SubscriptionEvidenceKind.telecomRechargeNoise:
        return SubscriptionEventType.ignore;
      case SubscriptionEvidenceKind.upiOneTime:
        return SubscriptionEventType.oneTimePayment;
    }
  }
}
