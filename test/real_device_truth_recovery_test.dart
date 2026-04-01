import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';
import 'package:sub_killer/domain/resolvers/deterministic_resolver.dart';

void main() {
  group('Forensic Truth Recovery: Real-Device Trace Playback', () {
    final eventPipeline = EventPipelineUseCase();
    const resolver = DeterministicResolver();

    test('Forensic 7206: JioHotstar Bundle (Telecom Noise) should NOT be billed', () {
      final message = MessageRecord(
        id: '7206',
        sourceAddress: 'JIO',
        body: 'Recharge now Jio no. 9340533718 with Rs.899 plan & enjoy Jio Offer- Free JioHotstar Mobile/TV subscription for 90 Days. Use PhonePe app & get upto Rs.400 Rewards.Plan 899 benefits: Unlimited 5G data + 2GB/day & 20GB extra 4G data, Unlimited Voice, 90 Days. T&CA.',
        receivedAt: DateTime(2025, 8, 31),
      );

      final events = eventPipeline.execute([message]);
      
      // It might be activeBundled or null, but NOT activePaid.
      for (final event in events) {
        final entry = resolver.resolve(event: event);
        expect(entry.state, isNot(ResolverState.activePaid), reason: 'Jio bundle should not be activePaid');
      }
    });

    test('Forensic 6949: Adobe "Stop Payment Request" should NOT be billed', () {
      final message = MessageRecord(
        id: '6949',
        sourceAddress: 'FEDBNK',
        body: 'Hi! Request to stop payment of Rs 1416 to ADOBE SYS SOFTWARE IRELAND LTD on your Federal Bank Debit Card 4413 has been received. Manage your mandates at -Federal Bank',
        receivedAt: DateTime(2025, 8, 17),
      );

      final events = eventPipeline.execute([message]);
      
      // If it's caught as billed, it's a false positive.
      // It should ideally be caught as a cancellation or ignored.
      for (final event in events) {
        expect(event.type, isNot(SubscriptionEventType.subscriptionBilled), reason: 'Stop payment request is not a成功 billing event');
      }
    });

    test('Forensic 6944: Adobe "Scheduled Debit" should be caught correctly', () {
      final message = MessageRecord(
        id: '6944',
        sourceAddress: 'FEDBNK',
        body: 'Payment to ADOBE SYS SOFTWARE IRELAND LTD for Rs. 1416 is scheduled for debit on 17/8/2025 on Federal Bank Debit Card 4413. Mandate Ref no: FBQ3dQDnZY. To stop, click -Federal Bank',
        receivedAt: DateTime(2025, 8, 17),
      );

      final events = eventPipeline.execute([message]);
      expect(events, isNotEmpty);
      
      // This is a mandate intent, not necessarily a 'billed' success yet in the eyes of the classifier.
      // But it's currently being caught as billed. Let's see if we want to keep it that way or move it to review.
    });

    test('Forensic 6913: Google Play Mandate with Monthly Freq', () {
      final message = MessageRecord(
        id: '6913',
        sourceAddress: 'FEDBNK',
        body: 'Hi, e-mandate on Federal Bank Debit Card 4413 is active for Merchant: Google Play, Desc: GoogleAIPro2TBGoogleOne, Amt: INR 1950.00, Freq: monthly, Start Dt: 12/08/2025 , End Dt: 31/12/2035, SiHubid: Xz2xm6QNmf, Manage e-mandate: T&CA -Federal Bank',
        receivedAt: DateTime(2025, 8, 12),
      );

      final events = eventPipeline.execute([message]);
      expect(events, isNotEmpty);
      expect(events.any((e) => e.type == SubscriptionEventType.mandateCreated), true);
    });

    test('Forensic 7203: UPI Noise should be ignored', () {
      final message = MessageRecord(
        id: '7203',
        sourceAddress: 'FEDBNK',
        body: 'Rs 185.00 sent via UPI on 02-09-2025 at 19:25:02 to AMAR SINGH.Ref:561188881934.Not you? Call 18004251199/SMS BLOCKUPI to 98950 88888 -Federal Bank',
        receivedAt: DateTime(2025, 9, 2),
      );

      final events = eventPipeline.execute([message]);
      expect(events.any((e) => e.type == SubscriptionEventType.subscriptionBilled), false);
    });
  });
}
