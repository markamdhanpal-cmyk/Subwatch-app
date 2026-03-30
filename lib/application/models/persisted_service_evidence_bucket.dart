import '../../domain/entities/evidence_trail.dart';
import '../../domain/entities/service_evidence_bucket.dart';
import '../../domain/enums/service_evidence_source_kind.dart';
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
    required this.promoCount,
    required this.cancellationHintCount,
    required this.weakRecurringHintCount,
    required this.unknownReviewCount,
    required this.oneTimePaymentNoiseCount,
    required this.ignoreNoiseCount,
    required this.amountSeries,
    required this.intervalHintsInDays,
    required this.contradictions,
    required this.evidenceTrail,
    this.lastBilledAt,
    this.schemaVersion = 2,
  });

  factory PersistedServiceEvidenceBucket.fromDomain(
    ServiceEvidenceBucket bucket,
  ) {
    return PersistedServiceEvidenceBucket(
      serviceKey: bucket.serviceKey.value,
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
      promoCount: bucket.promoCount,
      cancellationHintCount: bucket.cancellationHintCount,
      weakRecurringHintCount: bucket.weakRecurringHintCount,
      unknownReviewCount: bucket.unknownReviewCount,
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
      serviceKey: json['serviceKey'] as String,
      firstSeenAt: json['firstSeenAt'] as String,
      lastSeenAt: json['lastSeenAt'] as String,
      lastBilledAt: json['lastBilledAt'] as String?,
      sourceKindsSeen: _readStringList(json['sourceKindsSeen']),
      billedCount: (json['billedCount'] as num?)?.toInt() ?? 0,
      renewalHintCount: (json['renewalHintCount'] as num?)?.toInt() ?? 0,
      mandateCount: (json['mandateCount'] as num?)?.toInt() ?? 0,
      autopaySetupCount: (json['autopaySetupCount'] as num?)?.toInt() ?? 0,
      microChargeCount: (json['microChargeCount'] as num?)?.toInt() ?? 0,
      bundleCount: (json['bundleCount'] as num?)?.toInt() ?? 0,
      promoCount: (json['promoCount'] as num?)?.toInt() ?? 0,
      cancellationHintCount:
          (json['cancellationHintCount'] as num?)?.toInt() ?? 0,
      weakRecurringHintCount:
          (json['weakRecurringHintCount'] as num?)?.toInt() ?? 0,
      unknownReviewCount: (json['unknownReviewCount'] as num?)?.toInt() ?? 0,
      oneTimePaymentNoiseCount:
          (json['oneTimePaymentNoiseCount'] as num?)?.toInt() ?? 0,
      ignoreNoiseCount: (json['ignoreNoiseCount'] as num?)?.toInt() ?? 0,
      amountSeries: _readDoubleList(json['amountSeries']),
      intervalHintsInDays: _readIntList(json['intervalHintsInDays']),
      contradictions: _readStringList(json['contradictions']),
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
  final int promoCount;
  final int cancellationHintCount;
  final int weakRecurringHintCount;
  final int unknownReviewCount;
  final int oneTimePaymentNoiseCount;
  final int ignoreNoiseCount;
  final List<double> amountSeries;
  final List<int> intervalHintsInDays;
  final List<String> contradictions;
  final PersistedBucketEvidenceTrail evidenceTrail;

  ServiceEvidenceBucket toDomain() {
    return ServiceEvidenceBucket(
      serviceKey: ServiceKey(serviceKey),
      firstSeenAt: DateTime.parse(firstSeenAt),
      lastSeenAt: DateTime.parse(lastSeenAt),
      lastBilledAt: lastBilledAt == null ? null : DateTime.parse(lastBilledAt!),
      sourceKindsSeen: sourceKindsSeen
          .map(_sourceKindFromName)
          .toList(growable: false),
      billedCount: billedCount,
      renewalHintCount: renewalHintCount,
      mandateCount: mandateCount,
      autopaySetupCount: autopaySetupCount,
      microChargeCount: microChargeCount,
      bundleCount: bundleCount,
      promoCount: promoCount,
      cancellationHintCount: cancellationHintCount,
      weakRecurringHintCount: weakRecurringHintCount,
      unknownReviewCount: unknownReviewCount,
      oneTimePaymentNoiseCount: oneTimePaymentNoiseCount,
      ignoreNoiseCount: ignoreNoiseCount,
      amountSeries: amountSeries,
      intervalHintsInDays: intervalHintsInDays,
      contradictions: contradictions,
      evidenceTrail: evidenceTrail.toDomain(),
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
      'promoCount': promoCount,
      'cancellationHintCount': cancellationHintCount,
      'weakRecurringHintCount': weakRecurringHintCount,
      'unknownReviewCount': unknownReviewCount,
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
