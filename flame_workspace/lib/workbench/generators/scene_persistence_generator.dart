import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import 'imports.dart';
import '../model/semantic_model.dart';
import '../parser/writer.dart';
import '../project/project.dart';

/// Generates additive Dart adapters for persisted Workspace scenes.
class ScenePersistenceGenerator {
  const ScenePersistenceGenerator._();

  static String generate(SceneDefinition scene, FlameProject project) {
    final sceneToken = _sceneToken(scene.name);
    final imports = <String>{
      "import 'package:flame/components.dart';",
      "import 'package:flame_workspace_runtime/flame_workspace_runtime.dart';",
    };
    for (final component in _components(scene.components)) {
      final import = _componentImport(component, project);
      if (import != null) imports.add(import);
    }

    final buffer = StringBuffer()
      ..writeln(generatedFileNotice)
      ..writeln((imports.toList()..sort()).join('\n'))
      ..writeln()
      ..writeln('void populate${sceneToken}WorkspaceScene(World world) {');

    var ordinal = 0;
    void writeComponent(ComponentInstance component, String parent) {
      final variable = 'component$ordinal';
      ordinal++;
      final typeName = _identifier(component.type.name);
      final constructorProperties =
          component.type.properties
              .where((property) => !property.editable)
              .map((property) => property.name)
              .where((name) => component.properties[name] != null)
              .toList()
            ..sort();
      final constructorArguments = [
        "key: FlameKey('${component.id}')",
        for (final name in constructorProperties)
          '$name: ${_literal(component.properties[name])}',
      ];
      buffer.writeln(
        '  final $variable = $typeName(${constructorArguments.join(', ')});',
      );
      if (component.type.isPositionComponent) {
        buffer
          ..writeln('  ($variable as PositionComponent)')
          ..writeln(
            '    ..position = Vector2(${_number(component.transform.position.x)}, ${_number(component.transform.position.y)})',
          )
          ..writeln(
            '    ..size = Vector2(${_number(component.transform.size.x)}, ${_number(component.transform.size.y)})',
          )
          ..writeln('    ..angle = ${_number(component.transform.angle)}')
          ..writeln(
            '    ..anchor = ${_anchorLiteral(component.transform.anchor)}',
          )
          ..writeln('    ..priority = ${component.priority};');
      }
      for (final entry in _sortedProperties(component.properties).entries) {
        if (_transformProperties.contains(entry.key) ||
            entry.value == null ||
            component.type.properties.any(
              (property) => property.name == entry.key && !property.editable,
            )) {
          continue;
        }
        if (!_isIdentifier(entry.key)) continue;
        buffer.writeln('  $variable.${entry.key} = ${_literal(entry.value)};');
      }
      buffer.writeln('  $parent.add($variable);');
      for (final child in component.children) {
        writeComponent(child, variable);
      }
    }

    for (final component in scene.components) {
      writeComponent(component, 'world');
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  static Future<File> writeForScene(
    SceneDefinition scene,
    FlameProject project,
  ) async {
    final file = File(
      path.join(
        project.location.path,
        'lib',
        generatedFilesDirectory,
        'scenes',
        '${_sceneToken(scene.name).snakeCase}.workspace.dart',
      ),
    );
    await file.parent.create(recursive: true);
    await Writer.writeFormatted(file, generate(scene, project));
    return file;
  }

  static Iterable<ComponentInstance> _components(
    Iterable<ComponentInstance> components,
  ) sync* {
    for (final component in components) {
      yield component;
      yield* _components(component.children);
    }
  }

  static String? _componentImport(
    ComponentInstance component,
    FlameProject project,
  ) {
    final sourcePath = component.sourcePath;
    if (sourcePath == null) return null;
    final libPath = path.join(project.location.path, 'lib');
    final relative = path.relative(sourcePath, from: libPath);
    if (relative == '..' || relative.startsWith('../')) return null;
    return "import 'package:${project.name}/${relative.replaceAll(path.separator, '/')}';";
  }

  static Map<String, Object?> _sortedProperties(
    Map<String, Object?> properties,
  ) {
    final keys = properties.keys.toList()..sort();
    return {for (final key in keys) key: properties[key]};
  }

  static String _sceneToken(String name) =>
      _identifier(ReCase(name).pascalCase);

  static String _identifier(String value) {
    if (!_isIdentifier(value)) {
      throw FormatException('Cannot generate a Dart identifier from "$value".');
    }
    return value;
  }

  static bool _isIdentifier(String value) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);
  }

  static String _number(num value) => value.toString();

  static String _anchorLiteral(WorkspaceVector2 anchor) {
    final x = anchor.x;
    final y = anchor.y;
    if (x == 0 && y == 0) return 'Anchor.topLeft';
    if (x == 0.5 && y == 0.5) return 'Anchor.center';
    if (x == 1 && y == 1) return 'Anchor.bottomRight';
    if (x == 0.5 && y == 0) return 'Anchor.topCenter';
    if (x == 1 && y == 0) return 'Anchor.topRight';
    if (x == 0 && y == 0.5) return 'Anchor.centerLeft';
    if (x == 1 && y == 0.5) return 'Anchor.centerRight';
    if (x == 0 && y == 1) return 'Anchor.bottomLeft';
    if (x == 0.5 && y == 1) return 'Anchor.bottomCenter';
    return 'Anchor.topLeft';
  }

  static String _literal(Object? value) {
    if (value == null) return 'null';
    if (value is String) return jsonEncode(value);
    if (value is bool || value is num) return value.toString();
    if (value is List) {
      return '[${value.map(_literal).join(', ')}]';
    }
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return '{${entries.map((entry) => '${jsonEncode(entry.key.toString())}: ${_literal(entry.value)}').join(', ')}}';
    }
    throw FormatException('Unsupported persisted property value: $value');
  }
}

const _transformProperties = {
  'position',
  'size',
  'angle',
  'anchor',
  'priority',
};
