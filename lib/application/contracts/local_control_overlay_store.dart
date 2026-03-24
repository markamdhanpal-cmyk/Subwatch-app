import '../models/local_control_overlay_models.dart';

abstract interface class LocalControlOverlayStore {
  Future<List<LocalControlDecision>> list();

  Future<void> save(LocalControlDecision decision);

  Future<bool> remove(String targetKey);

  Future<void> clear();
}
