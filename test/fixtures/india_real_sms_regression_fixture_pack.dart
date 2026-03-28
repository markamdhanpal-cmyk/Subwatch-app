import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

/// Sanitized, minimized fixtures derived from real Indian SMS export patterns.
///
/// These are intentionally curated examples, not raw personal exports. They
/// protect the current conservative behavior against false-positive drift
/// without embedding production heuristics in the test layer.
enum IndiaRealSmsFixtureCategory {
  upiNoise,
  mandateSetup,
  microExecution,
  telecomBundle,
  weakRecurringReview,
  billedSubscription,
  identityMergeRisk,
  identitySplitRisk,
  identityFragmentRisk,
  ambiguousConservative,
}

String protectionForCategory(IndiaRealSmsFixtureCategory category) {
  switch (category) {
    case IndiaRealSmsFixtureCategory.upiNoise:
      return 'Protects against UPI, QR, VPA, and merchant-payment noise being surfaced as subscriptions.';
    case IndiaRealSmsFixtureCategory.mandateSetup:
      return 'Protects setup and authorization flows from being treated as active paid subscriptions.';
    case IndiaRealSmsFixtureCategory.microExecution:
      return 'Protects Rs 1 and Rs 2 validation executions from being treated as paid subscriptions.';
    case IndiaRealSmsFixtureCategory.telecomBundle:
      return 'Protects bundled recharge-linked benefits from being treated as paid subscriptions.';
    case IndiaRealSmsFixtureCategory.weakRecurringReview:
      return 'Protects ambiguous recurring-looking reminders by keeping them in review instead of confirmed.';
    case IndiaRealSmsFixtureCategory.billedSubscription:
      return 'Protects true billed subscription evidence so it remains confirmable despite nearby payment noise.';
    case IndiaRealSmsFixtureCategory.identityMergeRisk:
      return 'Protects known same-service variants from splitting into duplicate ledger entries.';
    case IndiaRealSmsFixtureCategory.identitySplitRisk:
      return 'Protects distinct services from collapsing into one merged identity.';
    case IndiaRealSmsFixtureCategory.identityFragmentRisk:
      return 'Protects broken body fragments from being promoted into visible service names.';
    case IndiaRealSmsFixtureCategory.ambiguousConservative:
      return 'Protects edge cases that look subscription-like but should still resolve conservatively.';
  }
}

class IndiaRealSmsRegressionCase {
  const IndiaRealSmsRegressionCase({
    required this.id,
    required this.category,
    required this.protection,
    required this.sourceAddress,
    required this.body,
    required this.expectedEventType,
    required this.expectedServiceKey,
    required this.expectedState,
    this.expectedTotalBilled = 0,
  });

  final String id;
  final IndiaRealSmsFixtureCategory category;
  final String protection;
  final String sourceAddress;
  final String body;
  final SubscriptionEventType expectedEventType;
  final String expectedServiceKey;
  final ResolverState expectedState;
  final double expectedTotalBilled;

  MessageRecord toMessage(DateTime receivedAt) {
    return MessageRecord(
      id: id,
      sourceAddress: sourceAddress,
      body: body,
      receivedAt: receivedAt,
    );
  }
}

class IndiaRealSmsRegressionScenario {
  const IndiaRealSmsRegressionScenario({
    required this.name,
    required this.category,
    required this.protection,
    required this.cases,
  });

  final String name;
  final IndiaRealSmsFixtureCategory category;
  final String protection;
  final List<IndiaRealSmsRegressionCase> cases;

  List<MessageRecord> toMessages(DateTime startAt) {
    return List<MessageRecord>.generate(
      cases.length,
      (index) => cases[index].toMessage(startAt.add(Duration(minutes: index))),
      growable: false,
    );
  }
}

const upiQrMerchantNoiseCase = IndiaRealSmsRegressionCase(
  id: 'upi-qr-merchant-noise',
  category: IndiaRealSmsFixtureCategory.upiNoise,
  protection:
      'Merchant QR receipts must stay out of subscriptions even when money and merchant names are present.',
  sourceAddress: 'HDFCBK',
  body: 'Paid Rs 450 via UPI on Paytm QR at KIRANA STORE. Ref 123456.',
  expectedEventType: SubscriptionEventType.ignore,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.ignored,
);

const upiVpaDebitNoiseCase = IndiaRealSmsRegressionCase(
  id: 'upi-vpa-debit-noise',
  category: IndiaRealSmsFixtureCategory.upiNoise,
  protection:
      'VPA debit alerts must stay one-time payment noise and never become paid subscriptions.',
  sourceAddress: 'ICICIB',
  body: 'Rs 1 debited via UPI to VPA recharge@upi. Ref 98123.',
  expectedEventType: SubscriptionEventType.oneTimePayment,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.oneTimeOnly,
);

const mandateCreatedCase = IndiaRealSmsRegressionCase(
  id: 'mandate-created-jiohotstar',
  category: IndiaRealSmsFixtureCategory.mandateSetup,
  protection:
      'Mandate creation for a known service must remain pending conversion until real billing happens.',
  sourceAddress: 'AXISBK',
  body: 'eMandate created on JioHotstar for max amount Rs 1499.',
  expectedEventType: SubscriptionEventType.mandateCreated,
  expectedServiceKey: 'JIOHOTSTAR',
  expectedState: ResolverState.pendingConversion,
);

const autopaySetupAdobeSystemsCase = IndiaRealSmsRegressionCase(
  id: 'autopay-setup-adobe-systems',
  category: IndiaRealSmsFixtureCategory.mandateSetup,
  protection:
      'Autopay setup language should not be promoted to paid until billed evidence appears.',
  sourceAddress: 'SBIBNK',
  body: 'Automatic payment setup enabled for Adobe Systems. Limit Rs 799.',
  expectedEventType: SubscriptionEventType.autopaySetup,
  expectedServiceKey: 'ADOBE_SYSTEMS',
  expectedState: ResolverState.pendingConversion,
);

const microExecutionCase = IndiaRealSmsRegressionCase(
  id: 'micro-execution-crunchyroll',
  category: IndiaRealSmsFixtureCategory.microExecution,
  protection:
      'Rs 1 validation charges should stay verification-only, even for recognizable subscription brands.',
  sourceAddress: 'KOTAKB',
  body: 'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
  expectedEventType: SubscriptionEventType.mandateExecutedMicro,
  expectedServiceKey: 'CRUNCHYROLL',
  expectedState: ResolverState.verificationOnly,
);

const telecomBundleCase = IndiaRealSmsRegressionCase(
  id: 'telecom-bundle-gemini',
  category: IndiaRealSmsFixtureCategory.telecomBundle,
  protection:
      'Recharge-linked complimentary bundles should stay separate from paid subscriptions.',
  sourceAddress: 'AIRTEL',
  body:
      'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
  expectedEventType: SubscriptionEventType.bundleActivated,
  expectedServiceKey: 'GOOGLE_GEMINI_PRO',
  expectedState: ResolverState.activeBundled,
);

const weakRecurringReminderCase = IndiaRealSmsRegressionCase(
  id: 'weak-recurring-reminder',
  category: IndiaRealSmsFixtureCategory.weakRecurringReview,
  protection:
      'Reminder-style recurring language should stay in review when billed evidence is absent.',
  sourceAddress: 'REMINDR',
  body: 'Reminder: your membership payment is due soon for Music Plus.',
  expectedEventType: SubscriptionEventType.unknownReview,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.possibleSubscription,
);

const billedNetflixCase = IndiaRealSmsRegressionCase(
  id: 'billed-netflix',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'Clear billed subscription evidence should keep producing a confirmed paid subscription.',
  sourceAddress: 'HDFCBK',
  body: 'Your Netflix subscription has been renewed for Rs 499.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'NETFLIX',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 499,
);

const billedYouTubePremiumCase = IndiaRealSmsRegressionCase(
  id: 'billed-youtube-premium',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'True monthly subscription billing should remain confirmable for known services.',
  sourceAddress: 'AMEXIN',
  body:
      'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'YOUTUBE_PREMIUM',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 149,
);

const billedAppleMusicCase = IndiaRealSmsRegressionCase(
  id: 'billed-apple-music',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'Simple multi-word service names should keep resolving after fragment filtering tightens.',
  sourceAddress: 'ICICIB',
  body: 'Your Apple Music plan renewed successfully. Rs 99 charged.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'APPLE_MUSIC',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 99,
);

const billedSpotifyCardCase = IndiaRealSmsRegressionCase(
  id: 'billed-spotify-card',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'Direct card debits for common recurring merchants should still surface as confirmed paid subscriptions.',
  sourceAddress: 'SBICRD',
  body: 'SBI Card XX4321 used for Rs 119 at SPOTIFY on 17 Mar.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'SPOTIFY',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 119,
);

const billedJioHotstarRenewalCase = IndiaRealSmsRegressionCase(
  id: 'billed-jiohotstar-renewal',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'A paid JioHotstar renewal must stay paid evidence and not collapse into telecom-bundle handling.',
  sourceAddress: 'HDFCBK',
  body: 'Your JioHotstar subscription has been renewed for Rs 299.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'JIOHOTSTAR',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 299,
);

const billedSwiggyOneCardCase = IndiaRealSmsRegressionCase(
  id: 'billed-swiggy-one-card',
  category: IndiaRealSmsFixtureCategory.billedSubscription,
  protection:
      'India-heavy membership merchants should not disappear when the bank message is a plain card debit.',
  sourceAddress: 'HDFCBK',
  body: 'HDFC Card XX1212 used for Rs 99 at SWIGGY ONE on 17 Mar.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'SWIGGY_ONE',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 99,
);

const reviewGooglePlayRecurringCase = IndiaRealSmsRegressionCase(
  id: 'review-google-play-recurring',
  category: IndiaRealSmsFixtureCategory.weakRecurringReview,
  protection:
      'Generic app-store recurring billing should route to review instead of silently dropping.',
  sourceAddress: 'HDFCBK',
  body:
      'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
  expectedEventType: SubscriptionEventType.unknownReview,
  expectedServiceKey: 'GOOGLE_PLAY',
  expectedState: ResolverState.possibleSubscription,
);

const reviewGooglePlayRecurringRepeatCase = IndiaRealSmsRegressionCase(
  id: 'review-google-play-recurring-repeat',
  category: IndiaRealSmsFixtureCategory.weakRecurringReview,
  protection:
      'Repeated app-store recurring billing messages should merge into one reviewable service key.',
  sourceAddress: 'HDFCBK',
  body:
      'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
  expectedEventType: SubscriptionEventType.unknownReview,
  expectedServiceKey: 'GOOGLE_PLAY',
  expectedState: ResolverState.possibleSubscription,
);

const adobeBilledRenewalCase = IndiaRealSmsRegressionCase(
  id: 'billed-adobe-renewal',
  category: IndiaRealSmsFixtureCategory.identityMergeRisk,
  protection:
      'Known Adobe naming variants should merge into one service identity when real billing arrives.',
  sourceAddress: 'SBIBNK',
  body: 'Adobe plan renewed successfully. Rs 799 charged.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'ADOBE_SYSTEMS',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 799,
);

const dailyQuotaFragmentCase = IndiaRealSmsRegressionCase(
  id: 'broken-daily-quota-fragment',
  category: IndiaRealSmsFixtureCategory.identityFragmentRisk,
  protection:
      'Broken plan-copy fragments should downgrade to a neutral unresolved service label instead of becoming a visible name.',
  sourceAddress: 'AIRTEL',
  body: 'Your Daily Quota As Per plan renewed successfully. Rs 249 charged.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 249,
);

const truncatedAmpersandFragmentCase = IndiaRealSmsRegressionCase(
  id: 'broken-day-ampersand-fragment',
  category: IndiaRealSmsFixtureCategory.identityFragmentRisk,
  protection:
      'Trailing connector fragments should not become service identities even when billing evidence is present.',
  sourceAddress: 'AIRTEL',
  body: 'Your 7 Day & plan renewed successfully. Rs 99 charged.',
  expectedEventType: SubscriptionEventType.subscriptionBilled,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.activePaid,
  expectedTotalBilled: 99,
);

const ambiguousUpiReminderCase = IndiaRealSmsRegressionCase(
  id: 'ambiguous-upi-reminder',
  category: IndiaRealSmsFixtureCategory.ambiguousConservative,
  protection:
      'Subscription-like reminders that still route through UPI rails should remain conservative and stay out of confirmed subscriptions.',
  sourceAddress: 'PAYMENT',
  body:
      'Subscription reminder: pay Rs 199 via UPI to ott@upi before 14 Mar to avoid interruption.',
  expectedEventType: SubscriptionEventType.ignore,
  expectedServiceKey: 'UNRESOLVED',
  expectedState: ResolverState.ignored,
);

const curatedSingleMessageCases = <IndiaRealSmsRegressionCase>[
  upiQrMerchantNoiseCase,
  upiVpaDebitNoiseCase,
  mandateCreatedCase,
  autopaySetupAdobeSystemsCase,
  microExecutionCase,
  telecomBundleCase,
  weakRecurringReminderCase,
  billedNetflixCase,
  billedYouTubePremiumCase,
  billedAppleMusicCase,
  billedSpotifyCardCase,
  billedJioHotstarRenewalCase,
  billedSwiggyOneCardCase,
  reviewGooglePlayRecurringCase,
  dailyQuotaFragmentCase,
  truncatedAmpersandFragmentCase,
  ambiguousUpiReminderCase,
];

const identityMergeScenario = IndiaRealSmsRegressionScenario(
  name: 'adobe_setup_then_billed_merge',
  category: IndiaRealSmsFixtureCategory.identityMergeRisk,
  protection:
      'Adobe Systems setup and Adobe billed renewal should converge to one ledger entry with paid state.',
  cases: <IndiaRealSmsRegressionCase>[
    autopaySetupAdobeSystemsCase,
    adobeBilledRenewalCase,
  ],
);

const identitySplitScenario = IndiaRealSmsRegressionScenario(
  name: 'netflix_and_youtube_premium_stay_separate',
  category: IndiaRealSmsFixtureCategory.identitySplitRisk,
  protection:
      'Distinct subscription brands should remain separate even when both are billed and monthly.',
  cases: <IndiaRealSmsRegressionCase>[
    billedNetflixCase,
    billedYouTubePremiumCase,
  ],
);

const repeatedGooglePlayReviewScenario = IndiaRealSmsRegressionScenario(
  name: 'google_play_recurring_review_merges',
  category: IndiaRealSmsFixtureCategory.weakRecurringReview,
  protection:
      'Repeated generic app-store recurring debits should stay reviewable under one stable service key.',
  cases: <IndiaRealSmsRegressionCase>[
    reviewGooglePlayRecurringCase,
    reviewGooglePlayRecurringRepeatCase,
  ],
);

const curatedMixedPackScenario = IndiaRealSmsRegressionScenario(
  name: 'mixed_real_pattern_pack',
  category: IndiaRealSmsFixtureCategory.ambiguousConservative,
  protection:
      'A realistic mixed inbox slice should keep confirmed subscriptions small, review items high-signal, and payments noise hidden.',
  cases: <IndiaRealSmsRegressionCase>[
    upiQrMerchantNoiseCase,
    upiVpaDebitNoiseCase,
    mandateCreatedCase,
    microExecutionCase,
    telecomBundleCase,
    weakRecurringReminderCase,
    billedNetflixCase,
    billedYouTubePremiumCase,
    billedSpotifyCardCase,
    billedJioHotstarRenewalCase,
    billedSwiggyOneCardCase,
    reviewGooglePlayRecurringCase,
    ambiguousUpiReminderCase,
  ],
);
