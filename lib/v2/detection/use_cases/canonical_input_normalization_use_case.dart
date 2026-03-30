import '../../../domain/knowledge/merchant_knowledge_base.dart';
import '../../../domain/parsing/indian_amount_parser.dart';
import '../contracts/canonical_input_normalizer.dart';
import '../models/canonical_input.dart';
import '../models/normalized_input_record.dart';

class CanonicalInputNormalizationUseCase implements CanonicalInputNormalizer {
  const CanonicalInputNormalizationUseCase();

  static final RegExp _htmlTagPattern = RegExp(r'<[^>]+>');
  static final RegExp _urlPattern = RegExp(r'https?:\/\/\S+|www\.\S+');
  static final RegExp _whitespacePattern = RegExp(r'\s+');
  static final RegExp _wrapperLabelPattern = RegExp(
    r'\b(?:body|message|text|title|subtitle|cta)\s*:\s*',
    caseSensitive: false,
  );
  static final RegExp _currencyAmountPattern = RegExp(
    r'(?:\u20B9\s*|rs\.?\s*|inr\s*|rupees\s*)([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _promoPattern = RegExp(
    r'\b(offer|sale|discount|coupon|cashback|reward|deal|limited time|save\b|off\b|promo)\b',
    caseSensitive: false,
  );
  static final RegExp _callToActionPattern = RegExp(
    r'\b(click|tap|buy now|shop now|claim|redeem|install now|subscribe now)\b',
    caseSensitive: false,
  );

  @override
  NormalizedInputRecord normalize(CanonicalInput input) {
    final sourceQualityMarkers = <NormalizationSourceQualityMarker>{};
    final noiseMarkers = <NormalizationNoiseMarker>{};

    if (_hasContent(input.senderHandle)) {
      sourceQualityMarkers.add(NormalizationSourceQualityMarker.senderKnown);
    }

    if (_hasContent(input.subject)) {
      sourceQualityMarkers.add(NormalizationSourceQualityMarker.subjectPresent);
    }

    if (input.richTextSegments.isNotEmpty) {
      sourceQualityMarkers.add(
        NormalizationSourceQualityMarker.richTextExpanded,
      );
    }

    final extractedTextSegments = <String>[
      if (_hasContent(input.subject)) input.subject!.trim(),
      for (final segment in input.richTextSegments)
        if (_sanitizeSegment(segment).isNotEmpty) _sanitizeSegment(segment),
      if (_sanitizeSegment(input.textBody).isNotEmpty)
        _sanitizeSegment(input.textBody),
    ];

    final rawJoinedText = extractedTextSegments.join(' ');
    final hadWrapperText =
        _htmlTagPattern.hasMatch(rawJoinedText) ||
            _wrapperLabelPattern.hasMatch(rawJoinedText);
    final hadUrls = _urlPattern.hasMatch(rawJoinedText);

    if (hadWrapperText) {
      sourceQualityMarkers.add(
        NormalizationSourceQualityMarker.wrapperTextStripped,
      );
    }

    if (hadUrls) {
      sourceQualityMarkers.add(NormalizationSourceQualityMarker.urlsStripped);
      noiseMarkers.add(NormalizationNoiseMarker.excessiveLinkout);
    }

    var normalizedText = rawJoinedText;
    normalizedText = normalizedText.replaceAll(_htmlTagPattern, ' ');
    normalizedText = normalizedText.replaceAll(_wrapperLabelPattern, ' ');
    normalizedText = normalizedText.replaceAll(_urlPattern, ' ');
    normalizedText = _collapseWhitespace(normalizedText);

    final amountTokens = _extractAmountTokens(normalizedText);
    if (amountTokens.isNotEmpty) {
      sourceQualityMarkers.add(NormalizationSourceQualityMarker.amountDetected);
    }

    final merchantHints = _extractMerchantHints(
      normalizedText,
      senderHandle: input.senderHandle,
    );
    if (merchantHints.isNotEmpty) {
      sourceQualityMarkers.add(
        NormalizationSourceQualityMarker.merchantHintDetected,
      );
    }

    final likelyPromotionalNoise = _promoPattern.hasMatch(normalizedText) ||
        _callToActionPattern.hasMatch(normalizedText);
    if (likelyPromotionalNoise) {
      sourceQualityMarkers.add(
        NormalizationSourceQualityMarker.likelyPromotionalNoise,
      );
    }

    if (_promoPattern.hasMatch(normalizedText)) {
      noiseMarkers.add(NormalizationNoiseMarker.promotionalLanguage);
      noiseMarkers.add(NormalizationNoiseMarker.discountLanguage);
    }

    if (_callToActionPattern.hasMatch(normalizedText)) {
      noiseMarkers.add(NormalizationNoiseMarker.callToAction);
    }

    if (normalizedText.length < 12) {
      sourceQualityMarkers.add(NormalizationSourceQualityMarker.sparseContent);
    }

    final searchText = _collapseWhitespace(
      <String>[
        if (_hasContent(input.senderHandle)) input.senderHandle!.trim(),
        normalizedText,
      ].join(' '),
    ).toLowerCase();

    return NormalizedInputRecord(
      canonicalId: input.id,
      kind: input.kind,
      origin: input.origin,
      receivedAt: input.receivedAt,
      senderHandle: input.senderHandle,
      subject: input.subject,
      threadId: input.threadId,
      rawTextBody: input.textBody,
      normalizedText: normalizedText,
      searchText: searchText,
      extractedTextSegments: extractedTextSegments,
      amountTokens: amountTokens,
      merchantHints: merchantHints,
      sourceQualityMarkers: sourceQualityMarkers.toList(growable: false),
      noiseMarkers: noiseMarkers.toList(growable: false),
      extractionConfidence: _confidenceFor(
        normalizedText,
        hadRichSegments: input.richTextSegments.isNotEmpty,
        hadSenderHandle: _hasContent(input.senderHandle),
      ),
      likelyPromotionalNoise: likelyPromotionalNoise,
    );
  }

  @override
  List<NormalizedInputRecord> normalizeAll(Iterable<CanonicalInput> inputs) {
    return List<NormalizedInputRecord>.unmodifiable(
      inputs.map(normalize),
    );
  }

  List<NormalizedAmountToken> _extractAmountTokens(String input) {
    final matches = _currencyAmountPattern.allMatches(input);
    final tokens = <NormalizedAmountToken>[];

    for (final match in matches) {
      final rawToken = match.group(0);
      final normalizedRawValue = match.group(1);
      if (rawToken == null || normalizedRawValue == null) {
        continue;
      }

      final normalizedValue =
          double.tryParse(normalizedRawValue.replaceAll(',', ''));
      if (normalizedValue == null) {
        continue;
      }

      tokens.add(
        NormalizedAmountToken(
          rawToken: _collapseWhitespace(rawToken),
          normalizedValue: normalizedValue,
        ),
      );
    }

    if (tokens.isNotEmpty) {
      return tokens;
    }

    final fallbackAmount = IndianAmountParser.extract(input);
    if (fallbackAmount == null) {
      return const <NormalizedAmountToken>[];
    }

    return <NormalizedAmountToken>[
      NormalizedAmountToken(
        rawToken: fallbackAmount.toString(),
        normalizedValue: fallbackAmount,
      ),
    ];
  }

  List<String> _extractMerchantHints(
    String normalizedText, {
    required String? senderHandle,
  }) {
    final hints = <String>{
      ...MerchantKnowledgeBase.extractMerchantHints(normalizedText),
    };

    final senderHint = _senderHint(senderHandle);
    if (senderHint != null) {
      hints.add(senderHint);
    }

    return hints.toList(growable: false);
  }

  String? _senderHint(String? senderHandle) {
    if (!_hasContent(senderHandle)) {
      return null;
    }

    final normalizedSender =
        senderHandle!.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (normalizedSender.length < 3) {
      return null;
    }

    const blockedHints = <String>{
      'bank',
      'banksms',
      'txnalerts',
      'alerts',
      'telco',
      'service',
      'sms',
      'vkbank',
      'jxbank',
    };

    if (blockedHints.contains(normalizedSender)) {
      return null;
    }

    return normalizedSender;
  }

  String _sanitizeSegment(String input) {
    return _collapseWhitespace(input.trim());
  }

  String _collapseWhitespace(String input) {
    return input.replaceAll(_whitespacePattern, ' ').trim();
  }

  bool _hasContent(String? input) {
    return input != null && input.trim().isNotEmpty;
  }

  NormalizationExtractionConfidence _confidenceFor(
    String normalizedText, {
    required bool hadRichSegments,
    required bool hadSenderHandle,
  }) {
    if (normalizedText.length >= 24 && hadSenderHandle) {
      return NormalizationExtractionConfidence.high;
    }

    if (normalizedText.length >= 12 || hadRichSegments) {
      return NormalizationExtractionConfidence.medium;
    }

    return NormalizationExtractionConfidence.low;
  }
}
