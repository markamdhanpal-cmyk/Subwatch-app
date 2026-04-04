import '../entities/evidence_fragment.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/evidence_fragment_type.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import 'recurring_billing_heuristics.dart';

class LifecycleEventClassifier {
  const LifecycleEventClassifier();

  // Legacy parsed-signal classifier kept for compatibility shadowing.
  // It only emits ended-lifecycle evidence when recurring context is explicit.

  static const String classifierId = 'lifecycle_event';

  ParsedSignal? classify(MessageRecord message) {
    final body = message.body.trim();
    if (body.isEmpty) {
      return null;
    }

    if (RecurringBillingHeuristics.hasProtectedNoise(body)) {
      return null;
    }

    final hasCancellation =
        RecurringBillingHeuristics.cancellationPattern.hasMatch(body);
    if (!hasCancellation) {
      return null;
    }

    final hasKnownRecurringMerchant =
        MerchantKnowledgeBase.matchKnownDirectRecurringMerchant(
              body,
              includeAppStore: true,
            ) !=
            null;
    final hasRecurringLifecycleContext =
        RecurringBillingHeuristics.hasSubscriptionContext(body) ||
            RecurringBillingHeuristics.hasRecurringContext(body) ||
            RecurringBillingHeuristics.hasPlanContext(body) ||
            hasKnownRecurringMerchant;
    if (!hasRecurringLifecycleContext) {
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
          type: EvidenceFragmentType.endedLifecycle,
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
