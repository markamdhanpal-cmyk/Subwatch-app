/// Legacy compatibility event types.
///
/// v3 runtime truth should rely on SubscriptionEvidenceKind and
/// ServiceDecisionState.
@Deprecated(
  'Compatibility-only enum. Prefer evidence-first service decision enums.',
)
enum SubscriptionEventType {
  ignore,
  oneTimePayment,
  mandateCreated,
  autopaySetup,
  mandateExecutedMicro,
  subscriptionBilled,
  bundleActivated,
  subscriptionCancelled,
  unknownReview,
}
