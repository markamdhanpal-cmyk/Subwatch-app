import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';

Future<void> main() async {
  final useCase = LocalIngestionFlowUseCase();
  final receivedAt = DateTime(2026, 3, 12, 23, 0);

  final messages = <String>[
    'Your subscription may renew shortly.',
    'Your membership payment is due soon.',
    'Your Netflix subscription has been renewed for Rs 499.',
    'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
    'Rs 1 debited via UPI to VPA test@upi.',
  ];

  for (var i = 0; i < messages.length; i++) {
    final message = MessageRecord(
      id: 'msg-$i',
      sourceAddress: 'SRC',
      body: messages[i],
      receivedAt: receivedAt,
    );
    final result = await useCase.execute(<MessageRecord>[message]);
    final eventType =
        result.events.isEmpty ? 'none' : result.events.first.type.name;
    print('Message $i: "${messages[i]}" -> $eventType');
  }
}

