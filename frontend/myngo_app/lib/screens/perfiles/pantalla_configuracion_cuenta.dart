import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_usuarios.dart';
import 'package:go_router/go_router.dart';
import '../../models/usuario.dart';
import 'package:flutter/services.dart';

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

  Future<void> _cambiarNombreUsuario() async {
    final nuevoNombre = _usernameController.text.replaceAll(' ', '');
    if (nuevoNombre.isEmpty || nuevoNombre == _usuarioActual?.nombreUsuario) return;

    if (nuevoNombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 3 caracteres'), backgroundColor: Colors.red),
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
              const SnackBar(content: Text('Nombre de usuario actualizado ✨'), backgroundColor: Color(0xFF248EA6)),
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

  Future<void> _cambiarContrasena() async {
    final pass = _passController.text.replaceAll(' ', '');
    final passConfirm = _passConfirmController.text.replaceAll(' ', '');

    if (pass.isEmpty || passConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena ambas contraseñas'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(pass)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usa mayúsculas, minúsculas, números y símbolos especiales'), backgroundColor: Colors.red),
      );
      return;
    }

    if (pass != passConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Contraseña cambiada. Te hemos enviado un correo de aviso 🐾'), backgroundColor: Color(0xFF248EA6)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cambiarPrivacidad(bool hacerPublico) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(hacerPublico ? 'Hacer cuenta Pública 🌍' : 'Hacer cuenta Privada 🔒', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          hacerPublico 
              ? '¿Estás seguro de que deseas hacer tu cuenta pública? Cualquiera podrá ver tus publicaciones y seguirte sin necesidad de aprobación.'
              : '¿Estás seguro de que deseas hacer tu cuenta privada? Las personas tendrán que enviarte una solicitud para poder seguirte y ver tus publicaciones completas.',
          style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hacerPublico ? const Color(0xFFC35E34) : const Color(0xFF4A4440),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('CONFIRMAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const SnackBar(content: Text('Privacidad actualizada correctamente ✨'), backgroundColor: Color(0xFF248EA6)),
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

  Future<void> _eliminarCuenta() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Eliminar Cuenta 🛑', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          '¿Estás completamente seguro de que quieres eliminar tu cuenta?\n\n'
          'Esta acción no se puede deshacer. Tus comunidades creadas serán eliminadas, pero tus salas de chat seguirán activas para el resto de miembros.',
          style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('SÍ, ELIMINAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
          'Configuración',
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
                  _buildSectionTitle('Perfil Público'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Nombre de Usuario', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: 'Tu nombre único',
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
                          child: Text('Actualizar Nombre', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Privacidad'),
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
                                _usuarioActual!.esPublico ? 'Cuenta Pública' : 'Cuenta Privada',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _usuarioActual!.esPublico
                                    ? 'Cualquiera puede ver tu perfil y seguirte instantáneamente.'
                                    : 'Solo tus seguidores aprobados podrán ver tu perfil completo.',
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

                  _buildSectionTitle('Seguridad'),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Nueva Contraseña', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: '••••••••',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Confirmar Contraseña', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passConfirmController,
                          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: '••••••••',
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
                          child: Text('Cambiar Contraseña', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('Zona de Peligro', color: Colors.red),
                  _buildCard(
                    borderColor: Colors.red.shade200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Si eliminas tu cuenta, perderás el acceso permanentemente y todas tus comunidades serán borradas. Esta acción no se puede deshacer.',
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
                          child: Text('Eliminar Cuenta Definitivamente', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
