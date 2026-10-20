import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

/// Pantalla de registro de Cundicents (tres etapas).
///
/// Etapa 1: Captura de cédula (foto o galería) y extracción OCR.
/// Etapa 2: Revisión y corrección de datos extraídos.
/// Etapa 3: Formulario de correo y contraseña.
/// Etapa 4: Éxito.
///
/// Basada en el diseño visual de Registro.html.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controladores de UI para datos de cédula (editables)
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroCedulaController = TextEditingController();

  // Controladores de UI para registro
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estado de la etapa actual (1 = cédula, 2 = revisar datos, 3 = formulario, 4 = éxito)
  int _currentStep = 1;

  // Datos de la cédula extraídos por OCR
  String? _cedulaNombres;
  String? _cedulaApellidos;
  String? _cedulaNumero;
  Uint8List? _cedulaImageBytes;

  // Controladores de UI
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  // Animaciones
  late AnimationController _stepAnimationController;
  late Animation<double> _stepProgressAnimation;

  // Colores institucionales
  static const Color _rojo = Color(0xFFD71920);
  static const Color _crema = Color(0xFFFFF8D6);
  static const Color _crema2 = Color(0xFFF5F0E1);
  static const Color _texto = Color(0xFF1E1E1E);
  static const Color _gris = Color(0xFF7A7360);
  static const Color _borde = Color(0xFFE6E0C9);
  static const Color _verde = Color(0xFF6C8B3F);

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stepProgressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _stepAnimationController, curve: Curves.easeInOut),
    );
    _stepAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroCedulaController.dispose();
    _stepAnimationController.dispose();
    _authService.dispose();
    super.dispose();
  }

  /// Captura una foto de la cédula usando la cámara.
  /// Selecciona una imagen de la galería.
  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 768,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        // Validar tamaño máximo (3MB)
        if (bytes.length > 3 * 1024 * 1024) {
          _mostrarError('La imagen es muy grande. Selecciona una imagen más pequeña.');
          return;
        }
        setState(() {
          _cedulaImageBytes = bytes;
        });
        await _procesarCedulaOCR(bytes, filename: image.name);
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  /// Envía la imagen al endpoint OCR para extraer datos.
  Future<void> _procesarCedulaOCR(Uint8List bytes, {String? filename}) async {
    setState(() => _isLoading = true);

    try {
      final cedulaData = await _authService.extraerDatosCedula(bytes, filename: filename ?? 'cedula.jpg');

      setState(() {
        _cedulaNombres = cedulaData.nombres;
        _cedulaApellidos = cedulaData.apellidos;
        _cedulaNumero = cedulaData.numeroDocumento;
        _nombresController.text = cedulaData.nombres;
        _apellidosController.text = cedulaData.apellidos;
        _numeroCedulaController.text = cedulaData.numeroDocumento;
        _isLoading = false;
      });

      _mostrarExito('Cédula procesada correctamente');
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (e.statusCode == 0) {
        _mostrarError('Error de conexión. Verifica tu internet.');
      } else {
        _mostrarError('Error al procesar cédula: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error inesperado: ${e.toString()}');
    }
  }

  /// Valida y avanza a la etapa 2 (revisar datos).
  void _continuarAPaso2() {
    if (_cedulaNombres == null || _cedulaApellidos == null || _cedulaNumero == null) {
      _mostrarError('Debes escanear tu cédula primero');
      return;
    }
    _cambiarPaso(2);
  }

  /// Cambia la etapa actual con animación.
  void _cambiarPaso(int paso) {
    _stepAnimationController.reset();
    setState(() => _currentStep = paso);
    _stepAnimationController.forward();
  }

  /// Vuelve a la etapa 1.
  void _volverAPaso1() {
    _cambiarPaso(1);
  }

  /// Valida y avanza a la etapa 3 (formulario de acceso).
  void _continuarAPaso3() {
    // Sincronizar controladores con variables de estado
    _cedulaNombres = _nombresController.text.trim();
    _cedulaApellidos = _apellidosController.text.trim();
    _cedulaNumero = _numeroCedulaController.text.trim();

    if (_cedulaNombres!.isEmpty || _cedulaApellidos!.isEmpty || _cedulaNumero!.isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return;
    }
    _cambiarPaso(3);
  }

  /// Valida el formulario de la etapa 3 y registra al usuario.
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _mostrarError('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cedulaInt = int.tryParse(_cedulaNumero ?? '');

      await _authService.registrarUsuario(
        nombre: _cedulaNombres!,
        apellido: _cedulaApellidos!,
        contrasena: _passwordController.text,
        correo: _emailController.text.trim(),
        cedula: cedulaInt,
      );

      if (!mounted) return;

      _cambiarPaso(4); // Pantalla de éxito
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (e.statusCode == 422) {
        _mostrarError('Datos inválidos: ${e.detail ?? e.message}');
      } else if (e.statusCode == 0) {
        _mostrarError('Error de conexión. Verifica tu internet.');
      } else {
        _mostrarError('Error al registrar: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error inesperado: ${e.toString()}');
    }
  }

  /// Navega al login después del registro exitoso.
  void _irAlLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
                      // Header con indicador de pasos
                      _buildHeader(horizontalPadding),

                      // Contenido según la etapa
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _buildCurrentStep(horizontalPadding),
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
    final stepTitles = {
      1: {'title': 'Escanear cédula', 'subtitle': 'Paso 1 de 4 · Verifica tu identidad'},
      2: {'title': 'Revisar datos', 'subtitle': 'Paso 2 de 4 · Confirma tus datos'},
      3: {'title': 'Datos de acceso', 'subtitle': 'Paso 3 de 4 · Correo y contraseña'},
      4: {'title': '¡Bienvenido!', 'subtitle': 'Tu cuenta fue creada con éxito'},
    };

    final current = stepTitles[_currentStep] ?? stepTitles[1]!;

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
      child: Column(
        children: [
          Row(
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
                    Text(
                      current['title']!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current['subtitle']!,
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
          const SizedBox(height: 12),
          // Indicador de pasos
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        // Paso 1
        _buildStepCircle(1, Icons.badge_outlined, _currentStep >= 1),
        // Línea entre paso 1 y 2
        Expanded(
          child: AnimatedBuilder(
            animation: _stepProgressAnimation,
            builder: (context, child) {
              return Container(
                height: 3,
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _borde,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentStep >= 2 ? 1.0 : (_currentStep == 1 ? 0.5 * _stepProgressAnimation.value : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Paso 2
        _buildStepCircle(2, Icons.assignment_outlined, _currentStep >= 2),
        // Línea entre paso 2 y 3
        Expanded(
          child: AnimatedBuilder(
            animation: _stepProgressAnimation,
            builder: (context, child) {
              return Container(
                height: 3,
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _borde,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentStep >= 3 ? 1.0 : (_currentStep == 2 ? 0.5 * _stepProgressAnimation.value : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Paso 3
        _buildStepCircle(3, Icons.person_add_outlined, _currentStep >= 3),
        // Línea entre paso 3 y 4
        Expanded(
          child: AnimatedBuilder(
            animation: _stepProgressAnimation,
            builder: (context, child) {
              return Container(
                height: 3,
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _borde,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentStep >= 4 ? 1.0 : (_currentStep == 3 ? 0.5 * _stepProgressAnimation.value : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Paso 4 (solo se muestra en éxito)
        if (_currentStep >= 4) ...[
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                color: _verde,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          _buildStepCircle(4, Icons.check, _currentStep >= 4),
        ],
      ],
    );
  }

  Widget _buildStepCircle(int step, IconData icon, bool active) {
    final isCurrent = _currentStep == step;
    final isDone = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? _verde : (isCurrent ? _rojo : _crema2),
            border: Border.all(
              color: isDone ? _verde : (isCurrent ? _rojo : _borde),
              width: 2,
            ),
            boxShadow: isCurrent
                ? [BoxShadow(color: _rojo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Icon(icon, color: isCurrent ? Colors.white : _gris, size: 16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step == 1 ? 'Cédula' : (step == 2 ? 'Datos' : (step == 3 ? 'Acceso' : 'Listo')),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isCurrent || isDone ? (isDone ? _verde : _rojo) : _gris,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(double horizontalPadding) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Cedula(horizontalPadding);
      case 2:
        return _buildStep2RevisarDatos(horizontalPadding);
      case 3:
        return _buildStep3Formulario(horizontalPadding);
      case 4:
        return _buildStep4Exito(horizontalPadding);
      default:
        return _buildStep1Cedula(horizontalPadding);
    }
  }

  // ==================== PASO 1: ESCANEAR CÉDULA ====================
  Widget _buildStep1Cedula(double horizontalPadding) {
    return KeyedSubtree(
      key: const ValueKey('step1'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Column(
          children: [
            // Tarjeta de escaneo
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, color: _rojo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escanea tu cédula',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _texto,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Coloca tu documento de identidad dentro del recuadro. Asegúrate de que la imagen se vea nítida, completa y sin reflejos.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _gris,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Área de escaneo / vista previa
                  if (_cedulaImageBytes == null) _buildScanFrame() else _buildScanPreview(),

                  const SizedBox(height: 12),

                  // Botón de captura
                  if (_cedulaImageBytes == null) _buildCaptureButton() else const SizedBox.shrink(),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _crema2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: _rojo, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tus datos se tratan de forma confidencial y solo se utilizan para validar tu identidad.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _gris,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Botón continuar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _cedulaImageBytes != null && !_isLoading ? _continuarAPaso2 : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rojo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD9D2C0),
                  elevation: 0,
                  shadowColor: _rojo.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continuar',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 9),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _crema2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC0B8A8), width: 2, style: BorderStyle.solid),
        ),
        child: Stack(
          children: [
            // Esquinas decorativas
            ..._buildCorners(),
            // Línea de escaneo animada
            _buildScanLine(),
            // Contenido central
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, color: _rojo.withValues(alpha: 0.65), size: 48),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Coloca tu cédula aquí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _gris,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double cornerSize = 22;
    const double borderWidth = 3;
    const double offset = 10;

    return [
      Positioned(
        top: offset,
        left: offset,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _rojo, width: borderWidth),
              left: BorderSide(color: _rojo, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
          ),
        ),
      ),
      Positioned(
        top: offset,
        right: offset,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _rojo, width: borderWidth),
              right: BorderSide(color: _rojo, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(6)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        left: offset,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _rojo, width: borderWidth),
              left: BorderSide(color: _rojo, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        right: offset,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _rojo, width: borderWidth),
              right: BorderSide(color: _rojo, width: borderWidth),
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(6)),
          ),
        ),
      ),
    ];
  }

  Widget _buildScanLine() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedBuilder(
        animation: _stepAnimationController,
        builder: (context, child) {
          // Animar la línea de escaneo de arriba a abajo
          final progress = (_stepAnimationController.value * 2) % 1.0;
          final topPercent = 0.1 + 0.78 * progress; // 10% a 88%
          return Positioned(
            left: MediaQuery.of(context).size.width * 0.06,
            right: MediaQuery.of(context).size.width * 0.06,
            top: MediaQuery.of(context).size.width * topPercent / 1.586,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [Colors.transparent, _rojo, Colors.transparent],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [BoxShadow(color: _rojo, blurRadius: 14)],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaptureButton() {
    return InkWell(
      onTap: _mostrarOpcionesCaptura,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _crema2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC0B8A8), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.camera_alt_outlined, color: _rojo, size: 28),
            const SizedBox(height: 6),
            Text(
              'Escanea tu cedula',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _gris,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesCaptura() {
    _seleccionarDeGaleria();
  }

  Widget _buildScanPreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _verde, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _cedulaImageBytes!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: Material(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {
                setState(() {
                  _cedulaImageBytes = null;
                  _cedulaNombres = null;
                  _cedulaApellidos = null;
                  _cedulaNumero = null;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Repetir captura',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PASO 2: REVISAR DATOS DE CÉDULA ====================
  Widget _buildStep2RevisarDatos(double horizontalPadding) {
    return KeyedSubtree(
      key: const ValueKey('step2'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Vista previa de la cédula
              if (_cedulaImageBytes != null) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _verde, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _cedulaImageBytes!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tarjeta de datos extraídos (editables)
              Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, color: _rojo, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Datos extraídos de la cédula',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _texto,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa y corrige los datos extraídos por OCR antes de continuar.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _gris,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo: Nombres
                    _buildFormField(
                      label: 'Nombres',
                      controller: _nombresController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa los nombres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),

                    // Campo: Apellidos
                    _buildFormField(
                      label: 'Apellidos',
                      controller: _apellidosController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa los apellidos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),

                    // Campo: Número de cédula
                    _buildFormField(
                      label: 'Número de cédula',
                      controller: _numeroCedulaController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa el número de cédula';
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'Solo números permitidos';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _crema2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _rojo, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verifica que los datos sean correctos. El OCR puede cometer errores en nombres compuestos o números.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _gris,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Botón continuar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continuarAPaso3,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rojo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9D2C0),
                    elevation: 0,
                    shadowColor: _rojo.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Continuar',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 9),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón volver
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _volverAPaso1,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: _gris,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: _gris),
                      const SizedBox(width: 8),
                      Text(
                        'Volver a escanear',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gris),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PASO 3: FORMULARIO DE ACCESO ====================
  Widget _buildStep3Formulario(double horizontalPadding) {
    return KeyedSubtree(
      key: const ValueKey('step3'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tarjeta de datos de acceso
              Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: _rojo, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Datos de acceso',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _texto,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),

                    // Campo: Correo
                    _buildFormField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa tu correo';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),

                    // Campo: Contraseña
                    _buildPasswordFormField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                        if (value.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),

                    // Campo: Confirmar contraseña
                    _buildPasswordFormField(
                      label: 'Confirmar contraseña',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                        if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Checkbox términos
              GestureDetector(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: _acceptTerms ? _rojo : Colors.white,
                        border: Border.all(
                          color: _acceptTerms ? _rojo : _borde,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _acceptTerms
                          ? const Icon(Icons.check, color: Colors.white, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 11.5, color: _gris, fontWeight: FontWeight.w600, height: 1.45),
                          children: [
                            const TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'términos y condiciones',
                              style: TextStyle(color: _rojo, fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' y el aviso de privacidad.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Botón registrar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rojo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9D2C0),
                    elevation: 0,
                    shadowColor: _rojo.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_outlined, size: 20),
                            const SizedBox(width: 9),
                            const Text(
                              'Crear cuenta',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Botón volver
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _volverAPaso1,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: _gris,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: _gris),
                      const SizedBox(width: 8),
                      Text(
                        'Volver',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gris),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PASO 4: ÉXITO ====================
  Widget _buildStep4Exito(double horizontalPadding) {
    return KeyedSubtree(
      key: const ValueKey('step4'),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 34, 22, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border(left: BorderSide(color: _verde, width: 5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _verde.withValues(alpha: 0.14),
                    border: Border.all(color: _verde.withValues(alpha: 0.25), width: 4),
                  ),
                  child: Icon(Icons.check, color: _verde, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Cuenta creada!',
                  style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, color: _texto),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu identidad fue verificada correctamente y tu cuenta está lista. Ya puedes iniciar sesión y comenzar a enviar reportes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: _gris, height: 1.5),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _irAlLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rojo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: _rojo.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_outlined, size: 20),
                        const SizedBox(width: 9),
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WIDGETS AUXILIARES ====================

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: _texto),
          decoration: InputDecoration(
            hintText: _getFormHint(label),
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildPasswordFormField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: _texto),
          decoration: InputDecoration(
            hintText: label == 'Contraseña' ? 'Mínimo 8 caracteres' : 'Repite tu contraseña',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _gris, size: 20),
              onPressed: onToggle,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
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

  String _getFormHint(String label) {
    switch (label) {
      case 'Correo electrónico':
        return 'tucorreo@ejemplo.com';
      default:
        return '';
    }
  }
}