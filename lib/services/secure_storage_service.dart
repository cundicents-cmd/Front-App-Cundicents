import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para el almacenamiento seguro de credenciales sensibles.
///
/// Utiliza flutter_secure_storage que en Android usa Keystore/Keychain
/// y en iOS usa Keychain para proteger la información.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences removed in v11 - now uses EncryptedSharedPreferences by default
      // Opcional: especificar alias de clave en Keystore
      // keyAlias: 'cundicents_key',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Claves de almacenamiento centralizadas para evitar errores tipográficos
  static const String _keyIdUsuario = 'id_usuario';
  static const String _keyCorreo = 'correo';
  static const String _keyHashPassword = 'hash_password';

  /// Guarda las tres credenciales requeridas para la sesión.
  ///
  /// Lanza una excepción si falla la escritura.
  static Future<void> guardarCredenciales({
    required int idUsuario,
    required String correo,
    required String hashPassword,
  }) async {
    await _storage.write(key: _keyIdUsuario, value: idUsuario.toString());
    await _storage.write(key: _keyCorreo, value: correo);
    await _storage.write(key: _keyHashPassword, value: hashPassword);
  }

  /// Lee el ID de usuario almacenado.
  ///
  /// Retorna `null` si no existe o está vacío.
  static Future<int?> leerIdUsuario() async {
    final value = await _storage.read(key: _keyIdUsuario);
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Lee el correo almacenado.
  ///
  /// Retorna `null` si no existe o está vacío.
  static Future<String?> leerCorreo() async {
    final value = await _storage.read(key: _keyCorreo);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Lee el hash de contraseña almacenado.
  ///
  /// Retorna `null` si no existe o está vacío.
  static Future<String?> leerHashPassword() async {
    final value = await _storage.read(key: _keyHashPassword);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Verifica si existe una sesión completa almacenada.
  ///
  /// Una sesión se considera completa cuando los tres campos
  /// (id_usuario, correo, hash_password) tienen valores no nulos y no vacíos.
  static Future<bool> existeSesionCompleta() async {
    final idUsuario = await leerIdUsuario();
    final correo = await leerCorreo();
    final hashPassword = await leerHashPassword();

    return idUsuario != null && correo != null && hashPassword != null;
  }

  /// Obtiene todas las credenciales almacenadas.
  ///
  /// Retorna un mapa con las tres claves, o valores nulos si no existen.
  static Future<Map<String, String?>> obtenerTodasLasCredenciales() async {
    return {
      'id_usuario': (await leerIdUsuario())?.toString(),
      'correo': await leerCorreo(),
      'hash_password': await leerHashPassword(),
    };
  }

  /// Elimina todas las credenciales de la sesión (cierre de sesión).
  static Future<void> limpiarSesion() async {
    await _storage.delete(key: _keyIdUsuario);
    await _storage.delete(key: _keyCorreo);
    await _storage.delete(key: _keyHashPassword);
  }

  /// Actualiza solo el correo almacenado.
  static Future<void> actualizarCorreo(String nuevoCorreo) async {
    await _storage.write(key: _keyCorreo, value: nuevoCorreo);
  }

  /// Actualiza solo el hash de contraseña almacenado.
  static Future<void> actualizarHashPassword(String nuevoHash) async {
    await _storage.write(key: _keyHashPassword, value: nuevoHash);
  }

  /// Actualiza solo el ID de usuario almacenado.
  static Future<void> actualizarIdUsuario(int nuevoId) async {
    await _storage.write(key: _keyIdUsuario, value: nuevoId.toString());
  }
}