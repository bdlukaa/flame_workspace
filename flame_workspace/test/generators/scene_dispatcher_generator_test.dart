import 'dart:io';

import 'package:flame_workspace/workbench/generators/scene_dispatcher_generator.dart';
import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projectRoot = '/workspace/generated_game';
  final project = FlameProject(
    name: 'generated_game',
    organization: 'com.example',
    location: Directory(projectRoot),
    initialScene: 'Beta',
  );
  final alpha = SceneDefinition(
    id: 'scene:alpha',
    name: 'Alpha',
    runtimeClassName: r'$SceneAlpha',
    runtimeSourcePath: '$projectRoot/lib/scenes/alpha.dart',
  );
  final beta = SceneDefinition(
    id: 'scene:beta',
    name: 'Beta',
    runtimeClassName: 'BetaScene',
    runtimeSourcePath: '$projectRoot/lib/scenes/beta.dart',
  );

  test('generates deterministic dispatch for multiple scenes', () {
    final first = _withoutScopedReferences(
      SceneDispatcherGenerator.generate([beta, alpha], project),
    );
    final second = _withoutScopedReferences(
      SceneDispatcherGenerator.generate([alpha, beta], project),
    );

    expect(first, second);
    expect(RegExp(r'''case ['"]Alpha['"]:''').hasMatch(first), isTrue);
    expect(
      first,
      contains(r'FlameWorkspaceCore.instance.currentScene = $SceneAlpha();'),
    );
    expect(RegExp(r'''case ['"]Beta['"]:''').hasMatch(first), isTrue);
    expect(
      first,
      contains('FlameWorkspaceCore.instance.currentScene = BetaScene();'),
    );
    expect(RegExp(r'''setScene\(['"]Beta['"]\);''').hasMatch(first), isTrue);
  });

  test('rejects an invalid runtime class identifier', () {
    final invalidScene = SceneDefinition(
      id: 'scene:invalid',
      name: 'Invalid',
      runtimeClassName: 'Invalid-Scene',
      runtimeSourcePath: '$projectRoot/lib/scenes/invalid.dart',
    );

    expect(
      () => SceneDispatcherGenerator.generate([invalidScene], project),
      throwsFormatException,
    );
  });
}

String _withoutScopedReferences(String source) =>
    source.replaceAll(RegExp(r'_i\d+\.'), '');
