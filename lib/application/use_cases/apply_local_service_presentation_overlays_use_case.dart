import '../contracts/local_service_presentation_overlay_store.dart';
import '../models/local_service_presentation_overlay_models.dart';
import '../../domain/entities/dashboard_card.dart';

class AppliedLocalServicePresentationOverlaysResult {
  const AppliedLocalServicePresentationOverlaysResult({
    required this.cards,
    required this.servicePresentationStates,
  });

  final List<DashboardCard> cards;
  final Map<String, LocalServicePresentationState> servicePresentationStates;
}

class ApplyLocalServicePresentationOverlaysUseCase {
  const ApplyLocalServicePresentationOverlaysUseCase({
    required LocalServicePresentationOverlayStore
        localServicePresentationOverlayStore,
  }) : _localServicePresentationOverlayStore =
            localServicePresentationOverlayStore;

  final LocalServicePresentationOverlayStore
      _localServicePresentationOverlayStore;

  Future<AppliedLocalServicePresentationOverlaysResult> execute({
    required List<DashboardCard> cards,
  }) async {
    final overlays = await _localServicePresentationOverlayStore.list();
    final overlaysByServiceKey = <String, LocalServicePresentationOverlay>{
      for (final overlay in overlays) overlay.serviceKey: overlay,
    };
    final servicePresentationStates = <String, LocalServicePresentationState>{};
    final indexedCards = cards.indexed.map(
      (entry) {
        final index = entry.$1;
        final card = entry.$2;
        final state = servicePresentationStates.putIfAbsent(
          card.serviceKey.value,
          () => LocalServicePresentationState.fromDashboardCard(
            card,
            overlay: overlaysByServiceKey[card.serviceKey.value],
          ),
        );
        return (
          index: index,
          card: state.displayTitle == card.title
              ? card
              : DashboardCard(
                  serviceKey: card.serviceKey,
                  bucket: card.bucket,
                  title: state.displayTitle,
                  subtitle: card.subtitle,
                  state: card.state,
                  amountLabel: card.amountLabel,
                  frequencyLabel: card.frequencyLabel,
                ),
          isPinned: state.isPinned,
        );
      },
    ).toList(growable: false)
      ..sort((left, right) {
        if (left.isPinned != right.isPinned) {
          return left.isPinned ? -1 : 1;
        }
        return left.index.compareTo(right.index);
      });

    return AppliedLocalServicePresentationOverlaysResult(
      cards: indexedCards.map((entry) => entry.card).toList(growable: false),
      servicePresentationStates:
          Map<String, LocalServicePresentationState>.unmodifiable(
        servicePresentationStates,
      ),
    );
  }
}
