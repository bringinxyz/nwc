import 'dart:developer' as dev;

abstract class NWCLogger {
  void disableLogs();
  void enableLogs();

  Future<bool> dispose();
}

/// [NWCLoggerUtils] to be used throughout the [NWC] instance.
class NWCLoggerUtils {
  /// Indicates whether logs are enabled.
  bool _isLogsEnabled = true;

  /// Disables logging.
  void disableLogs() {
    _isLogsEnabled = false;
  }

  /// Enables logging.
  void enableLogs() {
    _isLogsEnabled = true;
  }

  /// Logs a message, optionally including an error.
  void log(String message, [Object? error]) {
    if (_isLogsEnabled) {
      dev.log(
        message,
        name: "NWC${error != null ? "Error" : ""}",
        error: error,
      );
    }
  }
}
