/// The part where the game is called.
library fwcb_game;

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

VmService? vmService;

/// Registers the game VM and necessary extensions.
void registerGame() async {
  final info = await Service.getInfo();
  final serverUri = info.serverUri;
  if (serverUri != null) {
    vmService = await vmServiceConnectUri(
      info.serverWebSocketUri!.toString(),
    );
  }
}

Future<InstanceRef?> initializeClass(
  String className,
  Map<String, dynamic> namedParameters,
) async {
  assert(vmService != null);
  final vm = await vmService!.getVM();
  final isolateId = vm.isolates!.first.id!;

  final result = await vmService!.evaluate(
    isolateId,
    isolateId,
    [
      className,
      '(',
      namedParameters.entries.map((entry) {
        if (entry.value is String) {
          return '${entry.key}: "${entry.value}"';
        }
        return '${entry.key}: ${entry.value}';
      }).join(', '),
      ')',
    ].join(),
  );

  if (result.type == 'InstanceRef') {
    return InstanceRef.parse(result.json);
  }

  return null;
}
