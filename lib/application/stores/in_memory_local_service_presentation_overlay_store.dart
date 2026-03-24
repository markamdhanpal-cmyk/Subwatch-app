import '../contracts/local_service_presentation_overlay_store.dart';
import '../models/local_service_presentation_overlay_models.dart';

class InMemoryLocalServicePresentationOverlayStore
    implements LocalServicePresentationOverlayStore {
  final Map<String, LocalServicePresentationOverlay> _overlaysByServiceKey =
      <String, LocalServicePresentationOverlay>{};

  @override
  Future<List<LocalServicePresentationOverlay>> list() async {
    final overlays = _overlaysByServiceKey.values.toList(growable: false)
      ..sort((left, right) => left.serviceKey.compareTo(right.serviceKey));
    return overlays;
  }

  @override
  Future<void> save(LocalServicePresentationOverlay overlay) async {
    _overlaysByServiceKey[overlay.serviceKey] = overlay;
  }

  @override
  Future<bool> remove(String serviceKey) async {
    return _overlaysByServiceKey.remove(serviceKey) != null;
  }

  @override
  Future<void> clear() async {
    _overlaysByServiceKey.clear();
  }
}
