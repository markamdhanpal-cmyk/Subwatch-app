import '../models/canonical_input.dart';
import '../contracts/canonical_input_source.dart';
import '../../../application/contracts/bank_evidence_connector.dart';
import '../../../application/mappers/normalized_bank_transaction_canonical_input_mapper.dart';

class BankEvidenceConnectorCanonicalInputSourceAdapter
    implements CanonicalInputSource {
  const BankEvidenceConnectorCanonicalInputSourceAdapter({
    required BankEvidenceConnector connector,
    NormalizedBankTransactionCanonicalInputMapper canonicalInputMapper =
        const NormalizedBankTransactionCanonicalInputMapper(),
  })  : _connector = connector,
        _canonicalInputMapper = canonicalInputMapper;

  final BankEvidenceConnector _connector;
  final NormalizedBankTransactionCanonicalInputMapper _canonicalInputMapper;

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final result = await _connector.pullTransactions();
    return _canonicalInputMapper.mapAll(result.records);
  }
}
