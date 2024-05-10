import 'package:meta/meta.dart';
import 'package:nwc/src/model/count.dart';
import 'package:nwc/src/model/event.dart';
import 'package:nwc/src/model/event_eose.dart';
import 'package:nwc/src/model/event_ok.dart';
import 'package:nwc/src/utils/exceptions.dart';
import 'package:nwc/src/utils/nwc_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef SubscriptionCallback<T>
    = Map<String, void Function(String relay, T callback)>;

typedef RelayCallbackRegister<T> = Map<String, SubscriptionCallback<T>>;

/// This is responsible for registering and retrieving relays [WebSocket]s that are connected to the app.
@protected
class Registry {
  Registry({required this.utils});
  final NWCLoggerUtils utils;

  /// This is the registry which will have all relays [WebSocket]s.
  final relaysWebSocketsRegistry = <String, WebSocketChannel>{};

  ///  This is the registry which will have all events.
  final eventsRegistry = <String, Event>{};

  /// This is the registry which will have all ok commands callbacks.
  final okCommandCallBacks = RelayCallbackRegister<EventOk>();

  /// This is the registry which will have all eose responses callbacks.
  final eoseCommandCallBacks = RelayCallbackRegister<EventEose>();

  /// This is the registry which will have all count responses callbacks.
  final countResponseCallBacks = RelayCallbackRegister<CountResponse>();

  /// Registers a [WebSocket] to the registry with the given [relayUrl].
  /// If a [WebSocket] is already registered with the given [relayUrl], it will be replaced.
  WebSocketChannel registerRelayWebSocket({
    required String relayUrl,
    required WebSocketChannel webSocket,
  }) {
    relaysWebSocketsRegistry[relayUrl] = webSocket;
    return relaysWebSocketsRegistry[relayUrl]!;
  }

  /// Returns the [WebSocket] registered with the given [relayUrl].
  WebSocketChannel? getRelayWebSocket({
    required String relayUrl,
  }) {
    final targetWebSocket = relaysWebSocketsRegistry[relayUrl];

    if (targetWebSocket != null) {
      final relay = targetWebSocket;

      return relay;
    } else {
      utils.log(
        'No relay is registered with the given url: $relayUrl, did you forget to register it?',
      );

      throw RelayNotFoundException(relayUrl);
    }
  }

  /// Returns all [WebSocket]s registered in the registry.
  List<MapEntry<String, WebSocketChannel>> allRelaysEntries() {
    return relaysWebSocketsRegistry.entries.toList();
  }

  /// Clears all registries.
  void clearAllRegistries() {
    relaysWebSocketsRegistry.clear();
    eventsRegistry.clear();
    okCommandCallBacks.clear();
    eoseCommandCallBacks.clear();
    countResponseCallBacks.clear();
  }

  /// Wether a [WebSocket] is registered with the given [relayUrl].
  bool isRelayRegistered(String relayUrl) {
    return relaysWebSocketsRegistry.containsKey(relayUrl);
  }

  /// Wether an event is registered with the given [event].
  bool isEventRegistered(Event event) {
    return eventsRegistry.containsKey(eventUniqueId(event));
  }

  /// Registers an event to the registry with the given [event].
  Event registerEvent(Event event) {
    eventsRegistry[eventUniqueId(event)] = event;

    return eventsRegistry[eventUniqueId(event)]!;
  }

  /// REturns an [event] unique id, See also [NostrEvent.uniqueKey].
  String eventUniqueId(Event event) {
    return event.uniqueKey().toString();
  }

  /// Removes an event from the registry with the given [event].
  bool unregisterRelay(String relay) {
    final isUnregistered = relaysWebSocketsRegistry.remove(relay) != null;

    return isUnregistered;
  }

  /// Registers an ok command callback to the registry with the given [associatedEventId].
  void registerOkCommandCallBack({
    required String associatedEventId,
    required void Function(String relay, EventOk ok) onOk,
    required String relay,
  }) {
    final relayOkRegister = getOrCreateRegister(okCommandCallBacks, relay);

    relayOkRegister[associatedEventId] = onOk;
  }

  /// Returns an ok command callback from the registry with the given [associatedEventId].
  void Function(
    String relay,
    EventOk ok,
  )? getOkCommandCallBack({
    required String associatedEventIdWithOkCommand,
    required String relay,
  }) {
    final relayOkRegister = getOrCreateRegister(okCommandCallBacks, relay);

    return relayOkRegister[associatedEventIdWithOkCommand];
  }

  /// Registers an eose command callback to the registry with the given [subscriptionId].
  void registerEoseCommandCallBack({
    required String subscriptionId,
    required void Function(String relay, EventEose eose) onEose,
    required String relay,
  }) {
    final relayEoseRegister = getOrCreateRegister(eoseCommandCallBacks, relay);

    relayEoseRegister[subscriptionId] = onEose;
  }

  /// Returns an eose command callback from the registry with the given [subscriptionId].
  void Function(
    String relay,
    EventEose eose,
  )? getEoseCommandCallBack({
    required String subscriptionId,
    required String relay,
  }) {
    final relayEoseRegister = getOrCreateRegister(eoseCommandCallBacks, relay);

    return relayEoseRegister[subscriptionId];
  }

  /// Registers a count response callback to the registry with the given [subscriptionId].
  void registerCountResponseCallBack({
    required String subscriptionId,
    required void Function(String relay, CountResponse countResponse)
        onCountResponse,
    required String relay,
  }) {
    final relayCountRegister = countResponseCallBacks[subscriptionId];

    relayCountRegister?[subscriptionId] = onCountResponse;
  }

  /// Returns a count response callback from the registry with the given [subscriptionId].
  void Function(
    String relay,
    CountResponse countResponse,
  )? getCountResponseCallBack({
    required String subscriptionId,
    required String relay,
  }) {
    final relayCountRegister =
        getOrCreateRegister(countResponseCallBacks, relay);

    return relayCountRegister[subscriptionId];
  }

  /// Clears the events registry.
  void clearWebSocketsRegistry() {
    relaysWebSocketsRegistry.clear();
  }

  SubscriptionCallback<T> getOrCreateRegister<T>(
    RelayCallbackRegister<T> register,
    String relay,
  ) {
    final relayRegister = register[relay];

    if (relayRegister == null) {
      register[relay] = <String, void Function(String relay, T callback)>{};
    }

    return register[relay]!;
  }
}
