import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import 'recurring_billing_heuristics.dart';

class SubscriptionBilledClassifier implements EventClassifier {
  const SubscriptionBilledClassifier();

  // Legacy parsed-signal classifier kept for compatibility shadowing.
  // It should emit only strong paid evidence candidates.

  static const String classifierId = 'subscription_billed';

  static final RegExp annualCadencePattern = RegExp(
    r'\b(annual|yearly|12-month|one-year|1 year|1-year|1year)\b',
    caseSensitive: false,
  );

  static final RegExp _negativeOutcomePattern = RegExp(
    r'\b(?:failed|unsuccessful|unable|pending|retry|will retry|scheduled|due soon)\b',
    caseSensitive: false,
  );

  static final RegExp _bundleLanguagePattern = RegExp(
    r'\b(?:included|benefit|complimentary|free|unlocked|recharge)\b',
    caseSensitive: false,
  );

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final amount = RecurringBillingHeuristics.extractAmount(body);
    if (!RecurringBillingHeuristics.isCredibleAmount(amount)) {
      return null;
    }

    if (_negativeOutcomePattern.hasMatch(body)) {
      return null;
    }

    final hasMandateNoise = RecurringBillingHeuristics.hasMandateContext(body);
    final hasUpiNoise = RecurringBillingHeuristics.hasUpiNoise(body);
    final isTelecomBundle =
        RecurringBillingHeuristics.looksLikeTelecomBundle(body);
    if (hasMandateNoise || hasUpiNoise || isTelecomBundle) {
      return null;
    }

    final directRecurringEntry =
        MerchantKnowledgeBase.matchKnownDirectRecurringMerchant(body);
    final hasKnownRecurringMerchant = directRecurringEntry != null;

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
    final isAnnualSignal = annualCadencePattern.hasMatch(body);
    final hasBundleLanguage = _bundleLanguagePattern.hasMatch(body);
    final hasMerchantBundleContext = directRecurringEntry != null &&
        MerchantKnowledgeBase.hasBundleContextForEntry(
          body,
          directRecurringEntry,
        );
    final hasAnyBundleContext = hasBundleLanguage || hasMerchantBundleContext;
    final hasExplicitPlanOrSubscriptionContext =
        hasSubscriptionContext || hasPlanContext;

    final hasBillingSuccess =
        hasBillingContext && (hasSuccessContext || hasRecurringContext);
    final hasSubscriptionFrame =
        hasExplicitPlanOrSubscriptionContext || hasRecurringContext;

    final hasDirectPaidSignal = hasDirectRecurringMerchant &&
        hasBillingSuccess &&
        hasSubscriptionFrame &&
        !hasAnyBundleContext;
    final hasKnownMerchantPaidSignal = hasKnownRecurringMerchant &&
        hasBillingSuccess &&
        hasExplicitPlanOrSubscriptionContext &&
        !hasAnyBundleContext;
    final hasAppStorePaidSignal = hasAppStoreMerchant &&
        hasDirectRecurringMerchant &&
        hasBillingSuccess &&
        hasExplicitPlanOrSubscriptionContext &&
        !hasAnyBundleContext;
    final hasCardDebitForRecurringMerchant = hasDirectRecurringMerchant &&
        hasCardContext &&
        hasBillingContext &&
        hasSubscriptionFrame &&
        !hasAnyBundleContext;
    final hasAnnualSingleChargeSignal = isAnnualSignal &&
        (hasDirectPaidSignal ||
            hasKnownMerchantPaidSignal ||
            hasAppStorePaidSignal);

    if (!(hasDirectPaidSignal ||
        hasKnownMerchantPaidSignal ||
        hasAppStorePaidSignal ||
        hasCardDebitForRecurringMerchant ||
        hasAnnualSingleChargeSignal)) {
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
        annualCadencePattern,
      ],
    );
    final merchantHints = <String>{
      if (RecurringBillingHeuristics.extractMerchantHint(
            body,
            requiredTypeLabels: const <String>['direct_recurring'],
          )
          case final direct?)
        direct,
      if (RecurringBillingHeuristics.extractMerchantHint(
            body,
            requiredTypeLabels: const <String>['app_store'],
          )
          case final appStore?)
        appStore,
    };
    capturedTerms.addAll(merchantHints);

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.subscriptionBilled,
      summary: 'Strong recurring billing evidence detected.',
      detectedAt: message.receivedAt,
      amount: amount,
      capturedTerms: capturedTerms,
      evidenceFragments: <EvidenceFragment>[
        EvidenceFragment(
          type: EvidenceFragmentType.billedSuccess,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.strong,
          confidence: hasAnnualSingleChargeSignal ? 0.96 : 0.94,
          amount: amount,
          note: hasAnnualSingleChargeSignal
              ? 'Annual direct paid subscription evidence detected.'
              : 'Direct paid recurring billing evidence detected.',
          terms: capturedTerms,
        ),
      ],
    );
  }
}
