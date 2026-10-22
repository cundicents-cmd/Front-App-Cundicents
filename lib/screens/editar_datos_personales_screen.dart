import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../models/usuario.dart';
import 'perfil_screen.dart';

/// Pantalla para editar datos personales (nombres, apellidos, correo).
class EditarDatosPersonalesScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarDatosPersonalesScreen({super.key, required this.usuario});

  @override
  State<EditarDatosPersonalesScreen> createState() => _EditarDatosPersonalesScreenState();
}

class _EditarDatosPersonalesScreenState extends State<EditarDatosPersonalesScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _nombresError;
  String? _apellidosError;
  String? _correoError;

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
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() => _isLoading = true);

    try {
      final usuarioActualizado = await _authService.obtenerUsuarioPorId(widget.usuario.idUsuario);

      if (mounted) {
        setState(() {
          _nombresController.text = usuarioActualizado.nombre ?? '';
          _apellidosController.text = usuarioActualizado.apellido ?? '';
          _correoController.text = usuarioActualizado.correo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar datos: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _guardarCambios() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // Limpiar errores previos
    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await _authService.actualizarDatos(
        userId: widget.usuario.idUsuario,
        nombre: _nombresController.text.trim(),
        apellido: _apellidosController.text.trim(),
        correo: _correoController.text.trim(),
      );

      // Si el correo cambiÃ³, actualizar en almacenamiento seguro
      if (_correoController.text.trim() != widget.usuario.correo) {
        await SecureStorageService.actualizarCorreo(_correoController.text.trim());
      }

      if (mounted) {
        _mostrarExito('Datos actualizados correctamente');
        // Regresar a la pantalla de perfil
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
    if (mensaje.contains('422') || mensaje.contains('validaciÃ³n')) {
      return 'Datos invÃ¡lidos. Verifica el formato del correo y que los campos no estÃ©n vacÃ­os.';
    } else if (mensaje.contains('404')) {
      return 'Usuario no encontrado.';
    } else if (mensaje.contains('500')) {
      return 'Error del servidor. Intenta mÃ¡s tarde.';
    } else if (mensaje.contains('conexiÃ³n') || mensaje.contains('timeout')) {
      return 'Error de conexiÃ³n. Verifica tu internet.';
    }
    return 'Error al actualizar: $mensaje';
  }

  String? _validarNombres(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los nombres son obligatorios';
    }
    if (value.trim().length < 2) {
      return 'Los nombres deben tener al menos 2 caracteres';
    }
    if (value.trim().length > 150) {
      return 'MÃ¡ximo 150 caracteres';
    }
    return null;
  }

  String? _validarApellidos(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los apellidos son obligatorios';
    }
    if (value.trim().length < 2) {
      return 'Los apellidos deben tener al menos 2 caracteres';
    }
    if (value.trim().length > 150) {
      return 'MÃ¡ximo 150 caracteres';
    }
    return null;
  }

  String? _validarCorreo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo vÃ¡lido';
    }
    return null;
  }

  void _mostrarExito(String mensaje) {
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
                        child: _isLoading
                            ? _buildLoadingState()
                            : Form(
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
                  'Editar datos',
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
                  'Nombres, apellidos y correo',
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
            'Cargando datos...',
            style: TextStyle(fontSize: 16, color: _gris, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                widget.usuario.correo,
                style: TextStyle(
                  fontSize: 12,
                  color: _gris,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Estos son los datos con los que te identificas en la plataforma.',
                style: TextStyle(
                  fontSize: 11,
                  color: _gris,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Campos de solo lectura (ID y Cedula)
        _buildReadOnlyField('Cedula', widget.usuario.cedula?.toString() ?? 'No registrada', Icons.credit_card_outlined),
        const SizedBox(height: 24),

        // Formulario editable
        _buildSectionTitle('Datos editables'),
        const SizedBox(height: 12),

        _buildField(
          label: 'Nombres',
          controller: _nombresController,
          errorText: _nombresError,
          validator: _validarNombres,
          hint: 'Ej. Juan Carlos',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),

        _buildField(
          label: 'Apellidos',
          controller: _apellidosController,
          errorText: _apellidosError,
          validator: _validarApellidos,
          hint: 'Ej. PÃ©rez LÃ³pez',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),

        _buildField(
          label: 'Correo electronico',
          controller: _correoController,
          errorText: _correoError,
          validator: _validarCorreo,
          hint: 'Ej. juan.perez@correo.hn',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 16),

        // Mensaje de error
        if (_errorMessage != null)
          _buildErrorMessage(),

        // BotÃ³n guardar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _guardarCambios,
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
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: 9),
                      const Text(
                        'Guardar cambios',
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hint,
    required TextInputType keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
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
          ),
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _crema2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borde),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _rojo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _rojo, size: 24),
          ),
          const SizedBox(width: 14),
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
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _texto,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: _borde, size: 20),
        ],
      ),
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
}
