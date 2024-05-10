import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/nwc.dart';
import 'package:nwc/src/utils/event_types.dart';

class CountEvent extends Equatable {
  const CountEvent({
    required this.eventsFilter,
    required this.subscriptionId,
  });

  final Filter eventsFilter;
  final String subscriptionId;

  static CountEvent fromPartialData({
    required Filter eventsFilter,
  }) {
    final createdSubscriptionId =
        NWC.instance.generalService.consistent64HexChars(
      eventsFilter.toMap().toString(),
    );

    return CountEvent(
      eventsFilter: eventsFilter,
      subscriptionId: createdSubscriptionId,
    );
  }

  String serialized() {
    return jsonEncode([
      EventTypes.count,
      subscriptionId,
      eventsFilter.toMap(),
    ]);
  }

  @override
  List<Object?> get props => [
        eventsFilter,
        subscriptionId,
      ];
}

class CountResponse extends Equatable {
  const CountResponse({
    required this.subscriptionId,
    required this.count,
  });

  final String subscriptionId;
  final int count;

  factory CountResponse.deserialized(String data) {
    final decodedData = jsonDecode(data);
    assert(decodedData is List);

    final countMap = decodedData[2];
    assert(countMap is Map);

    return CountResponse(
      subscriptionId: decodedData[1] as String,
      count: int.parse(countMap['count'] as String),
    );
  }

  static bool canBeDeserialized(String data) {
    final decodedData = jsonDecode(data);

    assert(decodedData is List);

    if (decodedData[0] != EventTypes.count) {
      return false;
    }

    final countMap = decodedData[2];
    if (countMap is Map<String, dynamic>) {
      return countMap
          .map((key, value) => MapEntry(key.toUpperCase(), value))
          .containsKey(EventTypes.count);
    } else {
      return false;
    }
  }

  @override
  List<Object?> get props => throw UnimplementedError();
}
