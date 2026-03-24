import '../contracts/review_action_store.dart';
import '../models/review_item_action_models.dart';

class InMemoryReviewActionStore implements ReviewActionStore {
  final Map<String, ReviewItemDecision> _decisionsByTargetKey =
      <String, ReviewItemDecision>{};

  @override
  Future<List<ReviewItemDecision>> list() async {
    final decisions = _decisionsByTargetKey.values.toList(growable: false)
      ..sort((left, right) => left.targetKey.compareTo(right.targetKey));
    return decisions;
  }

  @override
  Future<void> save(ReviewItemDecision decision) async {
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
