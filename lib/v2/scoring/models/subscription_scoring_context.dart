class SubscriptionScoringContext {
  const SubscriptionScoringContext({
    this.userConfirmedCount = 0,
    this.userRejectedCount = 0,
    this.userMarkedBenefitCount = 0,
  });

  final int userConfirmedCount;
  final int userRejectedCount;
  final int userMarkedBenefitCount;
}
