import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/comunidad.dart';
import '../../../models/sala_chat.dart';
import '../../mensajeria/pantalla_chat.dart';

/// Widget que muestra las salas de chat disponibles en la comunidad.
class SeccionChatComunidad extends StatelessWidget {
  final Comunidad comunidad;
  final List<SalaChat>? salasChat;
  final bool estaCargando;
  final VoidCallback onCrearSala;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;

  const SeccionChatComunidad({
    super.key,
    required this.comunidad,
    required this.salasChat,
    required this.estaCargando,
    required this.onCrearSala,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
  });

  @override
  Widget build(BuildContext context) {
    if (estaCargando || salasChat == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: (salasChat?.length ?? 0) + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildChatHeader(context);
        if (index == 1) return _buildGeneralChatTile(context);

        final sala = salasChat![index - 2];
        return _SalaChatTile(
          sala: sala,
          esAppClara: esAppClara,
          colorTextoPrincipal: colorTextoPrincipal,
        );
      },
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Salas de Chat',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorTextoPrincipal,
            ),
          ),
          TextButton.icon(
            onPressed: onCrearSala,
            icon: const Icon(Icons.add_circle_outline,
                size: 20, color: Color(0xFF248EA6)),
            label: Text(
              'Crear Sala',
              style: GoogleFonts.outfit(
                color: const Color(0xFF248EA6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralChatTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: esAppClara ? Colors.black.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF28B50).withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF28B50),
          child: Icon(Icons.forum_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'Chat General ✨',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: colorTextoPrincipal,
          ),
        ),
        subtitle: Text(
          '¡Habla con toda la comunidad!',
          style: GoogleFonts.outfit(
            color: colorTextoSecundario,
            fontSize: 13,
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFF28B50)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => PantallaChat(
                salaId: comunidad.id * -1, // ID negativo para la sala general
                nombreSala: 'Chat General ✨ ${comunidad.nombre}',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SalaChatTile extends StatelessWidget {
  final SalaChat sala;
  final bool esAppClara;
  final Color colorTextoPrincipal;

  const _SalaChatTile({
    required this.sala,
    required this.esAppClara,
    required this.colorTextoPrincipal,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: esAppClara ? Colors.black.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.tag, color: Colors.grey),
      ),
      title: Text(
        sala.nombre,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: colorTextoPrincipal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 20, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => PantallaChat(
              salaId: sala.id,
              nombreSala: sala.nombre,
            ),
          ),
        );
      },
    );
  }
}
