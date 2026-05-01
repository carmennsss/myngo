import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/publicacion.dart';
import '../../models/comentario.dart';
import '../../services/servicio_interaccion.dart';
import '../../services/servicio_usuarios.dart';
import 'comentario_item.dart';
import 'bottom_sheet_colecciones.dart';

class AccionesYComentariosPost extends StatefulWidget {
  final Publicacion post;
  final Color colorTexto;

  const AccionesYComentariosPost({
    super.key,
    required this.post,
    this.colorTexto = Colors.white,
  });

  @override
  State<AccionesYComentariosPost> createState() => _AccionesYComentariosPostState();
}

class _AccionesYComentariosPostState extends State<AccionesYComentariosPost> {
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();
  final TextEditingController _comentarioController = TextEditingController();

  List<Comentario> _comentarios = [];
  bool _cargandoComentarios = true;
  bool _cargandoMas = false;
  bool _hayMasComentarios = true;
  bool _enviandoComentario = false;
  bool _mostrandoInputComentario = false;
  int _offset = 0;
  final int _limit = 10;

  late bool _dioLike;
  late int _likesCount;
  late int _comentariosCount;
  bool _estaGuardado = false;

  @override
  void initState() {
    super.initState();
    _dioLike = widget.post.usuarioDioLike;
    _likesCount = widget.post.likesCount;
    _comentariosCount = widget.post.comentariosCount;
    _estaGuardado = widget.post.usuarioGuardoPost;
    _cargarComentarios(reiniciar: true);
  }

  Future<void> _cargarComentarios({bool reiniciar = false}) async {
    if (!mounted) return;
    if (reiniciar) {
      setState(() {
        _cargandoComentarios = true;
        _offset = 0;
        _hayMasComentarios = true;
        _comentarios = [];
      });
    } else {
      if (!_hayMasComentarios || _cargandoMas) return;
      setState(() => _cargandoMas = true);
    }

    final respuesta = await _servicioInteraccion.obtenerComentarios(
      widget.post.id,
      limit: _limit,
      offset: _offset,
    );

    if (mounted) {
      setState(() {
        if (respuesta.exito) {
          final nuevos = respuesta.datos ?? [];
          if (reiniciar) {
            _comentarios = nuevos;
          } else {
            _comentarios.addAll(nuevos);
          }
          _hayMasComentarios = nuevos.length == _limit;
          _offset += nuevos.length;
        }
        _cargandoComentarios = false;
        _cargandoMas = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final token = await _servicioUsuarios.obtenerToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para dar like')),
        );
      }
      return;
    }

    setState(() {
      _dioLike = !_dioLike;
      _likesCount += _dioLike ? 1 : -1;
      widget.post.usuarioDioLike = _dioLike;
      widget.post.likesCount = _likesCount;
    });

    final respuesta = await _servicioInteraccion.alternarMeGusta(widget.post.id);
    
    if (!respuesta.exito) {
      if (mounted) {
        setState(() {
          _dioLike = !_dioLike;
          _likesCount += _dioLike ? 1 : -1;
          widget.post.usuarioDioLike = _dioLike;
          widget.post.likesCount = _likesCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(respuesta.mensaje)),
        );
      }
    }
  }

  Future<void> _enviarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    setState(() => _enviandoComentario = true);
    final respuesta = await _servicioInteraccion.crearComentario(
      widget.post.id,
      _comentarioController.text.trim(),
    );

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        _comentarios.insert(0, respuesta.datos!);
        _comentarioController.clear();
        _mostrandoInputComentario = false;
        _enviandoComentario = false;
        _comentariosCount++;
        widget.post.comentariosCount = _comentariosCount;
      });
    } else {
      setState(() => _enviandoComentario = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(respuesta.mensaje)),
        );
      }
    }
  }

  Future<void> _mostrarMenuGuardado() async {
    final token = await _servicioUsuarios.obtenerToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para guardar contenido')),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BottomSheetColecciones(
        postId: widget.post.id,
        estaGuardadoPost: _estaGuardado,
        imagenId: widget.post.imagenId,
        imagenUrl: widget.post.urlImagen,
      ),
    );
    
    if (mounted) {
      setState(() {
        _estaGuardado = widget.post.usuarioGuardoPost;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones de acción
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ActionIcon(
                icon: _dioLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _dioLike ? Colors.red : widget.colorTexto.withOpacity(0.7),
                label: _likesCount.toString(),
                textColor: widget.colorTexto,
                onTap: _toggleLike,
              ),
              _ActionIcon(
                icon: Icons.chat_bubble_outline_rounded,
                color: widget.colorTexto.withOpacity(0.7),
                label: _comentariosCount.toString(),
                textColor: widget.colorTexto,
                onTap: () {
                  setState(() {
                    _mostrandoInputComentario = !_mostrandoInputComentario;
                  });
                },
              ),
              const Spacer(),
              _ActionIcon(
                icon: _estaGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _estaGuardado ? const Color(0xFFF28B50) : widget.colorTexto.withOpacity(0.7),
                label: '',
                textColor: widget.colorTexto,
                onTap: _mostrarMenuGuardado,
              ),
            ],
          ),
        ),
        
        if (_mostrandoInputComentario)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: widget.colorTexto.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.colorTexto.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _comentarioController,
                      style: GoogleFonts.inter(color: widget.colorTexto, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Añadir un comentario...',
                        hintStyle: GoogleFonts.inter(color: widget.colorTexto.withOpacity(0.5), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _enviandoComentario
                    ? const SizedBox(width: 36, height: 36, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF248EA6)),
                        onPressed: _enviarComentario,
                      ),
              ],
            ),
          ),
          
        const SizedBox(height: 16),
        Divider(height: 1, color: widget.colorTexto.withOpacity(0.1)),
        
        if (_cargandoComentarios)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator(color: widget.colorTexto.withOpacity(0.5))),
          )
        else if (_comentarios.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Sin comentarios todavía',
                style: GoogleFonts.inter(color: widget.colorTexto.withOpacity(0.5)),
              ),
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            itemCount: _comentarios.length,
            itemBuilder: (context, index) {
              final esFondoClaro = widget.colorTexto.computeLuminance() > 0.5;
              final subColor = esFondoClaro ? Colors.black54 : Colors.white70;

              return ComentarioItem(
                comentario: _comentarios[index],
                textColor: widget.colorTexto,
                subTextColor: subColor,
              );
            },
          ),
          if (_hayMasComentarios)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _cargandoMas
                  ? CircularProgressIndicator(color: widget.colorTexto.withOpacity(0.5), strokeWidth: 2)
                  : TextButton(
                      onPressed: () => _cargarComentarios(),
                      child: Text('Cargar más comentarios 🐾', 
                        style: GoogleFonts.outfit(color: widget.colorTexto.withOpacity(0.6), fontWeight: FontWeight.bold)
                      ),
                    ),
              ),
            ),
        ],
        const SizedBox(height: 150),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
