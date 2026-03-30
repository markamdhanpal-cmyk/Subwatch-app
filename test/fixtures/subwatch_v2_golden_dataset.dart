import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

import 'india_real_sms_regression_fixture_pack.dart';

enum GoldenDatasetCategory {
  paidSubscription,
  bundledIncluded,
  setupOnly,
  verificationOnly,
  oneTimePaymentNoise,
  weakRecurringReview,
  noisyRichBusinessMessage,
  appStoreRenewal,
  emailReceipt,
  csvStatement,
}

enum GoldenTruthLabel {
  confirmedPaid,
  includedWithPlan,
  setupOnly,
  verificationOnly,
  oneTimeOrNoise,
  needsReview,
  ignored,
}

class GoldenTruthExpectation {
  const GoldenTruthExpectation({
    required this.label,
    required this.serviceKey,
    required this.resolverState,
    required this.eventType,
    this.totalBilled = 0,
    this.ledgerEntryCount = 1,
  });

  final GoldenTruthLabel label;
  final String serviceKey;
  final ResolverState resolverState;
  final SubscriptionEventType eventType;
  final double totalBilled;
  final int ledgerEntryCount;
}

class GoldenDatasetInput {
  const GoldenDatasetInput.messageRecords(this.records)
      : canonicalInputs = null,
        provenance = 'message_records';

  const GoldenDatasetInput.canonicalInputs(
    this.canonicalInputs, {
    required this.provenance,
  }) : records = null;

  final List<MessageRecord>? records;
  final List<CanonicalInput>? canonicalInputs;
  final String provenance;
}

class GoldenDatasetCase {
  const GoldenDatasetCase({
    required this.id,
    required this.title,
    required this.category,
    required this.protection,
    required this.input,
    required this.expected,
  });

  factory GoldenDatasetCase.fromSmsFixture(
    IndiaRealSmsRegressionCase fixture,
  ) {
    return GoldenDatasetCase(
      id: fixture.id,
      title: fixture.id,
      category: _categoryForFixture(fixture.category),
      protection: fixture.protection,
      input: GoldenDatasetInput.messageRecords(
        <MessageRecord>[
          fixture.toMessage(DateTime(2026, 3, 13, 9, 0)),
        ],
      ),
      expected: GoldenTruthExpectation(
        label: _labelForState(fixture.expectedState),
        serviceKey: fixture.expectedServiceKey,
        resolverState: fixture.expectedState,
        eventType: fixture.expectedEventType,
        totalBilled: fixture.expectedTotalBilled,
      ),
    );
  }

  final String id;
  final String title;
  final GoldenDatasetCategory category;
  final String protection;
  final GoldenDatasetInput input;
  final GoldenTruthExpectation expected;
}

GoldenDatasetCategory _categoryForFixture(IndiaRealSmsFixtureCategory category) {
  switch (category) {
    case IndiaRealSmsFixtureCategory.upiNoise:
      return GoldenDatasetCategory.oneTimePaymentNoise;
    case IndiaRealSmsFixtureCategory.mandateSetup:
      return GoldenDatasetCategory.setupOnly;
    case IndiaRealSmsFixtureCategory.microExecution:
      return GoldenDatasetCategory.verificationOnly;
    case IndiaRealSmsFixtureCategory.telecomBundle:
      return GoldenDatasetCategory.bundledIncluded;
    case IndiaRealSmsFixtureCategory.weakRecurringReview:
      return GoldenDatasetCategory.weakRecurringReview;
    case IndiaRealSmsFixtureCategory.billedSubscription:
    case IndiaRealSmsFixtureCategory.identityMergeRisk:
    case IndiaRealSmsFixtureCategory.identitySplitRisk:
    case IndiaRealSmsFixtureCategory.identityFragmentRisk:
      return GoldenDatasetCategory.paidSubscription;
    case IndiaRealSmsFixtureCategory.ambiguousConservative:
      return GoldenDatasetCategory.oneTimePaymentNoise;
  }
}

GoldenTruthLabel _labelForState(ResolverState state) {
  switch (state) {
    case ResolverState.activePaid:
      return GoldenTruthLabel.confirmedPaid;
    case ResolverState.activeBundled:
      return GoldenTruthLabel.includedWithPlan;
    case ResolverState.pendingConversion:
      return GoldenTruthLabel.setupOnly;
    case ResolverState.verificationOnly:
      return GoldenTruthLabel.verificationOnly;
    case ResolverState.oneTimeOnly:
      return GoldenTruthLabel.oneTimeOrNoise;
    case ResolverState.possibleSubscription:
      return GoldenTruthLabel.needsReview;
    case ResolverState.ignored:
      return GoldenTruthLabel.ignored;
    case ResolverState.cancelled:
      return GoldenTruthLabel.needsReview;
  }
}

final goldenRegressionDataset = <GoldenDatasetCase>[
  GoldenDatasetCase.fromSmsFixture(billedNetflixCase),
  GoldenDatasetCase.fromSmsFixture(telecomBundleCase),
  GoldenDatasetCase.fromSmsFixture(mandateCreatedCase),
  GoldenDatasetCase.fromSmsFixture(microExecutionCase),
  GoldenDatasetCase.fromSmsFixture(upiVpaDebitNoiseCase),
  GoldenDatasetCase.fromSmsFixture(weakRecurringReminderCase),
  GoldenDatasetCase(
    id: 'golden-rich-rcs-netflix',
    title: 'Rich RCS renewal with promo wrapper',
    category: GoldenDatasetCategory.noisyRichBusinessMessage,
    protection:
        'Rich business-message wrappers and promo clutter should still preserve true billed evidence without over-cleaning away the merchant.',
    input: GoldenDatasetInput.canonicalInputs(
      <CanonicalInput>[
        CanonicalInput(
          id: 'golden-rich-rcs-netflix',
          kind: CanonicalInputKind.rcs,
          origin: const CanonicalInputOrigin(
            kind: CanonicalInputOriginKind.deviceRcsInbox,
            sourceLabel: 'device_rcs_inbox',
            localOnly: true,
            captureConfidence: CanonicalInputCaptureConfidence.medium,
          ),
          receivedAt: DateTime(2026, 3, 20, 10, 45),
          senderHandle: 'VK-NETFLX',
          subject: 'Renewal reminder',
          textBody:
              '<div>Body: Renew now and save 20%! Visit https://example.com</div>',
          richTextSegments: <String>[
            'Netflix Premium monthly plan billed successfully for Rs 649',
          ],
        ),
      ],
      provenance: 'canonical_rcs_business_message',
    ),
    expected: const GoldenTruthExpectation(
      label: GoldenTruthLabel.confirmedPaid,
      serviceKey: 'NETFLIX',
      resolverState: ResolverState.activePaid,
      eventType: SubscriptionEventType.subscriptionBilled,
      totalBilled: 649,
    ),
  ),
  GoldenDatasetCase(
    id: 'golden-app-store-youtube-premium',
    title: 'Google Play renewal record',
    category: GoldenDatasetCategory.appStoreRenewal,
    protection:
        'Structured app-store renewal records should enter the same V2 path and stay measurable against expected paid truth.',
    input: GoldenDatasetInput.canonicalInputs(
      <CanonicalInput>[
        CanonicalInput(
          id: 'golden-app-store-youtube-premium',
          kind: CanonicalInputKind.appStore,
          origin: CanonicalInputOrigin.googlePlayRecord(
            batchId: 'golden_gp_batch_1',
            captureConfidence: CanonicalInputCaptureConfidence.high,
          ),
          receivedAt: DateTime(2026, 3, 23, 11, 0),
          senderHandle: 'google_play',
          subject: 'YouTube Premium',
          threadId: 'golden_gp_batch_1',
          textBody:
              'Google Play subscription for YouTube Premium YouTube Premium Monthly renewed successfully for Rs 149 (monthly). Auto-renew payment completed.',
          richTextSegments: <String>[
            'Provider: Google Play',
            'Product: YouTube Premium Monthly',
            'Billing period: monthly',
          ],
        ),
      ],
      provenance: 'canonical_google_play_record',
    ),
    expected: const GoldenTruthExpectation(
      label: GoldenTruthLabel.confirmedPaid,
      serviceKey: 'YOUTUBE_PREMIUM',
      resolverState: ResolverState.activePaid,
      eventType: SubscriptionEventType.subscriptionBilled,
      totalBilled: 149,
    ),
  ),
  GoldenDatasetCase(
    id: 'golden-email-receipt-netflix',
    title: 'Email receipt renewal',
    category: GoldenDatasetCategory.emailReceipt,
    protection:
        'Receipt-like evidence should stay measurable in the shared path without inventing certainty from weak provenance alone.',
    input: GoldenDatasetInput.canonicalInputs(
      <CanonicalInput>[
        CanonicalInput(
          id: 'golden-email-receipt-netflix',
          kind: CanonicalInputKind.receipt,
          origin: CanonicalInputOrigin.emailReceiptImport(
            batchId: 'golden_receipt_batch_1',
            captureConfidence: CanonicalInputCaptureConfidence.high,
          ),
          receivedAt: DateTime(2026, 3, 21, 8, 30),
          senderHandle: 'billing@netflix.com',
          subject: 'Netflix receipt',
          threadId: 'golden_receipt_batch_1',
          attachmentCount: 1,
          textBody:
              'Email receipt Subject: Netflix receipt. Service hint: NETFLIX. Your Netflix subscription renewed successfully for Rs 499. Receipt reference: NFX-123.',
          richTextSegments: <String>[
            'Source: gmail_receipts',
            'Service hint: NETFLIX',
            'Receipt reference: NFX-123',
          ],
        ),
      ],
      provenance: 'canonical_email_receipt',
    ),
    expected: const GoldenTruthExpectation(
      label: GoldenTruthLabel.confirmedPaid,
      serviceKey: 'NETFLIX',
      resolverState: ResolverState.activePaid,
      eventType: SubscriptionEventType.subscriptionBilled,
      totalBilled: 499,
    ),
  ),
  GoldenDatasetCase(
    id: 'golden-csv-netflix-statement',
    title: 'CSV statement row',
    category: GoldenDatasetCategory.csvStatement,
    protection:
        'Structured statement imports should remain measurable through the same pipeline as SMS and receipts.',
    input: GoldenDatasetInput.canonicalInputs(
      <CanonicalInput>[
        CanonicalInput(
          id: 'golden-csv-netflix-statement',
          kind: CanonicalInputKind.csv,
          origin: CanonicalInputOrigin.csvImport(
            batchId: 'golden_csv_batch_1',
            captureConfidence: CanonicalInputCaptureConfidence.medium,
          ),
          receivedAt: DateTime(2026, 3, 12, 0, 0),
          subject: 'Netflix',
          threadId: 'golden_csv_batch_1',
          textBody:
              'Statement import shows Rs 499 debited at NETFLIX on 2026-03-12. Description: Netflix monthly charge. Reference: NFX123. Channel: CARD.',
          richTextSegments: <String>[
            'Imported statement row 2',
            'Source: march_statement.csv',
            'Merchant: NETFLIX',
            'Description: Netflix monthly charge',
          ],
        ),
      ],
      provenance: 'canonical_csv_statement',
    ),
    expected: const GoldenTruthExpectation(
      label: GoldenTruthLabel.confirmedPaid,
      serviceKey: 'NETFLIX',
      resolverState: ResolverState.activePaid,
      eventType: SubscriptionEventType.subscriptionBilled,
      totalBilled: 499,
    ),
  ),
];

