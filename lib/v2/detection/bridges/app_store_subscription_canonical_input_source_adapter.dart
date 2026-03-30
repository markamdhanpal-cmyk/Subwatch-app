import '../models/canonical_input.dart';
import '../contracts/canonical_input_source.dart';
import '../../../application/contracts/app_store_subscription_source.dart';
import '../../../application/mappers/app_store_subscription_record_canonical_input_mapper.dart';

class AppStoreSubscriptionCanonicalInputSourceAdapter
    implements CanonicalInputSource {
  const AppStoreSubscriptionCanonicalInputSourceAdapter({
    required AppStoreSubscriptionSource source,
    AppStoreSubscriptionRecordCanonicalInputMapper canonicalInputMapper =
        const AppStoreSubscriptionRecordCanonicalInputMapper(),
  })  : _source = source,
        _canonicalInputMapper = canonicalInputMapper;

  final AppStoreSubscriptionSource _source;
  final AppStoreSubscriptionRecordCanonicalInputMapper _canonicalInputMapper;

  @override
  Future<List<CanonicalInput>> loadCanonicalInputs() async {
    final records = await _source.loadSubscriptionRecords();
    return _canonicalInputMapper.mapAll(records);
  }
}
