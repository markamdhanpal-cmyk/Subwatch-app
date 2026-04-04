import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import 'recurring_billing_heuristics.dart';

class TelecomBundleClassifier {
  const TelecomBundleClassifier();

  // Legacy parsed-signal classifier kept for compatibility shadowing.
  // It should only emit bundled-benefit evidence, never paid truth.

  static const String classifierId = 'telecom_bundle';

  static final RegExp _providerPattern = RegExp(
    r'\b(jio|airtel|vi)\b',
    caseSensitive: false,
  );

  static final RegExp _coBrandedBundlePattern = RegExp(
    r'\bjiohotstar\b',
    caseSensitive: false,
  );

  static final List<RegExp> _benefitPatterns = <RegExp>[
    RegExp(r'\bsubscription\b', caseSensitive: false),
    RegExp(r'\bbenefit\b', caseSensitive: false),
    RegExp(r'\bcomplimentary\b', caseSensitive: false),
    RegExp(r'\bfree\b', caseSensitive: false),
    RegExp(r'\bincluded\b', caseSensitive: false),
    RegExp(r'\brecent recharge has unlocked\b', caseSensitive: false),
    RegExp(r'\bunlocked by recharge\b', caseSensitive: false),
  ];

  static final List<RegExp> _rechargeOrPackMarkers = <RegExp>[
    RegExp(r'\brecharge\b', caseSensitive: false),
    RegExp(r'\bplan\b', caseSensitive: false),
    RegExp(r'\bpack\b', caseSensitive: false),
    RegExp(r'\bvalidity\b', caseSensitive: false),
    RegExp(r'\bunlocked\b', caseSensitive: false),
  ];

  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final hasCrediblePaidAmount = RecurringBillingHeuristics.isCredibleAmount(
      RecurringBillingHeuristics.extractAmount(body),
    );
    final hasDirectPaidSignal = hasCrediblePaidAmount &&
        RecurringBillingHeuristics.hasBillingContext(body) &&
        (RecurringBillingHeuristics.hasSuccessContext(body) ||
            RecurringBillingHeuristics.hasRecurringContext(body)) &&
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body) &&
        !RecurringBillingHeuristics.hasBundleContextForKnownMerchant(body);
    if (hasDirectPaidSignal) {
      return null;
    }

    final hasProviderContext = _providerPattern.hasMatch(body);
    final hasBenefitLanguage =
        _benefitPatterns.any((pattern) => pattern.hasMatch(body));
    final hasRechargeMarker =
        _rechargeOrPackMarkers.any((pattern) => pattern.hasMatch(body));
    final hasCoBrandedContext = _coBrandedBundlePattern.hasMatch(body);
    final bundleEntry =
        MerchantKnowledgeBase.matchKnownBundleCandidateMerchant(body);
    final hasBundleServiceAlias = bundleEntry != null;
    final hasMerchantBundleLanguage = bundleEntry != null &&
        MerchantKnowledgeBase.hasBundleContextForEntry(body, bundleEntry);

    final hasProviderBundleContext =
        hasProviderContext && hasBenefitLanguage && hasRechargeMarker;
    final hasCoBrandedBundleContext =
        hasCoBrandedContext && hasBenefitLanguage && hasRechargeMarker;
    final hasStrongBundleContext =
        hasProviderBundleContext || hasCoBrandedBundleContext;

    if (!hasStrongBundleContext || !hasBundleServiceAlias) {
      return null;
    }

    if (!hasMerchantBundleLanguage && !hasBenefitLanguage) {
      return null;
    }

    final capturedTerms = _capturedTerms(body);

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.bundleActivated,
      summary: 'Telecom-linked bundled benefit detected.',
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
      evidenceFragments: <EvidenceFragment>[
        EvidenceFragment(
          type: EvidenceFragmentType.bundledBenefit,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.strong,
          confidence: 0.95,
          note: 'Telecom-linked bundled benefit detected.',
          terms: capturedTerms,
        ),
      ],
    );
  }

  List<String> _capturedTerms(String input) {
    final terms = <String>{};

    final providerMatch = _providerPattern.firstMatch(input) ??
        _coBrandedBundlePattern.firstMatch(input);
    if (providerMatch != null) {
      final provider = providerMatch.group(0);
      if (provider != null) {
        terms.add(provider.toLowerCase());
      }
    }

    for (final pattern in _benefitPatterns) {
      final match = pattern.firstMatch(input);
      if (match == null) {
        continue;
      }

      final term = match.group(0);
      if (term != null) {
        terms.add(term.toLowerCase());
      }
    }

    for (final pattern in _rechargeOrPackMarkers) {
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
