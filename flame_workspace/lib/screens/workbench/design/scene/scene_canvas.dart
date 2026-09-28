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

/// Geometry and ordering rules shared by painting and pointer hit testing.
class SceneCanvasGeometry {
  const SceneCanvasGeometry._();

  static const fallbackSize = Size.square(64);

  static Size sizeFor(ComponentInstance component) {
    final size = component.transform.size;
    return size.x > 0 && size.y > 0 ? Size(size.x, size.y) : fallbackSize;
  }

  static List<ComponentInstance> paintOrder(SceneDefinition scene) {
    final ordered = <({ComponentInstance component, int order})>[];
    var order = 0;

    void visit(Iterable<ComponentInstance> components) {
      for (final component in components) {
        ordered.add((component: component, order: order++));
        visit(component.children);
      }
    }

    visit(scene.components);
    ordered.sort((first, second) {
      final priority = first.component.priority.compareTo(
        second.component.priority,
      );
      return priority == 0 ? first.order.compareTo(second.order) : priority;
    });
    return ordered.map((entry) => entry.component).toList();
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
    final translated = worldPoint - position;
    final cosine = math.cos(-transform.angle);
    final sine = math.sin(-transform.angle);
    final local = Offset(
      translated.dx * cosine - translated.dy * sine + anchor.dx,
      translated.dx * sine + translated.dy * cosine + anchor.dy,
    );
    return Rect.fromLTWH(0, 0, size.width, size.height).contains(local);
  }

  static ComponentInstance? hitTest(SceneDefinition scene, Offset worldPoint) {
    final ordered = paintOrder(scene);
    for (final component in ordered.reversed) {
      if (contains(component, worldPoint)) return component;
    }
    return null;
  }
}

/// A model-driven editing canvas for a single semantic scene.
class SceneCanvas extends StatefulWidget {
  final SceneDefinition scene;
  final String? selectedComponentId;
  final ValueChanged<String?> onSelectionChanged;
  final String? projectRootPath;

  const SceneCanvas({
    super.key,
    required this.scene,
    required this.selectedComponentId,
    required this.onSelectionChanged,
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
            },
            onPointerMove: (event) {
              final down = _pointerDownPosition;
              if (down != null && (event.localPosition - down).distance > 4) {
                _pointerMoved = true;
              }
            },
            onPointerUp: (event) {
              final wasTap = !_pointerMoved;
              _pointerDownPosition = null;
              _pointerMoved = false;
              if (wasTap) {
                final component = SceneCanvasGeometry.hitTest(
                  widget.scene,
                  viewport.viewportToWorld(event.localPosition),
                );
                widget.onSelectionChanged(component?.id);
              }
            },
            onPointerCancel: (_) {
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
                _gestureFocalPoint = details.localFocalPoint;
                _gestureZoom = _zoom;
                _gestureWorldPoint = viewport.viewportToWorld(
                  _gestureFocalPoint,
                );
              },
              onScaleUpdate: (details) {
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

  void _scheduleImageLoads() {
    final candidates = <String, String>{};
    for (final component in SceneCanvasGeometry.paintOrder(widget.scene)) {
      final asset = _assetPath(component);
      if (asset != null) candidates[component.id] = asset;
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
    for (final component in SceneCanvasGeometry.paintOrder(scene)) {
      _paintComponent(canvas, component);
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

  void _paintComponent(Canvas canvas, ComponentInstance component) {
    final componentSize = SceneCanvasGeometry.sizeFor(component);
    final transform = component.transform;
    final position = Offset(transform.position.x, transform.position.y);
    final anchor = Offset(
      componentSize.width * transform.anchor.x,
      componentSize.height * transform.anchor.y,
    );
    final image = _imageFor(component);

    canvas.save();
    final screenPosition = viewport.worldToViewport(position);
    canvas.translate(screenPosition.dx, screenPosition.dy);
    canvas.scale(viewport.zoom);
    canvas.rotate(transform.angle);
    canvas.translate(-anchor.dx, -anchor.dy);

    final rect = Offset.zero & componentSize;
    if (image == null) {
      final fill = Paint()
        ..color = _colorFor(component).withValues(alpha: 0.72)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);
      final border = Paint()
        ..color = _colorFor(component)
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

    if (component.id == selectedComponentId) {
      final selection = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / viewport.zoom;
      canvas.drawRect(rect, selection);
    }
    canvas.restore();
  }

  ui.Image? _imageFor(ComponentInstance component) {
    final asset = _assetValue(component);
    if (asset == null) return null;
    final key = '${component.id}:$asset';
    return images[key];
  }

  String? _assetValue(ComponentInstance component) {
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
