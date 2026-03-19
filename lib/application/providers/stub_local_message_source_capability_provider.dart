import '../contracts/local_message_source_capability_provider.dart';
import '../models/local_message_source_access_state.dart';

class StubLocalMessageSourceCapabilityProvider
    implements LocalMessageSourceCapabilityProvider {
  const StubLocalMessageSourceCapabilityProvider({
    LocalMessageSourceAccessState accessState =
        LocalMessageSourceAccessState.sampleDemo,
  }) : _accessState = accessState;

  final LocalMessageSourceAccessState _accessState;

  @override
  Future<LocalMessageSourceAccessState> getAccessState() async {
    return _accessState;
  }

  @override
  Future<LocalMessageSourceAccessRequestResult> requestAccess() async {
    switch (_accessState) {
      case LocalMessageSourceAccessState.deviceLocalAvailable:
        return LocalMessageSourceAccessRequestResult.granted;
      case LocalMessageSourceAccessState.deviceLocalDenied:
        return LocalMessageSourceAccessRequestResult.denied;
      case LocalMessageSourceAccessState.sampleDemo:
      case LocalMessageSourceAccessState.deviceLocalUnavailable:
        return LocalMessageSourceAccessRequestResult.unavailable;
    }
  }
}
