import 'dart:convert';

import 'package:nwc/nwc.dart';
import 'package:nwc/src/utils/exceptions.dart';

const connectionURI = 'nostr+walletconnect://......';

Future<void> main() async {
  final nwc = NWC();

  final parsedUri = nwc.nip47.parseNostrConnectUri(connectionURI);

  await nwc.relaysService.init(relaysUrl: [parsedUri.relay]);

  final subToFilter = Request(
    filters: [
      Filter(
        kinds: [23195],
        authors: [parsedUri.pubkey],
        since: DateTime.now(),
      )
    ],
  );

  final nostrStream = nwc.relaysService.startEventsSubscription(
    request: subToFilter,
    onEose: (relay, eose) =>
        print('[+] subscriptionId: ${eose.subscriptionId}, relay: $relay'),
  );

  nostrStream.stream.listen((Event event) {
    if (event.kind == 23195 && event.content != null) {
      try {
        final decryptedContent = nwc.nip04.decrypt(
          parsedUri.secret,
          parsedUri.pubkey,
          event.content!,
        );

        final content = nwc.nip47.parseResponseResult(decryptedContent);

        if (content.resultType == NWCResultType.get_balance) {
          final result = content.result as Get_Balance_Result;
          print('[+] Balance: ${result.balance} msat');
        } else if (content.resultType == NWCResultType.make_invoice) {
          final result = content.result as Make_Invoice_Result;
          print('[+] Invoice: ${result.invoice}');
        } else if (content.resultType == NWCResultType.pay_invoice) {
          final result = content.result as Pay_Invoice_Result;
          print('[+] Preimage: ${result.preimage}');
        } else if (content.resultType == NWCResultType.error) {
          final result = content.result as NWC_Error_Result;
          print('[+] Preimage: ${result.errorMessage}');
        } else {
          print('[+] content: $decryptedContent');
        }
      } catch (e) {
        if (e is DecipherFailedException) {
          print('$e');
        }
      }
    }
  });

  await getBalance(nwc, parsedUri);
  await makeInvoice(nwc, parsedUri);
  await payInvoice(nwc, parsedUri);
}

Future<void> getBalance(NWC nwc, NostrWalletConnectUri parsedUri) async {
  final message = {"method": "get_balance"};

  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = Event.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: KeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwc.relaysService.sendEventToRelays(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] getBalance() => okCommand: $okCommand');
}

Future<void> makeInvoice(NWC nwc, NostrWalletConnectUri parsedUri) async {
  final amountInSats = 100;
  final description = 'Hello Nostr Wallet Connect!';

  final message = {
    "method": "make_invoice",
    "params": {
      "amount": amountInSats * 1000, // value in msats
      "description": description, // invoice's description, optional
    }
  };

  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = Event.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: KeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwc.relaysService.sendEventToRelays(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] makeInvoice() => okCommand: $okCommand');
}

Future<void> payInvoice(NWC nwc, NostrWalletConnectUri parsedUri) async {
  final invoice =
      'lnbc1240n1pnrm654pp5q9evu4tpgd2f8luaz5vscezc5j84m7yqv2vk0h735r6mvc9ujwusdqu2askcmr9wssx7e3q2dshgmmndp5scqzzsxqyz5vqsp5rjq5vef8nuv4adtrlr22n5su5nkt9dh3xw8953yesg8f28n4k4js9qyyssqy80q0a057s67qz3cepdkfeucjnga6w08zsk7pp8eq9wuxkfr65uney4a4vs5c78k3vl7e43s0j97nwqrvc2s7k585j3p9gxfylp3ewgpwt3j6m';
  final message = {
    "method": "pay_invoice",
    "params": {
      "invoice": invoice,
    }
  };

  final content = nwc.nip04.encrypt(
    parsedUri.secret,
    parsedUri.pubkey,
    jsonEncode(message),
  );

  final request = Event.fromPartialData(
    kind: 23194,
    content: content,
    tags: [
      ['p', parsedUri.pubkey]
    ],
    createdAt: DateTime.now(),
    keyPairs: KeyPairs(private: parsedUri.secret),
  );

  final okCommand = await nwc.relaysService.sendEventToRelays(
    request,
    timeout: const Duration(seconds: 3),
  );

  print('[+] payInvoice() => okCommand: $okCommand');
}
