import '../models/local_message_source_access_state.dart';

abstract interface class LocalMessageSourceCapabilityProvider {
  Future<LocalMessageSourceAccessState> getAccessState();
  Future<LocalMessageSourceAccessRequestResult> requestAccess();
}
