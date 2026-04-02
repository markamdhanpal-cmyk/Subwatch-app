class LegacyServiceKeyTrustGuard {
  const LegacyServiceKeyTrustGuard._();

  static const String unresolvedServiceKey = 'UNRESOLVED';
  static const String _legacyLowCandidatePrefix =
      'merchant_resolution:extractedCandidate:low:';
  static const Set<String> _allowedDerivedServiceKeys = <String>{
    'JIO_BUNDLE',
    'AIRTEL_BUNDLE',
    'VI_BUNDLE',
  };

  static String sanitizePersistedServiceKey({
    required String serviceKey,
    required List<String> evidenceNotes,
  }) {
    if (!shouldDemoteToUnresolved(
      serviceKey: serviceKey,
      evidenceNotes: evidenceNotes,
    )) {
      return serviceKey;
    }
    return unresolvedServiceKey;
  }

  static bool shouldDemoteToUnresolved({
    required String serviceKey,
    required List<String> evidenceNotes,
  }) {
    if (serviceKey.isEmpty || serviceKey == unresolvedServiceKey) {
      return false;
    }

    if (_allowedDerivedServiceKeys.contains(serviceKey)) {
      return false;
    }

    return evidenceNotes.any(
      (note) => note.startsWith(_legacyLowCandidatePrefix),
    );
  }
}
