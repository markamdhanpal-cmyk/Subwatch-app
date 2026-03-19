import 'package:flutter/services.dart';

import '../contracts/local_message_source_capability_provider.dart';
import '../models/local_message_source_access_state.dart';

class AndroidLocalMessageSourceCapabilityProvider
    implements LocalMessageSourceCapabilityProvider {
  static const String defaultChannelName =
      'sub_killer/local_message_source_capability';
  static const String getAccessStateMethod = 'getAccessState';
  static const String requestAccessMethod = 'requestAccess';

  const AndroidLocalMessageSourceCapabilityProvider({
    MethodChannel methodChannel = const MethodChannel(defaultChannelName),
    LocalMessageSourceAccessState fallbackState =
        LocalMessageSourceAccessState.deviceLocalUnavailable,
  })  : _methodChannel = methodChannel,
        _fallbackState = fallbackState;

  final MethodChannel _methodChannel;
  final LocalMessageSourceAccessState _fallbackState;

  @override
  Future<LocalMessageSourceAccessState> getAccessState() async {
    try {
      final rawState = await _methodChannel.invokeMethod<String>(
        getAccessStateMethod,
      );

      return _mapAccessState(rawState);
    } on MissingPluginException {
      return _fallbackState;
    } on PlatformException {
      return _fallbackState;
    }
  }

  @override
  Future<LocalMessageSourceAccessRequestResult> requestAccess() async {
    try {
      final rawResult = await _methodChannel.invokeMethod<String>(
        requestAccessMethod,
      );

      return _mapRequestResult(rawResult);
    } on MissingPluginException {
      return LocalMessageSourceAccessRequestResult.unavailable;
    } on PlatformException {
      return LocalMessageSourceAccessRequestResult.unavailable;
    }
  }

  LocalMessageSourceAccessState _mapAccessState(String? rawState) {
    switch (rawState) {
      case 'sampleDemo':
        return LocalMessageSourceAccessState.sampleDemo;
      case 'deviceLocalAvailable':
        return LocalMessageSourceAccessState.deviceLocalAvailable;
      case 'deviceLocalDenied':
        return LocalMessageSourceAccessState.deviceLocalDenied;
      case 'deviceLocalUnavailable':
        return LocalMessageSourceAccessState.deviceLocalUnavailable;
      default:
        return _fallbackState;
    }
  }

  LocalMessageSourceAccessRequestResult _mapRequestResult(String? rawResult) {
    switch (rawResult) {
      case 'granted':
        return LocalMessageSourceAccessRequestResult.granted;
      case 'denied':
        return LocalMessageSourceAccessRequestResult.denied;
      case 'unavailable':
      default:
        return LocalMessageSourceAccessRequestResult.unavailable;
    }
  }
}
