import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/gateways/android_device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/local_message_source_platform_binding.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/models/runtime_snapshot_provenance.dart';
import 'package:sub_killer/application/providers/android_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const capabilityChannel = MethodChannel(
    AndroidLocalMessageSourceCapabilityProvider.defaultChannelName,
  );
  const gatewayChannel =
      MethodChannel(AndroidDeviceSmsGateway.defaultChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(capabilityChannel, null);
    messenger.setMockMethodCallHandler(gatewayChannel, null);
  });

  group('LoadRuntimeDashboardUseCase', () {
    test('runtime wiring produces projected dashboard cards', () async {
      final result = await LoadRuntimeDashboardUseCase().execute();

      expect(
        result.messageSourceSelection.resolution,
        LocalMessageSourceResolution.sampleLocal,
      );
      expect(
        result.messageSourceSelection.accessState,
        LocalMessageSourceAccessState.sampleDemo,
      );
      expect(result.provenance.kind, RuntimeSnapshotProvenanceKind.freshLoad);
      expect(result.provenance.sourceKind, RuntimeSnapshotSourceKind.sampleDemo);
      expect(
        result.cards
            .where(
              (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
            )
            .map((card) => card.serviceKey.value),
        contains('NETFLIX'),
      );
      expect(
        result.cards
            .where((card) => card.bucket == DashboardBucket.needsReview)
            .map((card) => card.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(
        result.cards
            .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
            .map((card) => card.serviceKey.value),
        contains('GOOGLE_GEMINI_PRO'),
      );
    });

    test('runtime wiring produces review queue items', () async {
      final result = await LoadRuntimeDashboardUseCase().execute();

      expect(result.reviewQueue, isNotEmpty);
      expect(
        result.reviewQueue.map((item) => item.serviceKey.value),
        contains('JIOHOTSTAR'),
      );
      expect(
        result.reviewQueue.map((item) => item.serviceKey.value),
        isNot(contains('NETFLIX')),
      );
    });

    test(
        'runtime loading still works using provider-driven device-local selection',
        () async {
      final result = await LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-netflix',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
      ).execute();

      expect(
        result.messageSourceSelection.accessState,
        LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      expect(result.provenance.kind, RuntimeSnapshotProvenanceKind.freshLoad);
      expect(result.provenance.sourceKind, RuntimeSnapshotSourceKind.deviceSms);
      expect(
        result.messageSourceSelection.resolution,
        LocalMessageSourceResolution.deviceLocal,
      );
      expect(
        result.cards
            .where(
              (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
            )
            .map((card) => card.serviceKey.value),
        contains('NETFLIX'),
      );
    });

    test('runtime loading works when the android-facing path is selected',
        () async {
      messenger.setMockMethodCallHandler(capabilityChannel, (call) async {
        expect(
          call.method,
          AndroidLocalMessageSourceCapabilityProvider.getAccessStateMethod,
        );

        return 'deviceLocalAvailable';
      });
      messenger.setMockMethodCallHandler(gatewayChannel, (call) async {
        expect(call.method, AndroidDeviceSmsGateway.readMessagesMethod);

        return <Object?>[
          <Object?, Object?>{
            'id': 'android-netflix',
            'address': 'BANK',
            'body': 'Your Netflix subscription has been renewed for Rs 499.',
            'receivedAtMillisecondsSinceEpoch':
                DateTime(2026, 3, 12, 13, 0).millisecondsSinceEpoch,
          },
        ];
      });

      final result = await LoadRuntimeDashboardUseCase.android().execute();

      expect(
        result.messageSourceSelection.accessState,
        LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      expect(
        result.messageSourceSelection.resolution,
        LocalMessageSourceResolution.deviceLocal,
      );
      expect(result.provenance.kind, RuntimeSnapshotProvenanceKind.freshLoad);
      expect(result.provenance.sourceKind, RuntimeSnapshotSourceKind.deviceSms);
      expect(
        result.cards
            .where(
              (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
            )
            .map((card) => card.serviceKey.value),
        contains('NETFLIX'),
      );
    });

    test(
        'device-local stub path is compile-safe and does not break runtime wiring',
        () async {
      final result =
          await LoadRuntimeDashboardUseCase.deviceLocalStub().execute();

      expect(
        result.messageSourceSelection.accessState,
        LocalMessageSourceAccessState.deviceLocalUnavailable,
      );
      expect(
        result.provenance.sourceKind,
        RuntimeSnapshotSourceKind.safeLocalFallback,
      );
      expect(
        result.messageSourceSelection.resolution,
        LocalMessageSourceResolution.deviceLocalStub,
      );
      expect(result.cards, isEmpty);
      expect(result.reviewQueue, isEmpty);
    });

    test('sample/demo platform binding remains unchanged', () async {
      final result = await LoadRuntimeDashboardUseCase(
        platformBinding: LocalMessageSourcePlatformBinding.sampleDemo(),
      ).execute();

      expect(
        result.messageSourceSelection.accessState,
        LocalMessageSourceAccessState.sampleDemo,
      );
      expect(
        result.messageSourceSelection.resolution,
        LocalMessageSourceResolution.sampleLocal,
      );
    });
  });
}

class _FakeDeviceSmsGateway implements DeviceSmsGateway {
  const _FakeDeviceSmsGateway(this.messages);

  final List<RawDeviceSms> messages;

  @override
  Future<List<RawDeviceSms>> readMessages() async {
    return messages;
  }
}
