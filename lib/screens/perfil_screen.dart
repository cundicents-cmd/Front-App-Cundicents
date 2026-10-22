import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/reporte_service.dart';
import '../../models/usuario.dart';
import '../../models/reporte.dart';
import 'editar_datos_personales_screen.dart';
import 'cambiar_contrasena_screen.dart';
import 'soporte_ayuda_screen.dart';
import 'login_screen.dart';

/// Pantalla principal de Perfil con opciones: Editar datos, Cambiar contraseña, Soporte y ayuda.
class PerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const PerfilScreen({super.key, required this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  int _reportesTotal = 0;
  int _reportesResueltos = 0;
  int _reportesPendientes = 0;

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
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final reporteService = ReporteService();
      
      // Cargar ambos tipos de reportes en paralelo
      final resultados = await Future.wait([
        reporteService.obtenerReportesPendientes(widget.usuario.idUsuario),
        reporteService.obtenerReportesHistoricos(widget.usuario.idUsuario),
      ]);
      
      final reportesPendientes = resultados[0] as List<ReportePendiente>;
      final reportesHistoricos = resultados[1] as List<ReporteHistorico>;
      
      if (mounted) {
        setState(() {
          _reportesTotal = reportesPendientes.length + reportesHistoricos.length;
          _reportesResueltos = reportesHistoricos.length; // Los historicos son los resueltos
          _reportesPendientes = reportesPendientes.where((r) => r.estaPendiente).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: _rojo, size: 28),
            const SizedBox(width: 12),
            const Text('Cerrar sesión', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: _gris, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cerrar sesión', style: TextStyle(color: _rojo, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crema,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final horizontalPadding = isWide ? 24.0 : 16.0;
            final maxWidth = isWide ? 430.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: _crema,
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

                      // Contenido principal
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingState()
                            : SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: 16,
                                ),
                                child: _buildContent(),
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
        color: _rojo,
        borderRadius: BorderRadius.only(
          bottomLeft: const Radius.circular(22),
          bottomRight: const Radius.circular(22),
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
                  'Perfil',
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
                  'Configuración de tu cuenta',
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
            errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 80, color: _rojo),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(color: _rojo, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: 16, color: _gris, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tarjeta de perfil
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: _rojo, width: 5)),
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
              // Avatar
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rojo,
                  border: Border.all(color: _amarillo, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _rojo.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.usuario.iniciales,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nombre
              Text(
                widget.usuario.nombreCompleto,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),

              // Correo
              Text(
                widget.usuario.correo,
                style: TextStyle(
                  fontSize: 12,
                  color: _gris,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Badge de rol
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _crema2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: _rojo, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Ciudadano registrado',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A6D00),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Estadísticas
        if (!_isLoading)
          Row(
            children: [
              _buildStatCard('Reportes', _reportesTotal.toString(), _rojo),
              const SizedBox(width: 10),
              _buildStatCard('Resueltos', _reportesResueltos.toString(), _verde),
              const SizedBox(width: 10),
              _buildStatCard('Pendientes', _reportesPendientes.toString(), _amarillo),
            ],
          )
        else
          const SizedBox(height: 16),

        const SizedBox(height: 12),

        // Opciones del perfil
        _buildOptionCard(
          icon: Icons.edit_outlined,
          title: 'Editar datos personales',
          subtitle: 'Nombres, apellidos y correo',
          color: _rojo,
          onTap: () => _navegarAEditarDatos(),
        ),
        const SizedBox(height: 12),

        _buildOptionCard(
          icon: Icons.lock_outline,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          color: _amarillo,
          onTap: () => _navegarACambiarContrasena(),
        ),
        const SizedBox(height: 12),

        _buildOptionCard(
          icon: Icons.help_outline,
          title: 'Soporte y ayuda',
          subtitle: 'Contacto y preguntas frecuentes',
          color: _gris,
          onTap: () => _navegarASoporteAyuda(),
        ),

        const SizedBox(height: 24),

        // Botón cerrar sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cerrarSesion,
            style: OutlinedButton.styleFrom(
              foregroundColor: _rojo,
              side: BorderSide(color: _rojo, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 20),
                const SizedBox(width: 9),
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Versión
        Text(
          'Cundicents v1.0.0',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB9B09A),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(top: BorderSide(color: color, width: 4)),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _gris,
                letterSpacing: 0.4,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borde.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: _gris,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _borde, size: 22),
          ],
        ),
      ),
    );
  }

  void _navegarAEditarDatos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarDatosPersonalesScreen(usuario: widget.usuario),
      ),
    );
  }

  void _navegarACambiarContrasena() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CambiarContrasenaScreen(usuario: widget.usuario),
      ),
    );
  }

  void _navegarASoporteAyuda() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoporteAyudaScreen(usuario: widget.usuario),
      ),
    );
  }
}