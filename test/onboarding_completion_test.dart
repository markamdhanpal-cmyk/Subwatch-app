import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/stores/in_memory_sms_onboarding_progress_store.dart';
import 'package:sub_killer/application/use_cases/complete_sms_onboarding_use_case.dart';
import 'package:sub_killer/application/use_cases/load_sms_onboarding_progress_use_case.dart';

void main() {
  group('Onboarding Completion Tracking', () {
    test('initially onboarding is not completed', () async {
      final store = InMemorySmsOnboardingProgressStore();
      final loadUseCase = LoadSmsOnboardingProgressUseCase(store: store);
      
      final completed = await loadUseCase.execute();
      expect(completed, isFalse);
    });

    test('completing onboarding updates the store status', () async {
      final store = InMemorySmsOnboardingProgressStore();
      final loadUseCase = LoadSmsOnboardingProgressUseCase(store: store);
      final completeUseCase = CompleteSmsOnboardingUseCase(store: store);

      await completeUseCase.execute();
      
      final completed = await loadUseCase.execute();
      expect(completed, isTrue);
    });

    test('clearing store resets onboarding status', () async {
      final store = InMemorySmsOnboardingProgressStore();
      final loadUseCase = LoadSmsOnboardingProgressUseCase(store: store);
      final completeUseCase = CompleteSmsOnboardingUseCase(store: store);

      await completeUseCase.execute();
      expect(await loadUseCase.execute(), isTrue);

      await store.clear();
      expect(await loadUseCase.execute(), isFalse);
    });
  });
}
