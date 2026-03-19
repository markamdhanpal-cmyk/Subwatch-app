import '../contracts/device_sms_gateway.dart';
import '../contracts/local_message_source_capability_provider.dart';
import '../message_sources/device_local_sms_message_source.dart';
import '../message_sources/sample_local_message_source.dart';
import '../models/local_message_source_access_state.dart';
import '../providers/stub_local_message_source_capability_provider.dart';
import '../../domain/contracts/local_message_source.dart';

class LocalMessageSourceSelection {
  const LocalMessageSourceSelection({
    required this.accessState,
    required this.resolution,
    required this.messageSource,
  });

  final LocalMessageSourceAccessState accessState;
  final LocalMessageSourceResolution resolution;
  final LocalMessageSource messageSource;
}

class SelectLocalMessageSourceUseCase {
  factory SelectLocalMessageSourceUseCase({
    LocalMessageSourceCapabilityProvider? capabilityProvider,
    SampleLocalMessageSource? sampleMessageSource,
    DeviceSmsGateway? deviceSmsGateway,
    DeviceSmsGateway? unavailableDeviceSmsGateway,
  }) {
    return SelectLocalMessageSourceUseCase._(
      capabilityProvider: capabilityProvider ??
          const StubLocalMessageSourceCapabilityProvider(),
      sampleMessageSource:
          sampleMessageSource ?? const SampleLocalMessageSource(),
      deviceLocalMessageSource: DeviceLocalSmsMessageSource(
        gateway: deviceSmsGateway ?? const StubDeviceSmsGateway(),
      ),
      unavailableDeviceLocalMessageSource: DeviceLocalSmsMessageSource(
        gateway: unavailableDeviceSmsGateway ?? const StubDeviceSmsGateway(),
      ),
    );
  }

  const SelectLocalMessageSourceUseCase._({
    required LocalMessageSourceCapabilityProvider capabilityProvider,
    required SampleLocalMessageSource sampleMessageSource,
    required DeviceLocalSmsMessageSource deviceLocalMessageSource,
    required DeviceLocalSmsMessageSource unavailableDeviceLocalMessageSource,
  })  : _capabilityProvider = capabilityProvider,
        _sampleMessageSource = sampleMessageSource,
        _deviceLocalMessageSource = deviceLocalMessageSource,
        _unavailableDeviceLocalMessageSource =
            unavailableDeviceLocalMessageSource;

  final LocalMessageSourceCapabilityProvider _capabilityProvider;
  final SampleLocalMessageSource _sampleMessageSource;
  final DeviceLocalSmsMessageSource _deviceLocalMessageSource;
  final DeviceLocalSmsMessageSource _unavailableDeviceLocalMessageSource;

  Future<LocalMessageSourceSelection> execute() async {
    final accessState = await _capabilityProvider.getAccessState();

    return resolve(accessState);
  }

  LocalMessageSourceSelection resolve(
    LocalMessageSourceAccessState accessState,
  ) {
    switch (accessState) {
      case LocalMessageSourceAccessState.sampleDemo:
        return LocalMessageSourceSelection(
          accessState: accessState,
          resolution: LocalMessageSourceResolution.sampleLocal,
          messageSource: _sampleMessageSource,
        );
      case LocalMessageSourceAccessState.deviceLocalAvailable:
        return LocalMessageSourceSelection(
          accessState: accessState,
          resolution: LocalMessageSourceResolution.deviceLocal,
          messageSource: _deviceLocalMessageSource,
        );
      case LocalMessageSourceAccessState.deviceLocalDenied:
      case LocalMessageSourceAccessState.deviceLocalUnavailable:
        return LocalMessageSourceSelection(
          accessState: accessState,
          resolution: LocalMessageSourceResolution.deviceLocalStub,
          messageSource: _unavailableDeviceLocalMessageSource,
        );
    }
  }
}
