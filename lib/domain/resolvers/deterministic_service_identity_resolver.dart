import '../contracts/service_identity_resolver.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/subscription_event_type.dart';
import '../value_objects/service_key.dart';

class DeterministicServiceIdentityResolver implements ServiceIdentityResolver {
  const DeterministicServiceIdentityResolver();

  static const ServiceKey unresolvedServiceKey = ServiceKey('UNRESOLVED');

  static final List<_ServiceHint> _serviceHints = <_ServiceHint>[
    _ServiceHint(
        'AMAZON_PRIME', RegExp(r'\bamazon prime\b', caseSensitive: false)),
    _ServiceHint('YOUTUBE_PREMIUM',
        RegExp(r'\byoutube ?premium\b', caseSensitive: false)),
    _ServiceHint(
        'GOOGLE_ONE', RegExp(r'\bgoogle ?one\b', caseSensitive: false)),
    _ServiceHint(
      'GOOGLE_GEMINI_PRO',
      RegExp(r'\bgoogle gemini pro\b', caseSensitive: false),
    ),
    _ServiceHint(
        'GOOGLE_PLAY', RegExp(r'\bgoogle ?play\b', caseSensitive: false)),
    _ServiceHint(
        'ADOBE_SYSTEMS', RegExp(r'\badobe systems\b', caseSensitive: false)),
    _ServiceHint('ADOBE_SYSTEMS', RegExp(r'\badobe\b', caseSensitive: false)),
    _ServiceHint(
        'APPLE_MUSIC', RegExp(r'\bapple music\b', caseSensitive: false)),
    _ServiceHint(
        'APPLE_SERVICES',
        RegExp(r'\bapple(?:\.com\/bill| services| bill)\b',
            caseSensitive: false)),
    _ServiceHint('SPOTIFY', RegExp(r'\bspotify\b', caseSensitive: false)),
    _ServiceHint('JIOHOTSTAR', RegExp(r'\bjiohotstar\b', caseSensitive: false)),
    _ServiceHint('JIOHOTSTAR',
        RegExp(r'\b(?:disney\+?\s*)?hotstar\b', caseSensitive: false)),
    _ServiceHint('NETFLIX', RegExp(r'\bnetflix\b', caseSensitive: false)),
    _ServiceHint(
        'CRUNCHYROLL', RegExp(r'\bcrunchyroll\b', caseSensitive: false)),
    _ServiceHint(
        'SWIGGY_ONE', RegExp(r'\bswiggy ?one\b', caseSensitive: false)),
    _ServiceHint(
        'ZOMATO_GOLD', RegExp(r'\bzomato ?gold\b', caseSensitive: false)),
    _ServiceHint('SONYLIV', RegExp(r'\bsony ?liv\b', caseSensitive: false)),
    _ServiceHint('ZEE5', RegExp(r'\bzee5\b', caseSensitive: false)),
    _ServiceHint('WYNK', RegExp(r'\bwynk\b', caseSensitive: false)),
    _ServiceHint('GAANA', RegExp(r'\bgaana\b', caseSensitive: false)),
  ];

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
  ServiceKey resolve({
    required MessageRecord message,
    required ParsedSignal signal,
  }) {
    if (signal.eventType == SubscriptionEventType.ignore ||
        signal.eventType == SubscriptionEventType.oneTimePayment) {
      return unresolvedServiceKey;
    }

    final explicitHint = _matchExplicitHint(message.body);
    if (explicitHint != null) {
      return explicitHint;
    }

    if (signal.eventType == SubscriptionEventType.unknownReview) {
      return unresolvedServiceKey;
    }

    final extractedCandidate = _extractCandidateKey(message.body);
    if (extractedCandidate != null) {
      return extractedCandidate;
    }

    if (signal.eventType == SubscriptionEventType.bundleActivated) {
      final providerFallback = _providerFallback(message.body);
      if (providerFallback != null) {
        return providerFallback;
      }
    }

    return unresolvedServiceKey;
  }

  ServiceKey? _matchExplicitHint(String body) {
    for (final hint in _serviceHints) {
      if (hint.pattern.hasMatch(body)) {
        return ServiceKey(hint.key);
      }
    }

    return null;
  }

  ServiceKey? _extractCandidateKey(String body) {
    for (final pattern in _candidatePatterns) {
      final match = pattern.firstMatch(body);
      if (match == null) {
        continue;
      }

      final candidate = match.group(1);
      if (candidate == null) {
        continue;
      }

      final normalized = _normalizeCandidate(candidate);
      if (normalized == null) {
        continue;
      }

      return ServiceKey(normalized);
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
}

class _ServiceHint {
  const _ServiceHint(this.key, this.pattern);

  final String key;
  final RegExp pattern;
}
