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
