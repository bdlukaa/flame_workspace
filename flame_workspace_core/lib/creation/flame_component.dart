import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame_workspace_core/flame_workspace_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A mixin that trakcs properties on [Component]s.
///
/// Every non built-in components must use this mixin. This is used to ensure
/// the IDE can track the properties of the component.
///
/// Components created directly from the Workspace will automatically use this
/// mixin.
///
/// This adds a selection highlight to the component when it is selected. This
/// enables the repositioning and resizing of the component.
mixin FlameComponent on PositionComponent {
  /// Wrap a component in a [FlameComponent] if it is not already wrapped.
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
}

/// A component that highlights itself.
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

class _FlameComponentWrapper extends PositionComponent
    with FlameComponent, HasGameRef, TapCallbacks, DragCallbacks {
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

  // TODO: implement this feature when proper embedding is available.
  //       We currently embed the game using flutter_native_view. Whether it is
  //       a great package, it doesn't support touch events.
  //       We need to wait for official platform views or touch implementation
  //       in flutter_native_view.
  // @override
  // void onTapUp(TapUpEvent event) {
  //   super.onTapUp(event);
  //   FlameWorkspaceCore.instance.currentSelectedComponent = component;
  // }

  // @override
  // void onDragUpdate(DragUpdateEvent event) {
  //   (component as PositionComponent).position = event.localEndPosition;
  // }
}
