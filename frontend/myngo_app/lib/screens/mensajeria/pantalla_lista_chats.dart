import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/servicio_mensajeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/usuario.dart';
import '../../widgets/mensajeria/dialogo_crear_sala.dart';
import '../inicio/pantalla_inicio.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/configuracion.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../tolgee/translation_widget.dart';


class PantallaListaChats extends StatefulWidget {
  const PantallaListaChats({super.key});

  @override
  State<PantallaListaChats> createState() => _PantallaListaChatsState();
}

class _PantallaListaChatsState extends State<PantallaListaChats> with SingleTickerProviderStateMixin {
  bool _cargando = true;
  int? _miId;
  final TextEditingController _searchController = TextEditingController();
  final _servicioMensajeria = ServicioMensajeria();
  final _servicioUsuarios = ServicioUsuarios();

  @override
  void initState() {
    super.initState();
    _cargar();
    // Escuchar cambios en el provider para refrescar si llegan nuevos mensajes o salas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().addListener(_onChatProviderChanged);
    });
  }

  void _onChatProviderChanged() {
    if (!mounted || _cargando) return;
    _cargar();
  }

  @override
  void dispose() {
    // Es importante remover el listener para evitar fugas de memoria
    if (mounted) {
       context.read<ChatProvider>().removeListener(_onChatProviderChanged);
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    
    setState(() => _cargando = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('usuario_id');
      
      // Delegamos la carga al provider
      await context.read<ChatProvider>().cargarSalas();
      
      if (mounted) {
        setState(() {
          _miId = id;
        });
      }
    } catch (e) {
      debugPrint('Error cargando chats: $e');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
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
    final myId = context.read<ChatProvider>().userId;
    final miembros = (sala['miembros_detalle'] as List?) ?? [];
    
    if (!sala['es_grupal'] && miembros.isNotEmpty) {
      Map<String, dynamic>? otro;
      try {
        // Buscamos al otro usuario que no soy yo de forma segura
        for (var m in miembros) {
          if (m['id'] != myId) {
            otro = m;
            break;
          }
        }
        // Si no hay otro, usamos el primero disponible
        otro ??= miembros.isNotEmpty ? miembros.first : null;
      } catch (_) {
        otro = miembros.isNotEmpty ? miembros.first : null;
      }
      
      if (otro == null) return {'nombre': 'Chat vacío', 'avatar': null}; // Se maneja en el builder con tr()


      final interlocutor = otro!;
      // Guardamos el ID del otro usuario para usarlo al abrir el chat
      sala['_otro_usuario_id'] = interlocutor['id'];
      
      // Intentamos sacar el nombre más amigable posible
      String nombreFinal = interlocutor['nombre_usuario'] ?? sala['nombre'] ?? 'Usuario';
      // Si tenemos un nombre a mostrar o nombre real, lo usamos sin el @
      if (interlocutor['nombre_completo'] != null && interlocutor['nombre_completo'].toString().isNotEmpty) {
        nombreFinal = interlocutor['nombre_completo'];
      } else if (interlocutor['nombre_usuario'] != null) {
        nombreFinal = interlocutor['nombre_usuario'];
      }
      
      return {
        'nombre': nombreFinal,
        'avatar': interlocutor['url_avatar'],
      };
    }
    return {
      'nombre': sala['nombre'], 
      'avatar': sala['avatar_s3']
    };
  }


  void _mostrarDialogoCrearSala() async {
    // Obtener lista de posibles participantes (amigos/seguidos)
    final res = await _servicioUsuarios.listarUsuarios();
    if (!res.exito || !mounted) return;

    // Filtramos para mostrar a todos menos yo
    final potenciales = (res.datos ?? []).where((u) => u.id != _miId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DialogoCrearSala(
        potencialesParticipantes: potenciales,
        alCrear: (nombre, esPublica, miembrosIds) async {
          Navigator.pop(context); // Cerrar diálogo
          
          final nuevaSala = await _servicioMensajeria.crearSala(
            nombre: nombre,
            esGrupal: true,
            esPublica: esPublica,
            miembrosIds: miembrosIds,
          );

          if (nuevaSala != null && mounted) {
            _cargar(); // Recargar lista
            context.push('/mensajes/sala/${nuevaSala['id']}', extra: {
              'nombre': nuevaSala['nombre'],
              'sala': nuevaSala
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final salas = chatProvider.salas;
    
    // Aplicamos el filtro de búsqueda localmente sobre las salas del provider
    final query = _searchController.text.toLowerCase();
    final salasFiltradas = salas.where((sala) {
      final datos = _datosInterlocutor(sala);
      final nombre = (datos['nombre'] ?? '').toLowerCase();
      return nombre.contains(query);
    }).toList();

    return TranslationWidget(
      builder: (context, tr) {
        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F8),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _mostrarDialogoCrearSala,
            backgroundColor: const Color(0xFFC35E34),
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            label: Text(
              tr('chatNew'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFFC35E34),
              onRefresh: () => chatProvider.cargarSalas(),
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
                            tr('chatMessages'),
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
                                hintText: tr('chatSearchHint'),
                                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
                                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (_) => setState(() {}), // Forzar rebuild para filtrar
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
    
                  // Lista de Chats
                  if (_cargando && salas.isEmpty)
                    SliverFillRemaining(
                      child: _buildCargando(),
                    )
                  else if (salasFiltradas.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEstadoVacio(tr),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildSalaItem(salasFiltradas[index], index, tr);
                          },
                          childCount: salasFiltradas.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
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

  Widget _buildEstadoVacio(String Function(String, [Map<String, dynamic>?]) tr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? tr('chatNoConversations') : tr('chatNoSearchResults'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty 
              ? tr('chatStartConnecting')
              : tr('chatTryAnotherName'),
            style: GoogleFonts.outfit(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }


  Widget _buildSalaItem(Map<String, dynamic> sala, int index, String Function(String, [Map<String, dynamic>?]) tr) {
    final datos = _datosInterlocutor(sala);
    final nombreRaw = datos['nombre'];
    final nombre = (nombreRaw == null || nombreRaw == 'Chat vacío') ? tr('chatEmpty') : nombreRaw;
    final avatarUrl = datos['avatar'];
    
    final ultimoMsg = sala['ultimo_mensaje'] as Map<String, dynamic>?;
    final preview = ultimoMsg != null ? (ultimoMsg['content'] ?? '') as String : tr('chatNoMessagesYet');
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
              if (mounted) _cargar();
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
                    tag: 'avatar_sala_${sala['id'] ?? index}',
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
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  avatarUrl.startsWith('http') ? avatarUrl : Uri.encodeFull('${Configuracion.baseUrl}${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl'),
                                ), 
                                fit: BoxFit.cover
                              )
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
                            Expanded(
                              child: Text(
                                nombre,
                                style: GoogleFonts.outfit(
                                  fontWeight: noLeidos > 0 ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 17,
                                  color: const Color(0xFF2D2D2D),
                                ),
                                overflow: TextOverflow.ellipsis,
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
