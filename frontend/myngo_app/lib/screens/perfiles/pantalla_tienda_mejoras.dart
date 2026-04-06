import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/catalogo_mejoras.dart';
import '../../services/servicio_mejoras.dart';

class PantallaTiendaMejoras extends StatelessWidget {
  const PantallaTiendaMejoras({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: Text(
            'Tienda de Mejoras',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: const Color(0xFFF28B50),
            labelColor: const Color(0xFFF28B50),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Avatares', icon: Icon(Icons.face_rounded)),
              Tab(text: 'Marcos', icon: Icon(Icons.crop_square_rounded)),
              Tab(text: 'Fondos', icon: Icon(Icons.wallpaper_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListaMejorasTab(tipo: 'avatar'),
            _ListaMejorasTab(tipo: 'marco'),
            _ListaMejorasTab(tipo: 'fondo'),
          ],
        ),
      ),
    );
  }
}

class _ListaMejorasTab extends StatefulWidget {
  final String tipo;
  const _ListaMejorasTab({required this.tipo});

  @override
  State<_ListaMejorasTab> createState() => _ListaMejorasTabState();
}

class _ListaMejorasTabState extends State<_ListaMejorasTab> {
  final ServicioMejoras _servicioMejoras = ServicioMejoras();
  bool _isLoading = true;
  List<CatalogoMejoras> _mejoras = [];
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarMejoras();
  }

  Future<void> _cargarMejoras() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });
    
    final respuesta = await _servicioMejoras.obtenerMejorasCatalogo(widget.tipo);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (respuesta.exito) {
          _mejoras = (respuesta.datos as List<CatalogoMejoras>?) ?? [];
        } else {
          _errorMensaje = respuesta.mensaje;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)));
    }
    if (_errorMensaje != null) {
      return Center(
        child: Text(
          _errorMensaje!,
          style: GoogleFonts.inter(color: Colors.red),
        ),
      );
    }
    if (_mejoras.isEmpty) {
      return Center(
        child: Text(
          'No hay ${widget.tipo}s disponibles por ahora.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140, // Cartas mucho más pequeñas
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55, // Más altura para que quepan títulos largos sin cortarse
      ),
      itemCount: _mejoras.length,
      itemBuilder: (context, index) {
        final mejora = _mejoras[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    color: const Color(0xFF121212),
                    child: mejora.urlRecurso.isNotEmpty
                        ? Image.network(
                            mejora.urlRecurso,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 40),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      mejora.nombre,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF248EA6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF248EA6).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF28B50), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${mejora.precioPuntos}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF28B50),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
