import 'dart:async';
import 'dart:io';

import 'package:flame_workspace/workbench/model/semantic_model.dart';
import 'package:flame_workspace/workbench/project/project.dart';
import 'package:flame_workspace/workbench/runner/logs.dart';
import 'package:flame_workspace/workbench/runner/runner.dart';
import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

const ready = {
  'sessionId': 'session-1',
  'scene': 'Main',
  'sceneReady': true,
  'capabilities': ['composeComponent'],
  'paused': false,
};
Map<String, dynamic> response(Object result) =>
    WorkspaceRuntimeResponse.success(result).toMap();

FlameProjectRunner fakeRunner(
  WorkspaceRuntimeClient client, {
  String? Function()? expectedScene,
}) => FlameProjectRunner(
  FlameProject(
    name: 'attach_test',
    organization: 'com.example',
    location: Directory.current,
    initialScene: 'Main',
  ),
  runtimeClientOverride: client,
  expectedScene: expectedScene ?? () => 'Main',
  handshakeTimeout: const Duration(milliseconds: 300),
  handshakePollInterval: const Duration(milliseconds: 5),
);

void main() {
  test(
    'parses direct VM Service and DevTools URLs without confusing web URL',
    () {
      expect(
        PreviewServiceUriDetector.find(
          'The Dart VM service is listening on http://127.0.0.1:8181/abc/',
        ).toString(),
        'ws://127.0.0.1:8181/abc/ws',
      );
      expect(
        PreviewServiceUriDetector.find(
          'The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:9000/?uri=http%3A%2F%2F127.0.0.1%3A8181%2Fabc%2F',
        ).toString(),
        'ws://127.0.0.1:8181/abc/ws',
      );
      expect(
        PreviewServiceUriDetector.find(
          'Web Server is available at http://127.0.0.1:1234',
        ),
        isNull,
      );
    },
  );

  test(
    'delayed registration and mounting remain unready until handshake',
    () async {
      var polls = 0;
      final client = WorkspaceRuntimeClient.fromInvoker((method, _) async {
        if (method == WorkspaceExtensionNames.getState) {
          polls++;
          if (polls < 3) {
            throw const WorkspaceRuntimeException(
              code: 'extension_not_registered',
              message: 'pending',
            );
          }
          return response({...ready, 'sceneReady': polls >= 5});
        }
        if (method == WorkspaceExtensionNames.getComponentTree) {
          return response({'id': 'Main', 'type': 'MainScene', 'children': []});
        }
        return response({});
      });
      final runner = fakeRunner(client);
      final states = <RuntimeConnectionState>[];
      runner.addListener(() => states.add(runner.connectionState));
      final first = runner.connectRuntime('ws://localhost:8181/ws');
      final second = runner.connectRuntime('ws://localhost:8181/ws');
      expect(identical(first, second), isTrue);
      expect(runner.connectionState, isNot(RuntimeConnectionState.sceneReady));
      expect(await first, isTrue);
      expect(polls, greaterThanOrEqualTo(5));
      expect(
        states,
        containsAllInOrder([
          RuntimeConnectionState.serviceConnected,
          RuntimeConnectionState.extensionsAvailable,
          RuntimeConnectionState.sceneLoading,
          RuntimeConnectionState.sceneReady,
        ]),
      );
      expect(runner.runtimeSessionId, 'session-1');
      await runner.stop();
      expect(runner.connectionState, RuntimeConnectionState.disconnected);
    },
  );

  test(
    'incomplete handshake reports an incompatible runtime after polling',
    () async {
      var polls = 0;
      final runner = fakeRunner(
        WorkspaceRuntimeClient.fromInvoker((method, _) async {
          if (method == WorkspaceExtensionNames.getState) {
            polls++;
            return response({'paused': false, 'scene': 'Main'});
          }
          return response({});
        }),
      );

      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isFalse);
      expect(polls, greaterThan(1));
      expect(runner.connectionState, RuntimeConnectionState.failed);
      expect(
        runner.runtimeError,
        contains('incompatible with this Workspace version'),
      );
      expect(runner.runtimeError, contains('sessionId and sceneReady'));

      await runner.stop();
    },
  );

  test(
    'DWDS without a browser debug client fails once without retrying',
    () async {
      var calls = 0;
      final runner = fakeRunner(
        WorkspaceRuntimeClient.fromInvoker((method, _) async {
          if (method == WorkspaceExtensionNames.getState) {
            calls++;
            throw const WorkspaceRuntimeException(
              code: 'dwds_client_unavailable',
              message: 'No clients available for service extension',
            );
          }
          return response({});
        }),
      );

      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isFalse);
      expect(calls, 1);
      expect(runner.connectionState, RuntimeConnectionState.failed);
      expect(
        runner.runtimeDiagnostic?.code,
        'runtime_debug_client_unavailable',
      );
      expect(
        runner.runtimeDiagnostic?.recovery,
        contains('no DWDS debug client'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(calls, 1);
      await runner.stop();
    },
  );

  test(
    'Game mode attaches without replacing the current gameplay scene',
    () async {
      var sceneChanges = 0;
      final runner = FlameProjectRunner(
        FlameProject(
          name: 'attach_test',
          organization: 'com.example',
          location: Directory.current,
          initialScene: 'Main',
        ),
        runtimeClientOverride: WorkspaceRuntimeClient.fromInvoker((
          method,
          _,
        ) async {
          if (method == WorkspaceExtensionNames.getState) {
            return response({...ready, 'scene': 'Gameplay'});
          }
          if (method == WorkspaceExtensionNames.getComponentTree) {
            return response({
              'id': 'Gameplay',
              'type': 'Scene',
              'children': [],
            });
          }
          if (method == WorkspaceExtensionNames.setScene) sceneChanges++;
          return response({});
        }),
        expectedScene: () => 'Main',
        isBuildMode: () => false,
      );
      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
      expect(sceneChanges, 0);
      await runner.stop();
    },
  );

  test('malformed handshake cannot advertise scene ready', () async {
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker(
        (_, _) async => response({'scene': 'Main'}),
      ),
    );
    expect(await runner.connectRuntime('ws://localhost:8181/ws'), isFalse);
    expect(runner.connectionState, RuntimeConnectionState.failed);
    expect(runner.canControlRuntime, isFalse);
    expect(runner.runtimeDiagnostic?.code, 'runtime_protocol_incompatible');
    await runner.stop();
  });

  test('stop during attachment rejects a late scene response', () async {
    final pending = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker((method, _) {
        if (!started.isCompleted) started.complete();
        return pending.future;
      }),
    );
    final attachment = runner.connectRuntime('ws://localhost:8181/ws');
    await started.future;
    await runner.stop();
    pending.complete(response(ready));
    expect(await attachment, isFalse);
    expect(runner.connectionState, RuntimeConnectionState.disconnected);
    expect(runner.runtimeSessionId, isNull);
  });

  test(
    'composition serializes add, dependent move and removal without reload',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final commands = <String>[];
      final positions = <num>[];
      final runner = fakeRunner(
        WorkspaceRuntimeClient.fromInvoker((method, arguments) async {
          if (method == WorkspaceExtensionNames.getState) {
            return response(ready);
          }
          if (method == WorkspaceExtensionNames.getComponentTree) {
            return response({'id': 'Main', 'type': 'Scene', 'children': []});
          }
          if (method == WorkspaceExtensionNames.setTransform) {
            commands.add('transform');
            final transform = arguments['transform'] as Map;
            positions.add((transform['position'] as Map)['x'] as num);
            return response({});
          }
          if (method == WorkspaceExtensionNames.composeComponent) {
            final action = arguments['action'] as String;
            commands.add(action);
            if (action == 'add') {
              started.complete();
              await release.future;
            }
            return response({
              'revision': arguments['revision'],
              'sessionId': arguments['sessionId'],
            });
          }
          fail('Unexpected runtime command $method');
        }),
      );
      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
      final add = runner.composeComponent(
        sceneName: 'Main',
        revision: 1,
        action: 'add',
        componentId: 'arm',
        component: const {'id': 'arm'},
      );
      await started.future;
      final firstMove = runner.setTransform(
        componentId: 'arm',
        transform: const WorkspaceTransform(position: WorkspaceVector2(1, 0)),
      );
      final lastMove = runner.setTransform(
        componentId: 'arm',
        transform: const WorkspaceTransform(position: WorkspaceVector2(99, 0)),
      );
      expect(identical(firstMove, lastMove), isTrue);
      final move = runner.composeComponent(
        sceneName: 'Main',
        revision: 2,
        action: 'move',
        componentId: 'arm',
        index: 0,
      );
      final remove = runner.composeComponent(
        sceneName: 'Main',
        revision: 3,
        action: 'remove',
        componentId: 'arm',
      );
      expect(commands, ['add']);
      release.complete();
      expect(await add, isTrue);
      expect(await firstMove, isTrue);
      expect(await lastMove, isTrue);
      expect(await move, isTrue);
      expect(await remove, isTrue);
      expect(positions, [99]);
      expect(commands, ['add', 'transform', 'move', 'remove']);
      await runner.stop();
    },
  );

  test(
    'stale composition acknowledgement cannot claim an applied edit',
    () async {
      final runner = fakeRunner(
        WorkspaceRuntimeClient.fromInvoker((method, _) async {
          if (method == WorkspaceExtensionNames.getState) {
            return response(ready);
          }
          if (method == WorkspaceExtensionNames.getComponentTree) {
            return response({'id': 'Main', 'type': 'Scene', 'children': []});
          }
          return response({'revision': 0, 'sessionId': 'session-1'});
        }),
      );
      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
      expect(
        await runner.composeComponent(
          sceneName: 'Main',
          revision: 2,
          action: 'remove',
          componentId: 'head',
        ),
        isFalse,
      );
      expect(runner.runtimeDiagnostic?.code, 'runtime_command_failed');
      await runner.stop();
    },
  );

  test('scene change waits for the selected scene to mount', () async {
    var polls = 0;
    var switched = false;
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker((method, _) async {
        if (method == WorkspaceExtensionNames.setScene) {
          switched = true;
          return response({'scene': 'Other'});
        }
        if (method == WorkspaceExtensionNames.getState) {
          if (switched) polls++;
          return response({
            ...ready,
            'scene': switched && polls >= 3 ? 'Other' : 'Main',
            'sceneReady': !switched || polls >= 3,
          });
        }
        if (method == WorkspaceExtensionNames.getComponentTree) {
          final scene = switched && polls >= 3 ? 'Other' : 'Main';
          return response({'id': scene, 'type': 'Scene', 'children': []});
        }
        return response({});
      }),
    );
    expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
    expect(await runner.setScene('Other'), isTrue);
    expect(polls, greaterThanOrEqualTo(3));
    expect(runner.connectionState, RuntimeConnectionState.sceneReady);
    await runner.stop();
  });

  test('stopping during scene loading rejects late acknowledgement', () async {
    final pending = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker((method, _) async {
        if (method == WorkspaceExtensionNames.getState) {
          if (started.isCompleted) return pending.future;
          return response(ready);
        }
        if (method == WorkspaceExtensionNames.getComponentTree) {
          return response({'id': 'Main', 'type': 'Scene', 'children': []});
        }
        if (method == WorkspaceExtensionNames.setScene) started.complete();
        return response({});
      }),
    );
    expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
    final switching = runner.setScene('Other');
    await started.future;
    await runner.stop();
    pending.complete(response({...ready, 'scene': 'Other'}));
    expect(await switching, isFalse);
    expect(runner.connectionState, RuntimeConnectionState.disconnected);
  });

  test('stale attachment cannot replace a newly opened session', () async {
    final oldResponse = Completer<Map<String, dynamic>>();
    final oldStarted = Completer<void>();
    var nextSession = false;
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker((method, _) async {
        if (method == WorkspaceExtensionNames.getState) {
          if (!nextSession) {
            oldStarted.complete();
            return oldResponse.future;
          }
          return response({...ready, 'sessionId': 'new-session'});
        }
        return response({'id': 'Main', 'type': 'Scene', 'children': []});
      }),
    );
    final stale = runner.connectRuntime('ws://localhost:8181/ws');
    await oldStarted.future;
    await runner.stop();
    nextSession = true;
    expect(await runner.connectRuntime('ws://localhost:8282/ws'), isTrue);
    oldResponse.complete(response(ready));
    expect(await stale, isFalse);
    expect(runner.runtimeSessionId, 'new-session');
    expect(runner.connectionState, RuntimeConnectionState.sceneReady);
    await runner.stop();
  });

  test('reconnection ignores the former runtime session', () async {
    var activeSession = 'session-1';
    final runner = fakeRunner(
      WorkspaceRuntimeClient.fromInvoker((method, _) async {
        if (method == WorkspaceExtensionNames.getState) {
          return response({...ready, 'sessionId': activeSession});
        }
        if (method == WorkspaceExtensionNames.getComponentTree) {
          return response({'id': 'Main', 'type': 'Scene', 'children': []});
        }
        return response({});
      }),
    );
    expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
    runner.reportRuntimeConnectionError(StateError('disconnected'));
    activeSession = 'session-2';
    expect(runner.canControlRuntime, isFalse);
    expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
    expect(runner.runtimeSessionId, 'session-2');
    await runner.stop();
  });

  test(
    'connection loss during a command settles edit without stale success',
    () async {
      final pending = Completer<Map<String, dynamic>>();
      final started = Completer<void>();
      final runner = fakeRunner(
        WorkspaceRuntimeClient.fromInvoker((method, _) async {
          if (method == WorkspaceExtensionNames.getState) {
            return response(ready);
          }
          if (method == WorkspaceExtensionNames.getComponentTree) {
            return response({
              'id': 'Main',
              'type': 'MainScene',
              'children': [],
            });
          }
          started.complete();
          return pending.future;
        }),
      );
      expect(await runner.connectRuntime('ws://localhost:8181/ws'), isTrue);
      final edit = runner.setProperty(
        componentId: 'head',
        property: 'priority',
        type: 'int',
        value: 1,
      );
      await started.future;
      runner.reportRuntimeConnectionError(StateError('socket closed'));
      pending.complete(response({}));
      expect(await edit, isFalse);
      expect(runner.connectionState, RuntimeConnectionState.disconnected);
      await runner.stop();
    },
  );
}
