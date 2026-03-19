import '../contracts/local_message_source_capability_provider.dart';
import '../models/local_message_source_access_state.dart';
import 'select_local_message_source_use_case.dart';

class RequestDeviceSmsAccessResult {
  const RequestDeviceSmsAccessResult({
    required this.requestResult,
    required this.selection,
  });

  final LocalMessageSourceAccessRequestResult requestResult;
  final LocalMessageSourceSelection selection;
}

class RequestDeviceSmsAccessUseCase {
  factory RequestDeviceSmsAccessUseCase({
    required LocalMessageSourceCapabilityProvider capabilityProvider,
    SelectLocalMessageSourceUseCase? selectLocalMessageSourceUseCase,
  }) {
    return RequestDeviceSmsAccessUseCase._(
      capabilityProvider: capabilityProvider,
      selectLocalMessageSourceUseCase: selectLocalMessageSourceUseCase ??
          SelectLocalMessageSourceUseCase(
            capabilityProvider: capabilityProvider,
          ),
    );
  }

  const RequestDeviceSmsAccessUseCase._({
    required LocalMessageSourceCapabilityProvider capabilityProvider,
    required SelectLocalMessageSourceUseCase selectLocalMessageSourceUseCase,
  })  : _capabilityProvider = capabilityProvider,
        _selectLocalMessageSourceUseCase = selectLocalMessageSourceUseCase;

  final LocalMessageSourceCapabilityProvider _capabilityProvider;
  final SelectLocalMessageSourceUseCase _selectLocalMessageSourceUseCase;

  Future<RequestDeviceSmsAccessResult> execute() async {
    final requestResult = await _capabilityProvider.requestAccess();
    final selection = await _selectLocalMessageSourceUseCase.execute();

    return RequestDeviceSmsAccessResult(
      requestResult: requestResult,
      selection: selection,
    );
  }
}
