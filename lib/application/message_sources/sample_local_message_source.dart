import '../../domain/contracts/local_message_source.dart';
import '../../domain/entities/message_record.dart';

class SampleLocalMessageSource implements LocalMessageSource {
  const SampleLocalMessageSource();

  @override
  Future<List<MessageRecord>> loadMessages() async {
    final receivedAt = DateTime(2026, 3, 12, 12, 0);

    return List<MessageRecord>.unmodifiable(<MessageRecord>[
      MessageRecord(
        id: 'sample-netflix',
        sourceAddress: 'BANK',
        body: 'Your Netflix subscription has been renewed for Rs 499.',
        receivedAt: receivedAt,
      ),
      MessageRecord(
        id: 'sample-spotify',
        sourceAddress: 'SBICRD',
        body: 'SBI Card XX4321 used for Rs 149 at SPOTIFY on 12 Mar.',
        receivedAt: receivedAt.add(const Duration(seconds: 30)),
      ),
      MessageRecord(
        id: 'sample-jiohotstar',
        sourceAddress: 'BANK',
        body: 'You have successfully created a mandate on JioHotstar.',
        receivedAt: receivedAt.add(const Duration(minutes: 1)),
      ),
      MessageRecord(
        id: 'sample-airtel',
        sourceAddress: 'TELCO',
        body:
            'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        receivedAt: receivedAt.add(const Duration(minutes: 2)),
      ),
      MessageRecord(
        id: 'sample-review',
        sourceAddress: 'BANK',
        body: 'Your subscription may renew shortly.',
        receivedAt: receivedAt.add(const Duration(minutes: 3)),
      ),
      MessageRecord(
        id: 'sample-upi-noise',
        sourceAddress: 'BANK',
        body: 'Rs 1 debited via UPI to VPA test@upi.',
        receivedAt: receivedAt.add(const Duration(minutes: 4)),
      ),
    ]);
  }
}
