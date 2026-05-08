import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/usuario.dart';
import '../../screens/inicio/pantalla_inicio.dart';

class HoverProfileCard extends StatefulWidget {
  final Widget child;
  final String nombre;
  final String? avatarUrl;
  final String? marcoUrl;
  final String? fondoUrl;
  final int puntos;
  final String estado;
  final int? userId;
  final VoidCallback onTap;

  const HoverProfileCard({
    super.key,
    required this.child,
    required this.nombre,
    this.avatarUrl,
    this.marcoUrl,
    this.fondoUrl,
    this.puntos = 0,
    this.estado = 'DESCONECTADO',
    this.userId,
    required this.onTap,
  });

  @override
  State<HoverProfileCard> createState() => _HoverProfileCardState();
}

class _HoverProfileCardState extends State<HoverProfileCard> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);
    Size screenSize = MediaQuery.of(context).size;
    
    // Dimensiones de nuestra tarjeta (aprox)
    double cardWidth = 280;
    double cardHeight = 220; // Estimación
    
    double dx = size.width + 12;
    double dy = -40;
    
    // Si se sale por la derecha, mostrar a la izquierda
    if (position.dx + size.width + cardWidth + 20 > screenSize.width) {
      dx = -cardWidth - 12;
    }
    
    // Si se sale por abajo, subirla
    if (position.dy + dy + cardHeight > screenSize.height) {
      dy = screenSize.height - (position.dy + cardHeight) - 20;
    }
    
    // Si se sale por arriba
    if (position.dy + dy < 0) {
      dy = -position.dy + 10;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        width: cardWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(dx, dy),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) {
              setState(() => _isHovering = false);
              _hideOverlay();
            },
            child: Material(
              elevation: 20,
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner (Fondo)
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E0),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: (widget.fondoUrl != null && widget.fondoUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(widget.fondoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    // Avatar con Marco
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white,
                                      child: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                                          ? ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: widget.avatarUrl!,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(color: Colors.grey.shade100),
                                                errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey, size: 30),
                                              ),
                                            )
                                          : const Icon(Icons.person, color: Color(0xFFC35E34), size: 30),
                                    ),
                                  ),
                                  if (widget.marcoUrl != null && widget.marcoUrl!.isNotEmpty)
                                    Positioned.fill(
                                      child: Center(
                                        child: SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: IgnorePointer(
                                            child: CachedNetworkImage(
                                              imageUrl: widget.marcoUrl!,
                                              fit: BoxFit.contain,
                                              alignment: Alignment.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Builder(
                                    builder: (context) {
                                      String displayEstado = widget.estado;
                                      try {
                                        final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                                        if (inicioState != null && widget.userId != null && inicioState.miId == widget.userId) {
                                          displayEstado = inicioState.miEstado;
                                        } else if (inicioState != null && widget.nombre == inicioState.miNombre) {
                                          displayEstado = inicioState.miEstado;
                                        }
                                      } catch (_) {}

                                      return Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _getColorEstado(displayEstado),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Builder(
                                builder: (context) {
                                  // Sincronizar con el estado live si es el usuario actual
                                  String displayEstado = widget.estado;
                                  try {
                                    final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
                                    if (inicioState != null && widget.userId != null && inicioState.miId == widget.userId) {
                                      displayEstado = inicioState.miEstado;
                                    } else if (inicioState != null && widget.nombre == inicioState.miNombre) {
                                      displayEstado = inicioState.miEstado;
                                    }
                                  } catch (_) {}

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getColorEstado(displayEstado).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getColorEstado(displayEstado).withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      displayEstado == 'ACTIVO' ? 'Activo' : (displayEstado == 'OCUPADO' ? 'Ocupado' : 'Desconectado'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: _getColorEstado(displayEstado).withOpacity(0.8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.nombre,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF4A4440),
                                  ),
                                ),
                                Text(
                                  '@${widget.nombre.toLowerCase().replaceAll(' ', '')}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const SizedBox(height: 4),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _hideOverlay();
                                widget.onTap();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC35E34),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: Text(
                                'Ver Perfil',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovering = true);
          _showOverlay();
        },
        onExit: (_) {
          // Un pequeño retraso para permitir mover el ratón al overlay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!_isHovering) {
              _hideOverlay();
            }
          });
          setState(() => _isHovering = false);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Colors.greenAccent;
      case 'OCUPADO':
        return Colors.redAccent;
      case 'DESCONECTADO':
      default:
        return Colors.grey.shade400;
    }
  }
}
