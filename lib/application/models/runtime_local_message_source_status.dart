import '../models/local_message_source_access_state.dart';
import '../models/runtime_snapshot_provenance.dart';
import '../use_cases/select_local_message_source_use_case.dart';

enum RuntimeLocalMessageSourceTone {
  demo,
  fresh,
  restored,
  caution,
  unavailable,
}

enum RuntimeLocalMessageSourcePermissionRationaleVariant {
  firstRun,
  retry,
}

class RuntimeLocalMessageSourceStatus {
  const RuntimeLocalMessageSourceStatus({
    required this.tone,
    required this.title,
    required this.description,
    required this.provenanceTitle,
    required this.hasLocalModifications,
    required this.provenanceDescription,
    required this.freshnessLabel,
    required this.freshnessDescription,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.permissionRationaleVariant,
    this.localModificationsLabel,
  });

  factory RuntimeLocalMessageSourceStatus.fromSelection(
    LocalMessageSourceSelection selection, {
    required RuntimeSnapshotProvenance provenance,
    DateTime Function()? clock,
    bool hasLocalModifications = false,
  }) {
    final freshness = _freshnessCopy(
      provenance: provenance,
      now: (clock ?? DateTime.now)(),
    );
    final localModificationsLabel =
        _localModificationsLabel(hasLocalModifications);
    final keepsRestoredSnapshot =
        provenance.kind == RuntimeSnapshotProvenanceKind.restoredLocalSnapshot;

    switch (selection.accessState) {
      case LocalMessageSourceAccessState.sampleDemo:
        return RuntimeLocalMessageSourceStatus(
          tone: RuntimeLocalMessageSourceTone.demo,
          title: 'Preview',
          description:
              'Scan to see confirmed, included, and possible services.',
          provenanceTitle: _provenanceTitle(provenance),
          hasLocalModifications: hasLocalModifications,
          localModificationsLabel: localModificationsLabel,
          provenanceDescription: _provenanceDescription(provenance),
          freshnessLabel: freshness.label,
          freshnessDescription: freshness.description,
          actionLabel: 'Scan messages',
          isActionEnabled: true,
          permissionRationaleVariant:
              RuntimeLocalMessageSourcePermissionRationaleVariant.firstRun,
        );
      case LocalMessageSourceAccessState.deviceLocalAvailable:
        return RuntimeLocalMessageSourceStatus(
          tone: provenance.kind ==
                  RuntimeSnapshotProvenanceKind.restoredLocalSnapshot
              ? RuntimeLocalMessageSourceTone.restored
              : RuntimeLocalMessageSourceTone.fresh,
          title: provenance.kind ==
                  RuntimeSnapshotProvenanceKind.restoredLocalSnapshot
              ? 'Last results'
              : 'From your messages',
          description: provenance.kind ==
                  RuntimeSnapshotProvenanceKind.restoredLocalSnapshot
              ? 'Showing your last results.'
              : 'Conservative service-level results from your messages.',
          provenanceTitle: _provenanceTitle(provenance),
          hasLocalModifications: hasLocalModifications,
          localModificationsLabel: localModificationsLabel,
          provenanceDescription: _provenanceDescription(provenance),
          freshnessLabel: freshness.label,
          freshnessDescription: freshness.description,
          actionLabel: 'Check again',
          isActionEnabled: true,
          permissionRationaleVariant: null,
        );
      case LocalMessageSourceAccessState.deviceLocalDenied:
        return RuntimeLocalMessageSourceStatus(
          tone: keepsRestoredSnapshot
              ? RuntimeLocalMessageSourceTone.restored
              : RuntimeLocalMessageSourceTone.caution,
          title: keepsRestoredSnapshot ? 'Last results' : 'Turn on SMS access',
          description: keepsRestoredSnapshot
              ? 'Showing your last results.'
              : 'Turn on SMS access to scan.',
          provenanceTitle: _provenanceTitle(provenance),
          hasLocalModifications: hasLocalModifications,
          localModificationsLabel: localModificationsLabel,
          provenanceDescription: _provenanceDescription(provenance),
          freshnessLabel: freshness.label,
          freshnessDescription: freshness.description,
          actionLabel: 'Turn on SMS access',
          isActionEnabled: true,
          permissionRationaleVariant:
              RuntimeLocalMessageSourcePermissionRationaleVariant.retry,
        );
      case LocalMessageSourceAccessState.deviceLocalUnavailable:
        return RuntimeLocalMessageSourceStatus(
          tone: keepsRestoredSnapshot
              ? RuntimeLocalMessageSourceTone.restored
              : RuntimeLocalMessageSourceTone.unavailable,
          title: keepsRestoredSnapshot
              ? 'Last results'
              : 'Can\'t scan here',
          description: keepsRestoredSnapshot
              ? 'Showing your last results.'
              : 'This phone can\'t scan messages.',
          provenanceTitle: _provenanceTitle(provenance),
          hasLocalModifications: hasLocalModifications,
          localModificationsLabel: localModificationsLabel,
          provenanceDescription: _provenanceDescription(provenance),
          freshnessLabel: freshness.label,
          freshnessDescription: freshness.description,
          actionLabel: 'Unavailable here',
          isActionEnabled: false,
          permissionRationaleVariant: null,
        );
    }
  }

  final RuntimeLocalMessageSourceTone tone;
  final String title;
  final String description;
  final String provenanceTitle;
  final bool hasLocalModifications;
  final String? localModificationsLabel;
  final String provenanceDescription;
  final String freshnessLabel;
  final String freshnessDescription;
  final String actionLabel;
  final bool isActionEnabled;
  final RuntimeLocalMessageSourcePermissionRationaleVariant?
      permissionRationaleVariant;

  static String _provenanceTitle(RuntimeSnapshotProvenance provenance) {
    switch (provenance.kind) {
      case RuntimeSnapshotProvenanceKind.freshLoad:
        switch (provenance.sourceKind) {
          case RuntimeSnapshotSourceKind.sampleDemo:
            return 'Preview';
          case RuntimeSnapshotSourceKind.deviceSms:
            return 'From your messages';
          case RuntimeSnapshotSourceKind.safeLocalFallback:
            return 'Last results';
          case RuntimeSnapshotSourceKind.unknown:
            return 'Last results';
        }
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        return 'Last results';
    }
  }

  static String _provenanceDescription(RuntimeSnapshotProvenance provenance) {
    switch (provenance.kind) {
      case RuntimeSnapshotProvenanceKind.freshLoad:
        return switch (provenance.sourceKind) {
          RuntimeSnapshotSourceKind.sampleDemo =>
            'Preview from ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.deviceSms =>
            'Last scan ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.safeLocalFallback =>
            'Saved on ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.unknown =>
            'Saved on ${_formatTimestamp(provenance.recordedAt)}.',
        };
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        final refreshedAt = provenance.refreshedAt;
        if (refreshedAt == null) {
          return 'Saved on ${_formatTimestamp(provenance.recordedAt)}.';
        }

        return 'Saved on ${_formatTimestamp(provenance.recordedAt)}. '
            'Last scan ${_formatTimestamp(refreshedAt)} from ${_sourceLabel(provenance.sourceKind)}.';
    }
  }

  static ({String label, String description}) _freshnessCopy({
    required RuntimeSnapshotProvenance provenance,
    required DateTime now,
  }) {
    switch (provenance.kind) {
      case RuntimeSnapshotProvenanceKind.freshLoad:
        return switch (provenance.sourceKind) {
          RuntimeSnapshotSourceKind.sampleDemo => (
              label: 'Preview',
              description: 'Example only.',
            ),
          RuntimeSnapshotSourceKind.deviceSms => (
              label: _lastScanLabel(provenance.recordedAt, now),
              description: 'From your messages.',
            ),
          RuntimeSnapshotSourceKind.safeLocalFallback => (
              label: 'Last scan unavailable',
              description: 'Using saved results.',
            ),
          RuntimeSnapshotSourceKind.unknown => (
              label: 'Last scan unavailable',
              description: 'Last scan time is unavailable.',
            ),
        };
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        final refreshedAt = provenance.refreshedAt;
        if (refreshedAt == null) {
          return (
            label: 'Last scan unavailable',
            description: 'Last scan time is unavailable.',
          );
        }

        final age = now.isAfter(refreshedAt)
            ? now.difference(refreshedAt)
            : Duration.zero;
        if (age < const Duration(hours: 24)) {
          return (
            label: _lastScanLabel(refreshedAt, now),
            description: 'From your last scan.',
          );
        }
        if (age < const Duration(hours: 72)) {
          return (
            label: _lastScanLabel(refreshedAt, now),
            description: 'From your last scan.',
          );
        }
        return (
          label: _lastScanLabel(refreshedAt, now),
          description: 'From your last scan.',
        );
    }
  }

  static String? _localModificationsLabel(bool hasLocalModifications) {
    if (!hasLocalModifications) {
      return null;
    }
    return 'Changed on this phone';
  }

  static String _lastScanLabel(DateTime timestamp, DateTime now) {
    final scanDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    final days = nowDate.difference(scanDate).inDays;

    if (days <= 0) {
      return 'Last scan: today';
    }
    if (days == 1) {
      return 'Last scan: yesterday';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[timestamp.month - 1];
    if (timestamp.year == now.year) {
      return 'Last scan: ${timestamp.day} $month';
    }
    return 'Last scan: ${timestamp.day} $month ${timestamp.year}';
  }

  static String _sourceLabel(RuntimeSnapshotSourceKind sourceKind) {
    switch (sourceKind) {
      case RuntimeSnapshotSourceKind.sampleDemo:
        return 'sample data';
      case RuntimeSnapshotSourceKind.deviceSms:
        return 'your messages';
      case RuntimeSnapshotSourceKind.safeLocalFallback:
        return 'a saved view';
      case RuntimeSnapshotSourceKind.unknown:
        return 'this phone';
    }
  }

  static String _formatTimestamp(DateTime timestamp) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[timestamp.month - 1];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.day} $month ${timestamp.year}, $hour:$minute';
  }
}
