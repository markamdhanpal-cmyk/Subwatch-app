import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';

void main() {
  test('runtime sample projection keeps unresolved-first key hygiene and blocks legacy candidate noise keys',
      () async {
    final snapshot = await LoadRuntimeDashboardUseCase(
      clock: () => DateTime(2026, 3, 24, 10, 0),
    ).execute();

    final serviceKeys = snapshot.cards
        .map((card) => card.serviceKey.value)
        .toList(growable: false);

    expect(serviceKeys, contains('NETFLIX'));
    expect(
      serviceKeys,
      isNot(contains('CLICK_IF_YOU_DO_NOT_HAVE_ANY_OTHER_DATA')),
    );
    expect(serviceKeys, isNot(contains('MODI')));
    expect(serviceKeys, isNot(contains('UNRESOLVED')));
  });
}

