// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';

/// Represents the result of an pay_invoice response.
class Pay_Invoice_Result extends Equatable {
  /// The preimage of the paid invoice.
  final String preimage;

  /// The type of the result.
  final String resultType;

  Pay_Invoice_Result({
    required this.preimage,
    required this.resultType,
  });

  factory Pay_Invoice_Result.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return Pay_Invoice_Result(
      preimage: result['preimage'] as String,
      resultType: input['result_type'] as String,
    );
  }

  @override
  List<Object?> get props => [
        preimage,
        resultType,
      ];
}
