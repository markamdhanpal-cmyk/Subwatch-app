import 'package:flutter_test/flutter_test.dart';

import 'fixtures/subwatch_v2_golden_dataset.dart';
import 'support/golden_regression_harness.dart';

Future<GoldenRegressionHarness> _createHarness() async {
  return GoldenRegressionHarness(logger: print);
}

void main() {
  const richImportedCategories = <GoldenDatasetCategory>{
    GoldenDatasetCategory.noisyRichBusinessMessage,
    GoldenDatasetCategory.appStoreRenewal,
    GoldenDatasetCategory.emailReceipt,
    GoldenDatasetCategory.csvStatement,
  };
  final summaryProbeCases = <GoldenDatasetCase>[
    goldenRegressionDataset.firstWhere(
      (testCase) =>
          testCase.category == GoldenDatasetCategory.paidSubscription,
    ),
    goldenRegressionDataset.firstWhere(
      (testCase) =>
          testCase.category ==
          GoldenDatasetCategory.noisyRichBusinessMessage,
    ),
    goldenRegressionDataset.firstWhere(
      (testCase) => testCase.category == GoldenDatasetCategory.csvStatement,
    ),
  ];

  group('SubWatch V2 golden dataset regression harness', () {
    test('dataset covers the core hard-case categories', () {
      final categories = goldenRegressionDataset
          .map((testCase) => testCase.category)
          .toSet();

      expect(
        categories,
        containsAll(<GoldenDatasetCategory>[
          GoldenDatasetCategory.paidSubscription,
          GoldenDatasetCategory.bundledIncluded,
          GoldenDatasetCategory.setupOnly,
          GoldenDatasetCategory.verificationOnly,
          GoldenDatasetCategory.oneTimePaymentNoise,
          GoldenDatasetCategory.weakRecurringReview,
          GoldenDatasetCategory.noisyRichBusinessMessage,
        ]),
      );
    });

    test('every golden case stays human-readable and provenance-aware', () {
      for (final testCase in goldenRegressionDataset) {
        expect(testCase.id, isNotEmpty);
        expect(testCase.title, isNotEmpty);
        expect(testCase.protection, isNotEmpty);
        expect(testCase.input.provenance, isNotEmpty);
        expect(testCase.expected.serviceKey, isNotEmpty);

        if (testCase.input.records != null) {
          expect(testCase.input.records, isNotEmpty);
          expect(testCase.input.canonicalInputs, isNull);
        } else {
          expect(testCase.input.canonicalInputs, isNotEmpty);
          expect(testCase.input.records, isNull);
        }
      }
    });

    test(
      'harness evaluateAll returns readable comparisons on a representative probe set',
      () async {
        final GoldenRegressionHarness harness = await _createHarness();
        final GoldenRegressionHarnessResult result =
            await harness.evaluateAll(summaryProbeCases);
        final List<GoldenCaseComparison> comparisons = result.comparisons;
        var categoryCaseCount = 0;
        for (final int count in result.summary.byCategory.values) {
          categoryCaseCount += count;
        }

        expect(result.summary.totalCases, summaryProbeCases.length);
        expect(
          categoryCaseCount,
          summaryProbeCases.length,
        );
        expect(result.summary.toReadableString(), isNotEmpty);
        expect(
          comparisons.every(
            (GoldenCaseComparison comparison) =>
                comparison.toReadableString().isNotEmpty,
          ),
          isTrue,
        );
        expect(
          comparisons.every(
            (GoldenCaseComparison comparison) => comparison.v2MatchesExpected,
          ),
          isTrue,
          reason:
              'The bridge-to-ledger V2 path should stay aligned with the golden truth set before rollout.',
        );
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );

    for (final testCase in goldenRegressionDataset) {
      test(
        'case ${testCase.id} returns measurable outcomes',
        () async {
          final GoldenRegressionHarness harness = await _createHarness();
          final GoldenCaseComparison comparison =
              await harness.evaluateCase(testCase);

          expect(comparison.v1.toReadableString(), isNotEmpty);
          expect(comparison.v2.toReadableString(), isNotEmpty);
          expect(comparison.v2MatchesExpected, isTrue);
          if (richImportedCategories.contains(testCase.category)) {
            expect(
              comparison.v2.toReadableString(),
              contains(testCase.expected.serviceKey),
            );
          }
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );
    }
  });
}
