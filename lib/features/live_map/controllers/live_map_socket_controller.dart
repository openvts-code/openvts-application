import '../../../core/socket/socket_service.dart';

class LiveMapSocketController {
  const LiveMapSocketController(this._socketService);

  final SocketService _socketService;

  Future<SocketConnection> connectTelemetry() {
    return _socketService.connect('/telemetry');
  }

  Future<SocketConnection> connectNotifications() {
    return _socketService.connect('/notifications');
  }
}
