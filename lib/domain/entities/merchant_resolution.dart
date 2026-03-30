import '../enums/merchant_resolution_confidence.dart';
import '../enums/merchant_resolution_method.dart';
import '../value_objects/service_key.dart';

class MerchantResolution {
  MerchantResolution({
    required this.resolvedServiceKey,
    required this.confidence,
    required this.resolutionMethod,
    List<String> matchedTerms = const <String>[],
  }) : matchedTerms = List<String>.unmodifiable(matchedTerms);

  final ServiceKey resolvedServiceKey;
  final MerchantResolutionConfidence confidence;
  final MerchantResolutionMethod resolutionMethod;
  final List<String> matchedTerms;

  bool get isResolved => resolvedServiceKey.value != 'UNRESOLVED';

  String get traceNote {
    final joinedTerms = matchedTerms.isEmpty ? 'none' : matchedTerms.join('|');
    return 'merchant_resolution:${resolutionMethod.name}:${confidence.name}:$joinedTerms';
  }
}
