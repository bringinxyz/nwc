// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';

/// Represents the result of an error response.
class NWC_Error_Result extends Equatable {
  /// The error code.
  final String errorCode;

  /// The error message.
  final String errorMessage;

  /// The type of the result.
  final String resultType;

  NWC_Error_Result({
    required this.errorCode,
    required this.errorMessage,
    required this.resultType,
  });

  factory NWC_Error_Result.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('error')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> error = input['error'] as Map<String, dynamic>;

    return NWC_Error_Result(
      errorCode: error['code'] as String,
      errorMessage: error['message'] as String,
      resultType: input['result_type'] as String,
    );
  }

  @override
  List<Object?> get props => [
        errorCode,
        errorMessage,
        resultType,
      ];
}
