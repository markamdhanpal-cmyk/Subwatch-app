import '../../v2/detection/models/canonical_input.dart';
import '../models/bank_connector_models.dart';

class NormalizedBankTransactionCanonicalInputMapper {
  const NormalizedBankTransactionCanonicalInputMapper();

  CanonicalInput map(NormalizedBankTransactionRecord record) {
    return CanonicalInput(
      id: record.id,
      kind: CanonicalInputKind.bankTransaction,
      origin: CanonicalInputOrigin.bankConnectorSync(
        connectorId: record.connectorId,
        batchId: record.batchId,
        captureConfidence: record.captureConfidence,
      ),
      receivedAt: record.observedAt,
      textBody: _composeTextBody(record),
      senderHandle: record.accountProviderLabel ?? record.connectorId,
      subject: record.serviceHint ?? record.merchantHint ?? record.description,
      threadId: record.batchId ?? record.connectorId,
      richTextSegments: <String>[
        'Connector: ${record.connectorId}',
        'Posting state: ${record.postingState.name}',
        'Channel: ${record.channel.name}',
        if (record.accountProviderLabel != null)
          'Account provider: ${record.accountProviderLabel}',
        if (record.accountReference != null)
          'Account reference: ${record.accountReference}',
        if (record.merchantHint != null) 'Merchant hint: ${record.merchantHint}',
        if (record.serviceHint != null) 'Service hint: ${record.serviceHint}',
        if (record.reference != null) 'Reference: ${record.reference}',
        if (record.rawSummary != null) 'Raw summary: ${record.rawSummary}',
      ],
    );
  }

  List<CanonicalInput> mapAll(Iterable<NormalizedBankTransactionRecord> records) {
    return List<CanonicalInput>.unmodifiable(records.map(map));
  }

  String _composeTextBody(NormalizedBankTransactionRecord record) {
    final amountPhrase = record.amount == null
        ? ''
        : ' of Rs ${record.amount == record.amount!.roundToDouble() ? record.amount!.round() : record.amount!.toStringAsFixed(2)}';
    final merchantPhrase = record.merchantHint == null
        ? ''
        : ' at ${record.merchantHint}';
    final servicePhrase = record.serviceHint == null
        ? ''
        : ' for ${record.serviceHint}';
    final referencePhrase =
        record.reference == null ? '' : ' Ref ${record.reference}.';

    return 'Bank connector ${record.direction.name} transaction$amountPhrase$merchantPhrase$servicePhrase via ${record.channel.name}. Description: ${record.description}.$referencePhrase'
        .trim();
  }
}
