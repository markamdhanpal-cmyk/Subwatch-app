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

  static final RegExp subscriptionContextPattern = RegExp(
    r'\b(subscription|monthly subscription|subscription payment|membership)\b',
    caseSensitive: false,
  );

  static final RegExp planContextPattern = RegExp(
    r'\b(plan|monthly plan|pass|membership)\b',
    caseSensitive: false,
  );

  static final RegExp recurringContextPattern = RegExp(
    r'\b(recurring|renew(?:ed|al)?|monthly|annual|yearly|next billing|membership|premium)\b',
    caseSensitive: false,
  );

  static final RegExp billingPattern = RegExp(
    r'\b(charged|billed|debited|payment|spent|used|processed|deducted)\b',
    caseSensitive: false,
  );

  static final RegExp successPattern = RegExp(
    r'\b(successful|successfully|approved|completed|processed)\b',
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
        looksLikeTelecomBundle(body);
  }

  static bool hasMandateContext(String body) {
    return mandatePattern.hasMatch(body);
  }

  static bool hasUpiNoise(String body) {
    return upiNoisePattern.hasMatch(body);
  }

  static bool looksLikeTelecomBundle(String body) {
    if (telecomProviderPattern.hasMatch(body) &&
        telecomBenefitPattern.hasMatch(body)) {
      return true;
    }

    return telecomCoBrandedBundlePattern.hasMatch(body) &&
        telecomBundleMarkerPattern.hasMatch(body);
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
      final match = pattern.firstMatch(input);
      if (match == null) {
        continue;
      }

      final term = match.group(0);
      if (term != null) {
        terms.add(term.toLowerCase());
      }
    }

    return terms.toList(growable: false);
  }
}
