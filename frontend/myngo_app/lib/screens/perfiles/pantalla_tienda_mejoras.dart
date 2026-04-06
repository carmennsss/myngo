import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/catalogo_mejoras.dart';
import '../../services/servicio_mejoras.dart';

class PantallaTiendaMejoras extends StatelessWidget {
  final bool esVistaIntegrada;
  
  const PantallaTiendaMejoras({super.key, this.esVistaIntegrada = false});

  @override
  Widget build(BuildContext context) {
    final content = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D0BD).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFFC35E34).withOpacity(0.1), blurRadius: 8)],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFFC35E34),
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Avatares'),
                Tab(text: 'Marcos'),
                Tab(text: 'Fondos'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ListaMejorasTab(tipo: 'avatar'),
                _ListaMejorasTab(tipo: 'marco'),
                _ListaMejorasTab(tipo: 'fondo'),
              ],
            ),
          ),
        ],
      ),
    );

    if (esVistaIntegrada) {
      return Container(
        color: const Color(0xFFFEF5F1),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFFC35E34), size: 24),
            const SizedBox(width: 10),
            Text(
              'Tienda de Mejoras',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440), fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
      ),
      body: content,
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
    }
    if (_errorMensaje != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_errorMensaje!, style: GoogleFonts.outfit(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    if (_mejoras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay ${widget.tipo}s disponibles aún 🐾',
              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: _mejoras.length,
      itemBuilder: (context, index) {
        final mejora = _mejoras[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8D5C4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC35E34).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    color: const Color(0xFFFBE9E0),
                    child: mejora.urlRecurso.isNotEmpty
                        ? Image.network(
                            mejora.urlRecurso,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade300, size: 36),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300, size: 36),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  children: [
                    Text(
                      mejora.nombre,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4A4440),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF28B50), Color(0xFFC35E34)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${mejora.precioPuntos} pts',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
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
