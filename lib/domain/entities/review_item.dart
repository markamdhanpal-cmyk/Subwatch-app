import '../value_objects/service_key.dart';
import 'evidence_trail.dart';

class ReviewItem {
  const ReviewItem({
    required this.serviceKey,
    required this.title,
    required this.rationale,
    required this.evidenceTrail,
    this.reasonLine = '',
    this.detailsBullets = const <String>[],
    this.priorityScore = 0,
  });

  final ServiceKey serviceKey;
  final String title;
  final String rationale;
  final EvidenceTrail evidenceTrail;
  final String reasonLine;
  final List<String> detailsBullets;
  final double priorityScore;
}
