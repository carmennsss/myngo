import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_mejoras.dart';

class PantallaPersonalizarPerfil extends StatefulWidget {
  const PantallaPersonalizarPerfil({super.key});

  @override
  State<PantallaPersonalizarPerfil> createState() => _PantallaPersonalizarPerfilState();
}

class _PantallaPersonalizarPerfilState extends State<PantallaPersonalizarPerfil> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServicioMejoras _servicioMejoras = ServicioMejoras();
  
  bool _isLoading = true;
  List<dynamic> _misMejoras = [];
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarMisMejoras();
  }

  Future<void> _cargarMisMejoras() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final respuesta = await _servicioMejoras.obtenerMisMejoras();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (respuesta.exito && respuesta.datos != null) {
          _misMejoras = respuesta.datos is Iterable ? List<dynamic>.from(respuesta.datos!) : [];
        } else {
          _errorMensaje = respuesta.mensaje;
        }
      });
    }
  }

  Future<void> _equiparMejora(int mejoraId) async {
    final respuesta = await _servicioMejoras.equiparMejora(mejoraId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.red,
        ),
      );
      if (respuesta.exito) {
        // Recargar inventario para actualizar estado "esta_equipada"
        _cargarMisMejoras();
      }
    }
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
        backgroundColor: const Color(0xFFFEF5F1),
        title: Text('Personalizar Perfil', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440))),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D0BD).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ListaMisMejorasTab(tipo: 'Avatar', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora),
                _ListaMisMejorasTab(tipo: 'Marco', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora),
                _ListaMisMejorasTab(tipo: 'Fondo', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaMisMejorasTab extends StatelessWidget {
  final String tipo;
  final List<dynamic> mejoras;
  final bool isLoading;
  final String? errorMensaje;
  final Function(int) onEquipar;

  const _ListaMisMejorasTab({required this.tipo, required this.mejoras, required this.isLoading, this.errorMensaje, required this.onEquipar});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFC35E34)));
    if (errorMensaje != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(errorMensaje!, style: GoogleFonts.outfit(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final filtradas = mejoras.where((m) => m['mejora_detalles'] != null && m['mejora_detalles']['tipo'].toString().toLowerCase() == tipo.toLowerCase()).toList();

    if (filtradas.isEmpty) {
      final String tipoPlural = tipo.toLowerCase() == 'avatar' ? 'avatares' : '${tipo.toLowerCase()}s';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 16),
            Text('No posees $tipoPlural 🐾', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 16)),
            Text('Visita la tienda para adquirir diseños', style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14)),
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
        childAspectRatio: 0.75,
      ),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final item = filtradas[index];
        final detalles = item['mejora_detalles'];
        final estaEquipada = item['esta_equipada'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: estaEquipada ? const Color(0xFF248EA6) : const Color(0xFFE8D5C4), width: estaEquipada ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: (estaEquipada ? const Color(0xFF248EA6) : const Color(0xFFC35E34)).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Container(
                        color: const Color(0xFFFBE9E0),
                        child: detalles['url_recurso'] != null && (detalles['url_recurso'] as String).isNotEmpty
                            ? Image.network(detalles['url_recurso'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: Colors.grey.shade300))
                            : Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300),
                      ),
                    ),
                    if (estaEquipada)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF248EA6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      detalles['tipo'] ?? 'Mejora',
                      style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w800, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () {
                          if (detalles['id'] != null) {
                            onEquipar(detalles['id']);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: estaEquipada ? Colors.grey.shade300 : const Color(0xFFC35E34)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: estaEquipada ? Colors.grey.shade100 : Colors.transparent,
                        ),
                        child: Text(
                          estaEquipada ? 'Equipado' : 'Equipar',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: estaEquipada ? Colors.grey.shade500 : const Color(0xFFC35E34),
                          ),
                        ),
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
