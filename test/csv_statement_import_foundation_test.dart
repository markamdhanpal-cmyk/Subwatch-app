import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/mappers/imported_statement_record_canonical_input_mapper.dart';
import 'package:sub_killer/application/models/statement_import_models.dart';
import 'package:sub_killer/application/parsers/csv_statement_import_parser.dart';
import 'package:sub_killer/application/use_cases/import_csv_statement_use_case.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('CSV statement import foundation', () {
    test('parser reads valid debit rows and preserves provenance fields', () {
      const parser = CsvStatementImportParser();

      final result = parser.parseCsv(
        csvText: '''
date,description,debit,merchant,ref,channel
2026-03-12,Netflix monthly charge,499,NETFLIX,NFX123,CARD
''',
        batchId: 'batch-1',
        sourceLabel: 'march_statement.csv',
      );

      expect(result.records, hasLength(1));
      expect(result.issues, isEmpty);
      expect(result.records.single.batchId, 'batch-1');
      expect(result.records.single.rowNumber, 2);
      expect(result.records.single.amount, 499);
      expect(result.records.single.description, 'Netflix monthly charge');
      expect(result.records.single.merchantName, 'NETFLIX');
      expect(result.records.single.reference, 'NFX123');
      expect(result.records.single.channel, 'CARD');
      expect(result.records.single.sourceLabel, 'march_statement.csv');
    });

    test('mapper emits canonical csv inputs with csv provenance', () {
      const parser = CsvStatementImportParser();
      const mapper = ImportedStatementRecordCanonicalInputMapper();
      final parsed = parser.parseCsv(
        csvText: '''
txn_date,narration,debit_amount,merchant_name
12/03/2026,"NETFLIX, monthly plan","INR 1,499.00",Netflix
''',
        batchId: 'batch-2',
      );

      final canonicalInput = mapper.map(parsed.records.single);

      expect(canonicalInput.kind, CanonicalInputKind.csv);
      expect(canonicalInput.origin.kind, CanonicalInputOriginKind.csvImport);
      expect(canonicalInput.origin.batchId, 'batch-2');
      expect(canonicalInput.subject, 'Netflix');
      expect(
        canonicalInput.textBody,
        contains('Statement import shows Rs 1499 debited'),
      );
      expect(
        canonicalInput.richTextSegments,
        contains('Description: NETFLIX, monthly plan'),
      );
    });

    test('import use case reuses canonical ingestion flow for valid rows',
        () async {
      final useCase = ImportCsvStatementUseCase(
        clock: () => DateTime(2026, 3, 20, 10, 0),
      );

      final result = await useCase.execute(
        csvText: '''
date,description,debit,merchant
2026-03-12,Streaming charge,499,NETFLIX
''',
        batchId: 'batch-3',
        sourceLabel: 'march_statement.csv',
      );

      expect(result.parseResult.records, hasLength(1));
      expect(result.canonicalInputs, hasLength(1));
      expect(result.events, hasLength(1));
      expect(result.events.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(result.ledgerEntries.single.totalBilled, 499);
    });

    test('partial and messy rows stay safe without faking certainty',
        () async {
      final useCase = ImportCsvStatementUseCase(
        clock: () => DateTime(2026, 3, 20, 10, 0),
      );

      final result = await useCase.execute(
        csvText: '''
transaction_date,narration,amount,merchant_name
bad-date,Mandate setup for Spotify,,Spotify
2026-03-14,,,,
2026-03-15,Statement note only,,Unknown Merchant
''',
        batchId: 'batch-4',
      );

      expect(result.parseResult.records, hasLength(1));
      expect(
        result.parseResult.issues.map((issue) => issue.code),
        containsAll(<StatementImportIssueCode>[
          StatementImportIssueCode.invalidDate,
          StatementImportIssueCode.emptyEvidenceRow,
        ]),
      );
      expect(result.canonicalInputs.single.kind, CanonicalInputKind.csv);
      expect(result.events, isEmpty);
      expect(result.ledgerEntries, isEmpty);
    });
  });
}

