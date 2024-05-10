import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/src/utils/event_types.dart';

class EventOk extends Equatable {
  const EventOk({
    required this.eventId,
    this.isEventAccepted,
    this.message,
  });

  final String eventId;

  final bool? isEventAccepted;

  final String? message;

  static bool canBeDeserialized(String dataFromRelay) {
    final decoded = jsonDecode(dataFromRelay) as List;

    return decoded.first == EventTypes.ok;
  }

  static EventOk fromRelayMessage(String data) {
    assert(canBeDeserialized(data));

    final decoded = jsonDecode(data) as List;
    final eventId = decoded[1] as String;
    final isEventAccepted = decoded.length > 2 ? decoded[2] as bool : null;
    final message = decoded.length > 3 ? decoded[3] as String : null;

    return EventOk(
      eventId: eventId,
      isEventAccepted: isEventAccepted,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        isEventAccepted,
        message,
      ];
}
