import '../../v2/detection/models/canonical_input.dart';

enum BankTransactionDirection {
  debit,
  credit,
  unknown,
}

enum BankTransactionChannel {
  card,
  upi,
  netBanking,
  ach,
  transfer,
  wallet,
  unknown,
}

enum BankTransactionPostingState {
  posted,
  pending,
  reversed,
}

class NormalizedBankTransactionRecord {
  const NormalizedBankTransactionRecord({
    required this.id,
    required this.connectorId,
    required this.observedAt,
    required this.description,
    required this.direction,
    required this.channel,
    this.accountProviderLabel,
    this.accountReference,
    this.amount,
    this.currencyCode = 'INR',
    this.merchantHint,
    this.serviceHint,
    this.reference,
    this.rawSummary,
    this.batchId,
    this.postingState = BankTransactionPostingState.posted,
    this.captureConfidence = CanonicalInputCaptureConfidence.high,
  });

  final String id;
  final String connectorId;
  final DateTime observedAt;
  final String description;
  final BankTransactionDirection direction;
  final BankTransactionChannel channel;
  final String? accountProviderLabel;
  final String? accountReference;
  final double? amount;
  final String currencyCode;
  final String? merchantHint;
  final String? serviceHint;
  final String? reference;
  final String? rawSummary;
  final String? batchId;
  final BankTransactionPostingState postingState;
  final CanonicalInputCaptureConfidence captureConfidence;
}

class BankConnectorPullResult {
  BankConnectorPullResult({
    required this.connectorId,
    required List<NormalizedBankTransactionRecord> records,
    this.connectionReady = false,
    this.syncCursor,
    this.note,
  }) : records = List<NormalizedBankTransactionRecord>.unmodifiable(records);

  final String connectorId;
  final List<NormalizedBankTransactionRecord> records;
  final bool connectionReady;
  final String? syncCursor;
  final String? note;
}
