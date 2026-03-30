import '../entities/service_evidence_bucket.dart';
import '../value_objects/service_key.dart';

abstract interface class ServiceEvidenceBucketRepository {
  Future<ServiceEvidenceBucket?> read(ServiceKey serviceKey);

  Future<void> write(ServiceEvidenceBucket bucket);

  Future<List<ServiceEvidenceBucket>> list();

  Future<void> replaceAll(Iterable<ServiceEvidenceBucket> buckets);

  Future<void> clear();
}
