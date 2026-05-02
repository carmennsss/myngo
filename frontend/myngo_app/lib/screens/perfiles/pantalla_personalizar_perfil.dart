import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_mejoras.dart';
import '../../utils/mejoras_notifier.dart';
import '../../utils/estilo_post_helper.dart';
import '../../widgets/comunes/post_preview.dart';
import '../../widgets/comunes/profile_preview.dart';
import '../../services/servicio_usuarios.dart';

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
  
  String? _previewAvatar;
  String? _previewMarco;
  String? _previewFondo;
  Map<String, dynamic>? _previewEstilo;
  String _nombreUsuario = 'Usuario';
  int _puntos = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarMisMejoras();
  }

  Future<void> _cargarMisMejoras() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final respuesta = await _servicioMejoras.obtenerInventarioUsuario();
    final datosUser = await ServicioUsuarios().obtenerDatosPropios();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (respuesta.exito && respuesta.datos != null) {
          _misMejoras = respuesta.datos is Iterable ? List<dynamic>.from(respuesta.datos!) : [];
          
          // Inicializar previsualización con lo que ya está equipado
          if (datosUser.exito && datosUser.datos != null) {
            final u = datosUser.datos!;
            _nombreUsuario = u.nombreUsuario;
            _puntos = u.puntos ?? 0;
            _previewAvatar = u.urlAvatar;
            _previewMarco = u.marco;
            _previewFondo = u.fondo;
            _previewEstilo = u.estiloPost;
          }
        } else {
          _errorMensaje = respuesta.mensaje;
        }
      });
    }
  }

  void _actualizarPreview(String tipo, dynamic detalles) {
    setState(() {
      final t = tipo.toLowerCase();
      if (t == 'avatar') {
        _previewAvatar = detalles['url_recurso'];
      } else if (t == 'marco') {
        _previewMarco = detalles['url_recurso'];
      } else if (t == 'fondo') {
        _previewFondo = detalles['url_recurso'];
      } else if (t.contains('estilo')) {
        _previewEstilo = detalles['datos_extra'];
      }
    });
  }

  Widget _buildPreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'VISTA PREVIA',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
      ],
    );
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
        notificarMejoraEquipada(); // Avisa al perfil para que recargue posts y datos
        _cargarMisMejoras();       // Actualiza el estado "esta_equipada" en esta pantalla
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool esAncho = constraints.maxWidth > 600;
                if (esAncho) {
                  return Column(
                    children: [
                      _buildPreviewHeader(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: ProfilePreview(
                              fondoUrl: _previewFondo,
                              avatarUrl: _previewAvatar,
                              marcoUrl: _previewMarco,
                              nombreUsuario: _nombreUsuario,
                              puntos: _puntos,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: PostPreview(
                              estilo: _previewEstilo,
                              avatarUrl: _previewAvatar,
                              marcoUrl: _previewMarco,
                              nombreUsuario: _nombreUsuario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // MÓVIL: PageView compacto para ahorrar espacio vertical
                  return Column(
                    children: [
                      _buildPreviewHeader(),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180, // Altura fija y moderada
                        child: PageView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Transform.scale(
                                scale: 0.9,
                                child: ProfilePreview(
                                  fondoUrl: _previewFondo,
                                  avatarUrl: _previewAvatar,
                                  marcoUrl: _previewMarco,
                                  nombreUsuario: _nombreUsuario,
                                  puntos: _puntos,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Transform.scale(
                                scale: 0.9,
                                child: PostPreview(
                                  estilo: _previewEstilo,
                                  avatarUrl: _previewAvatar,
                                  marcoUrl: _previewMarco,
                                  nombreUsuario: _nombreUsuario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFC35E34), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D0BD).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
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
                Tab(text: 'Estilos Post'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ListaMisMejorasTab(tipo: 'Avatar', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora, onPreview: _actualizarPreview),
                _ListaMisMejorasTab(tipo: 'Marco', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora, onPreview: _actualizarPreview),
                _ListaMisMejorasTab(tipo: 'Fondo', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora, onPreview: _actualizarPreview),
                _ListaMisMejorasTab(tipo: 'Estilo Post', mejoras: _misMejoras, isLoading: _isLoading, errorMensaje: _errorMensaje, onEquipar: _equiparMejora, onPreview: _actualizarPreview),
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
  final Function(String, dynamic) onPreview;

  const _ListaMisMejorasTab({required this.tipo, required this.mejoras, required this.isLoading, this.errorMensaje, required this.onEquipar, required this.onPreview});

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
        final esEstiloPost = detalles['tipo'].toString().toLowerCase() == 'estilo post';
        final datosExtra = detalles['datos_extra'] as Map<String, dynamic>?;

        return GestureDetector(
          onTap: () => onPreview(tipo, detalles),
          child: Container(
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
                        child: esEstiloPost && datosExtra != null
                            ? _buildMiniEstiloPreview(datosExtra)
                            : (detalles['url_recurso'] != null && (detalles['url_recurso'] as String).isNotEmpty
                                ? Image.network(detalles['url_recurso'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: Colors.grey.shade300))
                                : Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300)),
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
        ),
      );
    },
  );
}

  Widget _buildMiniEstiloPreview(Map<String, dynamic> datos) {
    return Container(
      decoration: EstiloPostHelper.buildDecoracion(
        datos,
        borderRadius: BorderRadius.circular(12),
        borderWidth: 1.5,
      ),
      child: Center(
        child: Icon(
          Icons.palette_rounded, 
          color: EstiloPostHelper.esFondoClaro(datos) ? Colors.black26 : Colors.white24, 
          size: 32
        ),
      ),
    );
  }
}

