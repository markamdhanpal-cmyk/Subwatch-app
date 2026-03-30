class SubscriptionScore {
  SubscriptionScore({
    required this.modelVersion,
    required this.featureSchemaVersion,
    required this.subscriptionProbability,
    required this.reviewPriorityScore,
    List<String> contributingSignals = const <String>[],
  }) : contributingSignals =
           List<String>.unmodifiable(contributingSignals);

  final String modelVersion;
  final int featureSchemaVersion;
  final double subscriptionProbability;
  final double reviewPriorityScore;
  final List<String> contributingSignals;
}
