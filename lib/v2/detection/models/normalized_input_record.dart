import 'canonical_input.dart';

enum NormalizationExtractionConfidence {
  high,
  medium,
  low,
}

enum NormalizationSourceQualityMarker {
  senderKnown,
  subjectPresent,
  richTextExpanded,
  wrapperTextStripped,
  urlsStripped,
  amountDetected,
  merchantHintDetected,
  likelyPromotionalNoise,
  sparseContent,
}

enum NormalizationNoiseMarker {
  promotionalLanguage,
  callToAction,
  discountLanguage,
  excessiveLinkout,
}

class NormalizedAmountToken {
  const NormalizedAmountToken({
    required this.rawToken,
    required this.normalizedValue,
    this.currencyCode = 'INR',
  });

  final String rawToken;
  final double normalizedValue;
  final String currencyCode;
}

class NormalizedInputRecord {
  NormalizedInputRecord({
    required this.canonicalId,
    required this.kind,
    required this.origin,
    required this.receivedAt,
    required this.rawTextBody,
    required this.normalizedText,
    required this.searchText,
    required List<String> extractedTextSegments,
    required List<NormalizedAmountToken> amountTokens,
    required List<String> merchantHints,
    required List<NormalizationSourceQualityMarker> sourceQualityMarkers,
    required List<NormalizationNoiseMarker> noiseMarkers,
    required this.extractionConfidence,
    required this.likelyPromotionalNoise,
    this.senderHandle,
    this.subject,
    this.threadId,
  })  : extractedTextSegments = List<String>.unmodifiable(extractedTextSegments),
        amountTokens = List<NormalizedAmountToken>.unmodifiable(amountTokens),
        merchantHints = List<String>.unmodifiable(merchantHints),
        sourceQualityMarkers =
            List<NormalizationSourceQualityMarker>.unmodifiable(
          sourceQualityMarkers,
        ),
        noiseMarkers = List<NormalizationNoiseMarker>.unmodifiable(
          noiseMarkers,
        );

  final String canonicalId;
  final CanonicalInputKind kind;
  final CanonicalInputOrigin origin;
  final DateTime receivedAt;
  final String rawTextBody;
  final String normalizedText;
  final String searchText;
  final List<String> extractedTextSegments;
  final List<NormalizedAmountToken> amountTokens;
  final List<String> merchantHints;
  final List<NormalizationSourceQualityMarker> sourceQualityMarkers;
  final List<NormalizationNoiseMarker> noiseMarkers;
  final NormalizationExtractionConfidence extractionConfidence;
  final bool likelyPromotionalNoise;
  final String? senderHandle;
  final String? subject;
  final String? threadId;
}
