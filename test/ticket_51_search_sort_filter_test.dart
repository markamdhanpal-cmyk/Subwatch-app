import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/dashboard_service_view_models.dart';
import 'package:sub_killer/application/models/local_service_presentation_overlay_models.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_service_view_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  const useCase = BuildDashboardServiceViewUseCase();

  test('search matches detected name and local label only', () {
    final cards = <DashboardCard>[
      _card(
        key: 'NETFLIX',
        bucket: DashboardBucket.confirmedSubscriptions,
        title: 'Family streaming',
        subtitle: 'Movie nights',
      ),
    ];
    final states = <String, LocalServicePresentationState>{
      'NETFLIX': const LocalServicePresentationState(
        serviceKey: 'NETFLIX',
        originalTitle: 'Netflix',
        displayTitle: 'Family streaming',
        localLabel: 'Family streaming',
        isPinned: false,
      ),
    };

    final labelSearch = useCase.execute(
      cards: cards,
      localServicePresentationStates: states,
      controls: const DashboardServiceViewControls(searchQuery: 'family'),
    );
    final detectedNameSearch = useCase.execute(
      cards: cards,
      localServicePresentationStates: states,
      controls: const DashboardServiceViewControls(searchQuery: 'netflix'),
    );
    final subtitleSearch = useCase.execute(
      cards: cards,
      localServicePresentationStates: states,
      controls: const DashboardServiceViewControls(searchQuery: 'movie'),
    );

    expect(
      labelSearch.cardsForBucket(DashboardBucket.confirmedSubscriptions),
      hasLength(1),
    );
    expect(
      detectedNameSearch.cardsForBucket(DashboardBucket.confirmedSubscriptions),
      hasLength(1),
    );
    expect(subtitleSearch.hasMatches, isFalse);
  });

  test('filter keeps only visible service buckets', () {
    final cards = <DashboardCard>[
      _card(
        key: 'NETFLIX',
        bucket: DashboardBucket.confirmedSubscriptions,
        title: 'Netflix',
      ),
      _card(
        key: 'JIOHOTSTAR',
        bucket: DashboardBucket.needsReview,
        title: 'Jiohotstar',
      ),
      _card(
        key: 'GEMINI',
        bucket: DashboardBucket.trialsAndBenefits,
        title: 'Google Gemini Pro',
      ),
      _card(
        key: 'HIDDEN',
        bucket: DashboardBucket.hidden,
        title: 'Hidden Service',
      ),
    ];

    final allVisible = useCase.execute(
      cards: cards,
      localServicePresentationStates: const <String,
          LocalServicePresentationState>{},
      controls: const DashboardServiceViewControls(),
    );
    final observedOnly = useCase.execute(
      cards: cards,
      localServicePresentationStates: const <String,
          LocalServicePresentationState>{},
      controls: const DashboardServiceViewControls(
        filterMode: DashboardServiceFilterMode.observedOnly,
      ),
    );

    expect(allVisible.totalVisibleCount, 3);
    expect(allVisible.sections, hasLength(3));
    expect(allVisible.cardsForBucket(DashboardBucket.hidden), isEmpty);
    expect(observedOnly.sections, hasLength(1));
    expect(
      observedOnly.cardsForBucket(DashboardBucket.needsReview).single.title,
      'Jiohotstar',
    );
  });

  test('sort orders services by visible title', () {
    final cards = <DashboardCard>[
      _card(
        key: 'YOUTUBE',
        bucket: DashboardBucket.confirmedSubscriptions,
        title: 'YouTube Premium',
      ),
      _card(
        key: 'NETFLIX',
        bucket: DashboardBucket.confirmedSubscriptions,
        title: 'Netflix',
      ),
    ];

    final ascending = useCase.execute(
      cards: cards,
      localServicePresentationStates: const <String,
          LocalServicePresentationState>{},
      controls: const DashboardServiceViewControls(
        sortMode: DashboardServiceSortMode.nameAscending,
      ),
    );
    final descending = useCase.execute(
      cards: cards,
      localServicePresentationStates: const <String,
          LocalServicePresentationState>{},
      controls: const DashboardServiceViewControls(
        sortMode: DashboardServiceSortMode.nameDescending,
      ),
    );

    expect(
      ascending
          .cardsForBucket(DashboardBucket.confirmedSubscriptions)
          .first
          .title,
      'Netflix',
    );
    expect(
      descending
          .cardsForBucket(DashboardBucket.confirmedSubscriptions)
          .first
          .title,
      'YouTube Premium',
    );
  });

  testWidgets('service search empty state resets back to visible sections', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('service-search-input')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('service-search-input')),
      'no-match-service',
    );
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('service-view-empty-state')),
      findsOneWidget,
    );
    expect(find.text('Nothing matches this view'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsNothing,
    );

    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('reset-service-view-controls-empty')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('reset-service-view-controls-empty')),
    );

    expect(
      find.byKey(const ValueKey<String>('service-view-empty-state')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsWidgets,
    );
  });

  testWidgets('service filter narrows subscriptions browse sections only', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    expect(
      find.byKey(const ValueKey<String>('service-view-controls-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('service-sort-menu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('service-filter-menu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsNothing,
    );
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('service-filter-menu')),
    );
    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('service-filter-menu')),
    );
    expect(find.text('All').last, findsOneWidget);
    expect(find.text('Subscriptions').last, findsOneWidget);
    await tester.tap(
      find
          .widgetWithText(
            CheckedPopupMenuItem<DashboardServiceFilterMode>,
            'Trials & benefits',
          )
          .last,
    );
    await pumpDashboardShellUi(tester);

    expect(
      find.byKey(const ValueKey<String>('section-trialsAndBenefits')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey<String>('section-confirmedSubscriptions')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('section-reviewQueue')),
      findsNothing,
    );
  });

  testWidgets('trials and benefits stay collapsed until opened', (
    tester,
  ) async {
    await pumpDashboardShellApp(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );

    await openDashboardDestination(tester, 'subscriptions');
    await scrollDashboardUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('toggle-section-trialsAndBenefits')),
    );

    expect(
      find.byKey(const ValueKey<String>('section-trialsAndBenefits')),
      findsWidgets,
    );
    expect(find.text('Google Gemini Pro'), findsNothing);

    await tapAndPumpDashboardShell(
      tester,
      find.byKey(const ValueKey<String>('toggle-section-trialsAndBenefits')),
    );

    expect(find.text('Google Gemini Pro'), findsOneWidget);
  });
}

DashboardCard _card({
  required String key,
  required DashboardBucket bucket,
  required String title,
  String subtitle = 'Visible subtitle',
}) {
  return DashboardCard(
    serviceKey: ServiceKey(key),
    bucket: bucket,
    title: title,
    subtitle: subtitle,
    state: ResolverState.activePaid,
  );
}
