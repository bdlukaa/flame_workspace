import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;
import 'package:path/path.dart' as path;

import 'package:flame_workspace/utils.dart';

import 'built_in_components.dart';
import 'game_objects.dart';

class ProjectIndexer {
  const ProjectIndexer._();

  static Future<List<Map<String, dynamic>>> indexProject(
    Directory libDir,
  ) async {
    final files = <Map<String, dynamic>>[];

    await for (final file in libDir
        .list(recursive: true)
        .where((f) => f is File && path.extension(f.path) == '.dart')) {
      final parsed = parseFile(
        path: file.path,
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      final unit = dartdoc.serializeCompilationUnit(parsed.unit);
      unit['source'] = file.path;
      files.add(unit);
    }

    return files;
  }

  /// Returns all the scenes in the project
  ///
  /// `components` represents all the components in the project. If null, the
  /// components will be searched for.
  static Iterable<FlameSceneObject> scenes(
    List<Map<String, dynamic>> indexed, [
    Iterable<FlameComponentObject>? components,
  ]) {
    components ??= ProjectIndexer.components(indexed);

    final scenes = <FlameSceneObject>[];
    for (final file in indexed) {
      final declarations = (file['declarations'] as List)
          .cast<Map>()
          .map((e) => e as Map<String, dynamic>);
      scenes.addAll(declarations.where((d) {
        return d['kind'] == 'class' && d['extends'] == 'FlameScene';
      }).map((d) {
        final members = (d['members'] as List).cast<Map>();

        final className = d['name'] as String;

        final fields = members.where((m) => m['kind'] == 'field');

        return FlameSceneObject(
          name: className,
          components: _componentsFromClassFields(components!, fields),
        );
      }));
    }

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
    components = [...components, ...builtInComponents];
    return components.where((component) {
      return fields.any((field) {
        return field['type'] == component.name;
      });
    }).map((component) {
      final field = fields.firstWhere((field) {
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

  /// Returns all the components in the project.
  static Iterable<FlameComponentObject> components(
    List<Map<String, dynamic>> indexed,
  ) {
    final components = <FlameComponentObject>[];

    for (final file in indexed) {
      final declarations = (file['declarations'] as List)
          .cast<Map>()
          .map((e) => e as Map<String, dynamic>);
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
            // TODO: add support for multiple constructors (factory constructors / named constructors)
            if (member['kind'] == 'constructor' &&
                member['factory'] != true &&
                !(member['name'] as String).contains('.')) {
              final parameters =
                  (member['parameters']['all'] as List).cast<Map>();
              for (final parameter in parameters) {
                var name = parameter['name'] as String;
                var type = parameter['type'] as String?;
                final defaultValue = parameter['default'] as String?;
                FlameComponentObject? superComponent;
                FlameComponentField? superParameter;

                if (type == null) {
                  if (name.startsWith('super.')) {
                    final superclass = d['extends'] as String?;
                    assert(
                      superclass != null,
                      'Cannot use super. without a superclass',
                    );
                    superComponent = [
                      ...components,
                      ...builtInComponents,
                    ].firstWhereOrNull((c) => c.name == superclass);

                    superParameter =
                        superComponent?.parameters.firstWhereOrNull(
                      (p) {
                        return p.name == name.replaceAll('super.', '');
                      },
                    );
                    type = superParameter?.type;

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
                  }
                }
                type ??= 'dynamic';

                componentParameters.add(FlameComponentField(
                  name.replaceAll('this.', ''),
                  type,
                  defaultValue,
                  superComponent == null
                      ? null
                      : [
                          superComponent.name,
                          if (superParameter?.superComponents != null)
                            ...superParameter!.superComponents!,
                        ],
                ));
              }
            }
          }
        }

        return FlameComponentObject(
          name: d['name'],
          type: d['extends'],
          parameters: componentParameters,
          data: d,
        );
      }));
    }

    // Populates the components with their children recursively.
    void populateComponents(List<FlameComponentObject> components) {
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

    populateComponents(components);

    return components;
  }
}
