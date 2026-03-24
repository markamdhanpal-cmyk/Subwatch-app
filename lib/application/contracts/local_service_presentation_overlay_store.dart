import '../models/local_service_presentation_overlay_models.dart';

abstract interface class LocalServicePresentationOverlayStore {
  Future<List<LocalServicePresentationOverlay>> list();

  Future<void> save(LocalServicePresentationOverlay overlay);

  Future<bool> remove(String serviceKey);

  Future<void> clear();
}
