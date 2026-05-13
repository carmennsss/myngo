import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';

import '../../models/publicacion.dart';
import '../../models/comentario.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_interaccion.dart';
import '../../widgets/inicio/tarjeta_post.dart';
import '../../services/servicio_mensajeria.dart';
import 'package:myngo_app/utils/tr_helper.dart';

// Vista ampliada de una publicación con su sección de comentarios inline.
// Se puede abrir pasando un objeto Publicacion o simplemente su ID.
class PantallaDetallePublicacion extends StatefulWidget {
  final int? publicacionId;
  final Publicacion? publicacion;

  const PantallaDetallePublicacion({
    Key? key, 
    this.publicacionId, 
    this.publicacion
  }) : super(key: key);

  @override
  State<PantallaDetallePublicacion> createState() => _PantallaDetallePublicacionState();
}

class _PantallaDetallePublicacionState extends State<PantallaDetallePublicacion> {
  final _servicioComunidades = ServicioComunidades();
  final _servicioInteraccion = ServicioInteraccion();
  final _servicioMensajeria = ServicioMensajeria();
  final _comentarioController = TextEditingController();
  
  Publicacion? _pub;
  List<Comentario> _comentarios = [];
  bool _cargandoComentarios = false;
  bool _enviandoComentario = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.publicacion != null) {
      _pub = widget.publicacion;
    } else {
      _cargarPublicacion();
    }
    _conectarWebSockets();
  }

  void _conectarWebSockets() {
    final pubId = widget.publicacion?.id ?? widget.publicacionId;
    if (pubId != null) {
      _servicioMensajeria.conectarAPublicacion(pubId, (evento) {
        if (evento['type'] == 'comentario_creado') {
          final data = evento['data'];
          if (data != null && mounted) {
            setState(() {
              final nuevoComentario = Comentario.fromJson(data);
              // Evitar duplicados si el usuario es el que lo envió
              if (!_comentarios.any((c) => c.id == nuevoComentario.id)) {
                _comentarios.add(nuevoComentario);
                if (_pub != null) {
                  _pub = _pub!.copyWith(comentariosCount: _comentarios.length);
                }
              }
            });
          }
        }
      });
    }
  }

  // Descarga los datos de la publicación desde el servidor si no se recibió el objeto
  Future<void> _cargarPublicacion() async {
    if (widget.publicacionId == null) return;
    setState(() { _cargando = true; _error = null; });
    final res = await _servicioComunidades.obtenerDetallePublicacion(widget.publicacionId!);
    if (mounted) {
      setState(() {
        _cargando = false;
        if (res.exito) {
          _pub = res.datos;
          _conectarWebSockets();
          _cargarComentarios();
        } else {
          _error = res.mensaje;
        }
      });
    }
  }

  // Carga los comentarios y actualiza el contador de la publicación
  Future<void> _cargarComentarios() async {
    if (_pub == null) return;
    setState(() => _cargandoComentarios = true);
    final res = await _servicioInteraccion.obtenerComentarios(_pub!.id);
    if (mounted) {
      setState(() {
        _comentarios = res.datos ?? [];
        _cargandoComentarios = false;
        if (_pub != null) {
          _pub = _pub!.copyWith(comentariosCount: _comentarios.length);
        }
      });
    }
  }

  // Devuelve la publicación actualizada (con el nuevo conteo de comentarios) al salir
  void _volverConDatos() {
    Navigator.pop(context, _pub);
  }

  // Envía el comentario y lo inserta en la lista local sin recargar todo
  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty || _pub == null) return;

    setState(() => _enviandoComentario = true);
    final res = await _servicioInteraccion.crearComentario(_pub!.id, texto);
    
    if (mounted) {
      setState(() => _enviandoComentario = false);
      if (res.exito && res.datos != null) {
        _comentarioController.clear();
        setState(() {
          _comentarios.add(res.datos!);
          if (_pub != null) {
            _pub = _pub!.copyWith(comentariosCount: _comentarios.length);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('commentSent'))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(tr('postDetailTitle'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.orangeAccent),
              onPressed: _volverConDatos,
            ),
          ),
          body: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _volverConDatos();
            },
            child: _buildContenido(tr),
          ),
          bottomNavigationBar: _buildInputComentario(tr),
        );
      }
    );

  }

  // Cuerpo principal: muestra la TarjetaPost seguida de la lista de comentarios
  Widget _buildContenido(String Function(String, [Map<String, dynamic>?]) tr) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    if (_error != null) return _buildErrorState();
    if (_pub == null) return Center(child: Text(tr('commonNotFound'), style: const TextStyle(color: Colors.white70)));

    return RefreshIndicator(
      onRefresh: _cargarComentarios,
      color: const Color(0xFFF28B50),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TarjetaPost(
              post: _pub!,
              onJoin: () {},
              onEliminado: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 24),
            Text(tr('postCommentsCount', {'count': _comentarios.length}), 
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildListaComentarios(tr),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Lista de comentarios con avatar, autor y contenido
  Widget _buildListaComentarios(String Function(String) tr) {
    if (_cargandoComentarios && _comentarios.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }
    if (_comentarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text(tr('postFirstComment'), style: GoogleFonts.inter(color: Colors.white24)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comentarios.length,
      itemBuilder: (context, index) {
        final c = _comentarios[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white10,
                backgroundImage: c.autorFoto != null ? NetworkImage(c.autorFoto!) : null,
                child: c.autorFoto == null ? const Icon(Icons.person, size: 18, color: Colors.white38) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.autorNombre, style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(tr('commonRecent'), style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.contenido, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Barra de texto fija en la parte inferior para escribir y enviar comentarios
  Widget _buildInputComentario(String Function(String) tr) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _comentarioController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: InputDecoration(
                hintText: tr('postAddCommentHint'),
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: _enviandoComentario ? null : _enviarComentario,
            icon: _enviandoComentario 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF28B50)))
              : const Icon(Icons.send_rounded, color: Color(0xFFF28B50)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _servicioMensajeria.dispose();
    super.dispose();
  }

  Widget _buildErrorState() {
     return Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)));
  }
}
