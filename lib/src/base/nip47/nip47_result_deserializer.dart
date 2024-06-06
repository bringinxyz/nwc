// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nwc/src/nip47_result/nip47_result.dart';
import '../../utils/nwc_result_type.dart';

/// Deserializes [NIP47] response results into corresponding objects.
class Nip47ResultDeserializer extends Equatable {
  /// The deserialized result.
  late dynamic result;

  /// The type of the deserialized result.
  late NWCResultType resultType;

  /// Constructs a [Nip47ResultDeserializer] instance and deserializes the provided [content].
  ///
  /// Throws an error if the content cannot be deserialized.
  Nip47ResultDeserializer.deserialize(String content) {
    assert(canBeDeserialized(content));
    final data = jsonDecode(content) as Map<String, dynamic>;

    final type = data['result_type'];
    if (!NWCResultType.values.map((e) => e.name).contains(type)) {
      throw '[!] Unsupported response';
    }

    resultType = NWCResultType.fromName(type);

    bool errorPresent = !data.containsKey('result');

    if (errorPresent) {
      result = NWC_Error_Result.deserialize(data);
      resultType = NWCResultType.error;
    } else {
      switch (resultType) {
        case NWCResultType.get_balance:
          result = Get_Balance_Result.deserialize(data);
          break;
        case NWCResultType.make_invoice:
          result = Make_Invoice_Result.deserialize(data);
          break;
        case NWCResultType.lookup_invoice:
          result = Lookup_Invoice_Result.deserialize(data);
          break;
        case NWCResultType.pay_invoice:
          result = Pay_Invoice_Result.deserialize(data);
          break;
        case NWCResultType.list_transactions:
          result = List_Transactions_Result.deserialize(data);
          break;
        default:
          result = data;
          break;
      }
    }
  }

  /// Checks if the given [dataFromRelay] can be deserialized into a [NWCResultType].
  static bool canBeDeserialized(String dataFromRelay) {
    final decoded = jsonDecode(dataFromRelay) as Map<String, dynamic>;

    return decoded['result_type'] != null;
  }

  @override
  List<Object?> get props => [
        result,
        resultType,
      ];
}
