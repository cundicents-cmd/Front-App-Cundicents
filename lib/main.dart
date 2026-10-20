import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const CundicentsApp());
}

/// Estados de la verificación de autenticación inicial.
enum _AuthState {
  checking,        // Verificando sesión almacenada
  unauthenticated, // No hay sesión o inválida -> Login
  authenticated,   // Sesión válida -> Menu
  error,           // Error de red al verificar
}

/// Aplicación principal de Cundicents.
class CundicentsApp extends StatelessWidget {
  const CundicentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cundicents',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD71920), // Rojo institucional
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8D6), // Crema
        fontFamily: 'system-ui',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD71920),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD71920),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E0C9), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E0C9), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD71920), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD71920), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD71920), width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFD71920), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentTextStyle: const TextStyle(fontSize: 13),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const _AuthWrapper(),
    );
  }
}

/// Widget que decide qué pantalla mostrar según el estado de autenticación.
///
/// Implementa el flujo de inicio:
/// 1. Verifica si hay credenciales almacenadas
/// 2. Si no hay -> LoginScreen
/// 3. Si hay -> Verifica con API (verificar-credenciales)
///    - Válidas (1) -> MenuScreen
///    - Inválidas (0) -> Borra credenciales -> LoginScreen
///    - Error de red -> Muestra error, permite reintentar -> LoginScreen
class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  final AuthService _authService = AuthService();

  _AuthState _currentState = _AuthState.checking;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificarSesionInicial();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  /// Verifica la sesión al iniciar la app.
  Future<void> _verificarSesionInicial() async {
    // 1. Comprobar si existen credenciales almacenadas
    final tieneSesion = await SecureStorageService.existeSesionCompleta();

    if (!tieneSesion) {
      // Caso A: No hay credenciales -> Login directo
      if (mounted) {
        setState(() => _currentState = _AuthState.unauthenticated);
      }
      return;
    }

    // Caso B: Hay credenciales -> Verificar con API
    if (mounted) {
      setState(() => _currentState = _AuthState.checking);
    }

    try {
      final esValida = await _authService.verificarSesionAlmacenada();

      if (mounted) {
        if (esValida) {
          setState(() => _currentState = _AuthState.authenticated);
        } else {
          // Credenciales inválidas -> limpiar y ir a login
          await SecureStorageService.limpiarSesion();
          setState(() => _currentState = _AuthState.unauthenticated);
        }
      }
    } on ApiException catch (e) {
      // Error de red/servidor -> NO borrar credenciales, mostrar error
      if (mounted) {
        if (e.statusCode == 401) {
          // El backend respondió 401 explícitamente (credenciales inválidas)
          await SecureStorageService.limpiarSesion();
          setState(() => _currentState = _AuthState.unauthenticated);
        } else {
          // Error de conexión, timeout, 500, etc.
          setState(() {
            _currentState = _AuthState.error;
            _errorMessage = e.message;
          });
        }
      }
    } catch (e) {
      // Error inesperado
      if (mounted) {
        setState(() {
          _currentState = _AuthState.error;
          _errorMessage = 'Error inesperado: ${e.toString()}';
        });
      }
    }
  }

  /// Reintenta la verificación de sesión (botón en pantalla de error).
  Future<void> _reintentarVerificacion() async {
    await _verificarSesionInicial();
  }

  /// Navega al login (desde pantalla de error).
  void _irALogin() {
    setState(() => _currentState = _AuthState.unauthenticated);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case _AuthState.checking:
        return _buildLoadingScreen('Verificando sesión...');
      case _AuthState.authenticated:
        return const MenuScreen();
      case _AuthState.unauthenticated:
        return const LoginScreen();
      case _AuthState.error:
        return _buildErrorScreen();
    }
  }

  Widget _buildLoadingScreen(String mensaje) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D6),
      body: Center(
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
              mensaje,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF7A7360),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D6),
      body: SafeArea(
        child: Center(
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
                        'No se pudo verificar la sesión',
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
                              onPressed: _reintentarVerificacion,
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
        ),
      ),
    );
  }
}