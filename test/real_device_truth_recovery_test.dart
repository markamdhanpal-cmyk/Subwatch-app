import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';
import 'package:sub_killer/domain/enums/subscription_event_type.dart';

void main() {
  group('Forensic Truth Recovery: Real-Device Trace Playback', () {
    late LocalIngestionFlowUseCase useCase;

    setUp(() {
      useCase = LocalIngestionFlowUseCase();
    });

    test('Forensic 7206: JioHotstar Bundle (Telecom Noise) should NOT be billed',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: '7206',
          sourceAddress: 'JIO',
          body:
              'Recharge now Jio no. 9340533718 with Rs.899 plan & enjoy Jio Offer- Free JioHotstar Mobile/TV subscription for 90 Days. Use PhonePe app & get upto Rs.400 Rewards.Plan 899 benefits: Unlimited 5G data + 2GB/day & 20GB extra 4G data, Unlimited Voice, 90 Days. T&CA.',
          receivedAt: DateTime(2025, 8, 31),
        ),
      ]);

      expect(
        result.events.any((event) => event.type == SubscriptionEventType.subscriptionBilled),
        false,
      );
      expect(
        result.ledgerEntries.any((entry) => entry.state == ResolverState.activePaid),
        false,
      );
    });

    test('Forensic 6949: Adobe "Stop Payment Request" should NOT be billed',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: '6949',
          sourceAddress: 'FEDBNK',
          body:
              'Hi! Request to stop payment of Rs 1416 to ADOBE SYS SOFTWARE IRELAND LTD on your Federal Bank Debit Card 4413 has been received. Manage your mandates at -Federal Bank',
          receivedAt: DateTime(2025, 8, 17),
        ),
      ]);

      expect(
        result.events.any((event) => event.type == SubscriptionEventType.subscriptionBilled),
        false,
        reason: 'Stop payment request is not a successful billing event',
      );
    });

    test('Forensic 6944: Adobe "Scheduled Debit" stays out of paid truth',
        () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: '6944',
          sourceAddress: 'FEDBNK',
          body:
              'Payment to ADOBE SYS SOFTWARE IRELAND LTD for Rs. 1416 is scheduled for debit on 17/8/2025 on Federal Bank Debit Card 4413. Mandate Ref no: FBQ3dQDnZY. To stop, click -Federal Bank',
          receivedAt: DateTime(2025, 8, 17),
        ),
      ]);

      expect(
        result.events.any((event) => event.type == SubscriptionEventType.subscriptionBilled),
        false,
      );
    });

    test('Forensic 6913: Google Play Mandate with Monthly Freq', () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: '6913',
          sourceAddress: 'FEDBNK',
          body:
              'Hi, e-mandate on Federal Bank Debit Card 4413 is active for Merchant: Google Play, Desc: GoogleAIPro2TBGoogleOne, Amt: INR 1950.00, Freq: monthly, Start Dt: 12/08/2025 , End Dt: 31/12/2035, SiHubid: Xz2xm6QNmf, Manage e-mandate: T&CA -Federal Bank',
          receivedAt: DateTime(2025, 8, 12),
        ),
      ]);

      expect(result.events, isNotEmpty);
      expect(
        result.events.any((event) => event.type == SubscriptionEventType.mandateCreated),
        true,
      );
    });

    test('Forensic 7203: UPI Noise should be ignored', () async {
      final result = await useCase.execute(<MessageRecord>[
        MessageRecord(
          id: '7203',
          sourceAddress: 'FEDBNK',
          body:
              'Rs 185.00 sent via UPI on 02-09-2025 at 19:25:02 to AMAR SINGH.Ref:561188881934.Not you? Call 18004251199/SMS BLOCKUPI to 98950 88888 -Federal Bank',
          receivedAt: DateTime(2025, 9, 2),
        ),
      ]);

      expect(
        result.events.any((event) => event.type == SubscriptionEventType.subscriptionBilled),
        false,
      );
    });
  });
}

