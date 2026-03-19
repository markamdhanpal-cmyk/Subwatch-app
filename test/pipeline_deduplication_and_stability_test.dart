import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/application/use_cases/event_pipeline_use_case.dart';
import 'package:sub_killer/application/use_cases/local_ingestion_flow_use_case.dart';
import 'package:sub_killer/domain/entities/message_record.dart';
import 'package:sub_killer/domain/enums/resolver_state.dart';

void main() {
  final receivedAt = DateTime(2026, 3, 15, 10, 0);

  MessageRecord message({
    required String id,
    required String body,
    String sourceAddress = 'BANK',
  }) {
    return MessageRecord(
      id: id,
      sourceAddress: sourceAddress,
      body: body,
      receivedAt: receivedAt,
    );
  }

  group('Idempotent rescan stability', () {
    test('same messages through two fresh pipelines produce identical ledgers',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'netflix-bill-1',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'spotify-bill-1',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
        message(
          id: 'jio-mandate-1',
          body: 'You have successfully created a mandate on JioHotstar.',
        ),
      ];

      final firstRun = await LocalIngestionFlowUseCase().execute(messages);
      final secondRun = await LocalIngestionFlowUseCase().execute(messages);

      expect(firstRun.ledgerEntries.length, secondRun.ledgerEntries.length);
      for (var i = 0; i < firstRun.ledgerEntries.length; i++) {
        final first = firstRun.ledgerEntries[i];
        final second = secondRun.ledgerEntries[i];
        expect(first.serviceKey, second.serviceKey);
        expect(first.state, second.state);
        expect(first.totalBilled, second.totalBilled);
        expect(first.lastEventType, second.lastEventType);
      }
    });

    test('rescan with identical messages does not inflate event count',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'adobe-1',
          body:
              'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.',
        ),
        message(
          id: 'adobe-2',
          body: 'Adobe plan renewed successfully. Rs 799 charged.',
        ),
      ];

      final firstRun = await LocalIngestionFlowUseCase().execute(messages);
      final secondRun = await LocalIngestionFlowUseCase().execute(messages);

      expect(firstRun.events.length, secondRun.events.length);
      expect(firstRun.ledgerEntries.length, secondRun.ledgerEntries.length);
      expect(
        firstRun.ledgerEntries.single.totalBilled,
        secondRun.ledgerEntries.single.totalBilled,
      );
    });

    test(
        'rescan produces stable event IDs across runs for the same message input',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'yt-premium-1',
          body:
              'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
        ),
      ];

      final firstRun = await LocalIngestionFlowUseCase().execute(messages);
      final secondRun = await LocalIngestionFlowUseCase().execute(messages);

      expect(firstRun.events.single.id, secondRun.events.single.id);
      expect(
        firstRun.events.single.serviceKey,
        secondRun.events.single.serviceKey,
      );
    });
  });

  group('Duplicate message prevention', () {
    test(
        'exact duplicate messages with different IDs produce separate events but one ledger entry',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'netflix-dup-1',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'netflix-dup-2',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);

      // Two different message IDs → two events, but both resolve to NETFLIX
      expect(result.events, hasLength(2));
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      // Total should still accumulate per event since these are different message IDs
      expect(result.ledgerEntries.single.totalBilled, 998);
    });

    test('event IDs are unique per message even for identical body content',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'msg-a',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'msg-b',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ];

      final pipeline = EventPipelineUseCase();
      final events = pipeline.execute(messages);

      expect(events, hasLength(2));
      expect(events[0].id, isNot(events[1].id));
      expect(events[0].serviceKey, events[1].serviceKey);
    });
  });

  group('Service key normalization convergence', () {

    test('Netflix in varied casings resolves to the same service key', () {
      final variants = <String>[
        'Your Netflix subscription has been renewed for Rs 499.',
        'Your NETFLIX subscription has been renewed for Rs 499.',
        'Your netflix subscription has been renewed for Rs 499.',
        'Your NeTfLiX subscription has been renewed for Rs 499.',
      ];

      final pipeline = EventPipelineUseCase();
      final keys = <String>{};

      for (var i = 0; i < variants.length; i++) {
        final msg = message(id: 'case-$i', body: variants[i]);
        final events = pipeline.execute(<MessageRecord>[msg]);
        expect(events, hasLength(1), reason: 'variant $i should produce event');
        keys.add(events.first.serviceKey.value);
      }

      expect(keys, hasLength(1), reason: 'All casings should resolve to one key');
      expect(keys.single, 'NETFLIX');
    });

    test('YouTube Premium with and without space resolves to same key', () {
      final variants = <String>[
        'Your YouTube Premium monthly subscription payment of Rs 149 was successful.',
        'Your YouTubePremium monthly subscription payment of Rs 149 was successful.',
      ];

      final pipeline = EventPipelineUseCase();
      final keys = <String>{};

      for (var i = 0; i < variants.length; i++) {
        final msg = message(id: 'yt-$i', body: variants[i]);
        final events = pipeline.execute(<MessageRecord>[msg]);
        if (events.isNotEmpty) {
          keys.add(events.first.serviceKey.value);
        }
      }

      expect(keys, hasLength(1));
      expect(keys.single, 'YOUTUBE_PREMIUM');
    });

    test('Google Play with and without space resolves to same key', () {
      final variants = <String>[
        'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        'Recurring payment of Rs 159 processed at GooglePlay on your card XX9123.',
      ];

      final pipeline = EventPipelineUseCase();
      final keys = <String>{};

      for (var i = 0; i < variants.length; i++) {
        final msg = message(id: 'gp-$i', body: variants[i]);
        final events = pipeline.execute(<MessageRecord>[msg]);
        if (events.isNotEmpty) {
          keys.add(events.first.serviceKey.value);
        }
      }

      expect(keys, hasLength(1));
      expect(keys.single, 'GOOGLE_PLAY');
    });

    test('explicit hint services always win over candidate extraction', () {
      final msg = message(
        id: 'adobe-hint',
        body:
            'Automatic payment of Rs.20,000 for Adobe Systems setup successfully.',
      );

      final pipeline = EventPipelineUseCase();
      final events = pipeline.execute(<MessageRecord>[msg]);

      expect(events.first.serviceKey.value, 'ADOBE_SYSTEMS');
    });

    test('candidate extraction normalizes to UPPER_UNDERSCORE', () {
      final msg = message(
        id: 'crunchyroll-1',
        body:
            'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
      );

      final pipeline = EventPipelineUseCase();
      final events = pipeline.execute(<MessageRecord>[msg]);
      expect(events.first.serviceKey.value, 'CRUNCHYROLL');
    });
  });

  group('Repeated merchant signals across multiple messages', () {
    test(
        'three Netflix billing messages produce one ledger entry with accumulated total',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'nf-jan',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'nf-feb',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'nf-mar',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);

      expect(result.events, hasLength(3));
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'NETFLIX');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(result.ledgerEntries.single.totalBilled, 1497);
    });

    test(
        'mandate then execution then billing for same service produces one entry without duplication',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'cr-mandate',
          body: 'You have successfully created a mandate on Crunchyroll.',
        ),
        message(
          id: 'cr-exec',
          body:
              'Your mandate for Crunchyroll was successfully executed for Rs.1.00.',
        ),
        message(
          id: 'cr-bill',
          body: 'Your Crunchyroll subscription has been renewed for Rs 99.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);

      expect(result.events, hasLength(3));
      expect(result.ledgerEntries, hasLength(1));
      expect(result.ledgerEntries.single.serviceKey.value, 'CRUNCHYROLL');
      expect(result.ledgerEntries.single.state, ResolverState.activePaid);
      expect(result.ledgerEntries.single.totalBilled, 99);
    });

    test(
        'mixed services with repeated signals keep separate stable entries',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'nf-1',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'sp-1',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
        message(
          id: 'nf-2',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'sp-2',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);

      expect(result.events, hasLength(4));
      expect(result.ledgerEntries, hasLength(2));

      final netflix = result.ledgerEntries
          .firstWhere((entry) => entry.serviceKey.value == 'NETFLIX');
      final spotify = result.ledgerEntries
          .firstWhere((entry) => entry.serviceKey.value == 'SPOTIFY');

      expect(netflix.totalBilled, 998);
      expect(spotify.totalBilled, 238);
      expect(netflix.state, ResolverState.activePaid);
      expect(spotify.state, ResolverState.activePaid);
    });
  });

  group('Evidence trail deduplication', () {
    test('merged evidence trail has no duplicate messageIds', () async {
      final messages = <MessageRecord>[
        message(
          id: 'nf-a',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'nf-b',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);
      final entry = result.ledgerEntries.single;

      final uniqueMessageIds = entry.evidenceTrail.messageIds.toSet();
      expect(
        uniqueMessageIds.length,
        entry.evidenceTrail.messageIds.length,
        reason: 'Evidence trail should have no duplicate messageIds',
      );
      expect(uniqueMessageIds, containsAll(<String>['nf-a', 'nf-b']));
    });

    test('merged evidence trail has no duplicate eventIds', () async {
      final messages = <MessageRecord>[
        message(
          id: 'sp-a',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
        message(
          id: 'sp-b',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
      ];

      final result = await LocalIngestionFlowUseCase().execute(messages);
      final entry = result.ledgerEntries.single;

      final uniqueEventIds = entry.evidenceTrail.eventIds.toSet();
      expect(
        uniqueEventIds.length,
        entry.evidenceTrail.eventIds.length,
        reason: 'Evidence trail should have no duplicate eventIds',
      );
    });
  });

  group('Multi-service rescan stability', () {
    test(
        'complex mixed input produces identical ledger across independent runs',
        () async {
      final messages = <MessageRecord>[
        message(
          id: 'nf-bill',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'sp-bill',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
        message(
          id: 'jio-mandate',
          body: 'You have successfully created a mandate on JioHotstar.',
        ),
        message(
          id: 'airtel-bundle',
          body:
              'Your recent recharge has unlocked a FREE 18-month Google Gemini Pro plan on Airtel.',
        ),
        message(
          id: 'upi-noise',
          body: 'Rs 1 debited via UPI to VPA test@upi.',
        ),
        message(
          id: 'gp-review',
          body:
              'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
      ];

      final run1 = await LocalIngestionFlowUseCase().execute(messages);
      final run2 = await LocalIngestionFlowUseCase().execute(messages);
      final run3 = await LocalIngestionFlowUseCase().execute(messages);

      // Stable event count
      expect(run1.events.length, run2.events.length);
      expect(run2.events.length, run3.events.length);

      // Stable ledger entry count
      expect(run1.ledgerEntries.length, run2.ledgerEntries.length);
      expect(run2.ledgerEntries.length, run3.ledgerEntries.length);

      // Stable per-service states and totals
      for (var i = 0; i < run1.ledgerEntries.length; i++) {
        expect(run1.ledgerEntries[i].serviceKey, run2.ledgerEntries[i].serviceKey);
        expect(run2.ledgerEntries[i].serviceKey, run3.ledgerEntries[i].serviceKey);
        expect(run1.ledgerEntries[i].state, run2.ledgerEntries[i].state);
        expect(run2.ledgerEntries[i].state, run3.ledgerEntries[i].state);
        expect(
          run1.ledgerEntries[i].totalBilled,
          run2.ledgerEntries[i].totalBilled,
        );
        expect(
          run2.ledgerEntries[i].totalBilled,
          run3.ledgerEntries[i].totalBilled,
        );
      }
    });

    test('rescan with superset of messages preserves all prior entries', () async {
      final firstBatch = <MessageRecord>[
        message(
          id: 'nf-only',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
      ];

      final secondBatch = <MessageRecord>[
        message(
          id: 'nf-only',
          body: 'Your Netflix subscription has been renewed for Rs 499.',
        ),
        message(
          id: 'sp-new',
          body: 'Your Spotify subscription has been renewed for Rs 119.',
        ),
      ];

      final firstResult = await LocalIngestionFlowUseCase().execute(firstBatch);
      final secondResult =
          await LocalIngestionFlowUseCase().execute(secondBatch);

      expect(firstResult.ledgerEntries, hasLength(1));
      expect(secondResult.ledgerEntries, hasLength(2));

      // Netflix entry should be structurally identical
      final firstNetflix = firstResult.ledgerEntries.single;
      final secondNetflix = secondResult.ledgerEntries
          .firstWhere((entry) => entry.serviceKey.value == 'NETFLIX');

      expect(firstNetflix.state, secondNetflix.state);
      expect(firstNetflix.totalBilled, secondNetflix.totalBilled);
    });
  });
}

