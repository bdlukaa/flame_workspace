import 'package:flame_workspace_communication_bridge/runtime_client.dart';
import 'package:flame_workspace_protocol/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client sends stable method and structured arguments', () async {
    String? method;
    Map<String, dynamic>? arguments;
    final client = WorkspaceRuntimeClient.fromInvoker((receivedMethod, args) {
      method = receivedMethod;
      arguments = args;
      return Future.value(
        const WorkspaceRuntimeResponse.success({'scene': 'level_one'}).toMap(),
      );
    });

    final result = await client.invoke(
      WorkspaceExtensionNames.setScene,
      arguments: {'scene': 'level_one'},
    );

    expect(method, WorkspaceExtensionNames.setScene);
    expect(arguments, {'scene': 'level_one'});
    expect(result, {'scene': 'level_one'});
  });

  test('client surfaces structured runtime failures', () async {
    final client = WorkspaceRuntimeClient.fromInvoker((_, _) {
      return Future.value(
        const WorkspaceRuntimeResponse.failure(
          error: WorkspaceRuntimeError(
            code: 'component_not_found',
            message: 'No component exists.',
          ),
        ).toMap(),
      );
    });

    await expectLater(
      client.invoke(WorkspaceExtensionNames.setProperty),
      throwsA(
        isA<WorkspaceRuntimeException>().having(
          (error) => error.code,
          'code',
          'component_not_found',
        ),
      ),
    );
  });

  test('client decodes VM Service result envelopes', () async {
    final client = WorkspaceRuntimeClient.fromInvoker((_, _) {
      return Future.value({
        'result': const WorkspaceRuntimeResponse.success({'paused': true})
            .toJsonString(),
      });
    });

    expect(await client.invoke(WorkspaceExtensionNames.getState), {
      'paused': true,
    });
  });
}
