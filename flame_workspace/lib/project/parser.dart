import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flame_workspace/utils.dart';
import 'package:path/path.dart' as path;
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;

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
}
