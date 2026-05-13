import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_usuarios.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import 'package:flutter/services.dart';
import 'package:myngo_app/utils/tr_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_notifier.dart';

// Pantalla de ajustes de cuenta: nombre de usuario, privacidad, contraseña y zona de peligro.
// Cada sección tiene su propia validación antes de llamar al servicio.
class PantallaConfiguracionCuenta extends StatefulWidget {
  const PantallaConfiguracionCuenta({super.key});

  @override
  State<PantallaConfiguracionCuenta> createState() => _PantallaConfiguracionCuentaState();
}

class _PantallaConfiguracionCuentaState extends State<PantallaConfiguracionCuenta> {
  final _servicioUsuarios = ServicioUsuarios();
  
  bool _isLoading = false;
  Usuario? _usuarioActual;

  // Controladores de texto
  final _usernameController = TextEditingController();
  final _passController = TextEditingController();
  final _passConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passController.dispose();
    _passConfirmController.dispose();
    super.dispose();
  }

  // Carga los datos actuales del usuario para pre-rellenar los campos
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final res = await _servicioUsuarios.obtenerDatosPropios();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.exito && res.datos != null) {
          _usuarioActual = res.datos;
          _usernameController.text = _usuarioActual!.nombreUsuario;
        }
      });
    }
  }

  // Valida que el nombre nuevo sea distinto, tenga ≥3 caracteres y no tenga espacios
  Future<void> _cambiarNombreUsuario() async {
    final nuevoNombre = _usernameController.text.replaceAll(' ', '');
    if (nuevoNombre.isEmpty || nuevoNombre == _usuarioActual?.nombreUsuario) return;

    if (nuevoNombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('configErrorNameShort')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _servicioUsuarios.actualizarNombreUsuario(_usuarioActual!.id, nuevoNombre);
    
      if (mounted) {
        if (res.exito) {
          await _cargarDatos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('configSuccessNameUpdated')), backgroundColor: const Color(0xFF248EA6)),
            );
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
          );
        }
      }
  }

  // Valida la contraseña con regex (mayúsculas, números y símbolos) y la confirma
  Future<void> _cambiarContrasena() async {
    final pass = _passController.text.replaceAll(' ', '');
    final passConfirm = _passConfirmController.text.replaceAll(' ', '');

    if (pass.isEmpty || passConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('configErrorFillPasswords')), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('configErrorPasswordShort')), backgroundColor: Colors.red),
      );
      return;
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(pass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('configErrorPasswordComplex')), backgroundColor: Colors.red),
      );
      return;
    }

    if (pass != passConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('configErrorPasswordsNotMatch')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _servicioUsuarios.cambiarPassword(pass);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (res.exito) {
        _passController.clear();
        _passConfirmController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('configSuccessPasswordChanged')), backgroundColor: const Color(0xFF248EA6)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Muestra un diálogo de confirmación antes de cambiar la visibilidad del perfil
  Future<void> _cambiarPrivacidad(bool hacerPublico) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(hacerPublico ? tr('dialogPrivacyPublicTitle') : tr('dialogPrivacyPrivateTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          hacerPublico 
              ? tr('dialogPrivacyPublicDesc')
              : tr('dialogPrivacyPrivateDesc'),
          style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hacerPublico ? const Color(0xFFC35E34) : const Color(0xFF4A4440),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('commonConfirm'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      setState(() => _isLoading = true);
      final res = await _servicioUsuarios.actualizarPerfil(
        perfilId: _usuarioActual!.perfilId,
        esPublico: hacerPublico,
      );
      
      if (mounted) {
        if (res.exito) {
          await _cargarDatos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('configSuccessPrivacyUpdated')), backgroundColor: const Color(0xFF248EA6)),
            );
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Acción destructiva: pide doble confirmación y elimina la cuenta definitivamente
  Future<void> _eliminarCuenta() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(tr('dialogDeleteAccountTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          tr('dialogDeleteAccountDesc'),
          style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('commonCancel'), style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('commonConfirm'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      setState(() => _isLoading = true);
      final res = await _servicioUsuarios.eliminarCuenta();
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (res.exito) {
          context.go('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleNotifier>();
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A4440), size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          tr('configTitle'),
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440)),
        ),
      ),
      body: Stack(
        children: [
          if (_usuarioActual != null)
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(tr('configSectionPublicProfile')),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(tr('configLabelUsername'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: tr('configHintUsername'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cambiarNombreUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC35E34),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(tr('configButtonUpdateName'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(tr('configSectionPrivacy')),
                  _buildCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_usuarioActual!.esPublico ? const Color(0xFFC35E34) : const Color(0xFF4A4440)).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _usuarioActual!.esPublico ? Icons.public_rounded : Icons.lock_rounded,
                            color: _usuarioActual!.esPublico ? const Color(0xFFC35E34) : const Color(0xFF4A4440),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _usuarioActual!.esPublico ? tr('configLabelPublicAccount') : tr('configLabelPrivateAccount'),
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _usuarioActual!.esPublico
                                    ? tr('configDescPublicAccount')
                                    : tr('configDescPrivateAccount'),
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: !_usuarioActual!.esPublico,
                          activeColor: const Color(0xFF4A4440),
                          onChanged: (bool value) => _cambiarPrivacidad(!value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(tr('configSectionSecurity')),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(tr('configLabelNewPassword'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: tr('commonPasswordPlaceholder'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(tr('configLabelConfirmPassword'), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passConfirmController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: tr('commonPasswordPlaceholder'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cambiarContrasena,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF248EA6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(tr('configButtonChangePassword'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle(tr('configSectionDangerZone'), color: Colors.red),
                  _buildCard(
                    borderColor: Colors.red.shade200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr('configDangerWarning'),
                          style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _eliminarCuenta,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(tr('configButtonDeleteAccount'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34), strokeWidth: 5)),
            ),
        ],
      ),
    );
  }

  // Título de sección (Perfil Público, Seguridad, Zona de Peligro...)
  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? const Color(0xFFC35E34),
        ),
      ),
    );
  }

  // Contenedor visual de tarjeta blanca con borde opcional (para la zona de peligro)
  Widget _buildCard({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}
