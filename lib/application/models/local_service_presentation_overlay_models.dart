import '../../domain/entities/dashboard_card.dart';

class LocalServicePresentationOverlay {
  const LocalServicePresentationOverlay({
    required this.serviceKey,
    this.localLabel,
    this.pinnedAt,
  });

  factory LocalServicePresentationOverlay.fromJson(Map<String, Object?> json) {
    return LocalServicePresentationOverlay(
      serviceKey: json['serviceKey'] as String,
      localLabel: json['localLabel'] as String?,
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String),
    );
  }

  static const Object _unset = Object();

  final String serviceKey;
  final String? localLabel;
  final DateTime? pinnedAt;

  bool get hasLocalLabel => localLabel != null && localLabel!.trim().isNotEmpty;
  bool get isPinned => pinnedAt != null;
  bool get isEmpty => !hasLocalLabel && !isPinned;

  LocalServicePresentationOverlay copyWith({
    Object? localLabel = _unset,
    Object? pinnedAt = _unset,
  }) {
    return LocalServicePresentationOverlay(
      serviceKey: serviceKey,
      localLabel: identical(localLabel, _unset)
          ? this.localLabel
          : localLabel as String?,
      pinnedAt: identical(pinnedAt, _unset)
          ? this.pinnedAt
          : pinnedAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'serviceKey': serviceKey,
      'localLabel': localLabel,
      'pinnedAt': pinnedAt?.toIso8601String(),
    };
  }
}

class LocalServicePresentationState {
  const LocalServicePresentationState({
    required this.serviceKey,
    required this.originalTitle,
    required this.displayTitle,
    required this.localLabel,
    required this.isPinned,
  });

  factory LocalServicePresentationState.fromDashboardCard(
    DashboardCard card, {
    LocalServicePresentationOverlay? overlay,
  }) {
    final localLabel = overlay?.hasLocalLabel == true
        ? overlay!.localLabel!.trim()
        : null;
    return LocalServicePresentationState(
      serviceKey: card.serviceKey.value,
      originalTitle: card.title,
      displayTitle: localLabel ?? card.title,
      localLabel: localLabel,
      isPinned: overlay?.isPinned ?? false,
    );
  }

  final String serviceKey;
  final String originalTitle;
  final String displayTitle;
  final String? localLabel;
  final bool isPinned;

  bool get hasLocalLabel => localLabel != null && localLabel!.trim().isNotEmpty;
}
