import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../models/comunidad.dart';
import '../../../models/sala_chat.dart';

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
    if (estaCargando && salasChat == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    final salasFiltradas = (salasChat ?? []).where((s) => s.esGrupal).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: (salasChat != null) ? salasFiltradas.length + 2 : 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildChatHeader(context);
        
        if (salasChat == null) {
          return const Center(child: Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: CircularProgressIndicator(color: Color(0xFFF28B50)),
          ));
        }

        if (index == 1) return _buildGeneralChatTile(context);

        final sala = salasFiltradas[index - 2];
        return _SalaChatTile(
          sala: sala,
          comunidad: comunidad,
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
    // Buscar la sala general real:
    // 1. Que contenga "general"
    // 2. O la primera sala grupal que encuentre
    final SalaChat? salaGeneral = (salasChat ?? []).firstWhere(
      (s) => s.nombre.toLowerCase().contains('general'),
      orElse: () => (salasChat ?? []).firstWhere(
        (s) => s.esGrupal,
        orElse: () => SalaChat(
          id: -1, 
          nombre: 'Buscando sala...', 
          comunidadId: comunidad.id, 
          esGrupal: true, 
          fechaCreacion: DateTime.now()
        ),
      ),
    );

    final bool salaEncontrada = salaGeneral != null && salaGeneral.id > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: esAppClara ? Colors.black.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: salaEncontrada 
            ? const Color(0xFFF28B50).withOpacity(0.4)
            : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: salaEncontrada ? const Color(0xFFF28B50) : Colors.grey,
          child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          salaEncontrada ? 'Chat General ✨' : 'No hay salas disponibles 🐾',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: colorTextoPrincipal,
          ),
        ),
        subtitle: Text(
          salaEncontrada ? '¡Habla con toda la comunidad!' : 'Prueba a crear una sala nueva.',
          style: GoogleFonts.outfit(
            color: colorTextoSecundario,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded, 
          color: salaEncontrada ? const Color(0xFFF28B50) : Colors.grey
        ),
        onTap: () {
          if (!salaEncontrada) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay una sala general en esta comunidad 🐾'))
            );
            return;
          }
          context.go(
            '/mensajes/sala/${salaGeneral.id}',
            extra: {
              'nombre': 'Chat General ✨ ${comunidad.nombre}',
              'comunidad_id': comunidad.id,
              'sala': {'id': salaGeneral.id, '_otro_usuario_id': null}
            },
          );
        },
      ),
    );
  }
}

class _SalaChatTile extends StatelessWidget {
  final SalaChat sala;
  final Comunidad comunidad;
  final bool esAppClara;
  final Color colorTextoPrincipal;

  const _SalaChatTile({
    required this.sala,
    required this.comunidad,
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
        context.go(
          '/mensajes/sala/${sala.id}',
          extra: {
            'nombre': sala.nombre,
            'comunidad_id': comunidad.id,
            'sala': {'id': sala.id, '_otro_usuario_id': null}
          },
        );
      },
    );
  }
}
