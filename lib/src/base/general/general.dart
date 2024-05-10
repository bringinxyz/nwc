import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../../utils/nwc_logger.dart';
import 'general_base.dart';

/// General class responsible for managing helper functions within the package.
class General extends GeneralBase {
  General({required this.utils});

  final NWCLoggerUtils utils;

  /// Generates a randwom 64-length hexadecimal string.
  ///
  /// Example:
  ///
  /// ```dart
  /// final randomGeneratedHex = NWC.instance.generalService.random64HexChars();
  /// print(randomGeneratedHex); // ...
  /// ```
  ///
  /// Returns the generated hexadecimal string.
  @override
  String random64HexChars() {
    final random = Random.secure();
    final randomBytes = List<int>.generate(32, (i) => random.nextInt(256));

    return hex.encode(randomBytes);
  }

  /// Generates a random 64-length hexadecimal string that is consistent with the given [input].
  ///
  /// Example:
  ///
  /// ```dart
  /// final input = "example";
  /// final consistentHex = Nostr.instance.utilsService.consistent64HexChars(input);
  /// print(consistentHex); // e.g., "b5c69220f7d..."
  /// ```
  ///
  /// Returns the consistent hexadecimal string corresponding to the input.
  @override
  String consistent64HexChars(String input) {
    final randomBytes = utf8.encode(input);
    final hashed = sha256.convert(randomBytes);

    return hex.encode(hashed.bytes);
  }

  /// Encodes the given [input] string to hexadecimal format.
  ///
  /// Example:
  ///
  /// ```dart
  /// final hexDecodedString = NWC.instance.generalService.hexEncodeString("example");
  /// print(hexDecodedString); // ...
  /// ```
  ///
  /// Returns the hexadecimal representation of the input string.
  @override
  String hexEncodeString(String input) {
    return hex.encode(utf8.encode(input));
  }

  /// Generates the requested quantity of random secure bytes.
  ///
  /// Example:
  ///
  /// ```dart
  /// final randomBytes = Nostr.instance.utilsService.generateRandomBytes(16);
  /// print(randomBytes); // e.g., [42, 187, 15, 92, ...]
  /// ```
  ///
  /// Returns a list of random secure bytes.
  List<int> generateRandomBytes(int quantity) {
    final random = Random.secure();
    return List<int>.generate(quantity, (i) => random.nextInt(256));
  }
}
