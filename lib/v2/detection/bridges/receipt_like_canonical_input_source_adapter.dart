import '../models/canonical_input.dart';
import '../contracts/canonical_input_source.dart';
import '../../../application/contracts/receipt_like_input_source.dart';
import '../../../application/mappers/receipt_like_input_canonical_input_mapper.dart';

class ReceiptLikeCanonicalInputSourceAdapter implements CanonicalInputSource {
  const ReceiptLikeCanonicalInputSourceAdapter({
    required ReceiptLikeInputSource source,
    ReceiptLikeInputCanonicalInputMapper canonicalInputMapper =
        const ReceiptLikeInputCanonicalInputMapper(),
  })  : _source = source,
        _canonicalInputMapper = canonicalInputMapper;

  final ReceiptLikeInputSource _source;
  final ReceiptLikeInputCanonicalInputMapper _canonicalInputMapper;

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final records = await _source.loadReceiptLikeInputs();
    return _canonicalInputMapper.mapAll(records);
  }
}
