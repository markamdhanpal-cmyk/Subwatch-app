import '../contracts/event_classifier.dart';
import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import 'recurring_billing_heuristics.dart';

class LifecycleEventClassifier implements EventClassifier {
  const LifecycleEventClassifier();

  static const String classifierId = 'lifecycle_event';

  @override
  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final hasCancellation = RecurringBillingHeuristics.cancellationPattern.hasMatch(body);
    if (!hasCancellation) {
      return null;
    }

    final capturedTerms = RecurringBillingHeuristics.capturedTerms(
      body,
      <RegExp>[RecurringBillingHeuristics.cancellationPattern],
    );

    return ParsedSignal(
      classifierId: classifierId,
      eventType: SubscriptionEventType.subscriptionCancelled,
      summary: 'Subscription cancellation or termination signal detected.',
      detectedAt: message.receivedAt,
      capturedTerms: capturedTerms,
      evidenceFragments: <EvidenceFragment>[
        EvidenceFragment(
          type: EvidenceFragmentType.cancellationHint,
          sourceMessageId: message.id,
          classifierId: classifierId,
          strength: EvidenceFragmentStrength.strong,
          confidence: 0.98,
          note: 'Explicit cancellation language detected.',
          terms: capturedTerms,
        ),
      ],
    );
  }
}
