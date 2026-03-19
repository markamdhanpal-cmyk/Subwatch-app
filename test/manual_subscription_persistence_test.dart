import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/manual_subscription_models.dart';
import 'package:sub_killer/application/stores/json_file_local_manual_subscription_store.dart';
import 'package:sub_killer/application/use_cases/handle_manual_subscription_use_case.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

void main() {
  group('Manual subscription persistence', () {
    late Directory tempDirectory;
    late JsonFileLocalManualSubscriptionStore store;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'sub-killer-manual-subscriptions-',
      );
      store = JsonFileLocalManualSubscriptionStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('manual subscriptions survive a fresh runtime load', () async {
      final createUseCase = HandleManualSubscriptionUseCase(
        localManualSubscriptionStore: store,
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          localManualSubscriptionStore: store,
          clock: () => DateTime(2026, 3, 16, 9, 30),
        ).execute(),
        clock: () => DateTime(2026, 3, 16, 9, 0),
      );

      final createResult = await createUseCase.create(
        serviceName: 'Adobe Creative Cloud',
        billingCycle: ManualSubscriptionBillingCycle.yearly,
        amountInput: '5999',
        nextRenewalDate: DateTime(2026, 12, 1),
        planLabel: 'Individual',
      );

      expect(createResult.outcome, HandleManualSubscriptionOutcome.created);
      expect(createResult.snapshot, isNotNull);
      expect(createResult.snapshot!.manualSubscriptions, hasLength(1));

      final reloaded = await LoadRuntimeDashboardUseCase(
        localManualSubscriptionStore: store,
        clock: () => DateTime(2026, 3, 16, 10, 0),
      ).execute();

      expect(reloaded.manualSubscriptions, hasLength(1));
      final entry = reloaded.manualSubscriptions.single;
      expect(entry.serviceName, 'Adobe Creative Cloud');
      expect(entry.billingCycle, ManualSubscriptionBillingCycle.yearly);
      expect(entry.amountInMinorUnits, 599900);
      expect(entry.nextRenewalDate, DateTime(2026, 12, 1));
      expect(entry.planLabel, 'Individual');
    });
  });
}
