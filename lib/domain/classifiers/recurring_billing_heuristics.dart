import '../knowledge/merchant_knowledge_base.dart';
import '../parsing/indian_amount_parser.dart';

class RecurringBillingHeuristics {
  const RecurringBillingHeuristics._();

  static final RegExp mandatePattern = RegExp(
    r'\b(mandate|autopay|auto[\s-]?pay|e[\s-]?mandate)\b',
    caseSensitive: false,
  );

  static final RegExp upiNoisePattern = RegExp(
    r'\b(upi|vpa|qr|bharatpe|paytm[\s-]?qr)\b',
    caseSensitive: false,
  );

  static final RegExp telecomProviderPattern = RegExp(
    r'\b(jio|airtel|vi)\b',
    caseSensitive: false,
  );

  static final RegExp telecomCoBrandedBundlePattern = RegExp(
    r'\bjiohotstar\b',
    caseSensitive: false,
  );

  static final RegExp telecomBenefitPattern = RegExp(
    r'\b(subscription|plan|pack|bundle|benefit|complimentary|free|recharge|unlocked)\b',
    caseSensitive: false,
  );

  static final RegExp telecomBundleMarkerPattern = RegExp(
    r'\b(bundle|benefit|complimentary|free|recharge|unlocked)\b',
    caseSensitive: false,
  );

  static final RegExp cancellationPattern = RegExp(
    r'\b(unsubscribed|cancelled|deactivated|stopped renewal|turned off auto-renew|subscription ended|subscription expired)\b',
    caseSensitive: false,
  );

  static final RegExp renewalRiskPattern = RegExp(
    r'\b(unable to renew|failed to renew|unsuccessful renewal|will retry|retry over next|renewal failed|renewal pending|cancel renewal|payment failed for renewal)\b',
    caseSensitive: false,
  );

  static final RegExp stopPaymentPattern = RegExp(
    r'\b(stop payment|request to stop|blocked|stop renewal|stop monthly)\b',
    caseSensitive: false,
  );

  static final RegExp activeStatusPattern = RegExp(
    r'\b(is active|status: active|active for)\b',
    caseSensitive: false,
  );

  static final RegExp subscriptionContextPattern = RegExp(
    r'\b(subscription|monthly subscription|subscription payment|membership|memberships)\b',
    caseSensitive: false,
  );

  static final RegExp planContextPattern = RegExp(
    r'\b(plan|monthly plan|pass|membership|passes|valid till|validity|vaidhta|expires? on|active till)\b',
    caseSensitive: false,
  );

  static final RegExp recurringContextPattern = RegExp(
    r'\b(recurring|renew(?:ed|al)?|monthly|annual|yearly|next billing|membership|premium|agla billing|agla renewal)\b',
    caseSensitive: false,
  );

  static final RegExp billingPattern = RegExp(
    r'\b(charged|billed|debited|payment|spent|used|processed|deducted|renew(?:ed|al)?|kati hai|nikale gaye|shulk|bhugtan)\b',
    caseSensitive: false,
  );

  static final RegExp successPattern = RegExp(
    r'\b(successful|successfully|approved|completed|processed|ho gaya|ho chuka|safal)\b',
    caseSensitive: false,
  );

  static final RegExp cardContextPattern = RegExp(
    r'\b(card|credit card|debit card|bank card|credit|debit|spent on|used at|ending|xx[0-9]{2,4})\b',
    caseSensitive: false,
  );

  static final RegExp directRecurringMerchantPattern =
      MerchantKnowledgeBase.aliasPatternForTypeLabels(
    <String>['direct_recurring'],
  );

  static final RegExp appStoreMerchantPattern =
      MerchantKnowledgeBase.aliasPatternForTypeLabels(
    <String>['app_store'],
  );

  static final RegExp merchantRoutingPattern = RegExp(
    r'\b(at|for|towards|on)\b',
    caseSensitive: false,
  );

  static bool hasProtectedNoise(String body) {
    return hasMandateContext(body) ||
        hasUpiNoise(body) ||
        looksLikeTelecomBundle(body) ||
        isStopRequest(body);
  }

  static bool isStopRequest(String body) {
    return stopPaymentPattern.hasMatch(body);
  }

  static bool hasMandateContext(String body) {
    return mandatePattern.hasMatch(body);
  }

  static bool hasUpiNoise(String body) {
    if (!upiNoisePattern.hasMatch(body)) return false;

    // Safety: If there is clear mandate/autopay language, don't treat UPI as noise.
    if (hasMandateContext(body)) return false;

    return true;
  }

  static bool looksLikeTelecomBundle(String body) {
    final lowerBody = body.toLowerCase();

    // Escape Hatch: Renewal-risk / Failure language
    if (renewalRiskPattern.hasMatch(lowerBody)) {
      return false;
    }

    final hasTelecomProvider = telecomProviderPattern.hasMatch(lowerBody);
    final hasTelecomBenefitMarker = telecomBenefitPattern.hasMatch(lowerBody);

    if (hasTelecomProvider && hasTelecomBenefitMarker) {
      // Direct detection of validity/recharge language suggests a telecom recharge, NOT a standalone sub.
      final hasRechargeLanguage = RegExp(
        r'\b(recharge|pack|complimentary|free|unlocked|benefit|validity|vaidhta|expires? on|active till)\b',
        caseSensitive: false,
      ).hasMatch(lowerBody);

      // Escape Hatch: Direct-billed subscription with no recharge/validity keywords
      final amount = extractAmount(body);
      if (isCredibleAmount(amount)) {
        final hasBillingLang = hasBillingContext(body) || hasSubscriptionContext(body);
        final hasSuccessRenewCharge = hasSuccessContext(body) || hasRecurringContext(body);
        
        if (hasBillingLang && hasSuccessRenewCharge && !hasRechargeLanguage) {
          // Strong billing evidence exists, and no recharge/validity noise
          return false;
        }
      }

      return true;
    }

    return telecomCoBrandedBundlePattern.hasMatch(lowerBody) &&
        telecomBundleMarkerPattern.hasMatch(lowerBody);
  }

  static bool hasSubscriptionContext(String body) {
    return subscriptionContextPattern.hasMatch(body);
  }

  static bool hasPlanContext(String body) {
    return planContextPattern.hasMatch(body);
  }

  static bool hasRecurringContext(String body) {
    return recurringContextPattern.hasMatch(body);
  }

  static bool hasBillingContext(String body) {
    return billingPattern.hasMatch(body);
  }

  static bool hasSuccessContext(String body) {
    return successPattern.hasMatch(body);
  }

  static bool hasCardContext(String body) {
    return cardContextPattern.hasMatch(body);
  }

  static bool hasDirectRecurringMerchant(String body) {
    return directRecurringMerchantPattern.hasMatch(body);
  }

  static bool hasAppStoreMerchant(String body) {
    return appStoreMerchantPattern.hasMatch(body);
  }

  static bool hasMerchantRoutingContext(String body) {
    return merchantRoutingPattern.hasMatch(body);
  }

  static bool isCredibleAmount(double? amount) {
    return amount != null && amount > 2;
  }

  static double? extractAmount(String input) {
    return IndianAmountParser.extract(input);
  }

  static List<String> capturedTerms(
    String input,
    Iterable<RegExp> patterns,
  ) {
    final terms = <String>{};

    for (final pattern in patterns) {
      final matches = pattern.allMatches(input);
      for (final match in matches) {
        final term = match.group(0);
        if (term != null) {
          terms.add(term.toLowerCase());
        }
      }
    }

    return terms.toList(growable: false);
  }
}
