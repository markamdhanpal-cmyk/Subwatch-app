enum ImportedStatementDirection {
  debit,
  credit,
  unknown,
}

class ImportedStatementRecord {
  ImportedStatementRecord({
    required this.id,
    required this.batchId,
    required this.rowNumber,
    required this.occurredAt,
    required this.description,
    required this.direction,
    required this.currencyCode,
    required Map<String, String> rawValuesByColumn,
    this.sourceLabel,
    this.amount,
    this.merchantName,
    this.reference,
    this.channel,
  }) : rawValuesByColumn = Map<String, String>.unmodifiable(rawValuesByColumn);

  final String id;
  final String batchId;
  final int rowNumber;
  final DateTime occurredAt;
  final String description;
  final ImportedStatementDirection direction;
  final String currencyCode;
  final Map<String, String> rawValuesByColumn;
  final String? sourceLabel;
  final double? amount;
  final String? merchantName;
  final String? reference;
  final String? channel;
}

enum StatementImportIssueCode {
  missingHeaderRow,
  malformedRow,
  missingDate,
  invalidDate,
  invalidAmount,
  emptyEvidenceRow,
}

class StatementImportIssue {
  const StatementImportIssue({
    required this.code,
    required this.message,
    this.rowNumber,
  });

  final StatementImportIssueCode code;
  final String message;
  final int? rowNumber;
}

class StatementImportParseResult {
  StatementImportParseResult({
    required this.batchId,
    required List<ImportedStatementRecord> records,
    required List<StatementImportIssue> issues,
  })  : records = List<ImportedStatementRecord>.unmodifiable(records),
        issues = List<StatementImportIssue>.unmodifiable(issues);

  final String batchId;
  final List<ImportedStatementRecord> records;
  final List<StatementImportIssue> issues;
}
