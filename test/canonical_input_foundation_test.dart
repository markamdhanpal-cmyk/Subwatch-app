import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/contracts/device_sms_gateway.dart';
import 'package:sub_killer/application/message_sources/device_local_sms_message_source.dart';
import 'package:sub_killer/application/models/raw_device_sms.dart';
import 'package:sub_killer/domain/contracts/local_message_source.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/v2/detection/bridges/canonical_input_message_record_bridge.dart';
import 'package:sub_killer/v2/detection/bridges/local_message_source_canonical_input_source_bridge.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';

void main() {
  group('Canonical input foundation', () {
    test('device local sms source exposes canonical sms inputs', () async {
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

      final canonicalInputs = await source.loadCanonicalInputs();

      expect(canonicalInputs, hasLength(1));
      expect(canonicalInputs.single.id, 'raw-1');
      expect(canonicalInputs.single.kind, CanonicalInputKind.sms);
      expect(
        canonicalInputs.single.origin.kind,
        CanonicalInputOriginKind.deviceSmsInbox,
      );
      expect(canonicalInputs.single.origin.localOnly, isTrue);
      expect(canonicalInputs.single.senderHandle, 'BANK');
      expect(
        canonicalInputs.single.textBody,
        'Your Netflix subscription has been renewed for Rs 499.',
      );
    });

    test('canonical input bridge preserves current message record shape', () {
      const bridge = CanonicalInputMessageRecordBridge();
      final canonicalInput = CanonicalInput.manualText(
        id: 'manual-1',
        textBody: 'Netflix billed me yesterday.',
        receivedAt: DateTime(2026, 3, 18, 8, 30),
      );

      final message = bridge.toMessageRecord(canonicalInput);

      expect(message.id, 'manual-1');
      expect(message.sourceAddress, 'manual_entry');
      expect(message.body, 'Netflix billed me yesterday.');
      expect(message.receivedAt, DateTime(2026, 3, 18, 8, 30));
    });

    test('legacy local message sources can be lifted into canonical inputs',
        () async {
      final bridge = LocalMessageSourceCanonicalInputSourceBridge(
        messageSource: _FakeLocalMessageSource(
          <MessageRecord>[
            MessageRecord(
              id: 'legacy-1',
              sourceAddress: 'HDFCBK',
              body: 'Recurring payment of Rs 159 processed at Google Play.',
              receivedAt: DateTime(2026, 3, 14, 9, 15),
            ),
          ],
        ),
      );

      final canonicalInputs = await bridge.loadCanonicalInputs();

      expect(canonicalInputs, hasLength(1));
      expect(canonicalInputs.single.kind, CanonicalInputKind.sms);
      expect(
        canonicalInputs.single.origin.kind,
        CanonicalInputOriginKind.legacyMessageRecordBridge,
      );
      expect(canonicalInputs.single.senderHandle, 'HDFCBK');
      expect(
        canonicalInputs.single.textBody,
        'Recurring payment of Rs 159 processed at Google Play.',
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

class _FakeLocalMessageSource implements LocalMessageSource {
  const _FakeLocalMessageSource(this.messages);

  final List<MessageRecord> messages;

  @override
  Future<List<MessageRecord>> loadMessages() async {
    return messages;
  }
}
