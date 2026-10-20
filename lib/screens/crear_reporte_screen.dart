import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/usuario.dart';
import 'menu_screen.dart';

/// Pantalla para crear un reporte de incidente.
///
/// Permite:
/// - Seleccionar tipo de incidente con buscador
/// - Escribir descripción y ubicación de referencia
/// - Obtener ubicación GPS automática
/// - Adjuntar hasta 4 imágenes desde galería
/// - Enviar reporte mediante POST multipart/form-data
class CrearReporteScreen extends StatefulWidget {
  final Usuario usuario;

  const CrearReporteScreen({super.key, required this.usuario});

  @override
  State<CrearReporteScreen> createState() => _CrearReporteScreenState();
}

class _CrearReporteScreenState extends State<CrearReporteScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Controladores
  final _descripcionController = TextEditingController();
  final _ubicacionRefController = TextEditingController();
  final _searchController = TextEditingController();

  // Estado
  List<Incidente> _incidentes = [];
  List<Incidente> _filteredIncidentes = [];
  Incidente? _selectedIncidente;
  Position? _currentPosition;
  final List<File> _evidencias = [];
  bool _isLoadingIncidentes = true;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  String? _locationError;
  String? _incidenteError;

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
    _cargarIncidentes();
    _obtenerUbicacion();
    _searchController.addListener(_filtrarIncidentes);
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionRefController.dispose();
    _searchController.dispose();
    _authService.dispose();
    super.dispose();
  }

  /// Carga la lista de incidentes desde la API.
  Future<void> _cargarIncidentes() async {
    setState(() => _isLoadingIncidentes = true);
    try {
      final incidentes = await _authService.obtenerIncidentes();
      if (mounted) {
        setState(() {
          _incidentes = incidentes;
          _filteredIncidentes = incidentes;
          _isLoadingIncidentes = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoadingIncidentes = false);
        _mostrarError('Error al cargar incidentes: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingIncidentes = false);
        _mostrarError('Error inesperado: ${e.toString()}');
      }
    }
  }

  /// Filtra los incidentes según el texto de búsqueda.
  void _filtrarIncidentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIncidentes = _incidentes;
      } else {
        _filteredIncidentes = _incidentes
            .where((i) => i.incidente.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  /// Obtiene la ubicación GPS actual del dispositivo.
  Future<void> _obtenerUbicacion() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado permanentemente');
      }

      // Obtener posición
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'No se pudo obtener la ubicación: ${e.toString()}';
        });
      }
    }
  }

  /// Abre la galería para seleccionar imágenes.
  Future<void> _seleccionarImagenes() async {
    if (_evidencias.length >= 4) {
      _mostrarError('Máximo 4 imágenes permitidas');
      return;
    }

    try {
      final List<XFile> imagenes = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (imagenes.isNotEmpty) {
        final espaciosDisponibles = 4 - _evidencias.length;
        final nuevasImagenes = imagenes.take(espaciosDisponibles).toList();

        setState(() {
          for (final imagen in nuevasImagenes) {
            _evidencias.add(File(imagen.path));
          }
        });

        if (imagenes.length > espaciosDisponibles) {
          _mostrarError('Solo se pueden adjuntar $espaciosDisponibles imágenes más');
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imágenes: ${e.toString()}');
    }
  }

  /// Elimina una evidencia de la lista.
  void _eliminarEvidencia(int index) {
    setState(() => _evidencias.removeAt(index));
  }

  /// Valida y envía el reporte.
  Future<void> _enviarReporte() async {
    // Validaciones
    if (_selectedIncidente == null) {
      setState(() => _incidenteError = 'Selecciona un tipo de incidente');
      return;
    }
    setState(() => _incidenteError = null);

    if (_descripcionController.text.trim().isEmpty) {
      _mostrarError('La descripción es obligatoria');
      return;
    }

    if (_currentPosition == null) {
      _mostrarError('No se ha podido obtener la ubicación GPS');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Combinar descripción con ubicación de referencia
      final descripcionCompleta = _ubicacionRefController.text.trim().isNotEmpty
          ? '${_descripcionController.text.trim()}. Ubicación de referencia: ${_ubicacionRefController.text.trim()}'
          : _descripcionController.text.trim();

      final response = await _authService.crearReporte(
        idUsuario: widget.usuario.idUsuario,
        idIncidente: _selectedIncidente!.id,
        descripcion: descripcionCompleta,
        latitud: _currentPosition!.latitude,
        longitud: _currentPosition!.longitude,
        evidencias: _evidencias,
      );

      if (!mounted) return;

      _mostrarExito('Reporte creado exitosamente puedes ver el seguimiento de este en la seccion del historial');

      // Navegar de vuelta al menú principal
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 422) {
        _mostrarError('Datos inválidos: ${e.detail ?? e.message}');
      } else if (e.statusCode == 0) {
        _mostrarError('Error de conexión. Verifica tu internet.');
      } else if (e.statusCode == 400) {
        _mostrarError(e.detail ?? e.message);
      } else {
        _mostrarError('Error: ${e.detail ?? e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      // Header
                      _buildHeader(horizontalPadding),

                      // Contenido
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 16,
                          ),
                          child: _buildForm(horizontalPadding),
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
                  'Crear reporte',
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
                  'Reporta un incidente en tu zona',
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

  Widget _buildForm(double horizontalPadding) {
    return Column(
      children: [
        // Tipo de incidente con buscador
        _buildIncidenteSelector(horizontalPadding),
        const SizedBox(height: 14),

        // Ubicación
        _buildUbicacionSection(horizontalPadding),
        const SizedBox(height: 14),

        // Descripción
        _buildDescripcionSection(horizontalPadding),
        const SizedBox(height: 14),

        // Evidencias
        _buildEvidenciasSection(horizontalPadding),
        const SizedBox(height: 24),

        // Botón enviar
        _buildBotonEnviar(horizontalPadding),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildIncidenteSelector(double horizontalPadding) {
    return Container(
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
              Icon(Icons.warning_amber_outlined, color: _rojo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tipo de incidente',
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

          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar tipo de incidente...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: _gris, size: 20),
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
            ),
          ),

          const SizedBox(height: 12),

          // Lista de incidentes filtrados
                    _buildIncidenteListContent(),
          if (_incidenteError != null) ...[
            const SizedBox(height: 8),
            Text(
              _incidenteError!,
              style: TextStyle(color: _rojo, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildIncidenteListContent() {
    if (_isLoadingIncidentes) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(color: _rojo, strokeWidth: 2),
        ),
      );
    }
    if (_filteredIncidentes.isEmpty) {
      return Text(
        _searchController.text.isEmpty
            ? 'No hay incidentes disponibles'
            : 'No se encontraron coincidencias',
        style: TextStyle(fontSize: 13, color: _gris, height: 1.5),
        textAlign: TextAlign.center,
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borde, width: 1.5),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredIncidentes.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: _borde, indent: 12, endIndent: 12),
        itemBuilder: (context, index) {
          final incidente = _filteredIncidentes[index];
          final isSelected = _selectedIncidente?.id == incidente.id;
          return InkWell(
            onTap: () => setState(() => _selectedIncidente = incidente),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isSelected ? _crema2 : Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _crema2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIncidenteIcon(incidente.incidente),
                      color: _rojo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      incidente.incidente,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? _rojo : _texto,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: _rojo, size: 22),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIncidenteIcon(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.contains('robo') || lower.contains('hurto')) return Icons.shield_outlined;
    if (lower.contains('accidente') || lower.contains('vial')) return Icons.directions_car_outlined;
    if (lower.contains('incendio')) return Icons.local_fire_department_outlined;
    if (lower.contains('violencia')) return Icons.report_outlined;
    if (lower.contains('desastre') || lower.contains('natural')) return Icons.warning_amber_outlined;
    if (lower.contains('inundación') || lower.contains('inundacion')) return Icons.water_damage_outlined;
    if (lower.contains('derrumbe')) return Icons.landslide_outlined;
    if (lower.contains('gas')) return Icons.gas_meter_outlined;
    if (lower.contains('energía') || lower.contains('energia') || lower.contains('corte')) return Icons.flash_off_outlined;
    if (lower.contains('agua') || lower.contains('problema')) return Icons.plumbing_outlined;
    if (lower.contains('alumbrado') || lower.contains('luz')) return Icons.lightbulb_outlined;
    if (lower.contains('animal')) return Icons.pets_outlined;
    if (lower.contains('contaminación') || lower.contains('contaminacion')) return Icons.cloud_outlined;
    if (lower.contains('médica') || lower.contains('medica') || lower.contains('emergencia')) return Icons.local_hospital_outlined;
    return Icons.report_outlined;
  }

  Widget _buildUbicacionSection(double horizontalPadding) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _amarillo, width: 5)),
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
              Icon(Icons.location_on_outlined, color: _amarillo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ubicación',
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

          // Estado GPS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentPosition != null ? _verde.withValues(alpha: 0.1) : _rojo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentPosition != null ? _verde : _rojo,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentPosition != null ? Icons.gps_fixed : Icons.gps_off,
                  color: _currentPosition != null ? _verde : _rojo,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPosition != null ? 'Ubicación GPS obtenida' : 'Ubicación GPS no disponible',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _currentPosition != null ? _verde : _rojo,
                        ),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 10.5, color: _gris),
                        )
                      else if (_locationError != null)
                        Text(
                          _locationError!,
                          style: TextStyle(fontSize: 10.5, color: _rojo),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_currentPosition == null)
                  TextButton.icon(
                    onPressed: _obtenerUbicacion,
                    icon: _isLoadingLocation
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _rojo))
                        : Icon(Icons.refresh, color: _rojo, size: 18),
                    label: Text('Reintentar', style: TextStyle(color: _rojo, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // Campo ubicación de referencia
          Text(
            'Ubicación de referencia (opcional)',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ubicacionRefController,
            decoration: InputDecoration(
              hintText: 'Ej. Col. Centro, frente al parque',
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
                borderSide: BorderSide(color: _amarillo, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcionSection(double horizontalPadding) {
    return Container(
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
              Icon(Icons.description_outlined, color: _rojo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Detalles',
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

          TextField(
            controller: _descripcionController,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe lo ocurrido, personas involucradas, gravedad, etc.',
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
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciasSection(double horizontalPadding) {
    return Container(
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
              Icon(Icons.photo_library_outlined, color: _rojo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Evidencias fotográficas',
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
            'Máximo 4 imágenes (JPG, PNG, WebP). Tamaño máx: 5 MB c/u.',
            style: TextStyle(
              fontSize: 11.5,
              color: _gris,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Botón adjuntar
          InkWell(
            onTap: _evidencias.length < 4 ? _seleccionarImagenes : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _crema2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _evidencias.length >= 4 ? _borde : _rojo,
                  width: 1.5,
                  style: _evidencias.length >= 4 ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _evidencias.length >= 4 ? Icons.check_circle_outline : Icons.add_photo_alternate_outlined,
                    color: _evidencias.length >= 4 ? _verde : _rojo,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _evidencias.length >= 4
                        ? 'Máximo de 4 imágenes alcanzado'
                        : 'Adjuntar evidencia fotográfica',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _evidencias.length >= 4 ? _verde : _gris,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vista previa de imágenes
          if (_evidencias.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _evidencias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _evidencias[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: () => _eliminarEvidencia(index),
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonEnviar(double horizontalPadding) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _enviarReporte,
        style: ElevatedButton.styleFrom(
          backgroundColor: _rojo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _rojo.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: _rojo.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: _isSubmitting
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
                  const Icon(Icons.send_outlined, size: 20),
                  const SizedBox(width: 9),
                  const Text(
                    'Enviar reporte',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}