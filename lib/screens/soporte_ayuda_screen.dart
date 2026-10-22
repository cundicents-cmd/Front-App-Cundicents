import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/usuario.dart';
import 'perfil_screen.dart';

/// Pantalla de Soporte y Ayuda con información de seguridad y contacto.
class SoporteAyudaScreen extends StatefulWidget {
  final Usuario usuario;

  const SoporteAyudaScreen({super.key, required this.usuario});

  @override
  State<SoporteAyudaScreen> createState() => _SoporteAyudaScreenState();
}

class _SoporteAyudaScreenState extends State<SoporteAyudaScreen> {
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
                  'Soporte y ayuda',
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
                  'Seguridad y contacto',
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

  Widget _buildContent() {
    return Column(
      children: [
        // Hero de ayuda
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: _rojo, width: 5)),
            borderRadius: BorderRadius.circular(16),
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
                margin: const EdgeInsets.only(bottom: 12),
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
                  child: Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Text(
                'Seguridad de tus datos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'En Cundicents tratamos tus datos personales con las medidas de seguridad pertinentes para proteger su confidencialidad e integridad. Si tienes alguna duda, necesitas asistencia o deseas realizar una consulta relacionada con la aplicación o el tratamiento de tus datos, puedes comunicarte con nosotros a través de',
                style: TextStyle(
                  fontSize: 13,
                  color: _gris,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tarjeta de contacto
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: _amarillo, width: 5)),
            borderRadius: BorderRadius.circular(16),
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
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rojo.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: _rojo,
                  size: 28,
                ),
              ),
              Text(
                'Correo de soporte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Escríbenos para cualquier duda, incidencia o consulta sobre el tratamiento de tus datos.',
                style: TextStyle(
                  fontSize: 12,
                  color: _gris,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Botón de correo
              InkWell(
                onTap: _abrirCorreo,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _rojo,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _rojo.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email, color: Colors.white, size: 20),
                      const SizedBox(width: 9),
                      Text(
                        'cundicents@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Preguntas frecuentes
        _buildSectionTitle('Preguntas frecuentes'),
        const SizedBox(height: 12),

        _buildFaqItem(
          '¿Cómo se protegen mis datos?',
          'Tus datos personales se almacenan de forma segura y se transmiten mediante conexiones encriptadas. No compartimos tu información con terceros sin tu consentimiento, salvo obligación legal.',
        ),
        _buildFaqItem(
          '¿Qué datos recopila la app?',
          'Recopilamos tu nombre, apellidos, correo electrónico, cédula y los reportes que envíes. También accedemos a tu ubicación GPS cuando creas un reporte, con tu permiso.',
        ),
        _buildFaqItem(
          '¿Puedo eliminar mi cuenta?',
          'Sí, puedes solicitar la eliminación de tu cuenta contactando a soporte en cundicents@gmail.com. Procesaremos tu solicitud según la normativa vigente.',
        ),
        _buildFaqItem(
          '¿Qué hago si olvidé mi contraseña?',
          'En la seccion de perfil puede entrar a cambiar contraseña y cambiar su contraseña, si no tiene acceso a la cuenta contacta a soporte en cundicents@gmail.com para asistencia con el restablecimiento.',
        ),
        _buildFaqItem(
          '¿Cómo reporto un problema técnico?',
          'Envía un correo a cundicents@gmail.com describiendo el problema, tu dispositivo y los pasos para reproducirlo. Te responderemos a la brevedad.',
        ),

        const SizedBox(height: 24),

        // Versión
        Text(
          'Cundicents v1.0.0',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB9B09A),
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

  Widget _buildFaqItem(String pregunta, String respuesta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.help_outline,
            color: _rojo,
            size: 22,
          ),
          title: Text(
            pregunta,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _texto,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: _borde,
            size: 22,
          ),
          collapsedIconColor: _borde,
          iconColor: _rojo,
          shape: Border(
            bottom: BorderSide(color: _borde.withValues(alpha: 0.3)),
          ),
          children: [
            Text(
              respuesta,
              style: TextStyle(
                fontSize: 12.5,
                color: _gris,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirCorreo() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'cundicents@gmail.com',
      query: 'subject=Soporte Cundicents&body=Hola, necesito ayuda con...',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _mostrarError('No se pudo abrir la aplicación de correo');
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al abrir el correo: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}