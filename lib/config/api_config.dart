/// Configuración centralizada de la API de Cundicents.
///
/// Permite modificar la URL base de la API desde un solo lugar
/// cuando se despliegue el backend en producción.
class ApiConfig {
  /// URL base de la API FastAPI.
  /// En desarrollo local: http://localhost:8000
  /// En producción: cambiar a la URL del servidor desplegado (ej. https://api.cundicents.com)
  static const String baseUrl = 'http://192.168.1.24:8000';

  /// Construye la URL completa para un endpoint.
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Construye la URL completa para un endpoint con parámetro de ruta.
  static String buildUrlWithId(String endpoint, int id) {
    return '$baseUrl$endpoint/$id';
  }
}

/// Rutas de los endpoints de la API centralizadas.
class ApiEndpoints {
  // Autenticación y usuarios
  static const String register = '/users/register';
  static const String login = '/users/login';
  static const String verificarCredenciales = '/users/verificar-credenciales';
  static const String getUser = '/users';
  static const String updatePassword = '/users';
  static const String updateUser = '/users';

  // Reportes
  static const String createReport = '/reportes/';
  static const String getUserReports = '/reportes/usuario';

  // Incidentes
  static const String getIncidentes = '/incidentes/';

  // Histórico
  static const String getHistorico = '/historico/usuario';

  // OCR Cédula
  static const String extraerCedula = '/cedula/extraer';
}