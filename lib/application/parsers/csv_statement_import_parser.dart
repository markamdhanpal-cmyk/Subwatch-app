import '../contracts/statement_import_parser.dart';
import '../models/statement_import_models.dart';

class CsvStatementImportParser implements StatementImportParser {
  const CsvStatementImportParser();

  static const Set<String> _dateHeaders = <String>{
    'date',
    'txn_date',
    'transaction_date',
    'posted_date',
    'value_date',
    'timestamp',
  };
  static const Set<String> _descriptionHeaders = <String>{
    'description',
    'details',
    'narration',
    'remarks',
    'remark',
    'particulars',
    'memo',
    'transaction_details',
    'note',
  };
  static const Set<String> _merchantHeaders = <String>{
    'merchant',
    'merchant_name',
    'payee',
    'biller',
    'service',
    'counterparty',
    'beneficiary',
  };
  static const Set<String> _amountHeaders = <String>{
    'amount',
    'txn_amount',
    'transaction_amount',
    'amount_inr',
  };
  static const Set<String> _debitHeaders = <String>{
    'debit',
    'debit_amount',
    'withdrawal',
    'spent',
    'paid',
    'outflow',
  };
  static const Set<String> _creditHeaders = <String>{
    'credit',
    'credit_amount',
    'deposit',
    'inflow',
    'received',
  };
  static const Set<String> _referenceHeaders = <String>{
    'reference',
    'ref',
    'txn_ref',
    'txn_id',
    'transaction_id',
    'utr',
  };
  static const Set<String> _channelHeaders = <String>{
    'channel',
    'mode',
    'payment_mode',
    'instrument',
    'source',
  };
  static const Set<String> _currencyHeaders = <String>{
    'currency',
    'currency_code',
  };
  static const Set<String> _directionHeaders = <String>{
    'direction',
    'dr_cr',
    'type',
    'transaction_type',
  };

  @override
  StatementImportParseResult parseCsv({
    required String csvText,
    required String batchId,
    String? sourceLabel,
  }) {
    final rows = _parseCsvRows(csvText);
    final issues = <StatementImportIssue>[];
    if (rows.isEmpty) {
      return StatementImportParseResult(
        batchId: batchId,
        records: const <ImportedStatementRecord>[],
        issues: const <StatementImportIssue>[
          StatementImportIssue(
            code: StatementImportIssueCode.missingHeaderRow,
            message: 'A CSV header row is required.',
          ),
        ],
      );
    }

    final headerRow = rows.first;
    final normalizedHeaders =
        headerRow.map(_normalizeHeader).toList(growable: false);
    final records = <ImportedStatementRecord>[];

    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      final rowNumber = index + 1;
      if (_isEmptyRow(row)) {
        continue;
      }

      if (row.length > normalizedHeaders.length) {
        issues.add(
          StatementImportIssue(
            code: StatementImportIssueCode.malformedRow,
            message: 'Row has more values than the header declares.',
            rowNumber: rowNumber,
          ),
        );
      }

      final valuesByColumn = <String, String>{};
      for (var cellIndex = 0; cellIndex < normalizedHeaders.length; cellIndex++) {
        final header = normalizedHeaders[cellIndex];
        if (header.isEmpty) {
          continue;
        }

        final cellValue = cellIndex < row.length ? row[cellIndex].trim() : '';
        if (cellValue.isNotEmpty) {
          valuesByColumn[header] = cellValue;
        }
      }

      final rawDate = _pick(valuesByColumn, _dateHeaders);
      final occurredAt = _parseDate(rawDate);
      if (occurredAt == null) {
        issues.add(
          StatementImportIssue(
            code: rawDate == null
                ? StatementImportIssueCode.missingDate
                : StatementImportIssueCode.invalidDate,
            message: 'Row is missing a usable statement date.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final description = _descriptionFor(valuesByColumn);
      final merchantName = _pick(valuesByColumn, _merchantHeaders);
      final reference = _pick(valuesByColumn, _referenceHeaders);
      final channel = _pick(valuesByColumn, _channelHeaders);
      final amountResult = _resolveAmount(valuesByColumn);

      if (amountResult.hadInvalidAmount) {
        issues.add(
          StatementImportIssue(
            code: StatementImportIssueCode.invalidAmount,
            message: 'Row amount could not be parsed cleanly.',
            rowNumber: rowNumber,
          ),
        );
      }

      if (description == null &&
          merchantName == null &&
          reference == null &&
          amountResult.amount == null) {
        issues.add(
          StatementImportIssue(
            code: StatementImportIssueCode.emptyEvidenceRow,
            message: 'Row did not contain enough evidence to import safely.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      records.add(
        ImportedStatementRecord(
          id: '$batchId:row:$rowNumber',
          batchId: batchId,
          rowNumber: rowNumber,
          occurredAt: occurredAt,
          description:
              description ?? merchantName ?? reference ?? 'Statement row',
          direction: amountResult.direction,
          currencyCode: _pick(valuesByColumn, _currencyHeaders) ?? 'INR',
          rawValuesByColumn: valuesByColumn,
          sourceLabel: sourceLabel,
          amount: amountResult.amount,
          merchantName: merchantName,
          reference: reference,
          channel: channel,
        ),
      );
    }

    return StatementImportParseResult(
      batchId: batchId,
      records: records,
      issues: issues,
    );
  }

  List<List<String>> _parseCsvRows(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var insideQuotes = false;

    for (var index = 0; index < input.length; index++) {
      final char = input[index];

      if (char == '"') {
        final nextChar = index + 1 < input.length ? input[index + 1] : null;
        if (insideQuotes && nextChar == '"') {
          currentCell.write('"');
          index++;
          continue;
        }

        insideQuotes = !insideQuotes;
        continue;
      }

      if (!insideQuotes && char == ',') {
        currentRow.add(currentCell.toString());
        currentCell.clear();
        continue;
      }

      if (!insideQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (!_isEmptyRow(currentRow)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow.clear();
        continue;
      }

      currentCell.write(char);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (!_isEmptyRow(currentRow)) {
        rows.add(List<String>.from(currentRow));
      }
    }

    return rows;
  }

  bool _isEmptyRow(List<String> row) {
    return row.every((cell) => cell.trim().isEmpty);
  }

  String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String? _pick(Map<String, String> valuesByColumn, Set<String> headers) {
    for (final header in headers) {
      final value = valuesByColumn[header];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  String? _descriptionFor(Map<String, String> valuesByColumn) {
    final direct = _pick(valuesByColumn, _descriptionHeaders);
    if (direct != null) {
      return direct;
    }

    final merchant = _pick(valuesByColumn, _merchantHeaders);
    final reference = _pick(valuesByColumn, _referenceHeaders);
    if (merchant != null && reference != null) {
      return '$merchant $reference';
    }

    return merchant ?? reference;
  }

  DateTime? _parseDate(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final trimmed = rawValue.trim();
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return direct;
    }

    final slashMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$')
        .firstMatch(trimmed);
    if (slashMatch != null) {
      final day = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final yearPart = int.parse(slashMatch.group(3)!);
      final year = yearPart < 100 ? 2000 + yearPart : yearPart;
      return DateTime(year, month, day);
    }

    final namedMonthMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})$',
    ).firstMatch(trimmed);
    if (namedMonthMatch != null) {
      final day = int.parse(namedMonthMatch.group(1)!);
      final month = _monthIndex(namedMonthMatch.group(2)!);
      final yearPart = int.parse(namedMonthMatch.group(3)!);
      final year = yearPart < 100 ? 2000 + yearPart : yearPart;
      if (month != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _monthIndex(String rawMonth) {
    const months = <String, int>{
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    return months[rawMonth.trim().toLowerCase()];
  }

  ({double? amount, ImportedStatementDirection direction, bool hadInvalidAmount})
      _resolveAmount(Map<String, String> valuesByColumn) {
    final debit = _parseAmount(_pick(valuesByColumn, _debitHeaders));
    if (debit.hadValue) {
      return (
        amount: debit.amount,
        direction: ImportedStatementDirection.debit,
        hadInvalidAmount: debit.hadInvalidAmount,
      );
    }

    final credit = _parseAmount(_pick(valuesByColumn, _creditHeaders));
    if (credit.hadValue) {
      return (
        amount: credit.amount,
        direction: ImportedStatementDirection.credit,
        hadInvalidAmount: credit.hadInvalidAmount,
      );
    }

    final amount = _parseAmount(_pick(valuesByColumn, _amountHeaders));
    final explicitDirection =
        _directionFor(_pick(valuesByColumn, _directionHeaders));
    return (
      amount: amount.amount,
      direction: explicitDirection,
      hadInvalidAmount: amount.hadInvalidAmount,
    );
  }

  ({double? amount, bool hadValue, bool hadInvalidAmount}) _parseAmount(
    String? rawValue,
  ) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return (amount: null, hadValue: false, hadInvalidAmount: false);
    }

    final cleaned = rawValue
        .trim()
        .replaceAll(RegExp(r'[\u20B9,]'), '')
        .replaceAll(RegExp(r'rs\.?', caseSensitive: false), '')
        .replaceAll(RegExp(r'inr', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null) {
      return (amount: null, hadValue: true, hadInvalidAmount: true);
    }

    return (amount: amount.abs(), hadValue: true, hadInvalidAmount: false);
  }

  ImportedStatementDirection _directionFor(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return ImportedStatementDirection.unknown;
    }

    final normalized = rawValue.trim().toLowerCase();
    if (normalized.contains('debit') ||
        normalized == 'dr' ||
        normalized.contains('outflow') ||
        normalized.contains('spent')) {
      return ImportedStatementDirection.debit;
    }
    if (normalized.contains('credit') ||
        normalized == 'cr' ||
        normalized.contains('inflow') ||
        normalized.contains('received')) {
      return ImportedStatementDirection.credit;
    }

    return ImportedStatementDirection.unknown;
  }
}
