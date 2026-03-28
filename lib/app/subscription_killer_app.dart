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
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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

  ThemeData _buildTheme(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? DashboardColorTokens.dark
        : DashboardColorTokens.light;
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Figtree',
    );
    final heroStyle = TextStyle(
      fontFamily: 'Instrument Serif',
      color: colors.ink,
      fontSize: 46,
      fontWeight: FontWeight.w400,
      height: 0.92,
      letterSpacing: -1.35,
    );
    final metricStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.ink,
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 0.94,
      letterSpacing: -1.05,
    );
    final headingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.ink,
      fontSize: 29,
      fontWeight: FontWeight.w700,
      height: 1.06,
      letterSpacing: -0.6,
    );
    final subheadingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.ink,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.14,
      letterSpacing: -0.26,
    );
    final rowTitleStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.18,
      letterSpacing: -0.12,
    );
    final bodyStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.softInk,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.38,
      letterSpacing: -0.02,
    );
    final supportingStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.mutedInk,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.32,
      letterSpacing: 0.02,
    );
    final labelStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.mutedInk,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: 0.3,
    );
    final buttonStyle = TextStyle(
      fontFamily: 'Figtree',
      color: colors.accentInk,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: 0.16,
    );
    final typeScale = DashboardTypeScale(
      display: heroStyle,
      heading: headingStyle,
      subheading: subheadingStyle,
      body: bodyStyle,
      caption: supportingStyle,
      label: labelStyle,
      button: buttonStyle,
    );
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: colors.accent,
            onPrimary: colors.accentInk,
            secondary: colors.statusBlue,
            onSecondary: colors.ink,
            error: colors.caution,
            onError: colors.accentInk,
            surface: colors.paper,
            onSurface: colors.ink,
          )
        : ColorScheme.light(
            primary: colors.accent,
            onPrimary: colors.accentInk,
            secondary: colors.statusBlue,
            onSecondary: colors.ink,
            error: colors.caution,
            onError: colors.accentInk,
            surface: colors.paper,
            onSurface: colors.ink,
          );

    return baseTheme.copyWith(
        colorScheme: colorScheme.copyWith(
          primaryContainer: colors.accentSoft,
          onPrimaryContainer: colors.ink,
          secondaryContainer: colors.nestedPaper,
          onSecondaryContainer: colors.softInk,
          tertiary: colors.success,
          onTertiary: colors.accentInk,
          tertiaryContainer: colors.successSoft,
          onTertiaryContainer: colors.success,
          outline: colors.outline,
          outlineVariant: colors.divider,
          shadow: colors.shadow,
          scrim: colors.scrim,
        ),
        scaffoldBackgroundColor: colors.canvas,
        canvasColor: colors.paper,
        splashFactory: InkRipple.splashFactory,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 68,
        ),
        iconTheme: IconThemeData(
          color: colors.softInk,
          size: 22,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.transparent,
        ),
        dividerColor: colors.divider,
        dividerTheme: DividerThemeData(
          color: colors.divider,
          thickness: 1,
          space: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colors.elevatedPaper,
          surfaceTintColor: Colors.transparent,
          shadowColor: colors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.card),
            side: BorderSide(color: colors.outlineStrong),
          ),
          titleTextStyle: subheadingStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          contentTextStyle: bodyStyle.copyWith(
            color: colors.softInk,
            height: 1.42,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: colors.softInk,
            backgroundColor: colors.paper.withValues(alpha: 0.92),
            disabledForegroundColor: colors.mutedInk.withValues(alpha: 0.72),
            overlayColor: colors.accent.withValues(alpha: 0.12),
            highlightColor: colors.accent.withValues(alpha: 0.08),
            hoverColor: colors.accent.withValues(alpha: 0.06),
            animationDuration: dashboardMotionDuration,
            padding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
              side: BorderSide(color: colors.outline),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentInk,
          elevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          splashColor: colors.accentGlow.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: colors.accent.withValues(alpha: 0.24),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colors.paper.withValues(alpha: 0.94),
          indicatorColor: colors.accentSoft,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          labelPadding: const EdgeInsets.only(top: 4),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colors.accent.withValues(alpha: 0.1)
                : states.contains(WidgetState.hovered)
                    ? colors.accent.withValues(alpha: 0.06)
                    : null,
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => labelStyle.copyWith(
              color: states.contains(WidgetState.selected)
                  ? colors.accent
                  : colors.faintInk,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w700,
              letterSpacing: 0.26,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colors.accent
                  : colors.faintInk,
              size: 22,
            ),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: colors.elevatedPaper,
          surfaceTintColor: Colors.transparent,
          shadowColor: colors.shadow,
          elevation: 0,
          position: PopupMenuPosition.under,
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.nested),
            side: BorderSide(color: colors.outlineStrong),
          ),
          textStyle: bodyStyle.copyWith(
            color: colors.softInk,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.elevatedPaper,
          contentTextStyle: bodyStyle.copyWith(
            color: colors.ink,
            height: 1.36,
            fontWeight: FontWeight.w600,
          ),
          actionTextColor: colors.accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            side: BorderSide(color: colors.outlineStrong),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.accentInk,
            disabledBackgroundColor: colors.outline,
            disabledForegroundColor: colors.mutedInk,
            overlayColor: colors.accentGlow.withValues(alpha: 0.1),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, DashboardActionRhythm.regularHeight),
            padding: DashboardActionRhythm.regularPadding,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
              side: BorderSide(
                color: colors.accent.withValues(alpha: 0.28),
              ),
            ),
            textStyle: typeScale.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.softInk,
            side: BorderSide(color: colors.outlineStrong),
            backgroundColor: colors.paper.withValues(
              alpha: 0.88,
            ),
            overlayColor: colors.accent.withValues(alpha: 0.08),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, DashboardActionRhythm.regularHeight),
            padding: DashboardActionRhythm.regularPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
            ),
            textStyle: typeScale.button.copyWith(
              color: colors.softInk,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colors.softInk,
            overlayColor: colors.accent.withValues(alpha: 0.08),
            animationDuration: dashboardMotionDuration,
            minimumSize: const Size(0, DashboardActionRhythm.quietHeight),
            padding: DashboardActionRhythm.quietPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardRadii.button),
            ),
            textStyle: typeScale.button.copyWith(
              color: colors.softInk,
              fontSize: 13,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: colors.nestedPaper,
          selectedColor: colors.accentSoft,
          disabledColor: colors.outline,
          secondarySelectedColor: colors.accentSoft,
          side: BorderSide(color: colors.outlineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.chip),
          ),
          labelStyle: labelStyle.copyWith(color: colors.mutedInk),
          secondaryLabelStyle: labelStyle.copyWith(color: colors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: colors.accent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.nestedPaper,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: bodyStyle.copyWith(
            color: colors.faintInk,
          ),
          helperStyle: supportingStyle.copyWith(
            color: colors.mutedInk,
            height: 1.22,
          ),
          labelStyle: labelStyle.copyWith(
            color: colors.mutedInk,
          ),
          prefixIconColor: colors.faintInk,
          suffixIconColor: colors.faintInk,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: BorderSide(color: colors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: BorderSide(color: colors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: BorderSide(color: colors.accent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: BorderSide(color: colors.caution),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DashboardRadii.button),
            borderSide: BorderSide(color: colors.caution),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colors.accent,
          selectionColor: colors.accentSoft,
          selectionHandleColor: colors.accent,
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
            color: colors.softInk,
            fontSize: 13,
          ),
          bodyLarge: bodyStyle,
          bodyMedium: bodyStyle,
          bodySmall: supportingStyle,
          labelLarge: buttonStyle.copyWith(color: colors.accentInk),
          labelMedium: labelStyle.copyWith(
            color: colors.mutedInk,
          ),
          labelSmall: supportingStyle.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          typeScale,
          colors,
        ],
      );
  }
}
