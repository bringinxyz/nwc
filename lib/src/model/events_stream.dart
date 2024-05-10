import 'package:equatable/equatable.dart';
import 'package:nwc/nwc.dart';

class EventsStream extends Equatable {
  const EventsStream({
    required this.stream,
    required this.subscriptionId,
    required this.request,
  });

  /// This the stream of nostr events that you can listen to and get the events.
  final Stream<Event> stream;

  /// This is the subscription id of the stream. You can use this to unsubscribe from the stream.
  final String subscriptionId;

  final Request request;

  void close() {
    return NWC.instance.relaysService.closeEventsSubscription(subscriptionId);
  }

  @override
  List<Object?> get props => [stream, subscriptionId, request];
}
