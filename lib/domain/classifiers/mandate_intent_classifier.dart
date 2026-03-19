import '../contracts/event_classifier.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/subscription_event_type.dart';
import '../parsing/indian_amount_parser.dart';

class MandateIntentClassifier implements EventClassifier {
  const MandateIntentClassifier();

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
    r'\b(create(?:d)?|register(?:ed)?|authori[sz](?:e|ed|ation)|approve(?:d)?)\b',
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

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final amount = IndianAmountParser.extract(body);
    final hasMandateContext = _mandateContextPattern.hasMatch(body);
    final hasAutopayContext = _autopayContextPattern.hasMatch(body);
    final hasAnyRecurringContext = hasMandateContext || hasAutopayContext;

    if (hasAnyRecurringContext &&
        amount != null &&
        amount <= 2 &&
        _executionPattern.hasMatch(body)) {
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.mandateExecutedMicro,
        summary: 'Recurring mandate validation or micro execution detected.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: _capturedTerms(body),
      );
    }

    if (hasMandateContext && _creationPattern.hasMatch(body)) {
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.mandateCreated,
        summary: 'Recurring mandate authorization intent detected.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: _capturedTerms(body),
      );
    }

    if (hasAutopayContext && _setupPattern.hasMatch(body)) {
      return ParsedSignal(
        classifierId: classifierId,
        eventType: SubscriptionEventType.autopaySetup,
        summary: 'Automatic payment or standing instruction setup detected.',
        detectedAt: message.receivedAt,
        amount: amount,
        capturedTerms: _capturedTerms(body),
      );
    }

    return null;
  }

  List<String> _capturedTerms(String input) {
    final terms = <String>{};

    for (final pattern in <RegExp>[
      _mandateContextPattern,
      _autopayContextPattern,
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
