import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flame_workspace/utils.dart';
import 'package:path/path.dart' as path;
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;

import 'game_objects.dart';
import 'project.dart';

extension FlameProjectIndexer on FlameProject {
  /// Indexes all the files in the project.
  Future<List<Map<String, dynamic>>> index() async {
    final files = <Map<String, dynamic>>[];

    final libDir = Directory(path.join(location.path, 'lib'));
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
}

class ProjectIndexer {
  /// Returns all the scenes in the project
  static Iterable<Map<String, dynamic>> scenes(
      List<Map<String, dynamic>> indexed) {
    final scenes = <Map<String, dynamic>>[];

    for (final file in indexed) {
      final declarations = (file['declarations'] as List)
          .cast<Map>()
          .map((e) => e as Map<String, dynamic>);
      scenes.addAll(declarations.where((d) {
        return d['kind'] == 'class' && d['extends'] == 'FlameScene';
      }).map((d) {
        final className = d['name'];
        final name = (d['members'] as List?)
            ?.firstWhereOrNull((d) => d['kind'] == 'constructor');
        return d;
      }));
    }

    return scenes;
  }

  /// Returns all the components in the project.
  static Iterable<FlameComponentObject> components(
      List<Map<String, dynamic>> indexed) {
    final scenes = <FlameComponentObject>[];

    for (final file in indexed) {
      final declarations = (file['declarations'] as List)
          .cast<Map>()
          .map((e) => e as Map<String, dynamic>);
      scenes.addAll(declarations.where((d) {
        return d['kind'] == 'class' &&
            d['with'] != null &&
            (d['with'] as List).contains('FlameComponent');
      }).map((d) {
        final componentParameters = <FlameComponentField>[];

        if (d['members'] != null) {
          final members = (d['members'] as List).cast<Map>();
          for (final member in members) {
            if (member['kind'] == 'constructor') {
              final parameters =
                  (member['parameters']['all'] as List).cast<Map>();
              for (final parameter in parameters) {
                final name = parameter['name'] as String;
                var type = parameter['type'] as String?;
                final defaultValue = parameter['default'] as String?;

                if (type == null) {
                  assert(
                    name.startsWith('this.'),
                    '.super parameters are not allowed',
                  );
                  // If type is null, we search through the fields to find the type.
                  final field = members.firstWhere(
                    (m) =>
                        m['kind'] == 'field' &&
                        m['name'] == name.replaceAll('this.', ''),
                  );
                  final fieldType = field['type'] as String?;
                  type = fieldType;
                }
                type ??= 'dynamic';

                componentParameters.add(FlameComponentField(
                  name.replaceAll('this.', ''),
                  type,
                  defaultValue,
                ));
              }
            }
          }
        }

        return FlameComponentObject(
          name: d['name'],
          type: d['extends'],
          parameters: componentParameters,
        );
      }));
    }

    return scenes;
  }
}
