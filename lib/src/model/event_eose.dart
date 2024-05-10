import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/src/utils/event_types.dart';

class EventEose extends Equatable {
  final String subscriptionId;

  const EventEose({
    required this.subscriptionId,
  });

  static bool canBeDeserialized(String dataFromRelay) {
    final decoded = jsonDecode(dataFromRelay) as List;

    return decoded.first == EventTypes.eose;
  }

  static EventEose fromRelayMessage(String dataFromRelay) {
    assert(canBeDeserialized(dataFromRelay));

    final decoded = jsonDecode(dataFromRelay) as List;

    return EventEose(
      subscriptionId: decoded[1] as String,
    );
  }

  @override
  List<Object?> get props => [
        subscriptionId,
      ];
}
