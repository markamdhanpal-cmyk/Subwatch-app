import 'package:flutter/material.dart';

import 'service_icon_registry.dart';

const Duration dashboardMotionDuration = Duration(milliseconds: 160);
const Duration dashboardEntranceDuration = Duration(milliseconds: 240);
const Duration dashboardSheetMotionDuration = Duration(milliseconds: 280);
const Duration dashboardSheetReverseDuration = Duration(milliseconds: 220);

class DashboardSpacing {
  static const double micro = 4;
  static const double xSmall = 8;
  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
  static const double xLarge = 24;
  static const double xxLarge = 32;
  static const double screenBlockGap = 18;
  static const double compactSectionGap = 20;
  static const double sectionGap = 28;
  static const double sectionHeaderGap = 12;
  static const double rowGap = 14;

  static const EdgeInsets screenInset = EdgeInsets.fromLTRB(20, 16, 20, 28);
  static const EdgeInsets secondaryScreenInset =
      EdgeInsets.fromLTRB(16, 12, 16, 32);
  static const EdgeInsets secondaryScreenInsetWithBottomNav =
      EdgeInsets.fromLTRB(16, 12, 16, 120);
}

class DashboardRadii {
  static const double chip = 14;
  static const double button = 18;
  static const double nested = 20;
  static const double card = 26;
  static const double prominentCard = 30;
  static const double sheet = 32;
  static const double avatar = 16;
}

class DashboardShellPalette {
  static const Color canvas = Color(0xFFF7EEE3);
  static const Color canvasRaised = Color(0xFFFFF8F1);
  static const Color paper = Color(0xFFFFFCF8);
  static const Color elevatedPaper = Color(0xFFFFF5EC);
  static const Color nestedPaper = Color(0xFFF6E8DA);
  static const Color registerPaper = Color(0xFFFBEFE2);
  static const Color ink = Color(0xFF201813);
  static const Color softInk = Color(0xFF493A2F);
  static const Color mutedInk = Color(0xFF7A6657);
  static const Color faintInk = Color(0xFFA48C79);
  static const Color accent = Color(0xFFF09A49);
  static const Color accentSoft = Color(0xFFFFE2C8);
  static const Color accentGlow = Color(0xFFFFBD80);
  static const Color accentInk = Color(0xFF2A180C);
  static const Color statusBlue = Color(0xFF2A8CB5);
  static const Color statusBlueSoft = Color(0xFFD9EEF6);
  static const Color benefitGold = Color(0xFFC6A14D);
  static const Color benefitGoldSoft = Color(0xFFF9EDCD);
  static const Color success = Color(0xFF3C9D72);
  static const Color successSoft = Color(0xFFDFF3E7);
  static const Color caution = Color(0xFFD96F4C);
  static const Color cautionSoft = Color(0xFFFBE4DB);
  static const Color recovery = Color(0xFF6C86A9);
  static const Color recoverySoft = Color(0xFFE4EDF8);
  static const Color outline = Color(0xFFE3D2C2);
  static const Color outlineStrong = Color(0xFFD3BBA8);
  static const Color divider = Color(0xFFEFDFD2);
  static const Color scrim = Color(0x99533B2A);
  static const Color shadow = Color(0x1F724122);
}

@immutable
class DashboardColorTokens extends ThemeExtension<DashboardColorTokens> {
  const DashboardColorTokens({
    required this.canvas,
    required this.canvasRaised,
    required this.paper,
    required this.elevatedPaper,
    required this.nestedPaper,
    required this.registerPaper,
    required this.ink,
    required this.softInk,
    required this.mutedInk,
    required this.faintInk,
    required this.accent,
    required this.accentSoft,
    required this.accentGlow,
    required this.accentInk,
    required this.statusBlue,
    required this.statusBlueSoft,
    required this.benefitGold,
    required this.benefitGoldSoft,
    required this.success,
    required this.successSoft,
    required this.caution,
    required this.cautionSoft,
    required this.recovery,
    required this.recoverySoft,
    required this.outline,
    required this.outlineStrong,
    required this.divider,
    required this.scrim,
    required this.shadow,
    required this.trustSurfaceStart,
    required this.backdropTop,
    required this.backdropBottom,
    required this.glowAccent,
    required this.glowInfo,
    required this.glowWarm,
  });

  static const DashboardColorTokens light = DashboardColorTokens(
    canvas: Color(0xFFF7EEE3),
    canvasRaised: Color(0xFFFFF8F1),
    paper: Color(0xFFFFFCF8),
    elevatedPaper: Color(0xFFFFF5EC),
    nestedPaper: Color(0xFFF6E8DA),
    registerPaper: Color(0xFFFBEFE2),
    ink: Color(0xFF201813),
    softInk: Color(0xFF493A2F),
    mutedInk: Color(0xFF7A6657),
    faintInk: Color(0xFFA48C79),
    accent: Color(0xFFF09A49),
    accentSoft: Color(0xFFFFE2C8),
    accentGlow: Color(0xFFFFBD80),
    accentInk: Color(0xFF2A180C),
    statusBlue: Color(0xFF2A8CB5),
    statusBlueSoft: Color(0xFFD9EEF6),
    benefitGold: Color(0xFFC6A14D),
    benefitGoldSoft: Color(0xFFF9EDCD),
    success: Color(0xFF3C9D72),
    successSoft: Color(0xFFDFF3E7),
    caution: Color(0xFFD96F4C),
    cautionSoft: Color(0xFFFBE4DB),
    recovery: Color(0xFF6C86A9),
    recoverySoft: Color(0xFFE4EDF8),
    outline: Color(0xFFE3D2C2),
    outlineStrong: Color(0xFFD3BBA8),
    divider: Color(0xFFEFDFD2),
    scrim: Color(0x99533B2A),
    shadow: Color(0x1F724122),
    trustSurfaceStart: Color(0xFFEAF6FA),
    backdropTop: Color(0xFFFFFBF5),
    backdropBottom: Color(0xFFF1E0D1),
    glowAccent: Color(0xFFFFB476),
    glowInfo: Color(0xFF8CCFCA),
    glowWarm: Color(0xFFFFD88A),
  );

  static const DashboardColorTokens dark = DashboardColorTokens(
    canvas: Color(0xFF0B0F17),
    canvasRaised: Color(0xFF101623),
    paper: Color(0xFF151B28),
    elevatedPaper: Color(0xFF1A2232),
    nestedPaper: Color(0xFF212B3D),
    registerPaper: Color(0xFF1B2536),
    ink: Color(0xFFF7F8FC),
    softInk: Color(0xFFDCE2F0),
    mutedInk: Color(0xFFA5B0C5),
    faintInk: Color(0xFF7D88A0),
    accent: Color(0xFFFFA75A),
    accentSoft: Color(0xFF3A2618),
    accentGlow: Color(0xFFFFC47E),
    accentInk: Color(0xFF1C120C),
    statusBlue: Color(0xFF6BCBFF),
    statusBlueSoft: Color(0xFF182D41),
    benefitGold: Color(0xFFE5C46D),
    benefitGoldSoft: Color(0xFF372B13),
    success: Color(0xFF5CD39B),
    successSoft: Color(0xFF183627),
    caution: Color(0xFFFF8E6E),
    cautionSoft: Color(0xFF3E211B),
    recovery: Color(0xFFA6BEFF),
    recoverySoft: Color(0xFF202A42),
    outline: Color(0xFF313C52),
    outlineStrong: Color(0xFF46516C),
    divider: Color(0xFF232C3F),
    scrim: Color(0xC005070D),
    shadow: Color(0x8A000000),
    trustSurfaceStart: Color(0xFF142A3D),
    backdropTop: Color(0xFF0F1420),
    backdropBottom: Color(0xFF090D15),
    glowAccent: Color(0xFFFF8B38),
    glowInfo: Color(0xFF2DB8FF),
    glowWarm: Color(0xFFFFD56C),
  );

  final Color canvas;
  final Color canvasRaised;
  final Color paper;
  final Color elevatedPaper;
  final Color nestedPaper;
  final Color registerPaper;
  final Color ink;
  final Color softInk;
  final Color mutedInk;
  final Color faintInk;
  final Color accent;
  final Color accentSoft;
  final Color accentGlow;
  final Color accentInk;
  final Color statusBlue;
  final Color statusBlueSoft;
  final Color benefitGold;
  final Color benefitGoldSoft;
  final Color success;
  final Color successSoft;
  final Color caution;
  final Color cautionSoft;
  final Color recovery;
  final Color recoverySoft;
  final Color outline;
  final Color outlineStrong;
  final Color divider;
  final Color scrim;
  final Color shadow;
  final Color trustSurfaceStart;
  final Color backdropTop;
  final Color backdropBottom;
  final Color glowAccent;
  final Color glowInfo;
  final Color glowWarm;

  @override
  DashboardColorTokens copyWith({
    Color? canvas,
    Color? canvasRaised,
    Color? paper,
    Color? elevatedPaper,
    Color? nestedPaper,
    Color? registerPaper,
    Color? ink,
    Color? softInk,
    Color? mutedInk,
    Color? faintInk,
    Color? accent,
    Color? accentSoft,
    Color? accentGlow,
    Color? accentInk,
    Color? statusBlue,
    Color? statusBlueSoft,
    Color? benefitGold,
    Color? benefitGoldSoft,
    Color? success,
    Color? successSoft,
    Color? caution,
    Color? cautionSoft,
    Color? recovery,
    Color? recoverySoft,
    Color? outline,
    Color? outlineStrong,
    Color? divider,
    Color? scrim,
    Color? shadow,
    Color? trustSurfaceStart,
    Color? backdropTop,
    Color? backdropBottom,
    Color? glowAccent,
    Color? glowInfo,
    Color? glowWarm,
  }) {
    return DashboardColorTokens(
      canvas: canvas ?? this.canvas,
      canvasRaised: canvasRaised ?? this.canvasRaised,
      paper: paper ?? this.paper,
      elevatedPaper: elevatedPaper ?? this.elevatedPaper,
      nestedPaper: nestedPaper ?? this.nestedPaper,
      registerPaper: registerPaper ?? this.registerPaper,
      ink: ink ?? this.ink,
      softInk: softInk ?? this.softInk,
      mutedInk: mutedInk ?? this.mutedInk,
      faintInk: faintInk ?? this.faintInk,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentGlow: accentGlow ?? this.accentGlow,
      accentInk: accentInk ?? this.accentInk,
      statusBlue: statusBlue ?? this.statusBlue,
      statusBlueSoft: statusBlueSoft ?? this.statusBlueSoft,
      benefitGold: benefitGold ?? this.benefitGold,
      benefitGoldSoft: benefitGoldSoft ?? this.benefitGoldSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      caution: caution ?? this.caution,
      cautionSoft: cautionSoft ?? this.cautionSoft,
      recovery: recovery ?? this.recovery,
      recoverySoft: recoverySoft ?? this.recoverySoft,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      divider: divider ?? this.divider,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
      trustSurfaceStart: trustSurfaceStart ?? this.trustSurfaceStart,
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      glowAccent: glowAccent ?? this.glowAccent,
      glowInfo: glowInfo ?? this.glowInfo,
      glowWarm: glowWarm ?? this.glowWarm,
    );
  }

  @override
  DashboardColorTokens lerp(
    covariant ThemeExtension<DashboardColorTokens>? other,
    double t,
  ) {
    if (other is! DashboardColorTokens) {
      return this;
    }
    return DashboardColorTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      canvasRaised: Color.lerp(canvasRaised, other.canvasRaised, t) ?? canvasRaised,
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      elevatedPaper: Color.lerp(elevatedPaper, other.elevatedPaper, t) ?? elevatedPaper,
      nestedPaper: Color.lerp(nestedPaper, other.nestedPaper, t) ?? nestedPaper,
      registerPaper: Color.lerp(registerPaper, other.registerPaper, t) ?? registerPaper,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      softInk: Color.lerp(softInk, other.softInk, t) ?? softInk,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t) ?? mutedInk,
      faintInk: Color.lerp(faintInk, other.faintInk, t) ?? faintInk,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t) ?? accentGlow,
      accentInk: Color.lerp(accentInk, other.accentInk, t) ?? accentInk,
      statusBlue: Color.lerp(statusBlue, other.statusBlue, t) ?? statusBlue,
      statusBlueSoft: Color.lerp(statusBlueSoft, other.statusBlueSoft, t) ?? statusBlueSoft,
      benefitGold: Color.lerp(benefitGold, other.benefitGold, t) ?? benefitGold,
      benefitGoldSoft: Color.lerp(benefitGoldSoft, other.benefitGoldSoft, t) ?? benefitGoldSoft,
      success: Color.lerp(success, other.success, t) ?? success,
      successSoft: Color.lerp(successSoft, other.successSoft, t) ?? successSoft,
      caution: Color.lerp(caution, other.caution, t) ?? caution,
      cautionSoft: Color.lerp(cautionSoft, other.cautionSoft, t) ?? cautionSoft,
      recovery: Color.lerp(recovery, other.recovery, t) ?? recovery,
      recoverySoft: Color.lerp(recoverySoft, other.recoverySoft, t) ?? recoverySoft,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t) ?? outlineStrong,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      scrim: Color.lerp(scrim, other.scrim, t) ?? scrim,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      trustSurfaceStart: Color.lerp(trustSurfaceStart, other.trustSurfaceStart, t) ?? trustSurfaceStart,
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t) ?? backdropTop,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t) ?? backdropBottom,
      glowAccent: Color.lerp(glowAccent, other.glowAccent, t) ?? glowAccent,
      glowInfo: Color.lerp(glowInfo, other.glowInfo, t) ?? glowInfo,
      glowWarm: Color.lerp(glowWarm, other.glowWarm, t) ?? glowWarm,
    );
  }
}

extension DashboardColorTokensContext on BuildContext {
  DashboardColorTokens get dashboardColors =>
      Theme.of(this).extension<DashboardColorTokens>()!;
}

enum DashboardPanelTone {
  base,
  elevated,
  inset,
  accent,
  trust,
}

enum DashboardPanelElevation {
  flat,
  raised,
  prominent,
}

enum DashboardBadgeTone {
  info,
  neutral,
  accent,
  success,
  caution,
  recovery,
  benefit,
}

enum DashboardIconSurfaceTone {
  neutral,
  accent,
  info,
  success,
  caution,
  benefit,
}

enum DashboardEmptyStateTone {
  neutral,
  success,
  trust,
  accent,
}

class DashboardGradients {
  static LinearGradient elevatedSurface(DashboardColorTokens colors) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colors.paper,
          colors.elevatedPaper,
        ],
      );

  static LinearGradient insetSurface(DashboardColorTokens colors) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          colors.paper,
          colors.nestedPaper,
        ],
      );

  static LinearGradient accentSurface(DashboardColorTokens colors) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colors.accentSoft,
          colors.paper,
        ],
      );

  static LinearGradient trustSurface(DashboardColorTokens colors) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colors.trustSurfaceStart,
          colors.paper,
        ],
      );
}

class DashboardListRowRhythm {
  static const double minHeight = 68;
  static const double leadingSize = 38;
  static const double leadingRadius = 14;
  static const double leadingIconSize = 18;
  static const double gap = 12;
  static const double leadingContentInset = leadingSize + gap;
  static const double dividerInset = 16;
  static const EdgeInsets verticalPadding =
      EdgeInsets.symmetric(vertical: 13);
}

class DashboardActionRhythm {
  static const double regularHeight = 52;
  static const double compactHeight = 46;
  static const double quietHeight = 44;
  static const EdgeInsets regularPadding =
      EdgeInsets.symmetric(horizontal: 18, vertical: 15);
  static const EdgeInsets compactPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets quietPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);
}

@immutable
class DashboardTypeScale extends ThemeExtension<DashboardTypeScale> {
  const DashboardTypeScale({
    required this.display,
    required this.heading,
    required this.subheading,
    required this.body,
    required this.caption,
    required this.label,
    required this.button,
  });

  final TextStyle display;
  final TextStyle heading;
  final TextStyle subheading;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle label;
  final TextStyle button;

  @override
  DashboardTypeScale copyWith({
    TextStyle? display,
    TextStyle? heading,
    TextStyle? subheading,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? button,
  }) {
    return DashboardTypeScale(
      display: display ?? this.display,
      heading: heading ?? this.heading,
      subheading: subheading ?? this.subheading,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      label: label ?? this.label,
      button: button ?? this.button,
    );
  }

  @override
  DashboardTypeScale lerp(
    covariant ThemeExtension<DashboardTypeScale>? other,
    double t,
  ) {
    if (other is! DashboardTypeScale) {
      return this;
    }

    return DashboardTypeScale(
      display: TextStyle.lerp(display, other.display, t) ?? display,
      heading: TextStyle.lerp(heading, other.heading, t) ?? heading,
      subheading: TextStyle.lerp(subheading, other.subheading, t) ?? subheading,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      label: TextStyle.lerp(label, other.label, t) ?? label,
      button: TextStyle.lerp(button, other.button, t) ?? button,
    );
  }
}

extension DashboardTypeScaleContext on BuildContext {
  DashboardTypeScale get dashboardType =>
      Theme.of(this).extension<DashboardTypeScale>()!;
}

extension DashboardSemanticTypeScale on DashboardTypeScale {
  TextStyle get hero => display;
  TextStyle get screenTitle => heading;
  TextStyle get sectionTitle => subheading;
  TextStyle get rowTitle => body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.14,
      );
  TextStyle get supporting => caption;
  TextStyle get meta => label.copyWith(fontWeight: FontWeight.w700);
  TextStyle get badge => label.copyWith(fontWeight: FontWeight.w700);
}

class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.backdropTop,
            colors.canvasRaised,
            colors.canvas,
            colors.backdropBottom,
          ],
          stops: <double>[0, 0.2, 0.68, 1],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _BackdropGlow(
              size: 240,
              color: colors.glowAccent,
            ),
          ),
          Positioned(
            top: 100,
            left: -90,
            child: _BackdropGlow(
              size: 180,
              color: colors.glowInfo,
            ),
          ),
          Positioned(
            bottom: -140,
            left: 30,
            child: _BackdropGlow(
              size: 210,
              color: colors.glowWarm,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DashboardSpacing.large),
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.radius = DashboardRadii.card,
    this.tone = DashboardPanelTone.base,
    this.elevation = DashboardPanelElevation.raised,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final DashboardPanelTone tone;
  final DashboardPanelElevation elevation;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    final colors = context.dashboardColors;
    final resolvedGradient = gradient ?? _gradientForTone(tone, colors);
    final resolvedBackground = resolvedGradient == null
        ? backgroundColor ?? _backgroundForTone(tone, colors)
        : null;
    final resolvedBorderColor = borderColor ?? _borderColorForTone(tone, colors);
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : dashboardMotionDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: resolvedBackground,
        gradient: resolvedGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: resolvedBorderColor
              .withValues(alpha: 0.94),
        ),
        boxShadow: _shadowForElevation(elevation, colors),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  static Gradient? _gradientForTone(
    DashboardPanelTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardPanelTone.base => null,
        DashboardPanelTone.elevated => DashboardGradients.elevatedSurface(colors),
        DashboardPanelTone.inset => DashboardGradients.insetSurface(colors),
        DashboardPanelTone.accent => DashboardGradients.accentSurface(colors),
        DashboardPanelTone.trust => DashboardGradients.trustSurface(colors),
      };

  static Color _backgroundForTone(
    DashboardPanelTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardPanelTone.base => colors.paper,
        DashboardPanelTone.elevated => colors.elevatedPaper,
        DashboardPanelTone.inset => colors.nestedPaper,
        DashboardPanelTone.accent => colors.accentSoft,
        DashboardPanelTone.trust => colors.trustSurfaceStart,
      };

  static Color _borderColorForTone(
    DashboardPanelTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardPanelTone.base => colors.outlineStrong,
        DashboardPanelTone.elevated => colors.outlineStrong,
        DashboardPanelTone.inset => colors.outlineStrong,
        DashboardPanelTone.accent => colors.accent.withValues(alpha: 0.32),
        DashboardPanelTone.trust => colors.statusBlue.withValues(alpha: 0.28),
      };

  static List<BoxShadow> _shadowForElevation(
    DashboardPanelElevation elevation,
    DashboardColorTokens colors,
  ) =>
      switch (elevation) {
        DashboardPanelElevation.flat => const <BoxShadow>[],
        DashboardPanelElevation.raised => <BoxShadow>[
            BoxShadow(
              color: colors.accentGlow.withValues(alpha: 0.16),
              blurRadius: 36,
              spreadRadius: -26,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.7),
              blurRadius: 24,
              spreadRadius: -18,
              offset: const Offset(0, 12),
            ),
          ],
        DashboardPanelElevation.prominent => <BoxShadow>[
            BoxShadow(
              color: colors.accentGlow.withValues(alpha: 0.22),
              blurRadius: 44,
              spreadRadius: -28,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.82),
              blurRadius: 30,
              spreadRadius: -18,
              offset: const Offset(0, 14),
            ),
          ],
      };
}

class DashboardBadge extends StatelessWidget {
  const DashboardBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = DashboardBadgeTone.info,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final DashboardBadgeTone tone;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    final resolvedBackground =
        backgroundColor ?? _backgroundForTone(tone, colors);
    final resolvedForeground =
        foregroundColor ?? _foregroundForTone(tone, colors);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardSpacing.xSmall + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(DashboardRadii.chip),
        border: Border.all(
          color: resolvedForeground.withValues(alpha: 0.24),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (icon != null)
            Icon(icon, size: 12, color: resolvedForeground),
          Text(
            label,
            style: type.badge.copyWith(
                  color: resolvedForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.18,
                ),
          ),
        ],
      ),
    );
  }

  static Color _backgroundForTone(
    DashboardBadgeTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardBadgeTone.info => colors.statusBlueSoft,
        DashboardBadgeTone.neutral => colors.nestedPaper,
        DashboardBadgeTone.accent => colors.accentSoft,
        DashboardBadgeTone.success => colors.successSoft,
        DashboardBadgeTone.caution => colors.cautionSoft,
        DashboardBadgeTone.recovery => colors.recoverySoft,
        DashboardBadgeTone.benefit => colors.benefitGoldSoft,
      };

  static Color _foregroundForTone(
    DashboardBadgeTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardBadgeTone.info => colors.statusBlue,
        DashboardBadgeTone.neutral => colors.softInk,
        DashboardBadgeTone.accent => colors.accent,
        DashboardBadgeTone.success => colors.success,
        DashboardBadgeTone.caution => colors.caution,
        DashboardBadgeTone.recovery => colors.recovery,
        DashboardBadgeTone.benefit => colors.benefitGold,
      };
}

class DashboardIconSurface extends StatelessWidget {
  const DashboardIconSurface({
    super.key,
    required this.icon,
    this.tone = DashboardIconSurfaceTone.neutral,
    this.size = DashboardListRowRhythm.leadingSize,
    this.iconSize = DashboardListRowRhythm.leadingIconSize,
    this.radius = DashboardListRowRhythm.leadingRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final IconData icon;
  final DashboardIconSurfaceTone tone;
  final double size;
  final double iconSize;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    final resolvedBackground =
        backgroundColor ?? _backgroundForTone(tone, colors);
    final resolvedForeground =
        foregroundColor ?? _foregroundForTone(tone, colors);
    final resolvedBorder = borderColor ?? _borderForTone(tone, colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: resolvedBorder,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: resolvedForeground,
        size: iconSize,
      ),
    );
  }

  static Color _backgroundForTone(
    DashboardIconSurfaceTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardIconSurfaceTone.neutral => colors.nestedPaper,
        DashboardIconSurfaceTone.accent => colors.accentSoft,
        DashboardIconSurfaceTone.info => colors.statusBlueSoft,
        DashboardIconSurfaceTone.success => colors.successSoft,
        DashboardIconSurfaceTone.caution => colors.cautionSoft,
        DashboardIconSurfaceTone.benefit => colors.benefitGoldSoft,
      };

  static Color _foregroundForTone(
    DashboardIconSurfaceTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardIconSurfaceTone.neutral => colors.softInk,
        DashboardIconSurfaceTone.accent => colors.accent,
        DashboardIconSurfaceTone.info => colors.statusBlue,
        DashboardIconSurfaceTone.success => colors.success,
        DashboardIconSurfaceTone.caution => colors.caution,
        DashboardIconSurfaceTone.benefit => colors.benefitGold,
      };

  static Color _borderForTone(
    DashboardIconSurfaceTone tone,
    DashboardColorTokens colors,
  ) =>
      switch (tone) {
        DashboardIconSurfaceTone.neutral => colors.outline,
        DashboardIconSurfaceTone.accent => colors.accent.withValues(alpha: 0.28),
        DashboardIconSurfaceTone.info =>
          colors.statusBlue.withValues(alpha: 0.26),
        DashboardIconSurfaceTone.success =>
          colors.success.withValues(alpha: 0.24),
        DashboardIconSurfaceTone.caution =>
          colors.caution.withValues(alpha: 0.24),
        DashboardIconSurfaceTone.benefit =>
          colors.benefitGold.withValues(alpha: 0.24),
      };
}

class DashboardServiceAvatar extends StatelessWidget {
  const DashboardServiceAvatar({
    super.key,
    required this.monogram,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    this.serviceKey,
    this.sealColor,
    this.size = 44,
  });

  final String monogram;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final String? serviceKey;
  final Color? sealColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final brandEntry =
        serviceKey == null ? null : ServiceIconRegistry.lookup(serviceKey!);

    final effectiveBackground =
        brandEntry?.brandColor ?? backgroundColor;
    final effectiveForeground =
        brandEntry?.glyphColor ?? foregroundColor;
    final effectiveMonogram = brandEntry?.glyph ?? monogram;
    final effectiveBorder = brandEntry != null
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08),
            effectiveBackground,
          )
        : borderColor;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              effectiveBackground,
              Color.alphaBlend(
                Colors.black.withValues(alpha: 0.16),
                effectiveBackground,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(DashboardRadii.avatar),
          border: Border.all(color: effectiveBorder),
        ),
        child: Stack(
          children: <Widget>[
            if (sealColor != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sealColor,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: sealColor!.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            Center(
              child: Text(
                effectiveMonogram,
                style: type.sectionTitle.copyWith(
                      color: effectiveForeground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSectionFrame extends StatelessWidget {
  const DashboardSectionFrame({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.countLabel,
    this.caption,
  });

  final String title;
  final List<Widget> children;
  final String? eyebrow;
  final String? countLabel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    final reduceMotion = shouldReduceMotion(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: reduceMotion ? Duration.zero : dashboardEntranceDuration,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 6),
                child: child,
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (eyebrow != null) ...<Widget>[
                      Text(
                        eyebrow!,
                        style: type.meta.copyWith(
                              letterSpacing: 0.42,
                              color: colors.faintInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: type.sectionTitle.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.ink,
                            ),
                      ),
                    ),
                    if (caption != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        caption!,
                        style: type.supporting.copyWith(
                              color: colors.mutedInk,
                              height: 1.28,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (countLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : dashboardMotionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey<String>(countLabel!),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DashboardSpacing.xSmall + 2,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.paper,
                        borderRadius:
                            BorderRadius.circular(DashboardRadii.chip),
                        border: Border.all(
                          color: colors.outlineStrong,
                        ),
                      ),
                      child: Text(
                        countLabel!,
                        style: type.meta.copyWith(
                          color: colors.softInk,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DashboardSpacing.sectionHeaderGap),
        ...children,
      ],
    );
  }
}

class DashboardButtonStyles {
  static ButtonStyle primaryCompact(BuildContext context) {
    final type = context.dashboardType;
    return FilledButton.styleFrom(
      minimumSize: const Size(0, DashboardActionRhythm.compactHeight),
      padding: DashboardActionRhythm.compactPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardRadii.button),
      ),
      textStyle: type.button,
    );
  }

  static ButtonStyle secondaryCompact(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, DashboardActionRhythm.compactHeight),
      padding: DashboardActionRhythm.compactPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardRadii.button),
      ),
      textStyle: type.button.copyWith(
        color: colors.softInk,
      ),
    );
  }

  static ButtonStyle quietCompact(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    return TextButton.styleFrom(
      minimumSize: const Size(0, DashboardActionRhythm.quietHeight),
      padding: DashboardActionRhythm.quietPadding,
      foregroundColor: colors.softInk,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardRadii.button),
      ),
      textStyle: type.button.copyWith(
        color: colors.softInk,
        fontSize: 13,
      ),
    );
  }
}

class DashboardRegisterEntry extends StatelessWidget {
  const DashboardRegisterEntry({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.tint,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    final reduceMotion = shouldReduceMotion(context);
    return SizedBox(
      width: 122,
      child: DashboardPanel(
        backgroundColor: colors.registerPaper,
        borderColor: accent.withValues(alpha: 0.28),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        radius: DashboardRadii.nested,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.meta.copyWith(
                          color: accent,
                          letterSpacing: 0.38,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration:
                  reduceMotion ? Duration.zero : dashboardMotionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                key: ValueKey<String>('register-value-$label-$value'),
                style: type.screenTitle.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: type.supporting.copyWith(
                    color: colors.mutedInk,
                    height: 1.28,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.eyebrow,
    this.tone = DashboardEmptyStateTone.neutral,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? eyebrow;
  final DashboardEmptyStateTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    final colors = context.dashboardColors;
    final reduceMotion = shouldReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: reduceMotion ? Duration.zero : dashboardEntranceDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: child,
          ),
        );
      },
      child: DashboardPanel(
        tone: _panelToneForTone(tone),
        elevation: DashboardPanelElevation.flat,
        radius: DashboardRadii.card,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (eyebrow != null && eyebrow!.isNotEmpty) ...<Widget>[
              DashboardBadge(
                label: eyebrow!,
                tone: _badgeToneForTone(tone),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DashboardIconSurface(
                  icon: icon,
                  tone: _iconToneForTone(tone),
                  size: 40,
                  iconSize: 18,
                  radius: 14,
                ),
                const SizedBox(width: DashboardSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: type.rowTitle.copyWith(
                          color: colors.softInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (message.isNotEmpty) ...<Widget>[
                        const SizedBox(height: DashboardSpacing.micro),
                        Text(
                          message,
                          style: type.supporting.copyWith(
                            color: colors.mutedInk,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: action!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static DashboardPanelTone _panelToneForTone(DashboardEmptyStateTone tone) =>
      switch (tone) {
        DashboardEmptyStateTone.neutral => DashboardPanelTone.base,
        DashboardEmptyStateTone.success => DashboardPanelTone.elevated,
        DashboardEmptyStateTone.trust => DashboardPanelTone.trust,
        DashboardEmptyStateTone.accent => DashboardPanelTone.elevated,
      };

  static DashboardBadgeTone _badgeToneForTone(DashboardEmptyStateTone tone) =>
      switch (tone) {
        DashboardEmptyStateTone.neutral => DashboardBadgeTone.neutral,
        DashboardEmptyStateTone.success => DashboardBadgeTone.success,
        DashboardEmptyStateTone.trust => DashboardBadgeTone.info,
        DashboardEmptyStateTone.accent => DashboardBadgeTone.accent,
      };

  static DashboardIconSurfaceTone _iconToneForTone(
    DashboardEmptyStateTone tone,
  ) =>
      switch (tone) {
        DashboardEmptyStateTone.neutral => DashboardIconSurfaceTone.neutral,
        DashboardEmptyStateTone.success => DashboardIconSurfaceTone.success,
        DashboardEmptyStateTone.trust => DashboardIconSurfaceTone.info,
        DashboardEmptyStateTone.accent => DashboardIconSurfaceTone.accent,
      };
}

bool shouldReduceMotion(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  return mediaQuery != null &&
      (mediaQuery.disableAnimations || mediaQuery.accessibleNavigation);
}

class SubWatchBrandMark extends StatelessWidget {
  const SubWatchBrandMark({
    super.key,
    this.size = 76,
    this.showBase = false,
  });

  final double size;
  final bool showBase;

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SubWatchBrandMarkPainter(
          showBase: showBase,
          paper: colors.paper,
          nestedPaper: colors.nestedPaper,
          outlineStrong: colors.outlineStrong,
          accent: colors.accent,
          ink: colors.ink,
        ),
      ),
    );
  }
}

class _SubWatchBrandMarkPainter extends CustomPainter {
  const _SubWatchBrandMarkPainter({
    required this.showBase,
    required this.paper,
    required this.nestedPaper,
    required this.outlineStrong,
    required this.accent,
    required this.ink,
  });

  final bool showBase;
  final Color paper;
  final Color nestedPaper;
  final Color outlineStrong;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (showBase) {
      final baseRect = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.21),
      );
      final basePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            paper,
            nestedPaper,
          ],
        ).createShader(Offset.zero & size);
      canvas.drawRRect(baseRect, basePaint);
      final outline = Paint()
        ..color = outlineStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035;
      canvas.drawRRect(baseRect, outline);
    }

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.105;
    final pulseRect = Rect.fromLTWH(
      size.width * 0.53,
      size.height * 0.15,
      size.width * 0.24,
      size.height * 0.24,
    );
    canvas.drawArc(pulseRect, -0.55, 4.95, false, accentPaint);

    final stemPaint = Paint()..color = accent;
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.275,
        size.width * 0.016,
        size.height * 0.084,
      ),
      Radius.circular(size.width * 0.012),
    );
    canvas.drawRRect(stemRect, stemPaint);
    canvas.drawCircle(
      Offset(size.width * 0.628, size.height * 0.272),
      size.width * 0.016,
      stemPaint,
    );

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.44,
        size.width * 0.52,
        size.height * 0.23,
      ),
      Radius.circular(size.width * 0.08),
    );
    final cardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFFF8E7D3),
          Color(0xFFF1D3B6),
        ],
      ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, cardPaint);
    final cardOutline = Paint()
      ..color = const Color(0xFFD2B18D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawRRect(cardRect, cardOutline);

    final lightPaint = Paint()..color = ink;
    final lineOne = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.37,
        size.height * 0.50,
        size.width * 0.22,
        size.height * 0.032,
      ),
      Radius.circular(size.width * 0.016),
    );
    final lineTwo = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.37,
        size.height * 0.555,
        size.width * 0.15,
        size.height * 0.028,
      ),
      Radius.circular(size.width * 0.014),
    );
    canvas.drawRRect(lineOne, lightPaint);
    canvas.drawRRect(lineTwo, lightPaint);
    canvas.drawCircle(
      Offset(size.width * 0.31, size.height * 0.515),
      size.width * 0.010,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SubWatchBrandMarkPainter oldDelegate) {
    return oldDelegate.showBase != showBase ||
        oldDelegate.paper != paper ||
        oldDelegate.nestedPaper != nestedPaper ||
        oldDelegate.outlineStrong != outlineStrong ||
        oldDelegate.accent != accent ||
        oldDelegate.ink != ink;
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

