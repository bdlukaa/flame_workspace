import 'dart:io';

import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/preview.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unsupported runtime edits retain a coded recovery diagnostic',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace_error_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final runner = FlameProjectRunner(
        FlameProject(
          name: 'workspace_error',
          organization: 'com.example',
          location: directory,
          initialScene: 'Main',
        ),
        previewSurface: UnavailablePreviewSurface(),
        runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((_, _) async {
          return const WorkspaceRuntimeResponse.failure(
            error: WorkspaceRuntimeError(
              code: 'component_not_found',
              message: 'No component with that semantic ID exists.',
            ),
          ).toMap();
        }),
      );

      expect(
        await runner.setProperty(
          componentId: 'scene:main:component:missing',
          property: 'speed',
          type: 'double',
          value: 2.0,
        ),
        isFalse,
      );
      expect(runner.runtimeDiagnostic?.code, 'component_not_found');
      expect(runner.runtimeDiagnostic?.operation, contains('setProperty'));
      expect(
        runner.runtimeDiagnostic?.recovery,
        contains('Refresh the runtime tree'),
      );
      expect(
        runner.runtimeError,
        contains('synchronization[component_not_found]'),
      );
    },
  );

  test('disconnected runtime controls expose a reconnect diagnostic', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace_disconnected_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final runner = FlameProjectRunner(
      FlameProject(
        name: 'workspace_disconnected',
        organization: 'com.example',
        location: directory,
        initialScene: 'Main',
      ),
      previewSurface: UnavailablePreviewSurface(),
    );

    expect(
      await runner.setProperty(
        componentId: 'scene:main:component:player',
        property: 'speed',
        type: 'double',
        value: 2.0,
      ),
      isFalse,
    );
    expect(runner.runtimeDiagnostic?.code, 'runtime_disconnected');
    expect(runner.runtimeError, contains('Reconnect VM Service'));
  });
}
