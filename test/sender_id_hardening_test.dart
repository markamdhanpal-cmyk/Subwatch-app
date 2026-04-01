import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/message_sources/device_local_sms_message_source.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/domain/knowledge/merchant_knowledge_base.dart';

void main() {
  group('Sender ID Hardening (Ticket 3 & 4)', () {
    group('Token Extraction', () {
      test('extracts middle token from 3-part DLT address', () {
        expect(MerchantKnowledgeBase.extractSenderToken('AD-JIOHTT-S'), 'JIOHTT');
      });

      test('extracts second token from 2-part DLT address', () {
        expect(MerchantKnowledgeBase.extractSenderToken('VX-GOOGLE'), 'GOOGLE');
      });

      test('falls back to raw address if no hyphen present', () {
        expect(MerchantKnowledgeBase.extractSenderToken('BANK'), 'BANK');
      });

      test('is case-insensitive and returns uppercase', () {
        expect(MerchantKnowledgeBase.extractSenderToken('ad-jiohtt-s'), 'JIOHTT');
      });
    });

    group('Resolution Hardening (MerchantKnowledgeBase)', () {
      test('resolves exact match for known prefixes', () {
        final entry = MerchantKnowledgeBase.matchSenderIdPrefix('AD-JIOHTT-S');
        expect(entry?.serviceKey, 'JIOHOTSTAR');
      });

      test('does NOT resolve similar but non-authoritative sender tokens', () {
        // Ticket 3 specific negative case
        final entry = MerchantKnowledgeBase.matchSenderIdPrefix('AD-JIOHTTINFO-S');
        expect(entry, isNull);
      });

      test('does NOT resolve Google One from generic Google alerts', () {
        // Ticket 3 specific negative case
        final entry = MerchantKnowledgeBase.matchSenderIdPrefix('VM-GOOGLEALERT-S');
        expect(entry, isNull);
      });

      test('does NOT resolve Swiggy One from generic Swiggy offers', () {
        // Ticket 3 specific negative case
        final entry = MerchantKnowledgeBase.matchSenderIdPrefix('VM-SWIGGYOFR-S');
        expect(entry, isNull);
      });
    });

    group('Suppression Hardening (DeviceLocalSmsMessageSource)', () {

      test('suppresses verified exact sender tokens', () async {
        final source = _createSourceWithAddresses(['VK-LAZYPY', 'AX-PAYTMI']);
        final messages = await source.loadMessages();
        expect(messages, isEmpty);
      });

      test('does NOT suppress vaguely similar sender tokens', () async {
        // Ticket 4 specific negative case
        final source = _createSourceWithAddresses(['VK-LAZYPAYMENT', 'AX-PAYTMBANK']);
        final messages = await source.loadMessages();
        expect(messages, hasLength(2));
      });

      test('allows real subscription sender tokens to pass', () async {
        final source = _createSourceWithAddresses(['AD-JIOHTT', 'VK-NETFLX', 'G-GOOGLE']);
        final messages = await source.loadMessages();
        expect(messages, hasLength(3));
      });
    });
  });
}

DeviceLocalSmsMessageSource _createSourceWithAddresses(List<String> addresses) {
  return DeviceLocalSmsMessageSource(
    gateway: _FakeGateway(
      addresses.map((addr) => RawDeviceSms(
        id: addr,
        address: addr,
        body: 'Some generic subscription/billing body text.',
        receivedAt: DateTime.now(),
      )).toList(),
    ),
  );
}

class _FakeGateway implements DeviceSmsGateway {
  _FakeGateway(this.messages);
  final List<RawDeviceSms> messages;
  @override
  Future<List<RawDeviceSms>> readMessages() async => messages;
}
