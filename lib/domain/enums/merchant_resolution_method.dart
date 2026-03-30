enum MerchantResolutionMethod {
  protectedUnresolved,
  senderIdPrefix,
  exactAlias,
  tokenAlias,
  fuzzyAlias,
  extractedCandidate,
  providerBundleFallback,
  ambiguousUnresolved,
  noMatch,
}
