import 'package:nwc/src/model/event.dart';
import 'package:nwc/src/model/event_eose.dart';
import 'package:nwc/src/model/event_ok.dart';
import 'package:nwc/src/model/events_stream.dart';
import 'package:nwc/src/model/request.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class RelaysBase {
  Map<String, WebSocketChannel> get relaysWebSocketsRegistry;
  Map<String, Event> get eventsRegistry;

  List<String>? relaysList;

  init({
    required List<String> relaysUrl,
    void Function(
      String relayUrl,
      dynamic receivedData,
      WebSocketChannel? relayWebSocket,
    )? onRelayListening,
    void Function(
      String relayUrl,
      Object? error,
      WebSocketChannel? relayWebSocket,
    )? onRelayConnectionError,
    void Function(
      String relayUrl,
      WebSocketChannel? relayWebSocket,
    )? onRelayConnectionDone,
    bool lazyListeningToRelays = false,
    bool retryOnError = false,
    bool retryOnClose = false,
  });

  Future<EventOk> sendEventToRelays(
    Event event, {
    required Duration timeout,
  });

  EventsStream startEventsSubscription({
    required Request request,
    void Function(String relay, EventEose ease)? onEose,
    bool useConsistentSubscriptionIdBasedOnRequestData = false,
  });

  void closeEventsSubscription(String subscriptionId, [String? relayUrl]);

  void startListeningToRelay({
    required String relay,
    required void Function(
      String relayUrl,
      dynamic receivedData,
      WebSocketChannel? relayWebSocket,
    )? onRelayListening,
    required void Function(
      String relayUrl,
      Object? error,
      WebSocketChannel? relayWebSocket,
    )? onRelayConnectionError,
    required void Function(String relayUrl, WebSocketChannel? relayWebSocket)?
        onRelayConnectionDone,
    required bool retryOnError,
    required bool retryOnClose,
    required bool shouldReconnectToRelayOnNotice,
    required Duration connectionTimeout,
    required bool ignoreConnectionException,
    required bool lazyListeningToRelays,
  });

  Future<void> reconnectToRelays({
    required void Function(
      String relayUrl,
      dynamic receivedData,
      WebSocketChannel? relayWebSocket,
    )? onRelayListening,
    required void Function(
      String relayUrl,
      Object? error,
      WebSocketChannel? relayWebSocket,
    )? onRelayConnectionError,
    required void Function(String relayUrl, WebSocketChannel? relayWebSocket)?
        onRelayConnectionDone,
    required bool retryOnError,
    required bool retryOnClose,
    required bool shouldReconnectToRelayOnNotice,
    required Duration connectionTimeout,
    required bool ignoreConnectionException,
    required bool lazyListeningToRelays,
    bool relayUnregistered = true,
  });

  Future<void> freeAllResources();
}
