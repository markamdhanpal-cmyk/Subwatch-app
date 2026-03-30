import '../models/canonical_input.dart';

abstract interface class CanonicalInputSource {
  Future<List<CanonicalInput>> loadCanonicalInputs();
}
