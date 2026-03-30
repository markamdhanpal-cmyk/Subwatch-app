import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/message_sources/device_local_sms_message_source.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';

void main() {
  group('DeviceLocalSmsMessageSource', () {
    test('maps raw device sms into message records', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-1',
              address: 'BANK',
              body: 'Your Netflix subscription has been renewed for Rs 499.',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();

      expect(messages, hasLength(1));
      expect(messages.single.id, 'raw-1');
      expect(messages.single.sourceAddress, 'BANK');
      expect(messages.single.body, 'Your Netflix subscription has been renewed for Rs 499.');
    });

    test('filters empty body messages', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'raw-empty',
              address: 'AD-JIOINF',
              body: '   \n  ',
              receivedAt: DateTime(2026, 3, 12, 13, 0),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();
      expect(messages, isEmpty);
    });

    test('filters RCS bot messages', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'rcs-1',
              address: 'somebrand.rcs.google.com',
              body: 'Hello from RCS bot',
              receivedAt: DateTime.now(),
            ),
            RawDeviceSms(
              id: 'rcs-2',
              address: '1234@bot.rcs.google.com',
              body: 'Another RCS struct',
              receivedAt: DateTime.now(),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();
      expect(messages, isEmpty);
    });

    test('filters LazyPay BNPL debt sender fixture', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'bnpl-1',
              address: 'VK-LAZYPY',
              body: 'Your Lazypay due is Rs 5000.',
              receivedAt: DateTime.now(),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();
      expect(messages, isEmpty);
    });

    test('filters Paytm insurance sender fixture', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'ins-1',
              address: 'AX-PAYTMI',
              body: 'Your health insurance protocol updated.',
              receivedAt: DateTime.now(),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();
      expect(messages, isEmpty);
    });

    test('does not suppress real subscription senders accidentally', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: _FakeDeviceSmsGateway(
          <RawDeviceSms>[
            RawDeviceSms(
              id: 'sub-1',
              address: 'AD-JIOHTT',
              body: 'Your JioHotstar plan is active.',
              receivedAt: DateTime.now(),
            ),
            RawDeviceSms(
              id: 'sub-2',
              address: 'VK-NETFLX',
              body: 'Your Netflix plan renewed.',
              receivedAt: DateTime.now(),
            ),
          ],
        ),
      );

      final messages = await source.loadMessages();
      expect(messages, hasLength(2));
    });

    test('stub device sms gateway remains compile-safe and returns no messages', () async {
      final source = DeviceLocalSmsMessageSource(
        gateway: const StubDeviceSmsGateway(),
      );

      final messages = await source.loadMessages();

      expect(messages, isEmpty);
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
