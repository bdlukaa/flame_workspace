/// This library generates [FlameComponentObject] for components that are built
/// into the Flame engine.
///
/// The built in components are the base for every component in the Flame ecosystem
/// and need to be parsed correctly.
// ignore_for_file: avoid_print

library built_in_directives;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flame_workspace/workbench/generators/imports.dart';
import 'package:flame_workspace/workbench/parser/writer.dart';
import 'package:flame_workspace/workbench/project/objects/component.dart';
import 'package:flame_workspace/workbench/parser/parser.dart';
import 'package:flame_workspace/workbench/project/objects/mixin.dart';
import 'package:http/http.dart' as http;
import 'package:dartdoc_json/dartdoc_json.dart' as dartdoc;

void main() async {
  print('Generating!');
  print('Checking local installation of Flame...');
  final flameDirectory = Directory(
    'C:/Users/bruno/AppData/Local/Pub/Cache/hosted/pub.dev/flame-1.18.0/lib',
  );

  List<Map<dynamic, dynamic>> files;
  if (!(await flameDirectory.exists())) {
    print('Flame not found, fetching from GitHub...');

    final response = await http.get(
      Uri.parse(
        'https://api.github.com/repos/flame-engine/flame/contents/packages/flame/lib/',
      ),
      headers: {'X-GitHub-Api-Version': '2022-11-28'},
    );
    files = (jsonDecode(response.body) as List).cast<Map>();
  } else {
    print('Flame found, fetching from local installation...');
    files = flameDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => {'name': file.path})
        .toList();
  }

  /// Run the function multiple times to ensure all the inheritance is done.
  /// It depends on its own previous fetch to know all the components.
  ///
  /// It firts gets all the root components, then it runs multiple times to
  /// get the components that are children of the root components. This runs
  /// recursively 5 times.
  for (var i = 0; i < 5; i++) {
    await getAll(files);
  }
}

Future<void> getAll(List<Map<dynamic, dynamic>> files) async {
  IndexedProject indexed = [];
  await Future.wait([
    for (final file in files)
      () async {
        final name = file['name'] as String;
        if (name.endsWith('.dart')) {
          // avoid the following files:
          // if (name.endsWith('advanced_button_component.dart') ||
          //     name.endsWith('polygon_hitbox.dart')) {
          //   return;
          // }
          try {
            print(name);
            final i = await forFile(name);
            indexed.addAll(i);
          } catch (e, s) {
            print('    Failed to get for file $name: \n$e\n$s');
          }
        }
      }()
  ]);

  print('Parsing components');
  // First, get all the components
  var components =
      ProjectIndexer.componentsFrom(indexed).map((e) => e.$1).toList();

  // Remove duplicates
  for (final component in List<FlameComponentObject>.from(components)) {
    if (components.where((c) => c.name == component.name).length > 1) {
      print('Duplicate found: ${component.name}');
      components.remove(component);
    }
  }

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

  print('    Writing to file');
  final componentFile = File(
      r'flame_workspace\lib\workbench\project\objects\built_in_components.dart');
  if (!await componentFile.exists()) {
    await componentFile.create(recursive: true);
  }
  await Writer.writeFormatted(componentFile, '''$generatedFileNotice

import 'component.dart';

const builtInComponents = <FlameComponentObject>[
  ${declarations.join(',\n')}
];
''');

  print('Parsing mixins');
  final mixins = ProjectIndexer.mixinsFrom(indexed).map((e) => e.$1).toList();

  // Remove duplicates
  for (final mixin in List<FlameMixin>.from(mixins)) {
    if (mixins.where((m) => m.name == mixin.name).length > 1) {
      print('Duplicate found: ${mixin.name}');
      mixins.remove(mixin);
    }
  }

  mixins.sort((a, b) => a.name.compareTo(b.name));

  final mixinDeclarations = mixins.map<String>((mixin) {
    return """FlameMixin(
  name: '${mixin.name}',
  types: [
    ${mixin.types.map((type) => "('${type.$1}', '${type.$2}')").join(',\n')}
  ],
  isComponentRestricted: ${mixin.isComponentRestricted},
  isSceneRestricted: ${mixin.isSceneRestricted},
)""";
  });

  print('    Writing to file');
  final mixinFile = File(
      r'flame_workspace\lib\workbench\project\objects\built_in_mixins.dart');
  if (!await mixinFile.exists()) {
    await mixinFile.create(recursive: true);
  }
  await Writer.writeFormatted(mixinFile, '''$generatedFileNotice
import 'mixin.dart';

final builtInMixins = <FlameMixin>[
  ${mixinDeclarations.join(',\n')}
];
''');
}

Future<IndexedProject> forFile(String path) async {
  final localFile = File(path);
  if (await localFile.exists()) {
    print('    Getting for local file $path');
    final parsed = parseString(
      content: localFile.readAsStringSync(),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final serialized = dartdoc.serializeCompilationUnit(parsed.unit);
    serialized['source'] = path;

    return [(serialized, parsed.unit)];
  }

  print('    Getting for file $path');
  final response = await http.get(
    Uri.parse(
        'https://raw.githubusercontent.com/flame-engine/flame/main/packages/flame/lib/$path'),
  );

  if (response.statusCode == 200) {
    final paths = response.body
        .split('\n')
        .map((line) {
          if (line.startsWith('//') || !line.startsWith('export')) return null;
          if (line.contains('package:')) return null;
          if (line.trim().isEmpty) return line;
          final split = line.split("'");
          if (split.length < 2) return null;
          return split[1];
        })
        .whereType<String>()
        .toList();

    // paths.removeRange(5, paths.length - 1);

    IndexedProject indexed = [];

    // Get all the files in the /components lib

    await Future.wait([
      for (final path in paths)
        () async {
          if (path.trim().isEmpty) return;

          final uri = Uri.parse(
            'https://raw.githubusercontent.com/flame-engine/flame/main/packages/flame/lib/$path',
          );
          print('    Downloading $path');
          final fileResponse = await http.get(uri);
          if (fileResponse.statusCode == 200) {
            try {
              final parsed = parseString(
                content: fileResponse.body
                    .split('\n')
                    .where((l) => !l.startsWith('library'))
                    .join('\n'),
                featureSet: FeatureSet.latestLanguageVersion(),
              );
              final serialized = dartdoc.serializeCompilationUnit(parsed.unit);
              serialized['source'] = path;

              indexed.add((serialized, parsed.unit));
            } catch (e, s) {
              print('    $path failed to parse with error:\n $e\n$s');
            }
          } else {
            print('    Failed to download the file $path');
          }
        }()
    ]);

    return indexed;
  } else {
    throw 'Failed to do so :/';
  }
}
