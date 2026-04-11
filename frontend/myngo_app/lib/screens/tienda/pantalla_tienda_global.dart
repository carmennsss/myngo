import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/catalogo_mejoras.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_usuarios.dart';

class PantallaTiendaGlobal extends StatefulWidget {
  const PantallaTiendaGlobal({super.key});

  @override
  State<PantallaTiendaGlobal> createState() => _PantallaTiendaGlobalState();
}

class _PantallaTiendaGlobalState extends State<PantallaTiendaGlobal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServicioMejoras _servicio = ServicioMejoras();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFFC35E34)),
            const SizedBox(width: 12),
            Text('Tienda Myngo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC35E34),
          labelColor: const Color(0xFFC35E34),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.account_circle), text: 'Avatares'),
            Tab(icon: Icon(Icons.filter_frames_rounded), text: 'Marcos'),
            Tab(icon: Icon(Icons.image), text: 'Fondos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MejorasTab(tipo: 'avatar'),
          _MejorasTab(tipo: 'marco'),
          _MejorasTab(tipo: 'fondo'),
        ],
      ),
    );
  }
}

class _MejorasTab extends StatefulWidget {
  final String tipo;
  const _MejorasTab({required this.tipo});

  @override
  State<_MejorasTab> createState() => _MejorasTabState();
}

class _MejorasTabState extends State<_MejorasTab> {
  List<CatalogoMejoras> _mejoras = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMejoras();
  }

  Future<void> _loadMejoras() async {
    final res = await ServicioMejoras().obtenerMejorasCatalogo(widget.tipo);
    if (mounted) {
      setState(() {
        _mejoras = res.datos ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _mejoras.length,
      itemBuilder: (context, i) {
        final mejora = _mejoras[i];
        return Card(
          child: Column(
            children: [
              Expanded(child: CachedNetworkImage(imageUrl: mejora.urlRecurso, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(mejora.nombre, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    Text('${mejora.precioPuntos} pts', style: GoogleFonts.outfit(color: Colors.green)),
                    ElevatedButton(
                      onPressed: () => _buy(mejora),
                      child: const Text('Comprar'),
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

  Future<void> _buy(CatalogoMejoras mejora) async {
    final res = await ServicioMejoras().comprarMejora(mejora.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mensaje)));
    if (res.exito) _loadMejoras();
  }
}
