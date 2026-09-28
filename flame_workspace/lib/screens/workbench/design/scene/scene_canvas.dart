import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../../workbench/model/semantic_model.dart';

/// Converts between semantic scene coordinates and the visible canvas.
class SceneViewport {
  final Size size;
  final double zoom;
  final Offset pan;

  const SceneViewport({
    required this.size,
    this.zoom = 1,
    this.pan = Offset.zero,
  });

  Offset worldToViewport(Offset point) {
    final center = Offset(size.width / 2, size.height / 2);
    return center + pan + point * zoom;
  }

  Offset viewportToWorld(Offset point) {
    final center = Offset(size.width / 2, size.height / 2);
    return (point - center - pan) / zoom;
  }
}

/// Operations available on a selected component in the Scene View.
enum SceneEditHandle { move, resize, rotate }

/// A component's world-space frame, including its parent-relative transform.
class SceneComponentFrame {
  final ComponentInstance component;
  final WorkspaceTransform transform;
  final Offset position;
  final double angle;
  final Size size;
  final Offset anchor;
  final SceneComponentFrame? parent;
  final int renderOrder;

  const SceneComponentFrame({
    required this.component,
    required this.transform,
    required this.position,
    required this.angle,
    required this.size,
    required this.anchor,
    required this.parent,
    required this.renderOrder,
  });

  Offset get topLeft => position - _rotate(anchor, angle);

  Offset localToWorld(Offset localPoint) {
    return position + _rotate(localPoint - anchor, angle);
  }

  Offset worldToLocal(Offset worldPoint) {
    return _rotate(worldPoint - position, -angle) + anchor;
  }
}

/// Geometry, ordering, hit testing, and transform math for the Scene View.
class SceneCanvasGeometry {
  const SceneCanvasGeometry._();

  static const fallbackSize = Size.square(64);

  static Size sizeFor(ComponentInstance component) {
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
        final localPosition = Offset(
          transform.position.x,
          transform.position.y,
        );
        final position = parent == null
            ? localPosition
            : parent.localToWorld(localPosition);
        final angle = parent == null
            ? transform.angle
            : parent.angle + transform.angle;
        final frame = SceneComponentFrame(
          component: component,
          transform: transform,
          position: position,
          angle: angle,
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
      component.transform.position.x - size.width * anchor.x,
      component.transform.position.y - size.height * anchor.y,
    );
  }

  static bool contains(ComponentInstance component, Offset worldPoint) {
    final size = sizeFor(component);
    final transform = component.transform;
    final anchor = Offset(
      size.width * transform.anchor.x,
      size.height * transform.anchor.y,
    );
    final position = Offset(transform.position.x, transform.position.y);
    final local = _rotate(worldPoint - position, -transform.angle) + anchor;
    return Rect.fromLTWH(0, 0, size.width, size.height).contains(local);
  }

  static ComponentInstance? hitTest(SceneDefinition scene, Offset worldPoint) {
    final ordered = renderFrames(scene);
    for (final frame in ordered.reversed) {
      if (containsFrame(frame, worldPoint)) return frame.component;
    }
    return null;
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

    final resizeHandle = frame.localToWorld(
      Offset(frame.size.width, frame.size.height),
    );
    if ((worldPoint - resizeHandle).distance <= tolerance) {
      return SceneEditHandle.resize;
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

  static WorkspaceTransform resize({
    required SceneDefinition scene,
    required SceneComponentFrame frame,
    required Offset worldPoint,
    double minimumSize = 8,
  }) {
    final localPoint = frame.worldToLocal(worldPoint);
    final width = math.max(minimumSize, localPoint.dx);
    final height = math.max(minimumSize, localPoint.dy);
    final newAnchor = Offset(
      width * frame.transform.anchor.x,
      height * frame.transform.anchor.y,
    );
    final worldPosition = frame.topLeft + _rotate(newAnchor, frame.angle);

    return frame.transform.copyWith(
      position: _localPosition(scene, frame, worldPosition),
      size: WorkspaceVector2(width, height),
    );
  }

  static WorkspaceTransform rotate({
    required SceneDefinition scene,
    required SceneComponentFrame frame,
    required Offset startWorldPoint,
    required Offset worldPoint,
  }) {
    final start = startWorldPoint - frame.position;
    final current = worldPoint - frame.position;
    if (start.distance == 0 || current.distance == 0) {
      return frame.transform;
    }

    final delta =
        math.atan2(current.dy, current.dx) - math.atan2(start.dy, start.dx);
    final parentAngle = frame.parent?.angle ?? 0;
    return frame.transform.copyWith(angle: frame.angle + delta - parentAngle);
  }

  static WorkspaceVector2 _localPosition(
    SceneDefinition scene,
    SceneComponentFrame frame,
    Offset worldPosition,
  ) {
    final parent = frame.parent;
    final localPosition = parent == null
        ? worldPosition
        : _rotate(worldPosition - parent.topLeft, -parent.angle);
    return WorkspaceVector2(localPosition.dx, localPosition.dy);
  }
}

/// A model-driven editing canvas for a single semantic scene.
class SceneCanvas extends StatefulWidget {
  final SceneDefinition scene;
  final String? selectedComponentId;
  final ValueChanged<String?> onSelectionChanged;
  final void Function(String componentId, WorkspaceTransform transform)?
  onTransformChanged;
  final ValueChanged<String>? onTransformEditStart;
  final VoidCallback? onTransformEditEnd;
  final String? projectRootPath;

  const SceneCanvas({
    super.key,
    required this.scene,
    required this.selectedComponentId,
    required this.onSelectionChanged,
    this.onTransformChanged,
    this.onTransformEditStart,
    this.onTransformEditEnd,
    this.projectRootPath,
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
  Offset _editGrabOffset = Offset.zero;
  Offset _editStartPoint = Offset.zero;
  final _images = <String, ui.Image>{};
  final _loadingImages = <String>{};
  final _unavailableImages = <String>{};

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
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
          final viewport = SceneViewport(size: size, zoom: _zoom, pan: _pan);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _pointerDownPosition = event.localPosition;
              _pointerMoved = false;
              _beginEdit(viewport.viewportToWorld(event.localPosition));
              final frame = _editFrame;
              if (_editOperation != null && frame != null) {
                widget.onTransformEditStart?.call(frame.component.id);
              }
            },
            onPointerMove: (event) {
              final down = _pointerDownPosition;
              if (down != null && (event.localPosition - down).distance > 4) {
                _pointerMoved = true;
              }
              if (_editOperation == null || _editFrame == null) return;
              _applyEdit(viewport.viewportToWorld(event.localPosition));
            },
            onPointerUp: (event) {
              final wasTap = !_pointerMoved;
              final wasEditing = _editOperation != null;
              _clearEdit();
              _pointerDownPosition = null;
              _pointerMoved = false;
              if (wasEditing) {
                widget.onTransformEditEnd?.call();
                return;
              }
              if (wasTap) {
                final component = SceneCanvasGeometry.hitTest(
                  widget.scene,
                  viewport.viewportToWorld(event.localPosition),
                );
                widget.onSelectionChanged(component?.id);
              }
            },
            onPointerCancel: (_) {
              if (_editOperation != null) widget.onTransformEditEnd?.call();
              _clearEdit();
              _pointerDownPosition = null;
              _pointerMoved = false;
            },
            onPointerSignal: (event) {
              if (event is! PointerScrollEvent) return;
              final factor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;
              final nextZoom = (_zoom * factor).clamp(_minZoom, _maxZoom);
              final center = Offset(size.width / 2, size.height / 2);
              final worldPoint = viewport.viewportToWorld(event.localPosition);
              setState(() {
                _zoom = nextZoom;
                _pan = event.localPosition - center - worldPoint * nextZoom;
              });
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                if (_editOperation != null) return;
                _gestureFocalPoint = details.localFocalPoint;
                _gestureZoom = _zoom;
                _gestureWorldPoint = viewport.viewportToWorld(
                  _gestureFocalPoint,
                );
              },
              onScaleUpdate: (details) {
                if (_editOperation != null) return;
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
                  images: _images,
                  placeholderColor: colors.primaryContainer,
                  outlineColor: colors.primary,
                  gridColor: colors.outlineVariant.withValues(alpha: 0.35),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _beginEdit(Offset worldPoint) {
    final selectedId = widget.selectedComponentId;
    if (selectedId == null) return;
    final frame = SceneCanvasGeometry.frameFor(widget.scene, selectedId);
    if (frame == null || !frame.component.type.isPositionComponent) return;
    final operation = SceneCanvasGeometry.editHandleFor(frame, worldPoint);
    if (operation == null) return;

    _editOperation = operation;
    _editFrame = frame;
    _editStartPoint = worldPoint;
    _editGrabOffset = worldPoint - frame.position;
  }

  void _applyEdit(Offset worldPoint) {
    final frame = _editFrame;
    final operation = _editOperation;
    final callback = widget.onTransformChanged;
    if (frame == null || operation == null || callback == null) return;

    final transform = switch (operation) {
      SceneEditHandle.move => SceneTransformMath.move(
        scene: widget.scene,
        frame: frame,
        worldAnchor: worldPoint - _editGrabOffset,
      ),
      SceneEditHandle.resize => SceneTransformMath.resize(
        scene: widget.scene,
        frame: frame,
        worldPoint: worldPoint,
      ),
      SceneEditHandle.rotate => SceneTransformMath.rotate(
        scene: widget.scene,
        frame: frame,
        startWorldPoint: _editStartPoint,
        worldPoint: worldPoint,
      ),
    };
    callback(frame.component.id, transform);
  }

  void _clearEdit() {
    _editOperation = null;
    _editFrame = null;
  }

  void _scheduleImageLoads() {
    final candidates = <String, String>{};
    for (final frame in SceneCanvasGeometry.renderFrames(widget.scene)) {
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

class _SceneCanvasPainter extends CustomPainter {
  final SceneDefinition scene;
  final SceneViewport viewport;
  final String? selectedComponentId;
  final Map<String, ui.Image> images;
  final Color placeholderColor;
  final Color outlineColor;
  final Color gridColor;

  const _SceneCanvasPainter({
    required this.scene,
    required this.viewport,
    required this.selectedComponentId,
    required this.images,
    required this.placeholderColor,
    required this.outlineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    final frames = SceneCanvasGeometry.renderFrames(scene);
    for (final frame in frames) {
      _paintComponent(canvas, frame);
    }

    final selectedFrame = selectedComponentId == null
        ? null
        : frames.cast<SceneComponentFrame?>().firstWhere(
            (frame) => frame?.component.id == selectedComponentId,
            orElse: () => null,
          );
    if (selectedFrame != null &&
        selectedFrame.component.type.isPositionComponent) {
      _paintSelectionGizmo(canvas, selectedFrame);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final step = (32 * viewport.zoom).clamp(12.0, 96.0);
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
    final image = _imageFor(frame.component);
    canvas.save();
    final screenPosition = viewport.worldToViewport(frame.position);
    canvas.translate(screenPosition.dx, screenPosition.dy);
    canvas.scale(viewport.zoom);
    canvas.rotate(frame.angle);
    canvas.translate(-frame.anchor.dx, -frame.anchor.dy);

    final rect = Offset.zero & frame.size;
    if (image == null) {
      final fill = Paint()
        ..color = Color.alphaBlend(
          _colorFor(frame.component).withValues(alpha: 0.72),
          placeholderColor,
        )
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);
      final border = Paint()
        ..color = _colorFor(frame.component)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / viewport.zoom;
      canvas.drawRect(rect, border);
    } else {
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    canvas.restore();
  }

  void _paintSelectionGizmo(Canvas canvas, SceneComponentFrame frame) {
    canvas.save();
    final screenPosition = viewport.worldToViewport(frame.position);
    canvas.translate(screenPosition.dx, screenPosition.dy);
    canvas.scale(viewport.zoom);
    canvas.rotate(frame.angle);
    canvas.translate(-frame.anchor.dx, -frame.anchor.dy);

    final selection = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / viewport.zoom;
    final rect = Offset.zero & frame.size;
    canvas.drawRect(rect, selection);

    final handleSize = 8 / viewport.zoom;
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
        images != oldDelegate.images ||
        placeholderColor != oldDelegate.placeholderColor ||
        outlineColor != oldDelegate.outlineColor ||
        gridColor != oldDelegate.gridColor;
  }
}

Offset _rotate(Offset point, double angle) {
  final cosine = math.cos(angle);
  final sine = math.sin(angle);
  return Offset(
    point.dx * cosine - point.dy * sine,
    point.dx * sine + point.dy * cosine,
  );
}
