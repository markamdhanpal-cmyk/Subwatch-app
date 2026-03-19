import '../contracts/sms_onboarding_progress_store.dart';
import '../stores/json_file_sms_onboarding_progress_store.dart';

class LoadSmsOnboardingProgressUseCase {
  LoadSmsOnboardingProgressUseCase({
    required SmsOnboardingProgressStore store,
  }) : _store = store;

  factory LoadSmsOnboardingProgressUseCase.persistent() {
    return LoadSmsOnboardingProgressUseCase(
      store: JsonFileSmsOnboardingProgressStore.applicationSupport(),
    );
  }

  final SmsOnboardingProgressStore _store;

  Future<bool> execute() {
    return _store.readCompleted();
  }
}
