import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/publicacion.dart';
import '../../models/comentario.dart';
import '../../services/servicio_interaccion.dart';
import '../../services/servicio_usuarios.dart';
import 'comentario_item.dart';
import 'bottom_sheet_colecciones.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';

class AccionesYComentariosPost extends StatefulWidget {
  final Publicacion post;
  final Color colorTexto;
  final bool esMiembro;
  final String? fuente;

  const AccionesYComentariosPost({
    super.key,
    required this.post,
    this.colorTexto = Colors.white,
    this.esMiembro = true,
    this.fuente,
  });

  @override
  State<AccionesYComentariosPost> createState() => _AccionesYComentariosPostState();
}

class _AccionesYComentariosPostState extends State<AccionesYComentariosPost> {
  final ServicioInteraccion _servicioInteraccion = ServicioInteraccion();
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();
  final TextEditingController _comentarioController = TextEditingController();
  final FocusNode _comentarioFocus = FocusNode();

  List<Comentario> _comentarios = [];
  bool _cargandoComentarios = true;
  bool _cargandoMas = false;
  bool _hayMasComentarios = true;
  bool _enviandoComentario = false;
  bool _mostrandoInputComentario = false;
  int _offset = 0;
  final int _limit = 10;

  Comentario? _comentarioPadre;

  late bool _dioLike;
  late int _likesCount;
  late int _comentariosCount;
  bool _estaGuardado = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _dioLike = widget.post.usuarioDioLike;
    _likesCount = widget.post.likesCount;
    _comentariosCount = widget.post.comentariosCount;
    _estaGuardado = widget.post.usuarioGuardoPost;
    _cargarComentarios(reiniciar: true);
    _obtenerUsuario();
  }

  Future<void> _obtenerUsuario() async {
    final id = await _servicioUsuarios.obtenerIdUsuario();
    if (id != null && mounted) {
      setState(() => _currentUserId = id);
    }
  }

  @override
  void didUpdateWidget(AccionesYComentariosPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.usuarioDioLike != widget.post.usuarioDioLike ||
        oldWidget.post.likesCount != widget.post.likesCount ||
        oldWidget.post.comentariosCount != widget.post.comentariosCount ||
        oldWidget.post.usuarioGuardoPost != widget.post.usuarioGuardoPost) {
      setState(() {
        _dioLike = widget.post.usuarioDioLike;
        _likesCount = widget.post.likesCount;
        _comentariosCount = widget.post.comentariosCount;
        _estaGuardado = widget.post.usuarioGuardoPost;
      });
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _comentarioFocus.dispose();
    super.dispose();
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

  Future<void> _enviarComentario() async {
    if (!widget.esMiembro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('communityJoinToChat')),
          backgroundColor: const Color(0xFFC35E34),
        ),
      );
      return;
    }
    if (_comentarioController.text.trim().isEmpty) return;

    setState(() => _enviandoComentario = true);
    final respuesta = await _servicioInteraccion.crearComentario(
      widget.post.id,
      _comentarioController.text.trim(),
      padreId: _comentarioPadre?.id,
    );

    if (respuesta.exito && respuesta.datos != null) {
      setState(() {
        if (_comentarioPadre != null) {

          _cargarComentarios(reiniciar: true);
        } else {
          _comentarios.insert(0, respuesta.datos!);
        }
        _comentarioController.clear();
        _comentarioPadre = null;
        _mostrandoInputComentario = false;
        _enviandoComentario = false;
        _comentariosCount++;
        widget.post.comentariosCount = _comentariosCount;
      });
    } else {
      setState(() => _enviandoComentario = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: const Color(0xFFC35E34),
          ),
        );
      }
    }
  }

  void _prepararRespuesta(Comentario padre) {
    setState(() {
      _comentarioPadre = padre;
      _mostrandoInputComentario = true;
    });
    _comentarioFocus.requestFocus();
  }

  Future<void> _eliminarComentario(Comentario comentario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('postCommentDeleteTitle')),
        content: Text(tr('postCommentDeleteContent')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('commonCancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(tr('commonDelete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final res = await _servicioInteraccion.eliminarComentario(comentario.id);
      if (res.exito && mounted) {
        setState(() {
          final comentarioABorrar = _comentarios.firstWhere((c) => c.id == comentario.id);

          int totalBorrados = 1 + comentarioABorrar.respuestas.length;
          
          _comentarios.removeWhere((c) => c.id == comentario.id);

          for (var p in _comentarios) {
            final antes = p.respuestas.length;
            p.respuestas.removeWhere((r) => r.id == comentario.id);
            if (p.respuestas.length < antes) totalBorrados = 1; 
          }
          
          _comentariosCount = (_comentariosCount - totalBorrados).clamp(0, 999999);
          widget.post.comentariosCount = _comentariosCount;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
    
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ActionIcon(
                    icon: _dioLike ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _dioLike ? Colors.red : widget.colorTexto.withOpacity(0.7),
                    label: _likesCount.toString(),
                    textColor: widget.colorTexto,
                    fuente: widget.fuente,
                onTap: () async {
                      if (!widget.esMiembro) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('communityJoinToLike')),
                            backgroundColor: const Color(0xFFC35E34),
                          ),
                        );
                        return;
                      }
                      final id = await _servicioUsuarios.obtenerIdUsuario();
                      if (id == 0) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('authLoginToLike')),
                              backgroundColor: const Color(0xFFC35E34),
                            ),
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

                      final res = await _servicioInteraccion.alternarMeGusta(widget.post.id);
                      if (!res.exito && mounted) {
                        setState(() {
                          _dioLike = !_dioLike;
                          _likesCount += _dioLike ? 1 : -1;
                          widget.post.usuarioDioLike = _dioLike;
                          widget.post.likesCount = _likesCount;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.mensaje),
                            backgroundColor: const Color(0xFFD95F43),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: widget.colorTexto.withOpacity(0.7),
                    label: _comentariosCount.toString(),
                    textColor: widget.colorTexto,
                    fuente: widget.fuente,
                onTap: () {
                      setState(() {
                        _mostrandoInputComentario = !_mostrandoInputComentario;
                        if (!_mostrandoInputComentario) _comentarioPadre = null;
                      });
                    },
                  ),
                  const Spacer(),
                  _ActionIcon(
                    icon: _estaGuardado ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _estaGuardado ? const Color(0xFFF28B50) : widget.colorTexto.withOpacity(0.7),
                    label: '',
                    textColor: widget.colorTexto,
                    fuente: widget.fuente,
                onTap: () async {
                      if (!widget.esMiembro) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('communityJoinToSave')),
                            backgroundColor: const Color(0xFFC35E34),
                          ),
                        );
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
                      setState(() => _estaGuardado = widget.post.usuarioGuardoPost);
                    },
                  ),
                ],
              ),
            ),
            
            if (_mostrandoInputComentario)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_comentarioPadre != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF28B50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('commentRespondingTo', {'name': _comentarioPadre!.autorNombre}),
                              style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: const Color(0xFFF28B50), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _comentarioPadre = null),
                              child: const Icon(Icons.close, size: 14, color: Color(0xFFF28B50)),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: widget.colorTexto.computeLuminance() > 0.5 
                              ? Colors.black.withOpacity(0.05) 
                              : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: widget.colorTexto.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: _comentarioController,
                              focusNode: _comentarioFocus,
                              style: GoogleFonts.getFont(widget.fuente ?? 'Outfit',
                            color: widget.colorTexto.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                              decoration: InputDecoration(
                                hintText: !widget.esMiembro 
                                    ? tr('commentJoinToComment')
                                    : (_comentarioPadre != null ? tr('commentWriteReply') : tr('commentAddComment')),
                                hintStyle: GoogleFonts.getFont(widget.fuente ?? 'Outfit',
                              color: (widget.colorTexto.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.5), 
                              fontSize: 14
                            ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                enabled: widget.esMiembro,
                              ),
                              enabled: widget.esMiembro,
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
                    tr('commentNoComments'),
                    style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: widget.colorTexto.withOpacity(0.5)),
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
                    onReply: _prepararRespuesta,
                    onDelete: _eliminarComentario,
                currentUserId: _currentUserId,
                fuente: widget.fuente,
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
                          child: Text(tr('commentLoadMore'), 
                            style: GoogleFonts.getFont(widget.fuente ?? 'Outfit', color: widget.colorTexto.withOpacity(0.6), fontWeight: FontWeight.bold)
                          ),
                        ),
                  ),
                ),
            ],
            const SizedBox(height: 150),
          ],
        );
      },
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  final String? fuente;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.textColor,
    required this.onTap,
    this.fuente,
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
              style: GoogleFonts.getFont(fuente ?? 'Outfit', color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
