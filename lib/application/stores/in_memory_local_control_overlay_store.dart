import '../contracts/local_control_overlay_store.dart';
import '../models/local_control_overlay_models.dart';

class InMemoryLocalControlOverlayStore implements LocalControlOverlayStore {
  final Map<String, LocalControlDecision> _decisionsByTargetKey =
      <String, LocalControlDecision>{};

  @override
  Future<List<LocalControlDecision>> list() async {
    final decisions = _decisionsByTargetKey.values.toList(growable: false)
      ..sort((left, right) => left.targetKey.compareTo(right.targetKey));
    return decisions;
  }

  @override
  Future<void> save(LocalControlDecision decision) async {
    _decisionsByTargetKey[decision.targetKey] = decision;
  }

  @override
  Future<bool> remove(String targetKey) async {
    return _decisionsByTargetKey.remove(targetKey) != null;
  }

  @override
  Future<void> clear() async {
    _decisionsByTargetKey.clear();
  }
}
