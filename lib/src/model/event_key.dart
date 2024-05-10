import 'package:equatable/equatable.dart';
import 'package:nwc/src/model/event.dart';

class EventKey extends Equatable {
  const EventKey({
    required this.eventId,
    required this.sourceSubscriptionId,
    required this.originalSourceEvent,
  });

  final String eventId;

  final String sourceSubscriptionId;

  final Event originalSourceEvent;

  @override
  List<Object?> get props => [
        eventId,
        sourceSubscriptionId,
        originalSourceEvent,
      ];

  @override
  String toString() {
    return 'EventKey{eventId: $eventId, sourceSubscriptionId: $sourceSubscriptionId, originalSourceEvent: $originalSourceEvent}';
  }
}
