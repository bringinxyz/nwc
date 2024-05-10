// ignore_for_file: constant_identifier_names

import 'package:nwc/src/base/nip47/nip47_result_deserializer.dart';
import 'package:nwc/src/model/nosrt_wallet_connect_uri.dart';

import '../../utils/nwc_logger.dart';
import 'nip47_base.dart';

/// Implementation of the [NIP47] protocol for parsing Nostr Wallet Connect URIs and response result deserialization.
class Nip47 extends Nip47Base {
  Nip47({required this.utils});

  /// Instance of [NWCLoggerUtils] used for logging and utility operations.
  final NWCLoggerUtils utils;

  /// Parses a Nostr Wallet Connect URI.
  ///
  /// Parses the [connectionUri] string and returns a [NostrWalletConnectUri] object representing the parsed URI.
  ///
  /// Returns the parsed Nostr Wallet Connect URI.
  @override
  NostrWalletConnectUri parseNostrConnectUri(String connectionUri) {
    final result = NostrWalletConnectUri.parseConnectionUri(connectionUri);
    return result;
  }

  /// Parses the response result from NIP47.
  ///
  /// Deserializes the [content] string and returns a [Nip47ResultDeserializer] object representing the parsed result.
  ///
  /// Returns the parsed response result.
  @override
  Nip47ResultDeserializer parseResponseResult(String content) {
    final result = Nip47ResultDeserializer.deserialize(content);
    return result;
  }
}
