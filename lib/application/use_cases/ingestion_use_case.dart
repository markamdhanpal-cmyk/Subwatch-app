import '../../domain/entities/message_record.dart';
import '../../domain/entities/subscription_event.dart';
import '../../v2/detection/mappers/message_record_canonical_input_mapper.dart';
import '../../v2/detection/models/canonical_input.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';
import '../../v2/decision/models/shadow_decision_comparison.dart';
import 'scan_subscriptions_v3_use_case.dart';

class IngestionUseCase {
  IngestionUseCase({
    required ScanSubscriptionsV3UseCase scanSubscriptionsV3UseCase,
    MessageRecordCanonicalInputMapper? messageRecordCanonicalInputMapper,
    DecisionExecutionMode decisionExecutionMode =
        DecisionExecutionMode.bridgeToLedger,
  })  : _scanSubscriptionsV3UseCase = scanSubscriptionsV3UseCase,
        _messageRecordCanonicalInputMapper =
            messageRecordCanonicalInputMapper ??
                const MessageRecordCanonicalInputMapper(),
        _decisionExecutionMode = decisionExecutionMode;

  final ScanSubscriptionsV3UseCase _scanSubscriptionsV3UseCase;
  final MessageRecordCanonicalInputMapper _messageRecordCanonicalInputMapper;
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
    final scanResult = await _scanSubscriptionsV3UseCase.executeCanonicalInputs(
      inputs,
      mode: _decisionExecutionMode,
    );

    return scanResult.events;
  }
}
