class SubscriptionScoringModelArtifact {
  const SubscriptionScoringModelArtifact({
    required this.modelVersion,
    required this.featureSchemaVersion,
    required this.intercept,
    required this.weights,
  });

  final String modelVersion;
  final int featureSchemaVersion;
  final double intercept;
  final Map<String, double> weights;
}
