import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../models/usuario.dart';
import 'login_screen.dart';
import 'crear_reporte_screen.dart';

/// Pantalla principal (menú) de Cundicents tras autenticación exitosa.
///
/// Por ahora es una pantalla vacía funcional, preparada para agregar
/// futuras secciones (reportes, histórico, perfil, etc.).
/// Incluye acción de cerrar sesión.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService _authService = AuthService();
  Usuario? _usuario;
  bool _isLoading = true;

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
    _cargarUsuario();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  /// Carga los datos del usuario desde almacenamiento seguro y API.
  Future<void> _cargarUsuario() async {
    try {
      final idUsuario = await SecureStorageService.leerIdUsuario();
      final correo = await SecureStorageService.leerCorreo();
      final hashPassword = await SecureStorageService.leerHashPassword();

      if (idUsuario == null || correo == null || hashPassword == null) {
        // No hay sesión, redirigir al login
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Intentar obtener datos completos del usuario desde la API
      Usuario usuario;
      try {
        usuario = await _authService.obtenerUsuarioPorId(idUsuario);
      } catch (e) {
        // Si falla la API, crear usuario básico con datos almacenados
        usuario = Usuario(
          idUsuario: idUsuario,
          correo: correo,
          hashPassword: hashPassword,
        );
      }

      if (mounted) {
        setState(() {
          _usuario = usuario;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar datos: ${e.toString()}');
      }
    }
  }

  /// Cierra la sesión y navega al login.
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

  /// Navega a la pantalla de crear reporte.
  void _irACrearReporte() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CrearReporteScreen(usuario: _usuario!)),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

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
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 16,
                          ),
                          child: _buildContent(horizontalPadding),
                        ),
                      ),

                      // Navegación inferior
                      _buildBottomNav(),
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _crema,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/log.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.shield_outlined, size: 80, color: _rojo),
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
                  'Cundicents',
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
                  _usuario?.nombreCompleto ?? 'Usuario',
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

  Widget _buildContent(double horizontalPadding) {
    return Column(
      children: [
        // Tarjeta de bienvenida / perfil
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
                    _usuario?.iniciales ?? 'U',
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
                _usuario?.nombreCompleto ?? 'Usuario',
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
                _usuario?.correo ?? '',
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

        const SizedBox(height: 24),

        // Sección de módulos (vacía por ahora - placeholders)
        _buildSectionTitle('Módulos disponibles'),
        const SizedBox(height: 12),

        _buildModuleCard(
          icon: Icons.assignment_outlined,
          title: 'Reportar incidente',
          subtitle: 'Crear nuevo reporte',
          color: _rojo,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CrearReporteScreen(usuario: _usuario!),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        _buildModuleCard(
          icon: Icons.history_outlined,
          title: 'Historial de reportes',
          subtitle: 'Próximamente',
          color: _amarillo,
          onTap: () => _mostrarProximamente('Historial de reportes'),
        ),
        const SizedBox(height: 12),

        _buildModuleCard(
          icon: Icons.person_outlined,
          title: 'Mi perfil',
          subtitle: 'Próximamente',
          color: _verde,
          onTap: () => _mostrarProximamente('Mi perfil'),
        ),
        const SizedBox(height: 12),

        _buildModuleCard(
          icon: Icons.help_outline,
          title: 'Ayuda y soporte',
          subtitle: 'Próximamente',
          color: _gris,
          onTap: () => _mostrarProximamente('Ayuda y soporte'),
        ),

        const SizedBox(height: 30),

        // Botón de cerrar sesión
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _texto,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildModuleCard({
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

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borde.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, Icons.add_outlined, 'Crear', true, onTap: _irACrearReporte),
          _buildNavItem(1, Icons.history_outlined, 'Historial', false, onTap: () => _mostrarProximamente('Historial')),
          _buildNavItem(2, Icons.person_outlined, 'Usuario', false, onTap: () => _mostrarProximamente('Usuario')),
          _buildNavItem(3, Icons.logout, 'Salir', false, isLogout: true, onTap: _cerrarSesion),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive,
    {VoidCallback? onTap, bool isLogout = false}) {
    final Color itemColor = isLogout ? _rojo : (isActive ? _rojo : const Color(0xFF9A9276));
    final Color backgroundColor = isActive ? const Color(0xFFFDF6D9) : Colors.transparent;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: itemColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarProximamente(String modulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$modulo - Próximamente'),
        backgroundColor: _rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}