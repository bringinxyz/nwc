import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

class Kepler {
  /// return a Bytes data secret
  static List<List<int>> byteSecret(String privateString, String publicString) {
    final secret = rawSecret(privateString, publicString);
    assert(secret.x != null && secret.y != null);
    final xs = secret.x!.toBigInteger()!.toRadixString(16);
    final ys = secret.y!.toBigInteger()!.toRadixString(16);
    final hexX = leftPadding(xs, 64);
    final hexY = leftPadding(ys, 64);
    final secretBytes = Uint8List.fromList(hex.decode('$hexX$hexY'));
    return [secretBytes.sublist(0, 32), secretBytes.sublist(32, 40)];
  }

  /// return a ECPoint data secret
  static ECPoint rawSecret(String privateString, String publicString) {
    final privateKey = loadPrivateKey(privateString);
    final publicKey = loadPublicKey(publicString);
    assert(privateKey.d != null && publicKey.Q != null);
    return scalarMultiple(privateKey.d!, publicKey.Q!);
  }

  static String leftPadding(String s, int width) {
    const paddingData = '000000000000000';
    final paddingWidth = width - s.length;
    if (paddingWidth < 1) {
      return s;
    }
    return "${paddingData.substring(0, paddingWidth)}$s";
  }

  /// return a privateKey from hex string
  static ECPrivateKey loadPrivateKey(String storedkey) {
    final d = BigInt.parse(storedkey, radix: 16);
    final param = ECCurve_secp256k1();
    return ECPrivateKey(d, param);
  }

  /// return a publicKey from hex string
  static ECPublicKey loadPublicKey(String storedkey) {
    final param = ECCurve_secp256k1();
    if (storedkey.length < 120) {
      List<int> codeList = [];
      for (var idx = 0; idx < storedkey.length - 1; idx += 2) {
        final hexStr = storedkey.substring(idx, idx + 2);
        codeList.add(int.parse(hexStr, radix: 16));
      }
      final Q = param.curve.decodePoint(codeList);
      return ECPublicKey(Q, param);
    } else {
      final x = BigInt.parse(storedkey.substring(0, 64), radix: 16);
      final y = BigInt.parse(storedkey.substring(64), radix: 16);
      final Q = param.curve.createPoint(x, y);
      return ECPublicKey(Q, param);
    }
  }
}

// credit: https://github.com/tjcampanella/kepler/blob/master/lib/src/operator.dart
BigInt theP = BigInt.parse(
    "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
    radix: 16);
BigInt theN = BigInt.parse(
    "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
    radix: 16);

bool isOnCurve(ECPoint point) {
  assert(point.x != null &&
      point.y != null &&
      point.curve.a != null &&
      point.curve.b != null);
  final x = point.x!.toBigInteger();
  final y = point.y!.toBigInteger();
  final rs = (y! * y -
          x! * x * x -
          point.curve.a!.toBigInteger()! * x -
          point.curve.b!.toBigInteger()!) %
      theP;
  return rs == BigInt.from(0);
}

BigInt inverseMod(BigInt k, BigInt p) {
  if (k.compareTo(BigInt.zero) == 0) {
    throw Exception("Cannot Divide By 0");
  }
  if (k < BigInt.from(0)) {
    return p - inverseMod(-k, p);
  }
  var s = [BigInt.from(0), BigInt.from(1), BigInt.from(1)];
  var t = [BigInt.from(1), BigInt.from(0), BigInt.from(0)];
  var r = [p, k, k];
  while (r[0] != BigInt.from(0)) {
    var quotient = r[2] ~/ r[0];
    r[1] = r[2] - quotient * r[0];
    r[2] = r[0];
    r[0] = r[1];
    s[1] = s[2] - quotient * s[0];
    s[2] = s[0];
    s[0] = s[1];
    t[1] = t[2] - quotient * t[0];
    t[2] = t[0];
    t[0] = t[1];
  }
  final gcd = r[2];
  final x = s[2];
  // final y = t[2];
  assert(gcd == BigInt.from(1));
  assert((k * x) % p == BigInt.from(1));
  return x % p;
}

ECPoint pointNeg(ECPoint point) {
  assert(isOnCurve(point));
  assert(point.x != null || point.y != null);
  final x = point.x!.toBigInteger();
  final y = point.y!.toBigInteger();
  final result = point.curve.createPoint(x!, -y! % theP);
  assert(isOnCurve(result));
  return result;
}

ECPoint pointAdd(ECPoint? point1, ECPoint? point2) {
  if (point1 == null) {
    return point2!;
  }
  if (point2 == null) {
    return point1;
  }
  assert(isOnCurve(point1));
  assert(isOnCurve(point2));
  final x1 = point1.x!.toBigInteger();
  final y1 = point1.y!.toBigInteger();
  final x2 = point2.x!.toBigInteger();
  final y2 = point2.y!.toBigInteger();

  BigInt m;
  if (x1 == x2) {
    m = (BigInt.from(3) * x1! * x1 + point1.curve.a!.toBigInteger()!) *
        inverseMod(BigInt.from(2) * y1!, theP);
  } else {
    m = (y1! - y2!) * inverseMod(x1! - x2!, theP);
  }
  final x3 = m * m - x1 - x2!;
  final y3 = y1 + m * (x3 - x1);
  ECPoint result = point1.curve.createPoint(x3 % theP, -y3 % theP);
  assert(isOnCurve(result));
  return result;
}

ECPoint scalarMultiple(BigInt k, ECPoint point) {
  assert(isOnCurve(point));
  assert((k % theN).compareTo(BigInt.zero) != 0);
  assert(point.x != null && point.y != null);
  if (k < BigInt.from(0)) {
    return scalarMultiple(-k, pointNeg(point));
  }
  ECPoint? result;
  ECPoint addend = point;
  while (k > BigInt.from(0)) {
    if (k & BigInt.from(1) > BigInt.from(0)) {
      result = pointAdd(result, addend);
    }
    addend = pointAdd(addend, addend);
    k >>= 1;
  }
  assert(isOnCurve(result!));
  return result!;
}
