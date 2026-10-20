import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/asymmetric/oaep.dart';

/// Servicio para encriptación RSA-OAEP-SHA256 usando pointycastle.
///
/// Implementa la encriptación compatible con el backend FastAPI
/// (OAEP con MGF1-SHA256, SHA256, sin label).
class CryptoService {
  static RSAPublicKey? _publicKey;
  static bool _isInitialized = false;

  /// Inicializa el servicio cargando la clave pública desde assets.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final pemString = await rootBundle.loadString('assets/clave_publica.pem');
      _publicKey = _parsePublicKey(pemString);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Error al cargar clave pública: $e');
    }
  }

  /// Parsea una clave pública PEM (PKCS#8 / X.509) a RSAPublicKey de pointycastle.
  static RSAPublicKey _parsePublicKey(String pemString) {
    // Remover headers, footers y whitespace
    final cleaned = pemString
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();

    final bytes = base64Decode(cleaned);

    // Parsear ASN.1 DER para extraer modulus y exponent
    // Estructura PKCS#8: SEQUENCE { algorithm, subjectPublicKey BIT STRING }
    // subjectPublicKey contiene: SEQUENCE { modulus INTEGER, publicExponent INTEGER }

    int offset = 0;

    // Leer SEQUENCE exterior
    if (bytes[offset] != 0x30) {
      throw Exception('Formato de clave pública inválido: se esperaba SEQUENCE');
    }
    offset++;
    final outerLength = _readLength(bytes, offset);
    offset += outerLength.length;
    // final outerEnd = offset + outerLength.value; // No usado

    // Leer AlgorithmIdentifier (SEQUENCE { OID, NULL })
    if (bytes[offset] != 0x30) {
      throw Exception('Formato de clave pública inválido: se esperaba AlgorithmIdentifier');
    }
    offset++;
    final algLength = _readLength(bytes, offset);
    offset += algLength.length;
    offset += algLength.value; // Saltar algorithm identifier

    // Leer subjectPublicKey (BIT STRING)
    if (bytes[offset] != 0x03) {
      throw Exception('Formato de clave pública inválido: se esperaba BIT STRING');
    }
    offset++;
    final bitStringLength = _readLength(bytes, offset);
    offset += bitStringLength.length;
    // BIT STRING tiene un byte de unused bits (normalmente 0)
    if (bytes[offset] != 0x00) {
      throw Exception('BIT STRING unused bits no es 0');
    }
    offset++;

    // Ahora estamos en la SEQUENCE interna con modulus y exponent
    if (bytes[offset] != 0x30) {
      throw Exception('Formato de clave pública inválido: se esperaba SEQUENCE interna');
    }
    offset++;
    final innerLength = _readLength(bytes, offset);
    offset += innerLength.length;

    // Leer modulus (INTEGER)
    if (bytes[offset] != 0x02) {
      throw Exception('Formato de clave pública inválido: se esperaba INTEGER para modulus');
    }
    offset++;
    final modLength = _readLength(bytes, offset);
    offset += modLength.length;
    final modulusBytes = bytes.sublist(offset, offset + modLength.value);
    offset += modLength.value;

    // Leer publicExponent (INTEGER)
    if (bytes[offset] != 0x02) {
      throw Exception('Formato de clave pública inválido: se esperaba INTEGER para exponent');
    }
    offset++;
    final expLength = _readLength(bytes, offset);
    offset += expLength.length;
    final exponentBytes = bytes.sublist(offset, offset + expLength.value);

    // Convertir a BigInt (big-endian)
    final modulus = _bytesToBigInt(modulusBytes);
    final exponent = _bytesToBigInt(exponentBytes);

    return RSAPublicKey(modulus, exponent);
  }

  /// Lee la longitud ASN.1 DER.
  static _LengthResult _readLength(List<int> bytes, int offset) {
    if (bytes[offset] < 0x80) {
      return _LengthResult(value: bytes[offset], length: 1);
    }
    final numBytes = bytes[offset] & 0x7F;
    offset++;
    int value = 0;
    for (int i = 0; i < numBytes; i++) {
      value = (value << 8) | bytes[offset + i];
    }
    return _LengthResult(value: value, length: 1 + numBytes);
  }

  /// Convierte bytes big-endian a BigInt.
  static BigInt _bytesToBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  /// Encripta un string plano usando RSA-OAEP-SHA256 con la clave pública.
  ///
  /// Retorna los bytes encriptados (no codificados en Base64).
  static Uint8List encryptOaepSha256(String plaintext) {
    if (!_isInitialized || _publicKey == null) {
      throw StateError('CryptoService no inicializado. Llama a initialize() primero.');
    }

    // Configurar OAEP con SHA-256 (MGF1 usa el mismo hash por defecto)
    // encodingParams (label) = vacío por defecto
    final oaep = OAEPEncoding.withSHA256(RSAEngine(), Uint8List(0))
      ..init(
        true, // forEncryption
        PublicKeyParameter<RSAPublicKey>(_publicKey!),
      );

    final plainBytes = utf8.encode(plaintext);
    final encrypted = oaep.process(Uint8List.fromList(plainBytes));

    return encrypted;
  }

  /// Encripta y codifica en Base64 listo para enviar como query parameter.
  static String encryptAndEncodeBase64(String plaintext) {
    final encrypted = encryptOaepSha256(plaintext);
    return base64Encode(encrypted);
  }
}

class _LengthResult {
  final int value;
  final int length;

  _LengthResult({required this.value, required this.length});
}