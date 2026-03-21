import 'package:flutter/material.dart';

import '../application/use_cases/handle_local_control_overlay_use_case.dart';
import '../application/use_cases/handle_manual_subscription_use_case.dart';
import '../application/use_cases/handle_local_renewal_reminder_use_case.dart';
import '../application/use_cases/handle_local_service_presentation_use_case.dart';
import '../application/use_cases/handle_review_item_action_use_case.dart';
import '../application/use_cases/load_runtime_dashboard_use_case.dart';
import '../application/use_cases/sync_device_sms_use_case.dart';
import '../application/use_cases/undo_local_control_overlay_use_case.dart';
import '../application/use_cases/undo_review_item_action_use_case.dart';
import '../presentation/dashboard/dashboard_primitives.dart';
import '../presentation/dashboard/dashboard_shell.dart';

class SubKillerApp extends StatelessWidget {
  const SubKillerApp({
    super.key,
    LoadRuntimeDashboardUseCase? runtimeUseCase,
    SyncDeviceSmsUseCase? syncDeviceSmsUseCase,
    HandleReviewItemActionUseCase? handleReviewItemActionUseCase,
    UndoReviewItemActionUseCase? undoReviewItemActionUseCase,
    HandleLocalControlOverlayUseCase? handleLocalControlOverlayUseCase,
    UndoLocalControlOverlayUseCase? undoLocalControlOverlayUseCase,
    HandleLocalRenewalReminderUseCase? handleLocalRenewalReminderUseCase,
    HandleManualSubscriptionUseCase? handleManualSubscriptionUseCase,
    HandleLocalServicePresentationUseCase?
        handleLocalServicePresentationUseCase,
  })  : _runtimeUseCase = runtimeUseCase,
        _syncDeviceSmsUseCase = syncDeviceSmsUseCase,
        _handleReviewItemActionUseCase = handleReviewItemActionUseCase,
        _undoReviewItemActionUseCase = undoReviewItemActionUseCase,
        _handleLocalControlOverlayUseCase = handleLocalControlOverlayUseCase,
        _undoLocalControlOverlayUseCase = undoLocalControlOverlayUseCase,
        _handleLocalRenewalReminderUseCase = handleLocalRenewalReminderUseCase,
        _handleManualSubscriptionUseCase = handleManualSubscriptionUseCase,
        _handleLocalServicePresentationUseCase =
            handleLocalServicePresentationUseCase;

  final LoadRuntimeDashboardUseCase? _runtimeUseCase;
  final SyncDeviceSmsUseCase? _syncDeviceSmsUseCase;
  final HandleReviewItemActionUseCase? _handleReviewItemActionUseCase;
  final UndoReviewItemActionUseCase? _undoReviewItemActionUseCase;
  final HandleLocalControlOverlayUseCase? _handleLocalControlOverlayUseCase;
  final UndoLocalControlOverlayUseCase? _undoLocalControlOverlayUseCase;
  final HandleLocalRenewalReminderUseCase? _handleLocalRenewalReminderUseCase;
  final HandleManualSubscriptionUseCase? _handleManualSubscriptionUseCase;
  final HandleLocalServicePresentationUseCase?
      _handleLocalServicePresentationUseCase;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DashboardShellPalette.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: DashboardShellPalette.accent,
      onPrimary: const Color(0xFF1A130F),
      secondary: DashboardShellPalette.success,
      onSecondary: DashboardShellPalette.paper,
      surface: DashboardShellPalette.paper,
      onSurface: DashboardShellPalette.ink,
      outline: DashboardShellPalette.outline,
      outlineVariant: DashboardShellPalette.outlineStrong,
    );

    return MaterialApp(
      title: 'SubWatch',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: DashboardShellPalette.canvas,
        splashFactory: InkRipple.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: DashboardShellPalette.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        iconTheme: const IconThemeData(
          color: DashboardShellPalette.ink,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.transparent,
        ),
        dividerColor: DashboardShellPalette.outline,
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: DashboardShellPalette.ink,
            disabledForegroundColor:
                DashboardShellPalette.mutedInk.withValues(alpha: 0.72),
            overlayColor: const Color(0x14E1A55A),
            highlightColor: const Color(0x10E1A55A),
            hoverColor: const Color(0x0DE1A55A),
            animationDuration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: DashboardShellPalette.paper.withValues(alpha: 0.98),
          indicatorColor: DashboardShellPalette.accentSoft,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 74,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelPadding: const EdgeInsets.only(top: 4),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? const Color(0x14E1A55A)
                : states.contains(WidgetState.hovered)
                    ? const Color(0x0DE1A55A)
                    : null,
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => baseTheme.textTheme.labelMedium?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? DashboardShellPalette.ink
                  : DashboardShellPalette.mutedInk,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w700,
              letterSpacing: 0.18,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? DashboardShellPalette.ink
                  : DashboardShellPalette.mutedInk,
              size: 24,
            ),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: DashboardShellPalette.elevatedPaper,
          surfaceTintColor: Colors.transparent,
          shadowColor: DashboardShellPalette.shadow,
          elevation: 0,
          position: PopupMenuPosition.under,
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
          ),
          textStyle: baseTheme.textTheme.bodyMedium?.copyWith(
            color: DashboardShellPalette.ink,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: DashboardShellPalette.elevatedPaper,
          contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
            color: DashboardShellPalette.ink,
            height: 1.35,
          ),
          actionTextColor: DashboardShellPalette.accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: DashboardShellPalette.accent,
            foregroundColor: const Color(0xFF1B140F),
            disabledBackgroundColor: DashboardShellPalette.outline,
            disabledForegroundColor: DashboardShellPalette.mutedInk,
            overlayColor: const Color(0x1FF7ECDD),
            animationDuration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DashboardShellPalette.ink,
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
            backgroundColor: DashboardShellPalette.elevatedPaper,
            overlayColor: const Color(0x14F7ECDD),
            animationDuration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DashboardShellPalette.accent,
            overlayColor: const Color(0x14E1A55A),
            animationDuration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DashboardShellPalette.accent,
        ),
        textTheme: baseTheme.textTheme.copyWith(
          headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.55,
          ),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.12,
          ),
          titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
            color: DashboardShellPalette.ink,
            height: 1.4,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
            color: DashboardShellPalette.ink,
            height: 1.38,
          ),
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
            color: DashboardShellPalette.mutedInk,
            height: 1.34,
          ),
          labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
            color: DashboardShellPalette.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.18,
          ),
          labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
            color: DashboardShellPalette.mutedInk,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.18,
          ),
          labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
            color: DashboardShellPalette.mutedInk,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.18,
          ),
        ),
      ),
      home: DashboardShell(
        runtimeUseCase:
            _runtimeUseCase ?? LoadRuntimeDashboardUseCase.persistent(),
        syncDeviceSmsUseCase:
            _syncDeviceSmsUseCase ?? SyncDeviceSmsUseCase.persistentAndroid(),
        handleReviewItemActionUseCase: _handleReviewItemActionUseCase ??
            HandleReviewItemActionUseCase.persistent(),
        undoReviewItemActionUseCase: _undoReviewItemActionUseCase ??
            UndoReviewItemActionUseCase.persistent(),
        handleLocalControlOverlayUseCase:
            _handleLocalControlOverlayUseCase ??
                HandleLocalControlOverlayUseCase.persistent(),
        undoLocalControlOverlayUseCase: _undoLocalControlOverlayUseCase ??
            UndoLocalControlOverlayUseCase.persistent(),
        handleLocalRenewalReminderUseCase:
            _handleLocalRenewalReminderUseCase ??
                HandleLocalRenewalReminderUseCase.persistent(),
        handleManualSubscriptionUseCase:
            _handleManualSubscriptionUseCase ??
                HandleManualSubscriptionUseCase.persistent(),
        handleLocalServicePresentationUseCase:
            _handleLocalServicePresentationUseCase ??
                HandleLocalServicePresentationUseCase.persistent(),
      ),
    );
  }
}
