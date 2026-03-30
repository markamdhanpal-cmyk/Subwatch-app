import '../../domain/entities/service_ledger_entry.dart';
import '../../domain/entities/subscription_event.dart';
import '../../v2/detection/models/canonical_input.dart';
import '../contracts/statement_import_parser.dart';
import '../mappers/imported_statement_record_canonical_input_mapper.dart';
import '../models/statement_import_models.dart';
import '../parsers/csv_statement_import_parser.dart';
import 'local_ingestion_flow_use_case.dart';

class CsvStatementImportResult {
  CsvStatementImportResult({
    required this.parseResult,
    required List<CanonicalInput> canonicalInputs,
    required List<SubscriptionEvent> events,
    required List<ServiceLedgerEntry> ledgerEntries,
  })  : canonicalInputs = List<CanonicalInput>.unmodifiable(canonicalInputs),
        events = List<SubscriptionEvent>.unmodifiable(events),
        ledgerEntries = List<ServiceLedgerEntry>.unmodifiable(ledgerEntries);

  final StatementImportParseResult parseResult;
  final List<CanonicalInput> canonicalInputs;
  final List<SubscriptionEvent> events;
  final List<ServiceLedgerEntry> ledgerEntries;
}

class ImportCsvStatementUseCase {
  ImportCsvStatementUseCase({
    StatementImportParser parser = const CsvStatementImportParser(),
    ImportedStatementRecordCanonicalInputMapper canonicalInputMapper =
        const ImportedStatementRecordCanonicalInputMapper(),
    LocalIngestionFlowUseCase? ingestionUseCase,
    DateTime Function()? clock,
  })  : _parser = parser,
        _canonicalInputMapper = canonicalInputMapper,
        _ingestionUseCase = ingestionUseCase ?? LocalIngestionFlowUseCase(),
        _clock = clock ?? DateTime.now;

  final StatementImportParser _parser;
  final ImportedStatementRecordCanonicalInputMapper _canonicalInputMapper;
  final LocalIngestionFlowUseCase _ingestionUseCase;
  final DateTime Function() _clock;

  Future<CsvStatementImportResult> execute({
    required String csvText,
    String? batchId,
    String? sourceLabel,
  }) async {
    final resolvedBatchId =
        batchId ?? 'csv_import_${_clock().microsecondsSinceEpoch}';
    final parseResult = _parser.parseCsv(
      csvText: csvText,
      batchId: resolvedBatchId,
      sourceLabel: sourceLabel,
    );
    final canonicalInputs = _canonicalInputMapper.mapAll(parseResult.records);
    if (canonicalInputs.isEmpty) {
      return CsvStatementImportResult(
        parseResult: parseResult,
        canonicalInputs: canonicalInputs,
        events: const <SubscriptionEvent>[],
        ledgerEntries: const <ServiceLedgerEntry>[],
      );
    }

    final ingestionResult = await _ingestionUseCase.executeCanonicalInputs(
      canonicalInputs,
    );
    return CsvStatementImportResult(
      parseResult: parseResult,
      canonicalInputs: canonicalInputs,
      events: ingestionResult.events,
      ledgerEntries: ingestionResult.ledgerEntries,
    );
  }
}
