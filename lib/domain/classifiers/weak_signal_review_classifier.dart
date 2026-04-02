import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
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
  static final RegExp _suspensionPattern = RegExp(
    r'\b(?:suspend(?:ed)?|deactivate(?:d)?|blocked|on\s+hold)\b',
    caseSensitive: false,
  );
  static final RegExp _trialEndingPattern = RegExp(
    r'\b(?:free\s+)?trial\b.*\b(?:ending|ends|expires?|expiring|is\s+up)\b',
    caseSensitive: false,
  );
  static final RegExp _expiryPattern = RegExp(
    r'\b(?:expires?|expiring|expiry)\b.*\b(?:on|soon|shortly|on|in)\b',
    caseSensitive: false,
  );

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
    final hasAppStoreMerchant =
        RecurringBillingHeuristics.hasAppStoreMerchant(body);
    final hasDirectRecurringMerchant =
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body);
    final hasKnownRecurringMerchant = MerchantKnowledgeBase.matchKnownMerchant(
          body,
          requiredTypeLabels: const <String>[
            'direct_recurring',
            'app_store',
          ],
          allowWeakReview: false,
          allowBundleSignals: false,
        ) !=
        null;
    final hasRenewalFailureLanguage = _renewalFailurePattern.hasMatch(body);
    final hasRetryLanguage = _retryPattern.hasMatch(body);
    final hasCancellationLanguage = _cancellationPattern.hasMatch(body);
    final hasSuspensionLanguage = _suspensionPattern.hasMatch(body);
    final hasTrialEndingLanguage = _trialEndingPattern.hasMatch(body);
    final hasExpiryLanguage = _expiryPattern.hasMatch(body);

    final hasRenewalRiskLanguage = hasRenewalFailureLanguage ||
        hasRetryLanguage ||
        hasCancellationLanguage ||
        hasSuspensionLanguage ||
        hasTrialEndingLanguage ||
        hasExpiryLanguage;
    if (!hasRenewalRiskLanguage) {
      return null;
    }

    final hasRecurringLifecycleContext =
        (hasSubscriptionContext || hasRecurringContext || hasPlanContext) &&
            (hasDirectRecurringMerchant ||
                hasAppStoreMerchant ||
                hasKnownRecurringMerchant);
    if (!hasRecurringLifecycleContext) {
      return null;
    }

    if (hasBillingContext &&
        amount != null &&
        amount <= 2 &&
        !hasDirectRecurringMerchant &&
        !hasAppStoreMerchant) {
      return null;
    }

    final capturedTerms = RecurringBillingHeuristics.capturedTerms(
      body,
      <RegExp>[
        _renewalFailurePattern,
        _retryPattern,
        _cancellationPattern,
        _suspensionPattern,
        _trialEndingPattern,
        _expiryPattern,
        RecurringBillingHeuristics.subscriptionContextPattern,
        RecurringBillingHeuristics.planContextPattern,
      ],
    );
    if (RecurringBillingHeuristics.extractMerchantHint(
          body,
          requiredTypeLabels: const <String>['direct_recurring', 'app_store'],
          allowBundleSignals: false,
        )
        case final merchantHint?) {
      capturedTerms.add(merchantHint);
    }

    final evidenceFragments = <EvidenceFragment>[
      EvidenceFragment(
        type: EvidenceFragmentType.weakRecurringHint,
        sourceMessageId: message.id,
        classifierId: classifierId,
        strength: EvidenceFragmentStrength.medium,
        confidence: 0.71,
        note: 'Renewal-risk recurring lifecycle wording detected.',
        terms: capturedTerms,
      ),
      if (hasRenewalFailureLanguage ||
          hasRetryLanguage ||
          hasTrialEndingLanguage ||
          hasExpiryLanguage)
        EvidenceFragment(
          type: EvidenceFragmentType.renewalHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.medium,
          confidence: 0.7,
          note: 'Renewal-risk lifecycle wording detected.',
          terms: capturedTerms,
        ),
      if (hasCancellationLanguage ||
          hasRenewalFailureLanguage ||
          hasSuspensionLanguage)
        EvidenceFragment(
          type: EvidenceFragmentType.cancellationHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.weak,
          confidence: 0.64,
          note: hasSuspensionLanguage
              ? 'Subscription suspension signal detected.'
              : 'Cancellation or failed-renewal wording detected.',
          terms: capturedTerms,
        ),
      if (hasTrialEndingLanguage || hasExpiryLanguage)
        EvidenceFragment(
          type: EvidenceFragmentType.renewalHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.medium,
          confidence: 0.67,
          note: hasTrialEndingLanguage
              ? 'Free trial ending signal detected.'
              : 'Subscription expiry signal detected.',
          terms: capturedTerms,
        ),
      EvidenceFragment(
        type: EvidenceFragmentType.unknownReview,
        sourceMessageId: message.id,
        classifierId: classifierId,
        strength: EvidenceFragmentStrength.medium,
        confidence: 0.66,
        note: 'Risky recurring lifecycle signal kept unconfirmed.',
        terms: capturedTerms,
      ),
    ];

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.unknownReview,
      summary: 'Renewal-risk lifecycle signal routed to conservative review.',
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
      evidenceFragments: evidenceFragments,
    );
  }
}
