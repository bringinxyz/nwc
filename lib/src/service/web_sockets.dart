import 'package:nwc/src/utils/nwc_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A service that manages the relays web sockets connections
class NostrWebSocketsService {
  NostrWebSocketsService({
    required this.utils,
  });

  final NWCLoggerUtils utils;

  /// Connects to a [relay] web socket, and trigger the [onConnectionSuccess] callback if the connection is successful, or the [onConnectionError] callback if the connection fails.
  Future<void> connectRelay({
    required String relay,
    bool? shouldIgnoreConnectionException,
    void Function(WebSocketChannel webSocket)? onConnectionSuccess,
  }) async {
    WebSocketChannel? webSocket;

    try {
      webSocket = WebSocketChannel.connect(
        Uri.parse(relay),
      );

      await webSocket.ready;

      onConnectionSuccess?.call(webSocket);
    } catch (e) {
      utils.log(
        'error while connecting to the relay with url: $relay',
        e,
      );

      if (shouldIgnoreConnectionException ?? true) {
        utils.log(
          'The error related to relay: $relay is ignored, because to the ignoreConnectionException parameter is set to true.',
        );
      } else {
        rethrow;
      }
    }
  }

  /// Changes the protocol of a websocket url to http.
  Uri getHttpUrlFromWebSocketUrl(String relayUrl) {
    assert(
      relayUrl.startsWith('ws://') || relayUrl.startsWith('wss://'),
      '[!] invalid relay url',
    );

    try {
      var removeWebsocketSign = relayUrl.replaceFirst('ws://', 'http://');
      removeWebsocketSign =
          removeWebsocketSign.replaceFirst('wss://', 'https://');
      return Uri.parse(removeWebsocketSign);
    } catch (e) {
      utils.log(
        '[!] error while getting http url from websocket url: $relayUrl',
        e,
      );

      rethrow;
    }
  }
}
