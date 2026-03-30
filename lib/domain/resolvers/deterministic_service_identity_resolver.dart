import '../contracts/service_identity_resolver.dart';
import '../entities/merchant_resolution.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/merchant_resolution_confidence.dart';
import '../enums/merchant_resolution_method.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import '../value_objects/service_key.dart';

class DeterministicServiceIdentityResolver implements ServiceIdentityResolver {
  const DeterministicServiceIdentityResolver();

  static const ServiceKey unresolvedServiceKey = ServiceKey('UNRESOLVED');

  static final RegExp _providerPattern = RegExp(
    r'\b(jio|airtel|vi)\b',
    caseSensitive: false,
  );

  static final List<RegExp> _candidatePatterns = <RegExp>[
    RegExp(r'\b([a-z][a-z0-9&+\- ]{2,40}?) subscription\b',
        caseSensitive: false),
    RegExp(r'\b([a-z][a-z0-9&+\- ]{2,40}?) plan\b', caseSensitive: false),
    RegExp(r'\bmandate on ([a-z][a-z0-9&+\- ]{2,40}?)\b', caseSensitive: false),
    RegExp(r'\bfor ([a-z][a-z0-9&+\- ]{2,40}?) setup successfully\b',
        caseSensitive: false),
    RegExp(r'\bfor ([a-z][a-z0-9&+\- ]{2,40}?) was successfully executed\b',
        caseSensitive: false),
  ];

  static final Set<String> _stopwords = <String>{
    'a',
    'an',
    'account',
    'automatic',
    'benefit',
    'bundle',
    'complimentary',
    'created',
    'debited',
    'for',
    'free',
    'has',
    'is',
    'mandate',
    'monthly',
    'of',
    'on',
    'payment',
    'plan',
    'recent',
    'recharge',
    'subscription',
    'successful',
    'successfully',
    'the',
    'this',
    'unlocked',
    'was',
    'your',
  };

  static final Set<String> _genericFragmentTokens = <String>{
    'as',
    'data',
    'day',
    'days',
    'daily',
    'pack',
    'packs',
    'per',
    'quota',
    'validity',
    'voice',
  };

  static final Set<String> _fragmentBoundaryTokens = <String>{
    '&',
    'and',
    'as',
    'per',
  };

  @override
  MerchantResolution resolveMerchant({
    required MessageRecord message,
    required ParsedSignal signal,
  }) {
    if (signal.eventType == SubscriptionEventType.ignore ||
        signal.eventType == SubscriptionEventType.oneTimePayment) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.protectedUnresolved,
        matchedTerms: <String>[signal.eventType.name],
      );
    }

    final exactAliasResolution = _matchExactAlias(
      message.body,
      allowWeakReview: signal.eventType != SubscriptionEventType.unknownReview,
    );
    if (exactAliasResolution != null) {
      return exactAliasResolution;
    }

    final tokenAliasResolution = _matchTokenAlias(
      message.body,
      allowWeakReview: signal.eventType != SubscriptionEventType.unknownReview,
    );
    if (tokenAliasResolution != null) {
      return tokenAliasResolution;
    }

    final fuzzyAliasResolution = _matchFuzzyAlias(
      message.body,
      allowWeakReview: signal.eventType != SubscriptionEventType.unknownReview,
    );
    if (fuzzyAliasResolution != null) {
      return fuzzyAliasResolution;
    }

    if (signal.eventType == SubscriptionEventType.unknownReview) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.noMatch,
      );
    }

    final extractedCandidateResolution = _extractCandidateResolution(message.body);
    if (extractedCandidateResolution != null) {
      return extractedCandidateResolution;
    }

    if (signal.eventType == SubscriptionEventType.bundleActivated) {
      final providerFallback = _providerFallback(message.body);
      if (providerFallback != null) {
        return MerchantResolution(
          resolvedServiceKey: providerFallback,
          confidence: MerchantResolutionConfidence.medium,
          resolutionMethod: MerchantResolutionMethod.providerBundleFallback,
          matchedTerms: <String>[providerFallback.displayName.toLowerCase()],
        );
      }
    }

    return MerchantResolution(
      resolvedServiceKey: unresolvedServiceKey,
      confidence: MerchantResolutionConfidence.none,
      resolutionMethod: MerchantResolutionMethod.noMatch,
    );
  }

  @override
  ServiceKey resolve({
    required MessageRecord message,
    required ParsedSignal signal,
  }) {
    return resolveMerchant(message: message, signal: signal).resolvedServiceKey;
  }

  MerchantResolution? _matchExactAlias(
    String body, {
    required bool allowWeakReview,
  }) {
    for (final candidate in MerchantKnowledgeBase.aliasCandidates(
      allowWeakReview: allowWeakReview,
    )) {
      if (!candidate.pattern.hasMatch(body)) {
        continue;
      }

      return MerchantResolution(
        resolvedServiceKey: ServiceKey(candidate.entry.serviceKey),
        confidence: MerchantResolutionConfidence.high,
        resolutionMethod: MerchantResolutionMethod.exactAlias,
        matchedTerms: <String>[candidate.alias],
      );
    }

    return null;
  }

  MerchantResolution? _matchTokenAlias(
    String body, {
    required bool allowWeakReview,
  }) {
    final bodyTokens = MerchantKnowledgeBase.tokenizeLookupText(body);
    if (bodyTokens.isEmpty) {
      return null;
    }

    for (final candidate in MerchantKnowledgeBase.aliasCandidates(
      allowWeakReview: allowWeakReview,
    )) {
      if (!_matchesAliasTokens(
        bodyTokens: bodyTokens,
        aliasTokens: candidate.aliasTokens,
        normalizedAlias: candidate.normalizedAlias,
      )) {
        continue;
      }

      return MerchantResolution(
        resolvedServiceKey: ServiceKey(candidate.entry.serviceKey),
        confidence: MerchantResolutionConfidence.medium,
        resolutionMethod: MerchantResolutionMethod.tokenAlias,
        matchedTerms: List<String>.unmodifiable(candidate.aliasTokens),
      );
    }

    return null;
  }

  MerchantResolution? _matchFuzzyAlias(
    String body, {
    required bool allowWeakReview,
  }) {
    final fuzzyCandidates = _candidateTexts(body);
    if (fuzzyCandidates.isEmpty) {
      return null;
    }

    _FuzzyResolutionMatch? bestMatch;
    _FuzzyResolutionMatch? secondBestMatch;
    for (final candidateText in fuzzyCandidates) {
      final normalizedCandidate =
          MerchantKnowledgeBase.normalizeLookupText(candidateText);
      if (normalizedCandidate.length < 5) {
        continue;
      }

      for (final aliasCandidate in MerchantKnowledgeBase.aliasCandidates(
        allowWeakReview: allowWeakReview,
      )) {
        final score = _fuzzyScore(
          candidate: normalizedCandidate,
          target: aliasCandidate.normalizedAlias,
        );
        if (score == null) {
          continue;
        }

        final nextMatch = _FuzzyResolutionMatch(
          aliasCandidate: aliasCandidate,
          candidateText: candidateText,
          score: score,
        );
        if (bestMatch == null || score > bestMatch.score) {
          secondBestMatch = bestMatch;
          bestMatch = nextMatch;
          continue;
        }
        if (secondBestMatch == null || score > secondBestMatch.score) {
          secondBestMatch = nextMatch;
        }
      }
    }

    if (bestMatch == null) {
      return null;
    }

    if (secondBestMatch != null &&
        secondBestMatch.aliasCandidate.entry.serviceKey !=
            bestMatch.aliasCandidate.entry.serviceKey &&
        (bestMatch.score - secondBestMatch.score) < 0.08) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.ambiguousUnresolved,
      );
    }

    final resolvedEntry = bestMatch.aliasCandidate.entry;
    return MerchantResolution(
      resolvedServiceKey: ServiceKey(resolvedEntry.serviceKey),
      confidence: bestMatch.score >= 0.93
          ? MerchantResolutionConfidence.high
          : MerchantResolutionConfidence.medium,
      resolutionMethod: MerchantResolutionMethod.fuzzyAlias,
      matchedTerms: <String>[
        bestMatch.candidateText.toLowerCase(),
        bestMatch.aliasCandidate.alias,
      ],
    );
  }

  MerchantResolution? _extractCandidateResolution(String body) {
    final seen = <String>{};
    for (final candidate in _candidateTexts(body)) {
      final normalized = _normalizeCandidate(candidate);
      if (normalized == null || !seen.add(normalized)) {
        continue;
      }

      return MerchantResolution(
        resolvedServiceKey: ServiceKey(normalized),
        confidence: MerchantResolutionConfidence.low,
        resolutionMethod: MerchantResolutionMethod.extractedCandidate,
        matchedTerms: <String>[candidate.toLowerCase()],
      );
    }

    return null;
  }

  ServiceKey? _providerFallback(String body) {
    final match = _providerPattern.firstMatch(body);
    if (match == null) {
      return null;
    }

    final provider = match.group(1);
    if (provider == null || provider.isEmpty) {
      return null;
    }

    return ServiceKey('${provider.toUpperCase()}_BUNDLE');
  }

  List<String> _candidateTexts(String body) {
    final candidates = <String>{};
    for (final pattern in _candidatePatterns) {
      final match = pattern.firstMatch(body);
      if (match == null) {
        continue;
      }

      final candidate = match.group(1);
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }
      candidates.add(candidate.trim());
    }

    final routingMatches = RegExp(
      r'\bat\s+([a-z][a-z0-9&+.\- ]{2,40}?)(?=\s+(?:on|via|using|with|for|ending|xx[0-9]{2,4})\b|[.,]|$)',
      caseSensitive: false,
    ).allMatches(body);
    for (final match in routingMatches) {
      final candidate = match.group(1);
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }
      candidates.add(candidate.trim());
    }

    return candidates.toList(growable: false);
  }

  String? _normalizeCandidate(String candidate) {
    final cleaned = candidate
        .replaceAll(RegExp(r'^[0-9]+(?:-[a-z]+)?\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-z0-9&+\- ]', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    if (cleaned.isEmpty) {
      return null;
    }

    final tokens = cleaned
        .split(' ')
        .where((token) => token.isNotEmpty && !_stopwords.contains(token))
        .toList(growable: false);

    if (tokens.isEmpty) {
      return null;
    }

    if (_isFragmentBoundaryToken(tokens.first) ||
        _isFragmentBoundaryToken(tokens.last)) {
      return null;
    }

    final identityTokens =
        tokens.where(_isCredibleIdentityToken).toList(growable: false);
    if (identityTokens.isEmpty) {
      return null;
    }

    if (tokens.length == 1 && tokens.first.length < 4) {
      return null;
    }

    return tokens.map((token) => token.toUpperCase()).join('_');
  }

  bool _isCredibleIdentityToken(String token) {
    if (token.length < 4 || _genericFragmentTokens.contains(token)) {
      return false;
    }

    return RegExp(r'[a-z0-9]', caseSensitive: false).hasMatch(token);
  }

  bool _isFragmentBoundaryToken(String token) {
    return _fragmentBoundaryTokens.contains(token) ||
        !RegExp(r'[a-z0-9]', caseSensitive: false).hasMatch(token);
  }

  bool _matchesAliasTokens({
    required List<String> bodyTokens,
    required List<String> aliasTokens,
    required String normalizedAlias,
  }) {
    if (aliasTokens.isEmpty) {
      return false;
    }

    final bodyJoined = bodyTokens.join();
    if (bodyJoined.contains(normalizedAlias) && normalizedAlias.length >= 6) {
      return true;
    }

    final aliasJoined = aliasTokens.join();
    if (aliasTokens.length >= 2 && bodyJoined.contains(aliasJoined)) {
      return true;
    }

    if (aliasTokens.length == 1) {
      if (normalizedAlias.length < 6) {
        return false;
      }

      for (var index = 0; index < bodyTokens.length - 1; index += 1) {
        final merged = bodyTokens[index] + bodyTokens[index + 1];
        if (merged == normalizedAlias) {
          return true;
        }
      }
      return false;
    }

    var aliasIndex = 0;
    for (final token in bodyTokens) {
      if (token == aliasTokens[aliasIndex]) {
        aliasIndex += 1;
        if (aliasIndex == aliasTokens.length) {
          return true;
        }
      }
    }

    return false;
  }

  double? _fuzzyScore({
    required String candidate,
    required String target,
  }) {
    if (candidate == target) {
      return 1;
    }

    final maxLength = candidate.length > target.length
        ? candidate.length
        : target.length;
    if (maxLength < 6) {
      return null;
    }

    final distance = _levenshteinDistance(candidate, target);
    final similarity = 1 - (distance / maxLength);
    final maxDistance = maxLength >= 12 ? 2 : 1;
    if (distance > maxDistance || similarity < 0.82) {
      return null;
    }

    return similarity;
  }

  int _levenshteinDistance(String source, String target) {
    final costs = List<int>.generate(target.length + 1, (index) => index);
    for (var sourceIndex = 1; sourceIndex <= source.length; sourceIndex += 1) {
      var previousDiagonal = costs.first;
      costs[0] = sourceIndex;
      for (var targetIndex = 1;
          targetIndex <= target.length;
          targetIndex += 1) {
        final temp = costs[targetIndex];
        final substitutionCost =
            source[sourceIndex - 1] == target[targetIndex - 1] ? 0 : 1;
        costs[targetIndex] = <int>[
          costs[targetIndex] + 1,
          costs[targetIndex - 1] + 1,
          previousDiagonal + substitutionCost,
        ].reduce((left, right) => left < right ? left : right);
        previousDiagonal = temp;
      }
    }

    return costs.last;
  }
}

class _FuzzyResolutionMatch {
  const _FuzzyResolutionMatch({
    required this.aliasCandidate,
    required this.candidateText,
    required this.score,
  });

  final MerchantAliasCandidate aliasCandidate;
  final String candidateText;
  final double score;
}
