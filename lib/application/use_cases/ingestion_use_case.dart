import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/contracts/ledger_repository.dart';
import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/message_record.dart';
import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../v2/detection/bridges/normalized_input_message_record_bridge.dart';
import '../../v2/detection/mappers/message_record_canonical_input_mapper.dart';
import '../../v2/detection/models/canonical_input.dart';
import '../../v2/detection/use_cases/canonical_input_normalization_use_case.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/models/shadow_decision_comparison.dart';
import '../../v2/decision/use_cases/apply_v2_decision_snapshots_use_case.dart';
import '../../v2/decision/use_cases/build_shadow_decision_comparison_use_case.dart';
import 'accumulate_service_evidence_buckets_use_case.dart';
import 'event_pipeline_use_case.dart';
import 'resolver_pipeline_use_case.dart';

class IngestionUseCase {
  IngestionUseCase({
    required EventPipelineUseCase eventPipeline,
    required ResolverPipelineUseCase resolverPipeline,
    CanonicalInputNormalizationUseCase? normalizationUseCase,
    MessageRecordCanonicalInputMapper? messageRecordCanonicalInputMapper,
    NormalizedInputMessageRecordBridge? normalizedInputMessageRecordBridge,
    LedgerRepository? ledgerRepository,
    ServiceEvidenceBucketRepository? serviceEvidenceBucketRepository,
    AccumulateServiceEvidenceBucketsUseCase?
        accumulateServiceEvidenceBucketsUseCase,
    ApplyV2DecisionSnapshotsUseCase? applyV2DecisionSnapshotsUseCase,
    BuildShadowDecisionComparisonUseCase? buildShadowDecisionComparisonUseCase,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
  })  : _eventPipeline = eventPipeline,
        _resolverPipeline = resolverPipeline,
        _normalizationUseCase =
            normalizationUseCase ?? const CanonicalInputNormalizationUseCase(),
        _messageRecordCanonicalInputMapper =
            messageRecordCanonicalInputMapper ??
                const MessageRecordCanonicalInputMapper(),
        _normalizedInputMessageRecordBridge =
            normalizedInputMessageRecordBridge ??
                const NormalizedInputMessageRecordBridge(),
        _ledgerRepository = ledgerRepository,
        _serviceEvidenceBucketRepository = serviceEvidenceBucketRepository,
        _accumulateServiceEvidenceBucketsUseCase =
            accumulateServiceEvidenceBucketsUseCase ??
                const AccumulateServiceEvidenceBucketsUseCase(),
        _applyV2DecisionSnapshotsUseCase =
            applyV2DecisionSnapshotsUseCase ??
                const ApplyV2DecisionSnapshotsUseCase(),
        _buildShadowDecisionComparisonUseCase =
            buildShadowDecisionComparisonUseCase ??
                const BuildShadowDecisionComparisonUseCase(),
        _decisionExecutionMode = decisionExecutionMode;

  final EventPipelineUseCase _eventPipeline;
  final ResolverPipelineUseCase _resolverPipeline;
  final CanonicalInputNormalizationUseCase _normalizationUseCase;
  final MessageRecordCanonicalInputMapper _messageRecordCanonicalInputMapper;
  final NormalizedInputMessageRecordBridge
      _normalizedInputMessageRecordBridge;
  final LedgerRepository? _ledgerRepository;
  final ServiceEvidenceBucketRepository? _serviceEvidenceBucketRepository;
  final AccumulateServiceEvidenceBucketsUseCase
      _accumulateServiceEvidenceBucketsUseCase;
  final ApplyV2DecisionSnapshotsUseCase _applyV2DecisionSnapshotsUseCase;
  final BuildShadowDecisionComparisonUseCase
      _buildShadowDecisionComparisonUseCase;
  final DecisionExecutionMode _decisionExecutionMode;

  ShadowDecisionComparison? _lastShadowComparison;

  ShadowDecisionComparison? get lastShadowComparison => _lastShadowComparison;

  Future<List<SubscriptionEvent>> execute(List<MessageRecord> messages) async {
    _lastShadowComparison = null;
    final canonicalInputs = messages
        .map(
          (message) => _messageRecordCanonicalInputMapper.map(
            message,
            origin: const CanonicalInputOrigin.legacyMessageRecordBridge(),
          ),
        )
        .toList(growable: false);

    return executeCanonicalInputs(canonicalInputs);
  }

  Future<List<SubscriptionEvent>> executeCanonicalInputs(
    List<CanonicalInput> inputs,
  ) async {
    _lastShadowComparison = null;
    final canonicalInputsByMessageId = <String, CanonicalInput>{
      for (final input in inputs) input.id: input,
    };

    // Offload heavy CPU work (Normalization + EventPipeline) to a background isolate.
    // This prevents UI jank during large scans (O(N) operations).
    // In test environments, we stay on the main isolate for stability.
    final List<SubscriptionEvent> events;
    final bool useIsolate =
        !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

    if (useIsolate) {
      events = await compute(_runClassificationBatch, inputs);
    } else {
      events = _runClassificationBatch(inputs);
    }

    await _resolverPipeline.execute(events);
    final bucketRepository = _serviceEvidenceBucketRepository;
    if (bucketRepository != null) {
      await _accumulateServiceEvidenceBucketsUseCase.execute(
        events: events,
        canonicalInputsByMessageId: canonicalInputsByMessageId,
        repository: bucketRepository,
      );
      final ledgerRepository = _ledgerRepository;
      if (ledgerRepository != null) {
        final legacyEntries =
            _decisionExecutionMode == DecisionExecutionMode.shadowCompareAndBridge
                ? await ledgerRepository.list()
                : const <ServiceLedgerEntry>[];
        final snapshots = await _applyV2DecisionSnapshotsUseCase.execute(
          bucketRepository: bucketRepository,
          ledgerRepository: ledgerRepository,
          mode: _decisionModeForApply(),
        );
        if (_decisionExecutionMode == DecisionExecutionMode.shadowCompareAndBridge) {
          final bridgedEntries = await ledgerRepository.list();
          _lastShadowComparison = _buildShadowDecisionComparisonUseCase.execute(
            legacyEntries: legacyEntries,
            v2Entries: bridgedEntries,
            comparedAt: snapshots.isEmpty
                ? DateTime.now()
                : snapshots.last.decidedAt,
          );
        }
      }
    }
    return events;
  }

  DecisionExecutionMode _decisionModeForApply() {
    if (_decisionExecutionMode == DecisionExecutionMode.shadowCompareAndBridge) {
      return DecisionExecutionMode.bridgeToLedger;
    }

    return _decisionExecutionMode;
  }

  /// Top-level or static function for Isolate execution.
  /// Must be self-contained or use only isolate-safe (stateless) objects.
  static List<SubscriptionEvent> _runClassificationBatch(
    List<CanonicalInput> inputs,
  ) {
    const normalizationUseCase = CanonicalInputNormalizationUseCase();
    const bridge = NormalizedInputMessageRecordBridge();
    final eventPipeline = EventPipelineUseCase();

    final normalizedInputs = normalizationUseCase.normalizeAll(inputs);
    final normalizedMessages = bridge.toMessageRecords(normalizedInputs);
    return eventPipeline.execute(normalizedMessages);
  }
}
