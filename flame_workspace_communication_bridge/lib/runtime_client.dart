import 'dart:convert';

import 'package:flame_workspace_protocol/runtime.dart';
import 'package:vm_service/vm_service.dart';

/// Invokes one VM Service extension and returns its JSON response.
typedef WorkspaceServiceExtensionInvoker =
    Future<Map<String, dynamic>> Function(
      String method,
      Map<String, dynamic> arguments,
    );

class WorkspaceRuntimeClient {
  WorkspaceRuntimeClient.fromVmService({
    required VmService service,
    required String isolateId,
  }) : _invoke = _vmServiceInvoker(service, isolateId);

  WorkspaceRuntimeClient.fromInvoker(this._invoke);

  static WorkspaceServiceExtensionInvoker _vmServiceInvoker(
    VmService service,
    String isolateId,
  ) => (method, arguments) async {
    final response = await service.callServiceExtension(
      method,
      isolateId: isolateId,
      args: {
        'request': jsonEncode(
          WorkspaceRuntimeRequest(arguments: arguments).toMap(),
        ),
      },
    );
    return response.json ?? const <String, dynamic>{};
  };

  final WorkspaceServiceExtensionInvoker _invoke;

  Future<dynamic> invoke(
    String method, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final response = await invokeResponse(method, arguments: arguments);
    if (!response.ok) {
      final error = response.error!;
      throw WorkspaceRuntimeException(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    }
    return response.result;
  }

  Future<WorkspaceRuntimeResponse> invokeResponse(
    String method, {
    Map<String, dynamic> arguments = const {},
  }) async {
    try {
      final payload = await _invoke(method, arguments);
      final decoded = _decodePayload(payload);
      return WorkspaceRuntimeResponse.fromMap(decoded);
    } on FormatException catch (error) {
      throw WorkspaceRuntimeException(
        code: 'invalid_response',
        message: 'The runtime returned an invalid response.',
        details: error.message,
      );
    }
  }

  Map<String, dynamic> _decodePayload(Map<String, dynamic> payload) {
    if (payload.containsKey('ok')) return payload;

    final result = payload['result'];
    if (result is String) {
      final decoded = jsonDecode(result);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    if (result is Map) return Map<String, dynamic>.from(result);
    return payload;
  }
}

class WorkspaceRuntimeException implements Exception {
  const WorkspaceRuntimeException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final dynamic details;

  @override
  String toString() {
    final suffix = details == null ? '' : ' ($details)';
    return 'WorkspaceRuntimeException[$code]: $message$suffix';
  }
}
