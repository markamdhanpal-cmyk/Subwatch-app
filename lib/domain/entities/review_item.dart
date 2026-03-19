import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class ReviewItem {
  const ReviewItem({
    required this.serviceKey,
    required this.title,
    required this.rationale,
    required this.evidenceTrail,
  });

  final ServiceKey serviceKey;
  final String title;
  final String rationale;
  final EvidenceTrail evidenceTrail;
}
