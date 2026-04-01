class IndianAmountParser {
  const IndianAmountParser._();

  static final RegExp _currencyAmountPattern = RegExp(
    r'(?:rs\.?|inr|₹|₨|rupees|amount|amt\.?|total|for|renewed|billed|debited|kati|bhugtan|shulk|processed|at)\s*[:\-\s]*\s*(?:rs\.?|inr|₹|₨)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)(?:\s*/-)?',
    caseSensitive: false,
  );

  static double? extract(String input) {
    if (input.isEmpty) return null;
    final matches = _currencyAmountPattern.allMatches(input);
    if (matches.isEmpty) {
      return null;
    }

    for (final match in matches) {
      final rawValue = match.group(1);
      if (rawValue == null) continue;
      
      final parsed = double.tryParse(rawValue.replaceAll(',', ''));
      if (parsed != null && parsed > 5) {
        return parsed;
      }
    }

    return null;
  }
}
