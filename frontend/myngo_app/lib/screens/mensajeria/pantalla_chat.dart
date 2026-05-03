import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
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
  int _miembrosOnline = 0;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    _miId = await ServicioUsuarios().obtenerIdUsuario();
    await _cargarDatos();
    _conectarWebSocket();
    _conectarPresencia();
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
        if (datos['type'] == 'chat_message') {
          final nuevoMsg = MensajeChat.fromJson(datos);
          _mensajes.insert(0, nuevoMsg);
        } else if (datos['type'] == 'room_updated') {
          _sala = SalaChat.fromJson(datos['data']);
        }
      });
    });
  }

  void _conectarPresencia() {
    _servicio.conectarPresencia((datos) {
      if (!mounted) return;
      if (datos['type'] == 'status_change') {
        setState(() {
          _estadosPresencia[datos['user_id']] = datos['status'];
          _actualizarConteoOnline();
        });
      } else if (datos['type'] == 'presence_connection_established') {
        final onlineUsers = List<int>.from(datos['online_users'] ?? []);
        setState(() {
          for (var id in onlineUsers) {
            _estadosPresencia[id] = 'ACTIVO';
          }
          _actualizarConteoOnline();
        });
      }
    });
  }

  void _actualizarConteoOnline() {
    if (_sala == null) return;
    _miembrosOnline = _sala!.participantes.where((p) => 
      _estadosPresencia[p.usuarioId] == 'ACTIVO' || _estadosPresencia[p.usuarioId] == 'OCUPADO'
    ).length;
  }

  void _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty || _sala == null) return;
    final texto = _mensajeController.text.trim();
    _mensajeController.clear();
    try {
      _servicio.enviarMensajeChat(texto);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perso = _sala?.personalizacion;
    final colorFondo = _colorFromHex(perso?.colorFondo);

    return Scaffold(
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
                : const Icon(Icons.palette_outlined),
            tooltip: 'Personalizar chat',
            onPressed: (_estaCargando || _sala == null) 
              ? null 
              : () async {
                  final actualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PantallaPersonalizacionChat(sala: _sala!)),
                  );
                  if (actualizado == true) _cargarDatos();
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
            ],
          ),
    );
  }

  Widget _buildAppBarTitle() {
    final nombre = _sala?.nombre ?? widget.nombreSala ?? 'Chat';
    String subtitulo = '';
    
    if (_sala != null) {
      if (_sala!.esGrupal) {
        subtitulo = '${_sala!.participantes.length} miembros • $_miembrosOnline en línea';
      } else {
        final otroId = _sala!.otroUsuarioId;
        final estado = _estadosPresencia[otroId] ?? 'DESCONECTADO';
        subtitulo = estado == 'ACTIVO' ? 'En línea' : (estado == 'OCUPADO' ? 'Ocupado' : 'Desconectado');
      }
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: (_sala?.avatarS3 != null)
            ? CachedNetworkImageProvider(_sala!.avatarS3!)
            : null,
          child: (_sala?.avatarS3 == null) ? const Icon(Icons.chat_bubble_outline, size: 20) : null,
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
                child: Text(
                  texto,
                  style: GoogleFonts.outfit(
                    color: esMio ? Colors.white : Colors.black87,
                    fontSize: fontSize,
                    fontStyle: borrado ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.reply), title: const Text('Responder'), onTap: () => Navigator.pop(context)),
            if (msg.emisorId == _miId) ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Borrar'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: esOscuro ? Colors.black : Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(hintText: 'Mensaje...', border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Color(0xFFF28B50)), onPressed: _enviarMensaje),
        ],
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
    _mensajeController.dispose();
    _scrollController.dispose();
    _servicio.dispose();
    super.dispose();
  }
}
