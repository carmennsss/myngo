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
import '../../widgets/mensajeria/decoraciones_burbuja.dart';
import '../../models/usuario.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/mensajeria/componentes_multimedia.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:mime/mime.dart';
import '../comunidades/widgets_detalle/lista_miembros_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import 'pantalla_personalizacion_chat.dart';


class PatternPainter extends CustomPainter {
  final String patternType;
  
  PatternPainter({required this.patternType});
  
  @override
  void paint(Canvas canvas, Size size) {

    if (!size.width.isFinite || !size.height.isFinite || 
        size.width <= 0 || size.height <= 0 || 
        size.width > 10000 || size.height > 10000) {
      return;
    }

    final paint = Paint()..color = Colors.white;
    const double spacing = 60.0;
    

    if (spacing <= 0) return;
    
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
          if (y > 5000) break; // Límite de seguridad
          for (double x = 0; x <= size.width; x += 5) {
            if (x > 5000) break; // Límite de seguridad
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
    final path = Path();
    final double innerRadius = size / 2.5;
    final double outerRadius = size;
    const int numPoints = 5;
    const double angleStep = (2 * pi) / numPoints;

    for (int i = 0; i < numPoints; i++) {
      double outerAngle = i * angleStep - pi / 2;
      double innerAngle = outerAngle + angleStep / 2;

      double x1 = center.dx + outerRadius * cos(outerAngle);
      double y1 = center.dy + outerRadius * sin(outerAngle);
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }

      double x2 = center.dx + innerRadius * cos(innerAngle);
      double y2 = center.dy + innerRadius * sin(innerAngle);
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }
  
  void _drawTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy + size);
    path.lineTo(center.dx - size, center.dy + size);
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
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
  bool _estaCargandoMas = false;
  bool _puedeCargarMas = true;
  int? _miId;
  

  Map<int, String> _estadosPresencia = {};
  
  bool _mostrarEmojiPicker = false;
  final List<XFile> _archivosSeleccionados = [];
  bool _estaSubiendoMedia = false;
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
    _scrollController.addListener(_onScroll);
    _inicializar();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_estaCargandoMas &&
        _puedeCargarMas) {
      _cargarMasMensajes();
    }
  }

  Future<void> _inicializar() async {
    _miId = await ServicioUsuarios().obtenerIdUsuario();
    await _cargarDatos();
    _conectarWebSocket();
  }

  void _enviarFoto() async {
    final picker = ImagePicker();
    
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
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería de imágenes'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickMultiImage();
                  if (picked.isNotEmpty) {
                    setState(() {
                      _archivosSeleccionados.addAll(picked.take(4 - _archivosSeleccionados.length));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Vídeo de la galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickVideo(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      if (_archivosSeleccionados.length < 4) {
                        _archivosSeleccionados.add(picked);
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() {
                      if (_archivosSeleccionados.length < 4) {
                        _archivosSeleccionados.add(picked);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() {
      _estaCargando = true;
      _puedeCargarMas = true;
    });
    try {
      if (widget.esChatGeneral && widget.comunidadId != null) {
        _sala = await _servicio.obtenerSalaGeneralComunidad(widget.comunidadId!);
      } else if (widget.salaId != null) {
        _sala = await _servicio.obtenerDetalleSala(widget.salaId!);
      }

      if (_sala != null) {
        final msgsData = await _servicio.obtenerMensajesSala(_sala!.id);
        _mensajes = msgsData.map((m) => MensajeChat.fromJson(m)).toList();
        
        if (msgsData.length < 30) {
          _puedeCargarMas = false;
        }


        if (mounted) {
          Provider.of<ChatProvider>(context, listen: false).setSalaActiva(_sala!.id);
        }
      }
    } catch (e) {

    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  Future<void> _cargarMasMensajes() async {
    if (_sala == null || _estaCargandoMas || !_puedeCargarMas) return;

    setState(() => _estaCargandoMas = true);
    try {
      final msgsData = await _servicio.obtenerMensajesSala(
        _sala!.id,
        offset: _mensajes.length,
      );

      if (msgsData.isEmpty) {
        _puedeCargarMas = false;
      } else {
        final nuevosMsgs = msgsData.map((m) => MensajeChat.fromJson(m)).toList();
        setState(() {
          _mensajes.addAll(nuevosMsgs);
          if (nuevosMsgs.length < 30) {
            _puedeCargarMas = false;
          }
        });
      }
    } catch (e) {

    } finally {
      if (mounted) setState(() => _estaCargandoMas = false);
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

          _servicio.marcarMensajesLeidosWS();
        } else if (type == 'room_updated') {
          _sala = SalaChat.fromJson(datos['data']);
        } else if (type == 'message_updated') {
          final mData = datos['message'] ?? datos['data'];
          if (mData != null) {
            final actualizado = MensajeChat.fromJson(mData);
            final idx = _mensajes.indexWhere((m) => m.id == actualizado.id);
            if (idx != -1) {
              _mensajes[idx] = actualizado;
            }
          }
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
          final rawIds = datos['leidos_ids'] as List?;
          if (rawIds != null) {
            final ids = rawIds.map((e) => (e as num).toInt()).toList();
            final lectorId = (datos['leido_por'] as num).toInt();
            
            bool huboCambios = false;
            for (var i = 0; i < _mensajes.length; i++) {
              if (ids.contains(_mensajes[i].id)) {
                if (!_mensajes[i].leidoPorIds.contains(lectorId)) {
                  _mensajes[i] = _mensajes[i].copyWith(
                    leidoPorIds: [..._mensajes[i].leidoPorIds, lectorId],
                  );
                  huboCambios = true;
                }
              }
            }
            if (huboCambios) {
              _mensajes = List.from(_mensajes);
            }
          }
        }
      });
    }, alConectar: () => _servicio.marcarMensajesLeidosWS());
  }

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty && _archivosSeleccionados.isEmpty) return;
    if (_sala == null) return;
    
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
        final exito = await _servicio.editarMensaje(edicionId, texto);
        if (exito) {

          setState(() {
            final idx = _mensajes.indexWhere((m) => m.id == edicionId);
            if (idx != -1) {
              _mensajes[idx] = _mensajes[idx].copyWith(
                contenido: texto,
                esEditado: true,
                fechaEdicion: DateTime.now(),
              );
            }
          });
        }
      } else {

        List<Map<String, dynamic>> attachments = [];
        if (_archivosSeleccionados.isNotEmpty) {
          setState(() => _estaSubiendoMedia = true);
          
          for (var file in _archivosSeleccionados) {
            final res = await _servicio.uploadMedia(_sala!.id, file);
            if (res != null) {
              attachments.add({
                'id': res['id'],
                'url': res['file_url'],
                'tipo': res['file_type'] == 'video' ? 'V' : 'I',
              });
            }
          }
          
          setState(() {
            _estaSubiendoMedia = false;
            _archivosSeleccionados.clear();
          });
        }

        String tipoFinal = 'TEXTO';
        if (attachments.isNotEmpty) {

          if (attachments.length == 1 && attachments.first['tipo'] == 'V') {
            tipoFinal = 'VIDEO';
          } else {
            tipoFinal = 'IMAGEN';
          }
        }

        _servicio.enviarMensajeChat(
          texto, 
          referenciaA: respuestaId,
          tipo: tipoFinal,
          attachments: attachments.isNotEmpty ? attachments : null,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _estaSubiendoMedia = false);
    }
  }

  Widget _buildBarraRespuesta() {
    if (_mensajeRespuesta == null && _mensajeEdicion == null) return const SizedBox.shrink();

    final esEdicion = _mensajeEdicion != null;
    final msg = esEdicion ? _mensajeEdicion! : _mensajeRespuesta!;

    String emisorNombre = 'Usuario';
    if (_sala != null) {
      for (var p in _sala!.participantes) {
        if (p.usuarioId == msg.emisorId) {
          emisorNombre = p.nombreAMostrar;
          break;
        }
      }
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
            final mCount = _sala!.numMiembros > 0 ? _sala!.numMiembros : _sala!.participantes.length;
            subtitulo = '$mCount miembros • $onlineCount en línea';
            avatarUrl = _sala!.avatarS3;
          } else {
            final otroId = _sala!.otroUsuarioId;
            final estado = chatProvider.getEstadoUsuario(otroId ?? 0);
            subtitulo = estado == 'ACTIVO' ? 'En línea' : (estado == 'OCUPADO' ? 'Ocupado' : 'Desconectado');
            
            ParticipanteChat? otroParticipante;
            if (_sala!.participantes.isNotEmpty) {
              for (var p in _sala!.participantes) {
                if (p.usuarioId == otroId) {
                  otroParticipante = p;
                  break;
                }
              }
              if (otroParticipante == null) {
                for (var p in _sala!.participantes) {
                  if (p.usuarioId != _miId) {
                    otroParticipante = p;
                    break;
                  }
                }
              }
              otroParticipante ??= _sala!.participantes.firstOrNull;
            }

            avatarUrl = _sala!.avatarS3 ?? otroParticipante?.usuario?.urlAvatar;
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
      itemCount: _mensajes.length + (_estaCargandoMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _mensajes.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50)),
            ),
          );
        }
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
                        
                        if (msg.attachments.isNotEmpty)
                          ChatMediaGrid(attachments: msg.attachments, esMio: esMio)
                        else if (msg.urlArchivoS3 != null && msg.urlArchivoS3!.isNotEmpty)
                          ChatMediaGrid(
                            attachments: [
                              ChatAttachment(
                                id: msg.id, 
                                url: msg.urlArchivoS3!, 
                                type: msg.tipo == 'VIDEO' ? 'V' : 'I'
                              )
                            ], 
                            esMio: esMio
                          ),
                        
                        if (texto.isNotEmpty)
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
                              if (msg.esEditado)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    'editado',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: esMio ? (colorMio.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70) : Colors.black45,
                                    ),
                                  ),
                                ),
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
                          if (esMio && msg.leidoPorIds.isNotEmpty)
                            _buildLectoresAvatar(msg),
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

  Widget _buildLectoresAvatar(MensajeChat msg) {
    if (_sala == null || msg.leidoPorIds.isEmpty) return const SizedBox.shrink();
    
    // Filtramos lectores: no nosotros mismos
    final lectoresIds = msg.leidoPorIds.where((id) => id != _miId).toList();
    if (lectoresIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: -6, 
        children: lectoresIds.take(5).map((id) {
          String? avatarUrl;
          try {
            final p = _sala!.participantes.firstWhere((p) => p.usuarioId == id);
            avatarUrl = p.usuario?.urlAvatar;
          } catch (_) {}
          
          if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
             avatarUrl = '${Configuracion.baseUrl}${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl';
          }

          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: CircleAvatar(
              radius: 7,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                ? CachedNetworkImageProvider(avatarUrl) 
                : null,
              backgroundColor: const Color(0xFFF28B50).withOpacity(0.2),
              child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 8, color: Color(0xFFC35E34)) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDecoracionesBurbuja(String estilo, bool esMio) {
    return DecoracionesBurbuja(estilo: estilo, esMio: esMio);
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
    

    if (_sala!.esGrupal && _sala!.comunidadId != 0) {
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
            id: _sala!.comunidadId, 
            nombre: _sala!.nombre, 
            descripcion: '', creadorNombre: '', urlPortada: '', esPublica: true, esVerificada: false, esMiembro: true, ratingMedio: 0.0, fechaCreacion: DateTime.now(), miRol: 'Miembro'
          )),
        ),
      );
      return;
    }


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
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _sala!.participantes.length,
                itemBuilder: (context, index) {
                  final p = _sala!.participantes[index];
                  final esYo = p.usuarioId == _miId;
                  final soyAdmin = _sala!.puedoEliminar; // Usamos el nuevo permiso centralizado
                  
                  return ListTile(
                    leading: Builder(
                      builder: (context) {
                        String? url = p.usuario?.urlAvatar;
                        if (url != null && url.isNotEmpty && !url.startsWith('http')) {
                          url = '${Configuracion.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
                        }
                        return CircleAvatar(
                          backgroundImage: (url != null && url.isNotEmpty) 
                            ? CachedNetworkImageProvider(url) 
                            : null,
                          child: (url == null || url.isEmpty) ? const Icon(Icons.person) : null,
                        );
                      }
                    ),
                    title: Text(
                      p.nombreAMostrar,
                      style: GoogleFonts.outfit(fontWeight: esYo ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: Text(esYo ? 'Tú' : (p.usuario?.nombreUsuario ?? '')),
                    trailing: (soyAdmin && !esYo) 
                      ? IconButton(
                          icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                          onPressed: () => _confirmarExpulsion(context, p),
                        )
                      : null,
                    onTap: () {
                      if (!esYo && p.usuarioId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetallePerfil(idOrUsername: p.usuarioId!)));
                      }
                    },
                  );
                },
              ),
            ),
            if (_sala != null && _sala!.esGrupal) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                title: Text('Abandonar sala', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () => _confirmarSalidaSala(context),
              ),
            ],
            if (_sala != null && _sala!.puedoEliminar) ...[
              if (!_sala!.esGrupal) const Divider(), // Separador si no lo puso el bloque anterior
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: Text('Eliminar chat permanentemente', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () => _confirmarEliminarSala(context),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarSala(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar sala permanentemente?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Esta acción borrará todos los mensajes, fotos y participantes para siempre. No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () async {
              final salaId = _sala?.id;
              
              // Cerrar diálogo
              Navigator.pop(dialogContext);
              
              // Salida a la lista de mensajes
              if (context.mounted) {
                context.go('/mensajes');
              }
              
              // Ejecutar borrado en segundo plano
              if (salaId != null) {
                _servicio.eliminarSala(salaId).then((exito) {
                  if (exito) {
                    // ELIMINACIÓN DEFINITIVA DE LA LISTA GLOBAL
                    if (context.mounted) {
                      Provider.of<ChatProvider>(context, listen: false).eliminarSalaDeLista(salaId);
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: No tienes permisos para eliminar esta sala'), backgroundColor: Colors.orange)
                    );
                  }
                });
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Procesando eliminación... 🐾'), backgroundColor: Colors.red)
              );
            },
            child: const Text('ELIMINAR TODO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarSalidaSala(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Abandonar sala?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Dejarás de recibir mensajes de este chat. Podrás volver a entrar si alguien te invita o si es pública.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () async {
              final salaId = _sala?.id;
              
              // Cerrar diálogo
              Navigator.pop(dialogContext);
              
              // Salida
              if (context.mounted) {
                context.go('/mensajes');
              }
              
              // Ejecutar abandono
              if (salaId != null) {
                _servicio.abandonarSala(salaId).then((exito) {
                  if (!exito && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abandonar la sala. ¿Eres el creador?'), backgroundColor: Colors.orange)
                    );
                  }
                });
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saliendo de la sala... 🐾'), duration: Duration(seconds: 1))
              );
            },
            child: const Text('ABANDONAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarExpulsion(BuildContext context, ParticipanteChat p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Expulsar a ${p.nombreAMostrar}?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Se eliminará a ${p.nombreAMostrar} de esta sala de chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final exito = await _servicio.expulsarMiembro(_sala!.id, p.usuarioId!);
              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nombreAMostrar} ha sido expulsado 🐾')));
                _cargarDatos(); // Recargar para ver la lista actualizada
              }
            },
            child: const Text('EXPULSAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
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
              if (msg.esEditado && msg.fechaEdicion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Editado el ${_formatFechaCompleta(msg.fechaEdicion!)}', 
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFC35E34), fontWeight: FontWeight.bold)
                  ),
                ),
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
                      leading: Builder(
                        builder: (context) {
                          String? url = lector.usuario?.urlAvatar;
                          if (url != null && url.isNotEmpty && !url.startsWith('http')) {
                            url = '${Configuracion.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
                          }
                          return CircleAvatar(
                            backgroundImage: (url != null && url.isNotEmpty) 
                              ? CachedNetworkImageProvider(url) 
                              : null,
                            child: (url == null || url.isEmpty) ? const Icon(Icons.person) : null,
                          );
                        }
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
        if (_archivosSeleccionados.isNotEmpty)
          MediaPreviewGrid(
            files: _archivosSeleccionados,
            onRemove: (index) => setState(() => _archivosSeleccionados.removeAt(index)),
          ),
        if (_estaSubiendoMedia)
          const LinearProgressIndicator(minHeight: 2, color: Colors.blue),
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
                      color: _archivosSeleccionados.length >= 4 ? Colors.grey : Colors.blue,
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

      return null;
    }
  }

  Widget _buildBody() {
    if (_estaCargando && _mensajes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }

    if (_sala == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'Sala no encontrada',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'La sala de chat no existe o ya no tienes acceso a ella 🐾',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _cargarDatos(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC35E34),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Reintentar'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Text('Volver atrás', style: TextStyle(color: Colors.grey[700])),
                ),
              ),
            ],
          ),
        ),
      );
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

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: gradColors == null ? colorFondo : null,
              gradient: gradColors != null ? LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            ),
          ),
        ),
        // Patrón geométrico
        if (perso?.patronFondo != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: _buildPatternBackground(perso!.patronFondo!),
              ),
            ),
          ),
        // Contenido
        Column(
          children: [
            Expanded(child: _buildListaMensajes()),
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
