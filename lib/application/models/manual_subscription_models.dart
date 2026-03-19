enum ManualSubscriptionBillingCycle {
  monthly,
  yearly,
}

class ManualSubscriptionEntry {
  const ManualSubscriptionEntry({
    required this.id,
    required this.serviceName,
    required this.billingCycle,
    required this.createdAt,
    required this.updatedAt,
    this.amountInMinorUnits,
    this.nextRenewalDate,
    this.planLabel,
  });

  factory ManualSubscriptionEntry.fromJson(Map<String, Object?> json) {
    return ManualSubscriptionEntry(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      amountInMinorUnits: json['amountInMinorUnits'] as int?,
      billingCycle: ManualSubscriptionBillingCycle.values.byName(
        json['billingCycle'] as String,
      ),
      nextRenewalDate: json['nextRenewalDate'] == null
          ? null
          : DateTime.parse(json['nextRenewalDate'] as String),
      planLabel: json['planLabel'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String serviceName;
  final int? amountInMinorUnits;
  final ManualSubscriptionBillingCycle billingCycle;
  final DateTime? nextRenewalDate;
  final String? planLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAmount => amountInMinorUnits != null;
  bool get hasNextRenewalDate => nextRenewalDate != null;
  bool get hasPlanLabel => planLabel != null && planLabel!.trim().isNotEmpty;

  ManualSubscriptionEntry copyWith({
    String? serviceName,
    int? amountInMinorUnits,
    bool clearAmount = false,
    ManualSubscriptionBillingCycle? billingCycle,
    DateTime? nextRenewalDate,
    bool clearNextRenewalDate = false,
    String? planLabel,
    bool clearPlanLabel = false,
    DateTime? updatedAt,
  }) {
    return ManualSubscriptionEntry(
      id: id,
      serviceName: serviceName ?? this.serviceName,
      amountInMinorUnits:
          clearAmount ? null : amountInMinorUnits ?? this.amountInMinorUnits,
      billingCycle: billingCycle ?? this.billingCycle,
      nextRenewalDate: clearNextRenewalDate
          ? null
          : nextRenewalDate ?? this.nextRenewalDate,
      planLabel: clearPlanLabel ? null : planLabel ?? this.planLabel,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'serviceName': serviceName,
      'amountInMinorUnits': amountInMinorUnits,
      'billingCycle': billingCycle.name,
      'nextRenewalDate': nextRenewalDate?.toIso8601String(),
      'planLabel': planLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
