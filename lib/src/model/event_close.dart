import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/src/utils/event_types.dart';

class EventClose extends Equatable {
  const EventClose({
    required this.subscriptionId,
  });

  final String subscriptionId;

  String serialized() {
    return jsonEncode([EventTypes.close, subscriptionId]);
  }

  @override
  List<Object?> get props => [subscriptionId];
}
