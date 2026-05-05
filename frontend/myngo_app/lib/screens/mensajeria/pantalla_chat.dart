import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:flutter/foundation.dart' as foundation;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
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

// Painter eficiente para patrones de fondo
class PatternPainter extends CustomPainter {
  final String patternType;
  
  PatternPainter({required this.patternType});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const spacing = 60.0;
    
    switch (patternType) {
      case 'dots':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), 3, paint);
          }
        }
        break;
      case 'stars':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            _drawStar(canvas, Offset(x, y), 6, paint);
          }
        }
        break;
      case 'triangles':
        for (double x = 0; x < size.width; x += spacing) {
          for (double y = 0; y < size.height; y += spacing) {
            _drawTriangle(canvas, Offset(x, y), 8, paint);
          }
        }
        break;
      case 'waves':
        for (double y = 0; y < size.height; y += 40) {
          for (double x = 0; x <= size.width; x += 5) {
            final nextX = x + 5;
            final nextY = y + (y.toInt() % 2 == 0 ? 3 : -3);
            if (nextX <= size.width) {
              canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint..strokeWidth = 0.5);
            }
          }
        }
        break;
      case 'lines':
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint..strokeWidth = 1);
        }
        break;
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const angles = [0, 72, 144, 216, 288];
    final points = <Offset>[];
    for (final angle in angles) {
      final rad = (angle * 3.14159 / 180);
      points.add(Offset(
        center.dx + size * 0.5 * (0.809 * cos(rad - 1.571) + 0.309 * cos(rad - 1.571)),
        center.dy + size * 0.5 * (0.809 * sin(rad - 1.571) + 0.309 * sin(rad - 1.571)),
      ));
    }
    
    // Dibujar un punto simple en lugar de una estrella compleja para mantener performance
    canvas.drawCircle(center, 3, paint);
  }
  
  void _drawTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx + size / 2, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy + size / 2);
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  
  @override
  bool shouldRepaint(PatternPainter oldDelegate) => oldDelegate.patternType != patternType;
}

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
  MensajeChat? _mensajeEdicion;
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

  Future<void> _enviarFoto() async {
    if (_sala == null) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (imagen != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo imagen...'))
      );
      
      final url = await _servicio.uploadChatImage(_sala!.id, imagen);
      
      if (url != null && mounted) {
        _servicio.enviarMensajeChat('', tipo: 'IMAGEN', url_archivo_s3: url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen enviada! 📷'))
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir imagen'))
        );
      }
    }
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
    
    final edicionId = _mensajeEdicion?.id;
    final respuestaId = _mensajeRespuesta?.id;

    _mensajeController.clear();
    setState(() {
      _mostrarEmojiPicker = false;
      _mensajeRespuesta = null;
      _mensajeEdicion = null;
    });
    
    try {
      if (edicionId != null) {
        await _servicio.editarMensaje(edicionId, texto);
      } else {
        _servicio.enviarMensajeChat(
          texto, 
          referenciaA: respuestaId,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildBarraRespuesta() {
    if (_mensajeRespuesta == null && _mensajeEdicion == null) return const SizedBox.shrink();

    final esEdicion = _mensajeEdicion != null;
    final msg = esEdicion ? _mensajeEdicion! : _mensajeRespuesta!;

    String emisorNombre = 'Usuario';
    if (_sala != null) {
      try {
        final part = _sala!.participantes.firstWhere((p) => p.usuarioId == msg.emisorId);
        emisorNombre = part.nombreAMostrar;
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: esEdicion ? Colors.blue.withOpacity(0.1) : Colors.grey[200],
        border: Border(left: BorderSide(color: esEdicion ? Colors.blue : const Color(0xFFC35E34), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  esEdicion ? 'Editando mensaje' : 'Respondiendo a $emisorNombre',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: esEdicion ? Colors.blue : const Color(0xFFC35E34),
                  ),
                ),
                Text(
                  msg.contenido ?? 'Archivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() {
              _mensajeRespuesta = null;
              _mensajeEdicion = null;
              if (esEdicion) _mensajeController.clear();
            }),
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
        body: _buildBody(),
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
    final estilo = perso?.estiloBurbuja ?? 'solido';
    final fontSize = (perso?.fontSize ?? 14).toDouble();
    
    final colorMio = _colorFromHex(perso?.colorBurbujaMio) ?? const Color(0xFFF28B50);
    final colorOtro = _colorFromHex(perso?.colorBurbujaOtro) ?? const Color(0xFFEEEEEE);
    
    final colorNombreMio = _colorFromHex(perso?.colorNombreMio) ?? const Color(0xFFF28B50);
    final colorNombreOtro = _colorFromHex(perso?.colorNombreOtro) ?? const Color(0xFF4A4440);
    
    final radius = forma == 'redondeada' ? 18.0 : 4.0;
    
    BoxDecoration deco;
    switch (estilo) {
      case 'cristal':
        deco = BoxDecoration(
          color: (esMio ? colorMio : colorOtro).withOpacity(0.4),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        );
        break;
      case 'neon':
        deco = BoxDecoration(
          color: (esMio ? colorMio : colorOtro).withOpacity(0.1),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: esMio ? colorMio : colorOtro, width: 2),
          boxShadow: [BoxShadow(color: (esMio ? colorMio : colorOtro).withOpacity(0.3), blurRadius: 10, spreadRadius: 1)],
        );
        break;
      case 'amor':
        deco = BoxDecoration(
          color: const Color(0xFFFCE4EC),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: Colors.pinkAccent, width: 1.5),
        );
        break;
      case 'vaquero':
        deco = BoxDecoration(
          color: const Color(0xFFD7CCC8),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: const Color(0xFF5D4037), width: 2),
        );
        break;
      case 'bosque':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
          borderRadius: _getBorderRadius(esMio, radius),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        );
        break;
      case 'cyber':
        deco = BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: _getBorderRadius(esMio, radius),
          border: const Border(
            top: BorderSide(color: Color(0xFF00E5FF), width: 2),
            bottom: BorderSide(color: Color(0xFF00E5FF), width: 2),
            left: BorderSide(color: Color(0xFF00E5FF), width: 8),
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 10)],
        );
        break;
      case 'kawaii':
        deco = BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10)],
        );
        break;
      case 'aventura':
        deco = BoxDecoration(
          color: const Color(0xFFF5E6CA),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8D6E63), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(2, 2))],
        );
        break;
      case 'retro':
      default: // solido
        deco = BoxDecoration(
          color: esMio ? colorMio : colorOtro,
          borderRadius: _getBorderRadius(esMio, radius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
        );
    }

    final bubbleColor = esMio ? colorMio : colorOtro;
    final textColor = estilo == 'neon' ? bubbleColor : (bubbleColor.computeLuminance() > 0.5 ? Colors.black : Colors.white);

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
                child: Text(
                  displayName, 
                  style: GoogleFonts.outfit(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: colorNombreOtro
                  )
                ),
              ),
            if (esMio)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: Text(
                  'Tú', 
                  style: GoogleFonts.outfit(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: colorNombreMio
                  )
                ),
              ),
            GestureDetector(
              onLongPress: () => _mostrarMenuMensaje(msg),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: deco,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (msg.referenciaADetalle != null) 
                          _buildCitaMensaje(msg.referenciaADetalle!, esMio),
                        Text(
                          texto,
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: fontSize,
                            fontWeight: (estilo == 'neon' || estilo == 'robot') ? FontWeight.bold : FontWeight.normal,
                            fontStyle: borrado ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        if (!borrado) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatHora(msg.fechaEnvio),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: esMio ? (colorMio.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70) : Colors.black45,
                                ),
                              ),
                              if (esMio) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  msg.leidoPorIds.isNotEmpty ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: msg.leidoPorIds.isNotEmpty ? const Color(0xFF248EA6) : (estilo == 'neon' ? colorMio : (colorMio.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildDecoracionesBurbuja(estilo, esMio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoracionesBurbuja(String estilo, bool esMio) {
    switch (estilo) {
      case 'amor':
        return Positioned(
          top: -12,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('💖', style: TextStyle(fontSize: 20)),
        );
      case 'vaquero':
        return Positioned(
          top: -18,
          right: esMio ? -5 : null,
          left: !esMio ? -5 : null,
          child: const Text('🤠', style: TextStyle(fontSize: 22)),
        );
      case 'bosque':
        return Positioned(
          top: -15,
          left: esMio ? -10 : null,
          right: !esMio ? -10 : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🍃', style: TextStyle(fontSize: 18)),
              Text('🌸', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      case 'cyber':
        return Positioned(
          top: 5,
          right: esMio ? 5 : null,
          left: !esMio ? 5 : null,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
          ),
        );
      case 'kawaii':
        return Stack(
          children: [
            Positioned(top: -15, left: -5, child: const Text('✨', style: TextStyle(fontSize: 18))),
            Positioned(bottom: -10, right: -5, child: const Text('🎀', style: TextStyle(fontSize: 22))),
            Positioned(top: -5, right: 10, child: const Text('⭐', style: TextStyle(fontSize: 12))),
          ],
        );
      case 'aventura':
        return Positioned(
          top: -18,
          right: 0,
          child: const Text('📜', style: TextStyle(fontSize: 24)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  BorderRadius _getBorderRadius(bool esMio, double radius) {
    if (esMio) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: const Radius.circular(4),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
        bottomLeft: const Radius.circular(4),
      );
    }
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
    if (_sala == null) return;
    
    // Si es un chat de comunidad, mostramos el componente existente
    if (_sala!.esGrupal && _sala!.comunidadId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: ListaMiembrosComunidad(comunidad: Comunidad(
            id: _sala!.comunidadId!, 
            nombre: _sala!.nombre ?? '', 
            descripcion: '', creadorNombre: '', urlPortada: '', esPublica: true, esVerificada: false, esMiembro: true, ratingMedio: 0.0, fechaCreacion: DateTime.now(), miRol: 'Miembro'
          )),
        ),
      );
      return;
    }

    // Si es un chat privado (DM), mostramos los participantes directamente
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              'Participantes del Chat',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4A4440)),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _sala!.participantes.length,
                itemBuilder: (context, index) {
                  final p = _sala!.participantes[index];
                  final esYo = p.usuarioId == _miId;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: p.usuario?.urlAvatar != null 
                        ? CachedNetworkImageProvider(p.usuario!.urlAvatar!) 
                        : null,
                      child: p.usuario?.urlAvatar == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      esYo ? '${p.nombreAMostrar} (Tú)' : p.nombreAMostrar,
                      style: GoogleFonts.outfit(fontWeight: esYo ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: Text(esYo ? 'Conectado' : 'Participante'),
                    trailing: !esYo ? IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/perfil/${p.usuarioId}');
                      },
                    ) : null,
                  );
                },
              ),
            ),
          ],
        ),
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
              if (esMio && msg.tipo != 'SISTEMA') ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar mensaje'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _mensajeEdicion = msg;
                      _mensajeController.text = msg.contenido ?? '';
                    });
                    _focusNode.requestFocus();
                  },
                ),
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
      builder: (dialogContext) => AlertDialog(
        title: Text('Info del mensaje', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enviado el ${_formatFechaCompleta(msg.fechaEnvio)}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
              const Divider(height: 24),
              Text('Leído por:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (lectores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Nadie ha leído este mensaje todavía.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: lectores.length,
                  itemBuilder: (context, index) {
                    final lector = lectores[index];
                    final fechaLectura = msg.infoLectura[lector.usuarioId];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: lector.usuario?.urlAvatar != null 
                          ? CachedNetworkImageProvider(lector.usuario!.urlAvatar!) 
                          : null,
                        child: lector.usuario?.urlAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(lector.nombreAMostrar, style: GoogleFonts.outfit(fontSize: 14)),
                      subtitle: fechaLectura != null 
                        ? Text('Leído el ${_formatFechaCompleta(fechaLectura)}', style: GoogleFonts.outfit(fontSize: 12))
                        : null,
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cerrar')
          ),
        ],
      ),
    );
  }

  String _formatFechaCompleta(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} a las ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
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
                  onTap: _enviarFoto,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.white, size: 20),
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

  Widget _buildBody() {
    if (_estaCargando && _mensajes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    final perso = _sala?.personalizacion;
    final colorFondo = _colorFromHex(perso?.colorFondo) ?? Colors.white;
    
    // Gradientes predefinidos
    final Map<String, List<Color>> gradientes = {
      'sunset': [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      'ocean': [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
      'forest': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'purple': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      'dark': [const Color(0xFF232526), const Color(0xFF414345)],
      'peach': [const Color(0xFFED4264), const Color(0xFFFFEDBC)],
      'lavender': [const Color(0xFFEECDA3), const Color(0xFFEF629F)],
    };

    final gradColors = perso?.gradienteFondo != null ? gradientes[perso!.gradienteFondo] : null;

    return Stack(
      children: [
        // Fondo base
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: gradColors == null ? colorFondo : null,
            gradient: gradColors != null ? LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          ),
        ),
        // Patrón geométrico
        if (perso?.patronFondo != null)
          Opacity(
            opacity: 0.05,
            child: _buildPatternBackground(perso!.patronFondo!),
          ),
        // Contenido
        Column(
          children: [
            Expanded(child: _buildListaMensajes()),
            _buildBarraRespuesta(),
            _buildInputArea(),
            if (_mostrarEmojiPicker) _buildEmojiPicker(),
          ],
        ),
      ],
    );
  }

  Widget _buildPatternBackground(String id) {
    return CustomPaint(
      painter: PatternPainter(patternType: id),
      child: Container(),
    );
  }

  String _formatHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
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
