abstract interface class ProblemReportLauncher {
  Future<bool> open({
    required String recipient,
    required String subject,
    required String body,
  });
}
