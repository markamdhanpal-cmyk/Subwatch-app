import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import 'recurring_billing_heuristics.dart';

class WeakSignalReviewClassifier implements EventClassifier {
  const WeakSignalReviewClassifier();

  static const String classifierId = 'weak_signal_review';

  static final RegExp _renewalFailurePattern = RegExp(
    r'\b(?:unable|failed|unsuccessful)\s+to\s+renew\b|\brenewal\b.*\b(?:failed|unsuccessful|declined|pending)\b',
    caseSensitive: false,
  );
  static final RegExp _retryPattern = RegExp(
    r'\b(?:will\s+retry|retry(?:ing)?(?:\s+over|\s+within)?\s+next)\b',
    caseSensitive: false,
  );
  static final RegExp _cancellationPattern = RegExp(
    r'\bcancel(?:\s+your)?\s+renewal\b',
    caseSensitive: false,
  );

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
    final hasSubscriptionContext =
        RecurringBillingHeuristics.hasSubscriptionContext(body);
    final hasPlanContext = RecurringBillingHeuristics.hasPlanContext(body);
    final hasCardContext = RecurringBillingHeuristics.hasCardContext(body);
    final hasAppStoreMerchant =
        RecurringBillingHeuristics.hasAppStoreMerchant(body);
    final hasDirectRecurringMerchant =
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body);
    final hasRenewalFailureLanguage = _renewalFailurePattern.hasMatch(body);
    final hasRetryLanguage = _retryPattern.hasMatch(body);
    final hasCancellationLanguage = _cancellationPattern.hasMatch(body);
    final hasRenewalRiskLanguage = hasRenewalFailureLanguage ||
        hasRetryLanguage ||
        hasCancellationLanguage;
    final hasReviewableLifecycleContext = hasSubscriptionContext ||
        (hasPlanContext && hasRecurringContext) ||
        hasDirectRecurringMerchant ||
        hasAppStoreMerchant;

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
                    hasRecurringContext));
    final hasLifecycleReviewEvidence =
        hasRenewalRiskLanguage && hasReviewableLifecycleContext;

    if (pattern == null &&
        !hasMerchantReviewEvidence &&
        !hasLifecycleReviewEvidence) {
      return null;
    }

    final capturedTerms = pattern != null
        ? <String>[pattern.firstMatch(body)!.group(0)!.toLowerCase()]
        : RecurringBillingHeuristics.capturedTerms(
            body,
            <RegExp>[
              _renewalFailurePattern,
              _retryPattern,
              _cancellationPattern,
              RecurringBillingHeuristics.directRecurringMerchantPattern,
              RecurringBillingHeuristics.appStoreMerchantPattern,
              RecurringBillingHeuristics.subscriptionContextPattern,
              RecurringBillingHeuristics.planContextPattern,
              RecurringBillingHeuristics.recurringContextPattern,
              RecurringBillingHeuristics.billingPattern,
              RecurringBillingHeuristics.cardContextPattern,
            ],
          );

    final weakRecurringHintStrength =
        hasMerchantReviewEvidence || hasLifecycleReviewEvidence
            ? EvidenceFragmentStrength.medium
            : EvidenceFragmentStrength.weak;
    final weakRecurringHintConfidence =
        hasMerchantReviewEvidence || hasLifecycleReviewEvidence ? 0.72 : 0.58;
    final evidenceFragments = <EvidenceFragment>[
      EvidenceFragment(
        type: EvidenceFragmentType.weakRecurringHint,
        sourceMessageId: message.id,
        classifierId: classifierId,
        strength: weakRecurringHintStrength,
        confidence: weakRecurringHintConfidence,
        note: hasLifecycleReviewEvidence
            ? 'Renewal-risk subscription wording detected.'
            : 'Recurring-looking wording detected.',
        terms: capturedTerms,
      ),
      if (hasRenewalRiskLanguage)
        EvidenceFragment(
          type: EvidenceFragmentType.renewalHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.medium,
          confidence: 0.68,
          note: 'Renewal-risk lifecycle wording detected.',
          terms: capturedTerms,
        ),
      if (hasCancellationLanguage || hasRenewalFailureLanguage)
        EvidenceFragment(
          type: EvidenceFragmentType.cancellationHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.weak,
          confidence: 0.64,
          note: 'Cancellation or failed-renewal wording detected.',
          terms: capturedTerms,
        ),
      EvidenceFragment(
        type: EvidenceFragmentType.unknownReview,
        sourceMessageId: message.id,
        classifierId: classifierId,
        strength: EvidenceFragmentStrength.medium,
        confidence: 0.7,
        note: 'Insufficient trust for confirmed subscription truth.',
        terms: capturedTerms,
      ),
    ];

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.unknownReview,
      summary: hasLifecycleReviewEvidence
          ? 'Renewal-risk subscription signal routed to review.'
          : 'Recurring-looking message routed to review.',
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
      evidenceFragments: evidenceFragments,
    );
  }
}
