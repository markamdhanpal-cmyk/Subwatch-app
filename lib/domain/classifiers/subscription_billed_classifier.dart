import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import 'recurring_billing_heuristics.dart';

class SubscriptionBilledClassifier implements EventClassifier {
  const SubscriptionBilledClassifier();

  static const String classifierId = 'subscription_billed';

  static final RegExp annualCadencePattern = RegExp(
    r'\b(annual|yearly|12-month|one-year|1 year|1-year|1year)\b',
    caseSensitive: false,
  );

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    final isAnnualSignal = annualCadencePattern.hasMatch(body) ||
        ((body.contains('1499') || body.contains('499') || body.contains('999')) && 
         body.toLowerCase().contains('hotstar')) ||
        (body.contains('1290') && body.toLowerCase().contains('youtube'));

    // Annual/High-confidence signals bypass general noise veto
    final hasMandateNoise = RecurringBillingHeuristics.hasMandateContext(body);
    final hasUpiNoise = RecurringBillingHeuristics.hasUpiNoise(body);
    final isTelecomBundle = RecurringBillingHeuristics.looksLikeTelecomBundle(body);

    if (body.isEmpty) return null;

    // Strict veto only if NOT a strong annual signal
    if (!isAnnualSignal && (hasMandateNoise || hasUpiNoise || isTelecomBundle)) {
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
    final hasAnnualCadence = annualCadencePattern.hasMatch(body);

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

    // Annual Single-Message Confirmation Rule
    final hasAnnualConfirmation = isAnnualSignal &&
        (hasDirectRecurringMerchant || hasAppStoreMerchant) &&
        (hasBillingContext || hasSubscriptionContext || hasMandateNoise);

    if (!hasStrongSubscriptionEvidence &&
        !hasStrongPlanEvidence &&
        !hasStrongMerchantEvidence &&
        !hasStrongAppStoreServiceEvidence &&
        !hasAnnualConfirmation) {
      return null;
    }

    final capturedTerms = RecurringBillingHeuristics.capturedTerms(
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
    );

    final evidenceFragments = <EvidenceFragment>[
      EvidenceFragment(
        type: EvidenceFragmentType.billedSuccess,
        sourceMessageId: message.id,
        classifierId: classifierId,
        strength: EvidenceFragmentStrength.strong,
        confidence: 0.95,
        amount: amount,
        note: 'Strong recurring billing evidence detected.',
        terms: capturedTerms,
      ),
      if (hasRecurringContext || body.toLowerCase().contains('renew'))
        EvidenceFragment(
          type: EvidenceFragmentType.renewalHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.medium,
          confidence: 0.8,
          amount: amount,
          note: 'Renewal or recurring wording present.',
          terms: capturedTerms,
        ),
    ];

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.subscriptionBilled,
      summary: 'Strong recurring billing evidence detected.',
      detectedAt: message.receivedAt,
      amount: amount,
      capturedTerms: capturedTerms,
      evidenceFragments: evidenceFragments,
    );
  }
}
