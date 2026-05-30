import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_storage.dart';

/// Manages the Socket.io connection to the MedGraph backend.
/// Used for real-time matching, presence, and call signalling.
class SocketService {
  SocketService._();

  static io.Socket? _socket;

  // Must match api_service.dart default so both point at the same server.
  static const String _base = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://medgraph-backend-2py8.onrender.com',
  );

  /// Connect (or reuse an existing connection).
  /// [onConnected] is called immediately if already connected,
  /// or once the handshake completes.
  static void connect({void Function()? onConnected}) {
    if (_socket?.connected == true) {
      // ignore: avoid_print
      print('SOCKET already connected: ${_socket!.id}');
      onConnected?.call();
      return;
    }

    final token = AuthStorage.token;
    // ignore: avoid_print
    print('SOCKET connecting to $_base');

    _socket = io.io(
      _base,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('SOCKET CONNECTED: ${_socket!.id}');
      onConnected?.call();
    });
    _socket!.onConnectError((e) {
      // ignore: avoid_print
      print('SOCKET CONN ERROR: $e');
    });
    _socket!.onError((e) {
      // ignore: avoid_print
      print('SOCKET ERROR: $e');
    });
    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('SOCKET DISCONNECTED');
    });

    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void emit(String event, dynamic data) {
    // ignore: avoid_print
    print('SOCKET EMIT $event: $data');
    _socket?.emit(event, data);
  }

  static void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static bool get isConnected => _socket?.connected ?? false;
}
