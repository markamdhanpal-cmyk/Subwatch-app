import '../../domain/entities/service_ledger_entry.dart';
import '../../v2/decision/enums/decision_execution_mode.dart';

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
    this.schemaVersion = 2,
    this.decisionExecutionMode,
    this.shadowDifferenceCount,
    this.shadowComparedAt,
  });

  factory LedgerSnapshotMetadata.fromJson(Map<String, Object?> json) {
    final sourceName = json['sourceKind'] as String?;
    final sourceKind = RuntimeSnapshotSourceKind.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => RuntimeSnapshotSourceKind.unknown,
    );
    final decisionModeName = json['decisionExecutionMode'] as String?;
    DecisionExecutionMode? decisionExecutionMode;
    if (decisionModeName != null) {
      for (final value in DecisionExecutionMode.values) {
        if (value.name == decisionModeName) {
          decisionExecutionMode = value;
          break;
        }
      }
    }

    return LedgerSnapshotMetadata(
      sourceKind: sourceKind,
      refreshedAt: DateTime.parse(json['refreshedAt'] as String),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      decisionExecutionMode: decisionExecutionMode,
      shadowDifferenceCount: (json['shadowDifferenceCount'] as num?)?.toInt(),
      shadowComparedAt: json['shadowComparedAt'] is String
          ? DateTime.parse(json['shadowComparedAt'] as String)
          : null,
    );
  }

  final int schemaVersion;
  final RuntimeSnapshotSourceKind sourceKind;
  final DateTime refreshedAt;
  final DecisionExecutionMode? decisionExecutionMode;
  final int? shadowDifferenceCount;
  final DateTime? shadowComparedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'sourceKind': sourceKind.name,
      'refreshedAt': refreshedAt.toIso8601String(),
      if (decisionExecutionMode != null)
        'decisionExecutionMode': decisionExecutionMode!.name,
      if (shadowDifferenceCount != null)
        'shadowDifferenceCount': shadowDifferenceCount,
      if (shadowComparedAt != null)
        'shadowComparedAt': shadowComparedAt!.toIso8601String(),
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
    this.decisionExecutionMode,
    this.shadowDifferenceCount,
    this.shadowComparedAt,
  });

  final RuntimeSnapshotProvenanceKind kind;
  final RuntimeSnapshotSourceKind sourceKind;
  final DateTime recordedAt;
  final DateTime? refreshedAt;
  final DecisionExecutionMode? decisionExecutionMode;
  final int? shadowDifferenceCount;
  final DateTime? shadowComparedAt;
}
