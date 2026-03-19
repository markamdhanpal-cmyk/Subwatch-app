import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/models/review_item_action_models.dart';
import 'package:sub_killer/application/stores/json_file_review_action_store.dart';

void main() {
  group('JsonFileReviewActionStore', () {
    late Directory tempDirectory;
    late JsonFileReviewActionStore store;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'sub-killer-review-actions-',
      );
      store = JsonFileReviewActionStore.applicationSupport(
        directoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('returns no actions when the file does not exist', () async {
      expect(await store.list(), isEmpty);
    });

    test('saves and loads review decisions deterministically', () async {
      await store.save(
        ReviewItemDecision(
          targetKey: 'YOUTUBE_PREMIUM',
          serviceKey: 'YOUTUBE_PREMIUM',
          title: 'YouTube Premium',
          action: ReviewItemAction.confirmSubscription,
          decidedAt: DateTime(2026, 3, 13, 10, 0),
        ),
      );
      await store.save(
        ReviewItemDecision(
          targetKey: 'CRUNCHYROLL',
          serviceKey: 'CRUNCHYROLL',
          title: 'Crunchyroll',
          action: ReviewItemAction.markAsBenefit,
          decidedAt: DateTime(2026, 3, 13, 10, 3),
        ),
      );
      await store.save(
        ReviewItemDecision(
          targetKey: 'SPOTIFY',
          serviceKey: 'SPOTIFY',
          title: 'Spotify',
          action: ReviewItemAction.dismissNotSubscription,
          decidedAt: DateTime(2026, 3, 13, 10, 5),
        ),
      );

      final decisions = await store.list();

      expect(decisions, hasLength(3));
      expect(decisions.map((item) => item.targetKey), <String>[
        'CRUNCHYROLL',
        'SPOTIFY',
        'YOUTUBE_PREMIUM',
      ]);
      expect(decisions.first.action, ReviewItemAction.markAsBenefit);
      expect(decisions[1].action, ReviewItemAction.dismissNotSubscription);
      expect(decisions.last.action, ReviewItemAction.confirmSubscription);
    });

    test('malformed stored data is handled safely', () async {
      final file = File(
        '${tempDirectory.path}${Platform.pathSeparator}${JsonFileReviewActionStore.defaultFileName}',
      );
      await file.writeAsString('{broken}', flush: true);

      expect(await store.list(), isEmpty);
    });

    test('removes a stored review decision safely', () async {
      await store.save(
        ReviewItemDecision(
          targetKey: 'JIOHOTSTAR',
          serviceKey: 'JIOHOTSTAR',
          title: 'Jiohotstar',
          action: ReviewItemAction.confirmSubscription,
          decidedAt: DateTime(2026, 3, 13, 10, 0),
        ),
      );

      final removed = await store.remove('JIOHOTSTAR');

      expect(removed, isTrue);
      expect(await store.list(), isEmpty);
    });
  });
}
