import '../models/receipt_adapter_models.dart';

abstract interface class AppStoreSubscriptionSource {
  Future<List<AppStoreSubscriptionRecord>> loadSubscriptionRecords();
}
