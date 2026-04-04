import 'package:flutter/material.dart';

import '../dashboard_primitives.dart';

typedef LazyIndexedStackItemBuilder = Widget Function(BuildContext context);

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.previousIndex,
    required this.itemBuilders,
    this.reduceMotion = false,
  });

  final int index;
  final int previousIndex;
  final List<LazyIndexedStackItemBuilder> itemBuilders;
  final bool reduceMotion;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final List<Widget?> _loadedChildren;
  int _fromIndex = 0;
  int _toIndex = 0;
  int _direction = 1;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: dashboardPageTransitionDuration,
    );
    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
    _loadedChildren = List<Widget?>.filled(widget.itemBuilders.length, null);
    _ensureChildLoaded(widget.index);
    _fromIndex = widget.index;
    _toIndex = widget.index;
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemBuilders.length != widget.itemBuilders.length) {
      final previousChildren = List<Widget?>.from(_loadedChildren);
      _loadedChildren
        ..clear()
        ..addAll(List<Widget?>.filled(widget.itemBuilders.length, null));
      for (var index = 0;
          index < previousChildren.length && index < _loadedChildren.length;
          index++) {
        _loadedChildren[index] = previousChildren[index];
      }
    }
    _ensureChildLoaded(widget.index);
    if (oldWidget.index != widget.index) {
      _fromIndex = widget.previousIndex.clamp(0, _loadedChildren.length - 1);
      _toIndex = widget.index;
      _direction = _toIndex >= _fromIndex ? 1 : -1;
      if (_fromIndex == _toIndex) {
        _isAnimating = false;
        return;
      }
      if (widget.reduceMotion) {
        _isAnimating = false;
      } else {
        _isAnimating = true;
        _transitionController.forward(from: 0);
      }
    }
  }

  void _ensureChildLoaded(int index) {
    if (_loadedChildren[index] != null) {
      return;
    }
    _loadedChildren[index] = Builder(
      builder: widget.itemBuilders[index],
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Widget _buildTransitionLayer(int childIndex, Widget child) {
    if (!_isAnimating || (childIndex != _fromIndex && childIndex != _toIndex)) {
      return Offstage(
        offstage: childIndex != widget.index,
        child: TickerMode(
          enabled: childIndex == widget.index,
          child: child,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_transitionController.value);
        final isIncoming = childIndex == _toIndex;
        final opacity = isIncoming ? t : (1 - t);
        final horizontalShift =
            isIncoming ? (1 - t) * 12 * _direction : -t * 10 * _direction;
        final scale = isIncoming ? 0.994 + (0.006 * t) : 1.0 - (0.006 * t);
        return IgnorePointer(
          ignoring: !isIncoming,
          child: ExcludeSemantics(
            excluding: !isIncoming,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(horizontalShift, 0),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureChildLoaded(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(_loadedChildren.length, (index) {
        final child = _loadedChildren[index] ?? const SizedBox.shrink();
        return _buildTransitionLayer(index, child);
      }),
    );
  }
}
