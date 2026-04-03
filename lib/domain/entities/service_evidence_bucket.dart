import '../enums/service_evidence_source_kind.dart';
import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class ServiceEvidenceBucket {
  ServiceEvidenceBucket({
    required this.serviceKey,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required List<ServiceEvidenceSourceKind> sourceKindsSeen,
    required this.evidenceTrail,
    this.lastBilledAt,
    this.billedCount = 0,
    this.renewalHintCount = 0,
    this.mandateCount = 0,
    this.autopaySetupCount = 0,
    this.microChargeCount = 0,
    this.bundleCount = 0,
    this.endedLifecycleCount = 0,
    this.promoCount = 0,
    this.cancellationHintCount = 0,
    this.weakRecurringHintCount = 0,
    this.unknownReviewCount = 0,
    this.otpNoiseCount = 0,
    this.telecomRechargeNoiseCount = 0,
    this.oneTimePaymentNoiseCount = 0,
    this.ignoreNoiseCount = 0,
    List<double> amountSeries = const <double>[],
    List<int> intervalHintsInDays = const <int>[],
    List<String> contradictions = const <String>[],
  })  : sourceKindsSeen = List<ServiceEvidenceSourceKind>.unmodifiable(
          sourceKindsSeen,
        ),
        amountSeries = List<double>.unmodifiable(amountSeries),
        intervalHintsInDays = List<int>.unmodifiable(intervalHintsInDays),
        contradictions = List<String>.unmodifiable(contradictions);

  factory ServiceEvidenceBucket.seed({
    required ServiceKey serviceKey,
    required DateTime seenAt,
    required ServiceEvidenceSourceKind sourceKind,
  }) {
    return ServiceEvidenceBucket(
      serviceKey: serviceKey,
      firstSeenAt: seenAt,
      lastSeenAt: seenAt,
      sourceKindsSeen: <ServiceEvidenceSourceKind>[sourceKind],
      evidenceTrail: EvidenceTrail.empty(),
    );
  }

  final ServiceKey serviceKey;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DateTime? lastBilledAt;
  final List<ServiceEvidenceSourceKind> sourceKindsSeen;
  final int billedCount;
  final int renewalHintCount;
  final int mandateCount;
  final int autopaySetupCount;
  final int microChargeCount;
  final int bundleCount;
  final int endedLifecycleCount;
  final int promoCount;
  final int cancellationHintCount;
  final int weakRecurringHintCount;
  final int unknownReviewCount;
  final int otpNoiseCount;
  final int telecomRechargeNoiseCount;
  final int oneTimePaymentNoiseCount;
  final int ignoreNoiseCount;
  final List<double> amountSeries;
  final List<int> intervalHintsInDays;
  final List<String> contradictions;
  final EvidenceTrail evidenceTrail;

  bool get hasConfirmedPaidEvidence => billedCount > 0;

  bool get hasIncludedBundleEvidence => bundleCount > 0;

  bool get hasSetupOrVerificationOnlyEvidence =>
      billedCount == 0 &&
      (mandateCount > 0 || autopaySetupCount > 0 || microChargeCount > 0) &&
      bundleCount == 0 &&
      endedLifecycleCount == 0;

  bool get hasReviewOnlyEvidence =>
      billedCount == 0 &&
      bundleCount == 0 &&
      endedLifecycleCount == 0 &&
      (renewalHintCount > 0 ||
          cancellationHintCount > 0 ||
          weakRecurringHintCount > 0 ||
          unknownReviewCount > 0);

  ServiceEvidenceBucket copyWith({
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    DateTime? lastBilledAt,
    List<ServiceEvidenceSourceKind>? sourceKindsSeen,
    int? billedCount,
    int? renewalHintCount,
    int? mandateCount,
    int? autopaySetupCount,
    int? microChargeCount,
    int? bundleCount,
    int? endedLifecycleCount,
    int? promoCount,
    int? cancellationHintCount,
    int? weakRecurringHintCount,
    int? unknownReviewCount,
    int? otpNoiseCount,
    int? telecomRechargeNoiseCount,
    int? oneTimePaymentNoiseCount,
    int? ignoreNoiseCount,
    List<double>? amountSeries,
    List<int>? intervalHintsInDays,
    List<String>? contradictions,
    EvidenceTrail? evidenceTrail,
  }) {
    return ServiceEvidenceBucket(
      serviceKey: serviceKey,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastBilledAt: lastBilledAt ?? this.lastBilledAt,
      sourceKindsSeen: sourceKindsSeen ?? this.sourceKindsSeen,
      billedCount: billedCount ?? this.billedCount,
      renewalHintCount: renewalHintCount ?? this.renewalHintCount,
      mandateCount: mandateCount ?? this.mandateCount,
      autopaySetupCount: autopaySetupCount ?? this.autopaySetupCount,
      microChargeCount: microChargeCount ?? this.microChargeCount,
      bundleCount: bundleCount ?? this.bundleCount,
      endedLifecycleCount: endedLifecycleCount ?? this.endedLifecycleCount,
      promoCount: promoCount ?? this.promoCount,
      cancellationHintCount:
          cancellationHintCount ?? this.cancellationHintCount,
      weakRecurringHintCount:
          weakRecurringHintCount ?? this.weakRecurringHintCount,
      unknownReviewCount: unknownReviewCount ?? this.unknownReviewCount,
      otpNoiseCount: otpNoiseCount ?? this.otpNoiseCount,
      telecomRechargeNoiseCount:
          telecomRechargeNoiseCount ?? this.telecomRechargeNoiseCount,
      oneTimePaymentNoiseCount:
          oneTimePaymentNoiseCount ?? this.oneTimePaymentNoiseCount,
      ignoreNoiseCount: ignoreNoiseCount ?? this.ignoreNoiseCount,
      amountSeries: amountSeries ?? this.amountSeries,
      intervalHintsInDays: intervalHintsInDays ?? this.intervalHintsInDays,
      contradictions: contradictions ?? this.contradictions,
      evidenceTrail: evidenceTrail ?? this.evidenceTrail,
    );
  }
}
