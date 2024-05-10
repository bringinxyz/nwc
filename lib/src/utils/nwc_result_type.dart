// ignore_for_file: constant_identifier_names

/// Represents the type of result for Nostr Wallet Connect operations.
enum NWCResultType {
  /// Indicates an idle state.
  idle("idle"),

  /// Indicates a 'get_balance' operation result.
  get_balance("get_balance"),

  /// Indicates a 'make_invoice' operation result.
  make_invoice("make_invoice"),

  /// Indicates a 'pay_invoice' operation result.
  pay_invoice("pay_invoice"),

  /// Indicates a 'lookup_invoice' operation result.
  lookup_invoice("lookup_invoice"),

  /// Indicates an error result.
  error("error");

  /// Returns the name of the enum value.
  final String name;
  const NWCResultType(this.name);

  /// Returns the [NWCResultType] enum value from its name.
  static fromName(String name) =>
      NWCResultType.values.byName(name.toLowerCase());
}
