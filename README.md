<p align="center"><img src="https://i.ibb.co/d4B6czh/O7a5j0-400x400.png" alt="nostr_tools package logo" /></p>
<p align="center">A dart package that simplifies the integration of <b>Nostr Wallet Connect</b> protocol into client applications.</p>

## Overview

NWC (Nostr Wallet Connect) is a Dart package. It offers a straightforward solution for developers aiming to integrate their app with the NWC protocol, enabling seamless access to a remote Lightning wallet through a standardized protocol. The protocol specifications are defined in [NIP47](https://github.com/nostr-protocol/nips/blob/master/47.md), and this package is created to adhere to those specifications.

## Features
- **Simple Integration**: Easily implement the NWC protocol into your Nostr client or Flutter app with minimal effort.
- **Standardized Protocol**: Follows the specifications outlined in [NIP47](https://github.com/nostr-protocol/nips/blob/master/47.md) for consistent and reliable functionality.
- **Secure Communication**: Ensures secure communication between your client and the remote Lightning wallet ([NIP04](https://github.com/nostr-protocol/nips/blob/master/04.md) included).

## Installation

Add the following line to your `pubspec.yaml`:

```yaml
dependencies:
  nwc: ^1.0.0
```

Then run:

```bash
$ flutter pub get
```

## Usage

### Initializing the "nwc" Package
To begin using the "nwc" package, you first need to import it into your Dart project. Then, instantiate the `NWC` class:

```dart
import 'package:nwc/nwc.dart';

final nwc = NWC();
```

### Parsing Connection URI
The `parseNostrConnectUri` method is used to parse the connection URI, extracting essential information such as pubkey, relay, secret and lud16 for communication with the remote Lightning wallet:

```dart
final parsedUri = nwc.nip47.parseNostrConnectUri(connectionURI);
```

### Initializing Relay Service
Before interacting with the remote wallet, you need to initialize the relay service. This step ensures proper communication channels are established:

```dart
await nwc.relaysService.init(relaysUrl: [parsedUri.relay]);
```

### Subscribing to Events
You can subscribe to specific events from the remote wallet using filters. This allows your application to react to relevant updates. :

```dart
final subToFilter = Request(
  filters: [
    Filter(
      kinds: [23195], // 23195 is registered for NIP47 response
      authors: [parsedUri.pubkey], // Specifying the pubkey of the wallet service
      since: DateTime.now(), // Specify a timestamp to start filtering events
    ),
  ],
);

final nostrStream = nwc.relaysService.startEventsSubscription(
  request: subToFilter,
  onEose: (relay, eose) =>
      print('[+] subscriptionId: ${eose.subscriptionId}, relay: $relay'),
);
```

### Listening to Event Stream
Once subscribed, you can listen to the event stream and react accordingly. Events are decrypted and processed based on the [NIP04](https://github.com/nostr-protocol/nips/blob/master/04.md) protocol:

```dart
nostrStream.stream.listen((Event event) {
  if (event.kind == 23195 && event.content != null) {
    try {
      final decryptedContent = nwc.nip04.decrypt(
        parsedUri.secret,
        parsedUri.pubkey,
        event.content!,
      );

      final content = nwc.nip47.parseResponseResult(decryptedContent);

      // Handle different types of events accordingly
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
```

###  Sending Events
Finally, you can send events to the remote wallet using the appropriate [commands defined in NIP47](https://github.com/nostr-protocol/nips/blob/master/47.md#commands). This allows you to perform actions such as fetching balances, generating invoices, or making payments:

```dart
final message = {"method": "get_balance"};

final content = nwc.nip04.encrypt(
  parsedUri.secret,
  parsedUri.pubkey,
  jsonEncode(message),
);

final request = Event.fromPartialData(
  kind: 23194,
  content: content,
  tags: [['p', parsedUri.pubkey]],
  createdAt: DateTime.now(),
  keyPairs: KeyPairs(private: parsedUri.secret),
);

final okCommand = await nwc.relaysService.sendEventToRelays(
  request,
  timeout: const Duration(seconds: 3),
);

print('[+] getBalance() => okCommand: $okCommand');
```

By following these steps, you can effectively integrate the "nwc" package into your flutter app, enabling seamless communication with remote Lightning wallets through the NWC protocol.

## Contributing
Contributions are welcome! If you have suggestions, feature requests, or bug reports, please open an issue or submit a pull request.

## License
This package is licensed under the MIT License - see the LICENSE file for details.
