import '../models/statement_import_models.dart';

abstract interface class StatementImportParser {
  StatementImportParseResult parseCsv({
    required String csvText,
    required String batchId,
    String? sourceLabel,
  });
}
