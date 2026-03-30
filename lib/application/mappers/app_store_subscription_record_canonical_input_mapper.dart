import '../../v2/detection/models/canonical_input.dart';
import '../models/receipt_adapter_models.dart';

class AppStoreSubscriptionRecordCanonicalInputMapper {
  const AppStoreSubscriptionRecordCanonicalInputMapper();

  CanonicalInput map(AppStoreSubscriptionRecord record) {
    return CanonicalInput(
      id: record.id,
      kind: CanonicalInputKind.appStore,
      origin: _originFor(record),
      receivedAt: record.observedAt,
      textBody: _composeTextBody(record),
      senderHandle: _senderHandleFor(record.provider),
      subject: record.serviceName,
      threadId: record.batchId ?? record.provider.name,
      richTextSegments: <String>[
        'Provider: ${_providerLabel(record.provider)}',
        if (record.appName != null) 'App: ${record.appName}',
        if (record.productName != null) 'Product: ${record.productName}',
        if (record.billingPeriodLabel != null)
          'Billing period: ${record.billingPeriodLabel}',
        if (record.orderId != null) 'Order id: ${record.orderId}',
        if (record.purchaseToken != null)
          'Purchase token: ${record.purchaseToken}',
        if (record.rawSummary != null) 'Raw summary: ${record.rawSummary}',
      ],
    );
  }

  List<CanonicalInput> mapAll(Iterable<AppStoreSubscriptionRecord> records) {
    return List<CanonicalInput>.unmodifiable(records.map(map));
  }

  CanonicalInputOrigin _originFor(AppStoreSubscriptionRecord record) {
    switch (record.provider) {
      case AppStoreProvider.googlePlay:
        return CanonicalInputOrigin.googlePlayRecord(
          batchId: record.batchId,
          captureConfidence: record.captureConfidence,
        );
      case AppStoreProvider.appleAppStore:
        return CanonicalInputOrigin.appleAppStoreRecord(
          batchId: record.batchId,
          captureConfidence: record.captureConfidence,
        );
    }
  }

  String _composeTextBody(AppStoreSubscriptionRecord record) {
    final amountPhrase = record.amount == null
        ? ''
        : ' for Rs ${record.amount == record.amount!.roundToDouble() ? record.amount!.round() : record.amount!.toStringAsFixed(2)}';
    final productPhrase =
        record.productName == null ? '' : ' ${record.productName}';
    final billingPeriodPhrase = record.billingPeriodLabel == null
        ? ''
        : ' (${record.billingPeriodLabel})';
    final summaryPhrase =
        record.rawSummary == null ? '' : ' ${record.rawSummary}';

    return '${_providerLabel(record.provider)} subscription for ${record.serviceName}$productPhrase ${record.stateLabel}$amountPhrase$billingPeriodPhrase.$summaryPhrase'
        .trim();
  }

  String _providerLabel(AppStoreProvider provider) {
    switch (provider) {
      case AppStoreProvider.googlePlay:
        return 'Google Play';
      case AppStoreProvider.appleAppStore:
        return 'Apple App Store';
    }
  }

  String _senderHandleFor(AppStoreProvider provider) {
    switch (provider) {
      case AppStoreProvider.googlePlay:
        return 'google_play';
      case AppStoreProvider.appleAppStore:
        return 'apple_app_store';
    }
  }
}
