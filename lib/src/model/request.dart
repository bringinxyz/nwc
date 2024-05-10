import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/nwc.dart';
import 'package:nwc/src/utils/event_types.dart';

/// Request is a request to subscribe to a set of events that match a set of filters with a given [subscriptionId].

// ignore: must_be_immutable
class Request extends Equatable {
  /// The subscription ID of the request.
  String? subscriptionId;

  /// A list of filters that the request will match.
  final List<Filter> filters;

  Request({
    required this.filters,
    this.subscriptionId,
  });

  /// Serialize the request to send it to the remote relays websockets.
  String serialized({String? subscriptionId}) {
    this.subscriptionId = subscriptionId ??
        this.subscriptionId ??
        NWC.instance.generalService.consistent64HexChars(
          filters
              .map((e) => e.toMap().toString())
              .reduce((value, element) => value + element),
        );

    final encodedReq = jsonEncode([
      EventTypes.request,
      subscriptionId,
      ...filters.map((e) => e.toMap()),
    ]);

    return encodedReq;
  }

  /// Deserialize a request
  factory Request.deserialized(input) {
    final haveThreeElements = input is List && input.length >= 3;

    assert(
      haveThreeElements,
      'Invalid request, must have at least 3 elements',
    );

    assert(
      input[0] == EventTypes.request,
      'Invalid request, must start with ${EventTypes.request}',
    );

    final subscriptionId = input[1] as String;

    return Request(
      subscriptionId: subscriptionId,
      filters: List.generate(
        input.length - 2,
        (index) => Filter.fromJson(
          input[index + 2],
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [subscriptionId, filters];

  Request copyWith({
    String? subscriptionId,
    List<Filter>? filters,
  }) {
    return Request(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      filters: filters ?? this.filters,
    );
  }
}
