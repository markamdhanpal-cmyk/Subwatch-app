import '../models/receipt_adapter_models.dart';

abstract interface class ReceiptLikeInputSource {
  Future<List<ReceiptLikeInputRecord>> loadReceiptLikeInputs();
}
