import '../../domain/contracts/service_evidence_bucket_repository.dart';
import '../../domain/entities/service_evidence_bucket.dart';
import '../../domain/value_objects/service_key.dart';

class InMemoryServiceEvidenceBucketRepository
    implements ServiceEvidenceBucketRepository {
  final Map<String, ServiceEvidenceBucket> _bucketsByKey =
      <String, ServiceEvidenceBucket>{};

  @override
  Future<ServiceEvidenceBucket?> read(ServiceKey serviceKey) async {
    return _bucketsByKey[serviceKey.value];
  }

  @override
  Future<void> write(ServiceEvidenceBucket bucket) async {
    _bucketsByKey[bucket.serviceKey.value] = bucket;
  }

  @override
  Future<List<ServiceEvidenceBucket>> list() async {
    final buckets = _bucketsByKey.values.toList(growable: false)
      ..sort(
        (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    return buckets;
  }

  @override
  Future<void> replaceAll(Iterable<ServiceEvidenceBucket> buckets) async {
    _bucketsByKey
      ..clear()
      ..addEntries(
        buckets.map(
          (bucket) => MapEntry(bucket.serviceKey.value, bucket),
        ),
      );
  }

  @override
  Future<void> clear() async {
    _bucketsByKey.clear();
  }
}
