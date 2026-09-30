import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:flame_workspace_protocol/workspace_value.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import '../model/semantic_model.dart';
import '../parser/writer.dart';
import '../project/project.dart';
import 'workspace_dart_emitter.dart';

/// Generates additive Dart adapters for persisted Workspace scenes.
class ScenePersistenceGenerator {
  const ScenePersistenceGenerator._();

  static String generate(SceneDefinition scene, FlameProject project) {
    final sceneToken = _sceneToken(scene.name);
    final sceneComponents = _components(scene.components).toList();
    final hasAssetComponents = sceneComponents.any(
      (component) => component.assetPath != null,
    );
    var ordinal = 0;
    final statements = <Code>[];

    statements.add(
      refer('world')
          .asA(refer('FlameScene', WorkspaceDartEmitter.runtime))
          .property('backgroundColor')
          .assign(
            WorkspaceDartEmitter.color(WorkspaceColor(scene.backgroundColor)),
          )
          .statement,
    );
    if (hasAssetComponents) {
      statements.add(
        declareFinal('images')
            .assign(
              refer(
                'Images',
                WorkspaceDartEmitter.flameCache,
              ).newInstance([], {'prefix': literalString('')}),
            )
            .statement,
      );
    }

    void writeComponent(ComponentInstance component, String parent) {
      final variable = 'component$ordinal';
      ordinal++;
      if (component.assetPath != null &&
          !_isSpriteLike(component.type.name, component.type.baseType)) {
        throw FormatException(
          'Component "${component.id}" has an image asset but is not sprite-like.',
        );
      }
      final positionalProperties =
          component.type.properties
              .where((property) => property.constructorPosition != null)
              .toList()
            ..sort(
              (first, second) => first.constructorPosition!.compareTo(
                second.constructorPosition!,
              ),
            );
      final constructorProperties =
          component.type.properties
              .where(
                (property) =>
                    !property.editable && property.constructorPosition == null,
              )
              .map((property) => property.name)
              .where((name) => component.properties[name] != null)
              .toList()
            ..sort();
      for (final property in positionalProperties) {
        if (component.properties[property.name] == null &&
            property.defaultValue == null) {
          throw FormatException(
            'Missing positional constructor value "${property.name}" '
            'for ${component.type.name} (${component.id}).',
          );
        }
      }

      final context = _valueContext(scene, component, 'constructor');
      final constructor = _componentReference(component, project).newInstance(
        [
          for (final property in positionalProperties)
            WorkspaceDartEmitter.value(
              component.properties[property.name] ?? property.defaultValue,
              context: '$context ${property.name}',
            ),
        ],
        {
          'key': refer(
            'FlameKey',
            WorkspaceDartEmitter.runtime,
          ).newInstance([literalString(component.id)]),
          for (final name in constructorProperties)
            name: WorkspaceDartEmitter.value(
              component.properties[name],
              context: '$context $name',
            ),
        },
      );
      statements.add(declareFinal(variable).assign(constructor).statement);

      if (component.assetPath case final assetPath?) {
        statements.add(
          refer(variable)
              .asA(
                refer('SpriteComponent', WorkspaceDartEmitter.flameComponents),
              )
              .property('sprite')
              .assign(
                refer('Sprite', WorkspaceDartEmitter.flameComponents)
                    .property('load')
                    .call(
                      [literalString(assetPath)],
                      {'images': refer('images')},
                    )
                    .awaited,
              )
              .statement,
        );
      }
      if (component.type.isPositionComponent) {
        var transform = refer(
          variable,
        ).asA(refer('PositionComponent', WorkspaceDartEmitter.flameComponents));
        transform = transform
            .cascade('position')
            .assign(
              WorkspaceDartEmitter.vector2(
                component.transform.position.x,
                component.transform.position.y,
              ),
            );
        if (component.type.name != 'CircleComponent' &&
            component.type.name != 'TextComponent') {
          transform = transform
              .cascade('size')
              .assign(
                WorkspaceDartEmitter.vector2(
                  component.transform.size.x,
                  component.transform.size.y,
                ),
              );
        }
        statements.add(
          transform
              .cascade('scale')
              .assign(
                WorkspaceDartEmitter.vector2(
                  component.transform.scale.x,
                  component.transform.scale.y,
                ),
              )
              .cascade('angle')
              .assign(literalNum(component.transform.angle))
              .cascade('anchor')
              .assign(
                WorkspaceDartEmitter.anchor(
                  component.transform.anchor.x,
                  component.transform.anchor.y,
                ),
              )
              .cascade('priority')
              .assign(literalNum(component.priority))
              .statement,
        );
      }
      for (final entry in _orderedProperties(component).entries) {
        if (_transformProperties.contains(entry.key) ||
            entry.value == null ||
            component.type.properties.any(
              (property) =>
                  property.name == entry.key &&
                  (!property.editable || property.constructorPosition != null),
            )) {
          continue;
        }
        if (!_isIdentifier(entry.key)) continue;
        statements.add(
          refer(variable)
              .property(entry.key)
              .assign(
                WorkspaceDartEmitter.value(
                  entry.value,
                  context: _valueContext(scene, component, entry.key),
                ),
              )
              .statement,
        );
      }
      statements.add(
        refer(parent).property('add').call([refer(variable)]).statement,
      );
      for (final child in component.children) {
        writeComponent(child, variable);
      }
    }

    for (final component in scene.components) {
      writeComponent(component, 'world');
    }

    return Writer.formatDartString(
      WorkspaceDartEmitter.emit(
        Library(
          (builder) => builder
            ..comments.add('This file is generated by Flame Workspace.')
            ..comments.add('Do not edit it manually.')
            ..body.add(
              Method(
                (builder) => builder
                  ..name = 'populate${sceneToken}WorkspaceScene'
                  ..returns = TypeReference(
                    (builder) => builder
                      ..symbol = 'Future'
                      ..url = 'dart:async'
                      ..types.add(refer('void')),
                  )
                  ..modifier = MethodModifier.async
                  ..requiredParameters.add(
                    Parameter(
                      (builder) => builder
                        ..name = 'world'
                        ..type = refer(
                          'World',
                          WorkspaceDartEmitter.flameComponents,
                        ),
                    ),
                  )
                  ..body = Block.of(statements),
              ),
            ),
        ),
      ),
    );
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

  static Reference _componentReference(
    ComponentInstance component,
    FlameProject project,
  ) => refer(component.type.name, _componentImportUri(component, project));

  static String? _componentImportUri(
    ComponentInstance component,
    FlameProject project,
  ) {
    final sourcePath = component.sourcePath;
    if (sourcePath == null) return WorkspaceDartEmitter.flameComponents;
    final libPath = path.join(project.location.path, 'lib');
    final resolvedSourcePath = path.isAbsolute(sourcePath)
        ? sourcePath
        : path.join(project.location.path, sourcePath);
    final relative = path.relative(resolvedSourcePath, from: libPath);
    if (relative == '..' || relative.startsWith('../')) {
      return WorkspaceDartEmitter.flameComponents;
    }
    return 'package:${project.name}/${relative.replaceAll(path.separator, '/')}';
  }

  static Map<String, Object?> _orderedProperties(ComponentInstance component) {
    final keys = component.properties.keys.toList()..sort();
    if (component.type.name == 'TextBoxComponent') {
      const order = ['text', 'textRenderer', 'boxConfig', 'align'];
      keys.sort((a, b) {
        final first = order.indexOf(a);
        final second = order.indexOf(b);
        if (first >= 0 && second >= 0) return first.compareTo(second);
        if (first >= 0) return -1;
        if (second >= 0) return 1;
        return a.compareTo(b);
      });
    }
    return {for (final key in keys) key: component.properties[key]};
  }

  static bool _isSpriteLike(String name, String? baseType) =>
      name.contains('Sprite') || baseType?.contains('Sprite') == true;

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

  static String _valueContext(
    SceneDefinition scene,
    ComponentInstance component,
    String property,
  ) =>
      'scene ${scene.id}, component ${component.id} '
      '(${component.type.name}), property $property';
}

const _transformProperties = {
  'position',
  'size',
  'scale',
  'angle',
  'anchor',
  'priority',
};
