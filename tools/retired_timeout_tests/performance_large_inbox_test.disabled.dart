import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/models/local_message_source_access_state.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/application/providers/stub_local_message_source_capability_provider.dart';
import 'package:sub_killer/application/use_cases/load_runtime_dashboard_use_case.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';

void main() {
  group('Large SMS Inbox Performance', () {
    final now = DateTime(2026, 3, 24, 10, 0);

    LoadRuntimeDashboardUseCase buildRuntimeUseCase(List<RawDeviceSms> messages) {
      return LoadRuntimeDashboardUseCase(
        capabilityProvider: const StubLocalMessageSourceCapabilityProvider(
          accessState: LocalMessageSourceAccessState.deviceLocalAvailable,
        ),
        deviceSmsGateway: _StaticGateway(messages),
        clock: () => now,
      );
    }

    test('1000 message scan remains responsive and trust-safe', () async {
      final messages = List<RawDeviceSms>.generate(1000, (index) {
        if (index % 100 == 0) {
          return RawDeviceSms(
            id: 'paid-$index',
            address: 'BANK-SMS',
            body:
                'Your Netflix subscription has been renewed for Rs 499 successfully.',
            receivedAt: now.subtract(Duration(days: index % 30)),
          );
        }

        return RawDeviceSms(
          id: 'noise-$index',
          address: 'AD-PROMO-S',
          body: 'Limited period offer $index. Buy now and get cashback.',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final useCase = buildRuntimeUseCase(messages);
      final stopwatch = Stopwatch()..start();
      final snapshot = await useCase.execute();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(
        snapshot.cards
            .where((card) => card.state == ResolverState.activePaid)
            .isNotEmpty,
        isTrue,
      );
      expect(snapshot.reviewQueue, isEmpty);
    });

    test('telecom-heavy noisy inbox does not leak obvious noise', () async {
      final messages = List<RawDeviceSms>.generate(2500, (index) {
        if (index % 250 == 0) {
          return RawDeviceSms(
            id: 'bundle-$index',
            address: 'AD-AIRTEL-S',
            body:
                'Your recent Airtel recharge has unlocked a FREE 6-month Google Gemini Pro plan as an included benefit.',
            receivedAt: now.subtract(Duration(days: index % 28)),
          );
        }

        if (index % 75 == 0) {
          return RawDeviceSms(
            id: 'missed-$index',
            address: 'VK-ALERT-S',
            body: 'You missed a call from +91-9876543210. Call me back.',
            receivedAt: now.subtract(Duration(minutes: index)),
          );
        }

        return RawDeviceSms(
          id: 'telecom-noise-$index',
          address: 'AD-JIOINF-S',
          body:
              'Aapka daily data quota almost khatam hai. Recharge karke validity continue karein.',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final useCase = buildRuntimeUseCase(messages);
      final stopwatch = Stopwatch()..start();
      final snapshot = await useCase.execute();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(
        snapshot.cards
            .where((card) => card.state == ResolverState.activePaid)
            .isEmpty,
        isTrue,
      );
      expect(
        snapshot.cards
            .where((card) => card.state == ResolverState.activeBundled)
            .isNotEmpty,
        isTrue,
      );
      expect(snapshot.reviewQueue, isEmpty);
    });

    test('5000 mixed inbox scan finishes within practical beta threshold',
        () async {
      final messages = List<RawDeviceSms>.generate(5000, (index) {
        if (index % 400 == 0) {
          return RawDeviceSms(
            id: 'paid-$index',
            address: 'BANK-SMS',
            body:
                'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
            receivedAt: now.subtract(Duration(days: index % 30)),
          );
        }

        if (index % 125 == 0) {
          return RawDeviceSms(
            id: 'upi-$index',
            address: 'VK-BANK-S',
            body: 'Rs 1 debited via UPI to VPA test@upi.',
            receivedAt: now.subtract(Duration(minutes: index)),
          );
        }

        return RawDeviceSms(
          id: 'noise-$index',
          address: 'VK-CHAT-S',
          body: 'Verified business chatbot message $index. Tap to reply.',
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      });

      final useCase = buildRuntimeUseCase(messages);
      final stopwatch = Stopwatch()..start();
      final snapshot = await useCase.execute();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(8000));
      expect(snapshot.cards.isNotEmpty, isTrue);
    });
  });
}

class _StaticGateway implements DeviceSmsGateway {
  const _StaticGateway(this._messages);

  final List<RawDeviceSms> _messages;

  Future<List<RawDeviceSms>> readMessages() async => _messages;
}


