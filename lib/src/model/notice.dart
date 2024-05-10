import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/src/utils/event_types.dart';

class Notice extends Equatable {
  final String message;

  const Notice({
    required this.message,
  });

  static bool canBeDeserialized(String dataFromRelay) {
    final decoded = jsonDecode(dataFromRelay) as List;

    return decoded.first == EventTypes.notice;
  }

  static Notice fromRelayMessage(String data) {
    assert(canBeDeserialized(data));

    final decoded = jsonDecode(data) as List;
    assert(decoded.first == EventTypes.notice);
    final message = decoded[1] as String;

    return Notice(message: message);
  }

  @override
  List<Object?> get props => [message];
}
