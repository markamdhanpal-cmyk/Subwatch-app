import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';

void main() {
  group('Truth Pack Detector Hardening', () {
    final receivedAt = DateTime(2026, 4, 1, 10, 0);

    MessageRecord message({
      required String id,
      required String sender,
      required String body,
    }) {
      return MessageRecord(
        id: id,
        sourceAddress: sender,
        body: body,
        receivedAt: receivedAt,
      );
    }

    Future<List<ServiceLedgerEntry>> ingestSingle(MessageRecord record) async {
      final flow = LocalIngestionFlowUseCase();
      final result = await flow.execute(<MessageRecord>[record]);
      return result.ledgerEntries;
    }

    test('Jio recharge with JioSaavn included benefit stays bundled', () async {
      final entries = await ingestSingle(
        message(
          id: 'jio-saavn-bundle',
          sender: 'AD-JIOINF-S',
          body:
              'Your Jio recharge of Rs 299 includes complimentary JioSaavn Pro subscription benefit for 28 days.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.serviceKey.value, 'JIOSAAVN_PRO');
      expect(entries.single.state, ResolverState.activeBundled);
    });

    test('Airtel bundled benefit stays separate from paid subscriptions',
        () async {
      final entries = await ingestSingle(
        message(
          id: 'airtel-gemini-bundle',
          sender: 'AD-AIRTEL-S',
          body:
              'Your recent Airtel recharge has unlocked a FREE 6-month Google Gemini Pro plan as an included benefit.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.serviceKey.value, 'GOOGLE_GEMINI_PRO');
      expect(entries.single.state, ResolverState.activeBundled);
    });

    test('Google or YouTube mandate-only message stays setup-only', () async {
      final entries = await ingestSingle(
        message(
          id: 'yt-mandate',
          sender: 'VK-FEDBNK-S',
          body:
              'e-mandate on card is active for Merchant: Google Play, Desc: YouTube Premium, Amt: INR 129.00, Freq: monthly.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.state, ResolverState.pendingConversion);
      expect(entries.single.state, isNot(ResolverState.activePaid));
    });

    test('Rs 2 verification-only message stays verification only', () async {
      final entries = await ingestSingle(
        message(
          id: 'micro-verify',
          sender: 'VK-BANK-S',
          body:
              'Your mandate for Crunchyroll was successfully executed for Rs 2.00 for verification.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.state, ResolverState.verificationOnly);
      expect(entries.single.state, isNot(ResolverState.activePaid));
    });

    test('direct monthly paid subscription is confirmed paid', () async {
      final entries = await ingestSingle(
        message(
          id: 'monthly-paid',
          sender: 'VK-NETFLX-S',
          body:
              'Your Netflix subscription has been renewed for Rs 499 successfully.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.serviceKey.value, 'NETFLIX');
      expect(entries.single.state, ResolverState.activePaid);
    });

    test('annual paid subscription is confirmed paid', () async {
      final entries = await ingestSingle(
        message(
          id: 'annual-paid',
          sender: 'VM-AMZN-S',
          body:
              'Amazon Prime annual subscription renewed successfully for Rs 1499.',
        ),
      );

      expect(entries, hasLength(1));
      expect(entries.single.serviceKey.value, 'AMAZON_PRIME');
      expect(entries.single.state, ResolverState.activePaid);
    });

    test('OTP message is filtered as noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'otp-noise',
          sender: 'VK-BANK-S',
          body: 'Your OTP is 483922. Do not share this code with anyone.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('telecom data usage message is filtered as noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'data-noise',
          sender: 'AD-AIRTEL-S',
          body:
              'Airtel alert: 90% of your daily data quota has been used. Recharge now.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('promo junk is filtered as noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'promo-noise',
          sender: 'VK-OFFER-S',
          body:
              'Mega sale today. Get cashback and rewards. Shop now to unlock deal.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('RCS or bot junk is filtered as noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'rcs-noise',
          sender: 'VK-CHAT-S',
          body:
              'Verified business chatbot message. Tap to reply and choose a button below.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('one-time UPI merchant payment stays hidden noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'upi-onetime',
          sender: 'VK-BANK-S',
          body: 'Rs 185.00 sent via UPI to AMAR SINGH. Ref 561188881934.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('loan or due reminder stays filtered as non-subscription', () async {
      final entries = await ingestSingle(
        message(
          id: 'loan-reminder',
          sender: 'VK-LENDER-S',
          body:
              'Your EMI due amount is pending. Pay your loan installment by tomorrow.',
        ),
      );

      expect(entries, isEmpty);
    });

    test('mixed Hindi or Hinglish telecom wording is filtered as noise',
        () async {
      final entries = await ingestSingle(
        message(
          id: 'hinglish-telecom',
          sender: 'AD-JIOINF-S',
          body:
              'Aapka daily data quota almost khatam hai. Recharge karke validity continue karein. Free benefit available.',
        ),
      );

      expect(entries, isEmpty);
    });
    test('missed call alerts are filtered as hard noise', () async {
      final entries = await ingestSingle(
        message(
          id: 'missed-call',
          sender: 'VK-ALERT-S',
          body: 'You missed a call from +91-9876543210. Call me back.',
        ),
      );

      expect(entries, isEmpty);
    });
  });
}


