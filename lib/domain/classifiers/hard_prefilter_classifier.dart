import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import 'recurring_billing_heuristics.dart';

class HardPrefilterClassifier implements EventClassifier {
  const HardPrefilterClassifier();

  static const String classifierId = 'hard_prefilter';

  static final RegExp _otpPattern = RegExp(
    r'\b(?:otp|one[\s-]?time password|do not share|never share|valid for \d+ min)\b',
    caseSensitive: false,
  );

  static final RegExp _missedCallPattern = RegExp(
    r'\b(?:missed call|you missed a call|call me back)\b',
    caseSensitive: false,
  );

  static final RegExp _dataQuotaPattern = RegExp(
    r'\b(?:\d+(?:\.\d+)?\s?(?:gb|mb)\/day|data balance|data used|data quota|high speed data|daily data|fup)\b',
    caseSensitive: false,
  );

  static final RegExp _promoPattern = RegExp(
    r'\b(?:sale|offer|deals?|coupon|cashback|buy now|limited period|shop now|discount|reward points?)\b',
    caseSensitive: false,
  );

  static final RegExp _rcsBotPattern = RegExp(
    r'\b(?:rcs|verified business|chatbot|tap to reply|reply with|button below)\b',
    caseSensitive: false,
  );

  static final RegExp _loanReminderPattern = RegExp(
    r'\b(?:loan|emi|instalment|installment|due amount|payment due|overdue)\b',
    caseSensitive: false,
  );

  static final RegExp _upiOneTimePattern = RegExp(
    r'\b(?:upi|vpa|utr|imps|neft|rtgs)\b',
    caseSensitive: false,
  );

  static final RegExp _telecomRechargePattern = RegExp(
    r'\b(?:recharge|pack|validity|2gb\/day|1\.5gb\/day|unlimited voice|sms\/day|daily data)\b',
    caseSensitive: false,
  );

  static final RegExp _telecomProviderPattern = RegExp(
    r'\b(?:jio|airtel|vi|vodafone idea)\b',
    caseSensitive: false,
  );

  static final RegExp _telecomBundleWordsPattern = RegExp(
    r'\b(?:included|complimentary|free|benefit|unlocked)\b',
    caseSensitive: false,
  );

  static final RegExp _negativeLifecyclePattern = RegExp(
    r'\b(?:failed|unsuccessful|unable|pending|scheduled|due soon|reminder)\b',
    caseSensitive: false,
  );

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    if (_hasStrongPaidEvidence(body)) {
      return null;
    }

    if (_otpPattern.hasMatch(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'OTP or authentication message filtered as noise.',
        note: 'otp/auth message filtered early.',
        type: EvidenceFragmentType.otpNoise,
        capturedTerms: _capturedTerms(body, <RegExp>[_otpPattern]),
      );
    }

    if (_isTelecomRechargeNoise(body)) {
      return _ignoreSignal(
        message: message,
        summary:
            'Telecom recharge/data message filtered before subscription logic.',
        note: 'telecom recharge/data noise filtered early.',
        type: EvidenceFragmentType.telecomRechargeNoise,
        capturedTerms: _capturedTerms(
          body,
          <RegExp>[
            _telecomProviderPattern,
            _telecomRechargePattern,
            _telecomBundleWordsPattern,
          ],
        ),
      );
    }

    if (_missedCallPattern.hasMatch(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'Missed-call style alert filtered as noise.',
        note: 'missed-call alert filtered early.',
        capturedTerms: _capturedTerms(body, <RegExp>[_missedCallPattern]),
      );
    }

    if (_rcsBotPattern.hasMatch(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'RCS/chatbot style message filtered as noise.',
        note: 'rcs/chatbot style message filtered early.',
        capturedTerms: _capturedTerms(body, <RegExp>[_rcsBotPattern]),
      );
    }

    if (_loanReminderPattern.hasMatch(body) &&
        !RecurringBillingHeuristics.hasSubscriptionContext(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'Loan or due-reminder message filtered as non-subscription.',
        note: 'loan reminder filtered early.',
        capturedTerms: _capturedTerms(body, <RegExp>[_loanReminderPattern]),
      );
    }

    if (_dataQuotaPattern.hasMatch(body) &&
        !RecurringBillingHeuristics.hasBillingContext(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'Data quota status message filtered as telecom noise.',
        note: 'data quota message filtered early.',
        type: EvidenceFragmentType.telecomRechargeNoise,
        capturedTerms: _capturedTerms(body, <RegExp>[_dataQuotaPattern]),
      );
    }

    if (_promoPattern.hasMatch(body) &&
        !RecurringBillingHeuristics.hasBillingContext(body)) {
      return _ignoreSignal(
        message: message,
        summary: 'Promotional blast filtered as noise.',
        note: 'promotional blast filtered early.',
        type: EvidenceFragmentType.promoOnly,
        capturedTerms: _capturedTerms(body, <RegExp>[_promoPattern]),
      );
    }

    if (_upiOneTimePattern.hasMatch(body) &&
        !RecurringBillingHeuristics.hasMandateContext(body) &&
        !RecurringBillingHeuristics.hasRecurringContext(body) &&
        !RecurringBillingHeuristics.hasSubscriptionContext(body)) {
      final amount = RecurringBillingHeuristics.extractAmount(body);
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.oneTimePayment,
        summary:
            'One-time banking rail message filtered before subscription logic.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: _capturedTerms(body, <RegExp>[_upiOneTimePattern]),
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.oneTimePaymentNoise,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.96,
            amount: amount,
            note: 'one-time payment rail message filtered early.',
            terms: _capturedTerms(body, <RegExp>[_upiOneTimePattern]),
          ),
        ],
      );
    }

    return null;
  }

  bool _hasStrongPaidEvidence(String body) {
    final amount = RecurringBillingHeuristics.extractAmount(body);
    final hasCredibleAmount =
        RecurringBillingHeuristics.isCredibleAmount(amount);
    if (!hasCredibleAmount) {
      return false;
    }

    if (_negativeLifecyclePattern.hasMatch(body)) {
      return false;
    }

    final hasMerchant =
        RecurringBillingHeuristics.hasDirectRecurringMerchant(body) ||
            MerchantKnowledgeBase.matchKnownMerchant(
                  body,
                  requiredTypeLabels: const <String>[
                    'direct_recurring',
                    'app_store',
                  ],
                  allowWeakReview: false,
                  allowBundleSignals: false,
                ) !=
                null;

    if (!hasMerchant) {
      return false;
    }

    final hasRecurringBillingContext =
        RecurringBillingHeuristics.hasBillingContext(body) &&
            (RecurringBillingHeuristics.hasSuccessContext(body) ||
                RecurringBillingHeuristics.hasRecurringContext(body)) &&
            (RecurringBillingHeuristics.hasSubscriptionContext(body) ||
                RecurringBillingHeuristics.hasPlanContext(body) ||
                RecurringBillingHeuristics.hasRecurringContext(body));

    return hasRecurringBillingContext &&
        !RecurringBillingHeuristics.hasMandateContext(body) &&
        !RecurringBillingHeuristics.looksLikeTelecomBundle(body);
  }

  bool _isTelecomRechargeNoise(String body) {
    if (!_telecomProviderPattern.hasMatch(body)) {
      return false;
    }

    if (_shouldAllowTelecomBundleExtraction(body)) {
      return false;
    }

    final hasRechargeOrPack = _telecomRechargePattern.hasMatch(body);
    final hasBundleWords = _telecomBundleWordsPattern.hasMatch(body);
    final hasDataWords = _dataQuotaPattern.hasMatch(body);
    if (!hasRechargeOrPack && !hasBundleWords && !hasDataWords) {
      return false;
    }

    return !_hasStrongPaidEvidence(body);
  }

  bool _shouldAllowTelecomBundleExtraction(String body) {
    final hasKnownBundleCandidate = MerchantKnowledgeBase.matchKnownMerchant(
          body,
          requiredTypeLabels: const <String>['bundle_candidate'],
          allowWeakReview: false,
          allowBundleSignals: true,
        ) !=
        null;
    if (!hasKnownBundleCandidate) {
      return false;
    }

    final hasRechargeOrPack = _telecomRechargePattern.hasMatch(body);
    final hasBundleWords = _telecomBundleWordsPattern.hasMatch(body);
    return hasRechargeOrPack && hasBundleWords;
  }

  ParsedSignal _ignoreSignal({
    required MessageRecord message,
    required String summary,
    required String note,
    EvidenceFragmentType type = EvidenceFragmentType.ignoreNoise,
    required List<String> capturedTerms,
  }) {
    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.ignore,
      summary: summary,
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
      evidenceFragments: <EvidenceFragment>[
        EvidenceFragment(
          type: type,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.strong,
          confidence: 0.95,
          note: note,
          terms: capturedTerms,
        ),
      ],
    );
  }

  List<String> _capturedTerms(String input, List<RegExp> patterns) {
    final terms = <String>{};
    for (final pattern in patterns) {
      final matches = pattern.allMatches(input);
      for (final match in matches) {
        final value = match.group(0);
        if (value != null && value.isNotEmpty) {
          terms.add(value.toLowerCase());
        }
      }
    }
    return terms.toList(growable: false);
  }
}
