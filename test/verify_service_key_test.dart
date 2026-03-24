import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/application/stores/in_memory_review_action_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_control_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_manual_subscription_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_service_presentation_overlay_store.dart';
import 'package:sub_killer/application/stores/in_memory_local_renewal_reminder_store.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';

class FakeDeviceSmsGateway implements DeviceSmsGateway {
  const FakeDeviceSmsGateway(this.messages);
  final List<RawDeviceSms> messages;
  @override
  Future<List<RawDeviceSms>> readMessages() async => messages;
}

void main() async {
  final now = DateTime(2026, 3, 24, 10, 0);
  final gateway = FakeDeviceSmsGateway([
    RawDeviceSms(
      id: 'raw-2',
      address: 'SPOTIFY',
      body: 'Premium Rs 119',
      receivedAt: now.subtract(const Duration(days: 2)),
    ),
  ]);

  final runtimeUseCase = LoadRuntimeDashboardUseCase(
    reviewActionStore: InMemoryReviewActionStore(),
    localControlOverlayStore: InMemoryLocalControlOverlayStore(),
    localManualSubscriptionStore: InMemoryLocalManualSubscriptionStore(),
    localServicePresentationOverlayStore: InMemoryLocalServicePresentationOverlayStore(),
    localRenewalReminderStore: InMemoryLocalRenewalReminderStore(),
    deviceSmsGateway: gateway,
    clock: () => now,
  );

  final snapshot = await runtimeUseCase.execute();
  for (final card in snapshot.cards) {
    print('Card title: ${card.title}, serviceKey: ${card.serviceKey.value}');
  }
}
