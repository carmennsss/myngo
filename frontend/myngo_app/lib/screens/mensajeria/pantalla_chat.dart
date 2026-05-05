import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/foundation.dart' as foundation;
import '../../utils/configuracion.dart';
import '../../services/servicio_mensajeria.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/comunidad.dart';
import '../../models/sala_chat.dart';
import '../../models/participante_chat.dart';
import '../../models/mensaje_chat.dart';
import '../../models/usuario.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../comunidades/widgets_detalle/lista_miembros_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import 'pantalla_personalizacion_chat.dart';

class PantallaChat extends StatefulWidget {
  final int? salaId;
  final int? comunidadId;
  final bool esChatGeneral;
  final String? nombreSala;
  final int? otroUsuarioId;

  const PantallaChat({
    super.key, 
    this.salaId, 
    this.comunidadId,
    this.esChatGeneral = false,
    this.nombreSala,
    this.otroUsuarioId,
  });

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final _servicio = ServicioMensajeria();
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  
  SalaChat? _sala;
  List<MensajeChat> _mensajes = [];
  bool _estaCargando = true;
  int? _miId;
  
  // Estados de presencia
  Map<int, String> _estadosPresencia = {};
  
  bool _mostrarEmojiPicker = false;
  MensajeChat? _mensajeRespuesta;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _mostrarEmojiPicker = false);
      }
    });
    _inicializar();
  }

  Future<void> _inicializar() async {
    _miId = await ServicioUsuarios().obtenerIdUsuario();
    await _cargarDatos();
    _conectarWebSocket();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _estaCargando = true);
    try {
      if (widget.esChatGeneral && widget.comunidadId != null) {
        _sala = await _servicio.obtenerSalaGeneralComunidad(widget.comunidadId!);
      } else if (widget.salaId != null) {
        _sala = await _servicio.obtenerDetalleSala(widget.salaId!);
      }

      if (_sala != null) {
        final msgsData = await _servicio.obtenerMensajesSala(_sala!.id);
        _mensajes = msgsData.map((m) => MensajeChat.fromJson(m)).toList();
        
        // Marcamos la sala como activa para que se limpien los no leídos
        if (mounted) {
          Provider.of<ChatProvider>(context, listen: false).setSalaActiva(_sala!.id);
        }
      }
    } catch (e) {
      debugPrint('Error cargando chat: $e');
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _conectarWebSocket() {
    if (_sala == null) return;
    _servicio.conectarASala(_sala!.id, (datos) {
      if (!mounted) return;
      setState(() {
        final type = datos['type'];
        if (type == 'chat_message') {
          final nuevoMsg = MensajeChat.fromJson(datos);
          _mensajes.insert(0, nuevoMsg);
        } else if (type == 'room_updated') {
          _sala = SalaChat.fromJson(datos['data']);
        } else if (type == 'message_deleted') {
          final mId = datos['mensaje_id'];
          final idx = _mensajes.indexWhere((m) => m.id == mId);
          if (idx != -1) {
            _mensajes[idx] = _mensajes[idx].copyWith(
              borradoParaTodos: true,
              contenido: 'Este mensaje fue eliminado',
            );
          }
        } else if (type == 'messages_read') {
          final ids = List<int>.from(datos['leidos_ids'] ?? []);
          final lectorId = datos['leido_por'];
          for (var i = 0; i < _mensajes.length; i++) {
            if (ids.contains(_mensajes[i].id)) {
              if (!_mensajes[i].leidoPorIds.contains(lectorId)) {
                _mensajes[i].leidoPorIds.add(lectorId);
              }
            }
          }
        }
      });
    });
  }

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _sala == null) return;
    
    _mensajeController.clear();
    setState(() => _mostrarEmojiPicker = false);
    
    try {
      _servicio.enviarMensajeChat(
        texto, 
        referenciaA: _mensajeRespuesta?.id,
      );
      
      if (mounted) {
        setState(() => _mensajeRespuesta = null);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildBarraRespuesta() {
    if (_mensajeRespuesta == null) return const SizedBox.shrink();

    String emisorNombre = 'Usuario';
    if (_sala != null) {
      try {
        final part = _sala!.participantes.firstWhere((p) => p.usuarioId == _mensajeRespuesta!.emisorId);
        emisorNombre = part.nombreAMostrar;
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: const Border(left: BorderSide(color: Color(0xFFC35E34), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Respondiendo a $emisorNombre',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFC35E34),
                  ),
                ),
                Text(
                  _mensajeRespuesta!.contenido ?? 'Archivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _mensajeRespuesta = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perso = _sala?.personalizacion;
    final colorFondo = _colorFromHex(perso?.colorFondo);

    return WillPopScope(
      onWillPop: () {
        if (_mostrarEmojiPicker) {
          setState(() => _mostrarEmojiPicker = false);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: colorFondo,
        appBar: AppBar(
          title: _buildAppBarTitle(),
          actions: [
            IconButton(
              icon: _estaCargando || _sala == null
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    )
                  : const Icon(Icons.palette_outlined, color: Color(0xFFC35E34)),
              tooltip: 'Personalizar chat',
              onPressed: (_sala == null) 
                ? null 
                : () async {
                    final actualizado = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PantallaPersonalizacionChat(sala: _sala!)),
                    );
                    if (actualizado == true) {
                      // Solo recargamos si hubo cambios, pero sin bloquear toda la UI si es posible
                      _cargarDatos();
                    }
                  },
            ),
            IconButton(
              icon: const Icon(Icons.people_outline),
              onPressed: () => _mostrarMiembros(context),
            ),
          ],
        ),
        body: _estaCargando 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
          : Column(
              children: [
                Expanded(
                  child: _buildListaMensajes(),
                ),
                _buildInputArea(),
                if (_mostrarEmojiPicker) _buildEmojiPicker(),
              ],
            ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final nombre = _sala?.nombre ?? widget.nombreSala ?? 'Chat';
        String subtitulo = '';
        String? avatarUrl;
        bool esDM = _sala != null && !_sala!.esGrupal;
        
        if (_sala != null) {
          if (_sala!.esGrupal) {
            final onlineCount = _sala!.participantes.where((p) => 
              chatProvider.isUsuarioOnline(p.usuarioId)
            ).length;
            subtitulo = '${_sala!.participantes.length} miembros • $onlineCount en línea';
            avatarUrl = _sala!.avatarS3;
          } else {
            final otroId = _sala!.otroUsuarioId;
            final estado = chatProvider.getEstadoUsuario(otroId ?? 0);
            subtitulo = estado == 'ACTIVO' ? 'En línea' : (estado == 'OCUPADO' ? 'Ocupado' : 'Desconectado');
            
            ParticipanteChat? otroParticipante;
            if (_sala!.participantes.isNotEmpty) {
              try {
                otroParticipante = _sala!.participantes.firstWhere((p) => p.usuarioId == otroId);
              } catch (_) {
                try {
                  otroParticipante = _sala!.participantes.firstWhere((p) => p.usuarioId != _miId);
                } catch (_) {
                  otroParticipante = _sala!.participantes.first;
                }
              }
            }
            avatarUrl = otroParticipante?.usuario?.urlAvatar;
          }
        }

        return Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (avatarUrl != null)
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                  backgroundColor: const Color(0xFFF28B50).withOpacity(0.2),
                  child: (avatarUrl == null) 
                    ? Icon(esDM ? Icons.person_outline : Icons.chat_bubble_outline, 
                        size: 20, color: const Color(0xFFF28B50)) 
                    : null,
                ),
                if (esDM && _sala != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getColorEstado(chatProvider.getEstadoUsuario(_sala!.otroUsuarioId ?? 0)),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitulo, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO': return Colors.green;
      case 'OCUPADO': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildListaMensajes() {
    if (_mensajes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No hay mensajes aún.', style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length,
      itemBuilder: (context, index) {
        final msg = _mensajes[index];
        if (msg.esSistema) return _buildMensajeSistema(msg);
        return _buildBurbujaMensaje(msg);
      },
    );
  }

  Widget _buildMensajeSistema(MensajeChat msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(
        msg.contenido ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildBurbujaMensaje(MensajeChat msg) {
    final esMio = msg.emisorId == _miId;
    final borrado = msg.borradoParaTodos;
    final texto = borrado ? 'Este mensaje fue eliminado' : (msg.contenido ?? '');
    final perso = _sala?.personalizacion;
    final forma = perso?.formaBurbuja ?? 'redondeada';
    final fontSize = (perso?.fontSize ?? 14).toDouble();
    
    final colorMio = _colorFromHex(perso?.colorBurbujaMio) ?? const Color(0xFFF28B50);
    final colorOtro = _colorFromHex(perso?.colorBurbujaOtro) ?? const Color(0xFFEEEEEE);
    
    String displayName = '';
    if (!esMio && _sala != null) {
      try {
        final part = _sala!.participantes.firstWhere((p) => p.usuarioId == msg.emisorId);
        displayName = part.nombreAMostrar;
      } catch (_) {}
    }

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!esMio && displayName.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(displayName, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            GestureDetector(
              onLongPress: () => _mostrarMenuMensaje(msg),
              child: Container(
                decoration: BoxDecoration(
                  color: esMio ? colorMio : colorOtro,
                  borderRadius: forma == 'redondeada' 
                    ? BorderRadius.circular(18)
                    : BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (msg.referenciaADetalle != null) 
                      _buildCitaMensaje(msg.referenciaADetalle!, esMio),
                    Text(
                      texto,
                      style: GoogleFonts.outfit(
                        color: esMio ? Colors.white : Colors.black87,
                        fontSize: fontSize,
                        fontStyle: borrado ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (esMio && !borrado) ...[
                      const SizedBox(height: 2),
                      Icon(
                        msg.leidoPorIds.isNotEmpty ? Icons.done_all : Icons.done,
                        size: 14,
                        color: msg.leidoPorIds.isNotEmpty ? Colors.blue[200] : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitaMensaje(Map<String, dynamic> cita, bool esMio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: esMio ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: esMio ? Colors.white70 : const Color(0xFFC35E34),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cita['emisor_nombre'] ?? 'Usuario',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: esMio ? Colors.white : const Color(0xFFC35E34),
            ),
          ),
          Text(
            cita['contenido'] ?? 'Archivo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: esMio ? Colors.white.withOpacity(0.8) : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMiembros(BuildContext context) {
    if (_sala == null && widget.comunidadId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: ListaMiembrosComunidad(comunidad: Comunidad(
          id: _sala?.comunidadId ?? widget.comunidadId!, 
          nombre: _sala?.nombre ?? '', 
          descripcion: '', creadorNombre: '', urlPortada: '', esPublica: true, esVerificada: false, esMiembro: true, ratingMedio: 0.0, fechaCreacion: DateTime.now(), miRol: 'Miembro'
        )),
      ),
    );
  }

  void _mostrarMenuMensaje(MensajeChat msg) {
    final esMio = msg.emisorId == _miId;
    if (msg.borradoParaTodos) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _mensajeRespuesta = msg);
                  _focusNode.requestFocus();
                },
              ),
              if (esMio) ...[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Info del mensaje'),
                  onTap: () {
                    Navigator.pop(context);
                    _verLectores(msg);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Borrar para todos', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarMensaje(msg, paraTodos: true);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Borrar para mí'),
                onTap: () {
                  Navigator.pop(context);
                  _eliminarMensaje(msg, paraTodos: false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _verLectores(MensajeChat msg) {
    if (_sala == null) return;
    
    // Filtramos los participantes que están en la lista de lectores
    final lectores = _sala!.participantes.where((p) => msg.leidoPorIds.contains(p.usuarioId)).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Leído por', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          child: lectores.isEmpty
            ? const Text('Nadie ha leído este mensaje todavía.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: lectores.length,
                itemBuilder: (context, index) {
                  final lector = lectores[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: lector.usuario?.urlAvatar != null 
                        ? CachedNetworkImageProvider(lector.usuario!.urlAvatar!) 
                        : null,
                      child: lector.usuario?.urlAvatar == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(lector.nombreAMostrar),
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _eliminarMensaje(MensajeChat msg, {required bool paraTodos}) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paraTodos ? '¿Borrar para todos?' : '¿Borrar para mí?'),
        content: Text(paraTodos 
          ? 'Esta acción eliminará el mensaje para todos los miembros del chat.' 
          : 'Esta acción ocultará el mensaje de tu historial personal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Borrar', style: TextStyle(color: paraTodos ? Colors.red : Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await _servicio.borrarMensaje(msg.id, paraTodos: paraTodos);
      if (exito) {
        if (!paraTodos) {
          // Si es borrado local, lo quitamos de la lista manualmente
          setState(() {
            _mensajes.removeWhere((m) => m.id == msg.id);
          });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al borrar el mensaje')));
      }
    }
  }

  Widget _buildInputArea() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBarraRespuesta(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: esOscuro ? Colors.grey[900] : Colors.white,
            border: const Border(top: BorderSide(color: Colors.black12)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _mostrarEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            if (_mostrarEmojiPicker) {
                              _focusNode.requestFocus();
                            } else {
                              _focusNode.unfocus();
                              setState(() => _mostrarEmojiPicker = true);
                            }
                          },
                        ),
                        Expanded(
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) {
                              if (event is RawKeyDownEvent && 
                                  event.logicalKey == LogicalKeyboardKey.enter && 
                                  !event.isShiftPressed) {
                                _enviarMensaje();
                              }
                            },
                            child: TextField(
                              controller: _mensajeController,
                              focusNode: _focusNode,
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              style: GoogleFonts.outfit(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _enviarMensaje(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BotonTactil(
                  onTap: _enviarMensaje,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC35E34),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: emoji.EmojiPicker(
        onEmojiSelected: (category, emojiData) {
          _mensajeController.text = _mensajeController.text + emojiData.emoji;
          _mensajeController.selection = TextSelection.fromPosition(
            TextPosition(offset: _mensajeController.text.length),
          );
        },
        config: emoji.Config(
          emojiViewConfig: emoji.EmojiViewConfig(
            columns: 7,
            emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            buttonMode: emoji.ButtonMode.MATERIAL,
            backgroundColor: const Color(0xFFF2F2F2),
            noRecents: const Text(
              'No hay recientes',
              style: TextStyle(fontSize: 16, color: Colors.black26),
              textAlign: TextAlign.center,
            ),
          ),
          categoryViewConfig: const emoji.CategoryViewConfig(
            initCategory: emoji.Category.RECENT,
            indicatorColor: Color(0xFFC35E34),
            iconColorSelected: Color(0xFFC35E34),
            backspaceColor: Color(0xFFC35E34),
          ),
          searchViewConfig: const emoji.SearchViewConfig(
            backgroundColor: Color(0xFFF2F2F2),
            buttonIconColor: Colors.grey,
            hintText: 'Buscar emoji...',
          ),
          bottomActionBarConfig: const emoji.BottomActionBarConfig(
            buttonColor: Color(0xFFF2F2F2),
            buttonIconColor: Colors.grey,
          ),
        ),
      ),
    );
  }

  Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      debugPrint('Error parsing color $hex: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Al salir de la pantalla, ya no hay sala activa
    try {
      Provider.of<ChatProvider>(context, listen: false).setSalaActiva(null);
    } catch (_) {}
    
    _mensajeController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _servicio.dispose();
    super.dispose();
  }
}
