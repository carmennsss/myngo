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

    // Avatar y nombre personalizados de la sala (aplican tanto a grupos como a 1-a-1)
    final avatarPersonalizado = sala['avatar_s3'] as String?;
    final nombrePersonalizado = sala['nombre'] as String?;

    if (!sala['es_grupal'] && miembros.isNotEmpty) {
      Map<String, dynamic>? otro;
      try {
        for (var m in miembros) {
          if (m['id'] != myId) {
            otro = m;
            break;
          }
        }
        otro ??= miembros.isNotEmpty ? miembros.first : null;
      } catch (_) {
        otro = miembros.isNotEmpty ? miembros.first : null;
      }

      if (otro == null) return {'nombre': 'Chat vacío', 'avatar': avatarPersonalizado};

      final interlocutor = otro!;
      sala['_otro_usuario_id'] = interlocutor['id'];

      // Si la sala tiene nombre personalizado, lo usamos; si no, el del interlocutor
      String nombreFinal;
      if (nombrePersonalizado != null && nombrePersonalizado.isNotEmpty) {
        nombreFinal = nombrePersonalizado;
      } else if (interlocutor['nombre_completo'] != null &&
          interlocutor['nombre_completo'].toString().isNotEmpty) {
        nombreFinal = interlocutor['nombre_completo'];
      } else {
        nombreFinal = interlocutor['nombre_usuario'] ?? sala['nombre'] ?? 'Usuario';
      }

      return {
        'nombre': nombreFinal,
        // Si la sala tiene avatar personalizado, lo usamos; si no, el del interlocutor
        'avatar': (avatarPersonalizado != null && avatarPersonalizado.isNotEmpty)
            ? avatarPersonalizado
            : interlocutor['url_avatar'],
      };
    }

    return {
      'nombre': sala['nombre'] ?? 'Chat',
      'avatar': sala['avatar_s3'],
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
          final nuevaSala = await _servicioMensajeria.crearSala(
            nombre: nombre,
            esGrupal: true,
            esPublica: esPublica,
            miembrosIds: miembrosIds,
          );

          if (nuevaSala != null && mounted) {
            await context.read<ChatProvider>().cargarSalas(); // Forzar carga en el provider
            if (mounted) {
              Navigator.pop(context); // Cerrar diálogo SOLO tras éxito
              context.push('/mensajes/sala/${nuevaSala['id']}', extra: {
                'nombre': nuevaSala['nombre'],
                'sala': nuevaSala
              });
            }
          } else if (mounted) {
            // Si falla, al menos quitamos el cargando del diálogo (esto lo hace el diálogo solo al terminar el await)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo crear el chat 🐾'))
            );
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

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearSala,
        backgroundColor: const Color(0xFFC35E34),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          'Nuevo Chat',
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
                  child: _buildEstadoVacio(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildSalaItem(salasFiltradas[index], index);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final chatProvider = context.read<ChatProvider>();
            await context.push('/mensajes/sala/${sala['id']}', extra: {'nombre': nombre, 'sala': sala});
            if (mounted) await chatProvider.cargarSalas();
            if (mounted) setState(() {});
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
                // Avatar — widget aislado para que no parpadee con cada evento del provider
                _AvatarSala(
                  avatarUrl: avatarUrl,
                  nombre: nombre,
                  noLeidos: noLeidos,
                  heroTag: 'avatar_sala_${sala['id'] ?? index}',
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
    );
  }
}

/// Avatar de sala aislado para evitar parpadeos cuando el ChatProvider
/// notifica cambios frecuentes (mensajes WS). Solo se reconstruye cuando
/// cambia su propia URL.
class _AvatarSala extends StatefulWidget {
  final String? avatarUrl;
  final String nombre;
  final int noLeidos;
  final String heroTag;

  const _AvatarSala({
    required this.avatarUrl,
    required this.nombre,
    required this.noLeidos,
    required this.heroTag,
  });

  @override
  State<_AvatarSala> createState() => _AvatarSalaState();
}

class _AvatarSalaState extends State<_AvatarSala> {
  @override
  void didUpdateWidget(_AvatarSala oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la URL cambia, borramos la caché de la URL anterior para forzar recarga
    if (oldWidget.avatarUrl != widget.avatarUrl && oldWidget.avatarUrl != null) {
      final oldResolved = oldWidget.avatarUrl!.startsWith('http')
          ? oldWidget.avatarUrl!
          : Uri.encodeFull(
              '${Configuracion.baseUrl}${oldWidget.avatarUrl!.startsWith('/') ? '' : '/'}${oldWidget.avatarUrl!}');
      CachedNetworkImage.evictFromCache(oldResolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.avatarUrl;
    final resolvedUrl = (url != null && url.isNotEmpty)
        ? (url.startsWith('http')
            ? url
            : Uri.encodeFull(
                '${Configuracion.baseUrl}${url.startsWith('/') ? '' : '/'}$url'))
        : null;

    return Hero(
      tag: widget.heroTag,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.noLeidos > 0 ? const Color(0xFFC35E34) : Colors.grey.shade200,
            width: 2,
          ),
          color: const Color(0xFFF5EBE6),
        ),
        child: ClipOval(
          child: resolvedUrl != null
              ? CachedNetworkImage(
                  imageUrl: resolvedUrl,
                  fit: BoxFit.cover,
                  width: 64,
                  height: 64,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => _Inicial(nombre: widget.nombre),
                )
              : _Inicial(nombre: widget.nombre),
        ),
      ),
    );
  }
}

class _Inicial extends StatelessWidget {
  final String nombre;
  const _Inicial({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EBE6),
      child: Center(
        child: Text(
          nombre.isNotEmpty ? nombre.replaceAll('@', '')[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFC35E34),
          ),
        ),
      ),
    );
  }
}
