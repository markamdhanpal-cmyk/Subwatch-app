import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/service_evidence_bucket.dart';
import '../../domain/enums/service_evidence_source_kind.dart';
import '../../domain/services/legacy_service_key_trust_guard.dart';
import '../../domain/value_objects/service_key.dart';

class PersistedServiceEvidenceBucket {
  const PersistedServiceEvidenceBucket({
    required this.serviceKey,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.sourceKindsSeen,
    required this.billedCount,
    required this.renewalHintCount,
    required this.mandateCount,
    required this.autopaySetupCount,
    required this.microChargeCount,
    required this.bundleCount,
    required this.endedLifecycleCount,
    required this.promoCount,
    required this.cancellationHintCount,
    required this.weakRecurringHintCount,
    required this.unknownReviewCount,
    required this.otpNoiseCount,
    required this.telecomRechargeNoiseCount,
    required this.oneTimePaymentNoiseCount,
    required this.ignoreNoiseCount,
    required this.amountSeries,
    required this.intervalHintsInDays,
    required this.contradictions,
    required this.evidenceTrail,
    this.lastBilledAt,
    this.schemaVersion = 3,
  });

  factory PersistedServiceEvidenceBucket.fromDomain(
    ServiceEvidenceBucket bucket,
  ) {
    return PersistedServiceEvidenceBucket(
      serviceKey: LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: bucket.serviceKey.value,
        evidenceNotes: bucket.evidenceTrail.notes,
      ),
      firstSeenAt: bucket.firstSeenAt.toIso8601String(),
      lastSeenAt: bucket.lastSeenAt.toIso8601String(),
      lastBilledAt: bucket.lastBilledAt?.toIso8601String(),
      sourceKindsSeen: bucket.sourceKindsSeen
          .map((kind) => kind.name)
          .toList(growable: false),
      billedCount: bucket.billedCount,
      renewalHintCount: bucket.renewalHintCount,
      mandateCount: bucket.mandateCount,
      autopaySetupCount: bucket.autopaySetupCount,
      microChargeCount: bucket.microChargeCount,
      bundleCount: bucket.bundleCount,
      endedLifecycleCount: bucket.endedLifecycleCount,
      promoCount: bucket.promoCount,
      cancellationHintCount: bucket.cancellationHintCount,
      weakRecurringHintCount: bucket.weakRecurringHintCount,
      unknownReviewCount: bucket.unknownReviewCount,
      otpNoiseCount: bucket.otpNoiseCount,
      telecomRechargeNoiseCount: bucket.telecomRechargeNoiseCount,
      oneTimePaymentNoiseCount: bucket.oneTimePaymentNoiseCount,
      ignoreNoiseCount: bucket.ignoreNoiseCount,
      amountSeries: bucket.amountSeries,
      intervalHintsInDays: bucket.intervalHintsInDays,
      contradictions: bucket.contradictions,
      evidenceTrail: PersistedBucketEvidenceTrail.fromDomain(
        bucket.evidenceTrail,
      ),
    );
  }

  factory PersistedServiceEvidenceBucket.fromJson(Map<String, Object?> json) {
    return PersistedServiceEvidenceBucket(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      serviceKey: (json['serviceKey'] as String?)?.trim().isNotEmpty == true
          ? (json['serviceKey'] as String).trim()
          : LegacyServiceKeyTrustGuard.unresolvedServiceKey,
      firstSeenAt: (json['firstSeenAt'] as String?) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toIso8601String(),
      lastSeenAt: (json['lastSeenAt'] as String?) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toIso8601String(),
      lastBilledAt: json['lastBilledAt'] as String?,
      sourceKindsSeen: _readStringList(json['sourceKindsSeen']).toSet().toList(
            growable: false,
          ),
      billedCount: _nonNegativeInt(json['billedCount']),
      renewalHintCount: _nonNegativeInt(json['renewalHintCount']),
      mandateCount: _nonNegativeInt(json['mandateCount']),
      autopaySetupCount: _nonNegativeInt(json['autopaySetupCount']),
      microChargeCount: _nonNegativeInt(json['microChargeCount']),
      bundleCount: _nonNegativeInt(json['bundleCount']),
      endedLifecycleCount: _nonNegativeInt(json['endedLifecycleCount']),
      promoCount: _nonNegativeInt(json['promoCount']),
      cancellationHintCount: _nonNegativeInt(json['cancellationHintCount']),
      weakRecurringHintCount: _nonNegativeInt(json['weakRecurringHintCount']),
      unknownReviewCount: _nonNegativeInt(json['unknownReviewCount']),
      otpNoiseCount: _nonNegativeInt(json['otpNoiseCount']),
      telecomRechargeNoiseCount:
          _nonNegativeInt(json['telecomRechargeNoiseCount']),
      oneTimePaymentNoiseCount:
          _nonNegativeInt(json['oneTimePaymentNoiseCount']),
      ignoreNoiseCount: _nonNegativeInt(json['ignoreNoiseCount']),
      amountSeries: _readDoubleList(json['amountSeries'])
          .where((amount) => amount.isFinite && amount > 0)
          .toSet()
          .toList(growable: false),
      intervalHintsInDays: _readIntList(
        json['intervalHintsInDays'],
      ).where((days) => days > 0).toSet().toList(growable: false),
      contradictions: _readStringList(
        json['contradictions'],
      ).where((value) => value.trim().isNotEmpty).toSet().toList(
            growable: false,
          ),
      evidenceTrail: PersistedBucketEvidenceTrail.fromJson(
        (json['evidenceTrail'] as Map?)
                ?.map((key, value) => MapEntry(key.toString(), value)) ??
            const <String, Object?>{},
      ),
    );
  }

  final int schemaVersion;
  final String serviceKey;
  final String firstSeenAt;
  final String lastSeenAt;
  final String? lastBilledAt;
  final List<String> sourceKindsSeen;
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
  final PersistedBucketEvidenceTrail evidenceTrail;

  ServiceEvidenceBucket toDomain() {
    final domainEvidenceTrail = evidenceTrail.toDomain();
    final sanitizedServiceKey =
        LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
      serviceKey: serviceKey,
      evidenceNotes: domainEvidenceTrail.notes,
    );

    return ServiceEvidenceBucket(
      serviceKey: ServiceKey(sanitizedServiceKey),
      firstSeenAt: _parseIso(firstSeenAt),
      lastSeenAt: _parseIso(lastSeenAt),
      lastBilledAt: lastBilledAt == null ? null : _tryParseIso(lastBilledAt!),
      sourceKindsSeen:
          sourceKindsSeen.map(_sourceKindFromName).toList(growable: false),
      billedCount: billedCount,
      renewalHintCount: renewalHintCount,
      mandateCount: mandateCount,
      autopaySetupCount: autopaySetupCount,
      microChargeCount: microChargeCount,
      bundleCount: bundleCount,
      endedLifecycleCount: endedLifecycleCount,
      promoCount: promoCount,
      cancellationHintCount: cancellationHintCount,
      weakRecurringHintCount: weakRecurringHintCount,
      unknownReviewCount: unknownReviewCount,
      otpNoiseCount: otpNoiseCount,
      telecomRechargeNoiseCount: telecomRechargeNoiseCount,
      oneTimePaymentNoiseCount: oneTimePaymentNoiseCount,
      ignoreNoiseCount: ignoreNoiseCount,
      amountSeries: amountSeries,
      intervalHintsInDays: intervalHintsInDays,
      contradictions: contradictions,
      evidenceTrail: domainEvidenceTrail,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'serviceKey': serviceKey,
      'firstSeenAt': firstSeenAt,
      'lastSeenAt': lastSeenAt,
      'lastBilledAt': lastBilledAt,
      'sourceKindsSeen': sourceKindsSeen,
      'billedCount': billedCount,
      'renewalHintCount': renewalHintCount,
      'mandateCount': mandateCount,
      'autopaySetupCount': autopaySetupCount,
      'microChargeCount': microChargeCount,
      'bundleCount': bundleCount,
      'endedLifecycleCount': endedLifecycleCount,
      'promoCount': promoCount,
      'cancellationHintCount': cancellationHintCount,
      'weakRecurringHintCount': weakRecurringHintCount,
      'unknownReviewCount': unknownReviewCount,
      'otpNoiseCount': otpNoiseCount,
      'telecomRechargeNoiseCount': telecomRechargeNoiseCount,
      'oneTimePaymentNoiseCount': oneTimePaymentNoiseCount,
      'ignoreNoiseCount': ignoreNoiseCount,
      'amountSeries': amountSeries,
      'intervalHintsInDays': intervalHintsInDays,
      'contradictions': contradictions,
      'evidenceTrail': evidenceTrail.toJson(),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.whereType<String>().toList(growable: false);
  }

  static List<double> _readDoubleList(Object? value) {
    if (value is! List) {
      return const <double>[];
    }

    return value
        .whereType<num>()
        .map((item) => item.toDouble())
        .toList(growable: false);
  }

  static List<int> _readIntList(Object? value) {
    if (value is! List) {
      return const <int>[];
    }

    return value
        .whereType<num>()
        .map((item) => item.toInt())
        .toList(growable: false);
  }

  static int _nonNegativeInt(Object? value) {
    return (value as num?)?.toInt().clamp(0, 1 << 30) ?? 0;
  }

  static DateTime _parseIso(String value) {
    return DateTime.tryParse(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? _tryParseIso(String value) {
    return DateTime.tryParse(value);
  }

  static ServiceEvidenceSourceKind _sourceKindFromName(String kindName) {
    for (final kind in ServiceEvidenceSourceKind.values) {
      if (kind.name == kindName) {
        return kind;
      }
    }

    return ServiceEvidenceSourceKind.legacyMessageRecordBridge;
  }
}

class PersistedBucketEvidenceTrail {
  const PersistedBucketEvidenceTrail({
    required this.messageIds,
    required this.eventIds,
    required this.notes,
  });

  factory PersistedBucketEvidenceTrail.fromDomain(EvidenceTrail evidenceTrail) {
    return PersistedBucketEvidenceTrail(
      messageIds: evidenceTrail.messageIds,
      eventIds: evidenceTrail.eventIds,
      notes: evidenceTrail.notes,
    );
  }

  factory PersistedBucketEvidenceTrail.fromJson(Map<String, Object?> json) {
    return PersistedBucketEvidenceTrail(
      messageIds: PersistedServiceEvidenceBucket._readStringList(
        json['messageIds'],
      ),
      eventIds: PersistedServiceEvidenceBucket._readStringList(
        json['eventIds'],
      ),
      notes: PersistedServiceEvidenceBucket._readStringList(json['notes']),
    );
  }

  final List<String> messageIds;
  final List<String> eventIds;
  final List<String> notes;

  EvidenceTrail toDomain() {
    return EvidenceTrail(
      messageIds: messageIds,
      eventIds: eventIds,
      notes: notes,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'messageIds': messageIds,
      'eventIds': eventIds,
      'notes': notes,
    };
  }
}
