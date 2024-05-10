import 'package:nwc/src/model/key_pairs.dart';

abstract class KeysBase {
  KeyPairs generateKeyPair();
  KeyPairs generateKeyPairFromExistingPrivateKey(String privateKey);
  String generatePrivateKey();
  String derivePublicKey({required String privateKey});
  String sign({required String privateKey, required String message});
}
