import 'dart:io';

import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'keeps indexing a broken fixture recoverable and reports diagnostics',
    () async {
      final projectDirectory = await _copyFixture('broken_project');
      addTearDown(() => projectDirectory.delete(recursive: true));

      final pubGet = await Process.run('flutter', [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: projectDirectory.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stderr}');

      final state = FlameProjectState(
        FlameProject(
          name: 'broken_project',
          organization: 'com.example',
          location: projectDirectory,
          initialScene: 'StillIndexableGame',
        ),
      );
      addTearDown(state.dispose);

      await state.ready;

      expect(state.initialized, isTrue);
      expect(state.isIndexing, isFalse);
      expect(state.indexError, isNull);
      expect(state.analysisDiagnostics, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('finishes initialization for a missing project directory', () async {
    final root = await Directory.systemTemp.createTemp('missing_project_');
    addTearDown(() => root.delete(recursive: true));
    final missing = Directory(path.join(root.path, 'does_not_exist'));
    final state = FlameProjectState(
      FlameProject(
        name: 'missing_project',
        organization: 'com.example',
        location: missing,
        initialScene: 'Main',
      ),
    );
    addTearDown(state.dispose);

    await state.ready;

    expect(state.initialized, isTrue);
    expect(state.indexError, isNotNull);
    expect(state.indexError, contains('failed'));
  });
}

Future<Directory> _copyFixture(String name) async {
  final source = Directory(
    path.join(Directory.current.parent.path, 'fixtures', name),
  );
  final destination = await Directory.systemTemp.createTemp('fixture_state_');

  await for (final entity in source.list(recursive: true)) {
    final relative = path.relative(entity.path, from: source.path);
    final target = path.join(destination.path, relative);
    if (entity is Directory) {
      await Directory(target).create(recursive: true);
    } else if (entity is File) {
      await entity.copy(target);
    }
  }

  return destination;
}
