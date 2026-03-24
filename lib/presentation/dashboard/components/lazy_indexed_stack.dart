import 'package:flutter/widgets.dart';

typedef LazyIndexedStackItemBuilder = Widget Function(BuildContext context);

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemBuilders,
  });

  final int index;
  final List<LazyIndexedStackItemBuilder> itemBuilders;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<Widget?> _loadedChildren;

  @override
  void initState() {
    super.initState();
    _loadedChildren = List<Widget?>.filled(widget.itemBuilders.length, null);
    _ensureChildLoaded(widget.index);
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
  Widget build(BuildContext context) {
    _ensureChildLoaded(widget.index);
    return IndexedStack(
      index: widget.index,
      children: _loadedChildren
          .map((child) => child ?? const SizedBox.shrink())
          .toList(growable: false),
    );
  }
}
