import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';

import 'package:go_router/go_router.dart';
import '../../../models/comunidad.dart';
import '../../../models/sala_chat.dart';
import 'package:myngo_app/utils/tr_helper.dart';

/// Widget que muestra las salas de chat disponibles en la comunidad.
class SeccionChatComunidad extends StatelessWidget {
  final Comunidad comunidad;
  final List<SalaChat>? salasChat;
  final bool estaCargando;
  final VoidCallback onCrearSala;
  final VoidCallback? onRefresh;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;
  final bool comoSliver;

  const SeccionChatComunidad({
    super.key,
    required this.comunidad,
    required this.salasChat,
    required this.estaCargando,
    required this.onCrearSala,
    this.onRefresh,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
    this.comoSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (estaCargando && salasChat == null) {
          final loading = const Center(
              child: CircularProgressIndicator(color: Color(0xFFF28B50)));
          return comoSliver ? SliverFillRemaining(child: loading) : loading;
        }
    
        // Buscamos cuál es la sala general para no repetirla en la lista de abajo
        SalaChat? salaGeneral;
        try {
          salaGeneral = (salasChat ?? []).firstWhere((s) => s.nombre.toLowerCase().contains('general'));
        } catch (_) {
          try {
            salaGeneral = (salasChat ?? []).firstWhere((s) => s.esGrupal);
          } catch (_) {}
        }
    
        final salasFiltradas = (salasChat ?? []).where((s) => s.esGrupal && s.id != salaGeneral?.id).toList();
        final itemCount = (salasChat != null) ? salasFiltradas.length + 2 : 1;
    
        if (comoSliver) {
          return SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildItem(context, index, salasFiltradas, tr),
                childCount: itemCount,
              ),
            ),
          );
        }
    
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: itemCount,
          itemBuilder: (context, index) => _buildItem(context, index, salasFiltradas, tr),
        );
      }
    );
  }


  Widget _buildItem(BuildContext context, int index, List<SalaChat> salasFiltradas, String Function(String, [Map<String, dynamic>?]) tr) {
    if (index == 0) return _buildChatHeader(context, tr);
    
    if (salasChat == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.only(top: 40.0),
        child: CircularProgressIndicator(color: Color(0xFFF28B50)),
      ));
    }

    if (index == 1) return _buildGeneralChatTile(context, tr);

    final sala = salasFiltradas[index - 2];
    return _SalaChatTile(
      sala: sala,
      comunidad: comunidad,
      esAppClara: esAppClara,
      colorTextoPrincipal: colorTextoPrincipal,
    );
  }


  Widget _buildChatHeader(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tr('chatRooms'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorTextoPrincipal,
            ),
          ),
          Row(
            children: [
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                  onPressed: onRefresh,
                ),
              TextButton.icon(
                onPressed: onCrearSala,
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: Color(0xFF248EA6)),
                label: Text(
                  tr('chatCreateRoom'),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF248EA6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildGeneralChatTile(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    // Buscar la sala general real:
    // Que contenga "general"
    // O la primera sala grupal que encuentre
    final SalaChat? salaGeneral = (salasChat ?? []).firstWhere(
      (s) => s.nombre.toLowerCase().contains('general'),
      orElse: () => (salasChat ?? []).firstWhere(
        (s) => s.esGrupal,
        orElse: () => SalaChat(
          id: -1, 
          nombre: tr('chatSearchingRooms'), 
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
          salaEncontrada ? tr('chatGeneralTitle') : tr('chatNoRoomsAvailable'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: colorTextoPrincipal,
          ),
        ),
        subtitle: Text(
          salaEncontrada ? tr('chatGeneralSubtitle') : tr('chatCreateNewSuggestion'),
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
              SnackBar(content: Text(tr('chatNoGeneralRoom')))
            );
            return;
          }
          context.push(
            '/mensajes/sala/${salaGeneral.id}',
            extra: {
              'nombre': '${tr('chatGeneralTitle')} ${comunidad.nombre}',
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
        context.push(
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
