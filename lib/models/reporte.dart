/// Modelo para reportes pendientes (desde /reportes/usuario/{id_usuario})
class ReportePendiente {
  final int id;
  final int idUsuario;
  final String usuario;
  final int idIncidente;
  final String incidente;
  final int idMunicipio;
  final String municipio;
  final int? idSector;
  final String? sector;
  final int idPrioridad;
  final String tpPrioridad;
  final int idEstado;
  final String estado;
  final String descripcion;
  final DateTime fechaHora;
  final Map<String, dynamic>? ubicacion;
  final Map<String, dynamic>? evidencias;

  ReportePendiente({
    required this.id,
    required this.idUsuario,
    required this.usuario,
    required this.idIncidente,
    required this.incidente,
    required this.idMunicipio,
    required this.municipio,
    this.idSector,
    this.sector,
    required this.idPrioridad,
    required this.tpPrioridad,
    required this.idEstado,
    required this.estado,
    required this.descripcion,
    required this.fechaHora,
    this.ubicacion,
    this.evidencias,
  });

  factory ReportePendiente.fromJson(Map<String, dynamic> json) {
    return ReportePendiente(
      id: json['id'] as int,
      idUsuario: json['id_usuario'] as int,
      usuario: json['usuario'] as String,
      idIncidente: json['id_incidente'] as int,
      incidente: json['incidente'] as String,
      idMunicipio: json['id_municipio'] as int,
      municipio: json['municipio'] as String,
      idSector: json['id_sector'] as int?,
      sector: json['sector'] as String?,
      idPrioridad: json['id_prioridad'] as int,
      tpPrioridad: json['tp_prioridad'] as String,
      idEstado: json['id_estado'] as int,
      estado: json['estado'] as String,
      descripcion: json['descripcion'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      ubicacion: json['ubicacion']?.cast<String, dynamic>(),
      evidencias: json['evidencias']?.cast<String, dynamic>(),
    );
  }

  /// Determina si el reporte está pendiente (estado "Pendiente")
  bool get estaPendiente => estado.toLowerCase() == 'pendiente';

  /// Determina si el reporte está resuelto
  bool get estaResuelto => estado.toLowerCase() == 'resuelto';

  /// Obtiene la primera URL de evidencia si existe
  String? get primeraEvidenciaUrl {
    if (evidencias != null && evidencias!.isNotEmpty) {
      return evidencias!.values.first as String?;
    }
    return null;
  }

  /// Obtiene todas las URLs de evidencias
  List<String> get evidenciasUrls {
    if (evidencias != null && evidencias!.isNotEmpty) {
      return evidencias!.values.map((e) => e as String).toList();
    }
    return [];
  }

  /// Obtiene el nombre del icono según el tipo de incidente
  String get iconoIncidente {
    final lower = incidente.toLowerCase();
    if (lower.contains('robo') || lower.contains('hurto')) return '🔒';
    if (lower.contains('accidente') || lower.contains('vial')) return '🚗';
    if (lower.contains('incendio')) return '🔥';
    if (lower.contains('violencia')) return '⚔️';
    if (lower.contains('desastre') || lower.contains('natural')) return '🌊';
    if (lower.contains('inundaci') || lower.contains('inundación')) return '🌊';
    if (lower.contains('derrumbe')) return '🏔️';
    if (lower.contains('gas')) return '⛽';
    if (lower.contains('energ') || lower.contains('corte')) return '⚡';
    if (lower.contains('agua')) return '💧';
    if (lower.contains('alumbrado') || lower.contains('luz')) return '💡';
    if (lower.contains('animal')) return '🐾';
    if (lower.contains('contamin')) return '💨';
    if (lower.contains('médica') || lower.contains('emergencia')) return '🚑';
    return '⚠️';
  }

  /// Color del badge según el estado
  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return '#F5C400'; // Amarillo
      case 'resuelto':
        return '#6C8B3F'; // Verde
      default:
        return '#D71920'; // Rojo por defecto
    }
  }
}

/// Modelo para reportes completos/históricos (desde /historico/usuario/{user_id})
class ReporteHistorico {
  final int id;
  final String ccUsuario;
  final String tipoIncidente;
  final String incidente;
  final String municipio;
  final String? sector;
  final String prioridad;
  final String estado;
  final String descripcion;
  final DateTime fechaHora;
  final Map<String, dynamic>? ubicacion;
  final Map<String, dynamic>? evidencias;

  ReporteHistorico({
    required this.id,
    required this.ccUsuario,
    required this.tipoIncidente,
    required this.incidente,
    required this.municipio,
    this.sector,
    required this.prioridad,
    required this.estado,
    required this.descripcion,
    required this.fechaHora,
    this.ubicacion,
    this.evidencias,
  });

  factory ReporteHistorico.fromJson(Map<String, dynamic> json) {
    return ReporteHistorico(
      id: json['id'] as int,
      ccUsuario: json['cc_usuario'].toString(),
      tipoIncidente: json['tipo_incidente'] as String,
      incidente: json['incidente'] as String,
      municipio: json['municipio'] as String,
      sector: json['sector'] as String?,
      prioridad: json['prioridad'] as String,
      estado: json['estado'] as String,
      descripcion: json['descripcion'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      ubicacion: json['ubicacion']?.cast<String, dynamic>(),
      evidencias: json['evidencias']?.cast<String, dynamic>(),
    );
  }

  /// Determina si el reporte está resuelto
  bool get estaResuelto => estado.toLowerCase() == 'resuelto';

  /// Obtiene todas las URLs de evidencias
  List<String> get evidenciasUrls {
    if (evidencias != null && evidencias!.isNotEmpty) {
      return evidencias!.values.map((e) => e as String).toList();
    }
    return [];
  }

  /// Obtiene la primera URL de evidencia si existe
  String? get primeraEvidenciaUrl {
    if (evidencias != null && evidencias!.isNotEmpty) {
      return evidencias!.values.first as String?;
    }
    return null;
  }

  /// Obtiene el icono según el tipo de incidente
  String get iconoIncidente {
    final lower = incidente.toLowerCase();
    if (lower.contains('robo') || lower.contains('hurto')) return '🔒';
    if (lower.contains('accidente') || lower.contains('vial')) return '🚗';
    if (lower.contains('incendio')) return '🔥';
    if (lower.contains('violencia')) return '⚔️';
    if (lower.contains('desastre') || lower.contains('natural')) return '🌊';
    if (lower.contains('inundaci') || lower.contains('inundación')) return '🌊';
    if (lower.contains('derrumbe')) return '🏔️';
    if (lower.contains('gas')) return '⛽';
    if (lower.contains('energ') || lower.contains('corte')) return '⚡';
    if (lower.contains('agua')) return '💧';
    if (lower.contains('alumbrado') || lower.contains('luz')) return '💡';
    if (lower.contains('animal')) return '🐾';
    if (lower.contains('contamin')) return '💨';
    if (lower.contains('médica') || lower.contains('emergencia')) return '🚑';
    return '⚠️';
  }

  /// Color del badge según el estado
  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return '#F5C400'; // Amarillo
      case 'resuelto':
        return '#6C8B3F'; // Verde
      default:
        return '#D71920'; // Rojo por defecto
    }
  }
}

/// Respuesta para la creación de reportes
class ReporteCreateResponse {
  final int idReporte;
  final String mensaje;
  final String? municipio;
  final Map<String, String>? evidencias;
  final String? mensajeEvidencias;

  ReporteCreateResponse({
    required this.idReporte,
    required this.mensaje,
    this.municipio,
    this.evidencias,
    this.mensajeEvidencias,
  });

  factory ReporteCreateResponse.fromJson(Map<String, dynamic> json) {
    return ReporteCreateResponse(
      idReporte: json['id_reporte'] as int,
      mensaje: json['p_mensaje'] as String,
      municipio: json['municipio'] as String?,
      evidencias: json['evidencias'] != null
          ? Map<String, String>.from(json['evidencias'] as Map)
          : null,
      mensajeEvidencias: json['mensaje_evidencias'] as String?,
    );
  }
}