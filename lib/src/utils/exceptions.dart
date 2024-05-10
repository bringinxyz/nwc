/// Thrown when a relay is not found or registered.
class RelayNotFoundException implements Exception {
  /// The URL of the relay that was not found.
  final String relayUrl;

  /// Constructs a [RelayNotFoundException] instance.
  ///
  /// Parameters:
  /// - [relayUrl]: The URL of the relay that was not found.
  RelayNotFoundException(this.relayUrl);

  @override
  String toString() {
    return '[!] RelayNotFoundException: Relay with URL "$relayUrl" was not found or registered.';
  }
}

/// Thrown when deciphering a message fails.
class DecipherFailedException implements Exception {
  /// The error message.
  final Object error;

  /// Constructs a [DecipherFailedException] instance.
  ///
  /// Parameters:
  /// - [error]: The error message.
  DecipherFailedException(this.error);

  @override
  String toString() {
    return '[!] DecipherFailedException: Deciphering failed with error: $error';
  }
}
