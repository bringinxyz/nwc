import 'dart:async';

import 'package:nwc/nwc.dart';
import 'package:nwc/src/base/relays/relays_base.dart';
import 'package:nwc/src/model/event_eose.dart';
import 'package:nwc/src/model/event_ok.dart';
import 'package:nwc/src/model/relay.dart';
import 'package:nwc/src/service/registry.dart';
import 'package:nwc/src/service/streams.dart';
import 'package:nwc/src/service/web_sockets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Class responsible for managing relay-related operations.
class Relays implements RelaysBase {
  Relays({required this.utils}) {
    nostrRegistry = Registry(utils: utils);
  }

  /// Instance of [NWCLoggerUtils] used for logging and utility operations.
  final NWCLoggerUtils utils;

  /// Registry for managing relay-related information.
  late final Registry nostrRegistry;

  final streamsController = NostrStreamsControllers();

  /// Manages WebSocket connections to relays.
  late final webSocketsService = NostrWebSocketsService(utils: utils);

  /// Represents a registry of all relays that have been registered.
  @override
  Map<String, WebSocketChannel> get relaysWebSocketsRegistry =>
      nostrRegistry.relaysWebSocketsRegistry;

  /// Represents a registry of all events received from all relays so far.
  @override
  Map<String, Event> get eventsRegistry => nostrRegistry.eventsRegistry;

  /// The list of relay URLs that have been registered.
  @override
  List<String>? relaysList;

  /// Initializes connections to all specified relays.
  ///
  /// This method establishes connections to each relay specified in the [relaysUrl] list.
  /// It registers each relay for future use. If [relaysUrl] is empty, an [AssertionError] is thrown
  /// as it doesn't make sense to connect to an empty list of relays.
  ///
  /// Relays' WebSocket connections start listening for events immediately after calling this method,
  /// unless [lazyListeningToRelays] is set to `true`. In that case, use the [startListeningToRelay] method
  /// to begin listening manually.
  ///
  /// You can provide callbacks to the [onRelayListening], [onRelayConnectionError], and [onRelayConnectionDone] parameters
  /// to be notified when a relay starts listening to its WebSocket, encounters an error, or closes the connection, respectively.
  ///
  /// Set [lazyListeningToRelays] to `true` if you prefer manual control over when to start listening to relays.
  /// This is useful if you want to delay listening until after calling the [init] method.
  ///
  /// To retry connecting to relays in case of an error or closure, set [retryOnError] or [retryOnClose] to `true`, respectively.
  ///
  /// If [ensureToClearRegistriesBeforeStarting] is set to `true`, all registries will be cleared before starting.
  /// This is useful for implementing a reconnect mechanism.
  ///
  /// Set [ignoreConnectionException] to `true` to ignore connection exceptions. This is useful for
  /// ignoring exceptions and retrying connections in case of an error (set [retryOnError] to `true`).
  ///
  /// This method must be called before using any other methods, typically in the `main()` function to ensure
  /// connections are established before use.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   await NWC.instance.relays.init(
  ///     relaysUrl: ["ws://localhost:8080"],
  ///     onRelayListening: (relayUrl) {
  ///       print("Relay with URL: $relayUrl is listening");
  ///     },
  ///     onRelayConnectionError: (relayUrl, error) {
  ///       print("Relay with URL: $relayUrl has thrown an error: $error");
  ///     },
  ///     onRelayConnectionDone: (relayUrl) {
  ///       print("Relay with URL: $relayUrl is closed");
  ///     },
  ///   );
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Use this method to re-connect to all relays in case of a connection failure.
  @override
  Future<void> init({
    required List<String> relaysUrl,
    void Function(
      String relayUrl,
      dynamic receivedData,
      WebSocketChannel? relayWebSocket,
    )? onRelayListening,
    void Function(
            String relayUrl, Object? error, WebSocketChannel? relayWebSocket)?
        onRelayConnectionError,
    void Function(String relayUrl, WebSocketChannel? relayWebSocket)?
        onRelayConnectionDone,
    bool lazyListeningToRelays = false,
    bool retryOnError = false,
    bool retryOnClose = false,
    bool ensureToClearRegistriesBeforeStarting = true,
    bool ignoreConnectionException = true,
    bool shouldReconnectToRelayOnNotice = false,
    Duration connectionTimeout = const Duration(seconds: 5),
  }) async {
    assert(
      relaysUrl.isNotEmpty,
      "initiating relays with an empty list doesn't make sense, please provide at least one relay url.",
    );
    relaysList = List.of(relaysUrl);

    _clearRegistriesIf(ensureToClearRegistriesBeforeStarting);

    return _startConnectingAndRegisteringRelays(
      relaysUrl: relaysUrl,
      onRelayListening: onRelayListening,
      onRelayConnectionError: onRelayConnectionError,
      onRelayConnectionDone: onRelayConnectionDone,
      lazyListeningToRelays: lazyListeningToRelays,
      retryOnError: retryOnError,
      retryOnClose: retryOnClose,
      ignoreConnectionException: ignoreConnectionException,
      shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
      connectionTimeout: connectionTimeout,
    );
  }

  /// Sends an event to all registered relays.
  ///
  /// This method takes a nostr [Event] object, serializes it internally, and sends it to all registered relay WebSockets.
  ///
  /// Example:
  /// ```dart
  /// await NWC.instance.relays.sendEventToRelays(event);
  /// ```
  ///
  /// You get a [Future] of nostr [EventOk] command that will be triggered when the event is accepted by the relays.
  @override
  Future<EventOk> sendEventToRelays(
    Event event, {
    required Duration timeout,
  }) {
    var isSomeOkTriggered = false;

    final completers = <Completer<EventOk>>[];

    _runFunctionOverRelationIteration((relay) {
      final completer = Completer<EventOk>();
      completers.add(completer);

      Future.delayed(timeout, () {
        if (!isSomeOkTriggered) {
          throw TimeoutException(
            'the event with id: ${event.id} has timed out after: ${timeout.inSeconds} seconds',
          );
        }
      });

      final serialized = event.serialized();

      if (event.id == null) {
        throw Exception('event id cannot be null');
      }

      _registerOnOklCallBack(
        associatedEventId: event.id!,
        relay: relay.url,
        onOk: (relay, ok) {
          isSomeOkTriggered = true;
          completer.complete(ok);
        },
      );

      relay.socket.sink.add(serialized);
      utils.log(
        'event with id: ${event.id} is sent to relay with url: ${relay.url}',
      );
    });

    return Future.any(completers.map((e) => e.future));
  }

  /// Sends a request to all registered relays and returns a stream of events filtered by the request's subscription ID.
  ///
  /// If the [request] does not specify a [subscriptionId], one will be generated automatically by the package.
  /// This is recommended only if you do not plan to use the [closeEventsSubscription] method.
  ///
  /// Example:
  /// ```dart
  /// NWC.instance.relays.startEventsSubscription(request);
  /// ```
  @override
  EventsStream startEventsSubscription({
    required Request request,
    void Function(String relay, EventEose eose)? onEose,
    bool useConsistentSubscriptionIdBasedOnRequestData = false,
  }) {
    final serialized = request.serialized(
      subscriptionId: useConsistentSubscriptionIdBasedOnRequestData
          ? null
          : NWC.instance.generalService.random64HexChars(),
    );

    _runFunctionOverRelationIteration((relay) {
      _registerOnEoselCallBack(
        subscriptionId: request.subscriptionId!,
        onEose: onEose ?? (relay, eose) {},
        relay: relay.url,
      );

      relay.socket.sink.add(serialized);
      utils.log(
        'request with subscription id: ${request.subscriptionId} is sent to relay with url: ${relay.url}',
      );
    });

    final requestSubId = request.subscriptionId;
    final subStream = streamsController.events.where(
      (event) => _filterNostrEventsWithId(event, requestSubId),
    );

    return EventsStream(
      request: request,
      stream: subStream,
      subscriptionId: request.subscriptionId!,
    );
  }

  /// Closes the subscription identified by the provided [subscriptionId].
  ///
  /// Use this method after calling [startEventsSubscription] to close the subscription associated with the given [subscriptionId].
  ///
  /// Example:
  /// ```dart
  /// NWC.instance.relays.closeEventsSubscription("<subscriptionId>");
  /// ```
  @override
  void closeEventsSubscription(String subscriptionId, [String? relay]) {
    final close = EventClose(
      subscriptionId: subscriptionId,
    );

    final serialized = close.serialized();

    if (relay != null) {
      final registeredRelay = nostrRegistry.getRelayWebSocket(relayUrl: relay);

      registeredRelay?.sink.add(serialized);

      utils.log(
        'Close request with subscription id: $subscriptionId is sent to relay with url: $relay',
      );

      return;
    }
    _runFunctionOverRelationIteration(
      (relay) {
        relay.socket.sink.add(serialized);
        utils.log(
          'Close request with subscription id: $subscriptionId is sent to relay with url: ${relay.url}',
        );
      },
    );
  }

  /// Starts listening to all registered relays.
  ///
  /// Call this method manually only if you set the [lazyListeningToRelays] parameter to `true` in the [init] method.
  /// Otherwise, it will be called automatically by the [init] method.
  ///
  /// Example:
  /// ```dart
  /// NWC.instance.relays.startListeningToRelay(
  ///   onRelayListening: (relayUrl, receivedData) {
  ///     print("Received data: $receivedData from relay with URL: $relayUrl");
  ///   },
  ///   onRelayConnectionError: (relayUrl, error) {
  ///     print("Relay with URL: $relayUrl has thrown an error: $error");
  ///   },
  ///   onRelayConnectionDone: (relayUrl) {
  ///     print("Relay with URL: $relayUrl is closed");
  ///   },
  /// );
  /// ```
  ///
  /// You can also use this method to re-connect to all relays in case of a connection failure.
  @override
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
    void Function(
            String relay, WebSocketChannel? relayWebSocket, Notice notice)?
        onNoticeMessageFromRelay,
  }) {
    final relayWebSocket = nostrRegistry.getRelayWebSocket(relayUrl: relay);

    relayWebSocket!.stream.listen(
      (d) {
        final data = d.toString();

        onRelayListening?.call(relay, d, relayWebSocket);

        if (Event.canBeDeserialized(data)) {
          _handleAddingEventToSink(
            event: Event.deserialized(data),
            relay: relay,
          );
        } else if (Notice.canBeDeserialized(data)) {
          final notice = Notice.fromRelayMessage(data);

          onNoticeMessageFromRelay?.call(relay, relayWebSocket, notice);

          _handleNoticeFromRelay(
            notice: notice,
            relay: relay,
            onRelayListening: onRelayListening,
            connectionTimeout: connectionTimeout,
            ignoreConnectionException: ignoreConnectionException,
            lazyListeningToRelays: lazyListeningToRelays,
            onRelayConnectionError: onRelayConnectionError,
            onRelayConnectionDone: onRelayConnectionDone,
            retryOnError: retryOnError,
            retryOnClose: retryOnClose,
            shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
          );
        } else if (EventOk.canBeDeserialized(data)) {
          _handleOkCommandMessageFromRelay(
            okCommand: EventOk.fromRelayMessage(data),
            relay: relay,
          );
        } else if (EventEose.canBeDeserialized(data)) {
          _handleEoseCommandMessageFromRelay(
            eoseCommand: EventEose.fromRelayMessage(data),
            relay: relay,
          );
        } else if (CountResponse.canBeDeserialized(data)) {
          final countResponse = CountResponse.deserialized(data);

          _handleCountResponseMessageFromRelay(
            relay: relay,
            countResponse: countResponse,
          );
        } else {
          utils.log(
            'received unknown message from relay: $relay, message: $d',
          );
        }
      },
      onError: (error) {
        if (retryOnError) {
          _reconnectToRelay(
            relay: relay,
            onRelayListening: onRelayListening,
            onRelayConnectionError: onRelayConnectionError,
            onRelayConnectionDone: onRelayConnectionDone,
            retryOnError: retryOnError,
            retryOnClose: retryOnClose,
            shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
            connectionTimeout: connectionTimeout,
            ignoreConnectionException: ignoreConnectionException,
            lazyListeningToRelays: lazyListeningToRelays,
          );
        }

        if (onRelayConnectionError != null) {
          onRelayConnectionError(relay, error, relayWebSocket);
        }

        utils.log(
          'web socket of relay with $relay had an error: $error',
          error,
        );
      },
      onDone: () {
        if (retryOnClose) {
          _reconnectToRelay(
            relay: relay,
            onRelayListening: onRelayListening,
            onRelayConnectionError: onRelayConnectionError,
            onRelayConnectionDone: onRelayConnectionDone,
            retryOnError: retryOnError,
            retryOnClose: retryOnClose,
            shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
            connectionTimeout: connectionTimeout,
            ignoreConnectionException: ignoreConnectionException,
            lazyListeningToRelays: lazyListeningToRelays,
          );
        }

        if (onRelayConnectionDone != null) {
          onRelayConnectionDone(relay, relayWebSocket);
        }
      },
    );
  }

  /// Attempts to reconnect to all registered relays.
  ///
  /// This method initiates reconnection to all registered relays, handling connection errors and closures.
  ///
  /// Example:
  /// ```dart
  /// await NWC.instance.relays.reconnectToRelays(
  ///   onRelayListening: (relayUrl, receivedData, relayWebSocket) {
  ///     print("Received data: $receivedData from relay with URL: $relayUrl");
  ///   },
  ///   onRelayConnectionError: (relayUrl, error, relayWebSocket) {
  ///     print("Relay with URL: $relayUrl has encountered an error: $error");
  ///   },
  ///   onRelayConnectionDone: (relayUrl, relayWebSocket) {
  ///     print("Relay with URL: $relayUrl connection closed");
  ///   },
  ///   retryOnError: true,
  ///   retryOnClose: true,
  ///   shouldReconnectToRelayOnNotice: true,
  ///   connectionTimeout: Duration(seconds: 10),
  ///   ignoreConnectionException: false,
  ///   lazyListeningToRelays: true,
  /// );
  /// ```
  @override
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
  }) async {
    final completer = Completer();

    if (relaysList == null || relaysList!.isEmpty) {
      throw Exception(
        'you need to call the init method before calling this method.',
      );
    }

    for (final relay in relaysList!) {
      await _reconnectToRelay(
        relayUnregistered: relayUnregistered,
        relay: relay,
        onRelayListening: onRelayListening,
        onRelayConnectionError: onRelayConnectionError,
        onRelayConnectionDone: onRelayConnectionDone,
        retryOnError: retryOnError,
        retryOnClose: retryOnClose,
        shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
        connectionTimeout: connectionTimeout,
        ignoreConnectionException: ignoreConnectionException,
        lazyListeningToRelays: lazyListeningToRelays,
      );
    }

    completer.complete();

    return completer.future;
  }

  Future<bool> disconnectFromRelays({
    int Function(String relayUrl)? closeCode,
    String Function(String relayUrl)? closeReason,
    void Function(
      String relayUrl,
      WebSocketChannel relayWebSOcket,
      dynamic webSocketDisconnectionMessage,
    )? onRelayDisconnect,
  }) async {
    final webSockets = nostrRegistry.relaysWebSocketsRegistry;
    for (var index = 0; index < webSockets.length; index++) {
      final current = webSockets.entries.elementAt(index);
      final relayUrl = current.key;
      final relayWebSocket = current.value;

      final returnedMessage = await relayWebSocket.sink.close(
        closeCode?.call(relayUrl),
        closeReason?.call(relayUrl),
      );

      onRelayDisconnect?.call(relayUrl, relayWebSocket, returnedMessage);
    }

    nostrRegistry.clearWebSocketsRegistry();
    relaysList = [];

    return true;
  }

  /// Frees all allocated resources and disconnects from relays.
  ///
  /// This method disconnects from all registered relays, closes streams controllers, and clears all registries.
  ///
  /// Parameters:
  /// - [throwOnFailure]: Specifies whether to throw an exception if resource deallocation fails. Default is `false`.
  ///
  /// Returns `true` if resources are deallocated successfully, otherwise `false`.
  ///
  /// Example:
  /// ```dart
  /// bool deallocationSuccess = await NWC.instance.relays.freeAllResources();
  /// ```
  @override
  Future<bool> freeAllResources([bool throwOnFailure = false]) async {
    try {
      await disconnectFromRelays();
      await streamsController.close();

      nostrRegistry.clearAllRegistries();

      return true;
    } catch (e) {
      if (throwOnFailure) {
        rethrow;
      }

      return false;
    }
  }

  Future<void> _reconnectToRelay({
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
    bool relayUnregistered = true,
  }) async {
    utils.log('retrying to listen to relay with url: $relay...');

    if (relayUnregistered) {
      await _startConnectingAndRegisteringRelay(
        relayUrl: relay,
        onRelayListening: onRelayListening,
        onRelayConnectionError: onRelayConnectionError,
        onRelayConnectionDone: onRelayConnectionDone,
        retryOnError: retryOnError,
        retryOnClose: retryOnClose,
        shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
        connectionTimeout: connectionTimeout,
        ignoreConnectionException: ignoreConnectionException,
        lazyListeningToRelays: lazyListeningToRelays,
      );
    }
  }

  Future<void> _startConnectingAndRegisteringRelay({
    required String relayUrl,
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
    required bool lazyListeningToRelays,
    required bool retryOnError,
    required bool retryOnClose,
    required bool ignoreConnectionException,
    required bool shouldReconnectToRelayOnNotice,
    required Duration connectionTimeout,
  }) {
    return _startConnectingAndRegisteringRelays(
      relaysUrl: [relayUrl],
      onRelayListening: onRelayListening,
      onRelayConnectionError: onRelayConnectionError,
      onRelayConnectionDone: onRelayConnectionDone,
      lazyListeningToRelays: lazyListeningToRelays,
      retryOnError: retryOnError,
      retryOnClose: retryOnClose,
      ignoreConnectionException: ignoreConnectionException,
      shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
      connectionTimeout: connectionTimeout,
    );
  }

  Future<void> _startConnectingAndRegisteringRelays({
    required List<String> relaysUrl,
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
    required bool lazyListeningToRelays,
    required bool retryOnError,
    required bool retryOnClose,
    required bool ignoreConnectionException,
    required bool shouldReconnectToRelayOnNotice,
    required Duration connectionTimeout,
  }) async {
    final completer = Completer();

    for (final relay in relaysUrl) {
      try {
        await webSocketsService.connectRelay(
          relay: relay,
          onConnectionSuccess: (relayWebSocket) {
            nostrRegistry.registerRelayWebSocket(
              relayUrl: relay,
              webSocket: relayWebSocket,
            );
            utils.log(
              'the websocket for the relay with url: $relay, is registered.',
            );
            utils.log(
              'listening to the websocket for the relay with url: $relay...',
            );

            if (!lazyListeningToRelays) {
              startListeningToRelay(
                relay: relay,
                onRelayListening: onRelayListening,
                onRelayConnectionError: onRelayConnectionError,
                onRelayConnectionDone: onRelayConnectionDone,
                retryOnError: retryOnError,
                retryOnClose: retryOnClose,
                shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
                connectionTimeout: connectionTimeout,
                ignoreConnectionException: ignoreConnectionException,
                lazyListeningToRelays: lazyListeningToRelays,
              );
            }
          },
        );
      } catch (e) {
        onRelayConnectionError?.call(relay, e, null);
      }
    }

    completer.complete();

    return completer.future;
  }

  bool _filterNostrEventsWithId(
    Event event,
    String? requestSubId,
  ) {
    final eventSubId = event.subscriptionId;

    return eventSubId == requestSubId;
  }

  void _handleAddingEventToSink({
    required String? relay,
    required Event event,
  }) {
    utils.log(
      'received event with content: ${event.content} from relay: $relay',
    );

    if (!nostrRegistry.isEventRegistered(event)) {
      if (streamsController.isClosed) {
        utils.log(
          'streams controller is closed, event with id: ${event.id} will be ignored and not added to the sink.',
        );

        return;
      }

      streamsController.eventsController.sink.add(event);
      nostrRegistry.registerEvent(event);
    }
  }

  void _handleNoticeFromRelay({
    required Notice notice,
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
  }) {
    utils.log(
      'received notice with message: ${notice.message} from relay: $relay',
    );

    if (nostrRegistry.isRelayRegistered(relay)) {
      final registeredRelay = nostrRegistry.getRelayWebSocket(relayUrl: relay);

      registeredRelay?.sink.close().then((value) {
        final relayUnregistered = nostrRegistry.unregisterRelay(relay);

        _reconnectToRelay(
          relayUnregistered: relayUnregistered,
          relay: relay,
          onRelayListening: onRelayListening,
          onRelayConnectionError: onRelayConnectionError,
          onRelayConnectionDone: onRelayConnectionDone,
          retryOnError: retryOnError,
          retryOnClose: retryOnClose,
          shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice,
          connectionTimeout: connectionTimeout,
          ignoreConnectionException: ignoreConnectionException,
          lazyListeningToRelays: lazyListeningToRelays,
        );
      });
    }
  }

  void _registerOnOklCallBack({
    required String associatedEventId,
    required void Function(String relay, EventOk ok) onOk,
    required String relay,
  }) {
    nostrRegistry.registerOkCommandCallBack(
      associatedEventId: associatedEventId,
      onOk: onOk,
      relay: relay,
    );
  }

  void _handleOkCommandMessageFromRelay({
    required EventOk okCommand,
    required String relay,
  }) {
    final okCallBack = nostrRegistry.getOkCommandCallBack(
      associatedEventIdWithOkCommand: okCommand.eventId,
      relay: relay,
    );

    okCallBack?.call(relay, okCommand);
  }

  void _registerOnEoselCallBack({
    required String subscriptionId,
    required void Function(String relay, EventEose eose) onEose,
    required String relay,
  }) {
    nostrRegistry.registerEoseCommandCallBack(
      subscriptionId: subscriptionId,
      onEose: onEose,
      relay: relay,
    );
  }

  void _handleEoseCommandMessageFromRelay({
    required EventEose eoseCommand,
    required String relay,
  }) {
    final eoseCallBack = nostrRegistry.getEoseCommandCallBack(
      subscriptionId: eoseCommand.subscriptionId,
      relay: relay,
    );

    eoseCallBack?.call(relay, eoseCommand);
  }

  void _handleCountResponseMessageFromRelay({
    required CountResponse countResponse,
    required String relay,
  }) {
    final countCallBack = nostrRegistry.getCountResponseCallBack(
      subscriptionId: countResponse.subscriptionId,
      relay: relay,
    );

    countCallBack?.call(
      relay,
      countResponse,
    );
  }

  void _runFunctionOverRelationIteration(
    void Function(NostrRelay) relayCallback,
  ) {
    final entries = nostrRegistry.allRelaysEntries();

    for (var index = 0; index < entries.length; index++) {
      final current = entries[index];
      final relay = NostrRelay(
        url: current.key,
        socket: current.value,
      );

      relayCallback.call(relay);
    }
  }

  void _clearRegistriesIf(bool ensureToClearRegistriesBeforeStarting) {
    if (ensureToClearRegistriesBeforeStarting) {
      nostrRegistry.clearAllRegistries();
    }
  }
}
