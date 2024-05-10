import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../utils/exceptions.dart';
import '../../utils/nwc_logger.dart';
import 'kepler.dart';
import 'nip04_base.dart';

/// Implementation of the [NIP04] protocol for encryption and decryption of content.
class Nip04 extends Nip04Base {
  Nip04({required this.utils});

  /// Instance of [NWCLoggerUtils] used for logging and utility operations.
  final NWCLoggerUtils utils;

  /// Encrypts a message using the NIP04 protocol.
  ///
  /// Encrypts the [message] using the sender's private key [senderPrivkey]
  /// and the receiver's public key [receiverPubkey].
  ///
  /// Returns the encrypted content.
  @override
  String encrypt(
    String senderPrivkey,
    String receiverPubkey,
    String message,
  ) {
    final content = _nip4cipher(
      senderPrivkey,
      '02$receiverPubkey',
      message,
      true,
    );
    return content;
  }

  /// Decrypts an encrypted content using the [NIP04] protocol.
  ///
  /// Decrypts the [content] using the sender's private key [senderPrivkey]
  /// and the receiver's public key [receiverPubkey].
  ///
  /// Throws a [DecipherFailedException] if decryption fails.
  ///
  /// Returns the decrypted message.
  @override
  String decrypt(
    String senderPrivkey,
    String receiverPubkey,
    String content,
  ) {
    String ciphertext = content.split("?iv=")[0];
    String plaintext;

    try {
      plaintext = _nip4cipher(
        senderPrivkey,
        "02$receiverPubkey",
        ciphertext,
        false,
        nonce: _findNonce(content),
      );
    } catch (e) {
      throw DecipherFailedException('Failed to decipher: $e');
    }
    return plaintext;
  }

  /// parse the ciphered content to return the nonce/IV
  String _findNonce(String content) {
    List<String> split = content.split("?iv=");
    if (split.length != 2) {
      throw Exception("[!] invalid content or non ciphered");
    }
    return split[1];
  }

  /// generates the requested quantity of random secure bytes
  List<int> generateRandomBytes(int quantity) {
    final random = Random.secure();
    return List<int>.generate(quantity, (i) => random.nextInt(256));
  }

  String _nip4cipher(
    String privkey,
    String pubkey,
    String payload,
    bool cipher, {
    String? nonce,
  }) {
    // if cipher=false –> decipher –> nonce needed
    if (!cipher && nonce == null) throw Exception("missing nonce");

    // init variables
    Uint8List input, output, iv;
    if (!cipher && nonce != null) {
      input = base64.decode(payload);
      output = Uint8List(input.length);
      iv = base64.decode(nonce);
    } else {
      input = Utf8Encoder().convert(payload);
      output = Uint8List(input.length + 16);
      iv = Uint8List.fromList(generateRandomBytes(16));
    }

    // params
    List<List<int>> keplerSecret = Kepler.byteSecret(privkey, pubkey);
    var key = Uint8List.fromList(keplerSecret[0]);
    var params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );
    var algo = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    // processing
    algo.init(cipher, params);
    var offset = 0;
    while (offset < input.length - 16) {
      offset += algo.processBlock(input, offset, output, offset);
    }
    offset += algo.doFinal(input, offset, output, offset);
    Uint8List result = output.sublist(0, offset);

    if (cipher) {
      String stringIv = base64.encode(iv);
      String plaintext = base64.encode(result);
      return "$plaintext?iv=$stringIv";
    } else {
      return Utf8Decoder().convert(result);
    }
  }
}
