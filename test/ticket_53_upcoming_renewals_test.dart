import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/build_dashboard_upcoming_renewals_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/entities/dashboard_card.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

import 'support/dashboard_shell_test_harness.dart';

void main() {
  final useCase = BuildDashboardUpcomingRenewalsUseCase(
    clock: () => DateTime(2026, 3, 14, 9, 0),
  );

  test('upcoming renewals keep nearest explicit dates first', () {
    final result = useCase.execute(
      cards: <DashboardCard>[
        _card(
          key: 'NETFLIX',
          title: 'Netflix',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle:
              'Confirmed paid subscription - Renews on 20 Mar 2026 - \u20B9499',
        ),
        _card(
          key: 'YOUTUBE',
          title: 'YouTube Premium',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription - Renews on 16 Mar 2026',
        ),
        _card(
          key: 'ADOBE',
          title: 'Adobe',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle:
              'Confirmed paid subscription - Renews on 12 Mar 2026 - Rs 799',
        ),
      ],
    );

    expect(result.items, hasLength(2));
    expect(result.items.first.serviceTitle, 'YouTube Premium');
    expect(result.items.first.renewalDateLabel, '16 Mar 2026');
    expect(result.items.first.amountLabel, isNull);
    expect(result.items.last.serviceTitle, 'Netflix');
    expect(result.items.last.amountLabel, '\u20B9499');
  });

  test('upcoming renewals extract labels from Rs and INR subtitle amounts', () {
    final result = useCase.execute(
      cards: <DashboardCard>[
        _card(
          key: 'NETFLIX',
          title: 'Netflix',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle:
              'Confirmed paid subscription - Renews on 16 Mar 2026 - Rs. 499',
        ),
        _card(
          key: 'GOOGLE_ONE',
          title: 'Google One',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle:
              'Confirmed paid subscription - Renews on 18 Mar 2026 - INR 299',
        ),
      ],
    );

    expect(result.items, hasLength(2));
    expect(result.items.first.amountLabel, '\u20B9499');
    expect(result.items.last.amountLabel, '\u20B9299');
  });

  test(
      'upcoming renewals exclude review bundled and items without explicit dates',
      () {
    final result = useCase.execute(
      cards: <DashboardCard>[
        _card(
          key: 'NETFLIX',
          title: 'Netflix',
          bucket: DashboardBucket.confirmedSubscriptions,
          state: ResolverState.activePaid,
          subtitle: 'Confirmed paid subscription - \u20B9499',
        ),
        _card(
          key: 'JIOHOTSTAR',
          title: 'Jiohotstar',
          bucket: DashboardBucket.needsReview,
          state: ResolverState.possibleSubscription,
          subtitle: 'Needs confirmation - Renews on 15 Mar 2026 - Rs 149',
        ),
        _card(
          key: 'GEMINI',
          title: 'Google Gemini Pro',
          bucket: DashboardBucket.trialsAndBenefits,
          state: ResolverState.activeBundled,
          subtitle: 'Included access - Renews on 15 Mar 2026',
        ),
      ],
    );

    expect(result.hasItems, isFalse);
    expect(
      result.summaryCopy,
      'No renewal dates yet.',
    );
  });

  testWidgets('dashboard shows honest empty upcoming renewals state', (
    tester,
  ) async {
    await pumpConstrainedDashboardShell(
      tester,
      runtimeUseCase: LoadRuntimeDashboardUseCase(
        clock: () => DateTime(2026, 3, 14, 9, 0),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('upcoming-renewals-card')),
      findsNothing,
    );
    expect(find.text('Upcoming renewals'), findsNothing);
    expect(find.text('No renewal dates yet'), findsNothing);
  });
}

DashboardCard _card({
  required String key,
  required String title,
  required DashboardBucket bucket,
  required ResolverState state,
  required String subtitle,
}) {
  return DashboardCard(
    serviceKey: ServiceKey(key),
    bucket: bucket,
    title: title,
    subtitle: subtitle,
    state: state,
  );
}
