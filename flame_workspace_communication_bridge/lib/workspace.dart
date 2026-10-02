import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'package:flame_workspace_protocol/runtime.dart';

import 'runtime_client.dart';

export 'dart:developer' hide Timeline;

export 'package:vm_service/vm_service.dart';
export 'package:vm_service/vm_service_io.dart';

export 'runtime_client.dart';

/// An owned VM Service connection; disposing it also settles outstanding RPCs.
class WorkspaceRuntimeConnection {
  WorkspaceRuntimeConnection._(this.service, this.client, this.isolateId);

  final VmService service;
  final WorkspaceRuntimeClient client;
  final String isolateId;
  Future<void> get onDone => service.onDone;
  Future<void> dispose() => service.dispose();

  static Future<WorkspaceRuntimeConnection> connect(String wsUri) async {
    final service = await vmServiceConnectUri(wsUri);
    try {
      final vm = await service.getVM().timeout(const Duration(seconds: 10));
      final isolates = vm.isolates ?? const [];
      for (final reference in isolates) {
        if (reference.id case final id?) {
          final isolate = await service
              .getIsolate(id)
              .timeout(const Duration(seconds: 10));
          if (isolate.name == 'main' || isolates.length == 1) {
            return WorkspaceRuntimeConnection._(
              service,
              WorkspaceRuntimeClient.fromVmService(
                service: service,
                isolateId: id,
              ),
              id,
            );
          }
        }
      }
      throw StateError('The VM Service has no main game isolate.');
    } catch (_) {
      await service.dispose();
      rethrow;
    }
  }
}

VmService? vmService;
WorkspaceRuntimeClient? runtimeClient;

Future<void> registerWorkspace(String wsUri) async {
  final connection = await WorkspaceRuntimeConnection.connect(wsUri);
  await vmService?.dispose();
  vmService = connection.service;
  runtimeClient = connection.client;
  log('Connected to workspace at $wsUri');
}

Future<dynamic> invokeWorkspaceExtension(
  String method, {
  Map<String, dynamic> arguments = const {},
}) {
  final client = runtimeClient;
  if (client == null) {
    throw StateError('Workspace runtime is not connected.');
  }
  return client.invoke(method, arguments: arguments);
}

/// Sets the scene to the given scene name through the stable runtime API.
Future<void> setScene(String sceneName) async {
  await invokeWorkspaceExtension(
    WorkspaceExtensionNames.setScene,
    arguments: {'scene': sceneName},
  );
}
