import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? detail;

  ApiException({
    required this.statusCode,
    required this.message,
    this.detail,
  });

  @override
  String toString() => 'ApiException($statusCode): $message${detail != null ? ' - $detail' : ''}';
}

/// Servicio base para comunicación HTTP con la API FastAPI.
///
/// Centraliza la configuración del cliente HTTP, timeouts,
/// manejo de errores y construcción de URLs.
class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Cliente HTTP compartido.
  final http.Client _client = http.Client();

  /// Construye y valida la URI completa.
  Uri _buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) {
      throw ApiException(
        statusCode: 0,
        message: 'Error de configuración: URL base de la API no definida',
      );
    }
    final url = ApiConfig.buildUrl(endpoint);
    print('API Request URL: $url');
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParameters);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw ApiException(
          statusCode: 0,
          message: 'URL inválida: esquema faltante o incorrecto ($url)',
        );
      }
      return uri;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'URL malformada: $url',
      );
    }
  }

  /// Realiza una petición GET.
  ///
  /// [endpoint] - Ruta del endpoint (ej. '/users/verificar-credenciales')
  /// [queryParameters] - Parámetros de consulta opcionales
  ///
  /// Retorna el cuerpo decodificado como JSON (Map o List).
  /// Lanza [ApiException] en caso de error HTTP o de red.
  Future<dynamic> get({
    required String endpoint,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters: queryParameters);

    try {
      final response = await _client.get(uri).timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición POST con cuerpo JSON.
  ///
  /// [endpoint] - Ruta del endpoint
  /// [body] - Mapa que se serializará a JSON
  ///
  /// Retorna el cuerpo decodificado como JSON.
  /// Lanza [ApiException] en caso de error.
  Future<dynamic> postJson({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final uri = _buildUri(endpoint);

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición POST multipart/form-data.
  ///
  /// [endpoint] - Ruta del endpoint
  /// [fields] - Campos de formulario (clave-valor string)
  /// [files] - Archivos a subir (lista de MultipartFile)
  ///
  /// Retorna el cuerpo decodificado como JSON.
  /// Lanza [ApiException] en caso de error.
  Future<dynamic> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final uri = _buildUri(endpoint);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Realiza una petición POST con cuerpo binario (para OCR de cédula).
  ///
  /// [endpoint] - Ruta del endpoint
  /// [bytes] - Bytes de la imagen
  /// [filename] - Nombre del archivo
  /// [contentType] - Tipo MIME del archivo (ej. image/jpeg, image/png, image/webp)
  ///
  /// Retorna el cuerpo decodificado como JSON.
  /// Lanza [ApiException] en caso de error.
  Future<dynamic> postBinary({
    required String endpoint,
    required List<int> bytes,
    String filename = 'cedula.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final uri = _buildUri(endpoint);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: http.MediaType.parse(contentType),
        ),
      );

      // Timeout mayor para OCR (puede tardar más)
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Procesa la respuesta HTTP y lanza excepción si hay error.
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (e) {
        throw ApiException(
          statusCode: statusCode,
          message: 'Respuesta inválida del servidor',
          detail: body,
        );
      }
    }

    // Intentar extraer el detalle del error del cuerpo JSON
    String detail = body;
    try {
      final json = jsonDecode(body);
      if (json is Map && json.containsKey('detail')) {
        detail = json['detail'].toString();
      }
    } catch (_) {
      // Si no es JSON válido, usar el cuerpo crudo
    }

    throw ApiException(
      statusCode: statusCode,
      message: _httpStatusMessage(statusCode),
      detail: detail,
    );
  }

  /// Mensaje legible para códigos de estado HTTP comunes.
  String _httpStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud incorrecta';
      case 401:
        return 'No autorizado';
      case 404:
        return 'No encontrado';
      case 422:
        return 'Datos inválidos';
      case 500:
        return 'Error interno del servidor';
      case 0:
        return 'Error de red o timeout';
      default:
        return 'Error HTTP $statusCode';
    }
  }

  /// Cierra el cliente HTTP.
  void dispose() {
    _client.close();
  }
}