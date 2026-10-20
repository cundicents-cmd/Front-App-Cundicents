/// Modelo de datos para un usuario de Cundicents.
class Usuario {
  final int idUsuario;
  final String correo;
  final String hashPassword;
  final String? nombre;
  final String? apellido;
  final int? cedula;

  Usuario({
    required this.idUsuario,
    required this.correo,
    required this.hashPassword,
    this.nombre,
    this.apellido,
    this.cedula,
  });

  /// Crea un Usuario a partir del JSON devuelto por el endpoint de login
  /// (/users/login o /users/verificar-credenciales).
  factory Usuario.fromLoginResponse(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int,
      correo: json['correo'] as String,
      hashPassword: json['hash_password'] as String,
    );
  }

  /// Crea un Usuario a partir del JSON devuelto por el endpoint GET /users/{user_id}.
  factory Usuario.fromDetailResponse(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: 0, // El ID no viene en este endpoint, se debe pasar por separado
      correo: json['email'] as String,
      hashPassword: '', // No se expone en este endpoint
      nombre: json['first_name'] as String?,
      apellido: json['last_name'] as String?,
      cedula: json['cedula'] as int?,
    );
  }

  /// Convierte el usuario a un mapa para almacenamiento seguro.
  Map<String, String> toSecureStorageMap() {
    return {
      'id_usuario': idUsuario.toString(),
      'correo': correo,
      'hash_password': hashPassword,
    };
  }

  /// Nombre completo del usuario.
  String get nombreCompleto {
    final parts = <String>[];
    if (nombre != null && nombre!.isNotEmpty) parts.add(nombre!);
    if (apellido != null && apellido!.isNotEmpty) parts.add(apellido!);
    return parts.isNotEmpty ? parts.join(' ') : correo;
  }

  /// Iniciales para el avatar.
  String get iniciales {
    final parts = <String>[];
    if (nombre != null && nombre!.isNotEmpty) parts.add(nombre![0].toUpperCase());
    if (apellido != null && apellido!.isNotEmpty) parts.add(apellido![0].toUpperCase());
    return parts.isNotEmpty ? parts.join() : correo[0].toUpperCase();
  }

  @override
  String toString() {
    return 'Usuario(idUsuario: $idUsuario, correo: $correo, nombre: $nombre, apellido: $apellido, cedula: $cedula)';
  }
}

/// Respuesta del endpoint de registro de usuario.
class RegisterResponse {
  final String mensaje;

  RegisterResponse({required this.mensaje});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(mensaje: json['p_mensaje'] as String);
  }
}

/// Respuesta del endpoint de verificación de credenciales.
class VerificarCredencialesResponse {
  final int pExiste;
  final String mensaje;

  VerificarCredencialesResponse({
    required this.pExiste,
    required this.mensaje,
  });

  factory VerificarCredencialesResponse.fromJson(Map<String, dynamic> json) {
    return VerificarCredencialesResponse(
      pExiste: json['p_existe'] as int,
      mensaje: json['mensaje'] as String,
    );
  }

  bool get credencialesValidas => pExiste == 1;
}

/// Datos extraídos de una cédula mediante OCR.
class CedulaData {
  final String nombres;
  final String apellidos;
  final String numeroDocumento;

  CedulaData({
    required this.nombres,
    required this.apellidos,
    required this.numeroDocumento,
  });

  factory CedulaData.fromJson(Map<String, dynamic> json) {
    return CedulaData(
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      numeroDocumento: json['numero_documento'] as String,
    );
  }

  int get cedulaComoInt => int.tryParse(numeroDocumento) ?? 0;
}

/// Tipo de incidente disponible en el catálogo.
class Incidente {
  final int id;
  final String incidente;
  final int idTpIncidente;
  final int idPrioridad;

  Incidente({
    required this.id,
    required this.incidente,
    required this.idTpIncidente,
    required this.idPrioridad,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id'] as int,
      incidente: json['incidente'] as String,
      idTpIncidente: json['id_tp_incidente'] as int,
      idPrioridad: json['id_prioridad'] as int,
    );
  }

  @override
  String toString() => 'Incidente(id: $id, nombre: $incidente)';
}

/// Respuesta del endpoint de creación de reporte.
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