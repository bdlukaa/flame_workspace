import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:path/path.dart' as path;

import '../../../../workbench/assets/asset_drag_data.dart';
import '../../../../workbench/model/semantic_model.dart';
import 'scene_render_adapters.dart';

/// Converts between semantic scene coordinates and the visible canvas.
class const SceneViewport({
  required final Size size,
  final double zoom = 1,
  final Offset pan = Offset.zero,
}) {
  Offset worldToViewport(Offset point) {
    final center = Offset(size.width / 2, size.height / 2);
    return center + pan + point * zoom;
  }

  Offset viewportToWorld(Offset point) {
    final center = Offset(size.width / 2, size.height / 2);
    return (point - center - pan) / zoom;
  }

  static SceneViewport fitBounds(
    Size size,
    Rect bounds, {
    double padding = 32,
    double minZoom = 0.2,
    double maxZoom = 4,
  }) {
    final availableWidth = math.max(1, size.width - padding * 2);
    final availableHeight = math.max(1, size.height - padding * 2);
    final boundsWidth = math.max(1, bounds.width);
    final boundsHeight = math.max(1, bounds.height);
    final zoom = math
        .min(availableWidth / boundsWidth, availableHeight / boundsHeight)
        .clamp(minZoom, maxZoom);
    return SceneViewport(
      size: size,
      zoom: zoom,
      pan: Offset(-bounds.center.dx * zoom, -bounds.center.dy * zoom),
    );
  }
}

/// Operations available on a selected component in the Scene View.
enum SceneEditHandle { move, resize, rotate, scale }

/// A two-dimensional affine transform used for nested component frames.
class _AffineTransform {
  const _AffineTransform(this.a, this.b, this.c, this.d, this.tx, this.ty);

  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;

  factory _AffineTransform.component(
    WorkspaceTransform transform,
    Offset anchor,
  ) {
    final cosine = math.cos(transform.angle);
    final sine = math.sin(transform.angle);
    final a = cosine * transform.scale.x;
    final b = sine * transform.scale.x;
    final c = -sine * transform.scale.y;
    final d = cosine * transform.scale.y;
    return _AffineTransform(
      a,
      b,
      c,
      d,
      transform.position.x - a * anchor.dx - c * anchor.dy,
      transform.position.y - b * anchor.dx - d * anchor.dy,
    );
  }

  _AffineTransform operator *(_AffineTransform other) => _AffineTransform(
    a * other.a + c * other.b,
    b * other.a + d * other.b,
    a * other.c + c * other.d,
    b * other.c + d * other.d,
    a * other.tx + c * other.ty + tx,
    b * other.tx + d * other.ty + ty,
  );

  Offset transformPoint(Offset point) => Offset(
    a * point.dx + c * point.dy + tx,
    b * point.dx + d * point.dy + ty,
  );

  Offset inverseTransformPoint(Offset point) {
    final determinant = a * d - b * c;
    if (determinant == 0) return Offset.zero;
    final x = point.dx - tx;
    final y = point.dy - ty;
    return Offset(
      (d * x - c * y) / determinant,
      (-b * x + a * y) / determinant,
    );
  }

  Float64List toCanvasTransform() =>
      Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]);
}

/// A component's world-space frame, including its parent-relative transform.
class SceneComponentFrame {
  SceneComponentFrame._({
    required this._worldTransform,
    required this.component,
    required this.transform,
    required this.position,
    required this.size,
    required this.anchor,
    required this.parent,
    required this.renderOrder,
  });

  final _AffineTransform _worldTransform;
  final ComponentInstance component;
  final WorkspaceTransform transform;
  final Offset position;
  final Size size;
  final Offset anchor;
  final SceneComponentFrame? parent;
  final int renderOrder;
  Offset get topLeft => localToWorld(Offset.zero);

  Offset localToWorld(Offset localPoint) =>
      _worldTransform.transformPoint(localPoint);

  Offset worldToLocal(Offset worldPoint) =>
      _worldTransform.inverseTransformPoint(worldPoint);
}

/// Geometry, ordering, hit testing, and transform math for the Scene View.
class SceneCanvasGeometry {
  const SceneCanvasGeometry._();

  static const fallbackSize = Size.square(64);

  static Size sizeFor(ComponentInstance component) {
    if (component.type.name == 'TextComponent') {
      final data = const EditorComponentRenderRegistry().resolve(component);
      final painter = TextPainter(
        text: TextSpan(text: data.text ?? '', style: data.textStyle),
        textDirection: data.textDirection,
      )..layout();
      final measured = painter.size;
      if (measured.width > 0 && measured.height > 0) return measured;
      return fallbackSize;
    }
    if (component.type.name == 'CircleComponent') {
      final radius = component.properties['radius'];
      if (radius is num && radius > 0) {
        return Size.square(radius.toDouble() * 2);
      }
    }
    if (component.type.name == 'PolygonComponent') {
      final vertices = component.properties['vertices'];
      if (vertices is List<WorkspaceVectorValue> && vertices.length >= 3) {
        final xs = vertices.map((vertex) => vertex.x);
        final ys = vertices.map((vertex) => vertex.y);
        final width = xs.reduce(math.max) - xs.reduce(math.min);
        final height = ys.reduce(math.max) - ys.reduce(math.min);
        if (width > 0 && height > 0) return Size(width, height);
      }
    }
    final size = component.transform.size;
    return size.x > 0 && size.y > 0 ? Size(size.x, size.y) : fallbackSize;
  }

  static List<SceneComponentFrame> frames(SceneDefinition scene) {
    final result = <SceneComponentFrame>[];
    var renderOrder = 0;

    void visit(
      Iterable<ComponentInstance> components,
      SceneComponentFrame? parent,
    ) {
      for (final component in components) {
        final transform = component.transform;
        final size = sizeFor(component);
        final anchor = Offset(
          size.width * transform.anchor.x,
          size.height * transform.anchor.y,
        );

        final localTransform = _AffineTransform.component(transform, anchor);
        final worldTransform = parent == null
            ? localTransform
            : parent._worldTransform * localTransform;
        final position = worldTransform.transformPoint(anchor);
        final frame = SceneComponentFrame._(
          worldTransform: worldTransform,
          component: component,
          transform: transform,
          position: position,
          size: size,
          anchor: anchor,
          parent: parent,
          renderOrder: renderOrder++,
        );
        result.add(frame);
        visit(component.children, frame);
      }
    }

    visit(scene.components, null);
    return result;
  }

  static List<SceneComponentFrame> renderFrames(SceneDefinition scene) {
    final result = frames(scene);
    result.sort((first, second) {
      final priority = first.component.priority.compareTo(
        second.component.priority,
      );
      return priority == 0
          ? first.renderOrder.compareTo(second.renderOrder)
          : priority;
    });
    return result;
  }

  static List<ComponentInstance> paintOrder(SceneDefinition scene) {
    return renderFrames(scene).map((frame) => frame.component).toList();
  }

  static SceneComponentFrame? frameFor(
    SceneDefinition scene,
    String componentId,
  ) {
    for (final frame in frames(scene)) {
      if (frame.component.id == componentId) return frame;
    }
    return null;
  }

  static Offset topLeft(ComponentInstance component) {
    final size = sizeFor(component);
    final anchor = component.transform.anchor;
    return Offset(
      component.transform.position.x -
          size.width * anchor.x * component.transform.scale.x,
      component.transform.position.y -
          size.height * anchor.y * component.transform.scale.y,
    );
  }

  static bool contains(ComponentInstance component, Offset worldPoint) {
    final size = sizeFor(component);
    final transform = component.transform;
    final anchor = Offset(
      size.width * transform.anchor.x,
      size.height * transform.anchor.y,
    );
    final worldTransform = _AffineTransform.component(transform, anchor);
    final local = worldTransform.inverseTransformPoint(worldPoint);
    return Rect.fromLTWH(0, 0, size.width, size.height).contains(local);
  }

  static ComponentInstance? hitTest(SceneDefinition scene, Offset worldPoint) {
    final ordered = renderFrames(scene);
    for (final frame in ordered.reversed) {
      if (frame.component.editorMetadata.visible &&
          !frame.component.editorMetadata.locked &&
          containsFrame(frame, worldPoint)) {
        return frame.component;
      }
    }
    return null;
  }

  static Rect boundsForFrame(SceneComponentFrame frame) {
    final corners = [
      frame.localToWorld(Offset.zero),
      frame.localToWorld(Offset(frame.size.width, 0)),
      frame.localToWorld(Offset(0, frame.size.height)),
      frame.localToWorld(Offset(frame.size.width, frame.size.height)),
    ];
    final left = corners.map((point) => point.dx).reduce(math.min);
    final top = corners.map((point) => point.dy).reduce(math.min);
    final right = corners.map((point) => point.dx).reduce(math.max);
    final bottom = corners.map((point) => point.dy).reduce(math.max);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static bool containsFrame(SceneComponentFrame frame, Offset worldPoint) {
    final local = frame.worldToLocal(worldPoint);
    return (Offset.zero & frame.size).contains(local);
  }

  static SceneEditHandle? editHandleFor(
    SceneComponentFrame frame,
    Offset worldPoint, {
    double tolerance = 10,
  }) {
    final rotateHandle = frame.localToWorld(Offset(frame.size.width / 2, -24));
    if ((worldPoint - rotateHandle).distance <= tolerance) {
      return SceneEditHandle.rotate;
    }

    final scaleHandle = frame.localToWorld(Offset(frame.size.width, 0));
    if ((worldPoint - scaleHandle).distance <= tolerance) {
      return SceneEditHandle.scale;
    }

    if (frame.component.type.name != 'CircleComponent' &&
        frame.component.type.name != 'TextComponent') {
      final resizeHandle = frame.localToWorld(
        Offset(frame.size.width, frame.size.height),
      );
      if ((worldPoint - resizeHandle).distance <= tolerance) {
        return SceneEditHandle.resize;
      }
    }

    if (containsFrame(frame, worldPoint)) return SceneEditHandle.move;
    return null;
  }
}

/// Pure transform updates used by pointer editing and unit tests.
class SceneTransformMath {
  const SceneTransformMath._();

  static WorkspaceTransform move({
    required SceneDefinition scene,
    required SceneComponentFrame frame,
    required Offset worldAnchor,
  }) {
    return frame.transform.copyWith(
      position: _localPosition(scene, frame, worldAnchor),
    );
  }

  static Offset snapPointToGrid(Offset point, double gridSize) {
    if (!gridSize.isFinite || gridSize <= 0) return point;
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }

  static double snapScalarToGrid(double value, double gridSize) {
    if (!gridSize.isFinite || gridSize <= 0) return value;
    return (value / gridSize).round() * gridSize;
  }

  static double snapAngleToIncrement(double angle, double increment) {
    if (!increment.isFinite || increment <= 0) return angle;
    return (angle / increment).round() * increment;
  }

  static WorkspaceTransform resize({
    required SceneDefinition scene,
    required SceneComponentFrame frame,
    required Offset worldPoint,
    double minimumSize = 8,
  }) {
    final localPoint = frame.worldToLocal(worldPoint);
    final width = math.max(minimumSize, localPoint.dx);
    final height = math.max(minimumSize, localPoint.dy);
    return frame.transform.copyWith(
      position: _localPosition(scene, frame, frame.position),
      size: WorkspaceVector2(width, height),
    );
  }

  static WorkspaceTransform scale({
    required SceneComponentFrame frame,
    required Offset startWorldPoint,
    required Offset worldPoint,
    double minimumScale = 0.01,
  }) {
    final start = frame.worldToLocal(startWorldPoint) - frame.anchor;
    final current = frame.worldToLocal(worldPoint) - frame.anchor;
    if (start.distance == 0) return frame.transform;
    final factor = math.max(minimumScale, current.distance / start.distance);
    return frame.transform.copyWith(
      scale: WorkspaceVector2(
        frame.transform.scale.x * factor,
        frame.transform.scale.y * factor,
      ),
    );
  }

  static WorkspaceTransform rotate({
    required SceneDefinition scene,
    required SceneComponentFrame frame,
    required Offset startWorldPoint,
    required Offset worldPoint,
  }) {
    final parent = frame.parent;
    final start = parent == null
        ? startWorldPoint - frame.position
        : parent.worldToLocal(startWorldPoint) -
              parent.worldToLocal(frame.position);
    final current = parent == null
        ? worldPoint - frame.position
        : parent.worldToLocal(worldPoint) - parent.worldToLocal(frame.position);
    if (start.distance == 0 || current.distance == 0) {
      return frame.transform;
    }

    final delta =
        math.atan2(current.dy, current.dx) - math.atan2(start.dy, start.dx);
    return frame.transform.copyWith(angle: frame.transform.angle + delta);
  }

  static WorkspaceVector2 _localPosition(
    SceneDefinition scene,
    SceneComponentFrame frame,
    Offset worldPosition,
  ) {
    final parent = frame.parent;
    final localPosition = parent == null
        ? worldPosition
        : parent.worldToLocal(worldPosition);
    return WorkspaceVector2(localPosition.dx, localPosition.dy);
  }
}

/// A model-driven editing canvas for a single semantic scene.
typedef SceneSelectionWithModifiers = void Function(
  String? componentId, {
  required bool toggle,
  required bool extend,
});

class SceneCanvas extends StatefulWidget {
  final SceneDefinition scene;
  final String? selectedComponentId;
  final Set<String> selectedComponentIds;
  final ValueChanged<String?> onSelectionChanged;
  final SceneSelectionWithModifiers? onSelectionChangedWithModifiers;
  final ValueChanged<Set<String>>? onSelectionSetChanged;
  final void Function(String assetPath, Offset worldPosition)? onAssetDropped;
  final void Function(String componentId, WorkspaceTransform transform)?
  onTransformChanged;
  final ValueChanged<Map<String, WorkspaceTransform>>? onTransformsChanged;
  final ValueChanged<String>? onTransformEditStart;
  final ValueChanged<Set<String>>? onTransformGroupEditStart;
  final VoidCallback? onTransformEditEnd;
  final String? projectRootPath;
  final EditorComponentRenderRegistry renderRegistry;
  final bool showGrid;
  final double gridSize;
  final bool snapPosition;
  final bool snapResize;
  final bool snapRotation;
  final double rotationSnapDegrees;

  const SceneCanvas({
    super.key,
    required this.scene,
    required this.selectedComponentId,
    this.selectedComponentIds = const {},
    required this.onSelectionChanged,
    this.onSelectionChangedWithModifiers,
    this.onSelectionSetChanged,
    this.onAssetDropped,
    this.onTransformChanged,
    this.onTransformsChanged,
    this.onTransformEditStart,
    this.onTransformGroupEditStart,
    this.onTransformEditEnd,
    this.projectRootPath,
    this.renderRegistry = const EditorComponentRenderRegistry(),
    this.showGrid = true,
    this.gridSize = 32,
    this.snapPosition = false,
    this.snapResize = false,
    this.snapRotation = false,
    this.rotationSnapDegrees = 15,
  });

  @override
  State<SceneCanvas> createState() => _SceneCanvasState();
}

class _SceneCanvasState extends State<SceneCanvas> {
  static const _minZoom = 0.2;
  static const _maxZoom = 4.0;

  double _zoom = 1;
  Offset _pan = Offset.zero;
  Offset _gestureFocalPoint = Offset.zero;
  Offset _gestureWorldPoint = Offset.zero;
  double _gestureZoom = 1;
  Offset? _pointerDownPosition;
  bool _pointerMoved = false;
  SceneEditHandle? _editOperation;
  SceneComponentFrame? _editFrame;
  List<SceneComponentFrame> _editFrames = const [];

  Offset _editStartPoint = Offset.zero;
  Offset? _marqueeStart;
  Offset? _marqueeCurrent;
  final _images = <String, ui.Image>{};
  final _loadingImages = <String>{};
  final _unavailableImages = <String>{};
  final _focusNode = FocusNode(debugLabel: 'Scene View');
  final _canvasKey = GlobalKey();
  Size _viewportSize = Size.zero;

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleImageLoads();
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          _viewportSize = size;
          final viewport = SceneViewport(size: size, zoom: _zoom, pan: _pan);
          return DragTarget<WorkspaceAssetDragData>(
            onAcceptWithDetails: (details) {
              final renderObject = _canvasKey.currentContext
                  ?.findRenderObject();
              final globalPosition = details.data.globalPosition;
              if (renderObject is! RenderBox ||
                  globalPosition == null ||
                  widget.onAssetDropped == null) {
                return;
              }
              final localPosition = renderObject.globalToLocal(globalPosition);
              widget.onAssetDropped!(
                details.data.assetPath,
                viewport.viewportToWorld(localPosition),
              );
            },
            builder: (context, candidates, rejected) => Focus(
              key: _canvasKey,
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _handleNavigationKey,
              child: Stack(
                children: [
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) {
                      _focusNode.requestFocus();
                      _pointerDownPosition = event.localPosition;
                      _pointerMoved = false;
                      final keyboard = HardwareKeyboard.instance;
                      final modifiedSelection =
                          keyboard.isControlPressed ||
                          keyboard.isMetaPressed ||
                          keyboard.isShiftPressed;
                      final worldPoint = viewport.viewportToWorld(
                        event.localPosition,
                      );
                      if (!modifiedSelection) {
                        _beginEdit(worldPoint);
                        final ids = _editFrames
                            .map((frame) => frame.component.id)
                            .toSet();
                        if (_editOperation != null) {
                          if (ids.length > 1) {
                            widget.onTransformGroupEditStart?.call(ids);
                          } else if (ids.isNotEmpty) {
                            widget.onTransformEditStart?.call(ids.single);
                          }
                        } else if (SceneCanvasGeometry.hitTest(
                              widget.scene,
                              worldPoint,
                            ) ==
                            null) {
                          _marqueeStart = worldPoint;
                          _marqueeCurrent = worldPoint;
                        }
                      }
                    },
                    onPointerMove: (event) {
                      final down = _pointerDownPosition;
                      if (down != null &&
                          (event.localPosition - down).distance > 4) {
                        _pointerMoved = true;
                      }
                      final marqueeStart = _marqueeStart;
                      if (marqueeStart != null) {
                        final worldPoint = viewport.viewportToWorld(
                          event.localPosition,
                        );
                        setState(() => _marqueeCurrent = worldPoint);
                        return;
                      }
                      if (_editOperation == null || _editFrame == null) return;
                      _applyEdit(viewport.viewportToWorld(event.localPosition));
                    },
                    onPointerUp: (event) {
                      final wasTap = !_pointerMoved;
                      final wasEditing = _editOperation != null;
                      final marquee = _marqueeStart != null && _pointerMoved;
                      final marqueeRect = marquee
                          ? Rect.fromPoints(_marqueeStart!, _marqueeCurrent!)
                          : null;
                      _clearEdit();
                      _marqueeStart = null;
                      _marqueeCurrent = null;
                      _pointerDownPosition = null;
                      _pointerMoved = false;
                      if (wasEditing) {
                        widget.onTransformEditEnd?.call();
                        return;
                      }
                      if (marquee && marqueeRect != null) {
                        final selected =
                            SceneCanvasGeometry.frames(widget.scene)
                                .where(
                                  (frame) =>
                                      frame.component.editorMetadata.visible &&
                                      !frame.component.editorMetadata.locked &&
                                      SceneCanvasGeometry.boundsForFrame(frame)
                                          .overlaps(marqueeRect),
                                )
                                .map((frame) => frame.component.id)
                                .toSet();
                        widget.onSelectionSetChanged?.call(selected);
                        return;
                      }
                      if (wasTap) {
                        final component = SceneCanvasGeometry.hitTest(
                          widget.scene,
                          viewport.viewportToWorld(event.localPosition),
                        );
                        final keyboard = HardwareKeyboard.instance;
                        final toggle =
                            keyboard.isControlPressed || keyboard.isMetaPressed;
                        final extend = keyboard.isShiftPressed;
                        final handler = widget.onSelectionChangedWithModifiers;
                        if (handler != null) {
                          handler(
                            component?.id,
                            toggle: toggle,
                            extend: extend,
                          );
                        } else {
                          widget.onSelectionChanged(component?.id);
                        }
                      }
                    },
                    onPointerCancel: (_) {
                      if (_editOperation != null) {
                        widget.onTransformEditEnd?.call();
                      }
                      _clearEdit();
                      _marqueeStart = null;
                      _marqueeCurrent = null;
                      _pointerDownPosition = null;
                      _pointerMoved = false;
                    },
                    onPointerSignal: (event) {
                      if (event is! PointerScrollEvent) return;
                      final factor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;
                      final nextZoom = (_zoom * factor).clamp(
                        _minZoom,
                        _maxZoom,
                      );
                      final center = Offset(size.width / 2, size.height / 2);
                      final worldPoint = viewport.viewportToWorld(
                        event.localPosition,
                      );
                      setState(() {
                        _zoom = nextZoom;
                        _pan =
                            event.localPosition -
                            center -
                            worldPoint * nextZoom;
                      });
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) {
                        if (_editOperation != null || _marqueeStart != null) {
                          return;
                        }
                        _gestureFocalPoint = details.localFocalPoint;
                        _gestureZoom = _zoom;
                        _gestureWorldPoint = viewport.viewportToWorld(
                          _gestureFocalPoint,
                        );
                      },
                      onScaleUpdate: (details) {
                        if (_editOperation != null || _marqueeStart != null) {
                          return;
                        }
                        final nextZoom = (_gestureZoom * details.scale).clamp(
                          _minZoom,
                          _maxZoom,
                        );
                        final center = Offset(size.width / 2, size.height / 2);
                        setState(() {
                          _zoom = nextZoom;
                          _pan =
                              details.localFocalPoint -
                              center -
                              _gestureWorldPoint * nextZoom;
                        });
                      },
                      child: CustomPaint(
                        painter: _SceneCanvasPainter(
                          scene: widget.scene,
                          viewport: viewport,
                          selectedComponentId: widget.selectedComponentId,
                          selectedComponentIds: widget.selectedComponentIds,
                          marqueeRect:
                              _marqueeStart == null || _marqueeCurrent == null
                              ? null
                              : Rect.fromPoints(
                                  _marqueeStart!,
                                  _marqueeCurrent!,
                                ),
                          images: _images,
                          renderRegistry: widget.renderRegistry,
                          placeholderColor: colors.primaryContainer,
                          outlineColor: colors.primary,
                          gridColor: colors.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                          showGrid: widget.showGrid,
                          gridSize: widget.gridSize,
                          backgroundColor: widget.scene.backgroundColor,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: colors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Frame selected (F)',
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.selectedComponentId == null
                                ? null
                                : _frameSelected,
                            icon: const Icon(Icons.center_focus_strong),
                          ),
                          IconButton(
                            tooltip: 'Fit scene (Home)',
                            visualDensity: VisualDensity.compact,
                            onPressed: _fitScene,
                            icon: const Icon(Icons.fit_screen),
                          ),
                          IconButton(
                            tooltip: 'Reset view (0)',
                            visualDensity: VisualDensity.compact,
                            onPressed: _resetViewport,
                            icon: const Icon(Icons.restart_alt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  KeyEventResult _handleNavigationKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _fitScene();
      } else {
        _frameSelected();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _fitScene();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.digit0 ||
        event.logicalKey == LogicalKeyboardKey.numpad0) {
      _resetViewport();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _resetViewport() {
    setState(() {
      _zoom = 1;
      _pan = Offset.zero;
    });
  }

  void _frameSelected() {
    final id = widget.selectedComponentId;
    if (id == null) return;
    final frame = SceneCanvasGeometry.frameFor(widget.scene, id);
    if (frame == null) return;
    _setViewportToBounds(SceneCanvasGeometry.boundsForFrame(frame));
  }

  void _fitScene() {
    final frames = SceneCanvasGeometry.frames(widget.scene)
        .where((frame) => frame.component.editorMetadata.visible)
        .toList();
    if (frames.isEmpty) {
      _resetViewport();
      return;
    }
    final bounds = frames
        .map(SceneCanvasGeometry.boundsForFrame)
        .reduce((first, second) => first.expandToInclude(second));
    _setViewportToBounds(bounds);
  }

  void _setViewportToBounds(Rect bounds) {
    final viewport = SceneViewport.fitBounds(_viewportSize, bounds);
    setState(() {
      _zoom = viewport.zoom;
      _pan = viewport.pan;
    });
  }

  void _beginEdit(Offset worldPoint) {
    final selectedIds = widget.selectedComponentIds.isEmpty
        ? {if (widget.selectedComponentId != null) widget.selectedComponentId!}
        : widget.selectedComponentIds;
    final frames = SceneCanvasGeometry.frames(widget.scene).where((frame) {
      return selectedIds.contains(frame.component.id) &&
          frame.component.type.isPositionComponent &&
          frame.component.editorMetadata.visible &&
          !frame.component.editorMetadata.locked;
    }).toList();
    final primary = frames.cast<SceneComponentFrame?>().firstWhere(
      (frame) => frame?.component.id == widget.selectedComponentId,
      orElse: () => null,
    );
    if (primary == null) return;

    final primaryHandle = SceneCanvasGeometry.editHandleFor(
      primary,
      worldPoint,
    );
    if (primaryHandle != null && primaryHandle != SceneEditHandle.move) {
      _editOperation = primaryHandle;
      _editFrame = primary;
      _editFrames = [primary];
    } else {
      final selectedFrame = frames.cast<SceneComponentFrame?>().firstWhere(
        (frame) =>
            frame != null &&
            SceneCanvasGeometry.containsFrame(frame, worldPoint),
        orElse: () => null,
      );
      if (selectedFrame == null) return;
      final movableIds = frames.map((frame) => frame.component.id).toSet();
      _editFrames = frames.where((frame) {
        var parent = frame.parent;
        while (parent != null) {
          if (movableIds.contains(parent.component.id)) return false;
          parent = parent.parent;
        }
        return true;
      }).toList();
      _editOperation = SceneEditHandle.move;
      _editFrame = selectedFrame;
    }
    _editStartPoint = worldPoint;
  }

  void _applyEdit(Offset worldPoint) {
    final frame = _editFrame;
    final operation = _editOperation;
    if (frame == null || operation == null) return;

    final bypassSnapping = HardwareKeyboard.instance.isAltPressed;
    if (operation == SceneEditHandle.move) {
      var delta = worldPoint - _editStartPoint;
      if (widget.snapPosition && !bypassSnapping) {
        final primaryWorldPosition = frame.position + delta;
        delta =
            SceneTransformMath.snapPointToGrid(
              primaryWorldPosition,
              widget.gridSize,
            ) -
            frame.position;
      }
      final transforms = <String, WorkspaceTransform>{
        for (final editFrame in _editFrames)
          editFrame.component.id: SceneTransformMath.move(
            scene: widget.scene,
            frame: editFrame,
            worldAnchor: editFrame.position + delta,
          ),
      };
      if (widget.onTransformsChanged != null) {
        widget.onTransformsChanged!(transforms);
      } else if (transforms.length == 1) {
        widget.onTransformChanged?.call(
          transforms.keys.single,
          transforms.values.single,
        );
      }
      return;
    }

    var transform = switch (operation) {
      SceneEditHandle.move => frame.transform,
      SceneEditHandle.resize => SceneTransformMath.resize(
        scene: widget.scene,
        frame: frame,
        worldPoint: worldPoint,
      ),
      SceneEditHandle.scale => SceneTransformMath.scale(
        frame: frame,
        startWorldPoint: _editStartPoint,
        worldPoint: worldPoint,
      ),
      SceneEditHandle.rotate => SceneTransformMath.rotate(
        scene: widget.scene,
        frame: frame,
        startWorldPoint: _editStartPoint,
        worldPoint: worldPoint,
      ),
    };
    if (!bypassSnapping &&
        widget.snapResize &&
        operation == SceneEditHandle.resize) {
      transform = transform.copyWith(
        size: WorkspaceVector2(
          math.max(
            8,
            SceneTransformMath.snapScalarToGrid(
              transform.size.x,
              widget.gridSize,
            ),
          ),
          math.max(
            8,
            SceneTransformMath.snapScalarToGrid(
              transform.size.y,
              widget.gridSize,
            ),
          ),
        ),
      );
    }
    if (!bypassSnapping &&
        widget.snapRotation &&
        operation == SceneEditHandle.rotate) {
      transform = transform.copyWith(
        angle: SceneTransformMath.snapAngleToIncrement(
          transform.angle,
          widget.rotationSnapDegrees * math.pi / 180,
        ),
      );
    }
    widget.onTransformChanged?.call(frame.component.id, transform);
  }

  void _clearEdit() {
    _editOperation = null;
    _editFrame = null;
    _editFrames = const [];
  }

  void _scheduleImageLoads() {
    final candidates = <String, String>{};
    for (final frame in SceneCanvasGeometry.renderFrames(widget.scene)) {
      if (widget.renderRegistry.resolve(frame.component).primitive !=
          EditorPreviewPrimitive.sprite) {
        continue;
      }
      final asset = _assetPath(frame.component);
      if (asset != null) candidates[frame.component.id] = asset;
    }

    for (final entry in candidates.entries) {
      final key = '${entry.key}:${entry.value}';
      if (_images.containsKey(key) ||
          _loadingImages.contains(key) ||
          _unavailableImages.contains(key)) {
        continue;
      }
      _loadingImages.add(key);
      unawaited(_loadImage(key, entry.value));
    }
  }

  Future<void> _loadImage(String key, String candidate) async {
    try {
      final filePath = _resolveAssetPath(candidate);
      final file = File(filePath);
      if (!await file.exists()) {
        _unavailableImages.add(key);
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _images[key] = frame.image);
    } catch (_) {
      _unavailableImages.add(key);
    } finally {
      _loadingImages.remove(key);
    }
  }

  String _resolveAssetPath(String candidate) {
    if (path.isAbsolute(candidate) || widget.projectRootPath == null) {
      return candidate;
    }
    return path.join(widget.projectRootPath!, candidate);
  }

  String? _assetPath(ComponentInstance component) {
    final semanticAssetPath = component.assetPath;
    if (semanticAssetPath != null && semanticAssetPath.trim().isNotEmpty) {
      return semanticAssetPath.trim();
    }
    const names = ['asset', 'assetPath', 'image', 'imagePath', 'spritePath'];
    for (final name in names) {
      final value = component.properties[name];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

class _SceneCanvasPainter({
  required final SceneDefinition scene,
  required final SceneViewport viewport,
  required final String? selectedComponentId,
  required final Set<String> selectedComponentIds,
  required final Rect? marqueeRect,
  required final Map<String, ui.Image> images,
  required final EditorComponentRenderRegistry renderRegistry,
  required final Color placeholderColor,
  required final Color outlineColor,
  required final Color gridColor,
  required final bool showGrid,
  required final double gridSize,
  required final int backgroundColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(backgroundColor),
    );
    if (showGrid) _paintGrid(canvas, size);
    final frames = SceneCanvasGeometry.renderFrames(scene)
        .where((frame) => frame.component.editorMetadata.visible)
        .toList();
    for (final frame in frames) {
      _paintComponent(canvas, frame);
      if (selectedComponentIds.contains(frame.component.id)) {
        _paintSelectionOutline(canvas, frame);
      }
    }

    final selectedFrame = selectedComponentId == null
        ? null
        : frames.cast<SceneComponentFrame?>().firstWhere(
            (frame) => frame?.component.id == selectedComponentId,
            orElse: () => null,
          );
    if (selectedFrame != null &&
        selectedFrame.component.type.isPositionComponent &&
        selectedFrame.component.editorMetadata.visible &&
        !selectedFrame.component.editorMetadata.locked) {
      _paintSelectionGizmo(canvas, selectedFrame);
    }
    final marquee = marqueeRect;
    if (marquee != null) {
      final first = viewport.worldToViewport(marquee.topLeft);
      final second = viewport.worldToViewport(marquee.bottomRight);
      final rect = Rect.fromPoints(first, second);
      canvas.drawRect(
        rect,
        Paint()
          ..color = outlineColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _paintSelectionOutline(Canvas canvas, SceneComponentFrame frame) {
    canvas.save();
    final screenOrigin = viewport.worldToViewport(Offset.zero);
    canvas.translate(screenOrigin.dx, screenOrigin.dy);
    canvas.scale(viewport.zoom);
    canvas.transform(frame._worldTransform.toCanvasTransform());
    canvas.drawRect(
      Offset.zero & frame.size,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / viewport.zoom,
    );
    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final step = (gridSize * viewport.zoom).clamp(4.0, 256.0);
    final center = viewport.worldToViewport(Offset.zero);
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var x = center.dx % step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = center.dy % step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintComponent(Canvas canvas, SceneComponentFrame frame) {
    final data = renderRegistry.resolve(frame.component);
    final image = data.primitive == EditorPreviewPrimitive.sprite
        ? _imageFor(frame.component)
        : null;
    canvas.save();
    final screenOrigin = viewport.worldToViewport(Offset.zero);
    canvas.translate(screenOrigin.dx, screenOrigin.dy);
    canvas.scale(viewport.zoom);
    canvas.transform(frame._worldTransform.toCanvasTransform());

    final rect = Offset.zero & frame.size;
    final color = data.color ?? _colorFor(frame.component);
    final paint = data.paint ?? (Paint()..color = color);
    switch (data.primitive) {
      case EditorPreviewPrimitive.sprite:
        if (image == null) {
          _paintPlaceholder(
            canvas,
            rect,
            data.label,
            color,
            unsupported: false,
          );
        } else {
          canvas.drawImageRect(
            image,
            Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
            rect,
            Paint()..filterQuality = FilterQuality.medium,
          );
        }
        break;
      case EditorPreviewPrimitive.text:
        final painter = TextPainter(
          text: TextSpan(
            text: data.text ?? data.label,
            style:
                data.textStyle ??
                TextStyle(color: color, fontSize: data.fontSize),
          ),
          textDirection: data.textDirection,
        )..layout(maxWidth: frame.size.width);
        painter.paint(canvas, Offset.zero);
        break;
      case EditorPreviewPrimitive.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case EditorPreviewPrimitive.circle:
        final diameter = math.min(frame.size.width, frame.size.height);
        canvas.drawCircle(rect.center, diameter / 2, paint);
        break;
      case EditorPreviewPrimitive.polygon:
        if (data.vertices.length >= 3) {
          final minX = data.vertices.map((vertex) => vertex.x).reduce(math.min);
          final minY = data.vertices.map((vertex) => vertex.y).reduce(math.min);
          final path = Path()
            ..moveTo(
              data.vertices.first.x - minX,
              data.vertices.first.y - minY,
            );
          for (final vertex in data.vertices.skip(1)) {
            path.lineTo(vertex.x - minX, vertex.y - minY);
          }
          canvas.drawPath(path..close(), paint);
        } else {
          _paintPlaceholder(canvas, rect, 'Polygon', color, unsupported: true);
        }
        break;
      case EditorPreviewPrimitive.ellipse:
        canvas.drawOval(rect, paint);
        break;
      case EditorPreviewPrimitive.placeholder:
        _paintPlaceholder(
          canvas,
          rect,
          'Unsupported\n${data.label}',
          color,
          unsupported: true,
        );
        break;
    }
    canvas.restore();
  }

  void _paintPlaceholder(
    Canvas canvas,
    Rect rect,
    String label,
    Color color, {
    required bool unsupported,
  }) {
    final markerColor = unsupported ? Colors.deepOrange : color;
    canvas.drawRect(
      rect,
      Paint()
        ..color = Color.alphaBlend(
          markerColor.withValues(alpha: 0.24),
          placeholderColor,
        ),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = markerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / viewport.zoom,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: markerColor,
          fontSize: 10 / viewport.zoom,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: math.max(0, rect.width - 8 / viewport.zoom));
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  void _paintSelectionGizmo(Canvas canvas, SceneComponentFrame frame) {
    canvas.save();
    final screenOrigin = viewport.worldToViewport(Offset.zero);
    canvas.translate(screenOrigin.dx, screenOrigin.dy);
    canvas.scale(viewport.zoom);
    canvas.transform(frame._worldTransform.toCanvasTransform());

    final selection = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / viewport.zoom;
    final rect = Offset.zero & frame.size;
    canvas.drawRect(rect, selection);

    final handleSize = 8 / viewport.zoom;
    if (frame.component.type.name != 'CircleComponent' &&
        frame.component.type.name != 'TextComponent') {
      final resizeHandle = Offset(frame.size.width, frame.size.height);
      canvas.drawRect(
        Rect.fromCenter(
          center: resizeHandle,
          width: handleSize,
          height: handleSize,
        ),
        Paint()
          ..color = outlineColor
          ..style = PaintingStyle.fill,
      );
    }

    final scaleHandle = Offset(frame.size.width, 0);
    final scaleHandleSize = handleSize * 1.4;
    final scalePath = Path()
      ..moveTo(scaleHandle.dx, scaleHandle.dy - scaleHandleSize / 2)
      ..lineTo(scaleHandle.dx + scaleHandleSize / 2, scaleHandle.dy)
      ..lineTo(scaleHandle.dx, scaleHandle.dy + scaleHandleSize / 2)
      ..lineTo(scaleHandle.dx - scaleHandleSize / 2, scaleHandle.dy)
      ..close();
    canvas.drawPath(
      scalePath,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.fill,
    );

    final rotateHandle = Offset(frame.size.width / 2, -24);
    canvas.drawLine(Offset(frame.size.width / 2, 0), rotateHandle, selection);
    canvas.drawCircle(
      rotateHandle,
      handleSize / 2,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  ui.Image? _imageFor(ComponentInstance component) {
    final asset = _assetValue(component);
    if (asset == null) return null;
    final key = '${component.id}:$asset';
    return images[key];
  }

  String? _assetValue(ComponentInstance component) {
    final semanticAssetPath = component.assetPath;
    if (semanticAssetPath != null && semanticAssetPath.trim().isNotEmpty) {
      return semanticAssetPath.trim();
    }
    const names = ['asset', 'assetPath', 'image', 'imagePath', 'spritePath'];
    for (final name in names) {
      final value = component.properties[name];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Color _colorFor(ComponentInstance component) {
    var hash = 0;
    for (final codeUnit in component.id.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0xFFFFFF;
    }
    return Color(0xFF000000 | (hash ^ 0x446688));
  }

  @override
  bool shouldRepaint(covariant _SceneCanvasPainter oldDelegate) {
    return scene != oldDelegate.scene ||
        viewport != oldDelegate.viewport ||
        selectedComponentId != oldDelegate.selectedComponentId ||
        selectedComponentIds.length !=
            oldDelegate.selectedComponentIds.length ||
        !selectedComponentIds.containsAll(oldDelegate.selectedComponentIds) ||
        marqueeRect != oldDelegate.marqueeRect ||
        images != oldDelegate.images ||
        !identical(renderRegistry, oldDelegate.renderRegistry) ||
        placeholderColor != oldDelegate.placeholderColor ||
        outlineColor != oldDelegate.outlineColor ||
        gridColor != oldDelegate.gridColor ||
        showGrid != oldDelegate.showGrid ||
        gridSize != oldDelegate.gridSize ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
