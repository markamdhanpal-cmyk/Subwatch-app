import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';

class SubWatchLaunchHandoff extends StatefulWidget {
  const SubWatchLaunchHandoff({
    super.key,
    required this.onCompleted,
    this.caption = 'Trust-first detection, on device.',
  });

  final VoidCallback onCompleted;
  final String caption;

  @override
  State<SubWatchLaunchHandoff> createState() => _SubWatchLaunchHandoffState();
}

class _SubWatchLaunchHandoffState extends State<SubWatchLaunchHandoff>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _arcProgress;
  late final Animation<double> _slabOffset;
  late final Animation<double> _captionOpacity;

  bool _initialized = false;
  bool _didNotifyComplete = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _reduceMotion = shouldReduceMotion(context);

    _controller = AnimationController(
      vsync: this,
      duration: _reduceMotion
          ? const Duration(milliseconds: 320)
          : const Duration(milliseconds: 1120),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _notifyComplete();
        }
      });

    _configureAnimations();
    _controller.forward();
  }

  void _configureAnimations() {
    if (_reduceMotion) {
      _overlayOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(1),
          weight: 65,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 0).chain(
            CurveTween(curve: Curves.easeOut),
          ),
          weight: 35,
        ),
      ]).animate(_controller);
      _markOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      );
      _markScale = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
        ),
      );
      _arcProgress = const AlwaysStoppedAnimation<double>(1);
      _slabOffset = const AlwaysStoppedAnimation<double>(0);
      _captionOpacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.48, curve: Curves.easeOut),
      );
      return;
    }

    _overlayOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 88,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 12,
      ),
    ]).animate(_controller);

    _markOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.27, curve: Curves.easeOutCubic),
    );
    _markScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.27, curve: Curves.easeOutCubic),
      ),
    );
    _arcProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
    );
    _slabOffset = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 8, end: -4).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 58,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -4, end: 0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 42,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.74),
      ),
    );
    _captionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
    );
  }

  void _notifyComplete() {
    if (_didNotifyComplete) {
      return;
    }
    _didNotifyComplete = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dashboardColors;
    final type = context.dashboardType;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final effectiveArcProgress = _reduceMotion ? 1.0 : _arcProgress.value;
          final effectiveSlabOffset = _reduceMotion ? 0.0 : _slabOffset.value;
          return Opacity(
            opacity: _overlayOpacity.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colors.backdropTop,
                    colors.backdropBottom,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Opacity(
                        opacity: _markOpacity.value,
                        child: Transform.scale(
                          scale: _markScale.value,
                          child: SizedBox(
                            width: 148,
                            height: 148,
                            child: CustomPaint(
                              painter: _LaunchSealPainter(
                                paper: colors.paper,
                                nestedPaper: colors.nestedPaper,
                                outlineStrong: colors.outlineStrong,
                                accent: colors.accent,
                                accentSoft: colors.accentSoft,
                                statusBlue: colors.statusBlue,
                                ink: colors.ink,
                                arcProgress: effectiveArcProgress,
                                slabOffset: effectiveSlabOffset,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: _captionOpacity.value,
                        child: Text(
                          widget.caption,
                          textAlign: TextAlign.center,
                          style: type.supporting.copyWith(
                            color: colors.mutedInk,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LaunchSealPainter extends CustomPainter {
  const _LaunchSealPainter({
    required this.paper,
    required this.nestedPaper,
    required this.outlineStrong,
    required this.accent,
    required this.accentSoft,
    required this.statusBlue,
    required this.ink,
    required this.arcProgress,
    required this.slabOffset,
  });

  final Color paper;
  final Color nestedPaper;
  final Color outlineStrong;
  final Color accent;
  final Color accentSoft;
  final Color statusBlue;
  final Color ink;
  final double arcProgress;
  final double slabOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final markRect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );
    final w = markRect.width;
    final h = markRect.height;

    final resolvedArc = arcProgress.clamp(0.0, 1.0);
    final resolvedSlabOffset = slabOffset.clamp(-6.0, 10.0);
    final stemVisibility = ((resolvedArc - 0.18) / 0.82).clamp(0.0, 1.0);

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.118;
    final pulseRect = Rect.fromLTWH(
      markRect.left + (w * 0.47),
      markRect.top + (h * 0.08),
      w * 0.34,
      h * 0.34,
    );
    final sweep = 5.02 * resolvedArc;
    if (sweep > 0.01) {
      canvas.drawArc(pulseRect, -0.52, sweep, false, accentPaint);
    }

    final stemColor = Color.lerp(
      accent.withValues(alpha: 0.12),
      accent,
      stemVisibility,
    )!;
    final stemPaint = Paint()..color = stemColor;
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + (w * 0.58),
        markRect.top + (h * 0.30),
        w * 0.10,
        h * 0.22,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(stemRect, stemPaint);
    canvas.drawCircle(
      Offset(markRect.left + (w * 0.63), markRect.top + (h * 0.30)),
      w * 0.056,
      stemPaint,
    );

    final slabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + (w * 0.16),
        markRect.top + (h * 0.46) + resolvedSlabOffset,
        w * 0.68,
        h * 0.31,
      ),
      Radius.circular(w * 0.13),
    );
    final slabTop = Color.alphaBlend(accentSoft.withValues(alpha: 0.23), paper);
    final slabBottom =
        Color.alphaBlend(ink.withValues(alpha: 0.10), nestedPaper);
    final slabPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          slabTop,
          slabBottom,
        ],
      ).createShader(slabRect.outerRect);
    canvas.drawRRect(slabRect, slabPaint);
    final slabOutline = Paint()
      ..color = Color.alphaBlend(ink.withValues(alpha: 0.20), outlineStrong)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawRRect(slabRect, slabOutline);

    final connector = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(
        markRect.left + (w * 0.63),
        markRect.top + (h * 0.51) + (resolvedSlabOffset * 0.72),
      ),
      w * 0.045,
      connector,
    );

    final trustTag = Paint()..color = statusBlue;
    final trustTagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + (w * 0.24),
        markRect.top + (h * 0.56) + resolvedSlabOffset,
        w * 0.10,
        h * 0.10,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(trustTagRect, trustTag);

    final linePaint = Paint()..color = ink.withValues(alpha: 0.82);
    final lineOne = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + (w * 0.39),
        markRect.top + (h * 0.56) + resolvedSlabOffset,
        w * 0.28,
        h * 0.05,
      ),
      Radius.circular(w * 0.024),
    );
    final lineTwo = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + (w * 0.39),
        markRect.top + (h * 0.64) + resolvedSlabOffset,
        w * 0.20,
        h * 0.045,
      ),
      Radius.circular(w * 0.022),
    );
    canvas.drawRRect(lineOne, linePaint);
    canvas.drawRRect(lineTwo, linePaint);

    canvas.drawCircle(
      Offset(
        markRect.left + (w * 0.21),
        markRect.top + (h * 0.61) + resolvedSlabOffset,
      ),
      w * 0.022,
      Paint()..color = accent.withValues(alpha: 0.86),
    );
  }

  @override
  bool shouldRepaint(covariant _LaunchSealPainter oldDelegate) {
    return oldDelegate.paper != paper ||
        oldDelegate.nestedPaper != nestedPaper ||
        oldDelegate.outlineStrong != outlineStrong ||
        oldDelegate.accent != accent ||
        oldDelegate.accentSoft != accentSoft ||
        oldDelegate.statusBlue != statusBlue ||
        oldDelegate.ink != ink ||
        oldDelegate.arcProgress != arcProgress ||
        oldDelegate.slabOffset != slabOffset;
  }
}
