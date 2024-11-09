library fwcm_workspace;

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

VmService? vmService;

void registerWorkspace(String wsUri) async {
  vmService = await vmServiceConnectUri(wsUri);

  log('Connected to workspace at $wsUri');
}

/// Sets the scene to the given scene name.
void setScene(String sceneName) async {
  if (vmService == null) {
    throw Exception('Workspace not connected');
  }

  final vm = await vmService!.getVM();
  final isolateId = vm.isolates!.first.id!;

  vmService!.callServiceExtension(
    'ext.fwcm.set_scene_$sceneName',
    isolateId: isolateId,
  );
}
