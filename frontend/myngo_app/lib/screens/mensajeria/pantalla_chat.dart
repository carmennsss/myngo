import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/configuracion.dart';
import '../../services/servicio_mensajeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../services/servicio_comunidades.dart';
import '../../models/usuario.dart';
import '../../models/comunidad.dart';
import '../../models/respuesta_api.dart';
import '../comunidades/widgets_detalle/lista_miembros_comunidad.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/foundation.dart' as foundation;
import '../../providers/chat_provider.dart';

class PantallaChat extends StatefulWidget {
  final int salaId;
  final String nombreSala;
  final int? otroUsuarioId;
  final int? comunidadId;

  const PantallaChat({
    super.key,
    required this.salaId,
    required this.nombreSala,
    this.otroUsuarioId,
    this.comunidadId,
  });

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final ServicioMensajeria _servicioChat = ServicioMensajeria();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _mensajes = [];
  Map<int, String> _presenciaUsuarios = {};
  int _usuariosOnline = 0;
  int? _miId;
  Usuario? _otroUsuario;
  bool _cargandoHistorial = true;
  bool _cargandoMas = false;
  String? _errorHistorial;
  int _offset = 0;
  bool _hasMore = true;
  final int _limit = 30;
  bool _chatConectado = false;
  bool _mostrarEmojis = false;
  final FocusNode _focusNode = FocusNode();

  /// IDs de mensajes que ya han sido leídos por el receptor.
  final Set<int> _mensajesLeidos = {};

  Timer? _typingTimer;
  bool _yoEstoyEscribiendo = false;
  final Map<int, String> _usuariosEscribiendo = {};

  // Estado para edición y respuestas
  int? _mensajeIdEdicion;
  Map<String, dynamic>? _mensajeParaResponder;

  @override
  void initState() {
    super.initState();
    _inicializar();
    _scrollController.addListener(_onScroll);
    _mensajeController.addListener(_onTypingChanged);

    // Notificar al provider que estamos en esta sala
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ChatProvider>();
        provider.setSalaActiva(widget.salaId);
        // El recibo de lectura ya se envía en _inicializar() -> _marcarLeidos()
        // pero podemos reforzarlo via WebSocket si ya está conectado.
      }
    });
  }

  void _onTypingChanged() {
    if (_mensajeController.text.isNotEmpty && !_yoEstoyEscribiendo) {
      _yoEstoyEscribiendo = true;
      _servicioChat.enviarEventoTyping(widget.salaId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_yoEstoyEscribiendo) {
        _yoEstoyEscribiendo = false;
        _servicioChat.enviarEventoTyping(widget.salaId, false);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_cargandoMas &&
        _hasMore) {
      _cargarMasHistorial();
    }
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    _miId = prefs.getInt('usuario_id');
    
    if (widget.otroUsuarioId != null) {
      _cargarDatosOtroUsuario();
    }
    
    await _cargarHistorial();
    _conectarWebSockets();
    // Marcar mensajes como leídos al abrir el chat
    await _marcarLeidos();
  }

  Future<void> _cargarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      setState(() {
        _cargandoHistorial = false;
        _errorHistorial = 'Sesión no válida';
      });
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${Configuracion.baseUrl}/mensajeria/salas/${widget.salaId}/mensajes/?limit=$_limit&offset=0'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> results = data['results'] ?? [];
        
        setState(() {
          _mensajes = results.map((m) => _parsearMensaje(m)).toList();
          _offset = _limit;
          _hasMore = data['next'] != null;
          _errorHistorial = null;
          
          // Pre-cargar los mensajes ya leídos
          for (final m in _mensajes) {
            if (m['leido'] == true) {
              _mensajesLeidos.add(m['message_id'] as int);
            }
          }
          _cargandoHistorial = false;
        });
      } else {
        setState(() {
          _errorHistorial = 'Error al cargar mensajes (${res.statusCode})';
          _cargandoHistorial = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorHistorial = 'No se pudo conectar con el servidor 🐾';
        _cargandoHistorial = false;
      });
    }
  }

  Future<void> _cargarDatosOtroUsuario() async {
    try {
      final res = await ServicioUsuarios().obtenerDatosUsuario(widget.otroUsuarioId!);
      if (res.exito && mounted) {
        setState(() {
          _otroUsuario = res.datos;
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarMasHistorial() async {
    if (_cargandoMas || !_hasMore) return;
    
    setState(() => _cargandoMas = true);
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
      final res = await http.get(
        Uri.parse('${Configuracion.baseUrl}/mensajeria/salas/${widget.salaId}/mensajes/?limit=$_limit&offset=$_offset'),
        headers: {'Authorization': 'Token $token'},
      );
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> results = data['results'] ?? [];
        
        setState(() {
          final nuevos = results.map((m) => _parsearMensaje(m)).toList();
          _mensajes.addAll(nuevos);
          _offset += _limit;
          _hasMore = data['next'] != null;
          _cargandoMas = false;
        });
      } else {
        setState(() => _cargandoMas = false);
      }
    } catch (_) {
      setState(() => _cargandoMas = false);
    }
  }

  Map<String, dynamic> _parsearMensaje(dynamic m) {
    return {
      'type': 'chat_message',
      'message_id': m['id'],
      'content': m['content'] ?? '',
      'user_id': m['emisor'],
      'username': m['emisor_nombre'],
      'timestamp': m['fecha_envio'],
      'leido_por_ids': List<int>.from(m['leido_por_ids'] ?? []),
      'referencia_a': m['referencia_a'],
      'referencia_a_detalle': m['referencia_a_detalle'],
      'es_editado': m['es_editado'] ?? false,
      'borrado_para_todos': m['borrado_para_todos'] ?? false,
      'hasError': (m['content'] == null && m['url_archivo_s3'] == null),
    };
  }

  Future<void> _marcarLeidos() async {
    await ServicioMensajeria().marcarMensajesComoLeidos(widget.salaId);
  }

  void _conectarWebSockets() {
    _servicioChat.conectarASala(widget.salaId, (data) {
      if (mounted) {
        setState(() {
          if (data['type'] == 'chat_message') {
            // Si el mensaje es mío, quitar el mensaje optimista por client_id
            if (data['user_id'] == _miId && data['client_id'] != null) {
              _mensajes.removeWhere((m) => m['client_id'] == data['client_id']);
            }

            // Añadir el mensaje real del servidor
            final msg = Map<String, dynamic>.from(data);
            msg['leido'] = data['leido'] ?? false;
            _mensajes.insert(0, msg);

            // Si el mensaje no es mío, marcar como leído inmediatamente
            if (msg['user_id'] != _miId) {
              _marcarLeidos();
            }
          } else if (data['type'] == 'user_joined') {
            _mensajes.insert(0, {
              'type': 'system',
              'content': '${data['username']} se ha unido al chat 🐾',
            });
          } else if (data['type'] == 'user_left') {
            _mensajes.insert(0, {
              'type': 'system',
              'content': '${data['username']} ha salido',
            });
          } else if (data['type'] == 'user_typing') {
            final int uId = data['user_id'];
            final String uName = data['username'] ?? 'Alguien';
            final bool isTyping = data['is_typing'] ?? false;

            if (isTyping) {
              _usuariosEscribiendo[uId] = uName;
            } else {
              _usuariosEscribiendo.remove(uId);
            }
          } else if (data['type'] == 'message_edited') {
            final idx = _mensajes.indexWhere((m) => m['message_id'] == data['mensaje_id']);
            if (idx != -1) {
              _mensajes[idx] = Map<String, dynamic>.from(_mensajes[idx])
                ..['content'] = data['nuevo_contenido']
                ..['es_editado'] = true;
            }
          } else if (data['type'] == 'message_deleted') {
            if (data['para_todos'] == true) {
              final idx = _mensajes.indexWhere((m) => m['message_id'] == data['mensaje_id']);
              if (idx != -1) {
                _mensajes[idx] = Map<String, dynamic>.from(_mensajes[idx])
                  ..['content'] = 'Mensaje borrado'
                  ..['borrado_para_todos'] = true;
              }
            }
          } else if (data['type'] == 'messages_read') {
            // El receptor ha leído los mensajes → marcar como leídos en UI
            final List<dynamic> ids = data['leidos_ids'] ?? [];
            final int leidoPor = data['leido_por'] ?? 0;
            
            for (int i = 0; i < _mensajes.length; i++) {
              if (ids.contains(_mensajes[i]['message_id'])) {
                final currentLeidos = List<int>.from(_mensajes[i]['leido_por_ids'] ?? []);
                if (!currentLeidos.contains(leidoPor)) {
                  currentLeidos.add(leidoPor);
                  _mensajes[i] = Map<String, dynamic>.from(_mensajes[i])
                    ..['leido_por_ids'] = currentLeidos;
                }
              }
            }
          }
        });
      }
    }, alConectar: () {
      if (mounted) setState(() => _chatConectado = true);
    });

  }

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isNotEmpty) {
      if (_mensajeIdEdicion != null) {
        // Modo edición
        final exito = await _servicioChat.editarMensaje(_mensajeIdEdicion!, texto);
        if (exito) {
          setState(() {
            _mensajeIdEdicion = null;
            _mensajeController.clear();
          });
        }
        return;
      }

      // Modo envío normal o respuesta
      final clientId = DateTime.now().microsecondsSinceEpoch.toString();
      final mensajeOptimista = {
        'type': 'chat_message',
        'content': texto,
        'user_id': _miId,
        'username': 'Tú',
        'timestamp': DateTime.now().toIso8601String(),
        'isOptimistic': true,
        'client_id': clientId,
        'leido_por_ids': [],
        'referencia_a': _mensajeParaResponder?['message_id'],
        'referencia_a_detalle': _mensajeParaResponder != null ? {
          'id': _mensajeParaResponder!['message_id'],
          'emisor_nombre': _mensajeParaResponder!['username'],
          'contenido': _mensajeParaResponder!['content'],
        } : null,
      };

      setState(() {
        _mensajes.insert(0, mensajeOptimista);
        _mensajeController.clear();
        final refId = _mensajeParaResponder?['message_id'];
        _mensajeParaResponder = null;
        _servicioChat.enviarMensajeChat(texto, idCliente: clientId, referenciaA: refId as int?);
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  void _responderMensaje(Map<String, dynamic> msg) {
    setState(() {
      _mensajeParaResponder = msg;
      _mensajeIdEdicion = null;
      _focusNode.requestFocus();
    });
  }

  void _editarMensaje(Map<String, dynamic> msg) {
    setState(() {
      _mensajeIdEdicion = msg['message_id'];
      _mensajeParaResponder = null;
      _mensajeController.text = msg['content'] ?? '';
      _focusNode.requestFocus();
    });
  }

  void _confirmarBorrado(Map<String, dynamic> msg) {
    final esMio = msg['user_id'] == _miId;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar mensaje?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _servicioChat.borrarMensaje(msg['message_id']);
              setState(() {
                _mensajes.removeWhere((m) => m['message_id'] == msg['message_id']);
              });
            },
            child: const Text('Borrar para mí'),
          ),
          if (esMio)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _servicioChat.borrarMensaje(msg['message_id'], paraTodos: true);
              },
              child: const Text('Borrar para todos', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar sala activa al salir. No usamos context.read en dispose si es asíncrono.
    // Pero podemos intentar marcarlo si el provider está disponible o simplemente confiar en el setSalaActiva del siguiente chat.
    // Una mejor forma es usar una referencia capturada si es necesario, pero aquí el problema era el addPostFrameCallback.
    try {
      context.read<ChatProvider>().setSalaActiva(null);
    } catch (_) {}
    
    _focusNode.dispose();
    _servicioChat.dispose();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A4440),
        elevation: 0.5,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: InkWell(
          onTap: () {
            if (_otroUsuario != null && mounted) {
              GoRouter.of(context).push('/inicio/perfiles/${_otroUsuario!.id}', extra: _otroUsuario);
            }
          },
          child: Row(
            children: [
              if (widget.otroUsuarioId != null) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFBE9E0),
                  backgroundImage: _otroUsuario?.urlAvatar != null 
                    ? NetworkImage(_otroUsuario!.urlAvatar!) 
                    : null,
                  child: _otroUsuario?.urlAvatar == null 
                    ? const Icon(Icons.person, size: 20, color: Color(0xFFC35E34)) 
                    : null,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nombreSala,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2D2D2D),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Builder(builder: (ctx) {
                      if (widget.otroUsuarioId != null) {
                        return Consumer<ChatProvider>(
                          builder: (context, prov, _) {
                            final estaOnline = prov.isUsuarioOnline(widget.otroUsuarioId!);
                            return Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: estaOnline ? Colors.green : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  estaOnline ? 'En línea' : 'Desconectado',
                                  style: GoogleFonts.outfit(
                                    color: estaOnline ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }
                        );
                      } else {
                        return Text(
                          _chatConectado ? 'Chat activo 🐾' : 'Conectando...',
                          style: GoogleFonts.outfit(
                            color: _chatConectado ? const Color(0xFF248EA6) : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF4A4440), size: 20),
          onPressed: () {
            if (!mounted) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/mensajes');
            }
          },
        ),
        actions: [
          if (widget.comunidadId != null)
            IconButton(
              icon: const Icon(Icons.people_rounded, color: Color(0xFF4A4440)),
              onPressed: () => _mostrarMiembros(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                if (_usuariosEscribiendo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.8),
                    child: Text(
                      '${_usuariosEscribiendo.values.join(", ")} ${_usuariosEscribiendo.length > 1 ? "están" : "está"} escribiendo... 🐾',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF248EA6),
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Expanded(
                  child: _cargandoHistorial
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC35E34)))
                : _errorHistorial != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_errorHistorial!, style: GoogleFonts.outfit(color: Colors.grey)),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _cargandoHistorial = true;
                                  _errorHistorial = null;
                                });
                                _cargarHistorial();
                              },
                              child: const Text('Reintentar', style: TextStyle(color: Color(0xFFC35E34))),
                            ),
                          ],
                        ),
                      )
                    : _mensajes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 56, color: Color(0xFFDDCCBB)),
                                const SizedBox(height: 16),
                                Text(
                                  'Sé el primero en escribir 🐾',
                                  style: GoogleFonts.outfit(
                                      color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _mensajes.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          
                          final msg = _mensajes[index];
                          if (msg['type'] == 'system') {
                            return _buildSystemMessage(msg['content']);
                          }
                          final esMio = msg['user_id'] == _miId;
                          final status =
                              _presenciaUsuarios[msg['user_id']] ?? 'DESCONECTADO';
                          final leido = _mensajesLeidos
                              .contains(msg['message_id'] as int?);
                          return _buildChatBubble(msg, esMio, status, leido);
                        },
                      ),
                    ),
                  ],
                ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String content) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(content,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic),
          ),
        ),
      );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool esMio, String status, bool _) {
    String timestampStr = '';
    try {
      timestampStr = DateFormat('HH:mm').format(DateTime.parse(msg['timestamp']));
    } catch (_) {}

    final leidoPorIds = List<int>.from(msg['leido_por_ids'] ?? []);
    final esLeidoTotal = leidoPorIds.isNotEmpty;
    final borrado = msg['borrado_para_todos'] == true;

    return GestureDetector(
      onLongPress: () {
        if (!borrado) _mostrarMenuMensaje(msg);
      },
      child: Align(
        alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!esMio && widget.comunidadId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(msg['username'] ?? '',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC35E34))),
                ),
              Container(
                decoration: BoxDecoration(
                  color: esMio ? const Color(0xFFC35E34) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(esMio ? 16 : 4),
                    bottomRight: Radius.circular(esMio ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview de Respuesta
                    if (msg['referencia_a_detalle'] != null)
                      Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: esMio ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: esMio ? Colors.white54 : const Color(0xFFC35E34), width: 3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['referencia_a_detalle']['emisor_nombre'] ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: esMio ? Colors.white : const Color(0xFFC35E34),
                              ),
                            ),
                            Text(
                              msg['referencia_a_detalle']['contenido'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: esMio ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            borrado ? 'Mensaje borrado' : (msg['content'] ?? ''),
                            style: GoogleFonts.outfit(
                              color: esMio ? Colors.white : const Color(0xFF4A4440),
                              fontSize: 15,
                              fontStyle: borrado ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          if (msg['es_editado'] == true && !borrado)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('editado',
                                  style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: esMio ? Colors.white70 : Colors.grey.shade400)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timestampStr.isNotEmpty)
                      Text(timestampStr, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500)),
                    if (esMio) ...[
                      const SizedBox(width: 4),
                      if (msg['isOptimistic'] == true)
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400)
                      else
                        esLeidoTotal
                            ? const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF248EA6))
                            : Icon(Icons.done_rounded, size: 14, color: Colors.grey.shade400),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMenuMensaje(Map<String, dynamic> msg) {
    final esMio = msg['user_id'] == _miId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(context);
                  _responderMensaje(msg);
                },
              ),
              if (esMio)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    _editarMensaje(msg);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Borrar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarBorrado(msg);
                },
              ),
              if (esMio && widget.comunidadId != null)
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Info de lectura'),
                  onTap: () {
                    Navigator.pop(context);
                    _mostrarInfoLectura(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarInfoLectura(Map<String, dynamic> msg) {
    // Aquí podrías mostrar un diálogo con la lista de quiénes han leído el mensaje.
    // Por simplicidad, mostramos un snackbar o un diálogo simple.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visto por'),
        content: Text('Este mensaje ha sido leído por ${msg['leido_por_ids']?.length ?? 0} personas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_mensajeParaResponder != null || _mensajeIdEdicion != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Icon(
                  _mensajeIdEdicion != null ? Icons.edit_rounded : Icons.reply_rounded,
                  size: 16,
                  color: const Color(0xFFC35E34),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mensajeIdEdicion != null ? 'Editando mensaje' : 'Respondiendo a ${_mensajeParaResponder!['username']}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC35E34),
                        ),
                      ),
                      Text(
                        _mensajeIdEdicion != null 
                          ? _mensajes.firstWhere((m) => m['message_id'] == _mensajeIdEdicion)['content'] ?? ''
                          : _mensajeParaResponder!['content'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() {
                    _mensajeParaResponder = null;
                    _mensajeIdEdicion = null;
                    if (_mensajeIdEdicion != null) _mensajeController.clear();
                  }),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _mostrarEmojis ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                    color: const Color(0xFFC35E34),
                  ),
                  onPressed: () {
                    setState(() => _mostrarEmojis = !_mostrarEmojis);
                    if (!_mostrarEmojis) {
                      _focusNode.requestFocus();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _mensajeController,
                      focusNode: _focusNode,
                      onTap: () {
                        if (_mostrarEmojis) setState(() => _mostrarEmojis = false);
                      },
                      decoration: InputDecoration(
                        hintText: _mensajeIdEdicion != null ? 'Edita tu mensaje...' : 'Escribe un mensaje...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.outfit(fontSize: 15),
                      onSubmitted: (_) => _enviarMensaje(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFFC35E34),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(
                      _mensajeIdEdicion != null ? Icons.check_rounded : Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_mostrarEmojis) _buildEmojiPicker(),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: emoji.EmojiPicker(
        onEmojiSelected: (emoji.Category? category, emoji.Emoji emojiData) {
          // El paquete ya maneja la inserción si le pasamos el controller
        },
        onBackspacePressed: () {
          // El paquete ya maneja el backspace si le pasamos el controller
        },
        textEditingController: _mensajeController,
        config: emoji.Config(
          height: 250,
          checkPlatformCompatibility: true,
          emojiViewConfig: emoji.EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            backgroundColor: const Color(0xFFFBF9F8),
            recentsLimit: 28,
            noRecents: const Text(
              'No hay emojis recientes 🐾',
              style: TextStyle(fontSize: 20, color: Colors.black26),
              textAlign: TextAlign.center,
            ),
            loadingIndicator: const SizedBox.shrink(),
          ),
          categoryViewConfig: emoji.CategoryViewConfig(
            initCategory: emoji.Category.RECENT,
            recentTabBehavior: emoji.RecentTabBehavior.RECENT,
            indicatorColor: const Color(0xFFC35E34),
            iconColor: Colors.grey,
            iconColorSelected: const Color(0xFFC35E34),
            backspaceColor: const Color(0xFFC35E34),
            categoryIcons: const emoji.CategoryIcons(),
          ),
          skinToneConfig: const emoji.SkinToneConfig(
            enabled: true,
            dialogBackgroundColor: Colors.white,
            indicatorColor: Colors.grey,
          ),
          bottomActionBarConfig: const emoji.BottomActionBarConfig(
            enabled: false,
          ),
        ),
      ),
    );
  }

  void _mostrarMiembros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFBF9F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Miembros del Chat 🐾',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4440),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<RespuestaApi<Comunidad>>(
                future: ServicioComunidades().obtenerComunidad(widget.comunidadId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.exito && snapshot.data!.datos != null) {
                    return ListaMiembrosComunidad(comunidad: snapshot.data!.datos!);
                  }
                  return const Center(child: Text('No se pudieron cargar los miembros'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
