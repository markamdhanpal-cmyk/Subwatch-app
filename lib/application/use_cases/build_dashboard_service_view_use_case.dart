import '../models/dashboard_service_view_models.dart';
import '../models/local_service_presentation_overlay_models.dart';
import '../../domain/entities/dashboard_card.dart';
import '../../domain/enums/dashboard_bucket.dart';

class BuildDashboardServiceViewUseCase {
  const BuildDashboardServiceViewUseCase();

  static const List<DashboardBucket> _visibleBucketOrder = <DashboardBucket>[
    DashboardBucket.confirmedSubscriptions,
    DashboardBucket.needsReview,
    DashboardBucket.trialsAndBenefits,
  ];

  DashboardServiceViewResult execute({
    required List<DashboardCard> cards,
    required Map<String, LocalServicePresentationState>
        localServicePresentationStates,
    required DashboardServiceViewControls controls,
  }) {
    final normalizedQuery = controls.normalizedSearchQuery.toLowerCase();
    final visibleBuckets = _visibleBucketsForFilter(controls.filterMode);
    final visibleBucketSet = visibleBuckets.toSet();
    final indexedCards = cards.indexed
        .where((entry) => visibleBucketSet.contains(entry.$2.bucket))
        .map(
          (entry) => (
            index: entry.$1,
            card: entry.$2,
            presentationState:
                localServicePresentationStates[entry.$2.serviceKey.value] ??
                    LocalServicePresentationState.fromDashboardCard(entry.$2),
          ),
        )
        .where(
          (entry) =>
              normalizedQuery.isEmpty ||
              _matchesSearchQuery(normalizedQuery, entry.presentationState),
        )
        .toList(growable: false);

    final sortedCards = indexedCards.toList(growable: false)
      ..sort((left, right) => _compareEntries(left, right, controls.sortMode));

    final sections = visibleBuckets
        .map(
          (bucket) => DashboardServiceSectionView(
            bucket: bucket,
            cards: sortedCards
                .where((entry) => entry.card.bucket == bucket)
                .map((entry) => entry.card)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    return DashboardServiceViewResult(
      controls: controls,
      sections: List<DashboardServiceSectionView>.unmodifiable(sections),
    );
  }

  List<DashboardBucket> _visibleBucketsForFilter(
    DashboardServiceFilterMode filterMode,
  ) {
    switch (filterMode) {
      case DashboardServiceFilterMode.allVisible:
        return _visibleBucketOrder;
      case DashboardServiceFilterMode.confirmedOnly:
        return const <DashboardBucket>[
          DashboardBucket.confirmedSubscriptions,
        ];
      case DashboardServiceFilterMode.observedOnly:
        return const <DashboardBucket>[
          DashboardBucket.needsReview,
        ];
      case DashboardServiceFilterMode.separateAccessOnly:
        return const <DashboardBucket>[
          DashboardBucket.trialsAndBenefits,
        ];
    }
  }

  bool _matchesSearchQuery(
    String normalizedQuery,
    LocalServicePresentationState presentationState,
  ) {
    return <String>{
      presentationState.displayTitle,
      presentationState.originalTitle,
      if (presentationState.localLabel != null) presentationState.localLabel!,
    }.any((value) => value.toLowerCase().contains(normalizedQuery));
  }

  int _compareEntries(
    ({
      DashboardCard card,
      int index,
      LocalServicePresentationState presentationState,
    }) left,
    ({
      DashboardCard card,
      int index,
      LocalServicePresentationState presentationState,
    }) right,
    DashboardServiceSortMode sortMode,
  ) {
    switch (sortMode) {
      case DashboardServiceSortMode.currentOrder:
        return left.index.compareTo(right.index);
      case DashboardServiceSortMode.nameAscending:
        return _compareByDisplayTitle(left, right);
      case DashboardServiceSortMode.nameDescending:
        return _compareByDisplayTitle(right, left);
    }
  }

  int _compareByDisplayTitle(
    ({
      DashboardCard card,
      int index,
      LocalServicePresentationState presentationState,
    }) left,
    ({
      DashboardCard card,
      int index,
      LocalServicePresentationState presentationState,
    }) right,
  ) {
    final titleComparison = left.presentationState.displayTitle
        .toLowerCase()
        .compareTo(right.presentationState.displayTitle.toLowerCase());
    if (titleComparison != 0) {
      return titleComparison;
    }

    final serviceKeyComparison =
        left.card.serviceKey.value.compareTo(right.card.serviceKey.value);
    if (serviceKeyComparison != 0) {
      return serviceKeyComparison;
    }

    return left.index.compareTo(right.index);
  }
}
