abstract class Nip04Base {
  String encrypt(
    String senderPrivkey,
    String receiverPubkey,
    String message,
  );

  String decrypt(
    String senderPrivkey,
    String receiverPubkey,
    String content,
  );
}
