import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';
import 'package:sub_killer/domain/classifiers/mandate_intent_classifier.dart';
import 'package:sub_killer/domain/classifiers/subscription_billed_classifier.dart';
import 'package:sub_killer/domain/classifiers/telecom_bundle_classifier.dart';
import 'package:sub_killer/domain/classifiers/upi_noise_veto_classifier.dart';
import 'package:sub_killer/domain/classifiers/weak_signal_review_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/evidence_fragment_type.dart';

void main() {
  final receivedAt = DateTime(2026, 3, 12, 12, 0);

  MessageRecord message(String body, {String sourceAddress = 'SRC'}) {
    return MessageRecord(
      id: body.hashCode.toString(),
      sourceAddress: sourceAddress,
      body: body,
      receivedAt: receivedAt,
    );
  }

  group('Evidence fragment foundation', () {
    test('billed classifier emits billed success and renewal fragments', () {
      const classifier = SubscriptionBilledClassifier();

      final result = classifier.classify(
        message('Your Netflix subscription has been renewed for Rs 499.'),
      );

      expect(result, isNotNull);
      expect(
        result!.evidenceFragments.map((fragment) => fragment.type),
        containsAll(<EvidenceFragmentType>[
          EvidenceFragmentType.billedSuccess,
          EvidenceFragmentType.renewalHint,
        ]),
      );
    });

    test('mandate classifier emits mandate and micro-charge fragments', () {
      const classifier = MandateIntentClassifier();

      final created = classifier.classify(
        message('You have successfully created a mandate on JioHotstar.'),
      );
      final micro = classifier.classify(
        message(
          'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
        ),
      );

      expect(created, isNotNull);
      expect(
        created!.evidenceFragments.single.type,
        EvidenceFragmentType.mandateCreated,
      );
      expect(micro, isNotNull);
      expect(
        micro!.evidenceFragments.single.type,
        EvidenceFragmentType.microCharge,
      );
    });

    test('telecom bundle classifier emits bundled benefit fragment', () {
      const classifier = TelecomBundleClassifier();

      final result = classifier.classify(
        message(
          'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
          sourceAddress: 'TELCO',
        ),
      );

      expect(result, isNotNull);
      expect(
        result!.evidenceFragments.single.type,
        EvidenceFragmentType.bundledBenefit,
      );
    });

    test('weak review classifier emits weak recurring and unknown review', () {
      const classifier = WeakSignalReviewClassifier();

      final result = classifier.classify(
        message('Your subscription may renew shortly.'),
      );

      expect(result, isNotNull);
      expect(
        result!.evidenceFragments.map((fragment) => fragment.type),
        containsAll(<EvidenceFragmentType>[
          EvidenceFragmentType.weakRecurringHint,
          EvidenceFragmentType.unknownReview,
        ]),
      );
    });

    test('upi veto classifier emits one-time payment noise fragment', () {
      const classifier = UpiNoiseVetoClassifier();

      final result = classifier.classify(
        message('Rs 1 debited via UPI to VPA test@upi. Ref 2222'),
      );

      expect(result, isNotNull);
      expect(
        result!.evidenceFragments.single.type,
        EvidenceFragmentType.oneTimePaymentNoise,
      );
    });

    test('event pipeline copies fragment trace notes into evidence trail', () {
      final pipeline = EventPipelineUseCase();

      final events = pipeline.execute(<MessageRecord>[
        message('Your Netflix subscription has been renewed for Rs 499.'),
      ]);

      expect(events, hasLength(1));
      expect(
        events.single.evidenceTrail.notes,
        contains('fragment:billed_success'),
      );
      expect(
        events.single.evidenceTrail.notes,
        contains('fragment:renewal_hint'),
      );
    });
  });
}
