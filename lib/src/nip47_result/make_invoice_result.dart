// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';

/// Represents the result of a 'make_invoice' response.
class Make_Invoice_Result extends Equatable {
  /// The type of the invoice "incoming" for invoices, "outgoing" for payments.
  final String type;

  /// The bolt11 invoice.
  final String invoice;

  /// The description of the invoice.
  final String description;

  /// The hash of the invoice description.
  final String descriptionHash;

  /// The preimage of the invoice.
  final String preimage;

  /// The payment hash of the invoice.
  final String paymentHash;

  /// The amount of the invoice (in MSATs)
  final int amount;

  /// The fees paid for the invoice (in MSATs).
  final int feesPaid;

  /// The timestamp when the invoice/payment was created.
  final int createdAt;

  /// The timestamp when the invoice/payment expires.
  final int expiresAt;

  /// The timestamp when the invoice was settled (optional).

  final int? settledAt;

  /// The type of the result.

  final String resultType;

  Make_Invoice_Result({
    required this.type,
    required this.invoice,
    required this.description,
    required this.descriptionHash,
    required this.preimage,
    required this.paymentHash,
    required this.amount,
    required this.feesPaid,
    required this.createdAt,
    required this.expiresAt,
    this.settledAt,
    required this.resultType,
  });

  factory Make_Invoice_Result.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return Make_Invoice_Result(
      type: result['type'] as String,
      invoice: result['invoice'] as String,
      description: result['description'] as String,
      descriptionHash: result['description_hash'] as String,
      preimage: result['preimage'] as String,
      paymentHash: result['payment_hash'] as String,
      amount: result['amount'] as int,
      feesPaid: result['fees_paid'] as int,
      createdAt: result['created_at'] as int,
      expiresAt: result['expires_at'] as int,
      settledAt: result['settled_at'] as int?, // optional
      resultType: input['result_type'] as String,
    );
  }

  @override
  List<Object?> get props => [
        type,
        invoice,
        description,
        descriptionHash,
        preimage,
        paymentHash,
        amount,
        feesPaid,
        createdAt,
        expiresAt,
        settledAt,
        resultType,
      ];
}
