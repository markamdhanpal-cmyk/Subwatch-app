import '../contracts/dashboard_projection.dart';
import '../entities/dashboard_card.dart';
import '../entities/review_item.dart';
import '../entities/service_ledger_entry.dart';
import '../enums/billing_cadence.dart';
import '../enums/dashboard_bucket.dart';
import '../enums/resolver_state.dart';

class DeterministicDashboardProjection implements DashboardProjection {
  const DeterministicDashboardProjection();

  @override
  List<DashboardCard> buildCards(Iterable<ServiceLedgerEntry> entries) {
    final sortedEntries = entries.toList(growable: false)
      ..sort((left, right) =>
          left.serviceKey.value.compareTo(right.serviceKey.value));

    return List<DashboardCard>.unmodifiable(
      sortedEntries.map(
        (entry) => DashboardCard(
          serviceKey: entry.serviceKey,
          bucket: bucketForState(entry.state),
          title: entry.serviceKey.displayName,
          subtitle: _subtitleForEntry(entry),
          state: entry.state,
          amountLabel: _amountLabelForEntry(entry),
          frequencyLabel: _frequencyLabelForEntry(entry),
          structuredAmount: entry.lastBilledAmount,
          structuredCadence: entry.billingCadence,
          structuredNextRenewalDate: entry.nextRenewalDate,
        ),
      ),
    );
  }

  @override
  List<ReviewItem> buildReviewQueue(Iterable<ServiceLedgerEntry> entries) {
    final reviewItems = entries
        .where((entry) => isReviewEligible(entry.state))
        .where(_shouldSurfaceReviewEntry)
        .map(_reviewItemForEntry)
        .toList(growable: false)
      ..sort((left, right) {
        final priorityCompare =
            right.priorityScore.compareTo(left.priorityScore);
        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return left.serviceKey.value.compareTo(right.serviceKey.value);
      });

    return List<ReviewItem>.unmodifiable(reviewItems);
  }

  DashboardBucket bucketForState(ResolverState state) {
    switch (state) {
      case ResolverState.activePaid:
        return DashboardBucket.confirmedSubscriptions;
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
        return DashboardBucket.needsReview;
      case ResolverState.activeBundled:
        return DashboardBucket.trialsAndBenefits;
      case ResolverState.cancelled:
        return DashboardBucket.endedSubscriptions;
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
        return DashboardBucket.hidden;
    }
  }

  bool isReviewEligible(ResolverState state) {
    switch (state) {
      case ResolverState.pendingConversion:
      case ResolverState.verificationOnly:
      case ResolverState.possibleSubscription:
        return true;
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return false;
    }
  }

  bool _shouldSurfaceReviewEntry(ServiceLedgerEntry entry) {
    if (entry.serviceKey.value == 'UNRESOLVED') {
      return false;
    }

    return true;
  }

  String _subtitleForEntry(ServiceLedgerEntry entry) {
    switch (entry.state) {
      case ResolverState.activePaid:
        final billed = entry.totalBilled.toStringAsFixed(0);
        return billed == '0'
            ? 'Confirmed paid subscription'
            : 'Confirmed paid subscription - \u20B9$billed';
      case ResolverState.pendingConversion:
        return 'Mandate or autopay setup detected';
      case ResolverState.verificationOnly:
        return 'Micro verification detected';
      case ResolverState.possibleSubscription:
        return 'Needs confirmation';
      case ResolverState.activeBundled:
        return 'Bundled with your plan';
      case ResolverState.ignored:
        return 'Ignored activity';
      case ResolverState.oneTimeOnly:
        return 'One-time payment';
      case ResolverState.cancelled:
        return 'Ended or cancelled';
    }
  }

  String? _amountLabelForEntry(ServiceLedgerEntry entry) {
    final amount = (entry.lastBilledAmount != null && entry.lastBilledAmount! > 0)
        ? entry.lastBilledAmount!
        : entry.totalBilled;

    if (amount <= 0) {
      return null;
    }

    final wholeUnits = amount.toStringAsFixed(0);
    return '\u20B9$wholeUnits';
  }

  /// Derives frequency label from structured [BillingCadence] enum.
  /// This is presentation-only — the enum is the source of truth.
  String? _frequencyLabelForEntry(ServiceLedgerEntry entry) {
    switch (entry.billingCadence) {
      case BillingCadence.weekly:
        return 'Weekly';
      case BillingCadence.monthly:
        return 'Monthly';
      case BillingCadence.quarterly:
        return 'Quarterly';
      case BillingCadence.semiAnnual:
        return 'Every 6 months';
      case BillingCadence.annual:
        return 'Yearly';
      case BillingCadence.unknown:
        return null;
    }
  }

  ReviewItem _reviewItemForEntry(ServiceLedgerEntry entry) {
    final facts = _reviewFacts(entry);
    final explanation = _reviewExplanation(entry, facts);
    return ReviewItem(
      serviceKey: entry.serviceKey,
      title: entry.serviceKey.displayName,
      rationale: explanation.rationale,
      evidenceTrail: entry.evidenceTrail,
      reasonLine: explanation.reasonLine,
      detailsBullets: explanation.detailsBullets,
      priorityScore: _reviewPriorityScore(entry, facts),
    );
  }

  _ReviewFacts _reviewFacts(ServiceLedgerEntry entry) {
    final reasonCodes = entry.evidenceTrail.notes
        .where((note) => note.startsWith('v2:reason='))
        .map((note) => note.substring('v2:reason='.length))
        .toSet();
    final contradictionNotes = entry.evidenceTrail.notes
        .where((note) =>
            note.startsWith('v2:note=') ||
            note.startsWith('contradiction') ||
            note.contains('paid_vs_bundle') ||
            note.contains('setup_after_paid') ||
            note.contains('paid_after_setup') ||
            note.contains('micro_after_paid') ||
            note.contains('paid_after_micro'))
        .toList(growable: false);

    return _ReviewFacts(
      reviewPriority: _parseDoubleNote(entry.evidenceTrail.notes, 'v2:reviewPriority='),
      mlProbability: _parseDoubleNote(entry.evidenceTrail.notes, 'v2:mlProbability='),
      hasPaidEvidence: reasonCodes.contains('paidEvidenceObserved'),
      hasWeakRecurringSignals:
          reasonCodes.contains('weakRecurringSignalsObserved'),
      hasPromoSignals: reasonCodes.contains('promoSignalsObserved'),
      hasCancellationSignals:
          reasonCodes.contains('cancellationSignalsObserved'),
      hasContradictions:
          reasonCodes.contains('contradictionObserved') ||
              contradictionNotes.isNotEmpty,
      hasLikelyPaidReason:
          reasonCodes.contains('likelyPaidNeedsMoreHistory'),
    );
  }

  _ReviewExplanation _reviewExplanation(
    ServiceLedgerEntry entry,
    _ReviewFacts facts,
  ) {
    switch (entry.state) {
      case ResolverState.pendingConversion:
        return const _ReviewExplanation(
          reasonLine: 'A recurring setup was found, but billing is still missing',
          rationale:
              'A mandate or autopay setup was found, but no billed renewal has been seen yet.',
          detailsBullets: <String>[
            'We saw a mandate or autopay setup for this service.',
            'There is still no billed renewal to prove it is active and paid.',
            'SubWatch keeps setup messages separate from confirmed subscriptions.',
          ],
        );
      case ResolverState.verificationOnly:
        return const _ReviewExplanation(
          reasonLine: 'Only a small verification charge was found',
          rationale:
              'Only a micro verification charge has been seen so far, which is not enough to confirm a paid subscription.',
          detailsBullets: <String>[
            'We saw a very small charge that looks like a payment check.',
            'Tiny verification charges do not prove an active paid subscription.',
            'SubWatch waits for a real billed renewal before confirming it.',
          ],
        );
      case ResolverState.possibleSubscription:
        if (facts.hasContradictions) {
          return const _ReviewExplanation(
            reasonLine: 'The signals conflict, so this still needs your review',
            rationale:
                'Some signals point in different directions, so SubWatch is keeping this separate instead of guessing.',
            detailsBullets: <String>[
              'We saw signals that do not agree with each other yet.',
              'Conflicting evidence is kept out of confirmed subscriptions.',
              'A later billed renewal or your decision can settle it safely.',
            ],
          );
        }
        if (facts.hasCancellationSignals) {
          return const _ReviewExplanation(
            reasonLine: 'We saw recurring and cancellation clues together',
            rationale:
                'This still looks subscription-related, but cancellation wording was also seen, so it stays in review.',
            detailsBullets: <String>[
              'Part of the evidence looked recurring.',
              'We also saw wording that points toward cancellation or change.',
              'SubWatch keeps mixed signals separate until they are clearer.',
            ],
          );
        }
        if (facts.hasPaidEvidence || facts.hasLikelyPaidReason) {
          return const _ReviewExplanation(
            reasonLine: 'A billing signal was found, but the proof is still thin',
            rationale:
                'A billed-looking signal was found, but there is not enough stable history yet to confirm it automatically.',
            detailsBullets: <String>[
              'We saw a billing signal that may belong to a subscription.',
              'There is not enough repeat history yet to treat it as confirmed.',
              'SubWatch keeps one-off or mixed paid signals separate for safety.',
            ],
          );
        }
        if (facts.hasPromoSignals) {
          return const _ReviewExplanation(
            reasonLine: 'The message looked recurring, but part of it was promotional',
            rationale:
                'A recurring-looking message was found, but promotional wording makes the evidence weaker.',
            detailsBullets: <String>[
              'We saw wording that looks subscription-related.',
              'The message also looked partly promotional or sales-like.',
              'SubWatch does not confirm paid subscriptions from weak mixed evidence.',
            ],
          );
        }
        if (facts.hasWeakRecurringSignals) {
          return const _ReviewExplanation(
            reasonLine: 'It looks recurring, but billing is still unproven',
            rationale:
                'Recurring wording was seen, but there is still not enough billing proof to confirm it automatically.',
            detailsBullets: <String>[
              'We saw wording that suggests recurring access.',
              'No strong billed renewal has been confirmed yet.',
              'SubWatch keeps weak recurring signals in Review instead of guessing.',
            ],
          );
        }
        return const _ReviewExplanation(
          reasonLine: 'This still needs a careful manual check',
          rationale:
              'The evidence is not strong enough to confirm automatically, so this stays in review.',
          detailsBullets: <String>[
            'Some evidence points toward a subscription.',
            'The proof is still not strong enough to confirm it safely.',
            'SubWatch is waiting for clearer history or your decision.',
          ],
        );
      case ResolverState.activePaid:
      case ResolverState.activeBundled:
      case ResolverState.ignored:
      case ResolverState.oneTimeOnly:
      case ResolverState.cancelled:
        return const _ReviewExplanation(
          reasonLine: 'No review required',
          rationale: 'No review required.',
          detailsBullets: <String>[],
        );
    }
  }

  double _reviewPriorityScore(ServiceLedgerEntry entry, _ReviewFacts facts) {
    var score = switch (entry.state) {
      ResolverState.verificationOnly => 1.0,
      ResolverState.pendingConversion => 0.9,
      ResolverState.possibleSubscription => 0.55,
      ResolverState.activePaid ||
      ResolverState.activeBundled ||
      ResolverState.ignored ||
      ResolverState.oneTimeOnly ||
      ResolverState.cancelled => 0.0,
    };

    score += facts.reviewPriority * 0.45;
    if (facts.hasContradictions) {
      score += 0.28;
    }
    if (facts.hasCancellationSignals) {
      score += 0.18;
    }
    if (facts.hasPaidEvidence || facts.hasLikelyPaidReason) {
      score += 0.15;
    }
    if (facts.hasPromoSignals) {
      score -= 0.06;
    }
    if (facts.mlProbability >= 0.35 && facts.mlProbability <= 0.8) {
      score += 0.08;
    }
    if (entry.totalBilled > 0) {
      score += 0.08;
    }

    return score;
  }

  double _parseDoubleNote(List<String> notes, String prefix) {
    for (final note in notes) {
      if (!note.startsWith(prefix)) {
        continue;
      }
      final parsed = double.tryParse(note.substring(prefix.length));
      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }
}

class _ReviewFacts {
  const _ReviewFacts({
    required this.reviewPriority,
    required this.mlProbability,
    required this.hasPaidEvidence,
    required this.hasWeakRecurringSignals,
    required this.hasPromoSignals,
    required this.hasCancellationSignals,
    required this.hasContradictions,
    required this.hasLikelyPaidReason,
  });

  final double reviewPriority;
  final double mlProbability;
  final bool hasPaidEvidence;
  final bool hasWeakRecurringSignals;
  final bool hasPromoSignals;
  final bool hasCancellationSignals;
  final bool hasContradictions;
  final bool hasLikelyPaidReason;
}

class _ReviewExplanation {
  const _ReviewExplanation({
    required this.reasonLine,
    required this.rationale,
    required this.detailsBullets,
  });

  final String reasonLine;
  final String rationale;
  final List<String> detailsBullets;
}
