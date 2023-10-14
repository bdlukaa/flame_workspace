import 'dart:io';

/// Initializes the package server.
Future<HttpServer> createServer() async {
  final address = InternetAddress.loopbackIPv4;
  const port = 4040;

  return await HttpServer.bind(address, port);
}
