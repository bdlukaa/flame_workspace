import 'package:flame/components.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A mixin that trakcs properties on [Component]s.
///
/// Every non built-in components must use this mixin. This is used to ensure
/// the IDE can track the properties of the component.
///
/// Components created directly from the IDE will automatically use this mixin.
mixin FlameComponent on PositionComponent {
  final FlameSelectionComponent _selectionHighlight = FlameSelectionComponent();

  @override
  @mustCallSuper
  void add(Component component) {
    debugPrint('added $component');
    super.add(component);
  }

  @override
  @mustCallSuper
  void remove(Component component) {
    super.remove(component);
  }

  @override
  @mustCallSuper
  void update(double t) {
    super.update(t);

    if (FlameWorkspaceCore.instance.currentSelectedComponent == this) {
      _selectionHighlight
        ..position = position
        ..size = size;
    }
  }

  @override
  @mustCallSuper
  void render(Canvas canvas) {
    super.render(canvas);

    if (FlameWorkspaceCore.instance.currentSelectedComponent == this) {
      _selectionHighlight.render(canvas);
    }
  }

  /// Updates a property of the component.
  void setProperty(String property, dynamic value);

  /// Gets the value of a property of the component.
  dynamic getProperty(String property);
}

/// A component that highlights itseslf when selected.
class FlameSelectionComponent extends PositionComponent {
  FlameSelectionComponent({
    Vector2? position,
    Vector2? size,
    Anchor anchor = Anchor.center,
    Color color = const Color(0xFFffb431),
  }) : super(
          position: position,
          size: size,
          anchor: anchor,
        ) {
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
  }

  late Paint _paint;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
  }
}
