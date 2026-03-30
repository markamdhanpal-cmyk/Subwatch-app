import '../../../domain/entities/service_ledger_entry.dart';
import '../models/shadow_decision_comparison.dart';

class BuildShadowDecisionComparisonUseCase {
  const BuildShadowDecisionComparisonUseCase();

  ShadowDecisionComparison execute({
    required List<ServiceLedgerEntry> legacyEntries,
    required List<ServiceLedgerEntry> v2Entries,
    required DateTime comparedAt,
  }) {
    final legacyByKey = <String, ServiceLedgerEntry>{
      for (final entry in legacyEntries) entry.serviceKey.value: entry,
    };
    final v2ByKey = <String, ServiceLedgerEntry>{
      for (final entry in v2Entries) entry.serviceKey.value: entry,
    };
    final serviceKeys = <String>{
      ...legacyByKey.keys,
      ...v2ByKey.keys,
    }.toList(growable: false)
      ..sort();

    final drifts = <ShadowDecisionDrift>[];
    for (final serviceKey in serviceKeys) {
      final legacyEntry = legacyByKey[serviceKey];
      final v2Entry = v2ByKey[serviceKey];
      if (_entriesMatch(legacyEntry, v2Entry)) {
        continue;
      }

      drifts.add(
        ShadowDecisionDrift.fromEntries(
          serviceKey: serviceKey,
          legacyEntry: legacyEntry,
          v2Entry: v2Entry,
        ),
      );
    }

    return ShadowDecisionComparison(
      comparedAt: comparedAt,
      legacyEntryCount: legacyEntries.length,
      v2EntryCount: v2Entries.length,
      drifts: drifts,
    );
  }

  bool _entriesMatch(
    ServiceLedgerEntry? legacyEntry,
    ServiceLedgerEntry? v2Entry,
  ) {
    return legacyEntry?.state == v2Entry?.state &&
        legacyEntry?.lastEventType == v2Entry?.lastEventType &&
        legacyEntry?.totalBilled == v2Entry?.totalBilled;
  }
}
