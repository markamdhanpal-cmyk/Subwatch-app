import 'package:flutter/material.dart';

import '../application/contracts/problem_report_launcher.dart';
import '../application/use_cases/handle_local_control_overlay_use_case.dart';
import '../application/use_cases/handle_manual_subscription_use_case.dart';
import '../application/use_cases/handle_local_renewal_reminder_use_case.dart';
import '../application/use_cases/handle_local_service_presentation_use_case.dart';
import '../application/use_cases/handle_review_item_action_use_case.dart';
import '../application/use_cases/load_runtime_dashboard_use_case.dart';
import '../application/use_cases/load_sms_onboarding_progress_use_case.dart';
import '../application/use_cases/complete_sms_onboarding_use_case.dart';
import '../application/use_cases/clear_all_local_data_use_case.dart';
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
    LoadSmsOnboardingProgressUseCase? loadSmsOnboardingProgressUseCase,
    CompleteSmsOnboardingUseCase? completeSmsOnboardingUseCase,
    ClearAllLocalDataUseCase? clearAllLocalDataUseCase,
    ProblemReportLauncher? problemReportLauncher,
    TextScaler? textScaler,
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
        _loadSmsOnboardingProgressUseCase = loadSmsOnboardingProgressUseCase,
        _completeSmsOnboardingUseCase = completeSmsOnboardingUseCase,
        _clearAllLocalDataUseCase = clearAllLocalDataUseCase,
        _problemReportLauncher = problemReportLauncher,
        _textScaler = textScaler;

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
  final LoadSmsOnboardingProgressUseCase? _loadSmsOnboardingProgressUseCase;
  final CompleteSmsOnboardingUseCase? _completeSmsOnboardingUseCase;
  final ClearAllLocalDataUseCase? _clearAllLocalDataUseCase;
  final ProblemReportLauncher? _problemReportLauncher;
  final TextScaler? _textScaler;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Figtree',
    );
    const heroStyle = TextStyle(
      fontFamily: 'Instrument Serif',
      color: DashboardShellPalette.ink,
      fontSize: 46,
      fontWeight: FontWeight.w400,
      height: 0.92,
      letterSpacing: -1.35,
    );
    const metricStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 0.94,
      letterSpacing: -1.05,
    );
    const headingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 29,
      fontWeight: FontWeight.w700,
      height: 1.06,
      letterSpacing: -0.6,
    );
    const subheadingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.14,
      letterSpacing: -0.26,
    );
    const rowTitleStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.18,
      letterSpacing: -0.12,
    );
    const bodyStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.softInk,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.38,
      letterSpacing: -0.02,
    );
    const supportingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.mutedInk,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.32,
      letterSpacing: 0.02,
    );
    const labelStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.mutedInk,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: 0.3,
    );
    const buttonStyle = TextStyle(
      fontFamily: 'Figtree',
      color: DashboardShellPalette.paper,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0.16,
    );
    const typeScale = DashboardTypeScale(
      display: heroStyle,
      heading: headingStyle,
      subheading: subheadingStyle,
      body: bodyStyle,
      caption: supportingStyle,
      label: labelStyle,
      button: buttonStyle,
    );
    final colorScheme = const ColorScheme.dark(
      primary: DashboardShellPalette.accent,
      onPrimary: Color(0xFF1A120C),
      secondary: DashboardShellPalette.statusBlue,
      onSecondary: DashboardShellPalette.paper,
      error: DashboardShellPalette.caution,
      onError: DashboardShellPalette.paper,
      surface: DashboardShellPalette.paper,
      onSurface: DashboardShellPalette.ink,
    ).copyWith(
      primaryContainer: DashboardShellPalette.accentSoft,
      onPrimaryContainer: DashboardShellPalette.accent,
      secondaryContainer: DashboardShellPalette.nestedPaper,
      onSecondaryContainer: DashboardShellPalette.softInk,
      tertiary: DashboardShellPalette.success,
      onTertiary: DashboardShellPalette.paper,
      tertiaryContainer: DashboardShellPalette.successSoft,
      onTertiaryContainer: DashboardShellPalette.success,
      outline: DashboardShellPalette.outline,
      outlineVariant: DashboardShellPalette.divider,
      shadow: DashboardShellPalette.shadow,
      scrim: DashboardShellPalette.scrim,
    );

    return MaterialApp(
      title: 'SubWatch',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (_textScaler == null) return child!;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _textScaler,
          ),
          child: child!,
        );
      },
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
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 68,
        ),
        iconTheme: const IconThemeData(
          color: DashboardShellPalette.softInk,
          size: 22,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.transparent,
        ),
        dividerColor: DashboardShellPalette.divider,
        dividerTheme: const DividerThemeData(
          color: DashboardShellPalette.divider,
          thickness: 1,
          space: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: DashboardShellPalette.elevatedPaper,
          surfaceTintColor: Colors.transparent,
          shadowColor: DashboardShellPalette.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.card),
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
          ),
          titleTextStyle: subheadingStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: bodyStyle.copyWith(
            color: DashboardShellPalette.softInk,
            height: 1.42,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: DashboardShellPalette.softInk,
            backgroundColor: DashboardShellPalette.paper.withValues(alpha: 0.28),
            disabledForegroundColor:
                DashboardShellPalette.mutedInk.withValues(alpha: 0.72),
            overlayColor: DashboardShellPalette.accent.withValues(alpha: 0.12),
            highlightColor:
                DashboardShellPalette.accent.withValues(alpha: 0.08),
            hoverColor: DashboardShellPalette.accent.withValues(alpha: 0.06),
            animationDuration: dashboardMotionDuration,
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
              side: const BorderSide(color: DashboardShellPalette.outline),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: DashboardShellPalette.accent,
          foregroundColor: const Color(0xFF1A120C),
          elevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          splashColor: DashboardShellPalette.accentGlow.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x33FFF1DE)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: DashboardShellPalette.paper.withValues(alpha: 0.98),
          indicatorColor: DashboardShellPalette.accentSoft,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          labelPadding: const EdgeInsets.only(top: 4),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? DashboardShellPalette.accent.withValues(alpha: 0.1)
                : states.contains(WidgetState.hovered)
                    ? DashboardShellPalette.accent.withValues(alpha: 0.06)
                    : null,
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => labelStyle.copyWith(
              color: states.contains(WidgetState.selected)
                  ? DashboardShellPalette.accent
                  : DashboardShellPalette.faintInk,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w700,
              letterSpacing: 0.26,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? DashboardShellPalette.accent
                  : DashboardShellPalette.faintInk,
              size: 22,
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
            borderRadius: BorderRadius.circular(DashboardRadii.nested),
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
          ),
          textStyle: bodyStyle.copyWith(
            color: DashboardShellPalette.softInk,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: DashboardShellPalette.paper,
          contentTextStyle: bodyStyle.copyWith(
            color: DashboardShellPalette.ink,
            height: 1.36,
            fontWeight: FontWeight.w600,
          ),
          actionTextColor: DashboardShellPalette.accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: DashboardShellPalette.accent,
            foregroundColor: const Color(0xFF1A120C),
            disabledBackgroundColor: DashboardShellPalette.outline,
            disabledForegroundColor: DashboardShellPalette.mutedInk,
            overlayColor: DashboardShellPalette.accentGlow.withValues(alpha: 0.1),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
            ),
            textStyle: typeScale.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DashboardShellPalette.softInk,
            side: const BorderSide(color: DashboardShellPalette.outlineStrong),
            backgroundColor: DashboardShellPalette.nestedPaper.withValues(
              alpha: 0.88,
            ),
            overlayColor: DashboardShellPalette.accent.withValues(alpha: 0.08),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
            ),
            textStyle: typeScale.button.copyWith(
              color: DashboardShellPalette.softInk,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: DashboardShellPalette.softInk,
            overlayColor: DashboardShellPalette.accent.withValues(alpha: 0.08),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
            ),
            textStyle: typeScale.button.copyWith(
              color: DashboardShellPalette.softInk,
              fontSize: 13,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: DashboardShellPalette.nestedPaper,
          selectedColor: DashboardShellPalette.accentSoft,
          disabledColor: DashboardShellPalette.outline,
          secondarySelectedColor: DashboardShellPalette.accentSoft,
          side: const BorderSide(color: DashboardShellPalette.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.chip),
          ),
          labelStyle: labelStyle.copyWith(color: DashboardShellPalette.mutedInk),
          secondaryLabelStyle:
              labelStyle.copyWith(color: DashboardShellPalette.accent),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: DashboardShellPalette.accent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DashboardShellPalette.nestedPaper,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: bodyStyle.copyWith(
            color: DashboardShellPalette.faintInk,
          ),
          helperStyle: supportingStyle.copyWith(
            color: DashboardShellPalette.mutedInk,
            height: 1.22,
          ),
          labelStyle: labelStyle.copyWith(
            color: DashboardShellPalette.mutedInk,
          ),
          prefixIconColor: DashboardShellPalette.faintInk,
          suffixIconColor: DashboardShellPalette.faintInk,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: const BorderSide(color: DashboardShellPalette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: const BorderSide(color: DashboardShellPalette.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: const BorderSide(color: DashboardShellPalette.accent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: const BorderSide(color: DashboardShellPalette.caution),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: const BorderSide(color: DashboardShellPalette.caution),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: DashboardShellPalette.accent,
          selectionColor: DashboardShellPalette.accentSoft,
          selectionHandleColor: DashboardShellPalette.accent,
        ),
        textTheme: baseTheme.textTheme.copyWith(
          displayLarge: heroStyle,
          displayMedium: metricStyle,
          displaySmall: headingStyle,
          headlineLarge: headingStyle,
          headlineMedium: subheadingStyle,
          headlineSmall: headingStyle,
          titleLarge: subheadingStyle,
          titleMedium: rowTitleStyle,
          titleSmall: labelStyle.copyWith(
            color: DashboardShellPalette.softInk,
            fontSize: 13,
          ),
          bodyLarge: bodyStyle,
          bodyMedium: bodyStyle,
          bodySmall: supportingStyle,
          labelLarge: buttonStyle.copyWith(color: DashboardShellPalette.paper),
          labelMedium: labelStyle.copyWith(
            color: DashboardShellPalette.mutedInk,
          ),
          labelSmall: supportingStyle.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
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
        loadSmsOnboardingProgressUseCase: _loadSmsOnboardingProgressUseCase,
        completeSmsOnboardingUseCase: _completeSmsOnboardingUseCase,
        clearAllLocalDataUseCase: _clearAllLocalDataUseCase,
        problemReportLauncher: _problemReportLauncher,
      ),
    );
  }
}
