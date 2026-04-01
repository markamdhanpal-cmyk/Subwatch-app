import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/subscription_billed_classifier.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/parsing/indian_amount_parser.dart';

void main() {
  group('Indian Multilingual & Amount Hardening Tests', () {
    const classifier = SubscriptionBilledClassifier();

    test('Harden Amount Parsing: Unicode & Stylized Symbols', () {
      expect(IndianAmountParser.extract('Amount: ₹299.00'), 299.0);
      expect(IndianAmountParser.extract('Paid Rs. 499/-'), 499.0);
      expect(IndianAmountParser.extract('Total: INR 1290'), 1290.0);
      expect(IndianAmountParser.extract('Amt: 149'), 149.0);
      expect(IndianAmountParser.extract('Total Amount: 999'), 999.0);
      
      // Unicode variants
      expect(IndianAmountParser.extract('Rs \u20A8 500'), 500.0); // Rupee sign
    });

    test('Hindi/Hinglish Billing Detection: kati hai', () {
      final message = MessageRecord(
        id: 'msg1',
        sourceAddress: 'AD-NETFLX',
        body: 'Apke account se Rs. 149 monthly subscription ke liye kati hai. Safal bhugtan.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      expect(signal, isNotNull);
      expect(signal!.amount, 149.0);
      expect(signal.capturedTerms, contains('kati hai'));
      expect(signal.capturedTerms, contains('bhugtan'));
    });

    test('Hindi/Hinglish Success Detection: Ho gaya', () {
      final message = MessageRecord(
        id: 'msg2',
        sourceAddress: 'VK-SONYLV',
        body: 'SonyLIV Premium renewal ho gaya hai. Amt: 299/- deducted.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      expect(signal, isNotNull);
      expect(signal!.amount, 299.0);
      expect(signal.capturedTerms, contains('ho gaya'));
    });

    test('Telecom Safety: Recharge with Benefit (False Positive Veto)', () {
      final message = MessageRecord(
        id: 'msg3',
        sourceAddress: 'AD-JIOHTT',
        body: 'Recharge of Rs. 719 successful. Validity: 84 days. Enjoy Disney+ Hotstar Mobile benefit.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      // Should be null because "Recharge" and "Validity" language triggers the telecom bundle veto.
      expect(signal, isNull);
    });

    test('Telecom Safety: Expiry Warning (False Positive Veto)', () {
      final message = MessageRecord(
        id: 'msg4',
        sourceAddress: 'AIRTEL',
        body: 'Your Amazon Prime plan valid till 20-Apr expires on that day. Renew your Airtel pack.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      expect(signal, isNull);
    });

    test('Telecom Safety: Direct Billed via Telecom (True Positive)', () {
      final message = MessageRecord(
        id: 'msg5',
        sourceAddress: 'V-JIOHTT',
        body: 'Monthly renewal of JioHotstar for Rs. 149 successful. Charged to your mobile bill.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      // Should NOT be null because there is no "Recharge" or "Validity" noise, just charging language.
      expect(signal, isNotNull);
      expect(signal!.amount, 149.0);
    });

    test('Bank Style Amount Parsing', () {
      final message = MessageRecord(
        id: 'msg6',
        sourceAddress: 'HDFCBK',
        body: 'Alert: Amt: 199.00 debited for Google One subscription.',
        receivedAt: DateTime.now(),
      );

      final signal = classifier.classify(message);
      expect(signal, isNotNull);
      expect(signal!.amount, 199.0);
    });
  });
}
