import '../contracts/service_identity_resolver.dart';
import '../entities/merchant_resolution.dart';
import '../entities/message_record.dart';
import '../entities/parsed_signal.dart';
import '../enums/merchant_resolution_confidence.dart';
import '../enums/merchant_resolution_method.dart';
import '../enums/subscription_event_type.dart';
import '../knowledge/merchant_knowledge_base.dart';
import '../value_objects/service_key.dart';

@Deprecated(
  'Legacy compatibility resolver. Use ServiceKeyResolverV2 for live '
  'evidence-first runtime resolution.',
)
class DeterministicServiceIdentityResolver implements ServiceIdentityResolver {
  const DeterministicServiceIdentityResolver();

  static const ServiceKey unresolvedServiceKey = ServiceKey('UNRESOLVED');

  @override
  MerchantResolution resolveMerchant({
    required MessageRecord message,
    required ParsedSignal signal,
  }) {
    if (_isProtectedUnresolved(signal.eventType)) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.protectedUnresolved,
        matchedTerms: <String>[signal.eventType.name],
      );
    }

    if (_mustStayUnresolvedNoMatch(signal.eventType)) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.noMatch,
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

    return MerchantResolution(
      resolvedServiceKey: unresolvedServiceKey,
      confidence: MerchantResolutionConfidence.none,
      resolutionMethod: MerchantResolutionMethod.noMatch,
    );
  }

  bool _isProtectedUnresolved(SubscriptionEventType eventType) {
    switch (eventType) {
      case SubscriptionEventType.ignore:
      case SubscriptionEventType.oneTimePayment:
        return true;
      case SubscriptionEventType.unknownReview:
      case SubscriptionEventType.mandateCreated:
      case SubscriptionEventType.autopaySetup:
      case SubscriptionEventType.mandateExecutedMicro:
      case SubscriptionEventType.subscriptionBilled:
      case SubscriptionEventType.subscriptionCancelled:
      case SubscriptionEventType.bundleActivated:
        return false;
    }
  }

  bool _mustStayUnresolvedNoMatch(SubscriptionEventType eventType) {
    switch (eventType) {
      case SubscriptionEventType.unknownReview:
      case SubscriptionEventType.mandateCreated:
      case SubscriptionEventType.autopaySetup:
      case SubscriptionEventType.mandateExecutedMicro:
        return true;
      case SubscriptionEventType.ignore:
      case SubscriptionEventType.oneTimePayment:
      case SubscriptionEventType.subscriptionBilled:
      case SubscriptionEventType.subscriptionCancelled:
      case SubscriptionEventType.bundleActivated:
        return false;
    }
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
