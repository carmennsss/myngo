import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/configuracion.dart';
import '../../services/servicio_chat.dart';
import '../../utils/configuracion.dart';
import '../inicio/pantalla_inicio.dart';

class PantallaChat extends StatefulWidget {
  final int salaId;
  final String nombreSala;

  const PantallaChat({
    super.key,
    required this.salaId,
    required this.nombreSala,
  });

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final ServicioChat _servicioChat = ServicioChat();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _mensajes = [];
  Map<int, String> _presenciaUsuarios = {};
  int _usuariosOnline = 0;
  int? _miId;
  bool _cargandoHistorial = true;

  /// IDs de mensajes que ya han sido leídos por el receptor.
  final Set<int> _mensajesLeidos = {};

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    _miId = prefs.getInt('usuario_id');
    await _cargarHistorial();
    _conectarWebSockets();
    // Marcar mensajes como leídos al abrir el chat
    await _marcarLeidos();
  }

  Future<void> _cargarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      setState(() => _cargandoHistorial = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${Configuracion.baseUrl}/mensajeria/salas/${widget.salaId}/mensajes/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _mensajes = data.map((m) => {
            'type': 'chat_message',
            'message_id': m['id'],
            'content': m['content'] ?? '',
            'user_id': m['emisor'],
            'username': m['emisor_nombre'],
            'timestamp': m['fecha_envio'],
            'leido': m['leido'] ?? false,
          }).toList();

          // Pre-cargar los mensajes ya leídos
          for (final m in _mensajes) {
            if (m['leido'] == true) {
              _mensajesLeidos.add(m['message_id'] as int);
            }
          }
          _cargandoHistorial = false;
        });
      } else {
        setState(() => _cargandoHistorial = false);
      }
    } catch (_) {
      setState(() => _cargandoHistorial = false);
    }
  }

  Future<void> _marcarLeidos() async {
    await ServicioChat.marcarLeidos(widget.salaId);
    // Notificar al estado principal para actualizar el badge
    if (mounted) {
      final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
      inicioState?.cargarMensajesSinLeer();
    }
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
          } else if (data['type'] == 'messages_read') {
            // El receptor ha leído los mensajes → marcar como leídos en UI
            final List<dynamic> ids = data['leidos_ids'] ?? [];
            for (final id in ids) {
              _mensajesLeidos.add(id as int);
            }
            // Actualizar campo leido en la lista local
            for (int i = 0; i < _mensajes.length; i++) {
              if (_mensajesLeidos.contains(_mensajes[i]['message_id'])) {
                _mensajes[i] = Map<String, dynamic>.from(_mensajes[i])
                  ..['leido'] = true;
              }
            }
          }
        });
      }
    });

    _servicioChat.conectarPresencia((data) {
      if (!mounted) return;
      setState(() {
        if (data['type'] == 'online_users_snapshot') {
          // ── FIX BUG PRESENCIA ──────────────────────────────────────
          // El servidor envía el estado actual de todos al conectarse.
          // Así el receptor ve al emisor como online desde el principio.
          final List<dynamic> ids = data['user_ids'] ?? [];
          for (final id in ids) {
            _presenciaUsuarios[id as int] = 'online';
          }
        } else if (data['type'] == 'status_change') {
          _presenciaUsuarios[data['user_id'] as int] = data['status'] as String;
        }
        _usuariosOnline = _presenciaUsuarios.values.where((s) => s == 'online').length;
      });
    });
  }

  void _enviarMensaje() {
    final texto = _mensajeController.text.trim();
    if (texto.isNotEmpty) {
      // Optimismo: Añadir mensaje localmente de inmediato
      final clientId = DateTime.now().microsecondsSinceEpoch.toString();
      final mensajeOptimista = {
        'type': 'chat_message',
        'content': texto,
        'user_id': _miId,
        'username': 'Tú',
        'timestamp': DateTime.now().toIso8601String(),
        'isOptimistic': true,
        'client_id': clientId,
        'leido': false,
      };

      setState(() {
        _mensajes.insert(0, mensajeOptimista);
      });

      _servicioChat.enviarMensaje(texto, clientId: clientId);
      _mensajeController.clear();
      
      // Auto-scroll si no estamos arriba
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
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
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombreSala,
              style: GoogleFonts.outfit(
                color: const Color(0xFF4A4440),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _usuariosOnline > 0 ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _usuariosOnline > 0
                      ? '$_usuariosOnline conectado${_usuariosOnline > 1 ? 's' : ''} ahora'
                      : 'Sin conexión',
                  style: GoogleFonts.outfit(
                    color: _usuariosOnline > 0
                        ? const Color(0xFFC35E34)
                        : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF4A4440), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cargandoHistorial
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC35E34)))
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
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final msg = _mensajes[index];
                          if (msg['type'] == 'system') {
                            return _buildSystemMessage(msg['content']);
                          }
                          final esMio = msg['user_id'] == _miId;
                          final status =
                              _presenciaUsuarios[msg['user_id']] ?? 'offline';
                          final leido = _mensajesLeidos
                              .contains(msg['message_id'] as int?);
                          return _buildChatBubble(msg, esMio, status, leido);
                        },
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
                fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildChatBubble(
      Map<String, dynamic> msg, bool esMio, String status, bool leido) {
    String timestampStr = '';
    try {
      timestampStr =
          DateFormat('HH:mm').format(DateTime.parse(msg['timestamp']));
    } catch (_) {}

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!esMio)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg['username'] ?? '',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status == 'online'
                            ? Colors.green
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: esMio ? const Color(0xFFC35E34) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esMio ? 16 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Opacity(
                opacity: msg['isOptimistic'] == true ? 0.6 : 1.0,
                child: Text(
                  msg['content'] ?? '',
                  style: GoogleFonts.outfit(
                      color: esMio ? Colors.white : const Color(0xFF4A4440),
                      fontSize: 15),
                ),
              ),
            ),
            // Timestamp + estado de lectura (solo en mensajes propios)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 4, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timestampStr.isNotEmpty)
                    Text(timestampStr,
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: Colors.grey.shade500)),
                  if (esMio) ...[
                    const SizedBox(width: 4),
                    if (msg['isOptimistic'] == true)
                      Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey.shade400)
                    else
                      // ✓ gris = enviado, ✓✓ azul = visto
                      leido
                          ? const Icon(Icons.done_all_rounded,
                              size: 14, color: Color(0xFF248EA6))
                          : Icon(Icons.done_rounded,
                              size: 14, color: Colors.grey.shade400),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _mensajeController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
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
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _enviarMensaje,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
