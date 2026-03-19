import '../contracts/event_classifier.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/subscription_event_type.dart';
import 'recurring_billing_heuristics.dart';

class WeakSignalReviewClassifier implements EventClassifier {
  const WeakSignalReviewClassifier();

  static const String classifierId = 'weak_signal_review';

  static final List<RegExp> _positivePatterns = <RegExp>[
    RegExp(
        r'\b(?:membership|subscription)\b.*\b(?:due soon|shortly|renew shortly|may renew|set to renew|will renew|renewing on|reminder|next cycle)\b',
        caseSensitive: false),
    RegExp(r'\b(?:service )?plan reminder\b', caseSensitive: false),
    RegExp(r'\bplan\b.*\bnext cycle\b', caseSensitive: false),
    RegExp(r'\bupcoming payment\b', caseSensitive: false),
    RegExp(
        r'\brecurring payment instruction\b.*\b(?:under process|in process|processing)\b',
        caseSensitive: false),
    RegExp(
        r'\b(?:google play|googleplay|apple(?:\.com\/bill| services| bill)|itunes|app store)\b.*\b(?:recurring|subscription|membership|monthly|renewal)\b',
        caseSensitive: false),
  ];

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty || RecurringBillingHeuristics.hasProtectedNoise(body)) {
      return null;
    }

    final amount = RecurringBillingHeuristics.extractAmount(body);
    final hasBillingContext =
        RecurringBillingHeuristics.hasBillingContext(body);
    final hasRecurringContext =
        RecurringBillingHeuristics.hasRecurringContext(body);
    final hasCardContext = RecurringBillingHeuristics.hasCardContext(body);
    final hasAppStoreMerchant =
        RecurringBillingHeuristics.hasAppStoreMerchant(body);
    final hasDirectRecurringMerchant =
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body);

    RegExp? pattern;
    for (final candidate in _positivePatterns) {
      if (candidate.hasMatch(body)) {
        pattern = candidate;
        break;
      }
    }

    final hasMerchantReviewEvidence =
        RecurringBillingHeuristics.isCredibleAmount(amount) &&
            hasBillingContext &&
            ((hasAppStoreMerchant && (hasRecurringContext || hasCardContext)) ||
                (hasDirectRecurringMerchant &&
                    hasCardContext &&
                    !hasRecurringContext));

    if (pattern == null && !hasMerchantReviewEvidence) {
      return null;
    }

    final capturedTerms = pattern != null
        ? <String>[pattern.firstMatch(body)!.group(0)!.toLowerCase()]
        : RecurringBillingHeuristics.capturedTerms(
            body,
            <RegExp>[
              RecurringBillingHeuristics.directRecurringMerchantPattern,
              RecurringBillingHeuristics.appStoreMerchantPattern,
              RecurringBillingHeuristics.billingPattern,
              RecurringBillingHeuristics.cardContextPattern,
              RecurringBillingHeuristics.recurringContextPattern,
            ],
          );

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.unknownReview,
      summary: 'Recurring-looking message routed to review.',
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
    );
  }
}
