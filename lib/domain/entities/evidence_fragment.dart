import '../enums/evidence_fragment_type.dart';

class EvidenceFragment {
  EvidenceFragment({
    required this.type,
    required this.sourceMessageId,
    required this.classifierId,
    required this.strength,
    this.confidence,
    this.note,
    this.amount,
    List<String> terms = const <String>[],
  }) : terms = List<String>.unmodifiable(terms);

  final EvidenceFragmentType type;
  final String sourceMessageId;
  final String classifierId;
  final EvidenceFragmentStrength strength;
  final double? confidence;
  final String? note;
  final double? amount;
  final List<String> terms;

  String get code {
    switch (type) {
      case EvidenceFragmentType.billedSuccess:
        return 'billed_success';
      case EvidenceFragmentType.renewalHint:
        return 'renewal_hint';
      case EvidenceFragmentType.mandateCreated:
        return 'mandate_created';
      case EvidenceFragmentType.autopaySetup:
        return 'autopay_setup';
      case EvidenceFragmentType.microCharge:
        return 'micro_charge';
      case EvidenceFragmentType.bundledBenefit:
        return 'bundled_benefit';
      case EvidenceFragmentType.endedLifecycle:
        return 'ended_lifecycle';
      case EvidenceFragmentType.cancellationHint:
        return 'cancellation_hint';
      case EvidenceFragmentType.promoOnly:
        return 'promo_only';
      case EvidenceFragmentType.weakRecurringHint:
        return 'weak_recurring_hint';
      case EvidenceFragmentType.unknownReview:
        return 'unknown_review';
      case EvidenceFragmentType.otpNoise:
        return 'otp_noise';
      case EvidenceFragmentType.telecomRechargeNoise:
        return 'telecom_recharge_noise';
      case EvidenceFragmentType.oneTimePaymentNoise:
        return 'one_time_payment_noise';
      case EvidenceFragmentType.ignoreNoise:
        return 'ignore_noise';
    }
  }

  String get traceNote => 'fragment:$code';
}
