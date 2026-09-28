import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'package:flame_workspace_protocol/runtime.dart';

import 'runtime_client.dart';

export 'dart:developer' hide Timeline;

export 'package:vm_service/vm_service.dart';
export 'package:vm_service/vm_service_io.dart';

export 'runtime_client.dart';

VmService? vmService;
WorkspaceRuntimeClient? runtimeClient;

Future<void> registerWorkspace(String wsUri) async {
  vmService = await vmServiceConnectUri(wsUri);
  final vm = await vmService!.getVM();
  final isolateId = vm.isolates?.isNotEmpty == true
      ? vm.isolates!.first.id
      : null;
  if (isolateId == null) {
    throw StateError('The connected VM has no usable isolate.');
  }
  runtimeClient = WorkspaceRuntimeClient.fromVmService(
    service: vmService!,
    isolateId: isolateId,
  );

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
