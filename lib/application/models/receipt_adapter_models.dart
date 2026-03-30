import '../../v2/detection/models/canonical_input.dart';

enum ReceiptLikeInputKind {
  emailReceipt,
  manualReceipt,
}

class ReceiptLikeInputRecord {
  ReceiptLikeInputRecord({
    required this.id,
    required this.kind,
    required this.receivedAt,
    required this.subject,
    required this.body,
    this.senderHandle,
    this.sourceLabel,
    this.batchId,
    this.receiptReference,
    this.serviceHint,
    this.attachmentCount = 0,
    this.captureConfidence = CanonicalInputCaptureConfidence.medium,
    List<String> extractedTextSegments = const <String>[],
  })  : extractedTextSegments =
            List<String>.unmodifiable(extractedTextSegments);

  final String id;
  final ReceiptLikeInputKind kind;
  final DateTime receivedAt;
  final String subject;
  final String body;
  final String? senderHandle;
  final String? sourceLabel;
  final String? batchId;
  final String? receiptReference;
  final String? serviceHint;
  final int attachmentCount;
  final CanonicalInputCaptureConfidence captureConfidence;
  final List<String> extractedTextSegments;
}

enum AppStoreProvider {
  googlePlay,
  appleAppStore,
}

class AppStoreSubscriptionRecord {
  const AppStoreSubscriptionRecord({
    required this.id,
    required this.provider,
    required this.observedAt,
    required this.serviceName,
    required this.stateLabel,
    this.appName,
    this.productName,
    this.amount,
    this.currencyCode = 'INR',
    this.billingPeriodLabel,
    this.orderId,
    this.purchaseToken,
    this.rawSummary,
    this.batchId,
    this.captureConfidence = CanonicalInputCaptureConfidence.high,
  });

  final String id;
  final AppStoreProvider provider;
  final DateTime observedAt;
  final String serviceName;
  final String stateLabel;
  final String? appName;
  final String? productName;
  final double? amount;
  final String currencyCode;
  final String? billingPeriodLabel;
  final String? orderId;
  final String? purchaseToken;
  final String? rawSummary;
  final String? batchId;
  final CanonicalInputCaptureConfidence captureConfidence;
}
