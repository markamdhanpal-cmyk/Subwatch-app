import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../parsing/indian_amount_parser.dart';
import 'recurring_billing_heuristics.dart';

class MandateIntentClassifier {
  const MandateIntentClassifier();

  // Legacy parsed-signal classifier kept for compatibility shadowing.
  // Mandate/setup/micro signals must remain non-paid evidence.

  static const String classifierId = 'mandate_intent';

  static final RegExp _mandateContextPattern = RegExp(
    r'\b(mandate|e[\s-]?mandate)\b',
    caseSensitive: false,
  );

  static final RegExp _autopayContextPattern = RegExp(
    r'\b(autopay|auto[\s-]?pay|automatic payment|standing instruction)\b',
    caseSensitive: false,
  );

  static final RegExp _creationPattern = RegExp(
    r'\b(create(?:d)?|register(?:ed)?|authori[sz](?:e|ed|ation)|approve(?:d)?|is\s+active|status:\s+active|active\s+for)\b',
    caseSensitive: false,
  );

  static final RegExp _cancellationPattern = RegExp(
    r'\b(cancel(?:led|lation)?|revok(?:e|ed)|terminat(?:e|ed|ion)|deactivat(?:e|ed)|stop(?:ped)?)\b',
    caseSensitive: false,
  );

  static final RegExp _setupPattern = RegExp(
    r'\b(set[\s-]?up|setup|enroll(?:ed|ment)?|enable(?:d)?|activat(?:e|ed)|configure(?:d)?)\b',
    caseSensitive: false,
  );

  static final RegExp _executionPattern = RegExp(
    r'\b(execut(?:e|ed|ion)|validat(?:e|ed|ion)|verif(?:y|ied|ication)|present(?:ed)?)\b',
    caseSensitive: false,
  );

  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final amount = IndianAmountParser.extract(body);
    final anyAmount = _extractAnyAmount(body);
    final hasMandateContext = _mandateContextPattern.hasMatch(body);
    final hasAutopayContext = _autopayContextPattern.hasMatch(body);
    final hasAnyRecurringContext = hasMandateContext || hasAutopayContext;
    final hasDirectPaidRenewalContext = hasAnyRecurringContext &&
        RecurringBillingHeuristics.hasBillingContext(body) &&
        RecurringBillingHeuristics.hasSuccessContext(body) &&
        RecurringBillingHeuristics.hasSubscriptionContext(body) &&
        (amount ?? anyAmount ?? 0) > 2;
    if (hasDirectPaidRenewalContext) {
      // Keep mandate/setup semantics conservative. If the text already carries
      // direct billed-renewal context, this classifier should not emit.
      return null;
    }

    if (hasAnyRecurringContext && _cancellationPattern.hasMatch(body)) {
      var resolveAmount = amount ?? anyAmount;
      if (resolveAmount == null) {
        final fallbackMatch = RegExp(
          r'\b(?:for|of)\s+([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
          caseSensitive: false,
        ).firstMatch(body);
        if (fallbackMatch != null) {
          resolveAmount =
              double.tryParse(fallbackMatch.group(1)!.replaceAll(',', ''));
        }
      }

      if (resolveAmount != null && resolveAmount >= 11) {
        final capturedTerms = _capturedTerms(body);
        return ParsedSignal(
          classifierId: classifierId,
          eventType: SubscriptionEventType.unknownReview,
          summary: 'Recurring mandate cancellation detected for review.',
          detectedAt: message.receivedAt,
          amount: resolveAmount,
          capturedTerms: capturedTerms,
          evidenceFragments: <EvidenceFragment>[
            EvidenceFragment(
              type: EvidenceFragmentType.cancellationHint,
              sourceMessageId: message.id,
              classifierId: classifierId,
              strength: EvidenceFragmentStrength.medium,
              confidence: 0.85,
              amount: resolveAmount,
              note: 'Mandate cancellation intent routed to review.',
              terms: capturedTerms,
            ),
          ],
        );
      }

      return null;
    }

    final microAmount = amount ?? anyAmount;
    if (hasAnyRecurringContext &&
        microAmount != null &&
        microAmount > 0 &&
        microAmount <= 2 &&
        _executionPattern.hasMatch(body)) {
      final capturedTerms = _capturedTerms(body);
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.mandateExecutedMicro,
        summary: 'Recurring mandate validation or micro execution detected.',
        detectedAt: message.receivedAt,
        amount: microAmount,
        capturedTerms: capturedTerms,
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.microCharge,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.98,
            amount: microAmount,
            note: 'Mandate validation or micro execution detected.',
            terms: capturedTerms,
          ),
        ],
      );
    }

    if (hasMandateContext && _creationPattern.hasMatch(body)) {
      final capturedTerms = _capturedTerms(body);
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.mandateCreated,
        summary: 'Recurring mandate authorization intent detected.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: capturedTerms,
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.mandateCreated,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.96,
            amount: amount,
            note: 'Mandate authorization intent detected.',
            terms: capturedTerms,
          ),
        ],
      );
    }

    if (hasAutopayContext && _setupPattern.hasMatch(body)) {
      final capturedTerms = _capturedTerms(body);
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.autopaySetup,
        summary: 'Automatic payment or standing instruction setup detected.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: capturedTerms,
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.autopaySetup,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.94,
            amount: amount,
            note: 'Automatic payment setup detected.',
            terms: capturedTerms,
          ),
        ],
      );
    }

    return null;
  }

  double? _extractAnyAmount(String input) {
    final match = RegExp(
      r'\b(?:rs\.?|inr|amt\.?|amount|for)\s*[:\-\s]*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(input);
    if (match == null) {
      return null;
    }

    final raw = match.group(1);
    if (raw == null) {
      return null;
    }

    return double.tryParse(raw.replaceAll(',', ''));
  }

  List<String> _capturedTerms(String input) {
    final terms = <String>{};

    for (final pattern in <RegExp>[
      _mandateContextPattern,
      _autopayContextPattern,
      _cancellationPattern,
      _creationPattern,
      _setupPattern,
      _executionPattern,
    ]) {
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
