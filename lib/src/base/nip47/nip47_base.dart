import 'package:nwc/src/base/nip47/nip47_result_deserializer.dart';
import 'package:nwc/src/model/model.dart';

abstract class Nip47Base {
  NostrWalletConnectUri parseNostrConnectUri(String connectionUri);
  Nip47ResultDeserializer parseResponseResult(String content);
}
