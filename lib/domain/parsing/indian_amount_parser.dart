class IndianAmountParser {
  const IndianAmountParser._();

  static final RegExp _currencyAmountPattern = RegExp(
    '(?:\\u20B9\\s*|rs\\.?\\s*|inr\\s*|rupees\\s*)([0-9][0-9,]*(?:\\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static double? extract(String input) {
    final match = _currencyAmountPattern.firstMatch(input);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }
}
