import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame_workspace/parser/parser_values.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'flame_workspace_core.dart';

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
    case WorkbenchMessages.propertyChanged:
      final declarationName = data['component'] as String;
      final property = data['property'] as String;
      final value = data['value'] as String;

      final component = FlameWorkspaceCore.instance.game.findByKeyName(
        declarationName,
      );

      print(component?.runtimeType);
      if (component == null) {
        print('Could not find component $declarationName');
        return;
      } else if (component is PositionComponent) {
        if (property case 'position') {
          final vector2 = ValuesParser.parseVector2(value);
          if (vector2 != null) {
            component.position = Vector2(vector2.$1, vector2.$2);
          }
          break;
        } else if (property case 'size') {
          final vector2 = ValuesParser.parseVector2(value);
          if (vector2 != null) {
            component.size = Vector2(vector2.$1, vector2.$2);
          }
          break;
        } else if (property case 'scale') {
          final vector2 = ValuesParser.parseVector2(value);
          if (vector2 != null) {
            component.scale = Vector2(vector2.$1, vector2.$2);
          }
          break;
        } else {
          FlameWorkspaceCore.instance.setPropertyValue(
            // If the component type is Component<SubType>, we only want the
            // Component part.
            component.runtimeType.toString().split('<').first,
            component,
            property,
            value,
          );
          print('Could not find property $property');
          break;
        }
      } else {
        print(
          'It is only possible to change properties of "PositionComponent"s',
        );
      }

      break;
    case WorkbenchMessages.componentSelected:
      final declarationName = data['component'] as String;
      final component = FlameWorkspaceCore.instance.game.findByKeyName(
        declarationName,
      );
      if (!_debugFoundComponent(component, declarationName)) return;

      FlameWorkspaceCore.instance.currentSelectedComponentKey = declarationName;
      break;
    case WorkbenchMessages.componentUnselected:
      FlameWorkspaceCore.instance.currentSelectedComponentKey = null;

    case WorkbenchMessages.componentAdded:
      final declarationName = data['component'] as String;
      FlameWorkspaceCore.instance.currentScene.addComponent(declarationName);
      break;

    case WorkbenchMessages.componentRemoved:
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
  }
}

bool _debugFoundComponent(dynamic component, String declarationName) {
  if (component == null) {
    print('Could not find component $declarationName');
    return false;
  }
  return true;
}
