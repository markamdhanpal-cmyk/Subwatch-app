import '../enums/subscription_event_type.dart';

class ParsedSignal {
  ParsedSignal({
    required this.classifierId,
    required this.eventType,
    required this.summary,
    DateTime? detectedAt,
    this.amount,
    List<String> capturedTerms = const <String>[],
  })  : detectedAt = detectedAt,
        capturedTerms = List.unmodifiable(capturedTerms);

  final String classifierId;
  final SubscriptionEventType eventType;
  final String summary;
  final DateTime? detectedAt;
  final double? amount;
  final List<String> capturedTerms;
}
