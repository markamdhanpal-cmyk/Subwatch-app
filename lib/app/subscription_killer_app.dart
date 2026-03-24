import 'package:flutter/material.dart';

import '../application/contracts/problem_report_launcher.dart';
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
    ProblemReportLauncher? problemReportLauncher,
  })  : _runtimeUseCase = runtimeUseCase,
        _syncDeviceSmsUseCase = syncDeviceSmsUseCase,
        _handleReviewItemActionUseCase = handleReviewItemActionUseCase,
        _undoReviewItemActionUseCase = undoReviewItemActionUseCase,
        _handleLocalControlOverlayUseCase = handleLocalControlOverlayUseCase,
        _undoLocalControlOverlayUseCase = undoLocalControlOverlayUseCase,
        _handleLocalRenewalReminderUseCase = handleLocalRenewalReminderUseCase,
        _handleManualSubscriptionUseCase = handleManualSubscriptionUseCase,
        _handleLocalServicePresentationUseCase =
            handleLocalServicePresentationUseCase,
        _problemReportLauncher = problemReportLauncher;

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
  final ProblemReportLauncher? _problemReportLauncher;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Figtree',
    );
    const displayStyle = TextStyle(
      fontFamily: 'Instrument Serif',
      color: DashboardShellPalette.ink,
      fontSize: 40,
      fontWeight: FontWeight.w400,
      height: 0.95,
      letterSpacing: -1.1,
    );
    const headingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -0.28,
    );
    const subheadingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.16,
    );
    const bodyStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    const captionStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.mutedInk,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.28,
      letterSpacing: 0.04,
    );
    const labelStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.16,
      letterSpacing: 0.12,
    );
    const buttonStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0.08,
    );
    const typeScale = DashboardTypeScale(
      display: displayStyle,
      heading: headingStyle,
      subheading: subheadingStyle,
      body: bodyStyle,
      caption: captionStyle,
      label: labelStyle,
      button: buttonStyle,
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
            overlayColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.14),
            highlightColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.1),
            hoverColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.08),
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
                ? DashboardShellPalette.mutedInk.withValues(alpha: 0.1)
                : states.contains(WidgetState.hovered)
                    ? DashboardShellPalette.mutedInk.withValues(alpha: 0.06)
                    : null,
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => baseTheme.textTheme.labelMedium?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? DashboardShellPalette.accent
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
                  ? DashboardShellPalette.accent
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
          actionTextColor: DashboardShellPalette.statusBlue,
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
            textStyle: typeScale.button,
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
            textStyle: typeScale.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DashboardShellPalette.statusBlue,
            overlayColor:
                DashboardShellPalette.statusBlue.withValues(alpha: 0.14),
            animationDuration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: typeScale.button,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DashboardShellPalette.statusBlue,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DashboardShellPalette.nestedPaper,
          hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
            color: DashboardShellPalette.mutedInk.withValues(alpha: 0.84),
          ),
          helperStyle: baseTheme.textTheme.bodySmall?.copyWith(
            color: DashboardShellPalette.mutedInk,
            height: 1.22,
          ),
          labelStyle: baseTheme.textTheme.labelMedium?.copyWith(
            color: DashboardShellPalette.mutedInk,
          ),
          prefixIconColor: DashboardShellPalette.mutedInk,
          suffixIconColor: DashboardShellPalette.mutedInk,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: DashboardShellPalette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: DashboardShellPalette.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: DashboardShellPalette.statusBlue,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: DashboardShellPalette.caution),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: DashboardShellPalette.caution),
          ),
        ),
        textTheme: baseTheme.textTheme.copyWith(
          displayLarge: displayStyle,
          displayMedium: headingStyle,
          displaySmall: headingStyle,
          headlineLarge: headingStyle,
          headlineMedium: subheadingStyle,
          headlineSmall: headingStyle,
          titleLarge: headingStyle,
          titleMedium: subheadingStyle,
          titleSmall: subheadingStyle,
          bodyLarge: bodyStyle,
          bodyMedium: bodyStyle,
          bodySmall: captionStyle,
          labelLarge: labelStyle,
          labelMedium: labelStyle.copyWith(
            color: DashboardShellPalette.mutedInk,
          ),
          labelSmall: captionStyle.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14,
          ),
        ),
        extensions: const <ThemeExtension<dynamic>>[
          typeScale,
        ],
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
        problemReportLauncher: _problemReportLauncher,
      ),
    );
  }
}
