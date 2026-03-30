import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/v2/detection/models/canonical_input.dart';
import 'package:sub_killer/v2/detection/models/normalized_input_record.dart';
import 'package:sub_killer/v2/detection/use_cases/canonical_input_normalization_use_case.dart';

void main() {
  group('CanonicalInputNormalizationUseCase', () {
    const useCase = CanonicalInputNormalizationUseCase();

    test('normalizes plain sms into stable text, amount tokens, and hints', () {
      final normalized = useCase.normalize(
        CanonicalInput.deviceSms(
          id: 'sms-1',
          senderHandle: 'BANK',
          textBody: 'Your Netflix subscription has been renewed for Rs 499.',
          receivedAt: DateTime(2026, 3, 12, 13, 0),
        ),
      );

      expect(
        normalized.normalizedText,
        'Your Netflix subscription has been renewed for Rs 499.',
      );
      expect(normalized.amountTokens, hasLength(1));
      expect(normalized.amountTokens.single.normalizedValue, 499);
      expect(normalized.merchantHints, contains('netflix'));
      expect(
        normalized.sourceQualityMarkers,
        contains(NormalizationSourceQualityMarker.amountDetected),
      );
      expect(
        normalized.extractionConfidence,
        NormalizationExtractionConfidence.high,
      );
      expect(normalized.likelyPromotionalNoise, isFalse);
    });

    test('expands richer wrapped content and marks quality/noise markers', () {
      final normalized = useCase.normalize(
        CanonicalInput(
          id: 'rcs-1',
          kind: CanonicalInputKind.rcs,
          origin: const CanonicalInputOrigin(
            kind: CanonicalInputOriginKind.deviceRcsInbox,
            sourceLabel: 'device_rcs_inbox',
            localOnly: true,
          ),
          receivedAt: DateTime(2026, 3, 20, 10, 45),
          senderHandle: 'VK-NETFLX',
          subject: 'Renewal reminder',
          textBody:
              '<div>Body: Renew now and save 20%! Visit https://example.com</div>',
          richTextSegments: <String>[
            'Netflix Premium monthly plan billed successfully for Rs 649',
          ],
        ),
      );

      expect(normalized.normalizedText, isNot(contains('<div>')));
      expect(normalized.normalizedText, isNot(contains('https://')));
      expect(normalized.normalizedText, contains('Netflix Premium monthly plan'));
      expect(normalized.amountTokens, hasLength(1));
      expect(normalized.amountTokens.single.normalizedValue, 649);
      expect(normalized.merchantHints, contains('netflix'));
      expect(
        normalized.sourceQualityMarkers,
        contains(NormalizationSourceQualityMarker.richTextExpanded),
      );
      expect(
        normalized.sourceQualityMarkers,
        contains(NormalizationSourceQualityMarker.wrapperTextStripped),
      );
      expect(
        normalized.sourceQualityMarkers,
        contains(NormalizationSourceQualityMarker.urlsStripped),
      );
      expect(normalized.likelyPromotionalNoise, isTrue);
      expect(
        normalized.noiseMarkers,
        contains(NormalizationNoiseMarker.promotionalLanguage),
      );
    });
  });
}

