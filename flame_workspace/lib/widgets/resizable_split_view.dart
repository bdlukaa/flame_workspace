import 'dart:async';

import 'package:flutter/material.dart';

import '../workbench/layout_preferences.dart';

enum SplitDirection { horizontal, vertical }

class ResizableSplitView extends StatefulWidget {
  const ResizableSplitView({
    super.key,
    required this.id,
    required this.direction,
    required this.first,
    required this.second,
    this.initialRatio = 0.5,
    this.minFirstSize = 120,
    this.minSecondSize = 120,
    this.maxFirstSize,
    this.dividerSize = 8,
    this.preferences,
    this.onChanged,
  }) : assert(initialRatio > 0 && initialRatio < 1),
       assert(minFirstSize >= 0 && minSecondSize >= 0),
       assert(dividerSize >= 1);

  final String id;
  final SplitDirection direction;
  final Widget first;
  final Widget second;
  final double initialRatio;
  final double minFirstSize;
  final double minSecondSize;
  final double? maxFirstSize;
  final double dividerSize;
  final LayoutPreferences? preferences;
  final ValueChanged<double>? onChanged;

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _ratio = widget.initialRatio;
  bool _dragging = false;
  bool _hovering = false;
  bool _userInteracted = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  @override
  void didUpdateWidget(ResizableSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.preferences != widget.preferences) {
      _userInteracted = false;
      unawaited(_restore());
    }
  }

  Future<void> _restore() async {
    final saved = await (widget.preferences ?? LayoutPreferences.instance)
        .readRatio(widget.id);
    if (!mounted || _userInteracted || saved == null || !saved.isFinite) return;
    setState(() => _ratio = saved.clamp(0.01, 0.99));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  double _clampExtent(double requested, double available) {
    final upper = <double>[
      available - widget.minSecondSize,
      ?widget.maxFirstSize,
    ].reduce((a, b) => a < b ? a : b);
    final lower = widget.minFirstSize;
    if (upper < lower) return available * _ratio;
    return requested.clamp(lower, upper);
  }

  void _resize(double delta, double available) {
    if (available <= 0) return;
    final currentExtent = available * _ratio;
    final nextExtent = _clampExtent(currentExtent + delta, available);
    final nextRatio = (nextExtent / available).clamp(0.01, 0.99);
    if ((nextRatio - _ratio).abs() < 0.0001) return;
    _userInteracted = true;
    setState(() => _ratio = nextRatio);
    widget.onChanged?.call(_ratio);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 200), _persistRatio);
  }

  void _reset() {
    _userInteracted = true;
    setState(() => _ratio = widget.initialRatio);
    widget.onChanged?.call(_ratio);
    _saveTimer?.cancel();
    unawaited(_persistRatio());
  }

  Future<void> _persistRatio() async {
    try {
      await (widget.preferences ?? LayoutPreferences.instance).writeRatio(
        widget.id,
        _ratio,
      );
    } on Object {
      // Layout persistence is best-effort; pane interaction remains usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = widget.direction == SplitDirection.horizontal;
        final total = horizontal ? constraints.maxWidth : constraints.maxHeight;
        if (!total.isFinite) {
          return Flex(
            direction: horizontal ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(child: widget.first),
              Expanded(child: widget.second),
            ],
          );
        }
        final available = (total - widget.dividerSize).clamp(0.0, total);
        final firstSize = _clampExtent(available * _ratio, available);
        final secondSize = (available - firstSize).clamp(0.0, available);
        final dividerColor = _dragging || _hovering
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.65)
            : Theme.of(context).dividerColor;
        final divider = MouseRegion(
          cursor: horizontal
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          key: ValueKey('split-divider-${widget.id}'),
          child: Semantics(
            label: 'Resize ${widget.id} split',
            value: '${(_ratio * 100).round()} percent',
            increasedValue:
                '${((_ratio + 0.05).clamp(0, 1) * 100).round()} percent',
            decreasedValue:
                '${((_ratio - 0.05).clamp(0, 1) * 100).round()} percent',
            onIncrease: () => _resize(24, available),
            onDecrease: () => _resize(-24, available),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _reset,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  if (event.buttons == 1) setState(() => _dragging = true);
                },
                onPointerMove: (event) {
                  if (!_dragging) return;
                  _resize(
                    horizontal ? event.delta.dx : event.delta.dy,
                    available,
                  );
                },
                onPointerUp: (_) => setState(() => _dragging = false),
                onPointerCancel: (_) => setState(() => _dragging = false),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    color: dividerColor,
                    width: horizontal ? 1 : double.infinity,
                    height: horizontal ? double.infinity : 1,
                  ),
                ),
              ),
            ),
          ),
        );
        return Flex(
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          children: [
            SizedBox(
              key: ValueKey('split-first-${widget.id}'),
              width: horizontal ? firstSize : null,
              height: horizontal ? null : firstSize,
              child: widget.first,
            ),
            SizedBox(
              width: horizontal ? widget.dividerSize : null,
              height: horizontal ? null : widget.dividerSize,
              child: divider,
            ),
            SizedBox(
              key: ValueKey('split-second-${widget.id}'),
              width: horizontal ? secondSize : null,
              height: horizontal ? null : secondSize,
              child: widget.second,
            ),
          ],
        );
      },
    );
  }
}
