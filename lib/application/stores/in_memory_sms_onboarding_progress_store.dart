import '../contracts/sms_onboarding_progress_store.dart';

class InMemorySmsOnboardingProgressStore implements SmsOnboardingProgressStore {
  bool _completed = false;

  @override
  Future<bool> readCompleted() async => _completed;

  @override
  Future<void> writeCompleted(bool completed) async {
    _completed = completed;
  }

  @override
  Future<void> clear() async {
    _completed = false;
  }
}
