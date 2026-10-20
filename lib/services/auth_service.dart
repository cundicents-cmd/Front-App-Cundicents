import '../config/api_config.dart';
import '../models/usuario.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'crypto_service.dart';
import 'dart:convert';

/// Servicio de autenticación y registro de usuarios.
///
/// Encapsula toda la lógica de comunicación con los endpoints
/// de autenticación de la API FastAPI.
class AuthService {
  final ApiService _apiService = ApiService();

  /// Verifica las credenciales usando el endpoint simple.
  ///
  /// Llama a `GET /users/verificar-credenciales` con username y password
  /// como query parameters.
  ///
  /// Retorna [VerificarCredencialesResponse] con el resultado.
  /// Lanza [ApiException] en caso de error de red o servidor.
  Future<VerificarCredencialesResponse> verificarCredenciales({
    required String username,
    required String password,
  }) async {
    final response = await _apiService.get(
      endpoint: ApiEndpoints.verificarCredenciales,
      queryParameters: {
        'username': username,
        'password': password,
      },
    );

    return VerificarCredencialesResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Inicia sesión con el endpoint principal (RSA-OAEP-SHA256).
  ///
  /// Encripta las credenciales con la clave pública RSA y las envía
  /// como query parameter `payload` a `GET /users/login`.
  ///
  /// Retorna [Usuario] con id_usuario, correo y hash_password del backend.
  /// Lanza [ApiException] en caso de error (401 credenciales inválidas, etc.).
  Future<Usuario> loginConRsa({
    required String correo,
    required String password,
  }) async {
    // Asegurar que el servicio criptográfico esté inicializado
    await CryptoService.initialize();

    // 1. Preparar JSON con credenciales
    final credentials = jsonEncode({'correo': correo, 'password': password});

    // 2. Encriptar con RSA-OAEP-SHA256 y codificar en Base64
    final payloadBase64 = CryptoService.encryptAndEncodeBase64(credentials);

    // 3. Enviar como query parameter
    final response = await _apiService.get(
      endpoint: ApiEndpoints.login,
      queryParameters: {'payload': payloadBase64},
    );

    final data = response as Map<String, dynamic>;

    return Usuario.fromLoginResponse(data);
  }

  /// Registra un nuevo usuario en el sistema.
  ///
  /// Llama a `POST /users/register` con los datos del usuario.
  /// El backend hashea la contraseña con Django PBKDF2.
  ///
  /// Retorna [RegisterResponse] con el mensaje del stored procedure.
  /// Lanza [ApiException] en caso de error (422 validación, 500 servidor).
  Future<RegisterResponse> registrarUsuario({
    required String nombre,
    required String apellido,
    required String contrasena,
    required String correo,
    int? cedula,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'contrasena': contrasena,
      'correo': correo,
      if (cedula != null) 'cedula': cedula,
    };

    final response = await _apiService.postJson(
      endpoint: ApiEndpoints.register,
      body: body,
    );

    return RegisterResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Obtiene los datos públicos de un usuario por su ID.
  ///
  /// Llama a `GET /users/{user_id}`.
  ///
  /// Retorna [Usuario] con los datos (nombre, apellido, email, cedula).
  /// Lanza [ApiException] si no se encuentra (404) o error de servidor.
  Future<Usuario> obtenerUsuarioPorId(int userId) async {
    final endpoint = '${ApiEndpoints.getUser}/$userId';
    final response = await _apiService.get(endpoint: endpoint);

    final usuario = Usuario.fromDetailResponse(response as Map<String, dynamic>);
    // El endpoint no devuelve el ID, lo asignamos manualmente
    return Usuario(
      idUsuario: userId,
      correo: usuario.correo,
      hashPassword: '', // No disponible en este endpoint
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      cedula: usuario.cedula,
    );
  }

  /// Actualiza la contraseña de un usuario.
  ///
  /// Llama a `POST /users/{user_id}/password`.
  ///
  /// Retorna [RegisterResponse] con mensaje de confirmación.
  /// Lanza [ApiException] en caso de error.
  Future<RegisterResponse> actualizarPassword({
    required int userId,
    required String newPassword,
  }) async {
    final endpoint = '${ApiEndpoints.updatePassword}/$userId/password';
    final response = await _apiService.postJson(
      endpoint: endpoint,
      body: {'new_password': newPassword},
    );

    return RegisterResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Actualiza los datos personales de un usuario.
  ///
  /// Llama a `POST /users/{user_id}/actualizar`.
  ///
  /// Retorna [RegisterResponse] con mensaje de confirmación.
  /// Lanza [ApiException] en caso de error.
  Future<RegisterResponse> actualizarDatos({
    required int userId,
    required String nombre,
    required String apellido,
    required String correo,
  }) async {
    final endpoint = '${ApiEndpoints.updateUser}/$userId/actualizar';
    final response = await _apiService.postJson(
      endpoint: endpoint,
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
      },
    );

    return RegisterResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Extrae datos de una cédula mediante OCR.
  ///
  /// Llama a `POST /cedula/extraer` con la imagen binaria.
  ///
  /// Retorna [CedulaData] con nombres, apellidos y número de documento.
  /// Lanza [ApiException] en caso de error.
  Future<CedulaData> extraerDatosCedula(List<int> imageBytes, {String filename = 'cedula.jpg'}) async {
    // Detectar MIME type basado en la extensión del archivo
    String contentType = 'image/jpeg';
    final lowerFilename = filename.toLowerCase();
    if (lowerFilename.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lowerFilename.endsWith('.webp')) {
      contentType = 'image/webp';
    } else if (lowerFilename.endsWith('.heic') || lowerFilename.endsWith('.heif')) {
      contentType = 'image/heic';
    }

    final response = await _apiService.postBinary(
      endpoint: ApiEndpoints.extraerCedula,
      bytes: imageBytes,
      filename: filename,
      contentType: contentType,
    );

    return CedulaData.fromJson(response as Map<String, dynamic>);
  }

  /// Verifica la sesión almacenada llamando al endpoint `verificar-credenciales`.
  ///
  /// Lee las credenciales del almacenamiento seguro (id_usuario, correo, hash_password)
  /// y las valida contra la API usando el endpoint simple de verificación.
  ///
  /// Retorna `true` si la sesión es válida (credenciales correctas, p_existe = 1),
  /// `false` si las credenciales son inválidas (401 o p_existe = 0),
  /// Lanza [ApiException] si hay error de red/servidor (NO borra credenciales).
  Future<bool> verificarSesionAlmacenada() async {
    final idUsuario = await SecureStorageService.leerIdUsuario();
    final correo = await SecureStorageService.leerCorreo();
    final hashPassword = await SecureStorageService.leerHashPassword();

    if (idUsuario == null || correo == null || hashPassword == null) {
      return false;
    }

    try {
      // Usar el endpoint verificar-credenciales con los datos almacenados
      // username = correo, password = hash_password (según SP verificar_Usuario_Credenciales)
      final response = await verificarCredenciales(
        username: correo,
        password: hashPassword,
      );

      return response.credencialesValidas;
    } on ApiException catch (e) {
      // Si es 401, credenciales inválidas -> retorna false
      // Si es otro error (red, 500, etc.) -> relanza para NO borrar credenciales
      if (e.statusCode == 401) {
        return false;
      }
      rethrow;
    }
  }

  /// Inicia sesión y guarda las credenciales en almacenamiento seguro.
  ///
  /// Usa `loginConRsa` (endpoint /users/login con RSA) para autenticar.
  /// Si es exitoso, guarda id_usuario, correo y hash_password devueltos por la API.
  ///
  /// Retorna el [Usuario] autenticado con datos completos.
  /// Lanza [ApiException] si falla la autenticación o hay error de red.
  Future<Usuario> loginYGuardarSesion({
    required String correo,
    required String password,
  }) async {
    // 1. Autenticar con endpoint RSA
    final usuario = await loginConRsa(
      correo: correo,
      password: password,
    );

    // 2. Guardar las tres credenciales devueltas por la API
    await SecureStorageService.guardarCredenciales(
      idUsuario: usuario.idUsuario,
      correo: usuario.correo,
      hashPassword: usuario.hashPassword,
    );

    return usuario;
  }

  /// Cierra la sesión eliminando las credenciales almacenadas.
  Future<void> logout() async {
    await SecureStorageService.limpiarSesion();
  }

  void dispose() {
    _apiService.dispose();
  }
}