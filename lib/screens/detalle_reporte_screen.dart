import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/reporte.dart';
import '../../models/usuario.dart';

/// Pantalla de detalle de reporte con mapa, galería de evidencias y información completa.
class DetalleReporteScreen extends StatefulWidget {
  final ReportePendiente? reportePendiente;
  final ReporteHistorico? reporteHistorico;
  final Usuario usuario;

  const DetalleReporteScreen({
    super.key,
    this.reportePendiente,
    this.reporteHistorico,
    required this.usuario,
  }) : assert((reportePendiente != null) != (reporteHistorico != null),
            'Debe proporcionar exactamente un reporte (pendiente o histórico)');

  @override
  State<DetalleReporteScreen> createState() => _DetalleReporteScreenState();
}

class _DetalleReporteScreenState extends State<DetalleReporteScreen> {
  late MapController _mapController;
  LatLng? _ubicacion;
  int _imagenActual = 0;
  bool _showLightbox = false;

  // Colores institucionales
  static const Color _rojo = Color(0xFFD71920);
  static const Color _amarillo = Color(0xFFF5C400);
  static const Color _crema = Color(0xFFFFF8D6);
  static const Color _crema2 = Color(0xFFF5F0E1);
  static const Color _texto = Color(0xFF1E1E1E);
  static const Color _gris = Color(0xFF7A7360);
  static const Color _borde = Color(0xFFE6E0C9);
  static const Color _verde = Color(0xFF6C8B3F);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    tz.initializeTimeZones();
    _procesarUbicacion();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _procesarUbicacion() {
    Map<String, dynamic>? ubicacion;
    if (widget.reportePendiente != null) {
      ubicacion = widget.reportePendiente!.ubicacion;
    } else if (widget.reporteHistorico != null) {
      ubicacion = widget.reporteHistorico!.ubicacion;
    }

    if (ubicacion != null) {
      final lat = ubicacion['latitud'] ?? ubicacion['lat'] ?? ubicacion['latitude'];
      final lng = ubicacion['longitud'] ?? ubicacion['lng'] ?? ubicacion['longitude'];
      if (lat != null && lng != null) {
        _ubicacion = LatLng((lat as num).toDouble(), (lng as num).toDouble());
      }
    }
  }

  String get _incidente => widget.reportePendiente?.incidente ?? widget.reporteHistorico!.incidente;
  String get _municipio => widget.reportePendiente?.municipio ?? widget.reporteHistorico!.municipio;
  String get _sector => widget.reportePendiente?.sector ?? widget.reporteHistorico?.sector ?? '';
  String get _estado => widget.reportePendiente?.estado ?? widget.reporteHistorico!.estado;
  String get _prioridad => widget.reportePendiente?.tpPrioridad ?? widget.reporteHistorico!.prioridad;
  DateTime get _fechaHora => widget.reportePendiente?.fechaHora ?? widget.reporteHistorico!.fechaHora;
  String get _descripcion => widget.reportePendiente?.descripcion ?? widget.reporteHistorico!.descripcion;
  String get _iconoIncidente => widget.reportePendiente?.iconoIncidente ?? widget.reporteHistorico!.iconoIncidente;
  Map<String, String> get _evidencias {
    final Map<String, dynamic>? rawEvidencias = widget.reportePendiente?.evidencias ?? widget.reporteHistorico!.evidencias;
    if (rawEvidencias == null || rawEvidencias.isEmpty) return {};
    return Map<String, String>.fromEntries(
      rawEvidencias.entries.map((e) => MapEntry(e.key, e.value as String)),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return _amarillo;
      case 'resuelto':
        return _verde;
      case 'en proceso':
        return _rojo;
      default:
        return _gris;
    }
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return _rojo;
      case 'media':
        return _amarillo;
      case 'baja':
        return _verde;
      default:
        return _gris;
    }
  }

  String _formatearFechaBogota(DateTime fecha) {
    try {
      final bogota = tz.getLocation('America/Bogota');
      final bogotaTime = tz.TZDateTime.from(fecha, bogota);

      final ahora = tz.TZDateTime.now(tz.getLocation('America/Bogota'));
      final diferencia = ahora.difference(bogotaTime);

      if (diferencia.inDays == 0) {
        return 'Hoy ${_formatearHora(bogotaTime)}';
      } else if (diferencia.inDays == 1) {
        return 'Ayer ${_formatearHora(bogotaTime)}';
      } else if (diferencia.inDays < 7) {
        return '${diferencia.inDays}d ${_formatearHora(bogotaTime)}';
      } else {
        return '${bogotaTime.day}/${bogotaTime.month}/${bogotaTime.year} ${_formatearHora(bogotaTime)}';
      }
    } catch (e) {
      return '${fecha.day}/${fecha.month}/${fecha.year} ${_formatearHora(fecha)}';
    }
  }

  String _formatearHora(DateTime fecha) {
    int hora = fecha.hour;
    final minutos = fecha.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'p. m.' : 'a. m.';
    if (hora == 0) hora = 12;
    if (hora > 12) hora -= 12;
    return '$hora:${minutos} $periodo';
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _abrirLightbox(int index) {
    setState(() {
      _imagenActual = index;
      _showLightbox = true;
    });
  }

  void _cerrarLightbox() {
    setState(() {
      _showLightbox = false;
    });
  }

  void _siguienteImagen() {
    if (_imagenActual < _evidencias.length - 1) {
      setState(() {
        _imagenActual++;
      });
    }
  }

  void _anteriorImagen() {
    if (_imagenActual > 0) {
      setState(() {
        _imagenActual--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final evidenciasList = _evidencias.entries.toList();

    return Scaffold(
      backgroundColor: _crema,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildMapCard(),
                        const SizedBox(height: 16),
                        if (evidenciasList.isNotEmpty) _buildEvidenciasCard(evidenciasList),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lightbox overlay
          if (_showLightbox) _buildLightbox(evidenciasList),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: _rojo,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: _rojo.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del reporte',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _incidente,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _crema2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_iconoIncidente, style: const TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: _rojo, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _crema2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(_iconoIncidente, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _incidente,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBadge(_estado, _getEstadoColor(_estado)),
                        const SizedBox(width: 8),
                        _buildBadge(_prioridad, _getPrioridadColor(_prioridad)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Descripción
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _gris,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _descripcion,
            style: const TextStyle(
              fontSize: 15,
              color: _texto,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Meta información
          _buildMetaRow(Icons.location_on_outlined, 'Ubicación', _sector.isNotEmpty ? '$_municipio - $_sector' : _municipio),
          const SizedBox(height: 10),
          _buildMetaRow(Icons.access_time_outlined, 'Fecha y hora', _formatearFechaBogota(_fechaHora)),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _borde),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _gris,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  color: _texto,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación en el mapa',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _texto,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 250,
              child: _ubicacion != null
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _ubicacion!,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cundicents.app',
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _ubicacion!,
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _rojo,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _rojo.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: _crema2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: _gris),
                            const SizedBox(height: 12),
                            Text(
                              'Ubicación no disponible',
                              style: TextStyle(
                                fontSize: 15,
                                color: _gris,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciasCard(List<MapEntry<String, String>> evidenciasList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidencias (${evidenciasList.length})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _texto,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: evidenciasList.length,
              itemBuilder: (context, index) {
                final entry = evidenciasList[index];
                return GestureDetector(
                  onTap: () => _abrirLightbox(index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borde),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            entry.value,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: _crema2,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _rojo,
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: _crema2,
                              child: Icon(Icons.broken_image_outlined, color: _gris, size: 32),
                            ),
                          ),
                          // Indicador de zoom
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightbox(List<MapEntry<String, String>> evidenciasList) {
    final entry = evidenciasList[_imagenActual];

    return GestureDetector(
      onTap: _cerrarLightbox,
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: Stack(
          children: [
            // Imagen centrada
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  entry.value,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: _rojo,
                        strokeWidth: 3,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: _gris, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudo cargar la imagen',
                        style: TextStyle(color: _gris, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: _cerrarLightbox,
              ),
            ),
            // Navegación anterior
            if (_imagenActual > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                    onPressed: _anteriorImagen,
                  ),
                ),
              ),
            // Navegación siguiente
            if (_imagenActual < evidenciasList.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                    onPressed: _siguienteImagen,
                  ),
                ),
              ),
            // Contador
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_imagenActual + 1} / ${evidenciasList.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Nombre del archivo
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}