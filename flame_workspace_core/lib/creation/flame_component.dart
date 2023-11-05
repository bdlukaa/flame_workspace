import 'dart:async';

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
  static Component wrap(Component component) {
    if (component is FlameComponent || component is _FlameComponentWrapper) {
      return component;
    }

    return _FlameComponentWrapper(component);
  }

  final FlameSelectionComponent _selectionHighlight = FlameSelectionComponent();
  Component get targetComponent {
    return this is _FlameComponentWrapper
        ? (this as _FlameComponentWrapper).component
        : this;
  }

  @override
  @mustCallSuper
  void add(Component component) {
    debugPrint('added $component');
    super.add(component);
  }

  @override
  @mustCallSuper
  void remove(Component component) {
    debugPrint('removed $component');
    super.remove(component);
  }

  @override
  @mustCallSuper
  void update(double t) {
    super.update(t);

    if (FlameWorkspaceCore.instance.currentSelectedComponent ==
        targetComponent) {
      _selectionHighlight
        ..position = position
        ..size = size;
    }
  }

  @override
  @mustCallSuper
  void render(Canvas canvas) {
    super.render(canvas);

    if (FlameWorkspaceCore.instance.currentSelectedComponent ==
        targetComponent) {
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
    canvas.drawRect(
      Rect.fromLTWH(position.x, position.y, width, height),
      _paint,
    );
  }
}

class _FlameComponentWrapper extends PositionComponent with FlameComponent {
  _FlameComponentWrapper(this.component) : super(children: [component]);

  final Component component;

  @override
  void update(double t) {
    super.update(t);

    if (component is PositionComponent) {
      position = (component as PositionComponent).position;
      size = (component as PositionComponent).size;
      anchor = (component as PositionComponent).anchor;
      angle = (component as PositionComponent).angle;
      scale = (component as PositionComponent).scale;
      nativeAngle = (component as PositionComponent).nativeAngle;
    }
  }

  @override
  getProperty(String property) {
    throw UnimplementedError();
  }

  @override
  void setProperty(String property, value) {
    throw UnimplementedError();
  }
}
