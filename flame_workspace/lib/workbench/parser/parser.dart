import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace/workbench/project/objects/mixin.dart';
import 'package:flame_workspace/workbench/project/objects/scene.dart';
import 'package:path/path.dart' as path;

import 'package:flame_workspace_core/utils.dart';

import '../../compilation_unit_helper.dart';
import '../project/objects/built_in_components.dart';

typedef IndexedProject = List<(IndexedUnit indexed, CompilationUnit unit)>;
typedef IndexedComponent = (
  FlameComponentObject component,
  IndexedUnit indexedUnit,
  CompilationUnit unit
);
typedef IndexedScene = (
  FlameSceneObject scene,
  IndexedUnit indexedUnit,
  CompilationUnit unit
);
typedef IndexedMixin = (
  FlameMixin mixin,
  IndexedUnit indexedUnit,
  CompilationUnit unit
);

class ProjectIndexer {
  const ProjectIndexer._();

  /// Indexes a project at the given [libDir].
  ///
  /// If [includeOnly] is provided, only the files that are in the list will be
  /// indexed.
  static Future<IndexedProject> indexProject(
    Directory libDir, [
    Iterable<String>? includeOnly,
  ]) async {
    // avoiding print because we can not import flutter to use it on the /bin folder
    // ignore: avoid_print
    print('Indexing project at ${libDir.path} including only $includeOnly');
    final IndexedProject files = <(IndexedUnit, CompilationUnit)>[];

    libDir = Directory(path.join(libDir.path, 'lib'));

    await for (final file in libDir
        .list(recursive: true)
        .where((f) => f is File && path.extension(f.path) == '.dart')) {
      if (includeOnly != null && !includeOnly.contains(file.path)) continue;

      final parsed = parseFile(
        path: file.path,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false, // Do not throw on errors/linting
      );
      final unit = dartdoc.serializeCompilationUnit(parsed.unit);
      unit['source'] = file.path;
      files.add((unit, parsed.unit));
    }

    return files;
  }

  /// Returns all the scenes in the project
  ///
  /// [components] represents all the components in the project. If `null`, the
  /// components will be searched for.
  static Iterable<IndexedScene> scenesFrom(
    IndexedProject indexed, [
    Iterable<IndexedComponent>? components,
  ]) {
    components ??= ProjectIndexer.componentsFrom(indexed);

    final scenes = <IndexedScene>[];
    for (final index in indexed) {
      final file = index.$1;
      final unit = index.$2;

      // If the file has no declarations, we skip it.
      if (file['declarations'] == null) continue;

      final declarations = (file['declarations'] as List)
          .cast<Map>()
          .map((e) => e as IndexedUnit);
      scenes.addAll(declarations.where((d) {
        // Only add the classes that extend FlameScene
        // return d['kind'] == 'class' && d['extends'] == 'FlameScene';
        return d['kind'] == 'class';
      }).map((d) {
        final members = (d['members'] as List).cast<Map>();
        final className = d['name'] as String;
        final fields = members.where((m) => m['kind'] == 'field');

        return (
          FlameSceneObject(
            name: className,
            components: _componentsFromClassFields(
              components!.map((e) => e.$1),
              fields,
            ),
            filePath: file['source'],
            unit: index,
            modifiers:
                (d['with'] as List<String>? ?? []).map<FlameMixin>((mixin) {
              return FlameMixin(
                name: mixin,
                types: mixin.split('<').map((e) {
                  final name = e.split(' ').last;
                  final extendsIndex = name.indexOf('extends');
                  if (extendsIndex == -1) return (name, null);
                  return (
                    name.substring(0, extendsIndex),
                    name.substring(extendsIndex + 7)
                  );
                }).toList(),
                isComponentRestricted: false,
                isSceneRestricted: false,
                on: [],
              );
            }).toList(),
          ),
          file,
          unit,
        );
      }));
    }

    for (final scene in scenes) {
      scene.$1.script = scenes.firstWhereOrNull((s) {
        return '\$${s.$1.name}' == scene.$1.name;
      })?.$1;
    }

    scenes.removeWhere((scene) {
      return scene.$1.script == null &&
          scene.$2['declarations'].first['extends'] != 'FlameScene';
    });

    return scenes;
  }

  /// Gets the components present in a class.
  ///
  /// The [components] parameter determines all the components present into the
  /// project.
  ///
  /// The [fields] parameter determines all the fields present in the class.
  ///
  /// This function will do a mapping of the fields to the components, returning
  /// the matching peers - with extra data. The type of the field must be
  /// explictitly declared, otherwise it will be ignored.
  static List<FlameComponentObject> _componentsFromClassFields(
    Iterable<FlameComponentObject> components,
    Iterable<Map> fields,
  ) {
    components = [...builtInComponents, ...components];
    return fields.where((field) {
      return components.any((component) => field['type'] == component.name);
    }).map((field) {
      final component = components.firstWhere((component) {
        return field['type'] == component.name;
      });

      return FlameComponentObject(
        name: component.name,
        type: component.type,
        data: component.data,
        parameters: component.parameters,
        declarationName: field['name'],
      )..components.addAll(component.components);
    }).toList();
  }

  /// Returns all the components in the project and its compilation unit.
  static Iterable<IndexedComponent> componentsFrom(IndexedProject indexed) {
    final components = <IndexedComponent>[];

    for (final index in indexed) {
      final indexedUnit = index.$1;
      final unit = index.$2;
      if (indexedUnit['declarations'] == null) continue;
      final declarations = (indexedUnit['declarations'] as List)
          .cast<Map>()
          .map((e) => e as IndexedUnit);

      components.addAll(declarations.where((d) {
        final w = d['with'] as List?;
        final e = d['extends'] as String?;
        return d['kind'] == 'class' &&
            (w != null && (w.contains('FlameComponent')) ||
                [
                  'PositionComponent',
                  'Component',
                  ...builtInComponents.map((e) => e.name),
                ].contains(e));
      }).map((d) {
        final componentParameters = <FlameComponentField>[];

        if (d['members'] != null) {
          final members = (d['members'] as List).cast<Map>();
          for (final member in members) {
            // TODO: add support for multiple constructors
            //       (factory constructors / named constructors)
            if (member['kind'] == 'constructor' &&
                member['factory'] != true &&
                !(member['name'] as String).contains('.')) {
              final parameters =
                  (member['parameters']?['all'] as List?)?.cast<Map>() ?? [];
              for (final parameter in parameters) {
                var name = parameter['name'] as String;
                var type = parameter['type'] as String?;
                final defaultValue = parameter['default'] as String?;
                FlameComponentObject? superComponent;
                FlameComponentField? superParameter;

                bool isFinal = false;

                if (type == null) {
                  if (name.startsWith('super.')) {
                    final superclass = d['extends'] as String?;
                    assert(
                      superclass != null,
                      'Cannot use super. without a superclass',
                    );
                    superComponent = [
                      ...components.map((e) => e.$1),
                      ...builtInComponents,
                    ].firstWhereOrNull((c) => c.name == superclass);

                    superParameter =
                        superComponent?.parameters.firstWhereOrNull(
                      (p) {
                        return p.name == name.replaceAll('super.', '');
                      },
                    );
                    type = superParameter?.type;
                    isFinal = superParameter?.isFinalField ?? isFinal;

                    name = name.replaceAll('super.', '');
                  } else {
                    assert(
                      name.startsWith('this.'),
                      'Only members parameters are allowed',
                    );
                    // If type is null, we search through the fields to find the type.
                    final field = members.firstWhereOrNull(
                      (m) =>
                          m['kind'] == 'field' &&
                          m['name'] == name.replaceAll('this.', ''),
                    );
                    final fieldType = field?['type'] as String?;
                    type = fieldType;

                    isFinal = field?['final'] == true;
                  }
                }
                type ??= 'dynamic';

                final fieldName = name.replaceAll('this.', '');
                final hasSetter = members.any(
                  (element) =>
                      element['kind'] == 'setter' &&
                      element['name'] == fieldName,
                );

                componentParameters.add(FlameComponentField(
                  fieldName,
                  type,
                  defaultValue,
                  superComponent == null
                      ? null
                      : [
                          superComponent.name,
                          if (superParameter?.superComponents != null)
                            ...superParameter!.superComponents!,
                        ],
                  name.startsWith('this.'),
                  isFinal,
                  hasSetter,
                ));
              }
            }
          }
        }

        return (
          FlameComponentObject(
            name: d['name'],
            type: d['extends'],
            parameters: componentParameters,
            data: d,
            filePath: indexedUnit['source'],
          ),
          indexedUnit,
          unit,
        );
      }));
    }

    // Populates the components with their children recursively.
    void populateComponents(Iterable<FlameComponentObject> components) {
      for (final parent in components) {
        if (parent.data['members'] == null) continue;
        final fields = (parent.data['members'] as List)
            .cast<Map>()
            .where((d) => d['kind'] == 'field');

        if (fields.isEmpty) continue;

        final childComponents = _componentsFromClassFields(components, fields);

        if (childComponents.any((c) => c.name == parent.name)) {
          throw Exception(
            'Component ${parent.type} cannot extend itself.\n'
            'You are probably seeing this error because you have a component '
            'that contains itself as a child. This leads to an infinite loop, '
            'therefore it is not allowed.',
          );
        }

        childComponents
          ..removeWhere((c) => c.name == parent.name)
          ..forEach((component) => component.parent = parent);

        populateComponents(childComponents);
        parent.components.addAll(childComponents);
        // print('$parent // $childComponents');
      }
    }

    populateComponents(components.map((e) => e.$1));

    return components;
  }

  /// Returns all the top level constants and variables.
  static List<(Map<String, dynamic>, IndexedUnit, CompilationUnit)> topLevel(
    IndexedProject indexed,
  ) {
    final result = <(Map<String, dynamic>, IndexedUnit, CompilationUnit)>[];

    for (final index in indexed) {
      final indexedUnit = index.$1;
      final unit = index.$2;
      if (indexedUnit['declarations'] == null) continue;

      final declarations = (indexedUnit['declarations'] as List)
          .cast<Map>()
          .map((e) => e as IndexedUnit);

      final variables = declarations.where((d) => d['kind'] == 'variable');
      for (final variable in variables) {
        result.add((variable, indexedUnit, unit));
      }
    }

    return result;
  }

  /// Returns all the mixins in the project.
  static Iterable<IndexedMixin> mixinsFrom(IndexedProject indexed) {
    final mixins = <IndexedMixin>[];

    for (final index in indexed) {
      final indexedUnit = index.$1;
      final unit = index.$2;
      if (indexedUnit['declarations'] == null) continue;
      final declarations = (indexedUnit['declarations'] as List)
          .cast<Map>()
          .map((e) => e as IndexedUnit);

      mixins.addAll(declarations.where((d) {
        return d['kind'] == 'mixin';
      }).map((mixin) {
        final mixinName = mixin['name'] as String;
        final typeParameters = List<Map>.from(mixin['typeParameters'] ?? [])
            .map<MixinType>((mixin) {
          return (mixin['name'], mixin['extends']);
        }).toList();

        return (
          FlameMixin(
            name: mixinName,
            types: typeParameters,
            isComponentRestricted: false,
            isSceneRestricted: false,
            on: mixin['on'] ?? [],
          ),
          indexedUnit,
          unit,
        );
      }));
    }

    return mixins;
  }
}
