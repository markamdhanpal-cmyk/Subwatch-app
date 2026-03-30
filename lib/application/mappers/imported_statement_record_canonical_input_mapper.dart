import '../../v2/detection/models/canonical_input.dart';
import '../models/statement_import_models.dart';

class ImportedStatementRecordCanonicalInputMapper {
  const ImportedStatementRecordCanonicalInputMapper();

  CanonicalInput map(ImportedStatementRecord record) {
    return CanonicalInput(
      id: record.id,
      kind: CanonicalInputKind.csv,
      origin: CanonicalInputOrigin.csvImport(batchId: record.batchId),
      receivedAt: record.occurredAt,
      textBody: _composeTextBody(record),
      subject: record.merchantName ?? record.description,
      threadId: record.batchId,
      richTextSegments: <String>[
        'Imported statement row ${record.rowNumber}',
        if (record.sourceLabel != null) 'Source: ${record.sourceLabel}',
        if (record.merchantName != null) 'Merchant: ${record.merchantName}',
        if (record.description.trim().isNotEmpty)
          'Description: ${record.description.trim()}',
        if (record.reference != null) 'Reference: ${record.reference}',
        if (record.channel != null) 'Channel: ${record.channel}',
        for (final entry in record.rawValuesByColumn.entries)
          if (entry.value.trim().isNotEmpty)
            '${entry.key}: ${entry.value.trim()}',
      ],
    );
  }

  List<CanonicalInput> mapAll(Iterable<ImportedStatementRecord> records) {
    return List<CanonicalInput>.unmodifiable(records.map(map));
  }

  String _composeTextBody(ImportedStatementRecord record) {
    final leadSentence = switch (record.direction) {
      ImportedStatementDirection.debit =>
        'Statement import shows${_amountPhrase(record.amount)} debited${_merchantPhrase(record.merchantName)} on ${_formatDate(record.occurredAt)}.',
      ImportedStatementDirection.credit =>
        'Statement import shows${_amountPhrase(record.amount)} credited${_merchantPhrase(record.merchantName)} on ${_formatDate(record.occurredAt)}.',
      ImportedStatementDirection.unknown =>
        'Statement import shows a transaction${_amountPhrase(record.amount)}${_merchantPhrase(record.merchantName)} on ${_formatDate(record.occurredAt)}.',
    };

    final segments = <String>[
      leadSentence,
      'Description: ${record.description.trim()}.',
      if (record.reference != null) 'Reference: ${record.reference}.',
      if (record.channel != null) 'Channel: ${record.channel}.',
    ];

    return segments.join(' ');
  }

  String _amountPhrase(double? amount) {
    if (amount == null) {
      return '';
    }

    final amountText = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toStringAsFixed(2);
    return ' Rs $amountText';
  }

  String _merchantPhrase(String? merchantName) {
    if (merchantName == null || merchantName.trim().isEmpty) {
      return '';
    }

    return ' at ${merchantName.trim()}';
  }

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
