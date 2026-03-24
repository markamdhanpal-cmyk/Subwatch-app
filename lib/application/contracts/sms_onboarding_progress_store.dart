abstract interface class SmsOnboardingProgressStore {
  Future<bool> readCompleted();

  Future<void> writeCompleted(bool completed);

  Future<void> clear();
}
