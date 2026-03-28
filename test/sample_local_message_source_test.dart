import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/message_sources/sample_local_message_source.dart';

void main() {
  test('sample local message source returns the expected sample messages',
      () async {
    final messages = await const SampleLocalMessageSource().loadMessages();

    expect(messages, hasLength(6));
    expect(messages.map((message) => message.id), <String>[
      'sample-netflix',
      'sample-spotify',
      'sample-jiohotstar',
      'sample-airtel',
      'sample-review',
      'sample-upi-noise',
    ]);
    expect(
      messages.map((message) => message.body),
      containsAll(<String>[
        'Your Netflix subscription has been renewed for Rs 499.',
        'SBI Card XX4321 used for Rs 149 at SPOTIFY on 12 Mar.',
        'You have successfully created a mandate on JioHotstar.',
        'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        'Your subscription may renew shortly.',
        'Rs 1 debited via UPI to VPA test@upi.',
      ]),
    );
  });
}
