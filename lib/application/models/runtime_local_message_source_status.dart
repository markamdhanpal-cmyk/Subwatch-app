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
    required this.provenanceDescription,
    required this.freshnessLabel,
    required this.freshnessDescription,
    required this.actionLabel,
    required this.isActionEnabled,
    required this.permissionRationaleVariant,
  });

  factory RuntimeLocalMessageSourceStatus.fromSelection(
    LocalMessageSourceSelection selection, {
    required RuntimeSnapshotProvenance provenance,
    DateTime Function()? clock,
  }) {
    final freshness = _freshnessCopy(
      provenance: provenance,
      now: (clock ?? DateTime.now)(),
    );
    final keepsRestoredSnapshot =
        provenance.kind == RuntimeSnapshotProvenanceKind.restoredLocalSnapshot;

    switch (selection.accessState) {
      case LocalMessageSourceAccessState.sampleDemo:
        return RuntimeLocalMessageSourceStatus(
          tone: RuntimeLocalMessageSourceTone.demo,
          title: 'Sample view',
          description: 'Scan your messages to replace the sample view.',
          provenanceTitle: _provenanceTitle(provenance),
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
              ? 'Saved view'
              : 'From your messages',
          description: provenance.kind ==
                  RuntimeSnapshotProvenanceKind.restoredLocalSnapshot
              ? 'Showing the last saved view on this device.'
              : 'Showing what SubWatch found from messages on this device.',
          provenanceTitle: _provenanceTitle(provenance),
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
          title: keepsRestoredSnapshot ? 'Saved view' : 'SMS access is off',
          description: keepsRestoredSnapshot
              ? 'Showing the last saved view on this device.'
              : 'Showing safe local results.',
          provenanceTitle: _provenanceTitle(provenance),
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
              ? 'Saved view'
              : 'SMS refresh unavailable',
          description: keepsRestoredSnapshot
              ? 'Showing the last saved view on this device.'
              : 'Safe local results stay active.',
          provenanceTitle: _provenanceTitle(provenance),
          provenanceDescription: _provenanceDescription(provenance),
          freshnessLabel: freshness.label,
          freshnessDescription: freshness.description,
          actionLabel: 'SMS unavailable',
          isActionEnabled: false,
          permissionRationaleVariant: null,
        );
    }
  }

  final RuntimeLocalMessageSourceTone tone;
  final String title;
  final String description;
  final String provenanceTitle;
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
            return 'Sample view';
          case RuntimeSnapshotSourceKind.deviceSms:
            return 'Checked';
          case RuntimeSnapshotSourceKind.safeLocalFallback:
            return 'Current view';
          case RuntimeSnapshotSourceKind.unknown:
            return 'Current';
        }
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        return 'Saved view';
    }
  }

  static String _provenanceDescription(RuntimeSnapshotProvenance provenance) {
    switch (provenance.kind) {
      case RuntimeSnapshotProvenanceKind.freshLoad:
        return switch (provenance.sourceKind) {
          RuntimeSnapshotSourceKind.sampleDemo =>
            'Showing the sample view prepared on ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.deviceSms =>
            'Checked your messages on ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.safeLocalFallback =>
            'Showing a safe local view prepared on ${_formatTimestamp(provenance.recordedAt)}.',
          RuntimeSnapshotSourceKind.unknown =>
            'Showing a local snapshot from ${_formatTimestamp(provenance.recordedAt)}.',
        };
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        final refreshedAt = provenance.refreshedAt;
        if (refreshedAt == null) {
          return 'Opened the saved view from ${_formatTimestamp(provenance.recordedAt)}.';
        }

        return 'Opened the saved view from ${_formatTimestamp(provenance.recordedAt)}. '
            'It was last checked on ${_formatTimestamp(refreshedAt)} from ${_sourceLabel(provenance.sourceKind)}.';
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
              label: 'Sample view',
              description: 'The sample view stays fixed until you scan your messages.',
            ),
          RuntimeSnapshotSourceKind.deviceSms => (
              label: 'Checked recently',
              description: 'Based on a recent message check on this device.',
            ),
          RuntimeSnapshotSourceKind.safeLocalFallback => (
              label: 'Safe local view',
              description: 'Not from a recent message check.',
            ),
          RuntimeSnapshotSourceKind.unknown => (
              label: 'Timing unavailable',
              description: 'Recent check details are not available.',
            ),
        };
      case RuntimeSnapshotProvenanceKind.restoredLocalSnapshot:
        final refreshedAt = provenance.refreshedAt;
        if (refreshedAt == null) {
          return (
            label: 'Timing unavailable',
            description: 'This saved view does not include recent check timing.',
          );
        }

        final age = now.isAfter(refreshedAt)
            ? now.difference(refreshedAt)
            : Duration.zero;
        if (age < const Duration(hours: 24)) {
          return (
            label: 'Still recent',
            description: 'The last message check on this device is still recent.',
          );
        }
        if (age < const Duration(hours: 72)) {
          return (
            label: 'Check again soon',
            description: 'This saved view is getting older.',
          );
        }
        return (
          label: 'May be out of date',
          description: 'This saved view may be out of date.',
        );
    }
  }

  static String _sourceLabel(RuntimeSnapshotSourceKind sourceKind) {
    switch (sourceKind) {
      case RuntimeSnapshotSourceKind.sampleDemo:
        return 'the sample view';
      case RuntimeSnapshotSourceKind.deviceSms:
        return 'your messages';
      case RuntimeSnapshotSourceKind.safeLocalFallback:
        return 'a safe local view';
      case RuntimeSnapshotSourceKind.unknown:
        return 'this device';
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
