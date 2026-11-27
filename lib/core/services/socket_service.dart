import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:bookease/core/network/network_config.dart';
import 'package:bookease/core/storage/token_storage.dart';

typedef SocketEventHandler = void Function(Map<String, dynamic> payload);

class SocketService extends WidgetsBindingObserver {
  final TokenStorage _tokenStorage;
  socket_io.Socket? _socket;
  bool _isConnected = false;
  bool _lifecycleObserverAttached = false;
  String? _userId;

  VoidCallback? onConnected;
  VoidCallback? onDisconnected;
  SocketEventHandler? onMessageNew;
  SocketEventHandler? onMessageRead;
  SocketEventHandler? onChatUnreadCountUpdated;
  SocketEventHandler? onConversationUpdated;
  SocketEventHandler? onTyping;
  SocketEventHandler? onStopTyping;
  SocketEventHandler? onBookingEvent;
  SocketEventHandler? onNotificationNew;
  SocketEventHandler? onNotificationRead;
  SocketEventHandler? onNotificationDeleted;
  SocketEventHandler? onNotificationUnreadCountUpdated;
  SocketEventHandler? onPresenceEvent;
  SocketEventHandler? onServiceEvent;
  SocketEventHandler? onFavoriteEvent;

  SocketService(this._tokenStorage);

  bool get isConnected => _isConnected;

  static const bool _socketDebugEnabled = bool.fromEnvironment('SOCKET_DEBUG');

  void _log(String message) {
    if (kDebugMode || _socketDebugEnabled) {
      debugPrint('[SOCKET] $message');
    }
  }

  static String get _serverRootUrl {
    final uri = Uri.parse(NetworkConfig.baseUrl);
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    final rootPath = path.replaceFirst(RegExp(r'/api(?:/v\d+)?$'), '');
    return uri.replace(path: rootPath, query: null, fragment: null).toString();
  }

  Map<String, dynamic> _asPayload(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  void _listen(String event, SocketEventHandler? handler) {
    _socket!.on(event, (dynamic payload) {
      final parsedPayload = _asPayload(payload);
      _log(
        'received event=$event userId=${_userId ?? "unknown"} '
        'payloadKeys=${parsedPayload.keys.join(",")}',
      );
      handler?.call(parsedPayload);
    });
  }

  void connect({required String userId}) {
    if (_socket != null) {
      _log('connect skipped; socket already initialized userId=$userId');
      return;
    }

    final token = _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      _log('connect skipped; no authentication token userId=$userId');
      return;
    }

    try {
      _userId = userId;
      _log('connecting userId=$userId url=$_serverRootUrl');
      final socket = socket_io.io(
        _serverRootUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setAuth({'token': token})
            .build(),
      );
      _socket = socket;
      if (!_lifecycleObserverAttached) {
        WidgetsBinding.instance.addObserver(this);
        _lifecycleObserverAttached = true;
      }

      socket.onConnect((_) {
        _isConnected = true;
        _log('connected userId=$userId');
        onConnected?.call();
      });

      socket.onDisconnect((reason) {
        _isConnected = false;
        onDisconnected?.call();
        _log('disconnected userId=$userId reason=$reason');
      });

      socket.onError((error) {
        _log('socket error userId=$userId error=$error');
      });

      socket.onConnectError((error) {
        _log('connection error userId=$userId error=$error');
      });

      _listen('message:new', onMessageNew);
      _listen('message:read', onMessageRead);
      _listen('chat:unread_count_updated', onChatUnreadCountUpdated);
      _listen('conversation:updated', onConversationUpdated);
      _listen('message:typing', onTyping);
      _listen('message:stop_typing', onStopTyping);

      for (final event in const [
        'booking:created',
        'booking:accepted',
        'booking:rejected',
        'booking:cancelled',
        'booking:completed',
        'booking:updated',
      ]) {
        _listen(
            event,
            onBookingEvent == null
                ? null
                : (payload) {
                    onBookingEvent!({...payload, 'event': event});
                  });
      }

      _listen('notification:new', onNotificationNew);
      _listen('notification:read', onNotificationRead);
      _listen('notification:deleted', onNotificationDeleted);
      _listen(
        'notification:unread_count_updated',
        onNotificationUnreadCountUpdated,
      );

      for (final event in const ['user:online', 'user:offline']) {
        _listen(
            event,
            onPresenceEvent == null
                ? null
                : (payload) {
                    onPresenceEvent!({...payload, 'event': event});
                  });
      }

      for (final event in const [
        'service:created',
        'service:updated',
        'service:deleted',
      ]) {
        _listen(
            event,
            onServiceEvent == null
                ? null
                : (payload) {
                    onServiceEvent!({...payload, 'event': event});
                  });
      }

      for (final event in const ['favorite:added', 'favorite:removed']) {
        _listen(
            event,
            onFavoriteEvent == null
                ? null
                : (payload) {
                    onFavoriteEvent!({...payload, 'event': event});
                  });
      }

      socket.connect();
    } catch (error) {
      _removeLifecycleObserver();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _userId = null;
      _log('initialization failed userId=$userId error=$error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final socket = _socket;
    if (socket == null) return;
    _log(
        'app resumed userId=${_userId ?? "unknown"} connected=${socket.connected}');
    if (socket.connected) {
      _isConnected = true;
      onConnected?.call();
    } else {
      socket.connect();
    }
  }

  void _removeLifecycleObserver() {
    if (!_lifecycleObserverAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleObserverAttached = false;
  }

  Future<bool> joinConversation(String conversationId) =>
      _conversationRoomAction('conversation:join', conversationId, 'joined');

  Future<bool> leaveConversation(String conversationId) =>
      _conversationRoomAction('conversation:leave', conversationId, 'left');

  Future<bool> _conversationRoomAction(
    String event,
    String conversationId,
    String successKey,
  ) async {
    final socket = _socket;
    if (socket == null || !_isConnected || conversationId.isEmpty) {
      _log(
        'room action unavailable event=$event userId=${_userId ?? "unknown"} '
        'conversationId=$conversationId connected=$_isConnected',
      );
      return false;
    }

    _log(
        'room action requested event=$event userId=$_userId conversationId=$conversationId');
    final completer = Completer<bool>();
    socket.emitWithAck(
      event,
      {'conversationId': conversationId},
      ack: (dynamic response) {
        final payload = _asPayload(response);
        if (!completer.isCompleted) {
          final succeeded = payload[successKey] == true;
          _log(
            'room action ${succeeded ? "succeeded" : "failed"} '
            'event=$event userId=$_userId conversationId=$conversationId '
            'responseKeys=${payload.keys.join(",")}',
          );
          completer.complete(succeeded);
        }
      },
    );

    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _log(
          'room action timed out event=$event userId=$_userId conversationId=$conversationId');
      return false;
    }
  }

  void sendTyping(String conversationId) {
    emit('message:typing', {'conversationId': conversationId});
  }

  void stopTyping(String conversationId) {
    emit('message:stop_typing', {'conversationId': conversationId});
  }

  void disconnect() {
    final socket = _socket;
    _removeLifecycleObserver();
    if (socket == null) return;

    socket.disconnect();
    socket.dispose();
    _socket = null;
    _isConnected = false;
    _log('disposed userId=${_userId ?? "unknown"}');
    _userId = null;
  }

  void emit(String event, [dynamic data]) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    }
  }
}
