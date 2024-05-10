import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:nwc/src/model/event_key.dart';
import 'package:nwc/src/model/key_pairs.dart';
import 'package:nwc/src/utils/event_types.dart';

class Event extends Equatable {
  const Event({
    required this.content,
    required this.createdAt,
    required this.id,
    required this.kind,
    required this.pubkey,
    required this.sig,
    required this.tags,
    this.subscriptionId,
  });

  /// The id of the event.
  final String? id;

  /// The kind of the event.
  final int? kind;

  /// The content of the event.
  final String? content;

  /// The signature of the event.
  final String? sig;

  /// The public key of the event creator.
  final String pubkey;

  /// The creation date of the event.
  final DateTime? createdAt;

  /// The tags of the event.
  final List<List<String>>? tags;

  /// The subscription id of the event
  /// This is meant for events that are got from the relays, and not for events that are created by you.
  final String? subscriptionId;

  /// This represents a nostr event that is received from the relays,
  /// it takes directly the relay message which is serialized, and handles all internally
  factory Event.deserialized(String data) {
    assert(Event.canBeDeserialized(data));
    final decoded = jsonDecode(data) as List;

    final event = decoded.last as Map<String, dynamic>;
    return Event(
      id: event['id'] as String,
      kind: event['kind'] as int,
      content: event['content'] as String,
      sig: event['sig'] as String,
      pubkey: event['pubkey'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (event['created_at'] as int) * 1000,
      ),
      tags: List<List<String>>.from(
        (event['tags'] as List)
            .map(
              (nestedElem) => (nestedElem as List)
                  .map(
                    (nestedElemContent) => nestedElemContent.toString(),
                  )
                  .toList(),
            )
            .toList(),
      ),
      subscriptionId: decoded[1] as String?,
    );
  }

  /// Wether the given [dataFromRelay] can be deserialized into a [NostrEvent].
  static bool canBeDeserialized(String dataFromRelay) {
    final decoded = jsonDecode(dataFromRelay) as List;

    return decoded.first == EventTypes.event;
  }

  /// Creates the [id] of an event, based on Nostr specs.
  static String getEventId({
    required int kind,
    required String content,
    required DateTime createdAt,
    required List tags,
    required String pubkey,
  }) {
    final data = [
      0,
      pubkey,
      createdAt.millisecondsSinceEpoch ~/ 1000,
      kind,
      tags,
      content,
    ];

    final serializedEvent = jsonEncode(data);
    final bytes = utf8.encode(serializedEvent);
    final digest = sha256.convert(bytes);
    final id = hex.encode(digest.bytes);

    return id;
  }

  static Event fromPartialData({
    required int kind,
    required String content,
    required KeyPairs keyPairs,
    List<List<String>>? tags,
    DateTime? createdAt,
    String? ots,
  }) {
    final pubkey = keyPairs.public;
    final tagsToUse = tags ?? [];
    final createdAtToUse = createdAt ?? DateTime.now();

    final id = Event.getEventId(
      kind: kind,
      content: content,
      createdAt: createdAtToUse,
      tags: tagsToUse,
      pubkey: pubkey,
    );

    final sig = keyPairs.sign(id);

    return Event(
      id: id,
      kind: kind,
      content: content,
      sig: sig,
      pubkey: pubkey,
      createdAt: createdAtToUse,
      tags: tagsToUse,
    );
  }

  /// Creates a new [NostrEvent] with the given [content].
  static Event deleteEvent({
    required KeyPairs keyPairs,
    required List<String> eventIdsToBeDeleted,
    String reasonOfDeletion = '',
    DateTime? createdAt,
  }) {
    return fromPartialData(
      kind: 5,
      content: reasonOfDeletion,
      keyPairs: keyPairs,
      tags: eventIdsToBeDeleted.map((eventId) => ['e', eventId]).toList(),
      createdAt: createdAt,
    );
  }

  /// Returns a unique tag for this event that you can use to identify it.
  EventKey uniqueKey() {
    if (subscriptionId == null) {
      throw Exception(
        "You can't get a unique key for an event that you created, you can only get a unique key for an event that you got from the relays",
      );
    }

    if (id == null) {
      throw Exception(
        "You can't get a unique key for an event that you created, you can only get a unique key for an event that you got from the relays",
      );
    }

    return EventKey(
      eventId: id!,
      sourceSubscriptionId: subscriptionId!,
      originalSourceEvent: this,
    );
  }

  /// Returns a serialized [NostrEvent] from this event.
  String serialized() {
    return jsonEncode([EventTypes.event, toMap()]);
  }

  /// Returns a map representation of this event.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      'pubkey': pubkey,
      if (content != null) 'content': content,
      if (sig != null) 'sig': sig,
      if (createdAt != null)
        'created_at': createdAt!.millisecondsSinceEpoch ~/ 1000,
      if (tags != null)
        'tags': tags!.map((tag) => tag.map((e) => e).toList()).toList(),
    };
  }

  bool isVerified() {
    if (id == null || sig == null) {
      return false;
    }

    return KeyPairs.verify(
      pubkey,
      id!,
      sig!,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        content,
        sig,
        pubkey,
        createdAt,
        tags,
        subscriptionId,
      ];
}
