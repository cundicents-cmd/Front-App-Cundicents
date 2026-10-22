import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../models/usuario.dart';
import 'perfil_screen.dart';

/// Pantalla para cambiar la contraseña del usuario autenticado.
class CambiarContrasenaScreen extends StatefulWidget {
  final Usuario usuario;

  const CambiarContrasenaScreen({super.key, required this.usuario});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _isSaving = false;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  String? _errorMessage;

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
  void dispose() {
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _authService.actualizarPassword(
        userId: widget.usuario.idUsuario,
        newPassword: _nuevaContrasenaController.text,
      );

      if (mounted) {
        _mostrarExito(context, 'Contraseña actualizada correctamente');
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _extraerMensajeError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _extraerMensajeError(Exception e) {
    final mensaje = e.toString();
    if (mensaje.contains('422') || mensaje.contains('validación')) {
      return 'La contraseña no cumple los requisitos (mínimo 8 caracteres, máximo 16).';
    } else if (mensaje.contains('404')) {
      return 'Usuario no encontrado.';
    } else if (mensaje.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    } else if (mensaje.contains('conexión') || mensaje.contains('timeout')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return 'Error al cambiar contraseña: $mensaje';
  }

  String? _validarNuevaContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'La nueva contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (value.length > 16) {
      return 'Máximo 16 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos 1 mayúscula';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos 1 minúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos 1 número';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos 1 caracter especial';
    }
    return null;
  }

  String? _validarConfirmarContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la nueva contraseña';
    }
    if (value != _nuevaContrasenaController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
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

                      // Contenido
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 16,
                            ),
                            child: _buildForm(),
                          ),
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cambiar contraseña',
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
                  'Ingresa y confirma tu nueva contraseña',
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta informativa
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rojo.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.lock_outline, color: _rojo, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Cambiar contraseña',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'La nueva contraseña debe tener al menos 6 caracteres. No uses contraseñas que hayas usado antes.',
                style: TextStyle(
                  fontSize: 12,
                  color: _gris,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Campo nueva contraseña
        _buildPasswordField(
          label: 'Nueva contraseña',
          controller: _nuevaContrasenaController,
          obscureText: _obscureNueva,
          onToggleVisibility: () => setState(() => _obscureNueva = !_obscureNueva),
          validator: (value) {
            if (value == null || value.isEmpty) return 'La nueva contraseña es obligatoria';
            if (value.length < 8) return 'Mínimo 8 caracteres';
            if (value.length > 16) return 'Máximo 16 caracteres';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Campo confirmar contraseña
        _buildPasswordField(
          label: 'Confirmar contraseña',
          controller: _confirmarContrasenaController,
          obscureText: _obscureConfirmar,
          onToggleVisibility: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Confirma la nueva contraseña';
            if (value != _nuevaContrasenaController.text) return 'Las contraseñas no coinciden';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Requisitos de contraseña
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _crema2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: _rojo, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Requisitos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _texto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRequirement('Mínimo 8 caracteres', _nuevaContrasenaController.text.length >= 8),
              _buildRequirement('Máximo 16 caracteres', _nuevaContrasenaController.text.length <= 16),
              _buildRequirement('Al menos 1 mayúscula', _nuevaContrasenaController.text.contains(RegExp(r'[A-Z]'))),
              _buildRequirement('Al menos 1 minúscula', _nuevaContrasenaController.text.contains(RegExp(r'[a-z]'))),
              _buildRequirement('Al menos 1 número', _nuevaContrasenaController.text.contains(RegExp(r'[0-9]'))),
              _buildRequirement('Al menos 1 caracter especial', _nuevaContrasenaController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>+-]'))),
              _buildRequirement('Coincide con la confirmación', _confirmarContrasenaController.text == _nuevaContrasenaController.text && _confirmarContrasenaController.text.isNotEmpty),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Mensaje de error
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F7),
              border: Border.all(color: _rojo.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: _rojo, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _rojo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (_errorMessage != null) const SizedBox(height: 16),

        // Botón guardar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _cambiarContrasena,
            style: ElevatedButton.styleFrom(
              backgroundColor: _rojo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              disabledBackgroundColor: const Color(0xFFD9D0BF),
              elevation: _isSaving ? 0 : 4,
              shadowColor: _rojo.withValues(alpha: 0.3),
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Guardando...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 20),
                      const SizedBox(width: 9),
                      const Text(
                        'Cambiar contraseña',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingresa tu contraseña',
        hintStyle: TextStyle(color: _gris.withValues(alpha: 0.5), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: BorderSide(color: _rojo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _rojo, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _rojo, width: 2),
        ),
        errorStyle: TextStyle(
          fontSize: 11,
          color: _rojo,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: _gris,
            size: 22,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildRequirement(String text, bool cumplido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: cumplido ? _verde : _gris.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cumplido ? _verde : _gris,
            ),
          ),
        ],
      ));
    }

  void _mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}