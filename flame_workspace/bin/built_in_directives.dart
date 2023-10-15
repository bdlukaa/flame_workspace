/// This library generates [FlameComponentObject] for components that are built
/// into the Flame engine.
///
/// The built in components are the base for every component in the Flame ecosystem
/// and need to be parsed correctly.
// ignore_for_file: avoid_print

library built_in_directives;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flame_workspace/project/game_objects.dart';
import 'package:flame_workspace/project/parser.dart';
import 'package:http/http.dart' as http;
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;

void main() async {
  print('Downloading components.dart');
  // Get all the files in the /components lib
  final response = await http.get(
    Uri.parse(
      'https://raw.githubusercontent.com/flame-engine/flame/main/packages/flame/lib/components.dart',
    ),
  );

  if (response.statusCode == 200) {
    final paths = (response.body.split('\n')
          ..removeWhere((line) => line.startsWith('//')))
        .map((line) {
      if (line.trim().isEmpty) return line;
      return line.split("'")[1];
    }).toList();

    // paths.removeRange(5, paths.length - 1);

    List<Map<String, dynamic>> indexed = [];

    // Get all the files in the /components lib

    await Future.wait([
      for (final path in paths)
        () async {
          if (path.trim().isEmpty) return;

          final uri = Uri.parse(
            'https://raw.githubusercontent.com/flame-engine/flame/main/packages/flame/lib/$path',
          );
          print('Downloading $path');
          final fileResponse = await http.get(uri);
          if (fileResponse.statusCode == 200) {
            try {
              final parsed = parseString(
                content: fileResponse.body,
                featureSet: FeatureSet.latestLanguageVersion(),
              );
              final unit = dartdoc.serializeCompilationUnit(parsed.unit);
              unit['source'] = path;

              indexed.add(unit);
            } catch (e, s) {
              print('$path failed to parse with error:\n $e\n$s');
            }
          } else {
            print('Failed to download the file $path');
          }
        }()
    ]);

    // First, get all the components
    var components = ProjectIndexer.components(indexed).toList();
    components.sort((a, b) => a.name.compareTo(b.name));
    // Then, declare the components
    final declarations = components.map<String>((component) {
      String forComponent(FlameComponentObject component) {
        // data: ${json.encode(component.data..remove('description'))},
        return """FlameComponentObject(
  name: '${component.name}',
  type: '${component.type}',
  parameters: ${component.parameters},
  data: { /* This data is omitted and can be found at the flame-engine/flame repository */},
)${component.components.isEmpty ? '' : '''..components = [
${component.components.map(forComponent).join(',\n')}
]'''}""";
      }

      return forComponent(component);
    });

    final file = File(r'flame_workspace\lib\project\built_in_components.dart');
    file.writeAsString('''/// Automatically generated file.
/// Do not edit manually

import 'game_objects.dart';

final builtInComponents = [
  ${declarations.join(',\n')}
];
''');

    await Process.run('dart', ['format', file.path]);
  } else {
    throw 'Failed to do so :/';
  }
}
