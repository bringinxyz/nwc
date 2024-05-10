// ignore_for_file: camel_case_types

import 'package:equatable/equatable.dart';

/// Represents the result of a 'get_balance' response.
class Get_Balance_Result extends Equatable {
  /// The type of the result.
  final String resultType;

  /// The current balance.
  final int balance;

  /// The maximum amount.
  final int? maxAmount;

  /// The budget renewal information.
  final String? budgetRenewal;

  Get_Balance_Result({
    required this.resultType,
    required this.balance,
    this.maxAmount,
    this.budgetRenewal,
  });

  factory Get_Balance_Result.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;

    return Get_Balance_Result(
      resultType: input['result_type'] as String,
      balance: result['balance'] as int,
      maxAmount: result['max_amount'] as int,
      budgetRenewal: result['budget_renewal'] as String,
    );
  }

  @override
  List<Object?> get props => [
        balance,
        maxAmount,
        budgetRenewal,
      ];
}
