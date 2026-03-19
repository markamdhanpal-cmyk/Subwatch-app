import '../../domain/entities/dashboard_card.dart';
import '../../domain/enums/dashboard_bucket.dart';

enum DashboardServiceSortMode {
  currentOrder,
  nameAscending,
  nameDescending,
}

enum DashboardServiceFilterMode {
  allVisible,
  confirmedOnly,
  observedOnly,
  separateAccessOnly,
}

class DashboardServiceViewControls {
  const DashboardServiceViewControls({
    this.searchQuery = '',
    this.sortMode = DashboardServiceSortMode.currentOrder,
    this.filterMode = DashboardServiceFilterMode.allVisible,
  });

  final String searchQuery;
  final DashboardServiceSortMode sortMode;
  final DashboardServiceFilterMode filterMode;

  String get normalizedSearchQuery => searchQuery.trim();

  bool get isSearchActive => normalizedSearchQuery.isNotEmpty;
  bool get isFilterActive =>
      filterMode != DashboardServiceFilterMode.allVisible;
  bool get restrictsResults => isSearchActive || isFilterActive;
  bool get hasActiveControls =>
      isSearchActive ||
      isFilterActive ||
      sortMode != DashboardServiceSortMode.currentOrder;

  DashboardServiceViewControls copyWith({
    String? searchQuery,
    DashboardServiceSortMode? sortMode,
    DashboardServiceFilterMode? filterMode,
  }) {
    return DashboardServiceViewControls(
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      filterMode: filterMode ?? this.filterMode,
    );
  }
}

class DashboardServiceSectionView {
  const DashboardServiceSectionView({
    required this.bucket,
    required this.cards,
  });

  final DashboardBucket bucket;
  final List<DashboardCard> cards;

  int get count => cards.length;
  bool get isEmpty => cards.isEmpty;
}

class DashboardServiceViewResult {
  const DashboardServiceViewResult({
    required this.controls,
    required this.sections,
  });

  final DashboardServiceViewControls controls;
  final List<DashboardServiceSectionView> sections;

  int get totalVisibleCount =>
      sections.fold(0, (count, section) => count + section.cards.length);

  bool get hasMatches => totalVisibleCount > 0;

  List<DashboardCard> cardsForBucket(DashboardBucket bucket) {
    for (final section in sections) {
      if (section.bucket == bucket) {
        return section.cards;
      }
    }
    return const <DashboardCard>[];
  }
}
