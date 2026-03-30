import '../contracts/service_evidence_bucket_store.dart';
import '../../domain/entities/service_evidence_bucket.dart';

class InMemoryServiceEvidenceBucketStore implements ServiceEvidenceBucketStore {
  List<ServiceEvidenceBucket> _buckets = const <ServiceEvidenceBucket>[];

  @override
  Future<List<ServiceEvidenceBucket>> load() async {
    return _buckets;
  }

  @override
  Future<void> save(List<ServiceEvidenceBucket> buckets) async {
    final next = buckets.toList(growable: false)
      ..sort(
        (left, right) => left.serviceKey.value.compareTo(right.serviceKey.value),
      );
    _buckets = List<ServiceEvidenceBucket>.unmodifiable(next);
  }

  @override
  Future<void> clear() async {
    _buckets = const <ServiceEvidenceBucket>[];
  }
}
