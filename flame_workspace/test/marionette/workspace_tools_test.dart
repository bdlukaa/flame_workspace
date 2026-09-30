import 'package:flame_workspace/main.dart';
import 'package:flame_workspace/marionette/workspace_tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  test('Welcome diagnostics succeed without an open project', () async {
    initializeFlameWorkspaceBinding();
    initializeWorkspaceMarionetteTools();

    final state = await readWorkspaceMarionetteToolForTesting(
      'workspace.getState',
    );
    expect(state, isA<MarionetteExtensionSuccess>());
    expect((state as MarionetteExtensionSuccess).data, {
      'screen': 'welcome',
      'projectOpen': false,
    });

    final runtime = await readWorkspaceMarionetteToolForTesting(
      'workspace.getRuntimeHierarchy',
    );
    expect(runtime, isA<MarionetteExtensionSuccess>());
    expect((runtime as MarionetteExtensionSuccess).data, {
      'available': false,
      'reason': 'no_project',
    });
  });

  test('registers schema-bearing diagnostic tools in debug mode', () {
    initializeFlameWorkspaceBinding();
    initializeWorkspaceMarionetteTools();

    final extensions = {
      for (final extension in customExtensionRegistry)
        extension.name: extension,
    };
    expect(
      extensions.keys,
      containsAll([
        'workspace.getState',
        'workspace.getCurrentScene',
        'workspace.getBuildHierarchy',
        'workspace.getRuntimeHierarchy',
        'workspace.getDiagnostics',
        'workspace.getPreviewLogs',
        'workspace.getSyncStatus',
        'workspace.selectScene',
      ]),
    );
    expect(
      extensions.values.every((extension) => extension.inputSchema != null),
      isTrue,
    );
    expect(extensions['workspace.selectScene']!.inputSchema!.required, [
      'sceneId',
    ]);
  });
}
