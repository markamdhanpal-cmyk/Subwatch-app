import '../contracts/event_classifier.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/subscription_event_type.dart';
import 'recurring_billing_heuristics.dart';

class SubscriptionBilledClassifier implements EventClassifier {
  const SubscriptionBilledClassifier();

  static const String classifierId = 'subscription_billed';

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty || RecurringBillingHeuristics.hasProtectedNoise(body)) {
      return null;
    }

    final amount = RecurringBillingHeuristics.extractAmount(body);
    if (!RecurringBillingHeuristics.isCredibleAmount(amount)) {
      return null;
    }

    final hasSubscriptionContext =
        RecurringBillingHeuristics.hasSubscriptionContext(body);
    final hasPlanContext = RecurringBillingHeuristics.hasPlanContext(body);
    final hasRecurringContext =
        RecurringBillingHeuristics.hasRecurringContext(body);
    final hasBillingContext =
        RecurringBillingHeuristics.hasBillingContext(body);
    final hasSuccessContext =
        RecurringBillingHeuristics.hasSuccessContext(body);
    final hasCardContext = RecurringBillingHeuristics.hasCardContext(body);
    final hasDirectRecurringMerchant =
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body);
    final hasAppStoreMerchant =
        RecurringBillingHeuristics.hasAppStoreMerchant(body);
    final hasMerchantRoutingContext =
        RecurringBillingHeuristics.hasMerchantRoutingContext(body);

    final hasStrongSubscriptionEvidence = hasSubscriptionContext &&
        (hasRecurringContext || hasBillingContext) &&
        (hasSuccessContext || hasRecurringContext || hasBillingContext);
    final hasStrongPlanEvidence = hasPlanContext &&
        hasRecurringContext &&
        (hasBillingContext || hasSuccessContext);
    final hasStrongMerchantEvidence = hasDirectRecurringMerchant &&
        hasBillingContext &&
        (hasSuccessContext ||
            hasRecurringContext ||
            hasCardContext ||
            hasMerchantRoutingContext);
    final hasStrongAppStoreServiceEvidence =
        hasAppStoreMerchant && hasDirectRecurringMerchant && hasBillingContext;

    if (!hasStrongSubscriptionEvidence &&
        !hasStrongPlanEvidence &&
        !hasStrongMerchantEvidence &&
        !hasStrongAppStoreServiceEvidence) {
      return null;
    }

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.subscriptionBilled,
      summary: 'Strong recurring billing evidence detected.',
      detectedAt: message.receivedAt,
      amount: amount,
      capturedTerms: RecurringBillingHeuristics.capturedTerms(
        body,
        <RegExp>[
          RecurringBillingHeuristics.subscriptionContextPattern,
          RecurringBillingHeuristics.planContextPattern,
          RecurringBillingHeuristics.recurringContextPattern,
          RecurringBillingHeuristics.billingPattern,
          RecurringBillingHeuristics.successPattern,
          RecurringBillingHeuristics.directRecurringMerchantPattern,
          RecurringBillingHeuristics.appStoreMerchantPattern,
          RecurringBillingHeuristics.cardContextPattern,
        ],
      ),
    );
  }
}
