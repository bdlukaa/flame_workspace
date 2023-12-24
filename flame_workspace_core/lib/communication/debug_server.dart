import 'dart:convert';
import 'dart:io';

import 'package:flame_workspace_core/utils.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../flame_workspace_core.dart';

final connections = <WebSocketChannel>[];

/// Initializes the package server.
Future<HttpServer> createServer() async {
  print('Initializing Server');
  var handler = webSocketHandler((WebSocketChannel webSocket) {
    connections.add(webSocket);

    webSocket.stream.listen(
      (data) => listen(webSocket, data),
      onDone: () => connections.remove(webSocket),
    );
  });

  var server = await io.serve(handler, 'localhost', 8080);

  print('Serving at ws://${server.address.host}:${server.port}');

  return server;
}

void send(dynamic data) {
  if (connections.isEmpty) {
    print('No connections to send data');
    return;
  }
  print('Sending data $data to ${connections.length} connections');
  for (final channel in connections) {
    channel.sink.add(data);
  }
}

void listen(WebSocketChannel channel, dynamic message) {
  print('Received message $message');

  if (message is String) {
    message = json.decode(message);
  }

  assert(message is Map);

  final data = message as Map<String, dynamic>;
  final id = data['id'] as String;

  switch (WorkbenchMessages.fromString(id)) {
    case WorkbenchMessages.setGameState:
      FlameWorkspaceCore.instance.setGameState(GameState.fromMap(data));
      break;
    case WorkbenchMessages.propertyChanged:
      assert(_debugGamePaused());
      final message = PropertyChangedMessage.fromMap(data);

      final component = FlameWorkspaceCore.instance.game.findByKeyName(
        message.component!,
      );

      if (component == null) {
        print(
          'Could not find component ${message.component}/${component.runtimeType}',
        );
        return;
      } else {
        print(
          'Setting property ${message.property} to ${message.value} (${message.type}) of $component',
        );
        FlameWorkspaceCore.instance.setPropertyValue(
          // If the component type is Component<SubType>, we only want the
          // Component part.
          component.runtimeType.toString().removeGenerics(),
          component,
          message.property,
          ValuesParser.parse(message.type, message.value),
        );
      }

      break;
    case WorkbenchMessages.componentSelected:
      assert(_debugGamePaused());
      final declarationName = data['component'] as String;
      final component = FlameWorkspaceCore.instance.game.findByKeyName(
        declarationName,
      );
      if (!_debugFoundComponent(component, declarationName)) return;

      FlameWorkspaceCore.instance.currentSelectedComponentKey = declarationName;
      break;
    case WorkbenchMessages.componentUnselected:
      assert(_debugGamePaused());
      FlameWorkspaceCore.instance.currentSelectedComponentKey = null;
      break;

    case WorkbenchMessages.componentAdded:
      assert(_debugGamePaused());
      final declarationName = data['component'] as String;
      FlameWorkspaceCore.instance.currentScene.addComponent(declarationName);
      break;

    case WorkbenchMessages.componentRemoved:
      assert(_debugGamePaused());
      final declarationName = data['component'] as String;
      final component = FlameWorkspaceCore.instance.game.findByKeyName(
        declarationName,
      );
      if (!_debugFoundComponent(component, declarationName)) return;

      FlameWorkspaceCore.instance.currentScene.remove(
        // the component parent is removed because the components, when added,
        // are wrapped in a FlameComponent using [FlameComponent.wrap]. This
        // is the effective component that is added and it is the one that needs
        // to be removed.
        component!.parent!,
      );
      break;
    case WorkbenchMessages.setScene:
      // assert(_debugGamePaused());
      final scene = data['scene'] as String;
      FlameWorkspaceCore.instance.setScene(scene);
      break;
  }
}

bool _debugFoundComponent(dynamic component, String declarationName) {
  if (component == null) {
    print('Could not find component $declarationName');
    return false;
  }
  return true;
}

bool _debugGamePaused() {
  // if (!FlameWorkspaceCore.instance.game.paused) {
  //   print(
  //     'To manipulate the current scene, the game must be paused. You can pause '
  //     'the game using the pause button (||) on the top right corner of the '
  //     'screen.',
  //   );
  //   return false;
  // }
  // return true;
  return true;
}
