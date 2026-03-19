import '../../domain/entities/service_ledger_entry.dart';

enum RuntimeSnapshotSourceKind {
  sampleDemo,
  deviceSms,
  safeLocalFallback,
  unknown,
}

enum RuntimeSnapshotProvenanceKind {
  freshLoad,
  restoredLocalSnapshot,
}

class LedgerSnapshotMetadata {
  const LedgerSnapshotMetadata({
    required this.sourceKind,
    required this.refreshedAt,
  });

  factory LedgerSnapshotMetadata.fromJson(Map<String, Object?> json) {
    final sourceName = json['sourceKind'] as String?;
    final sourceKind = RuntimeSnapshotSourceKind.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => RuntimeSnapshotSourceKind.unknown,
    );

    return LedgerSnapshotMetadata(
      sourceKind: sourceKind,
      refreshedAt: DateTime.parse(json['refreshedAt'] as String),
    );
  }

  final RuntimeSnapshotSourceKind sourceKind;
  final DateTime refreshedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sourceKind': sourceKind.name,
      'refreshedAt': refreshedAt.toIso8601String(),
    };
  }
}

class LedgerSnapshotRecord {
  const LedgerSnapshotRecord({
    required this.entries,
    this.metadata,
  });

  final List<ServiceLedgerEntry> entries;
  final LedgerSnapshotMetadata? metadata;
}

class RuntimeSnapshotProvenance {
  const RuntimeSnapshotProvenance({
    required this.kind,
    required this.sourceKind,
    required this.recordedAt,
    this.refreshedAt,
  });

  final RuntimeSnapshotProvenanceKind kind;
  final RuntimeSnapshotSourceKind sourceKind;
  final DateTime recordedAt;
  final DateTime? refreshedAt;
}
