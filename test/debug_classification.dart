import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';

void main() {
  final pipeline = EventPipelineUseCase();
  final receivedAt = DateTime(2026, 3, 12, 23, 0);

  final messages = [
    'Your subscription may renew shortly.',
    'Your membership payment is due soon.',
    'Your Netflix subscription has been renewed for Rs 499.',
    'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
    'Rs 1 debited via UPI to VPA test@upi.',
  ];

  for (var i = 0; i < messages.length; i++) {
    final msg = MessageRecord(
      id: 'msg-$i',
      sourceAddress: 'SRC',
      body: messages[i],
      receivedAt: receivedAt,
    );
    final signal = pipeline.classify(msg);
    print('Message $i: "${messages[i]}" -> ${signal?.eventType}');
  }
}
