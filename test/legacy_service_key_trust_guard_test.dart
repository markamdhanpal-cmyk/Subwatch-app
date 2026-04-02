import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/services/legacy_service_key_trust_guard.dart';

void main() {
  group('LegacyServiceKeyTrustGuard', () {
    test('demotes low-confidence legacy extracted candidates to unresolved',
        () {
      final sanitized = LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: 'MODI',
        evidenceNotes: const <String>[
          'Recurring mandate authorization intent detected.',
          'merchant_resolution:extractedCandidate:low:modi',
        ],
      );

      expect(sanitized, LegacyServiceKeyTrustGuard.unresolvedServiceKey);
    });

    test('keeps known knowledge-base service keys untouched', () {
      final sanitized = LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: 'NETFLIX',
        evidenceNotes: const <String>[
          'merchant_resolution:exactAlias:high:netflix',
        ],
      );

      expect(sanitized, 'NETFLIX');
    });

    test('keeps provider fallback bundle keys untouched', () {
      final sanitized = LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: 'JIO_BUNDLE',
        evidenceNotes: const <String>[
          'merchant_resolution:providerBundleFallback:medium:jio bundle',
        ],
      );

      expect(sanitized, 'JIO_BUNDLE');
    });

    test('does not demote unknown keys without legacy low-candidate note', () {
      final sanitized = LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
        serviceKey: 'UNKNOWN_SERVICE',
        evidenceNotes: const <String>[
          'merchant_resolution:noMatch:none:none',
        ],
      );

      expect(sanitized, 'UNKNOWN_SERVICE');
    });

    test('demotes noisy low-candidate keys seen in device artifacts', () {
      const artifactKeys = <String>[
        'CLICK_IF_YOU_DO_NOT_HAVE_ANY_OTHER_DATA',
        'SIRF_RS499_SE_SHURU_HONE_WALE',
        'TRUE_5G_UNLIMITED',
        'QUARTERLY',
        'YOUTUBE_BEEN',
        'MODI',
        'RAZORPAY',
      ];

      for (final serviceKey in artifactKeys) {
        final sanitized =
            LegacyServiceKeyTrustGuard.sanitizePersistedServiceKey(
          serviceKey: serviceKey,
          evidenceNotes: const <String>[
            'merchant_resolution:extractedCandidate:low:artifact',
          ],
        );

        expect(
          sanitized,
          LegacyServiceKeyTrustGuard.unresolvedServiceKey,
          reason: 'Expected noisy key  to be demoted',
        );
      }
    });
  });
}
