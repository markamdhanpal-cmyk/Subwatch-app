import '../models/canonical_input.dart';
import '../models/normalized_input_record.dart';

abstract interface class CanonicalInputNormalizer {
  NormalizedInputRecord normalize(CanonicalInput input);

  List<NormalizedInputRecord> normalizeAll(Iterable<CanonicalInput> inputs);
}
