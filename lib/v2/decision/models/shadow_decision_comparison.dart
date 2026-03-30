import '../../../domain/entities/service_ledger_entry.dart';

class ShadowDecisionComparison {
  ShadowDecisionComparison({
    required this.comparedAt,
    required this.legacyEntryCount,
    required this.v2EntryCount,
    required List<ShadowDecisionDrift> drifts,
  }) : drifts = List<ShadowDecisionDrift>.unmodifiable(drifts);

  final DateTime comparedAt;
  final int legacyEntryCount;
  final int v2EntryCount;
  final List<ShadowDecisionDrift> drifts;

  int get driftCount => drifts.length;
  bool get hasDifferences => drifts.isNotEmpty;

  String toDebugString() {
    return 'legacy=$legacyEntryCount; '
        'v2=$v2EntryCount; '
        'drifts=$driftCount; '
        'services=[${drifts.map((drift) => drift.serviceKey).join(', ')}]';
  }
}

class ShadowDecisionDrift {
  const ShadowDecisionDrift({
    required this.serviceKey,
    required this.legacyStateName,
    required this.v2StateName,
    required this.legacyEventTypeName,
    required this.v2EventTypeName,
    required this.legacyTotalBilled,
    required this.v2TotalBilled,
  });

  factory ShadowDecisionDrift.fromEntries({
    required String serviceKey,
    ServiceLedgerEntry? legacyEntry,
    ServiceLedgerEntry? v2Entry,
  }) {
    return ShadowDecisionDrift(
      serviceKey: serviceKey,
      legacyStateName: legacyEntry?.state.name ?? 'missing',
      v2StateName: v2Entry?.state.name ?? 'missing',
      legacyEventTypeName: legacyEntry?.lastEventType?.name ?? 'none',
      v2EventTypeName: v2Entry?.lastEventType?.name ?? 'none',
      legacyTotalBilled: legacyEntry?.totalBilled ?? 0,
      v2TotalBilled: v2Entry?.totalBilled ?? 0,
    );
  }

  final String serviceKey;
  final String legacyStateName;
  final String v2StateName;
  final String legacyEventTypeName;
  final String v2EventTypeName;
  final double legacyTotalBilled;
  final double v2TotalBilled;

  String toDebugString() {
    return '$serviceKey: '
        '$legacyStateName/$legacyEventTypeName/${legacyTotalBilled.toStringAsFixed(2)} '
        '-> '
        '$v2StateName/$v2EventTypeName/${v2TotalBilled.toStringAsFixed(2)}';
  }
}
