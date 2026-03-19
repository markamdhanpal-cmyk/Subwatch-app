import '../contracts/device_sms_gateway.dart';
import '../contracts/local_message_source_capability_provider.dart';
import '../gateways/android_device_sms_gateway.dart';
import '../message_sources/device_local_sms_message_source.dart';
import '../models/local_message_source_access_state.dart';
import '../providers/android_local_message_source_capability_provider.dart';
import '../providers/stub_local_message_source_capability_provider.dart';

class LocalMessageSourcePlatformBinding {
  const LocalMessageSourcePlatformBinding({
    required this.capabilityProvider,
    required this.deviceSmsGateway,
    DeviceSmsGateway? unavailableDeviceSmsGateway,
  }) : unavailableDeviceSmsGateway =
            unavailableDeviceSmsGateway ?? const StubDeviceSmsGateway();

  factory LocalMessageSourcePlatformBinding.sampleDemo() {
    return const LocalMessageSourcePlatformBinding(
      capabilityProvider: StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.sampleDemo,
      ),
      deviceSmsGateway: StubDeviceSmsGateway(),
    );
  }

  factory LocalMessageSourcePlatformBinding.stubDeviceLocal() {
    return const LocalMessageSourcePlatformBinding(
      capabilityProvider: StubLocalMessageSourceCapabilityProvider(
        accessState: LocalMessageSourceAccessState.deviceLocalUnavailable,
      ),
      deviceSmsGateway: StubDeviceSmsGateway(),
    );
  }

  factory LocalMessageSourcePlatformBinding.android() {
    return const LocalMessageSourcePlatformBinding(
      capabilityProvider: AndroidLocalMessageSourceCapabilityProvider(),
      deviceSmsGateway: AndroidDeviceSmsGateway(),
    );
  }

  final LocalMessageSourceCapabilityProvider capabilityProvider;
  final DeviceSmsGateway deviceSmsGateway;
  final DeviceSmsGateway unavailableDeviceSmsGateway;
}
