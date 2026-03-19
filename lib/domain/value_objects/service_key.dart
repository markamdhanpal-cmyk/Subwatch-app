class ServiceKey {
  const ServiceKey(this.value);

  final String value;

  String get displayName {
    if (value.isEmpty) {
      return 'Unknown service';
    }

    return value
        .split('_')
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceKey && runtimeType == other.runtimeType && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
