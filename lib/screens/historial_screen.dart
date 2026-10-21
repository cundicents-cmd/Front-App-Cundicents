import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../services/reporte_service.dart';
import '../../models/reporte.dart';
import '../../models/usuario.dart';
import 'login_screen.dart';
import 'detalle_reporte_screen.dart';

/// Pantalla principal de Historial con dos pestañas: Pendientes y Completos.
class HistorialScreen extends StatefulWidget {
  final Usuario usuario;

  const HistorialScreen({super.key, required this.usuario});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> with SingleTickerProviderStateMixin {
  final ReporteService _reporteService = ReporteService();
  late TabController _tabController;

  // Estados
  bool _isLoading = true;
  String? _errorMessage;
  List<ReportePendiente> _reportesPendientes = [];
  List<ReporteHistorico> _reportesCompletos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarReportes();
    tz.initializeTimeZones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar ambos tipos de reportes en paralelo
      final resultados = await Future.wait([
        _cargarReportesPendientes(),
        _cargarReportesCompletos(),
      ]);

      if (mounted) {
        setState(() {
          _reportesPendientes = resultados[0] as List<ReportePendiente>;
          _reportesCompletos = resultados[1] as List<ReporteHistorico>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar reportes: ${e.toString()}';
        });
      }
    }
  }

  Future<List<ReportePendiente>> _cargarReportesPendientes() async {
    final reportes = await _reporteService.obtenerReportesPendientes(widget.usuario.idUsuario);
    return reportes;
  }

  Future<List<ReporteHistorico>> _cargarReportesCompletos() async {
    return await _reporteService.obtenerReportesHistoricos(widget.usuario.idUsuario);
  }

  Future<void> _reintentarCarga() async {
    await _cargarReportes();
  }

  void _navegarADetallePendiente(ReportePendiente reporte) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleReporteScreen(
          reportePendiente: reporte,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  void _navegarADetalleHistorico(ReporteHistorico reporte) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleReporteScreen(
          reporteHistorico: reporte,
          usuario: widget.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D6), // Crema
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final maxWidth = isWide ? 430.0 : double.infinity;
            final horizontalPadding = isWide ? 24.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8D6),
                    borderRadius: isWide ? BorderRadius.circular(35) : null,
                    boxShadow: isWide
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 60,
                              offset: const Offset(0, 24),
                            ),
                            BoxShadow(
                              color: const Color(0xFF111111),
                              blurRadius: 0,
                              spreadRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(horizontalPadding),

                      // Segment control (pestañas) - Debajo del header
                      _buildTabSelector(),

                      // Contenido principal
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingState()
                            : _errorMessage != null
                                ? _buildErrorState()
                                : _buildContent(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double horizontalPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        MediaQuery.of(context).padding.top + 14,
        horizontalPadding,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD71920), // Rojo institucional
        borderRadius: BorderRadius.only(
          bottomLeft: const Radius.circular(22),
          bottomRight: const Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD71920).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/log.png',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reportes pendientes y completados',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E1), // Crema2
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _tabController.index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD71920).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _buildTabButton(0, 'Pendientes', Icons.pending_outlined),
                _buildTabButton(1, 'Completos', Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          final isSelected = _tabController.index == index;
          return InkWell(
            onTap: () => _tabController.animateTo(index),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFFD71920)
                        : const Color(0xFF7A7360).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFD71920)
                          : const Color(0xFF7A7360).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/log.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.shield_outlined, size: 80, color: Color(0xFFD71920)),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: Color(0xFFD71920),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando historial...',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF7A7360),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/log.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shield_outlined, size: 80, color: Color(0xFFD71920)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: const Color(0xFFD71920), width: 5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: const Color(0xFFD71920),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo cargar el historial',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E1E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Error de conexión con el servidor',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF7A7360),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _irALogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7A7360),
                            side: const BorderSide(color: Color(0xFFE6E0C9), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reintentarCarga,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD71920),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text(
                            'Reintentar',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Segment control ya está en el header

        // Contenido de la pestaña activa
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListaReportes(_reportesPendientes, true),
              _buildListaReportes(_reportesCompletos, false),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildListaReportes(List<dynamic> reportes, bool esPendientes) {
    if (reportes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        titulo: 'Sin reportes',
        subtitulo: 'No hay reportes ${esPendientes ? 'pendientes' : 'completados'} registrados.',
      );
    }

    return RefreshIndicator(
      onRefresh: _reintentarCarga,
      color: const Color(0xFFD71920),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: reportes.length,
        itemBuilder: (context, index) {
          final reporte = reportes[index];
          final reportePendiente = esPendientes ? reporte as ReportePendiente : null;
          final reporteHistorico = !esPendientes ? reporte as ReporteHistorico : null;

          return _buildReportCard(reporte, esPendientes, reportePendiente, reporteHistorico);
        },
      ),
    );
  }

  Widget _buildReportCard(dynamic reporte, bool esPendiente, ReportePendiente? reportePendiente, ReporteHistorico? reporteHistorico) {
    final String incidente = reportePendiente?.incidente ?? reporteHistorico!.incidente;
    final String municipio = reportePendiente?.municipio ?? reporteHistorico!.municipio;
    final String sector = reportePendiente?.sector ?? reporteHistorico?.sector ?? '';
    final String estado = reportePendiente?.estado ?? reporteHistorico!.estado;
    final String prioridad = reportePendiente?.tpPrioridad ?? reporteHistorico!.prioridad;
    final DateTime fechaHora = reportePendiente?.fechaHora ?? reporteHistorico!.fechaHora;
    final String descripcion = reportePendiente?.descripcion ?? reporteHistorico!.descripcion;

    return InkWell(
      onTap: () {
        if (esPendiente) {
          _navegarADetallePendiente(reportePendiente!);
        } else {
          _navegarADetalleHistorico(reporteHistorico!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: esPendiente ? const Color(0xFFF5C400) : const Color(0xFF6C8B3F),
              width: 5,
            ),
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
            // Encabezado del reporte
            Row(
              children: [
                // Icono del incidente
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      reportePendiente?.iconoIncidente ?? reporteHistorico!.iconoIncidente,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidente,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Badges de estado y prioridad
                      Row(
                        children: [
                          _buildBadge(estado, _getEstadoColor(estado)),
                          const SizedBox(width: 6),
                          _buildBadge(prioridad, _getPrioridadColor(prioridad)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Flecha
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC9C2AE),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción (resumen)
            Text(
              descripcion.length > 100
                  ? '${descripcion.substring(0, 100)}...'
                  : descripcion,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF7A7360),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Meta información
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: const Color(0xFFB9B09A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sector.isNotEmpty ? '$municipio - $sector' : municipio,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7360),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time_outlined, size: 14, color: const Color(0xFFB9B09A)),
                const SizedBox(width: 4),
                Text(
                  _formatearFechaBogota(DateTime.parse(fechaHora.toString())),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A7360),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF5C400);
      case 'resuelto':
        return const Color(0xFF6C8B3F);
      case 'en proceso':
        return const Color(0xFFD71920);
      default:
        return const Color(0xFF7A7360);
    }
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return const Color(0xFFD71920);
      case 'media':
        return const Color(0xFFF5C400);
      case 'baja':
        return const Color(0xFF6C8B3F);
      default:
        return const Color(0xFF7A7360);
    }
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF7A7360)),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF7A7360),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFechaBogota(DateTime fecha) {
    // Convertir a zona horaria de Bogotá (UTC-5)
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
      // Fallback si falla la conversión de zona horaria
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

  void _irALogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}