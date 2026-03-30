import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../parsing/indian_amount_parser.dart';

class UpiNoiseVetoClassifier implements EventClassifier {
  const UpiNoiseVetoClassifier();

  static const String classifierId = 'upi_noise_veto';

  static final RegExp _mandatePrecedencePattern = RegExp(
    r'\b(mandate|autopay|auto[\s-]?pay|e[\s-]?mandate)\b',
    caseSensitive: false,
  );

  static final List<RegExp> _noiseMarkers = <RegExp>[
    RegExp(r'\bupi\b', caseSensitive: false),
    RegExp(r'\bvpa\b', caseSensitive: false),
    RegExp(r'\bbharatpe\b', caseSensitive: false),
    RegExp(r'\bpaytm[\s-]?qr\b', caseSensitive: false),
    RegExp(r'\bqr\b', caseSensitive: false),
  ];

  static final List<RegExp> _ignoreMarkers = <RegExp>[
    RegExp(r'\bsent\b', caseSensitive: false),
    RegExp(r'\bpaid\b', caseSensitive: false),
    RegExp(r'\bbharatpe\b', caseSensitive: false),
    RegExp(r'\bpaytm[\s-]?qr\b', caseSensitive: false),
    RegExp(r'\bqr\b', caseSensitive: false),
  ];

  static final List<RegExp> _oneTimeMarkers = <RegExp>[
    RegExp(r'\bdebited\b', caseSensitive: false),
    RegExp(r'\bdebit\b', caseSensitive: false),
    RegExp(r'\bspent\b', caseSensitive: false),
  ];

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    if (_mandatePrecedencePattern.hasMatch(body)) {
      return null;
    }

    if (!_matchesAny(_noiseMarkers, body)) {
      return null;
    }

    final matchedTerms = _matchedTerms(body);
    final amount = IndianAmountParser.extract(body);

    if (_matchesAny(_ignoreMarkers, body)) {
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.ignore,
        summary: 'Plain UPI or QR payment noise vetoed.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: matchedTerms,
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.ignoreNoise,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.97,
            amount: amount,
            note: 'UPI or QR payment noise vetoed.',
            terms: matchedTerms,
          ),
        ],
      );
    }

    if (_matchesAny(_oneTimeMarkers, body)) {
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.oneTimePayment,
        summary: 'UPI debit treated as one-time payment noise.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: matchedTerms,
        evidenceFragments: <EvidenceFragment>[
          EvidenceFragment(
            type: EvidenceFragmentType.oneTimePaymentNoise,
            sourceMessageId: message.id,
            classifierId: classifierId,
            strength: EvidenceFragmentStrength.strong,
            confidence: 0.95,
            amount: amount,
            note: 'UPI debit treated as one-time payment noise.',
            terms: matchedTerms,
          ),
        ],
      );
    }

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.ignore,
      summary: 'Unstructured UPI payment noise vetoed conservatively.',
      detectedAt: message.receivedAt,
      amount: amount,
      capturedTerms: matchedTerms,
      evidenceFragments: <EvidenceFragment>[
        EvidenceFragment(
          type: EvidenceFragmentType.ignoreNoise,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.medium,
          confidence: 0.83,
          amount: amount,
          note: 'Unstructured payment noise vetoed conservatively.',
          terms: matchedTerms,
        ),
      ],
    );
  }

  bool _matchesAny(List<RegExp> patterns, String input) {
    return patterns.any((pattern) => pattern.hasMatch(input));
  }

  List<String> _matchedTerms(String input) {
    final terms = <String>{};

    for (final pattern in <RegExp>[
      ..._noiseMarkers,
      ..._ignoreMarkers,
      ..._oneTimeMarkers,
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
