enum LocalMessageSourceAccessState {
  sampleDemo,
  deviceLocalAvailable,
  deviceLocalDenied,
  deviceLocalUnavailable,
}

enum LocalMessageSourceResolution {
  sampleLocal,
  deviceLocal,
  deviceLocalStub,
}

enum LocalMessageSourceAccessRequestResult {
  granted,
  denied,
  unavailable,
}
