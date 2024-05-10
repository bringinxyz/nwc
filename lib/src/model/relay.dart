// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A representation of a relay, it contains the [WebSocket] connection to the relay and the [url] of the relay.
class NostrRelay extends Equatable {
  /// The [WebSocketChannel] connection to the relay.
  final WebSocketChannel socket;

  /// The url of the relay.
  final String url;

  const NostrRelay({
    required this.socket,
    required this.url,
  });

  @override
  List<Object?> get props => [socket, url];
}
