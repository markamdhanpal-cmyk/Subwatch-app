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
  static const Color canvas = Color(0xFF100C0A);
  static const Color canvasRaised = Color(0xFF16110E);
  static const Color paper = Color(0xFF17110F);
  static const Color elevatedPaper = Color(0xFF1E1714);
  static const Color nestedPaper = Color(0xFF261D19);
  static const Color registerPaper = Color(0xFF14100D);
  static const Color ink = Color(0xFFF5EBDD);
  static const Color softInk = Color(0xFFE2D8CA);
  static const Color mutedInk = Color(0xFFB3A79A);
  static const Color faintInk = Color(0xFF877B71);
  static const Color accent = Color(0xFFE0A258);
  static const Color accentSoft = Color(0xFF352416);
  static const Color accentGlow = Color(0xFFF1C07C);
  static const Color statusBlue = Color(0xFF89A2CC);
  static const Color statusBlueSoft = Color(0xFF192332);
  static const Color benefitGold = Color(0xFFD1AF67);
  static const Color benefitGoldSoft = Color(0xFF302315);
  static const Color success = Color(0xFF86B39F);
  static const Color successSoft = Color(0xFF16231D);
  static const Color caution = Color(0xFFD29156);
  static const Color cautionSoft = Color(0xFF312016);
  static const Color recovery = Color(0xFFABB8CB);
  static const Color recoverySoft = Color(0xFF17202A);
  static const Color outline = Color(0xFF362C27);
  static const Color outlineStrong = Color(0xFF4C3C34);
  static const Color divider = Color(0xFF2A221E);
  static const Color scrim = Color(0x99080504);
  static const Color shadow = Color(0x66040201);
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
        color: DashboardShellPalette.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.14,
      );
  TextStyle get supporting => caption.copyWith(
        color: DashboardShellPalette.mutedInk,
      );
  TextStyle get meta => label.copyWith(
        color: DashboardShellPalette.mutedInk,
        fontWeight: FontWeight.w700,
      );
  TextStyle get badge => label.copyWith(
        fontWeight: FontWeight.w700,
      );
}

class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF18110E),
            DashboardShellPalette.canvasRaised,
            DashboardShellPalette.canvas,
            Color(0xFF0B0908),
          ],
          stops: <double>[0, 0.16, 0.56, 1],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: -120,
            right: -90,
            child: _BackdropGlow(
              size: 240,
              color: Color(0xFF8D5E34),
            ),
          ),
          const Positioned(
            top: 100,
            left: -90,
            child: _BackdropGlow(
              size: 180,
              color: Color(0xFF3F2D21),
            ),
          ),
          const Positioned(
            bottom: -140,
            left: 30,
            child: _BackdropGlow(
              size: 210,
              color: Color(0xFF1D2D28),
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = shouldReduceMotion(context);
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : dashboardMotionDuration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: gradient == null
            ? backgroundColor ?? DashboardShellPalette.paper
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (borderColor ?? DashboardShellPalette.outline)
              .withValues(alpha: 0.9),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DashboardShellPalette.shadow.withValues(alpha: 0.78),
            blurRadius: 28,
            spreadRadius: -18,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class DashboardBadge extends StatelessWidget {
  const DashboardBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = DashboardShellPalette.statusBlueSoft,
    this.foregroundColor = DashboardShellPalette.statusBlue,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardSpacing.xSmall + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DashboardRadii.chip),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.18),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (icon != null)
            Icon(icon, size: 12, color: foregroundColor),
          Text(
            label,
            style: type.badge.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.18,
                ),
          ),
        ],
      ),
    );
  }
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
                              color: DashboardShellPalette.faintInk,
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
                              color: DashboardShellPalette.ink,
                            ),
                      ),
                    ),
                    if (caption != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        caption!,
                        style: type.supporting.copyWith(
                              color: DashboardShellPalette.mutedInk,
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
                        color: DashboardShellPalette.nestedPaper,
                        borderRadius:
                            BorderRadius.circular(DashboardRadii.chip),
                        border: Border.all(
                          color: DashboardShellPalette.outline,
                        ),
                      ),
                      child: Text(
                        countLabel!,
                        style: type.meta.copyWith(
                          color: DashboardShellPalette.softInk,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DashboardSpacing.small),
        ...children,
      ],
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
    final reduceMotion = shouldReduceMotion(context);
    return SizedBox(
      width: 122,
      child: DashboardPanel(
        backgroundColor: DashboardShellPalette.registerPaper,
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
                      color: DashboardShellPalette.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: type.supporting.copyWith(
                    color: DashboardShellPalette.mutedInk,
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
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final type = context.dashboardType;
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
        backgroundColor: DashboardShellPalette.paper,
        borderColor: DashboardShellPalette.outlineStrong,
        radius: DashboardRadii.card,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DashboardShellPalette.nestedPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DashboardShellPalette.outlineStrong,
                ),
              ),
              child: Icon(
                icon,
                color: DashboardShellPalette.statusBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: DashboardSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: type.rowTitle.copyWith(
                          color: DashboardShellPalette.softInk,
                        ),
                  ),
                  if (message.isNotEmpty) ...<Widget>[
                    const SizedBox(height: DashboardSpacing.micro),
                    Text(
                      message,
                      style: type.supporting.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            height: 1.28,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SubWatchBrandMarkPainter(showBase: showBase),
      ),
    );
  }
}

class _SubWatchBrandMarkPainter extends CustomPainter {
  const _SubWatchBrandMarkPainter({
    required this.showBase,
  });

  final bool showBase;

  @override
  void paint(Canvas canvas, Size size) {
    if (showBase) {
      final baseRect = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.21),
      );
      final basePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1E1714),
            Color(0xFF13100E),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawRRect(baseRect, basePaint);
      final outline = Paint()
        ..color = const Color(0xFF57463D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035;
      canvas.drawRRect(baseRect, outline);
    }

    final accentPaint = Paint()
      ..color = DashboardShellPalette.accent
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

    final stemPaint = Paint()..color = DashboardShellPalette.accent;
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
          Color(0xFF251D19),
          Color(0xFF181311),
        ],
      ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, cardPaint);
    final cardOutline = Paint()
      ..color = const Color(0xFF655146)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawRRect(cardRect, cardOutline);

    final lightPaint = Paint()..color = const Color(0xFFF6EDE0);
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
      Paint()..color = DashboardShellPalette.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SubWatchBrandMarkPainter oldDelegate) {
    return oldDelegate.showBase != showBase;
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

