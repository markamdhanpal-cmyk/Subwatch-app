import '../contracts/event_classifier.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/subscription_event_type.dart';

class TelecomBundleClassifier implements EventClassifier {
  const TelecomBundleClassifier();

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
    RegExp(r'\bplan\b', caseSensitive: false),
    RegExp(r'\bpack\b', caseSensitive: false),
    RegExp(r'\bbundle\b', caseSensitive: false),
    RegExp(r'\bbenefit\b', caseSensitive: false),
    RegExp(r'\bcomplimentary\b', caseSensitive: false),
    RegExp(r'\bfree\b', caseSensitive: false),
    RegExp(r'\brecent recharge has unlocked\b', caseSensitive: false),
    RegExp(r'\bunlocked by recharge\b', caseSensitive: false),
  ];

  static final List<RegExp> _bundleMarkerPatterns = <RegExp>[
    RegExp(r'\bbundle\b', caseSensitive: false),
    RegExp(r'\bbenefit\b', caseSensitive: false),
    RegExp(r'\bcomplimentary\b', caseSensitive: false),
    RegExp(r'\bfree\b', caseSensitive: false),
    RegExp(r'\brecharge\b', caseSensitive: false),
    RegExp(r'\bunlocked\b', caseSensitive: false),
  ];

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final hasProviderBundleContext = _providerPattern.hasMatch(body) &&
        _benefitPatterns.any((pattern) => pattern.hasMatch(body));
    final hasCoBrandedBundleContext = _coBrandedBundlePattern.hasMatch(body) &&
        _bundleMarkerPatterns.any((pattern) => pattern.hasMatch(body));

    if (!hasProviderBundleContext && !hasCoBrandedBundleContext) {
      return null;
    }

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.bundleActivated,
      summary: 'Telecom-linked bundled benefit detected.',
      detectedAt: message.receivedAt,
      capturedTerms: _capturedTerms(body),
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

    return terms.toList(growable: false);
  }
}
