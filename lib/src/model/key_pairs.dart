import 'package:bip340/bip340.dart' as bip340;
import 'package:equatable/equatable.dart';
import 'package:nwc/nwc.dart';

/// This class is responsible for generating, handling and signing keys.
/// It is used by the [NostrClient] to sign messages.
class KeyPairs extends Equatable {
  factory KeyPairs({
    required String private,
  }) {
    return KeyPairs._(private: private);
  }

  KeyPairs._({required this.private}) {
    assert(
      private.length == 64,
      '[!] Private key should be 64 chars length (32 bytes hex encoded)',
    );

    public = bip340.getPublicKey(private);
  }

  /// Instantiate a [NostrKeyPairs] from random bytes.
  factory KeyPairs.generate() {
    return KeyPairs(
      private: NWC.instance.generalService.random64HexChars(),
    );
  }

  /// This is the private generate Key, hex-encoded (64 chars)
  final String private;

  /// This is the public generate Key, hex-encoded (64 chars)
  late final String public;

  /// This will sign a [message] with the [private] key and return the signature.
  String sign(String message) {
    final aux = NWC.instance.generalService.random64HexChars();
    return bip340.sign(private, message, aux);
  }

  /// This will verify a [signature] for a [message] with the [public] key.
  static bool verify(
    String pubkey,
    String message,
    String signature,
  ) {
    return bip340.verify(pubkey, message, signature);
  }

  static bool isValidPrivateKey(String privateKey) {
    try {
      KeyPairs(private: privateKey);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  List<Object?> get props => [private, public];
}
