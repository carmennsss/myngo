import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/comunidad.dart';
import '../../models/catalogo_mejoras.dart';
import '../../services/servicio_mejoras.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_usuarios.dart';
import '../comunidades/pantalla_enviar_propuesta.dart';
import '../../widgets/comunes/boton_tactil.dart';
import '../inicio/pantalla_inicio.dart';
import '../../widgets/comunes/estado_vacio_cargando.dart';

class PantallaTiendaMejoras extends StatefulWidget {
  final bool esVistaIntegrada;
  final Comunidad? comunidad;
  final Function(String)? onCategoryChanged;
  final Function(int)? onPuntosActualizados;
  
  const PantallaTiendaMejoras({
    super.key, 
    this.esVistaIntegrada = false, 
    this.comunidad, 
    this.onCategoryChanged,
    this.onPuntosActualizados,
  });

  @override
  State<PantallaTiendaMejoras> createState() => _PantallaTiendaMejorasState();
}

class _PantallaTiendaMejorasState extends State<PantallaTiendaMejoras> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  int _tabIndex = 0; // 0: Global, 1: Comunidad
  bool _esModerador = false;
  bool _modoGestion = false;

  @override
  void initState() {
    super.initState();
    // Si entramos desde una comunidad, empezamos directamente en la pestaña "Exclusivo"
    if (widget.comunidad != null) {
      _tabIndex = 1;
      _checkRol();
    }
    _subTabController = TabController(length: 3, vsync: this);
    _subTabController.addListener(_handleTabChange);
  }

  Future<void> _checkRol() async {
    final userId = await ServicioUsuarios().obtenerIdUsuario();
    if (userId != null && widget.comunidad != null) {
      final res = await ServicioComunidades().obtenerRolUsuarioEnComunidad(widget.comunidad!.id, userId);
      if (mounted && res.exito) {
        setState(() {
          _esModerador = res.datos == 'Administrador' || res.datos == 'Moderador';
          // Activamos modo gestión por defecto si es moderador
          if (_esModerador) _modoGestion = true;
        });
      }
    }
  }

  void _handleTabChange() {
    if (!_subTabController.indexIsChanging) {
      final tipos = ['Avatar', 'Marco', 'Fondo'];
      widget.onCategoryChanged?.call(tipos[_subTabController.index]);
    }
  }

  @override
  void dispose() {
    _subTabController.removeListener(_handleTabChange);
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos en una comunidad y la tienda no está habilitada, mostramos aviso
    if (widget.comunidad != null && !widget.comunidad!.tiendaHabilitada) {
      return _buildTiendaDeshabilitada();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_esModerador)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionChip(
                  avatar: Icon(_modoGestion ? Icons.admin_panel_settings_rounded : Icons.visibility_rounded, 
                    color: _modoGestion ? Colors.white : const Color(0xFFC35E34), size: 16),
                  label: Text(_modoGestion ? 'GESTIÓN ON' : 'PREVIEW', 
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _modoGestion ? Colors.white : const Color(0xFFC35E34))),
                  backgroundColor: _modoGestion ? const Color(0xFFC35E34) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFC35E34))),
                  onPressed: () => setState(() => _modoGestion = !_modoGestion),
                ),
              ],
            ),
          ),
        // Se elimina el toggle GLOBAL/EXCLUSIVO para que en la comunidad solo se vea lo EXCLUSIVO
        // si se quiere ir a la tienda global, ya hay un acceso en el navbar.
        Expanded(
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
                    controller: _subTabController,
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
                    controller: _subTabController,
                    children: [
                      _ListaMejorasTab(
                        tipo: 'Avatar', 
                        comunidadId: widget.comunidad?.id,
                        esModerador: _esModerador,
                        modoGestion: _modoGestion,
                        onPuntosActualizados: widget.onPuntosActualizados,
                      ),
                      _ListaMejorasTab(
                        tipo: 'Marco', 
                        comunidadId: widget.comunidad?.id,
                        esModerador: _esModerador,
                        modoGestion: _modoGestion,
                        onPuntosActualizados: widget.onPuntosActualizados,
                      ),
                      _ListaMejorasTab(
                        tipo: 'Fondo', 
                        comunidadId: widget.comunidad?.id,
                        esModerador: _esModerador,
                        modoGestion: _modoGestion,
                        onPuntosActualizados: widget.onPuntosActualizados,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.esVistaIntegrada) {
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
              widget.comunidad != null ? 'Tienda: ${widget.comunidad!.nombre}' : 'Tienda de Mejoras',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF4A4440), fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4A4440)),
      ),
      body: content,
      floatingActionButton: (_tabIndex == 1 && widget.comunidad != null) 
        ? FloatingActionButton.extended(
            onPressed: () => _irAEnviarPropuesta(),
            label: Text('Sugerir Diseño', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
            backgroundColor: widget.comunidad!.colorTema,
          )
        : null,
    );
  }

  Widget _buildTiendaDeshabilitada() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Esta comunidad no tiene la tienda habilitada aún 🐾',
            style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTienda() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 0),
              child: Container(
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? const Color(0xFFC35E34) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'GLOBAL',
                  style: GoogleFonts.outfit(
                    color: _tabIndex == 0 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 1),
              child: Container(
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? const Color(0xFFC35E34) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'EXCLUSIVO',
                  style: GoogleFonts.outfit(
                    color: _tabIndex == 1 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _irAEnviarPropuesta() {
    if (widget.comunidad == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEnviarPropuesta(comunidad: widget.comunidad!),
      ),
    );
  }
}

class _ListaMejorasTab extends StatefulWidget {
  final String tipo;
  final int? comunidadId;
  final bool esModerador;
  final bool modoGestion;
  final Function(int)? onPuntosActualizados;
  
  const _ListaMejorasTab({
    required this.tipo, 
    this.comunidadId, 
    this.esModerador = false, 
    this.modoGestion = false,
    this.onPuntosActualizados,
  });

  @override
  State<_ListaMejorasTab> createState() => _ListaMejorasTabState();
}

class _ListaMejorasTabState extends State<_ListaMejorasTab> {
  final ServicioMejoras _servicioMejoras = ServicioMejoras();
  final ServicioComunidades _servicioComunidades = ServicioComunidades();
  bool _isLoading = true;
  List<CatalogoMejoras> _mejoras = [];
  List<dynamic> _misMejoras = []; // Lista de mejoras que el usuario posee
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarMejoras();
  }

  @override
  void didUpdateWidget(_ListaMejorasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comunidadId != widget.comunidadId || oldWidget.modoGestion != widget.modoGestion) {
      _cargarMejoras();
    }
  }

  Future<void> _cargarMejoras() async {
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final respuesta = widget.comunidadId != null 
        ? await _servicioMejoras.obtenerMejorasComunidad(widget.comunidadId!)
        : await _servicioMejoras.obtenerMejorasGlobales();

    final misMejorasRespuesta = await _servicioMejoras.obtenerMisMejoras();
        
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (respuesta.exito) {
          final todas = (respuesta.datos as List<CatalogoMejoras>?) ?? [];
          // 1. Filtrar por tipo
          var filtradas = todas.where((m) => m.tipo.toLowerCase() == widget.tipo.toLowerCase()).toList();
          // 2. Si no estamos en modo gestión, ocultar las inactivas
          if (!widget.modoGestion) {
            filtradas = filtradas.where((m) => m.estaActivo).toList();
          }
          _mejoras = filtradas;
          if (misMejorasRespuesta.exito && misMejorasRespuesta.datos != null) {
            _misMejoras = misMejorasRespuesta.datos is Iterable 
                ? List<dynamic>.from(misMejorasRespuesta.datos!) 
                : [];
          }
        } else {
          _errorMensaje = respuesta.mensaje;
        }
      });
    }
  }

  bool _tieneMejora(int mejoraId) {
    if (_misMejoras is! Iterable) return false;
    try {
      return (_misMejoras as Iterable).any((m) => m != null && m is Map && m['mejora'] == mejoraId);
    } catch (e) {
      return false;
    }
  }

  bool _tieneEquipada(int mejoraId) {
    if (_misMejoras is! Iterable) return false;
    try {
      return (_misMejoras as Iterable).any((m) => m != null && m is Map && m['mejora'] == mejoraId && m['esta_equipada'] == true);
    } catch (e) {
      return false;
    }
  }

  void _abrirDetalleMejora(CatalogoMejoras mejora, bool laTiene, bool estaEquipada) {
    showDialog(
      context: context,
      builder: (context) => _DialogoDetalleMejora(
        mejora: mejora,
        laTiene: laTiene,
        estaEquipada: estaEquipada,
        onPuntosActualizados: widget.onPuntosActualizados, // Pass down to Dialog
        onComprado: () {
          _cargarMejoras();
        },
      ),
    );
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
      final String tipoPlural = widget.tipo.toLowerCase() == 'avatar' ? 'avatares' : '${widget.tipo.toLowerCase()}s';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay $tipoPlural disponibles aún 🐾',
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
        final bool estaActivo = mejora.estaActivo;
        final bool laTiene = _tieneMejora(mejora.id);
        final bool estaEquipada = _tieneEquipada(mejora.id);
        
        Widget card = GestureDetector(
          onTap: () => _abrirDetalleMejora(mejora, laTiene, estaEquipada),
          child: Container(
            decoration: BoxDecoration(
              color: estaActivo ? Colors.white : Colors.grey.shade50,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          (estaActivo && !estaEquipada)
                            ? [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0] // Normal
                            : [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0] // Grayscale
                        ),
                        child: Opacity(
                          opacity: estaActivo ? 1.0 : 0.6,
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
                      ),
                      if (estaEquipada)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          ),
                        ),

                    if (!estaActivo)
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'OCULTO',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Opacity(
                  opacity: estaActivo ? 1.0 : 0.7,
                  child: Column(
                    children: [
                      Text(
                        mejora.tipo,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A4440),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mejora.nombreCreador != null)
                        Text(
                          'por ${mejora.nombreCreador}',
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      if (estaActivo)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(laTiene ? Icons.check_circle_rounded : Icons.workspace_premium_rounded, 
                                 color: laTiene ? Colors.green : const Color(0xFFC35E34), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              laTiene ? 'Adquirido' : '${mejora.precioPuntos} pts',
                              style: GoogleFonts.outfit(
                                color: laTiene ? Colors.green : const Color(0xFFC35E34),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text('Ítem desactivado', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));

        if (widget.esModerador && widget.modoGestion) {
          return Stack(
            children: [
              card,
              Positioned(
                top: 4,
                right: 4,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: estaActivo,
                    activeColor: const Color(0xFFC35E34),
                    onChanged: (val) => _toggleActivo(mejora, val),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                right: 8,
                child: BotonTactil(
                  onTap: () => _mostrarDialogoPrecio(mejora),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFFC35E34), size: 16),
                  ),
                ),
              ),
            ],
          );
        }

        return card;
      },
    );
  }

  Future<void> _toggleActivo(CatalogoMejoras item, bool val) async {
    if (widget.comunidadId == null) return;
    
    final res = await _servicioMejoras.actualizarItemCatalogo(
      widget.comunidadId!, 
      item.id, 
      estaActivo: val
    );
    
    if (mounted) {
      if (res.exito) {
        _cargarMejoras();
      }
    }
  }

  void _mostrarDialogoPrecio(CatalogoMejoras item) {
    final controller = TextEditingController(text: item.precioPuntos.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cambiar Precio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF4A4440))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajusta el coste de la mejora:', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: 'pts',
                filled: true,
                fillColor: const Color(0xFFFEF5F1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC35E34)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final precio = int.tryParse(controller.text);
              if (precio != null && precio >= 0) {
                Navigator.pop(context);
                _actualizarPrecio(item, precio);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC35E34),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('GUARDAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarPrecio(CatalogoMejoras item, int nuevoPrecio) async {
    if (widget.comunidadId == null) return;
    
    final res = await _servicioMejoras.actualizarItemCatalogo(
      widget.comunidadId!, 
      item.id, 
      precio: nuevoPrecio
    );
    
    if (mounted) {
      if (res.exito) {
        _cargarMejoras();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio actualizado correctamente 🐾'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _DialogoDetalleMejora extends StatefulWidget {
  final CatalogoMejoras mejora;
  final bool laTiene;
  final bool estaEquipada;
  final VoidCallback onComprado;
  final Function(int)? onPuntosActualizados;
  
  const _DialogoDetalleMejora({
    required this.mejora, 
    required this.laTiene, 
    required this.estaEquipada,
    required this.onComprado,
    this.onPuntosActualizados,
  });

  @override
  State<_DialogoDetalleMejora> createState() => _DialogoDetalleMejoraState();
}

class _DialogoDetalleMejoraState extends State<_DialogoDetalleMejora> {
  bool _comprando = false;

  Future<void> _comprar() async {
    // Show confirmation first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Comprar diseño?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Esto costará ${widget.mejora.precioPuntos} puntos. ¿Estás seguro?', style: GoogleFonts.outfit(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC35E34)),
            child: Text('Comprar', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _comprando = true);
    final res = await ServicioMejoras().comprarMejora(widget.mejora.id);
    if (mounted) {
      setState(() => _comprando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje),
          backgroundColor: res.exito ? Colors.green : Colors.red,
        ),
      );
      if (res.exito) {
        widget.onComprado();
        if (widget.onPuntosActualizados != null && res.datos != null && res.datos is int) {
          widget.onPuntosActualizados!(res.datos as int);
        }
        Navigator.pop(context); // Close detail dialog on success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF5F1),
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: double.infinity,
                  color: const Color(0xFFFBE9E0),
                  padding: const EdgeInsets.all(24), // Give it some breathing room
                  child: widget.mejora.urlRecurso.isNotEmpty
                      ? Image.network(
                          widget.mejora.urlRecurso,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: Colors.grey.shade300, size: 64),
                        )
                      : Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade300, size: 64),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 30),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    widget.mejora.tipo,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF4A4440)),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.mejora.nombreCreador != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Diseño por ${widget.mejora.nombreCreador}',
                      style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (widget.estaEquipada)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text('Equipado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                        ],
                      ),
                    )
                  else if (widget.laTiene)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Ya adquirido', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _comprando ? null : _comprar,
                        icon: _comprando 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                        label: Text(
                          _comprando ? 'Comprando...' : 'Comprar por ${widget.mejora.precioPuntos} pts',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC35E34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  }
}

