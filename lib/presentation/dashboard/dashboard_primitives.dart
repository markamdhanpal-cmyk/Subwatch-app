import 'package:flutter/material.dart';

import 'service_icon_registry.dart';

const Duration dashboardMotionDuration = Duration(milliseconds: 180);
const Duration dashboardEntranceDuration = Duration(milliseconds: 220);

class DashboardShellPalette {
  static const Color canvas = Color(0xFF120E0C);
  static const Color paper = Color(0xFF191311);
  static const Color elevatedPaper = Color(0xFF211916);
  static const Color nestedPaper = Color(0xFF2A211D);
  static const Color registerPaper = Color(0xFF1C1512);
  static const Color ink = Color(0xFFF7ECDD);
  static const Color mutedInk = Color(0xFFC8BFB2);
  static const Color accent = Color(0xFFE1A55A);
  static const Color accentSoft = Color(0xFF3A281B);
  static const Color statusBlue = Color(0xFF6295E2);
  static const Color statusBlueSoft = Color(0xFF1B2738);
  static const Color benefitGold = Color(0xFFC89B40);
  static const Color benefitGoldSoft = Color(0xFF342714);
  static const Color success = Color(0xFF7AB49D);
  static const Color successSoft = Color(0xFF1A2722);
  static const Color caution = Color(0xFFD88C4B);
  static const Color cautionSoft = Color(0xFF322218);
  static const Color recovery = Color(0xFFA4B1C5);
  static const Color recoverySoft = Color(0xFF1C232D);
  static const Color outline = Color(0xFF3A2F2A);
  static const Color outlineStrong = Color(0xFF51423A);
  static const Color shadow = Color(0x66060302);
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
            Color(0xFF18110F),
            DashboardShellPalette.canvas,
            Color(0xFF0E0B09),
          ],
          stops: <double>[0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: -120,
            right: -90,
            child: _BackdropGlow(
              size: 220,
              color: Color(0xFF9F6937),
            ),
          ),
          const Positioned(
            top: 100,
            left: -90,
            child: _BackdropGlow(
              size: 180,
              color: Color(0xFF4D3629),
            ),
          ),
          const Positioned(
            bottom: -140,
            left: 30,
            child: _BackdropGlow(
              size: 210,
              color: Color(0xFF1C322D),
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
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.radius = 28,
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
              .withValues(alpha: 0.78),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: DashboardShellPalette.shadow,
            blurRadius: 10,
            spreadRadius: -8,
            offset: Offset(0, 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.12),
        ),
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (icon != null)
            Icon(icon, size: 13, color: foregroundColor),
          Text(
            label,
            style: type.label.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
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
          borderRadius: BorderRadius.circular(15),
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
                style: type.subheading.copyWith(
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
                        style: type.label.copyWith(
                              letterSpacing: 0.42,
                              color: DashboardShellPalette.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: type.subheading.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DashboardShellPalette.ink,
                            ),
                      ),
                    ),
                    if (caption != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        caption!,
                        style: type.caption.copyWith(
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
                    child: Text(
                      countLabel!,
                      key: ValueKey<String>(countLabel!),
                      style: type.label.copyWith(
                            color: DashboardShellPalette.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
        borderColor: accent.withValues(alpha: 0.24),
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        radius: 16,
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
                    style: type.label.copyWith(
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
                style: type.heading.copyWith(
                      color: DashboardShellPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: type.caption.copyWith(
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: DashboardShellPalette.paper.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: DashboardShellPalette.statusBlue,
                size: 13,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: type.body.copyWith(
                          color: DashboardShellPalette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: type.caption.copyWith(
                          color: DashboardShellPalette.mutedInk,
                          height: 1.28,
                        ),
                  ),
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
  if (mediaQuery == null) {
    return false;
  }
  return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
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

