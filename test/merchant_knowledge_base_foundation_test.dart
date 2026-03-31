import 'package:flutter_test/flutter_test.dart';
import 'package:sub_killer/domain/classifiers/recurring_billing_heuristics.dart';
import 'package:sub_killer/domain/knowledge/merchant_knowledge_base.dart';
import 'package:sub_killer/domain/value_objects/service_key.dart';

void main() {
  group('MerchantKnowledgeBase', () {
    test('exposes a versioned india-first seed catalog', () {
      expect(MerchantKnowledgeBase.schemaVersion, 1);
      expect(MerchantKnowledgeBase.datasetId, 'india_first_seed_v1');
      expect(MerchantKnowledgeBase.entries, isNotEmpty);
    });

    test('finds seeded merchant entries by service key', () {
      final entry = MerchantKnowledgeBase.findByServiceKey('JIOHOTSTAR');

      expect(entry, isNotNull);
      expect(entry!.displayName, 'JioHotstar');
      expect(entry.category, MerchantCategory.videoStreaming);
      expect(entry.aliases, contains('disney+ hotstar'));
      expect(entry.includedBundleHints, contains('recharge'));
    });

    test('matches known merchant aliases deterministically', () {
      final entry = MerchantKnowledgeBase.matchKnownMerchant(
        'HDFC Card XX4411 used for Rs 299 at DISNEY+ HOTSTAR on 17 Mar.',
      );

      expect(entry, isNotNull);
      expect(entry!.serviceKey, 'JIOHOTSTAR');
    });

    test('extracts canonical merchant hints from noisy text', () {
      final hints = MerchantKnowledgeBase.extractMerchantHints(
        'Renew now and save 20%! Netflix Premium monthly plan billed successfully for Rs 649',
      );

      expect(hints, contains('netflix'));
    });

    test('feeds recurring billing heuristics from the knowledge base', () {
      expect(
        RecurringBillingHeuristics.hasDirectRecurringMerchant(
          'Card XX1212 used for Rs 99 at SWIGGY ONE on 17 Mar.',
        ),
        isTrue,
      );
      expect(
        RecurringBillingHeuristics.hasAppStoreMerchant(
          'Recurring payment of Rs 159 processed at Google Play on your card XX9123.',
        ),
        isTrue,
      );
    });

    test('service key display names prefer knowledge-base titles', () {
      expect(const ServiceKey('JIOHOTSTAR').displayName, 'JioHotstar');
      expect(const ServiceKey('GOOGLE_PLAY').displayName, 'Google Play');
      expect(const ServiceKey('AIRTEL_XSTREAM').displayName, 'Airtel Xstream');
    });

    test('resolves Airtel Xstream and Airtel Black from aliases', () {
      final xstream = MerchantKnowledgeBase.matchKnownMerchant('Your airtel xstream subscription is successful.');
      final black = MerchantKnowledgeBase.matchKnownMerchant('Airtel Black bill for XX123 is generated.');

      expect(xstream?.serviceKey, 'AIRTEL_XSTREAM');
      expect(black?.serviceKey, 'AIRTEL_BLACK');
    });

    test('resolves merchants from specific sender ID prefixes', () {
      final swiggy = MerchantKnowledgeBase.matchSenderIdPrefix('AD-SWIGGY');
      final google = MerchantKnowledgeBase.matchSenderIdPrefix('G-GOOGLE');
      final zomato = MerchantKnowledgeBase.matchSenderIdPrefix('JM-ZOMATO');

      expect(swiggy?.serviceKey, 'SWIGGY_ONE');
      expect(google?.serviceKey, 'GOOGLE_ONE');
      expect(zomato?.serviceKey, 'ZOMATO_GOLD');
    });
  });
}
