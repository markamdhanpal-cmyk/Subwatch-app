enum DecisionBand {
  confirmedPaid,
  likelyPaid,
  needsReview,
  includedWithPlan,
  setupOnly,
  verificationOnly,
  ended,
  oneTimeOrNoise,
  ignored,
}

extension DecisionBandTrustSemantics on DecisionBand {
  bool get isConfirmedPaidTruth => this == DecisionBand.confirmedPaid;

  bool get isIncludedBenefit => this == DecisionBand.includedWithPlan;

  bool get isConservativePossible =>
      this == DecisionBand.likelyPaid ||
      this == DecisionBand.needsReview ||
      this == DecisionBand.setupOnly ||
      this == DecisionBand.verificationOnly;
}
