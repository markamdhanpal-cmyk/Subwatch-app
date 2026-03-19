import '../models/review_item_action_models.dart';

abstract interface class ReviewActionStore {
  Future<List<ReviewItemDecision>> list();

  Future<void> save(ReviewItemDecision decision);

  Future<bool> remove(String targetKey);
}
