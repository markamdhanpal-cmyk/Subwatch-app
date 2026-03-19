import '../contracts/sms_onboarding_progress_store.dart';
import '../stores/json_file_sms_onboarding_progress_store.dart';

class CompleteSmsOnboardingUseCase {
  CompleteSmsOnboardingUseCase({
    required SmsOnboardingProgressStore store,
  }) : _store = store;

  factory CompleteSmsOnboardingUseCase.persistent() {
    return CompleteSmsOnboardingUseCase(
      store: JsonFileSmsOnboardingProgressStore.applicationSupport(),
    );
  }

  final SmsOnboardingProgressStore _store;

  Future<void> execute() {
    return _store.writeCompleted(true);
  }
}
