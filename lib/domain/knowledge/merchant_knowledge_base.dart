enum MerchantCategory {
  videoStreaming,
  musicAudio,
  cloudStorage,
  digitalStore,
  productivity,
  aiAssistant,
  foodMembership,
  telecomBenefit,
}

class MerchantResolutionMetadata {
  const MerchantResolutionMetadata({
    this.resolveOnWeakReview = true,
    this.resolveOnBundleSignals = false,
    this.preferredHintAlias,
  });

  final bool resolveOnWeakReview;
  final bool resolveOnBundleSignals;
  final String? preferredHintAlias;
}

class MerchantKnowledgeEntry {
  const MerchantKnowledgeEntry({
    required this.serviceKey,
    required this.displayName,
    required this.aliases,
    required this.category,
    this.senderIdPrefixes = const <String>[],
    this.planHints = const <String>[],
    this.billingHints = const <String>[],
    this.includedBundleHints = const <String>[],
    this.typeLabels = const <String>[],
    this.resolutionMetadata = const MerchantResolutionMetadata(),
  });

  final String serviceKey;
  final String displayName;
  final List<String> aliases;
  final MerchantCategory category;
  final List<String> senderIdPrefixes;
  final List<String> planHints;
  final List<String> billingHints;
  final List<String> includedBundleHints;
  final List<String> typeLabels;
  final MerchantResolutionMetadata resolutionMetadata;

  String get preferredHintAlias {
    return (resolutionMetadata.preferredHintAlias ?? aliases.first).toLowerCase();
  }
}

class MerchantKnowledgeBase {
  const MerchantKnowledgeBase._();

  static const int schemaVersion = 1;
  static const String datasetId = 'india_first_seed_v1';

  static const List<MerchantKnowledgeEntry> entries = <MerchantKnowledgeEntry>[
    MerchantKnowledgeEntry(
      serviceKey: 'AMAZON_PRIME',
      displayName: 'Amazon Prime',
      aliases: <String>['amazon prime', 'prime video'],
      category: MerchantCategory.videoStreaming,
      planHints: <String>['prime', 'monthly', 'annual'],
      billingHints: <String>['renewed', 'membership', 'subscription'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'NETFLIX',
      displayName: 'Netflix',
      aliases: <String>['netflix', 'netflix.com'],
      category: MerchantCategory.videoStreaming,
      senderIdPrefixes: <String>['NETFLX', 'NTFLIX'],
      planHints: <String>['premium', 'mobile', 'basic'],
      billingHints: <String>['subscription', 'renewed', 'monthly'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'YOUTUBE_PREMIUM',
      displayName: 'YouTube Premium',
      aliases: <String>['youtube premium', 'youtubepremium'],
      category: MerchantCategory.videoStreaming,
      planHints: <String>['premium', 'monthly', 'family'],
      billingHints: <String>['subscription payment', 'monthly subscription'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'JIOHOTSTAR',
      displayName: 'JioHotstar',
      aliases: <String>['jiohotstar', 'disney hotstar', 'disney+ hotstar', 'hotstar'],
      category: MerchantCategory.videoStreaming,
      senderIdPrefixes: <String>['JIOHTT'],
      planHints: <String>['super', 'premium', 'mobile'],
      billingHints: <String>['subscription', 'renewed', 'membership'],
      includedBundleHints: <String>['recharge', 'complimentary', 'benefit', 'free'],
      typeLabels: <String>['direct_recurring', 'bundle_candidate', 'india_first'],
      resolutionMetadata: MerchantResolutionMetadata(
        resolveOnBundleSignals: true,
        preferredHintAlias: 'jiohotstar',
      ),
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'SONYLIV',
      displayName: 'SonyLIV',
      aliases: <String>['sonyliv', 'sony liv'],
      category: MerchantCategory.videoStreaming,
      planHints: <String>['premium', 'monthly'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'ZEE5',
      displayName: 'ZEE5',
      aliases: <String>['zee5'],
      category: MerchantCategory.videoStreaming,
      planHints: <String>['premium', 'monthly'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'CRUNCHYROLL',
      displayName: 'Crunchyroll',
      aliases: <String>['crunchyroll'],
      category: MerchantCategory.videoStreaming,
      planHints: <String>['premium', 'fan'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'SPOTIFY',
      displayName: 'Spotify',
      aliases: <String>['spotify'],
      category: MerchantCategory.musicAudio,
      planHints: <String>['premium', 'duo', 'family'],
      billingHints: <String>['subscription', 'renewed', 'membership'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'APPLE_MUSIC',
      displayName: 'Apple Music',
      aliases: <String>['apple music'],
      category: MerchantCategory.musicAudio,
      planHints: <String>['individual', 'family', 'student'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'WYNK',
      displayName: 'Wynk',
      aliases: <String>['wynk'],
      category: MerchantCategory.musicAudio,
      planHints: <String>['premium'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'GAANA',
      displayName: 'Gaana',
      aliases: <String>['gaana'],
      category: MerchantCategory.musicAudio,
      planHints: <String>['plus', 'premium'],
      billingHints: <String>['subscription', 'renewed'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'GOOGLE_ONE',
      displayName: 'Google One',
      aliases: <String>['google one', 'googleone'],
      category: MerchantCategory.cloudStorage,
      planHints: <String>['100 gb', '200 gb', '2 tb'],
      billingHints: <String>['plan', 'upcoming payment', 'subscription'],
      typeLabels: <String>['direct_recurring'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'GOOGLE_PLAY',
      displayName: 'Google Play',
      aliases: <String>['google play', 'googleplay'],
      category: MerchantCategory.digitalStore,
      planHints: <String>['membership', 'subscription'],
      billingHints: <String>['recurring payment', 'processed'],
      typeLabels: <String>['app_store', 'review_family'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'APPLE_SERVICES',
      displayName: 'Apple Services',
      aliases: <String>['apple services', 'apple bill', 'apple.com/bill', 'itunes', 'app store'],
      category: MerchantCategory.digitalStore,
      planHints: <String>['subscription', 'icloud'],
      billingHints: <String>['bill', 'services'],
      typeLabels: <String>['app_store', 'review_family'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'ADOBE_SYSTEMS',
      displayName: 'Adobe Systems',
      aliases: <String>['adobe systems', 'adobe'],
      category: MerchantCategory.productivity,
      planHints: <String>['creative cloud', 'acrobat'],
      billingHints: <String>['automatic payment', 'plan renewed'],
      typeLabels: <String>['direct_recurring'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'GOOGLE_GEMINI_PRO',
      displayName: 'Google Gemini Pro',
      aliases: <String>['google gemini pro', 'gemini advanced'],
      category: MerchantCategory.aiAssistant,
      planHints: <String>['pro', 'advanced'],
      billingHints: <String>['subscription', 'plan'],
      includedBundleHints: <String>['recharge', 'complimentary', 'free', 'unlocked'],
      typeLabels: <String>['direct_recurring', 'bundle_candidate'],
      resolutionMetadata: MerchantResolutionMetadata(resolveOnBundleSignals: true),
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'SWIGGY_ONE',
      displayName: 'Swiggy One',
      aliases: <String>['swiggy one'],
      category: MerchantCategory.foodMembership,
      planHints: <String>['one', 'membership'],
      billingHints: <String>['membership', 'subscription'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
    MerchantKnowledgeEntry(
      serviceKey: 'ZOMATO_GOLD',
      displayName: 'Zomato Gold',
      aliases: <String>['zomato gold'],
      category: MerchantCategory.foodMembership,
      planHints: <String>['gold', 'membership'],
      billingHints: <String>['membership', 'subscription'],
      typeLabels: <String>['direct_recurring', 'india_first'],
    ),
  ];

  static final Map<String, MerchantKnowledgeEntry> _entriesByServiceKey =
      <String, MerchantKnowledgeEntry>{
    for (final entry in entries) entry.serviceKey: entry,
  };

  static final List<MerchantAliasCandidate> _aliasCandidates = () {
    final matchers = <MerchantAliasCandidate>[];
    for (final entry in entries) {
      for (final alias in entry.aliases) {
        matchers.add(
          MerchantAliasCandidate(
            entry: entry,
            alias: alias,
            pattern: _patternForAlias(alias),
            aliasTokens: tokenizeLookupText(alias),
            normalizedAlias: normalizeLookupText(alias),
          ),
        );
      }
    }
    matchers.sort((left, right) {
      final lengthCompare = right.alias.length.compareTo(left.alias.length);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      return left.entry.serviceKey.compareTo(right.entry.serviceKey);
    });
    return List<MerchantAliasCandidate>.unmodifiable(matchers);
  }();

  static MerchantKnowledgeEntry? findByServiceKey(String serviceKey) {
    return _entriesByServiceKey[serviceKey];
  }

  static MerchantKnowledgeEntry? matchSenderIdPrefix(
    String senderAddress, {
    Iterable<String>? requiredTypeLabels,
    bool allowWeakReview = true,
    bool allowBundleSignals = true,
  }) {
    if (senderAddress.isEmpty) return null;
    final upperAddress = senderAddress.toUpperCase();
    final labels = requiredTypeLabels == null
        ? null
        : Set<String>.from(requiredTypeLabels);

    for (final entry in entries) {
      if (entry.senderIdPrefixes.isEmpty) continue;
      
      if (labels != null && !entry.typeLabels.any(labels.contains)) continue;
      if (!allowWeakReview && !entry.resolutionMetadata.resolveOnWeakReview) continue;
      if (!allowBundleSignals && entry.resolutionMetadata.resolveOnBundleSignals) continue;

      for (final prefix in entry.senderIdPrefixes) {
        if (upperAddress.contains(prefix.toUpperCase())) {
          return entry;
        }
      }
    }
    return null;
  }

  static String? displayNameFor(String serviceKey) {
    return findByServiceKey(serviceKey)?.displayName;
  }

  static MerchantKnowledgeEntry? matchKnownMerchant(
    String input, {
    Iterable<String>? requiredTypeLabels,
    bool allowWeakReview = true,
    bool allowBundleSignals = true,
  }) {
    final labels = requiredTypeLabels == null
        ? null
        : Set<String>.from(requiredTypeLabels);

    for (final matcher in aliasCandidates(
      requiredTypeLabels: labels,
      allowWeakReview: allowWeakReview,
      allowBundleSignals: allowBundleSignals,
    )) {
      final entry = matcher.entry;
      if (matcher.pattern.hasMatch(input)) {
        return entry;
      }
    }

    return null;
  }

  static List<String> extractMerchantHints(String input) {
    final hints = <String>{};
    for (final matcher in _aliasCandidates) {
      if (matcher.pattern.hasMatch(input)) {
        hints.add(matcher.entry.preferredHintAlias);
      }
    }

    final ordered = hints.toList(growable: false)..sort();
    return ordered;
  }

  static RegExp aliasPatternForTypeLabels(Iterable<String> typeLabels) {
    final labels = Set<String>.from(typeLabels);
    final aliasPatterns = _aliasCandidates
        .where((matcher) => matcher.entry.typeLabels.any(labels.contains))
        .map((matcher) => matcher.pattern.pattern)
        .toSet()
        .toList(growable: false);

    if (aliasPatterns.isEmpty) {
      return RegExp(r'$a');
    }

    return RegExp(aliasPatterns.join('|'), caseSensitive: false);
  }

  static List<MerchantAliasCandidate> aliasCandidates({
    Iterable<String>? requiredTypeLabels,
    bool allowWeakReview = true,
    bool allowBundleSignals = true,
  }) {
    final labels = requiredTypeLabels == null
        ? null
        : Set<String>.from(requiredTypeLabels);

    return _aliasCandidates.where((candidate) {
      final entry = candidate.entry;
      if (labels != null &&
          !entry.typeLabels.any((label) => labels.contains(label))) {
        return false;
      }
      if (!allowWeakReview && !entry.resolutionMetadata.resolveOnWeakReview) {
        return false;
      }
      if (!allowBundleSignals &&
          entry.resolutionMetadata.resolveOnBundleSignals) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static String normalizeLookupText(String input) {
    return tokenizeLookupText(input).join();
  }

  static List<String> tokenizeLookupText(String input) {
    return RegExp(r'[a-z0-9]+', caseSensitive: false)
        .allMatches(input.toLowerCase())
        .map((match) => match.group(0)!)
        .toList(growable: false);
  }

  static RegExp _patternForAlias(String alias) {
    final tokens = tokenizeLookupText(alias);

    if (tokens.isEmpty) {
      return RegExp(r'$a');
    }

    final pattern = tokens.length == 1
        ? '\\b${RegExp.escape(tokens.first)}\\b'
        : '\\b${tokens.map(RegExp.escape).join(r'[\s./+&-]*')}\\b';

    return RegExp(pattern, caseSensitive: false);
  }
}

class MerchantAliasCandidate {
  const MerchantAliasCandidate({
    required this.entry,
    required this.alias,
    required this.pattern,
    required this.aliasTokens,
    required this.normalizedAlias,
  });

  final MerchantKnowledgeEntry entry;
  final String alias;
  final RegExp pattern;
  final List<String> aliasTokens;
  final String normalizedAlias;
}

