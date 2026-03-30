import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/service_ledger_entry.dart';
import 'package:sub_killer/domain/entities/subscription_event.dart';
import 'package:sub_killer/v2/decision/enums/decision_execution_mode.dart';

import '../fixtures/subwatch_v2_golden_dataset.dart';

enum GoldenHarnessPath {
  v1Shadow,
  v2Bridge,
}

class GoldenObservedOutcome {
  const GoldenObservedOutcome({
    required this.path,
    required this.eventCount,
    required this.ledgerEntryCount,
    required this.serviceKey,
    required this.eventTypeName,
    required this.resolverStateName,
    required this.totalBilled,
  });

  final GoldenHarnessPath path;
  final int eventCount;
  final int ledgerEntryCount;
  final String serviceKey;
  final String eventTypeName;
  final String resolverStateName;
  final double totalBilled;

  String toReadableString() {
    return '${path.name}: service=$serviceKey, '
        'event=$eventTypeName, '
        'state=$resolverStateName, '
        'billed=${totalBilled.toStringAsFixed(totalBilled == totalBilled.roundToDouble() ? 0 : 2)}, '
        'events=$eventCount, ledger=$ledgerEntryCount';
  }
}

class GoldenCaseComparison {
  const GoldenCaseComparison({
    required this.testCase,
    required this.v1,
    required this.v2,
    required this.v1MatchesExpected,
    required this.v2MatchesExpected,
  });

  final GoldenDatasetCase testCase;
  final GoldenObservedOutcome v1;
  final GoldenObservedOutcome v2;
  final bool v1MatchesExpected;
  final bool v2MatchesExpected;

  String toReadableString() {
    return '${testCase.id} | expected=${testCase.expected.label.name}/'
        '${testCase.expected.serviceKey}/${testCase.expected.resolverState.name} | '
        '${v1.toReadableString()} | match=${v1MatchesExpected ? 'yes' : 'no'} | '
        '${v2.toReadableString()} | match=${v2MatchesExpected ? 'yes' : 'no'}';
  }
}

class GoldenHarnessSummary {
  const GoldenHarnessSummary({
    required this.totalCases,
    required this.v1MatchesExpectedCount,
    required this.v2MatchesExpectedCount,
    required this.v1V2DifferCount,
    required this.byCategory,
  });

  final int totalCases;
  final int v1MatchesExpectedCount;
  final int v2MatchesExpectedCount;
  final int v1V2DifferCount;
  final Map<GoldenDatasetCategory, int> byCategory;

  String toReadableString() {
    final categorySummary = byCategory.entries
        .map((entry) => '${entry.key.name}:${entry.value}')
        .join(', ');
    return 'cases=$totalCases; '
        'v1_matches=$v1MatchesExpectedCount; '
        'v2_matches=$v2MatchesExpectedCount; '
        'v1_v2_differ=$v1V2DifferCount; '
        'categories=[$categorySummary]';
  }
}

class GoldenRegressionHarnessResult {
  const GoldenRegressionHarnessResult({
    required this.comparisons,
    required this.summary,
  });

  final List<GoldenCaseComparison> comparisons;
  final GoldenHarnessSummary summary;
}

class GoldenRegressionHarness {
  GoldenRegressionHarness({
    void Function(String message)? logger,
  }) : _logger = logger;

  final void Function(String message)? _logger;

  Future<GoldenRegressionHarnessResult> evaluateAll(
    Iterable<GoldenDatasetCase> dataset,
  ) async {
    final comparisons = <GoldenCaseComparison>[];
    var completed = 0;
    for (final testCase in dataset) {
      _log('evaluateAll:start:${testCase.id}');
      comparisons.add(await evaluateCase(testCase));
      completed += 1;
      _log('evaluateAll:end:${testCase.id};completed=$completed');
    }

    final byCategory = <GoldenDatasetCategory, int>{};
    for (final comparison in comparisons) {
      byCategory.update(
        comparison.testCase.category,
        (current) => current + 1,
        ifAbsent: () => 1,
      );
    }

    final summary = GoldenHarnessSummary(
      totalCases: comparisons.length,
      v1MatchesExpectedCount:
          comparisons.where((comparison) => comparison.v1MatchesExpected).length,
      v2MatchesExpectedCount:
          comparisons.where((comparison) => comparison.v2MatchesExpected).length,
      v1V2DifferCount: comparisons
          .where(
            (comparison) => comparison.v1.serviceKey != comparison.v2.serviceKey ||
                comparison.v1.eventTypeName != comparison.v2.eventTypeName ||
                comparison.v1.resolverStateName !=
                    comparison.v2.resolverStateName ||
                comparison.v1.totalBilled != comparison.v2.totalBilled,
          )
          .length,
      byCategory: Map<GoldenDatasetCategory, int>.unmodifiable(byCategory),
    );

    _log('evaluateAll:summary:${summary.toReadableString()}');

    return GoldenRegressionHarnessResult(
      comparisons: List<GoldenCaseComparison>.unmodifiable(comparisons),
      summary: summary,
    );
  }

  Future<GoldenCaseComparison> evaluateCase(GoldenDatasetCase testCase) async {
    _log('case:start:${testCase.id};category=${testCase.category.name}');
    final v1 = await _runCase(
      testCase,
      path: GoldenHarnessPath.v1Shadow,
      decisionExecutionMode: DecisionExecutionMode.shadowOnly,
    );
    final v2 = await _runCase(
      testCase,
      path: GoldenHarnessPath.v2Bridge,
      decisionExecutionMode: DecisionExecutionMode.bridgeToLedger,
    );

    final comparison = GoldenCaseComparison(
      testCase: testCase,
      v1: v1,
      v2: v2,
      v1MatchesExpected: _matchesExpected(v1, testCase.expected),
      v2MatchesExpected: _matchesExpected(v2, testCase.expected),
    );

    _log(
      'case:end:${testCase.id};'
      'v1=${comparison.v1MatchesExpected};'
      'v2=${comparison.v2MatchesExpected};'
      'service=${comparison.v2.serviceKey}',
    );

    return comparison;
  }

  Future<GoldenObservedOutcome> _runCase(
    GoldenDatasetCase testCase, {
    required GoldenHarnessPath path,
    required DecisionExecutionMode decisionExecutionMode,
  }) async {
    _log('path:start:${testCase.id};path=${path.name}');
    final useCase = LocalIngestionFlowUseCase(
      decisionExecutionMode: decisionExecutionMode,
    );

    final ({List<SubscriptionEvent> events, List<ServiceLedgerEntry> ledgerEntries})
        result;
    if (testCase.input.records != null) {
      result = await useCase.execute(testCase.input.records!);
    } else {
      result = await useCase.executeCanonicalInputs(
        testCase.input.canonicalInputs!,
      );
    }

    final event = _primaryEvent(result.events, testCase.expected.serviceKey);
    final ledgerEntry =
        _primaryLedgerEntry(result.ledgerEntries, testCase.expected.serviceKey);

    final outcome = GoldenObservedOutcome(
      path: path,
      eventCount: result.events.length,
      ledgerEntryCount: result.ledgerEntries.length,
      serviceKey: ledgerEntry?.serviceKey.value ??
          event?.serviceKey.value ??
          'UNRESOLVED',
      eventTypeName: event?.type.name ?? 'none',
      resolverStateName: ledgerEntry?.state.name ?? 'none',
      totalBilled: ledgerEntry?.totalBilled ?? 0,
    );

    _log(
      'path:end:${testCase.id};path=${path.name};'
      'service=${outcome.serviceKey};'
      'event=${outcome.eventTypeName};'
      'state=${outcome.resolverStateName};'
      'ledger=${outcome.ledgerEntryCount}',
    );

    return outcome;
  }

  SubscriptionEvent? _primaryEvent(
    List<SubscriptionEvent> events,
    String expectedServiceKey,
  ) {
    for (final event in events) {
      if (event.serviceKey.value == expectedServiceKey) {
        return event;
      }
    }
    return events.isEmpty ? null : events.first;
  }

  ServiceLedgerEntry? _primaryLedgerEntry(
    List<ServiceLedgerEntry> entries,
    String expectedServiceKey,
  ) {
    for (final entry in entries) {
      if (entry.serviceKey.value == expectedServiceKey) {
        return entry;
      }
    }
    return entries.isEmpty ? null : entries.first;
  }

  bool _matchesExpected(
    GoldenObservedOutcome outcome,
    GoldenTruthExpectation expected,
  ) {
    return outcome.serviceKey == expected.serviceKey &&
        outcome.eventTypeName == expected.eventType.name &&
        outcome.resolverStateName == expected.resolverState.name &&
        outcome.ledgerEntryCount == expected.ledgerEntryCount &&
        outcome.totalBilled == expected.totalBilled;
  }

  void _log(String message) {
    _logger?.call(message);
  }
}
