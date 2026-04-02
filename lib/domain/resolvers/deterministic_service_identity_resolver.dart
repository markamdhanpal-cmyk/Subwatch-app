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

    final senderPrefixResolution = _matchSenderPrefix(
      message.sourceAddress,
      allowWeakReview: signal.eventType != SubscriptionEventType.unknownReview,
    );
    if (senderPrefixResolution != null) {
      return senderPrefixResolution;
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

    if (signal.eventType == SubscriptionEventType.unknownReview) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.noMatch,
      );
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

  MerchantResolution? _matchSenderPrefix(
    String senderAddress, {
    required bool allowWeakReview,
  }) {
    final entry = MerchantKnowledgeBase.matchSenderIdPrefix(
      senderAddress,
      allowWeakReview: allowWeakReview,
    );
    if (entry != null) {
      return MerchantResolution(
        resolvedServiceKey: ServiceKey(entry.serviceKey),
        confidence: MerchantResolutionConfidence.high,
        resolutionMethod: MerchantResolutionMethod.senderIdPrefix,
        matchedTerms: <String>[senderAddress],
      );
    }
    return null;
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

  bool _matchesAliasTokens({
    required List<String> bodyTokens,
    required List<String> aliasTokens,
    required String normalizedAlias,
  }) {
    if (aliasTokens.isEmpty) {
      return false;
    }

    if (aliasTokens.length == 1) {
      return bodyTokens.contains(aliasTokens.single);
    }

    for (var start = 0;
        start <= bodyTokens.length - aliasTokens.length;
        start += 1) {
      var matches = true;
      for (var offset = 0; offset < aliasTokens.length; offset += 1) {
        if (bodyTokens[start + offset] != aliasTokens[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return true;
      }
    }

    if (normalizedAlias.length >= 8) {
      final bodyJoined = bodyTokens.join();
      if (bodyJoined.contains(normalizedAlias)) {
        return true;
      }
    }

    return false;
  }
}
