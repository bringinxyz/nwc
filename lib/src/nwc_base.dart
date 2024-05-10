import 'package:nwc/src/base/nip47/nip47.dart';

import 'base/general/general.dart';
import 'base/keys/keys.dart';
import 'base/nip04/nip04.dart';
import 'base/relays/relays.dart';
import 'utils/nwc_logger.dart';

/// The main entry point for interacting with the Nostr Wallet Connect package.
class NWC implements NWCLogger {
  /// Factory constructor for creating a singleton instance of [NWC].
  factory NWC() {
    return NWC._();
  }

  /// Private constructor for initializing internal resources.
  NWC._() {
    loggerUtils = NWCLoggerUtils();
  }

  /// Utility instance for handling logging within the NWC package.
  late final NWCLoggerUtils loggerUtils;

  /// Indicates whether this instance's resources have been disposed.
  bool _isDisposed = false;

  /// Singleton instance of [NWC].
  static final NWC _instance = NWC._();

  /// Retrieves the singleton instance of [NWC].
  static NWC get instance => _instance;

  /// Disables logging within the NWC package.
  @override
  void disableLogs() {
    loggerUtils.disableLogs();
  }

  /// Enables logging within the NWC package.
  @override
  void enableLogs() {
    loggerUtils.enableLogs();
  }

  /// Disposes of this instance and frees associated resources.
  ///
  /// Returns a [Future] indicating whether disposal was successful.
  @override
  Future<bool> dispose() async {
    if (_isDisposed) {
      loggerUtils.log('This NWC instance is already disposed.');
      return true;
    }

    _isDisposed = true;

    loggerUtils.log('A NWC instance disposed successfully.');

    await Future.wait<dynamic>(<Future<bool>>[
      Future.value(keysService.freeAllResources()),
      relaysService.freeAllResources(),
    ]);

    return true;
  }

  /// Service for managing cryptographic keys.
  late final keysService = Keys(
    utils: loggerUtils,
  );

  /// Service for interacting with relays.
  late final relaysService = Relays(
    utils: loggerUtils,
  );

  /// Service providing general utilities.
  late final generalService = General(
    utils: loggerUtils,
  );

  /// Service for NIP-04 operations.
  late final nip04 = Nip04(
    utils: loggerUtils,
  );

  /// Service for NIP-47 operations.
  late final nip47 = Nip47(
    utils: loggerUtils,
  );
}
