import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/contracts/local_message_source_capability_provider.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/use_cases/request_device_sms_access_use_case.dart';
import 'package:sub_killer/application/use_cases/sync_device_sms_use_case.dart';
import 'package:sub_killer/domain/enums/dashboard_bucket.dart';

class _MutableCapabilityProvider
    implements LocalMessageSourceCapabilityProvider {
  _MutableCapabilityProvider({
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

class _FakeDeviceSmsGateway implements DeviceSmsGateway {
  const _FakeDeviceSmsGateway(this.messages);

  final List<RawDeviceSms> messages;

  @override
  Future<List<RawDeviceSms>> readMessages() async => messages;
}

void main() {
  group('SyncDeviceSmsUseCase', () {
    test(
        'granted request reloads the runtime dashboard with refreshed device-local state',
        () async {
      final provider = _MutableCapabilityProvider(
        initialState: LocalMessageSourceAccessState.deviceLocalDenied,
        requestResult: LocalMessageSourceAccessRequestResult.granted,
        refreshedState: LocalMessageSourceAccessState.deviceLocalAvailable,
      );
      final useCase = SyncDeviceSmsUseCase(
        requestDeviceSmsAccessUseCase: RequestDeviceSmsAccessUseCase(
          capabilityProvider: provider,
        ),
        loadRuntimeDashboard: () => LoadRuntimeDashboardUseCase(
          capabilityProvider: provider,
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
        ).execute(),
      );

      final result = await useCase.execute();

      expect(
          result.requestResult, LocalMessageSourceAccessRequestResult.granted);
      expect(result.snapshot.messageSourceSelection.accessState,
          LocalMessageSourceAccessState.deviceLocalAvailable);
      expect(result.snapshot.messageSourceSelection.resolution,
          LocalMessageSourceResolution.deviceLocal);
      expect(
        result.snapshot.cards
            .where(
              (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
            )
            .map((card) => card.serviceKey.value),
        contains('NETFLIX'),
      );
    });
  });
}
