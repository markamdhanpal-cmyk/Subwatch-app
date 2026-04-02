import '../enums/subscription_evidence_kind.dart';

class SubscriptionEvidence {
  const SubscriptionEvidence({
    required this.messageId,
    required this.kind,
    required this.occurredAt,
    this.serviceKey,
    this.amount,
    this.senderToken,
    this.explanation,
    this.confidence = 1.0,
    this.count = 1,
  });

  const SubscriptionEvidence.aggregate({
    required this.kind,
    required this.count,
  })  : messageId = '',
        occurredAt = null,
        serviceKey = null,
        amount = null,
        senderToken = null,
        explanation = null,
        confidence = 1.0;

  final String messageId;
  final SubscriptionEvidenceKind kind;
  final DateTime? occurredAt;
  final String? serviceKey;
  final double? amount;
  final String? senderToken;
  final String? explanation;
  final double confidence;
  final int count;
}
