import 'package:nwc/nwc.dart';

import 'keys_base.dart';

/// This class is responsible for generating key pairs and deriving public keys from private keys.
class Keys extends KeysBase {
  Keys({
    required this.utils,
  });

  final NWCLoggerUtils utils;

  /// A caching system for the key pairs, so we don't have to generate them again.
  /// A cache key is the private key, and the value is the [KeyPairs] instance.
  static final _keyPairsCache = <String, KeyPairs>{};

  /// Derives a public key from a given [privateKey].
  ///
  /// This method generates a public key from the provided [privateKey].
  ///
  /// Example:
  ///
  /// ```dart
  /// final publicKey = Nwc.instance.keysService.derivePublicKey(privateKey: yourPrivateKey);
  /// print(publicKey);
  /// ```
  ///
  /// Returns the derived public key corresponding to the input private key.
  @override
  String derivePublicKey({required String privateKey}) {
    final nostrKeyPairs = _keyPairFrom(privateKey);

    utils.log(
      "derived public key from private key, with it's value is: ${nostrKeyPairs.public}",
    );

    return nostrKeyPairs.public;
  }

  /// Generates a key pair for end users.
  ///
  /// This method generates a key pair consisting of a public key and a private key.
  ///
  /// Example:
  ///
  /// ```dart
  /// final keyPair = NWC.instance.keysService.generateKeyPair();
  /// print(keyPair.public);
  /// print(keyPair.private);
  /// ```
  ///
  /// Returns a [KeyPairs] object containing the generated key pair.
  @override
  KeyPairs generateKeyPair() {
    final nostrKeyPairs = _generateKeyPair();

    utils.log(
      "generated key pairs, with it's public key is: ${nostrKeyPairs.public}",
    );

    return nostrKeyPairs;
  }

  /// Generates a key pair from an existing [privateKey].
  ///
  /// Use this method to generate a key pair from a provided private key.
  ///
  /// Example:
  ///
  /// ```dart
  /// final keyPair = NWC.instance.keysService.generateKeyPairFromExistingPrivateKey(yourPrivateKey);
  /// print(keyPair.public);
  /// print(keyPair.private);
  /// ```
  ///
  /// Returns a [KeyPairs] object containing the generated key pair.
  @override
  KeyPairs generateKeyPairFromExistingPrivateKey(
    String privateKey,
  ) {
    return _keyPairFrom(privateKey);
  }

  /// Generates a private key for end users.
  ///
  /// Use this method to generate a private key.
  ///
  /// Example:
  ///
  /// ```dart
  /// final privateKey = NWC.instance.keysService.generatePrivateKey();
  /// print(privateKey);
  /// ```
  ///
  /// Returns the generated private key as a string.
  @override
  String generatePrivateKey() {
    return _generateKeyPair().private;
  }

  /// Signs a [message] with a specified [privateKey].
  ///
  /// Use this method to generate a signature for a message using a private key.
  ///
  /// Example:
  ///
  /// ```dart
  /// final signature = NWC.instance.keysService.sign(
  ///   privateKey: yourPrivateKey,
  ///   message: yourMessage,
  /// );
  ///
  /// print(signature);
  /// ```
  ///
  /// Returns the signature of the message.
  @override
  String sign({
    required String privateKey,
    required String message,
  }) {
    final nostrKeyPairs = _keyPairFrom(privateKey);

    final hexEncodedMessage =
        NWC.instance.generalService.hexEncodeString(message);

    final signature = nostrKeyPairs.sign(hexEncodedMessage);

    utils.log(
      "[+] signed message with private key, with it's value is: $signature",
    );

    return signature;
  }

  /// Clears all cached key pairs.
  ///
  /// Use this method to clear the cache of previously generated key pairs.
  ///
  /// Example:
  ///
  /// ```dart
  /// NWC.instance.keysService.freeAllResources();
  /// ```
  ///
  /// Returns `true` if the operation is successful.
  bool freeAllResources() {
    _keyPairsCache.clear();
    return true;
  }

  KeyPairs _keyPairFrom(String privateKey) {
    if (_keyPairsCache.containsKey(privateKey)) {
      return _keyPairsCache[privateKey]!;
    } else {
      _keyPairsCache[privateKey] = KeyPairs(private: privateKey);

      return _keyPairsCache[privateKey]!;
    }
  }

  KeyPairs _generateKeyPair() {
    final keyPair = KeyPairs.generate();
    _keyPairsCache[keyPair.private] = keyPair;

    return keyPair;
  }
}
