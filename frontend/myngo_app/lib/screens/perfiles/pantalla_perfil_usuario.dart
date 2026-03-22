import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/usuario.dart';

class PantallaPerfilUsuario extends StatelessWidget {
  final Usuario usuario;

  const PantallaPerfilUsuario({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(usuario.nombreUsuario, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar & Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF248EA6).withOpacity(0.1),
                    child: Text(
                      usuario.nombreUsuario.isNotEmpty ? usuario.nombreUsuario[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF248EA6),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        usuario.nombreUsuario,
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (usuario.esVerificado) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: Color(0xFF248EA6), size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario.email,
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildStat('Rating', usuario.ratingActual.toString(), Icons.star_rounded, const Color(0xFFF29C50)),
                   _buildStat('Seguidores', '0', Icons.people_outline_rounded, const Color(0xFFF28B50)),
                   _buildStat('Posts', '0', Icons.feed_outlined, const Color(0xFFF2D0BD)),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Seguir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28B50),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Enviar Mensaje'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Content Tabs Placeholder
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.feed_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    '${usuario.nombreUsuario} aún no ha publicado nada.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
