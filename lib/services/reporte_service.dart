import '../config/api_config.dart';
import '../models/reporte.dart';
import 'api_service.dart';

/// Servicio para consultar reportes (pendientes e históricos).
class ReporteService {
  final ApiService _apiService = ApiService();

  /// Obtiene la lista de reportes pendientes del usuario.
  ///
  /// Llama a `GET /reportes/usuario/{id_usuario}`.
  ///
  /// Retorna una lista de [ReportePendiente].
  /// Lanza [ApiException] en caso de error.
  Future<List<ReportePendiente>> obtenerReportesPendientes(
    int idUsuario,
  ) async {
    final response = await _apiService.get(
      endpoint: '${ApiEndpoints.getUserReports}/$idUsuario',
    );

    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((json) => ReportePendiente.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene la lista de reportes completos/históricos del usuario.
  ///
  /// Llama a `GET /historico/usuario/{user_id}`.
  ///
  /// Retorna una lista de [ReporteHistorico].
  /// Lanza [ApiException] en caso de error.
  Future<List<ReporteHistorico>> obtenerReportesHistoricos(int userId) async {
    final response = await _apiService.get(
      endpoint: '${ApiEndpoints.getHistorico}/$userId',
    );

    final List<dynamic> data = response as List<dynamic>;

    return data
        .map((json) => ReporteHistorico.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el detalle completo de un reporte pendiente por su ID.
  ///
  /// Llama a `GET /reportes/usuario/{id_usuario}` y busca el reporte por ID.
  ///
  /// Retorna el [ReportePendiente] completo o null si no se encuentra.
  /// Lanza [ApiException] en caso de error.
  Future<ReportePendiente?> obtenerDetalleReportePendiente(
    int idUsuario,
    int reporteId,
  ) async {
    final reportes = await obtenerReportesPendientes(idUsuario);
    try {
      return reportes.firstWhere((r) => r.id == reporteId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el detalle completo de un reporte histórico por su ID.
  ///
  /// Llama a `GET /historico/usuario/{user_id}` y busca el reporte por ID.
  ///
  /// Retorna el [ReporteHistorico] completo o null si no se encuentra.
  /// Lanza [ApiException] en caso de error.
  Future<ReporteHistorico?> obtenerDetalleReporteHistorico(
    int userId,
    int reporteId,
  ) async {
    final reportes = await obtenerReportesHistoricos(userId);
    try {
      return reportes.firstWhere((r) => r.id == reporteId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la lista de evidencias como URLs a partir del objeto evidencias.
  ///
  /// El campo evidencias de la API es un objeto JSON donde las claves son
  /// nombres de archivo y los valores son URLs.
  ///
  /// Retorna una lista de URLs de imágenes.
  static List<String> extraerEvidenciasUrls(Map<String, dynamic>? evidencias) {
    if (evidencias == null || evidencias.isEmpty) return [];
    return evidencias.values.map((e) => e as String).toList();
  }

  void dispose() {
    // No hay recursos que liberar específicamente en este servicio
  }
}
