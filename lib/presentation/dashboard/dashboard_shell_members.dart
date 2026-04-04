// ignore_for_file: invalid_use_of_protected_member

part of 'dashboard_shell.dart';

extension _DashboardShellMembers on _DashboardShellState {
  static const MethodChannel _localMessageSourceCapabilityChannel =
      MethodChannel('sub_killer/local_message_source_capability');

  void _reloadSnapshot() {
    ref.read(dashboardSnapshotControllerProvider.notifier).reload();
  }

  Future<void> _scrollHomeToRenewals() async {
    if (!_homeScrollController.hasClients) {
      return;
    }
    await _homeScrollController.animateTo(
      _homeScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleServiceSearchChanged() {
    final nextQuery = _serviceSearchController.text;
    if (nextQuery == _serviceViewControls.searchQuery) {
      return;
    }

    ref.read(dashboardLocalControlsProvider.notifier).setSearchQuery(nextQuery);
  }

  void _setServiceSortMode(DashboardServiceSortMode sortMode) {
    ref.read(dashboardLocalControlsProvider.notifier).setSortMode(sortMode);
  }

  void _setServiceFilterMode(DashboardServiceFilterMode filterMode) {
    ref.read(dashboardLocalControlsProvider.notifier).setFilterMode(filterMode);
  }

  void _clearServiceViewControls() {
    if (!_serviceViewControls.hasActiveControls &&
        _serviceSearchController.text.isEmpty) {
      return;
    }

    ref
        .read(dashboardLocalControlsProvider.notifier)
        .clearServiceViewControls();
    _serviceSearchController.clear();
  }

  void _selectDestination(_DashboardDestination destination) {
    if (destination == _selectedDestination) {
      return;
    }

    setState(() {
      _previousDestination = _selectedDestination;
      _selectedDestination = destination;
    });
  }

  String _localIgnoreTargetKeyForReviewItem(ReviewItem item) {
    return LocalControlDecision.ignoreReviewItem(
      reviewItem: item,
      decidedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ).targetKey;
  }

  Future<void> _handleSyncWithSms({FirstRunController? firstRun}) async {
    try {
      final result = await ref.read(dashboardSyncStateProvider.notifier).sync(
            minimumIndicatorDuration: const Duration(milliseconds: 600),
          );
      if (!mounted) {
        return;
      }

      if (firstRun != null) {
        if (result.requestResult ==
            LocalMessageSourceAccessRequestResult.granted) {
          final confirmedCount = result.snapshot.cards
              .where((card) =>
                  card.bucket == DashboardBucket.confirmedSubscriptions)
              .length;

          if (confirmedCount > 0) {
            await firstRun.markCompleted();
          } else {
            firstRun.setFirstResult(result.snapshot);
          }
        } else if (result.requestResult ==
            LocalMessageSourceAccessRequestResult.denied) {
          firstRun.setPhase(FirstRunPhase.denied);
        } else {
          firstRun.setPhase(FirstRunPhase.permanentlyDenied);
        }
      }

      _showFeedbackSnackBar(
        _syncMessage(result.requestResult, result.snapshot),
        action:
            result.requestResult == LocalMessageSourceAccessRequestResult.denied
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: _openSettingsDestination,
                  )
                : null,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      firstRun?.setPhase(FirstRunPhase.denied);
      _showFeedbackSnackBar(
        'Scan failed. Your current results stayed in place.',
      );
    }
  }

  Future<void> _handleSyncEntry(
    RuntimeLocalMessageSourceStatus status,
  ) async {
    if (status.permissionRationaleVariant == null) {
      return _handleSyncWithSms();
    }

    _showSmsPermissionRationale(
      status.permissionRationaleVariant!,
      firstRun: ref.read(dashboardFirstRunProvider.notifier),
    );
  }

  Future<bool> _handleCreateManualSubscription(
    _ManualSubscriptionFormValue value,
  ) async {
    const targetKey = 'manual-create';

    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .createManualSubscription(
            targetKey: targetKey,
            serviceName: value.serviceName,
            billingCycle: value.billingCycle,
            amountInput: value.amountInput,
            nextRenewalDate: value.nextRenewalDate,
            planLabel: value.planLabel,
          );
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: _manualMutationSuccessMessage(
          serviceName: value.serviceName.trim(),
          verb: 'added to your list',
          amountInput: value.amountInput,
          nextRenewalDate: value.nextRenewalDate,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }
      _showFeedbackSnackBar(
        'Couldn\'t save that subscription. Your current view stayed the same.',
      );
      return false;
    }
  }

  Future<bool> _handleUpdateManualSubscription(
    String id,
    _ManualSubscriptionFormValue value,
  ) async {
    final targetKey = id;

    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .updateManualSubscription(
            id: id,
            serviceName: value.serviceName,
            billingCycle: value.billingCycle,
            amountInput: value.amountInput,
            nextRenewalDate: value.nextRenewalDate,
            planLabel: value.planLabel,
          );
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: _manualMutationSuccessMessage(
          serviceName: value.serviceName.trim(),
          verb: 'updated in your list',
          amountInput: value.amountInput,
          nextRenewalDate: value.nextRenewalDate,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }
      _showFeedbackSnackBar(
        'Couldn\'t update that subscription. Your current view stayed the same.',
      );
      return false;
    }
  }

  Future<bool> _handleDeleteManualSubscription(
    ManualSubscriptionEntry entry,
  ) async {
    final targetKey = entry.id;

    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .deleteManualSubscription(
            id: entry.id,
          );
      return _finishManualSubscriptionMutation(
        targetKey: targetKey,
        result: result,
        successMessage: '${entry.serviceName} removed from your list.',
      );
    } catch (_) {
      if (!mounted) {
        return false;
      }
      _showFeedbackSnackBar(
        'Couldn\'t remove that subscription. Your current view stayed the same.',
      );
      return false;
    }
  }

  Future<bool> _finishManualSubscriptionMutation({
    required String targetKey,
    required HandleManualSubscriptionResult result,
    required String successMessage,
  }) async {
    if (!mounted) {
      return false;
    }

    switch (result.outcome) {
      case HandleManualSubscriptionOutcome.created:
      case HandleManualSubscriptionOutcome.updated:
      case HandleManualSubscriptionOutcome.deleted:
        _showFeedbackSnackBar(successMessage);
        return true;
      case HandleManualSubscriptionOutcome.invalid:
        _showFeedbackSnackBar(
          result.errorMessage ?? 'Please check the added item and try again.',
        );
        return false;
      case HandleManualSubscriptionOutcome.notFound:
        _showFeedbackSnackBar(
          'Nothing changed. That subscription wasn\'t available.',
        );
        return false;
    }
  }

  String _manualMutationSuccessMessage({
    required String serviceName,
    required String verb,
    required String amountInput,
    required DateTime? nextRenewalDate,
  }) {
    final hasAmount = amountInput.trim().isNotEmpty;
    final hasRenewalDate = nextRenewalDate != null;
    if (hasAmount && hasRenewalDate) {
      return '$serviceName $verb. It now shows in spend and renewals.';
    }
    if (hasAmount) {
      return '$serviceName $verb. It now shows in spend.';
    }
    if (hasRenewalDate) {
      return '$serviceName $verb. It now shows in renewals.';
    }
    return '$serviceName $verb.';
  }

  Future<void> _handleReviewItemAction(
    ReviewItem item,
    ReviewItemAction action,
  ) async {
    final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);

    try {
      final result = await ref
          .read(dashboardReviewActionsProvider.notifier)
          .executeAction(item: item, action: action);
      if (!mounted) {
        return;
      }
      _showReviewActionResult(
        outcome: result.outcome,
        title: item.title,
        targetKey: descriptor.targetKey,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'Possible item couldn\'t be updated. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleUndoReviewItemAction({
    required String targetKey,
    required String title,
  }) async {
    try {
      final result = await ref
          .read(dashboardReviewActionsProvider.notifier)
          .undo(targetKey: targetKey);
      if (!mounted) {
        return;
      }
      _showUndoReviewActionResult(result.outcome, title);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'Undo didn\'t go through. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleIgnoreCard(DashboardCard card) async {
    final targetKey = 'service::${card.serviceKey.value}';
    try {
      await ref.read(dashboardLocalControlsProvider.notifier).ignoreCard(card);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        '${card.title} hidden on this phone.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: card.title,
              restoredLabel: 'returned to the dashboard',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleHideCard(DashboardCard card) async {
    final targetKey = 'card::${card.bucket.name}::${card.serviceKey.value}';
    try {
      await ref.read(dashboardLocalControlsProvider.notifier).hideCard(card);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        '${card.title} hidden on this phone.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: card.title,
              restoredLabel: 'returned to the dashboard',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleIgnoreReviewItem(ReviewItem item) async {
    final targetKey = _localIgnoreTargetKeyForReviewItem(item);
    try {
      await ref
          .read(dashboardLocalControlsProvider.notifier)
          .ignoreReviewItem(item);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        '${item.title} hidden on this phone.',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _handleUndoLocalControlOverlay(
              targetKey: targetKey,
              title: item.title,
              restoredLabel: 'returned to Possible',
            );
          },
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleUndoLocalControlOverlay({
    required String targetKey,
    required String title,
    required String restoredLabel,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .undoLocalControl(targetKey: targetKey);
      if (!mounted) {
        return;
      }
      final message = switch (result.outcome) {
        LocalControlUndoOutcome.restored => '$title $restoredLabel.',
        LocalControlUndoOutcome.notFound => 'Nothing changed.',
      };
      _showFeedbackSnackBar(message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'Undo didn\'t go through. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleSaveLocalLabel({
    required DashboardCard card,
    required String label,
    required String originalTitle,
  }) async {
    try {
      await ref
          .read(dashboardLocalControlsProvider.notifier)
          .saveLocalLabel(card: card, label: label);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar('$originalTitle label updated on this phone.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleResetLocalLabel({
    required String serviceKey,
    required String originalTitle,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .resetLocalLabel(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle label reset to the detected name.'
            : 'Nothing changed. No local label was reset.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handlePinService({
    required DashboardCard card,
    required String originalTitle,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .pinService(card);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle pinned on this phone.'
            : 'Nothing changed. This service was already pinned.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleUnpinService({
    required String serviceKey,
    required String originalTitle,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .unpinService(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        result.changed
            ? '$originalTitle unpinned on this phone.'
            : 'Nothing changed. This service was not pinned.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'That change couldn\'t be saved. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleEnableRenewalReminder({
    required DashboardRenewalReminderItemPresentation item,
    required RenewalReminderLeadTimePreset preset,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .enableReminder(item: item, preset: preset);
      if (!mounted) {
        return;
      }
      switch (result.outcome) {
        case LocalRenewalReminderOutcome.enabled:
          _showFeedbackSnackBar(
            '${item.renewal.serviceTitle} reminder set for ${preset.label}.',
          );
          break;
        case LocalRenewalReminderOutcome.unchanged:
          _showFeedbackSnackBar(
            'Nothing changed. That reminder was already set.',
          );
          break;
        case LocalRenewalReminderOutcome.failed:
        case LocalRenewalReminderOutcome.disabled:
          _showFeedbackSnackBar(
            'Reminder could not be scheduled from the current renewal timing.',
          );
          break;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'Reminder couldn\'t be updated. Your current view stayed the same.',
      );
    }
  }

  Future<void> _handleDisableRenewalReminder({
    required String serviceKey,
    required String serviceTitle,
  }) async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .disableReminder(serviceKey: serviceKey);
      if (!mounted) {
        return;
      }
      switch (result.outcome) {
        case LocalRenewalReminderOutcome.disabled:
          _showFeedbackSnackBar(
            '$serviceTitle reminder removed from this phone.',
          );
          break;
        case LocalRenewalReminderOutcome.unchanged:
          _showFeedbackSnackBar('Nothing changed. No reminder was removed.');
          break;
        case LocalRenewalReminderOutcome.failed:
        case LocalRenewalReminderOutcome.enabled:
          _showFeedbackSnackBar(
            'Reminder could not be removed from the current local state.',
          );
          break;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedbackSnackBar(
        'Reminder couldn\'t be updated. Your current view stayed the same.',
      );
    }
  }

  void _showRenewalReminderControls(
    DashboardRenewalReminderItemPresentation item,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _RenewalReminderControlsSheet(
        item: item,
        isBusy: _localRenewalReminderTargetsInFlight.contains(
          item.renewal.serviceKey,
        ),
        onSelectPreset: (preset) {
          Navigator.of(sheetContext).pop();
          return _handleEnableRenewalReminder(
            item: item,
            preset: preset,
          );
        },
        onDisable: item.selectedPreset == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                return _handleDisableRenewalReminder(
                  serviceKey: item.renewal.serviceKey,
                  serviceTitle: item.renewal.serviceTitle,
                );
              },
      ),
    );
  }

  void _showLocalServiceControls(
    DashboardCard card,
    LocalServicePresentationState servicePresentationState,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _LocalServiceControlsSheet(
        card: card,
        servicePresentationState: servicePresentationState,
        isBusy: _localServicePresentationTargetsInFlight.contains(
          card.serviceKey.value,
        ),
        onSaveLabel: (label) {
          Navigator.of(sheetContext).pop();
          return _handleSaveLocalLabel(
            card: card,
            label: label,
            originalTitle: servicePresentationState.originalTitle,
          );
        },
        onResetLabel: servicePresentationState.hasLocalLabel
            ? () {
                Navigator.of(sheetContext).pop();
                return _handleResetLocalLabel(
                  serviceKey: card.serviceKey.value,
                  originalTitle: servicePresentationState.originalTitle,
                );
              }
            : null,
        onTogglePin: () {
          Navigator.of(sheetContext).pop();
          return servicePresentationState.isPinned
              ? _handleUnpinService(
                  serviceKey: card.serviceKey.value,
                  originalTitle: servicePresentationState.originalTitle,
                )
              : _handlePinService(
                  card: card,
                  originalTitle: servicePresentationState.originalTitle,
                );
        },
      ),
    );
  }

  void _showSubscriptionDetails(
    DashboardCard card,
    DashboardBucket bucket,
    LocalServicePresentationState servicePresentationState,
    DashboardUpcomingRenewalItemPresentation? renewal,
    List<DashboardRenewalReminderItemPresentation> renewalReminderItems,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (context) => _SubscriptionDetailsSheet(
        card: card,
        bucket: bucket,
        servicePresentationState: servicePresentationState,
        metadata: _SubscriptionCardMetadata.fromCard(
          card,
          renewal: renewal,
        ),
        renewal: renewal,
        onExplain: () {
          Navigator.of(context).pop();
          _showContextualExplanation(
            ContextualExplanationPresentation.forDashboardCard(card),
          );
        },
        onOpenLocalServiceControls: () {
          Navigator.of(context).pop();
          _showLocalServiceControls(card, servicePresentationState);
        },
        onOpenRenewalReminderControls: renewal == null
            ? null
            : () {
                final reminderItem = renewalReminderItems.firstWhere(
                  (item) => item.renewal.serviceKey == renewal.serviceKey,
                );
                Navigator.of(context).pop();
                _showRenewalReminderControls(reminderItem);
              },
      ),
    );
  }

  String _syncMessage(
    LocalMessageSourceAccessRequestResult result,
    RuntimeDashboardSnapshot snapshot,
  ) {
    final keptRestoredSnapshot = snapshot.provenance.kind ==
        RuntimeSnapshotProvenanceKind.restoredLocalSnapshot;
    final confirmedCount = snapshot.cards
        .where(
          (card) => card.bucket == DashboardBucket.confirmedSubscriptions,
        )
        .length;
    return switch (result) {
      LocalMessageSourceAccessRequestResult.granted =>
        snapshot.reviewQueue.isNotEmpty && confirmedCount == 0
            ? 'Scan finished. Some items are marked Possible.'
            : confirmedCount == 0
                ? 'Scan finished. No paid subscriptions confirmed yet.'
                : 'Scan finished. Results updated.',
      LocalMessageSourceAccessRequestResult.denied => keptRestoredSnapshot
          ? 'SMS access is off. Showing your last saved results.'
          : 'SMS access is off. You can try again later.',
      LocalMessageSourceAccessRequestResult.unavailable => keptRestoredSnapshot
          ? 'SMS scan is unavailable here. Showing saved results.'
          : 'SMS scan is unavailable here.',
    };
  }

  void _showReviewActionResult({
    required ReviewItemActionOutcome outcome,
    required String title,
    required String targetKey,
  }) {
    final message = switch (outcome) {
      ReviewItemActionOutcome.confirmed =>
        '$title added to your subscriptions.',
      ReviewItemActionOutcome.markedAsBenefit =>
        '$title kept as included access.',
      ReviewItemActionOutcome.dismissed => '$title removed from Possible.',
      ReviewItemActionOutcome.notAllowed =>
        'SubWatch still needs a clearer service name.',
    };

    _showFeedbackSnackBar(
      message,
      action: switch (outcome) {
        ReviewItemActionOutcome.confirmed ||
        ReviewItemActionOutcome.markedAsBenefit ||
        ReviewItemActionOutcome.dismissed =>
          SnackBarAction(
            label: 'Undo',
            onPressed: () {
              _handleUndoReviewItemAction(
                targetKey: targetKey,
                title: title,
              );
            },
          ),
        ReviewItemActionOutcome.notAllowed => null,
      },
    );
  }

  void _showUndoReviewActionResult(
    ReviewItemUndoOutcome outcome,
    String title,
  ) {
    final message = switch (outcome) {
      ReviewItemUndoOutcome.restored => '$title returned to Possible.',
      ReviewItemUndoOutcome.notFound =>
        'Nothing changed. No possible item was restored.',
    };

    _showFeedbackSnackBar(message);
  }

  void _showFeedbackSnackBar(
    String message, {
    SnackBarAction? action,
  }) {
    final reduceMotion = shouldReduceMotion(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: DashboardShellPalette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: DashboardShellPalette.outlineStrong),
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardShellPalette.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
        action: action == null
            ? null
            : SnackBarAction(
                label: action.label,
                textColor: DashboardShellPalette.accent,
                onPressed: action.onPressed,
              ),
        behavior: SnackBarBehavior.floating,
        duration: action == null
            ? const Duration(milliseconds: 3200)
            : const Duration(milliseconds: 4200),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      ),
      snackBarAnimationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 190),
              reverseDuration: Duration(milliseconds: 150),
            ),
    );
  }

  AnimationStyle _dashboardSheetAnimationStyle() {
    return shouldReduceMotion(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: dashboardSheetMotionDuration,
            reverseDuration: dashboardSheetReverseDuration,
          );
  }

  Future<T?> _showDashboardBottomSheet<T>({
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: DashboardShellPalette.scrim,
      sheetAnimationStyle: _dashboardSheetAnimationStyle(),
      builder: builder,
    );
  }

  void _showContextualExplanation(
    ContextualExplanationPresentation presentation,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (context) =>
          _ContextualExplanationSheet(presentation: presentation),
    );
  }

  void _showReviewItemDetails(
    ReviewItem item,
    ReviewItemActionDescriptor descriptor,
    ReviewQueueItemPresentation presentation,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ReviewItemDetailsSheet(
        item: item,
        descriptor: descriptor,
        presentation: presentation,
        isBusy: _reviewActionTargetsInFlight.contains(descriptor.targetKey),
        onConfirm: descriptor.canConfirm
            ? () {
                Navigator.of(sheetContext).pop();
                _handleReviewItemAction(
                  item,
                  ReviewItemAction.confirmSubscription,
                );
              }
            : null,
        onMarkAsBenefit: presentation.benefitLabel == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _handleReviewItemAction(
                  item,
                  ReviewItemAction.markAsBenefit,
                );
              },
        onDismiss: () {
          Navigator.of(sheetContext).pop();
          _handleReviewItemAction(
            item,
            ReviewItemAction.dismissNotSubscription,
          );
        },
        onIgnore: () {
          Navigator.of(sheetContext).pop();
          _handleIgnoreReviewItem(item);
        },
        onEditDetails: () {
          final initialServiceName = descriptor.canConfirm ? item.title : null;
          const String? initialPlanLabel = null;
          Navigator.of(sheetContext).pop();
          _showCreateManualSubscriptionForm(
            initialServiceName: initialServiceName,
            initialPlanLabel: initialPlanLabel,
          );
        },
      ),
    );
  }

  Future<void> _openReviewDestination() async {
    _selectDestination(_DashboardDestination.review);
  }

  void _openSettingsDestination() {
    _selectDestination(_DashboardDestination.settings);
  }

  Future<void> _handleFirstRunGetStarted() async {
    final sourceStatus = ref.read(dashboardSourceStatusProvider);
    if (sourceStatus.permissionRationaleVariant != null) {
      _showSmsPermissionRationale(
        sourceStatus.permissionRationaleVariant!,
        firstRun: ref.read(dashboardFirstRunProvider.notifier),
      );
      return;
    }

    _handleSyncWithSms(firstRun: ref.read(dashboardFirstRunProvider.notifier));
  }

  Future<void> _handleFirstRunRetry() => _handleFirstRunGetStarted();

  Future<void> _openDevicePermissionSettings() async {
    try {
      final opened = await _localMessageSourceCapabilityChannel
          .invokeMethod<bool>('openAppSettings');
      if (opened == true) {
        return;
      }
    } on MissingPluginException {
      // Fall back to the in-app settings screen below.
    } on PlatformException {
      // Fall back to the in-app settings screen below.
    }

    if (!mounted) {
      return;
    }
    _openSettingsDestination();
  }

  Future<void> _handleFirstRunOpenSettings() async {
    await _openDevicePermissionSettings();
  }

  Future<void> _handleFirstRunNotNow() async {
    await ref.read(dashboardFirstRunProvider.notifier).markCompleted();
  }

  Future<void> _handleFirstRunDone() async {
    await ref.read(dashboardFirstRunProvider.notifier).markCompleted();
  }

  void _showSmsPermissionRationale(
    RuntimeLocalMessageSourcePermissionRationaleVariant variant, {
    FirstRunController? firstRun,
  }) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _SmsPermissionRationaleSheet(
        variant: variant,
        onContinue: () {
          Navigator.of(sheetContext).pop();
          return _handleSyncWithSms(firstRun: firstRun);
        },
        onSecondaryAction: () {
          Navigator.of(sheetContext).pop();
          if (variant ==
              RuntimeLocalMessageSourcePermissionRationaleVariant.retry) {
            _openDevicePermissionSettings();
            return;
          }
          if (firstRun != null) {
            firstRun.markCompleted();
          }
        },
      ),
    );
  }

  void _showHowSubWatchWorksSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _HowSubWatchWorksSheet(),
    );
  }

  void _showPrivacySheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _PrivacySheet(),
    );
  }

  void _showAboutSheet() {
    _showDashboardBottomSheet<void>(
      builder: (context) => const _AboutSubWatchSheet(),
    );
  }

  void _showSettingsReminderManagerSheet(
    List<DashboardRenewalReminderItemPresentation> reminderItems,
  ) {
    _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _SettingsReminderManagerSheet(
        reminderItems: reminderItems,
        busyTargets: _localRenewalReminderTargetsInFlight,
        onOpenReminderControls: (item) {
          Navigator.of(sheetContext).pop();
          _showRenewalReminderControls(item);
        },
      ),
    );
  }

  Future<void> _reportProblem({
    required RuntimeDashboardSnapshot data,
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required List<DashboardRenewalReminderItemPresentation> reminderItems,
  }) async {
    final launcher = ref.read(dashboardProblemReportLauncherProvider) ??
        const AndroidProblemReportLauncher();
    final opened = await launcher.open(
      recipient: _DashboardShellState._problemReportRecipient,
      subject: 'SubWatch problem report',
      body: _buildProblemReportBody(
        data: data,
        sourceStatus: sourceStatus,
        reminderItems: reminderItems,
      ),
    );
    if (!mounted || opened) {
      return;
    }

    _showFeedbackSnackBar('Could not open your email app.');
  }

  Future<void> _confirmClearAllData() async {
    final cleared = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Clear all data?'),
            content: const Text(
              'This removes saved subscriptions, possible-item decisions, reminders, and labels from this phone.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _isClearingAllData
                    ? null
                    : () async {
                        final didClear = await _handleClearAllData();
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(didClear);
                        }
                      },
                child: Text(
                  _isClearingAllData ? 'Clearing...' : 'Clear all data',
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!cleared || !mounted) {
      return;
    }
  }

  Future<bool> _handleClearAllData() async {
    try {
      final result = await ref
          .read(dashboardLocalControlsProvider.notifier)
          .clearAllData();
      if (!mounted) {
        return false;
      }
      setState(() {
        _selectedDestination = _DashboardDestination.home;
      });
      _serviceSearchController.clear();
      _showFeedbackSnackBar(
        switch (result.outcome) {
          ClearAllLocalDataOutcome.cleared =>
            'Local data cleared from this phone.',
          ClearAllLocalDataOutcome.clearedWithReminderWarning =>
            'Local data cleared. Some reminders may still appear.',
        },
      );
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      _showFeedbackSnackBar('Could not clear local data from this phone.');
      return false;
    }
  }

  Widget _buildSubscriptionsSection({
    required DashboardServiceSectionView section,
    required RuntimeDashboardSnapshot data,
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required List<DashboardRenewalReminderItemPresentation>
        renewalReminderItems,
    required DashboardServiceViewControls controls,
  }) {
    final children = _buildSubscriptionSectionChildren(
      section.cards,
      data.localServicePresentationStates,
      section.bucket,
      upcomingRenewals: upcomingRenewals,
      renewalReminderItems: renewalReminderItems,
      emptyTitle: _serviceSectionEmptyTitle(section.bucket),
      emptyMessage: _serviceSectionEmptyMessage(section.bucket),
    );
    final shouldCollapse =
        section.bucket == DashboardBucket.trialsAndBenefits &&
            section.cards.isNotEmpty &&
            !controls.restrictsResults;

    if (!shouldCollapse) {
      return _DashboardSection(
        key: ValueKey<String>('section-${section.bucket.name}'),
        title: _serviceSectionTitle(section.bucket),
        countLabel: _countLabel(section.cards.length),
        caption: _subscriptionsSectionCaption(section.bucket),
        children: children,
      );
    }

    return _DashboardSection(
      key: ValueKey<String>('section-${section.bucket.name}'),
      title: _serviceSectionTitle(section.bucket),
      children: <Widget>[
        _CollapsedSubscriptionSection(
          sectionKey: section.bucket.name,
          label: 'Included with your plan',
          icon: Icons.workspace_premium_outlined,
          countLabel: _countLabel(section.cards.length),
          caption: _subscriptionsSectionCaption(section.bucket),
          children: children,
        ),
      ],
    );
  }

  int _subscriptionsSectionPriority(
    DashboardBucket bucket,
    DashboardServiceFilterMode filterMode, {
    required List<DashboardServiceSectionView> visibleServiceSections,
  }) {
    return switch (bucket) {
      DashboardBucket.confirmedSubscriptions => 0,
      DashboardBucket.endedSubscriptions => 1,
      DashboardBucket.trialsAndBenefits => 2,
      DashboardBucket.needsReview => 3,
      DashboardBucket.hidden => 4,
    };
  }

  String _subscriptionsSectionCaption(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Recurring charges SubWatch can stand behind.';
      case DashboardBucket.endedSubscriptions:
        return 'No longer active or payment has stopped.';
      case DashboardBucket.needsReview:
        return 'Possible items stay separate until billing is stronger.';
      case DashboardBucket.trialsAndBenefits:
        return 'Visible separately because they are not direct paid billing.';
      case DashboardBucket.hidden:
        return 'Hidden on this phone.';
    }
  }

  bool _shouldShowManualSubscriptions(
    DashboardServiceFilterMode filterMode,
  ) {
    return filterMode == DashboardServiceFilterMode.allVisible ||
        filterMode == DashboardServiceFilterMode.confirmedOnly;
  }

  DashboardBucket _emptyStateBucketForFilter(
    DashboardServiceFilterMode filterMode,
  ) {
    switch (filterMode) {
      case DashboardServiceFilterMode.allVisible:
      case DashboardServiceFilterMode.confirmedOnly:
        return DashboardBucket.confirmedSubscriptions;
      case DashboardServiceFilterMode.observedOnly:
        return DashboardBucket.needsReview;
      case DashboardServiceFilterMode.separateAccessOnly:
        return DashboardBucket.trialsAndBenefits;
    }
  }

  List<ManualSubscriptionEntry> _visibleManualSubscriptions(
    List<ManualSubscriptionEntry> entries,
    DashboardServiceViewControls controls,
  ) {
    if (!_shouldShowManualSubscriptions(controls.filterMode)) {
      return const <ManualSubscriptionEntry>[];
    }

    final normalizedQuery = controls.normalizedSearchQuery.toLowerCase();
    final filtered = entries
        .where(
          (entry) =>
              normalizedQuery.isEmpty ||
              entry.serviceName.toLowerCase().contains(normalizedQuery) ||
              (entry.planLabel?.toLowerCase().contains(normalizedQuery) ??
                  false),
        )
        .toList(growable: false);
    final sorted = filtered.toList(growable: false)
      ..sort((left, right) {
        switch (controls.sortMode) {
          case DashboardServiceSortMode.currentOrder:
            return right.updatedAt.compareTo(left.updatedAt);
          case DashboardServiceSortMode.nameAscending:
            return left.serviceName
                .toLowerCase()
                .compareTo(right.serviceName.toLowerCase());
          case DashboardServiceSortMode.nameDescending:
            return right.serviceName
                .toLowerCase()
                .compareTo(left.serviceName.toLowerCase());
        }
      });
    return sorted;
  }

  List<Widget> _buildSubscriptionSectionChildren(
    List<DashboardCard> cards,
    Map<String, LocalServicePresentationState> localServicePresentationStates,
    DashboardBucket bucket, {
    required DashboardUpcomingRenewalsPresentation upcomingRenewals,
    required List<DashboardRenewalReminderItemPresentation>
        renewalReminderItems,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (cards.isEmpty) {
      return <Widget>[
        _EmptySectionText(
          title: emptyTitle,
          message: emptyMessage,
          icon: _emptyStateIcon(bucket),
        ),
      ];
    }

    final style = _bucketStyle(bucket);
    final renewalByServiceKey =
        <String, DashboardUpcomingRenewalItemPresentation>{
      for (final item in upcomingRenewals.items) item.serviceKey: item,
    };

    final rows = cards.map(
      (card) {
        final explanation =
            ContextualExplanationPresentation.forDashboardCard(card);
        final servicePresentationState =
            localServicePresentationStates[card.serviceKey.value] ??
                LocalServicePresentationState.fromDashboardCard(card);
        final localControlBusy = _localControlTargetsInFlight.contains(
              'card::${bucket.name}::${card.serviceKey.value}',
            ) ||
            _localControlTargetsInFlight.contains(
              'service::${card.serviceKey.value}',
            );
        final localPresentationBusy =
            _localServicePresentationTargetsInFlight.contains(
          card.serviceKey.value,
        );
        return _SubscriptionListRow(
          key: ValueKey<String>('passport-card-${bucket.name}-${card.title}'),
          card: card,
          metadata: _SubscriptionCardMetadata.fromCard(
            card,
            renewal: renewalByServiceKey[card.serviceKey.value],
          ),
          style: style,
          servicePresentationState: servicePresentationState,
          onTap: () => _showSubscriptionDetails(
            card,
            bucket,
            servicePresentationState,
            renewalByServiceKey[card.serviceKey.value],
            renewalReminderItems,
          ),
          trailing: _SubscriptionCardOverflowButton(
            bucket: bucket,
            card: card,
            explanation: explanation,
            servicePresentationState: servicePresentationState,
            localControlBusy: localControlBusy,
            localPresentationBusy: localPresentationBusy,
            onExplain: () => _showContextualExplanation(explanation),
            onOpenLocalServiceControls: () => _showLocalServiceControls(
              card,
              servicePresentationState,
            ),
            onHide: () => _handleHideCard(card),
            onIgnore: () => _handleIgnoreCard(card),
          ),
        );
      },
    ).toList(growable: false);

    return <Widget>[
      _InsetListGroup(children: rows),
    ];
  }

  List<Widget> _buildManualSubscriptionRows(
    List<ManualSubscriptionEntry> entries,
    DashboardUpcomingRenewalsPresentation upcomingRenewals,
    List<DashboardRenewalReminderItemPresentation> reminderItems,
  ) {
    if (entries.isEmpty) {
      return const <Widget>[
        _EmptySectionText(
          title: 'No added subscriptions yet',
          message:
              'Add one you already know so it stays visible without changing the current scan result.',
          icon: Icons.edit_note_rounded,
        ),
      ];
    }

    final rows = entries
        .map(
          (entry) => _ManualSubscriptionRow(
            key: ValueKey<String>('manual-subscription-${entry.id}'),
            entry: entry,
            isBusy: _manualSubscriptionTargetsInFlight.contains(entry.id),
            onTap: () => _showManualSubscriptionDetails(entry, reminderItems),
            onEdit: () => _showEditManualSubscriptionForm(entry),
            onDelete: () => _confirmDeleteManualSubscription(entry),
            onOpenReminderControls: (reminderItems
                        .any((item) => item.renewal.serviceKey == entry.id)) ==
                    false
                ? null
                : () => _showRenewalReminderControls(
                      reminderItems.firstWhere(
                        (item) => item.renewal.serviceKey == entry.id,
                      ),
                    ),
          ),
        )
        .toList(growable: false);
    return <Widget>[
      _InsetListGroup(children: rows),
    ];
  }

  Future<void> _showCreateManualSubscriptionForm({
    String? initialServiceName,
    String? initialPlanLabel,
    int? initialAmountInMinorUnits,
    ManualSubscriptionBillingCycle? initialBillingCycle,
  }) async {
    if (initialServiceName != null) {
      await _showDashboardBottomSheet<void>(
        builder: (sheetContext) => _ManualSubscriptionEditorSheet(
          initialServiceName: initialServiceName,
          initialPlanLabel: initialPlanLabel,
          initialAmountInMinorUnits: initialAmountInMinorUnits,
          initialBillingCycle: initialBillingCycle,
          onSubmit: _handleCreateManualSubscription,
        ),
      );
      return;
    }

    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualAddFlowSheet(
        onSubmit: _handleCreateManualSubscription,
      ),
    );
  }

  Future<void> _showEditManualSubscriptionForm(
    ManualSubscriptionEntry entry,
  ) async {
    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualSubscriptionEditorSheet(
        existingEntry: entry,
        onSubmit: (value) => _handleUpdateManualSubscription(entry.id, value),
        onDelete: () => _confirmDeleteManualSubscription(entry),
      ),
    );
  }

  Future<void> _showManualSubscriptionDetails(
    ManualSubscriptionEntry entry,
    List<DashboardRenewalReminderItemPresentation> reminderItems,
  ) async {
    final reminderItem =
        reminderItems.any((item) => item.renewal.serviceKey == entry.id)
            ? reminderItems
                .firstWhere((item) => item.renewal.serviceKey == entry.id)
            : null;

    await _showDashboardBottomSheet<void>(
      builder: (sheetContext) => _ManualSubscriptionDetailsSheet(
        entry: entry,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          _showEditManualSubscriptionForm(entry);
        },
        onDelete: () async {
          final deleted = await _confirmDeleteManualSubscription(entry);
          if (deleted && mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
        onOpenReminderControls: reminderItem == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _showRenewalReminderControls(reminderItem);
              },
      ),
    );
  }

  Future<bool> _confirmDeleteManualSubscription(
    ManualSubscriptionEntry entry,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove added subscription?'),
            content: Text(
              'Remove ${entry.serviceName} from the subscriptions you added?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final deleted = await _handleDeleteManualSubscription(entry);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(deleted);
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<Widget> _buildReviewRows(
    List<ReviewItem> reviewQueue, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (reviewQueue.isEmpty) {
      return <Widget>[
        _EmptySectionText(
          title: emptyTitle,
          message: emptyMessage,
          icon: Icons.verified_outlined,
        ),
      ];
    }

    return reviewQueue.map(
      (item) {
        final descriptor = ReviewItemActionDescriptor.fromReviewItem(item);
        final presentation = ReviewQueueItemPresentation.fromReviewItem(item);
        final isBusy = _reviewActionTargetsInFlight.contains(
          descriptor.targetKey,
        );

        return Padding(
          key: ValueKey<String>('review-item-${descriptor.targetKey}'),
          padding: const EdgeInsets.only(bottom: DashboardSpacing.medium),
          child: _ReviewDecisionPassportCard(
            item: item,
            descriptor: descriptor,
            presentation: presentation,
            isBusy: isBusy,
            onOpenDetails: () => _showReviewItemDetails(
              item,
              descriptor,
              presentation,
            ),
            onConfirm: descriptor.canConfirm
                ? () => _handleReviewItemAction(
                      item,
                      ReviewItemAction.confirmSubscription,
                    )
                : null,
            onMarkAsBenefit: descriptor.canConfirm
                ? () => _handleReviewItemAction(
                      item,
                      ReviewItemAction.markAsBenefit,
                    )
                : null,
            onEditDetails: descriptor.canConfirm
                ? null
                : () => _showCreateManualSubscriptionForm(
                      initialServiceName: item.title,
                    ),
            onDismiss: () => _handleReviewItemAction(
              item,
              ReviewItemAction.dismissNotSubscription,
            ),
          ),
        );
      },
    ).toList(growable: false);
  }

  IconData _emptyStateIcon(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return Icons.verified_outlined;
      case DashboardBucket.endedSubscriptions:
        return Icons.event_busy_rounded;
      case DashboardBucket.needsReview:
        return Icons.shield_moon_outlined;
      case DashboardBucket.trialsAndBenefits:
        return Icons.card_giftcard_outlined;
      case DashboardBucket.hidden:
        return Icons.visibility_off_outlined;
    }
  }

  _BucketStyle _bucketStyle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return const _BucketStyle(
          badgeLabel: 'Confirmed',
          background: DashboardShellPalette.successSoft,
          border: Color(0xFF9BC3AE),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.success,
        );
      case DashboardBucket.endedSubscriptions:
        return const _BucketStyle(
          badgeLabel: 'Ended',
          background: DashboardShellPalette.nestedPaper,
          border: DashboardShellPalette.outlineStrong,
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.mutedInk,
        );
      case DashboardBucket.needsReview:
        return const _BucketStyle(
          badgeLabel: 'Possible',
          background: DashboardShellPalette.elevatedPaper,
          border: DashboardShellPalette.outlineStrong,
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.mutedInk,
        );
      case DashboardBucket.trialsAndBenefits:
        return const _BucketStyle(
          badgeLabel: 'Included',
          background: Color(0xFF18211C),
          border: Color(0xFF314339),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.benefitGold,
        );
      case DashboardBucket.hidden:
        return const _BucketStyle(
          badgeLabel: 'Hidden',
          background: DashboardShellPalette.recoverySoft,
          border: Color(0xFF536A81),
          badgeBackground: DashboardShellPalette.registerPaper,
          badgeForeground: DashboardShellPalette.recovery,
        );
    }
  }

  List<Widget> _buildSettingsRecoveryChildren(RuntimeDashboardSnapshot data) {
    final children = <Widget>[];

    if (data.confirmedReviewItems.isNotEmpty) {
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-confirmedByYou'),
          title: 'Confirmed',
          caption: 'Items you moved out of Possible as paid subscriptions.',
          children: _buildConfirmedReviewRows(data.confirmedReviewItems),
        ),
      );
    }

    if (data.dismissedReviewItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-hiddenFromReview'),
          title: 'Not subscriptions',
          caption:
              'Items you decided should stay out of subscription tracking.',
          children: _buildDismissedReviewRows(data.dismissedReviewItems),
        ),
      );
    }

    if (data.benefitReviewItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-benefitsByYou'),
          title: 'Included with your plan',
          caption: 'Items you kept separate from paid subscriptions.',
          children: _buildBenefitReviewRows(data.benefitReviewItems),
        ),
      );
    }

    if (data.ignoredLocalItems.isNotEmpty || data.hiddenLocalItems.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _SettingsSubsection(
          key: const ValueKey<String>('section-localControls'),
          title: 'Hidden items',
          caption: 'Local-only controls that affect this phone view.',
          children: <Widget>[
            ..._buildIgnoredLocalRows(data.ignoredLocalItems),
            ..._buildHiddenLocalRows(data.hiddenLocalItems),
          ],
        ),
      );
    }

    return children;
  }

  String _countLabel(int count) {
    if (count == 1) {
      return '1 item';
    }
    return '$count items';
  }

  String _settingsSourceActionTitle(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return 'Scan messages';
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return 'Scan again';
      case RuntimeLocalMessageSourceTone.caution:
        return 'Turn on SMS access';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'About this view';
    }
  }

  String _settingsSourceActionSubtitle(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return 'Replace the sample view.';
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return 'Refresh from SMS.';
      case RuntimeLocalMessageSourceTone.caution:
        return 'Allow access to scan again.';
      case RuntimeLocalMessageSourceTone.unavailable:
        return 'This phone can\'t scan messages.';
    }
  }

  IconData _settingsSourceActionIcon(RuntimeLocalMessageSourceStatus status) {
    switch (status.tone) {
      case RuntimeLocalMessageSourceTone.demo:
        return Icons.sms_outlined;
      case RuntimeLocalMessageSourceTone.fresh:
      case RuntimeLocalMessageSourceTone.restored:
        return Icons.sync_outlined;
      case RuntimeLocalMessageSourceTone.caution:
        return Icons.lock_open_outlined;
      case RuntimeLocalMessageSourceTone.unavailable:
        return Icons.info_outline;
    }
  }

  String _buildProblemReportBody({
    required RuntimeDashboardSnapshot data,
    required RuntimeLocalMessageSourceStatus sourceStatus,
    required List<DashboardRenewalReminderItemPresentation> reminderItems,
  }) {
    final confirmedCount = data.cards
        .where((card) => card.bucket == DashboardBucket.confirmedSubscriptions)
        .length;
    final separateAccessCount = data.cards
        .where((card) => card.bucket == DashboardBucket.trialsAndBenefits)
        .length;
    final activeReminderCount =
        reminderItems.where((item) => item.selectedPreset != null).length;

    return <String>[
      'Issue summary:',
      '',
      'What you expected:',
      '',
      'What happened instead:',
      '',
      'Visible state:',
      '- Source status: ${sourceStatus.title}',
      '- Provenance: ${sourceStatus.provenanceDescription}',
      '- Possible items: ${data.reviewQueue.length}',
      '- Confirmed subscriptions: $confirmedCount',
      '- Included items: $separateAccessCount',
      '- Manual entries: ${data.manualSubscriptions.length}',
      '- Renewal notifications active: $activeReminderCount',
      '',
      'Optional:',
      '- Attach screenshots if they help.',
      '- Remove any message text you do not want to share.',
    ].join('\n');
  }

  String _serviceSectionTitle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Confirmed';
      case DashboardBucket.needsReview:
        return 'Possible';
      case DashboardBucket.trialsAndBenefits:
        return 'Included with your plan';
      case DashboardBucket.hidden:
        return 'Hidden items';
      case DashboardBucket.endedSubscriptions:
        return 'History';
    }
  }

  String _serviceSectionEmptyTitle(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'No confirmed subscriptions found yet';
      case DashboardBucket.needsReview:
        return 'No possible items found';
      case DashboardBucket.trialsAndBenefits:
        return 'No included services found';
      case DashboardBucket.hidden:
        return 'Nothing hidden';
      case DashboardBucket.endedSubscriptions:
        return 'No history found';
    }
  }

  String _serviceSectionEmptyMessage(DashboardBucket bucket) {
    switch (bucket) {
      case DashboardBucket.confirmedSubscriptions:
        return 'Confirmed subscriptions appear here. You can still add one yourself.';
      case DashboardBucket.needsReview:
        return 'No possible items right now.';
      case DashboardBucket.trialsAndBenefits:
        return 'No included services right now.';
      case DashboardBucket.hidden:
        return 'No hidden items here.';
      case DashboardBucket.endedSubscriptions:
        return 'Ended subscriptions appear here.';
    }
  }

  List<Widget> _buildConfirmedReviewRows(
    List<UserConfirmedReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-confirmedByYou-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Moved to Confirmed',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildDismissedReviewRows(
    List<UserDismissedReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-hiddenFromReview-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Marked as not a subscription',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildBenefitReviewRows(
    List<UserBenefitReviewItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-benefitsByYou-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Included with your plan',
            isBusy: _reviewActionTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoReviewItemAction(
              targetKey: item.targetKey,
              title: item.title,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildIgnoredLocalRows(
    List<UserIgnoredLocalItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key: ValueKey<String>(
                'passport-card-ignoredLocal-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Hidden on this phone',
            isBusy: _localControlTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoLocalControlOverlay(
              targetKey: item.targetKey,
              title: item.title,
              restoredLabel: 'returned to your list',
            ),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildHiddenLocalRows(
    List<UserHiddenLocalItem> items,
  ) {
    return items
        .map(
          (item) => _SettingsRecoveryRow(
            key:
                ValueKey<String>('passport-card-hiddenLocal-${item.targetKey}'),
            title: item.title,
            subtitle: item.subtitle,
            statusLabel: 'Hidden on this phone',
            isBusy: _localControlTargetsInFlight.contains(item.targetKey),
            actionKey: ValueKey<String>('undo-review-action-${item.targetKey}'),
            onUndo: () => _handleUndoLocalControlOverlay(
              targetKey: item.targetKey,
              title: item.title,
              restoredLabel: 'returned to your list',
            ),
          ),
        )
        .toList(growable: false);
  }
}
