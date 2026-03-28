import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/local_message_source_capability_provider.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/use_cases/request_device_sms_access_use_case.dart';

class _FakeCapabilityProvider implements LocalMessageSourceCapabilityProvider {
  _FakeCapabilityProvider({
    required this.initialState,
    required this.requestResult,
    required this.refreshedState,
  }) : _state = initialState;

  final LocalMessageSourceAccessState initialState;
  final LocalMessageSourceAccessRequestResult requestResult;
  final LocalMessageSourceAccessState refreshedState;
  int requestCount = 0;
  LocalMessageSourceAccessState _state;

  @override
  Future<LocalMessageSourceAccessState> getAccessState() async => _state;

  @override
  Future<LocalMessageSourceAccessRequestResult> requestAccess() async {
    requestCount++;
    _state = refreshedState;
    return requestResult;
  }
}

void main() {
  test('request use case refreshes selection after a granted permission result',
      () async {
    final provider = _FakeCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalDenied,
      requestResult: LocalMessageSourceAccessRequestResult.granted,
      refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
    );
    final useCase = RequestDeviceSmsAccessUseCase(
      capabilityProvider: provider,
    );

    final result = await useCase.execute();

    expect(result.requestResult, LocalMessageSourceAccessRequestResult.granted);
    expect(result.selection.accessState,
        LocalMessageSourceAccessState.deviceLocalAvailable);
    expect(
        result.selection.resolution, LocalMessageSourceResolution.deviceLocal);
    expect(provider.requestCount, 1);
  });

  test(
      'request use case preserves the safe path when access remains unavailable',
      () async {
    final provider = _FakeCapabilityProvider(
      initialState: LocalMessageSourceAccessState.deviceLocalUnavailable,
      requestResult: LocalMessageSourceAccessRequestResult.unavailable,
      refreshedState: LocalMessageSourceAccessState.deviceLocalUnavailable,
    );
    final useCase = RequestDeviceSmsAccessUseCase(
      capabilityProvider: provider,
    );

    final result = await useCase.execute();

    expect(result.requestResult,
        LocalMessageSourceAccessRequestResult.unavailable);
    expect(result.selection.accessState,
        LocalMessageSourceAccessState.deviceLocalUnavailable);
    expect(result.selection.resolution,
        LocalMessageSourceResolution.deviceLocalStub);
    expect(provider.requestCount, 1);
  });
}
