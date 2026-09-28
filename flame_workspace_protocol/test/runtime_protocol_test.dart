import 'dart:convert';

import 'package:flame_workspace_protocol/runtime.dart';
import 'package:test/test.dart';

void main() {
  test('runtime requests round-trip structured arguments', () {
    const request = WorkspaceRuntimeRequest(
      arguments: {
        'componentId': 'player',
        'transform': {
          'position': {'x': 10, 'y': 20},
        },
      },
    );

    final decoded = WorkspaceRuntimeRequest.fromJsonString(
      request.toJsonString(),
    );

    expect(decoded.arguments['componentId'], 'player');
    expect(decoded.arguments['transform'], isA<Map>());
  });

  test('runtime responses preserve structured errors', () {
    const response = WorkspaceRuntimeResponse.failure(
      error: WorkspaceRuntimeError(
        code: 'component_not_found',
        message: 'No component exists.',
        details: {'componentId': 'missing'},
      ),
    );

    final decoded = WorkspaceRuntimeResponse.fromMap(
      jsonDecode(response.toJsonString()) as Map<String, dynamic>,
    );

    expect(decoded.ok, isFalse);
    expect(decoded.error!.code, 'component_not_found');
    expect(decoded.error!.details, {'componentId': 'missing'});
  });

  test('invalid request JSON is rejected', () {
    expect(
      () => WorkspaceRuntimeRequest.fromJsonString('[]'),
      throwsA(isA<FormatException>()),
    );
  });
}
