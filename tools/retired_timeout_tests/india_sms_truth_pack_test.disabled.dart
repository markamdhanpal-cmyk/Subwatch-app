import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';

void main() {
  group('India SMS Truth Pack', () {
    final fixtureFile =
        File('test/fixtures/sms_cases/india_sms_truth_pack.json');
    final rawCases =
        jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;

    for (final rawCase in rawCases) {
      final caseData = rawCase as Map<String, dynamic>;
      final id = caseData['id'] as String;
      final messagesJson = caseData['messages'] as List<dynamic>;
      final expectedState = caseData['expectedState'] as String;
      final expectedServiceKey = caseData['expectedServiceKey'] as String?;

      test(id, () async {
        final useCase = LocalIngestionFlowUseCase();
        final receivedAt = DateTime(2026, 4, 1, 10, 0);
        final messages = <MessageRecord>[
          for (var index = 0; index < messagesJson.length; index += 1)
            MessageRecord(
              id: '$id-$index',
              sourceAddress:
                  (messagesJson[index] as Map<String, dynamic>)['sender']
                      as String,
              body: (messagesJson[index] as Map<String, dynamic>)['body']
                  as String,
              receivedAt: receivedAt.add(Duration(minutes: index)),
            ),
        ];

        final result = await useCase.execute(messages);

        if (expectedState == 'none') {
          expect(result.ledgerEntries, isEmpty);
          return;
        }

        expect(expectedServiceKey, isNotNull);
        final entry = result.ledgerEntries.firstWhere(
          (candidate) => candidate.serviceKey.value == expectedServiceKey,
          orElse: () => throw StateError(
            'Expected ledger entry for $expectedServiceKey in case $id',
          ),
        );

        final expectedResolverState = ResolverState.values.firstWhere(
          (value) => value.name == expectedState,
        );
        expect(entry.state, expectedResolverState);
      });
    }
  });
}
