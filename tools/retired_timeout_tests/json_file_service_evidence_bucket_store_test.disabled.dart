import 'dart:io';

import 'support/test_temp_dir.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/stores/json_file_service_evidence_bucket_store.dart';
import 'package:sub_killer/domain/entities/evidence_trail.dart';
import 'package:sub_killer/domain/entities/service_evidence_bucket.dart';
import 'package:sub_killer/domain/enums/service_evidence_source_kind.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('JsonFileServiceEvidenceBucketStore', () {
    late Directory tempDirectory;
    late JsonFileServiceEvidenceBucketStore store;

    setUp(() async {
      tempDirectory = await createWorkspaceTempDirectory('sub-killer-evidence-bucket-store');
      store = JsonFileServiceEvidenceBucketStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves and loads service evidence buckets deterministically', () async {
      await store.save(<ServiceEvidenceBucket>[
        ServiceEvidenceBucket(
          serviceKey: const ServiceKey('YOUTUBE_PREMIUM'),
          firstSeenAt: DateTime(2026, 3, 1, 9, 0),
          lastSeenAt: DateTime(2026, 4, 1, 9, 0),
          lastBilledAt: DateTime(2026, 4, 1, 9, 0),
          sourceKindsSeen: const <ServiceEvidenceSourceKind>[
            ServiceEvidenceSourceKind.deviceSmsInbox,
          ],
          billedCount: 2,
          renewalHintCount: 2,
          amountSeries: const <double>[149, 149],
          intervalHintsInDays: const <int>[31],
          contradictions: const <String>['paid_after_setup'],
          evidenceTrail: EvidenceTrail(
            messageIds: const <String>['yt-1'],
            eventIds: const <String>['yt-event-1'],
            notes: const <String>['fragment:billed_success'],
          ),
        ),
        ServiceEvidenceBucket(
          serviceKey: const ServiceKey('NETFLIX'),
          firstSeenAt: DateTime(2026, 3, 5, 9, 0),
          lastSeenAt: DateTime(2026, 3, 5, 9, 0),
          sourceKindsSeen: const <ServiceEvidenceSourceKind>[
            ServiceEvidenceSourceKind.deviceSmsInbox,
          ],
          billedCount: 1,
          amountSeries: const <double>[499],
          evidenceTrail: EvidenceTrail(
            messageIds: const <String>['nf-1'],
            eventIds: const <String>['nf-event-1'],
            notes: const <String>['fragment:billed_success'],
          ),
        ),
      ]);

      final restored = await store.load();

      expect(restored, hasLength(2));
      expect(
        restored.map((bucket) => bucket.serviceKey.value),
        <String>['NETFLIX', 'YOUTUBE_PREMIUM'],
      );
      expect(restored.last.intervalHintsInDays, <int>[31]);
      expect(restored.last.contradictions, <String>['paid_after_setup']);
    });
    test('demotes legacy low-confidence extracted-candidate bucket keys on load',
        () async {
      await store.save(<ServiceEvidenceBucket>[
        ServiceEvidenceBucket(
          serviceKey: const ServiceKey('MODI'),
          firstSeenAt: DateTime(2026, 3, 6, 9, 0),
          lastSeenAt: DateTime(2026, 3, 6, 9, 0),
          sourceKindsSeen: const <ServiceEvidenceSourceKind>[
            ServiceEvidenceSourceKind.deviceSmsInbox,
          ],
          mandateCount: 1,
          amountSeries: const <double>[2868],
          evidenceTrail: EvidenceTrail(
            notes: const <String>[
              'merchant_resolution:extractedCandidate:low:modi',
            ],
          ),
        ),
      ]);

      final restored = await store.load();

      expect(restored, hasLength(1));
      expect(restored.single.serviceKey.value, 'UNRESOLVED');
    });

    test('returns empty list when the persisted file is malformed', () async {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileServiceEvidenceBucketStore.defaultFileName}',
      );
      await file.writeAsString('{not-json}', flush: true);

      expect(await store.load(), isEmpty);
    });
  });
}

