import '../entities/merchant_resolution.dart';
import '../entities/message_record.dart';
import '../entities/subscription_evidence.dart';
import '../enums/merchant_resolution_confidence.dart';
import '../enums/merchant_resolution_method.dart';
import '../knowledge/merchant_knowledge_base.dart';
import '../value_objects/service_key.dart';

class ServiceKeyResolverV2 {
  const ServiceKeyResolverV2();

  static const ServiceKey unresolvedServiceKey = ServiceKey('UNRESOLVED');

  MerchantResolution resolve({
    required MessageRecord message,
    required SubscriptionEvidence evidence,
  }) {
    if (evidence.serviceKey != null && evidence.serviceKey!.isNotEmpty) {
      return MerchantResolution(
        resolvedServiceKey: ServiceKey(evidence.serviceKey!),
        confidence: MerchantResolutionConfidence.high,
        resolutionMethod: MerchantResolutionMethod.exactAlias,
      );
    }

    final senderResolution = _matchSenderToken(
      message.sourceAddress,
      allowBundleSignals: true,
    );
    if (senderResolution != null) {
      return senderResolution;
    }

    final bodyTokens = MerchantKnowledgeBase.tokenizeLookupText(message.body);
    if (bodyTokens.isEmpty) {
      return MerchantResolution(
        resolvedServiceKey: unresolvedServiceKey,
        confidence: MerchantResolutionConfidence.none,
        resolutionMethod: MerchantResolutionMethod.noMatch,
      );
    }

    final exactAlias = _matchExactAlias(
      bodyTokens: bodyTokens,
      allowBundleSignals: true,
    );
    if (exactAlias != null) {
      return exactAlias;
    }

    final scopedAlias = _matchScopedAlias(
      message.body,
      allowBundleSignals: true,
    );
    if (scopedAlias != null) {
      return scopedAlias;
    }

    return MerchantResolution(
      resolvedServiceKey: unresolvedServiceKey,
      confidence: MerchantResolutionConfidence.none,
      resolutionMethod: MerchantResolutionMethod.noMatch,
    );
  }

  MerchantResolution? _matchSenderToken(
    String senderAddress, {
    required bool allowBundleSignals,
  }) {
    final entry = MerchantKnowledgeBase.matchSenderIdPrefix(
      senderAddress,
      allowWeakReview: false,
      allowBundleSignals: allowBundleSignals,
    );
    if (entry == null) {
      return null;
    }

    return MerchantResolution(
      resolvedServiceKey: ServiceKey(entry.serviceKey),
      confidence: MerchantResolutionConfidence.high,
      resolutionMethod: MerchantResolutionMethod.senderIdPrefix,
      matchedTerms: <String>[senderAddress],
    );
  }

  MerchantResolution? _matchExactAlias({
    required List<String> bodyTokens,
    required bool allowBundleSignals,
  }) {
    for (final candidate in MerchantKnowledgeBase.aliasCandidates(
      allowWeakReview: false,
      allowBundleSignals: allowBundleSignals,
    )) {
      final aliasTokens = candidate.aliasTokens;
      if (aliasTokens.isEmpty) {
        continue;
      }
      if (_containsContiguousAlias(bodyTokens, aliasTokens)) {
        return MerchantResolution(
          resolvedServiceKey: ServiceKey(candidate.entry.serviceKey),
          confidence: MerchantResolutionConfidence.high,
          resolutionMethod: MerchantResolutionMethod.exactAlias,
          matchedTerms: <String>[candidate.alias],
        );
      }
    }

    return null;
  }

  MerchantResolution? _matchScopedAlias(
    String body, {
    required bool allowBundleSignals,
  }) {
    for (final candidate in MerchantKnowledgeBase.aliasCandidates(
      allowWeakReview: false,
      allowBundleSignals: allowBundleSignals,
    )) {
      if (!candidate.pattern.hasMatch(body)) {
        continue;
      }

      return MerchantResolution(
        resolvedServiceKey: ServiceKey(candidate.entry.serviceKey),
        confidence: MerchantResolutionConfidence.medium,
        resolutionMethod: MerchantResolutionMethod.tokenAlias,
        matchedTerms: <String>[candidate.alias],
      );
    }

    return null;
  }

  bool _containsContiguousAlias(
    List<String> bodyTokens,
    List<String> aliasTokens,
  ) {
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

    return false;
  }
}
