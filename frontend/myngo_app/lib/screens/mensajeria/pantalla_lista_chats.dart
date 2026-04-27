import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/servicio_chat.dart';
import '../inicio/pantalla_inicio.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class PantallaListaChats extends StatefulWidget {
  const PantallaListaChats({super.key});

  @override
  State<PantallaListaChats> createState() => _PantallaListaChatsState();
}

class _PantallaListaChatsState extends State<PantallaListaChats> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _salas = [];
  List<Map<String, dynamic>> _salasFiltradas = [];
  bool _cargando = true;
  int? _miId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchController.addListener(_filtrarSalas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    final prefs = await SharedPreferences.getInstance();
    _miId = prefs.getInt('usuario_id');
    
    // Obtener salas (el backend ya está optimizado con prefetch)
    final salas = await ServicioChat.obtenerSalas();
    
    if (mounted) {
      setState(() {
        _salas = salas;
        _salasFiltradas = salas;
        _cargando = false;
      });
    }
  }

  void _filtrarSalas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _salasFiltradas = _salas.where((sala) {
        final datos = _datosInterlocutor(sala);
        final nombre = (datos['nombre'] ?? '').toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  String _formatearFecha(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final ahora = DateTime.now();
      if (dt.day == ahora.day && dt.month == ahora.month && dt.year == ahora.year) {
        return DateFormat('HH:mm').format(dt);
      }
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return '';
    }
  }

  Map<String, String?> _datosInterlocutor(Map<String, dynamic> sala) {
    final miembros = (sala['miembros_detalle'] as List?) ?? [];
    if (!sala['es_grupal'] && miembros.length == 2) {
      final otro = miembros.firstWhere(
        (m) => m['id'] != _miId,
        orElse: () => miembros.first,
      );
      return {
        'nombre': '@${otro['nombre_usuario'] ?? sala['nombre']}',
        'avatar': otro['url_avatar'],
      };
    }
    return {'nombre': sala['nombre'] ?? 'Chat', 'avatar': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC35E34),
          onRefresh: _cargar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Cabecera Premium
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensajes',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2D2D2D),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Barra de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar chats...',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de Chats
              if (_cargando)
                SliverFillRemaining(
                  child: _buildCargando(),
                )
              else if (_salasFiltradas.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEstadoVacio(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildSalaItem(_salasFiltradas[index], index);
                      },
                      childCount: _salasFiltradas.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar búsqueda de usuarios para iniciar chat nuevo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Busca a alguien en Explorar para chatear 🐾')),
          );
        },
        backgroundColor: const Color(0xFFC35E34),
        elevation: 4,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          'Nuevo Chat',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCargando() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Sin conversaciones' : 'No se encontró nada',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty 
              ? '¡Empieza a conectar con otros Myngos! 🐾'
              : 'Prueba con otro nombre',
            style: GoogleFonts.outfit(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaItem(Map<String, dynamic> sala, int index) {
    final datos = _datosInterlocutor(sala);
    final nombre = datos['nombre'] ?? 'Chat';
    final avatarUrl = datos['avatar'];
    
    final ultimoMsg = sala['ultimo_mensaje'] as Map<String, dynamic>?;
    final preview = ultimoMsg != null ? (ultimoMsg['content'] ?? '') as String : 'Sin mensajes aún';
    final hora = ultimoMsg != null ? _formatearFecha(ultimoMsg['fecha_envio']) : '';
    final noLeidos = (sala['mensajes_no_leidos'] as num?)?.toInt() ?? 0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await context.push('/mensajes/sala/${sala['id']}', extra: {'nombre': nombre, 'sala': sala});
              _cargar();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: noLeidos > 0 ? const Color(0xFFFBF4F1) : Colors.transparent,
                border: Border.all(
                  color: noLeidos > 0 ? const Color(0xFFF5EBE6) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'avatar_${sala['id']}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: noLeidos > 0 ? const Color(0xFFC35E34) : Colors.grey.shade200,
                          width: 2,
                        ),
                        image: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                            : null,
                        color: const Color(0xFFF5EBE6),
                      ),
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Center(
                              child: Text(
                                nombre.isNotEmpty ? nombre.replaceAll('@', '')[0].toUpperCase() : '?',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC35E34),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.outfit(
                                fontWeight: noLeidos > 0 ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 17,
                                color: const Color(0xFF2D2D2D),
                              ),
                            ),
                            Text(
                              hora,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: noLeidos > 0 ? const Color(0xFFC35E34) : Colors.grey.shade500,
                                fontWeight: noLeidos > 0 ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: noLeidos > 0 ? const Color(0xFF4A4440) : Colors.grey.shade500,
                                  fontWeight: noLeidos > 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Consumer<ChatProvider>(
                              builder: (context, chat, child) {
                                final liveNoLeidos = chat.noLeidosEnSala(sala['id']);
                                // Usamos el máximo entre lo que vino de la API y lo que tiene el provider en tiempo real
                                final displayNoLeidos = liveNoLeidos > 0 ? liveNoLeidos : noLeidos;
                                
                                if (displayNoLeidos == 0) return const SizedBox.shrink();
                                
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC35E34),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    displayNoLeidos.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
