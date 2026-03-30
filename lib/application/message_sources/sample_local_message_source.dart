import '../../domain/contracts/local_message_source.dart';
import '../../domain/entities/message_record.dart';
import '../../v2/detection/bridges/canonical_input_message_record_bridge.dart';
import '../../v2/detection/contracts/canonical_input_source.dart';
import '../../v2/detection/models/canonical_input.dart';

class SampleLocalMessageSource
    implements LocalMessageSource, CanonicalInputSource {
  const SampleLocalMessageSource({
    CanonicalInputMessageRecordBridge messageRecordBridge =
        const CanonicalInputMessageRecordBridge(),
  }) : _messageRecordBridge = messageRecordBridge;

  final CanonicalInputMessageRecordBridge _messageRecordBridge;

  @override
  Future<List<MessageRecord>> loadMessages() async {
    final canonicalInputs = await loadCanonicalInputs();
    return _messageRecordBridge.toMessageRecords(canonicalInputs);
  }

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final receivedAt = DateTime(2026, 3, 12, 12, 0);

    return List<CanonicalInput>.unmodifiable(<CanonicalInput>[
      CanonicalInput.sampleSms(
        id: 'sample-netflix',
        senderHandle: 'BANK',
        textBody: 'Your Netflix subscription has been renewed for Rs 499.',
        receivedAt: receivedAt,
      ),
      CanonicalInput.sampleSms(
        id: 'sample-spotify',
        senderHandle: 'SBICRD',
        textBody: 'SBI Card XX4321 used for Rs 149 at SPOTIFY on 12 Mar.',
        receivedAt: receivedAt.add(const Duration(seconds: 30)),
      ),
      CanonicalInput.sampleSms(
        id: 'sample-jiohotstar',
        senderHandle: 'BANK',
        textBody: 'You have successfully created a mandate on JioHotstar.',
        receivedAt: receivedAt.add(const Duration(minutes: 1)),
      ),
      CanonicalInput.sampleSms(
        id: 'sample-airtel',
        senderHandle: 'TELCO',
        textBody:
            'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        receivedAt: receivedAt.add(const Duration(minutes: 2)),
      ),
      CanonicalInput.sampleSms(
        id: 'sample-review',
        senderHandle: 'BANK',
        textBody: 'Your subscription may renew shortly.',
        receivedAt: receivedAt.add(const Duration(minutes: 3)),
      ),
      CanonicalInput.sampleSms(
        id: 'sample-upi-noise',
        senderHandle: 'BANK',
        textBody: 'Rs 1 debited via UPI to VPA test@upi.',
        receivedAt: receivedAt.add(const Duration(minutes: 4)),
      ),
    ]);
  }
}
