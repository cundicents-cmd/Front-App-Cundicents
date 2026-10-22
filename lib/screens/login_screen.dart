import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'registro_screen.dart';
import 'menu_screen.dart';

/// Pantalla de inicio de sesión de Cundicents.
///
/// Reproduce el diseño visual de Login.html utilizando widgets nativos de Flutter.
/// Incluye validación, indicadores de carga, navegación a registro y recuperación de contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Colores institucionales (extraídos de Login.html)
  static const Color _rojo = Color(0xFFD71920);
  static const Color _crema = Color(0xFFFFF8D6);
  static const Color _crema2 = Color(0xFFF5F0E1);
  static const Color _texto = Color(0xFF1E1E1E);
  static const Color _gris = Color(0xFF7A7360);
  static const Color _borde = Color(0xFFE6E0C9);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _authService.dispose();
    super.dispose();
  }

  /// Valida el formato del correo electrónico.
  String? _validarCorreo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Valida la contraseña.
  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    return null;
  }

  /// Muestra un SnackBar con mensaje de error.
  void _mostrarError(String mensaje) {
    if (!mounted) return;
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

  /// Muestra un SnackBar con mensaje de éxito.
  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFF6C8B3F), // verde institucional
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Maneja el envío del formulario de login.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await _authService.loginYGuardarSesion(
        correo: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      _mostrarExito('Bienvenido, ${usuario.nombreCompleto}');

      // Navegar al menú principal y limpiar la pila de navegación
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        _mostrarError('Correo o contraseña incorrectos');
      } else if (e.statusCode == 0) {
        _mostrarError('Error de conexión. Verifica tu internet e inténtalo de nuevo.');
      } else {
        _mostrarError('Error: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Navega a la pantalla de registro.
  void _irARegistro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  /// Muestra el diálogo de recuperación de contraseña.
  void _mostrarRecuperarPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.key_outlined, color: _rojo, size: 28),
            const SizedBox(width: 12),
            const Text('Recuperar contraseña', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Para recuperar tu contraseña, debes acceder a cundicents.com y seguir el proceso de recuperación de cuenta.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido', style: TextStyle(color: _rojo, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crema,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final horizontalPadding = isWide ? 24.0 : 18.0;
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

                      // Contenido scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 22,
                          ),
                          child: _buildLoginCard(horizontalPadding),
                        ),
                      ),

                      // Enlaces inferiores
                      _buildBottomLinks(horizontalPadding),
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
        MediaQuery.of(context).padding.top + 22,
        horizontalPadding,
        22,
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
          // Logo
          Image.asset(
            'assets/log.png',
            width: 54,
            height: 54,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Accede al sistema de reportes',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildLoginCard(double horizontalPadding) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: _rojo, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de login
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _crema2,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, color: _rojo, size: 28),
            ),

            // Título
            const Text(
              'Bienvenido de nuevo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _texto,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresa tus credenciales para continuar',
              style: TextStyle(
                fontSize: 12.5,
                color: _gris,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // Campo: Correo electrónico
            _buildField(
              label: 'Correo electrónico',
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocus: _passwordFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline,
              validator: _validarCorreo,
            ),
            const SizedBox(height: 16),

            // Campo: Contraseña
            _buildPasswordField(
              label: 'Contraseña',
              controller: _passwordController,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 16),

            // Botón principal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rojo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _rojo.withValues(alpha: 0.7),
                  elevation: 0,
                  shadowColor: _rojo.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_outlined, size: 20),
                          const SizedBox(width: 9),
                          const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted ??
              (value) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: _texto),
          decoration: InputDecoration(
            hintText: _getHintText(label),
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFFB9B09A), size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borde, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borde, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            errorStyle: TextStyle(color: _rojo, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputAction textInputAction = TextInputAction.done,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: _obscurePassword,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: _validarPassword,
          style: const TextStyle(fontSize: 13.5, color: _texto),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
            prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFFB9B09A), size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: _gris,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borde, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borde, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _rojo, width: 1.5),
            ),
            errorStyle: TextStyle(color: _rojo, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Correo electrónico':
        return 'Ej. juan.perez@correo.hn';
      case 'Contraseña':
        return '••••••••';
      default:
        return '';
    }
  }

  Widget _buildBottomLinks(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      child: Column(
        children: [
          // Separador "o"
          Row(
            children: [
              Expanded(child: Divider(color: _borde, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: TextStyle(
                    color: const Color(0xFFC9C2AE),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(child: Divider(color: _borde, thickness: 1)),
            ],
          ),
          const SizedBox(height: 14),

          // Botón: Crear cuenta
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _irARegistro,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                foregroundColor: _rojo,
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Crear una cuenta nueva',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Botón: Recuperar contraseña
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _mostrarRecuperarPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                foregroundColor: _rojo,
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}