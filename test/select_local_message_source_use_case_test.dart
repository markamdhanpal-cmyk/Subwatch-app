import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/message_sources/device_local_sms_message_source.dart';
import 'package:sub_killer/application/message_sources/sample_local_message_source.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/select_local_message_source_use_case.dart';

void main() {
  group('SelectLocalMessageSourceUseCase', () {
    test('sample demo capability state selects the sample local message source',
        () async {
      final selection = await SelectLocalMessageSourceUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(),
      ).execute();

      expect(selection.accessState, LocalMessageSourceAccessState.sampleDemo);
      expect(selection.resolution, LocalMessageSourceResolution.sampleLocal);
      expect(selection.messageSource, isA<SampleLocalMessageSource>());
    });

    test(
        'device-local available capability state selects the device-local source',
        () async {
      final selection = await SelectLocalMessageSourceUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
      ).execute();

      expect(
        selection.accessState,
        LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      expect(selection.resolution, LocalMessageSourceResolution.deviceLocal);
      expect(selection.messageSource, isA<DeviceLocalSmsMessageSource>());
    });

    test('denied capability state resolves to the deterministic stub-safe path',
        () async {
      final deniedSelection = await SelectLocalMessageSourceUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalDenied,
        ),
      ).execute();

      expect(
        deniedSelection.resolution,
        LocalMessageSourceResolution.deviceLocalStub,
      );
      expect(
        deniedSelection.accessState,
        LocalMessageSourceAccessState.deviceLocalDenied,
      );
      expect(deniedSelection.messageSource, isA<DeviceLocalSmsMessageSource>());
      expect(await deniedSelection.messageSource.loadMessages(), isEmpty);
    });

    test(
        'unavailable capability state resolves to the deterministic stub-safe path',
        () async {
      final unavailableSelection = await SelectLocalMessageSourceUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalUnavailable,
        ),
      ).execute();

      expect(
        unavailableSelection.resolution,
        LocalMessageSourceResolution.deviceLocalStub,
      );
      expect(
        unavailableSelection.accessState,
        LocalMessageSourceAccessState.deviceLocalUnavailable,
      );
      expect(
        unavailableSelection.messageSource,
        isA<DeviceLocalSmsMessageSource>(),
      );
      expect(await unavailableSelection.messageSource.loadMessages(), isEmpty);
    });
  });
}
