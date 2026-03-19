import '../enums/dashboard_bucket.dart';
import '../enums/resolver_state.dart';
import '../value_objects/service_key.dart';

class DashboardCard {
  const DashboardCard({
    required this.serviceKey,
    required this.bucket,
    required this.title,
    required this.subtitle,
    required this.state,
    this.amountLabel,
    this.frequencyLabel,
  });

  final ServiceKey serviceKey;
  final DashboardBucket bucket;
  final String title;
  final String subtitle;
  final ResolverState state;
  final String? amountLabel;
  final String? frequencyLabel;
}
