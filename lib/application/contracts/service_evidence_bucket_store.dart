import '../../domain/entities/service_evidence_bucket.dart';

abstract interface class ServiceEvidenceBucketStore {
  Future<List<ServiceEvidenceBucket>> load();

  Future<void> save(List<ServiceEvidenceBucket> buckets);

  Future<void> clear();
}
