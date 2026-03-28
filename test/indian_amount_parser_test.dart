import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/parsing/indian_amount_parser.dart';

void main() {
  group('IndianAmountParser', () {
    test('parses supported Indian SMS money formats', () {
      expect(IndianAmountParser.extract('Paid \u20B9499 for service.'), 499);
      expect(
        IndianAmountParser.extract('Amount billed: \u20B9 499 today.'),
        499,
      );
      expect(IndianAmountParser.extract('Rs 299 debited.'), 299);
      expect(IndianAmountParser.extract('Rs. 499 charged.'), 499);
      expect(IndianAmountParser.extract('INR 499 processed.'), 499);
      expect(IndianAmountParser.extract('Rupees 99 paid.'), 99);
    });

    test('returns null when no supported amount marker is present', () {
      expect(IndianAmountParser.extract('Amount 299 debited.'), isNull);
    });
  });
}
