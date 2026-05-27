import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the Socket.io connection to the MedGraph backend.
/// Used for real-time matching, presence, and call signalling.
class SocketService {
  SocketService._();

  static io.Socket? _socket;

  static const String _base = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  static void connect() {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    _socket = io.io(
      _base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  static void emit(String event, dynamic data) {
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
