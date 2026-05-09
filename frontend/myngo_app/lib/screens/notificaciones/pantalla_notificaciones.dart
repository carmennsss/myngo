import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_comunidades.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import '../../models/notificacion.dart';
import '../comunidades/pantalla_detalle_publicacion.dart';
import '../comunidades/pantalla_detalle_comunidad.dart';
import '../comunidades/pantalla_admin_comunidad.dart';
import '../perfiles/pantalla_detalle_perfil.dart';
import '../inicio/pantalla_inicio.dart';
import '../../widgets/comunes/boton_tactil.dart';
import 'package:intl/intl.dart';

class PantallaNotificaciones extends StatefulWidget {
  final VoidCallback? onNotificacionesLeidas;
  const PantallaNotificaciones({super.key, this.onNotificacionesLeidas});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  final _servicioNotificaciones = ServicioNotificaciones();
  final _servicioComunidades = ServicioComunidades();
  final _servicioPerfiles = ServicioPerfiles();
  final _servicioUsuarios = ServicioUsuarios();
  List<Notificacion> _notificaciones = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  // Tipos que requieren acción del usuario: no se marcan leídas automáticamente
  static const _tiposPeticion = {'PETICION_CO_ADMIN', 'PETICION_UNION', 'PETICION_SEGUIMIENTO'};

  Future<void> _cargarNotificaciones() async {
    final respuesta = await _servicioNotificaciones.listarNotificaciones();
    if (mounted) {
      setState(() {
        _notificaciones = respuesta.datos ?? [];
        _estaCargando = false;
      });

      // Solo marcamos como leídas las que NO son peticiones pendientes
      final tieneNoLeidasNormales = _notificaciones.any(
        (n) => !n.leida && !_tiposPeticion.contains(n.tipo),
      );

      if (tieneNoLeidasNormales) {
        await _servicioNotificaciones.marcarTodasComoLeidas();
        if (mounted) {
          setState(() {
            _notificaciones = _notificaciones.map((n) {
              // Las peticiones pendientes conservan su estado leída=false
              if (_tiposPeticion.contains(n.tipo)) return n;
              return n.copyWith(leida: true);
            }).toList();
          });
          // Notificar al padre para que refresque el badge
          widget.onNotificacionesLeidas?.call();
        }
      }
    }
  }

  Future<void> _responder(Notificacion notif, bool aceptar) async {
    if (notif.referenciaId == null) return;
    
    dynamic respuesta;
    if (notif.nombreComunidad != null && notif.nombreComunidad!.isNotEmpty) {
      respuesta = await _servicioComunidades.responderPeticionAcceso(notif.referenciaId!, aceptar);
    } else {
      respuesta = await _servicioPerfiles.responderSolicitudSeguimiento(notif.referenciaId!, aceptar);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje, style: GoogleFonts.outfit()),
          backgroundColor: respuesta.exito ? const Color(0xFF248EA6) : const Color(0xFFD95F43),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      if (respuesta.exito) _cargarNotificaciones();
    }
  }

  void _navegarADetalle(Notificacion notif) async {
    // Marcar como leída localmente e informar al servidor
    if (!notif.leida) {
      _servicioNotificaciones.marcarComoLeida(notif.id);
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
        }
      });
      widget.onNotificacionesLeidas?.call();
    }

    if (notif.tipo == 'LIKE' || notif.tipo == 'COMENTARIO') {
      if (notif.referenciaId != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetallePublicacion(publicacionId: notif.referenciaId)));
      }
    } else if (['VOTO', 'SEGUIMIENTO', 'PETICION_ACEPTADA', 'PETICION_SEGUIMIENTO'].contains(notif.tipo)) {
      if (notif.idGenerador != null) {
        final res = await _servicioUsuarios.obtenerDatosUsuario(notif.idGenerador!);
        if (mounted && res.exito && res.datos != null) {
          final inicioState = context.findAncestorStateOfType<PantallaInicioState>();
          if (inicioState != null) {
            inicioState.seleccionarUsuario(res.datos!);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PantallaDetallePerfil(usuario: res.datos!),
              ),
            );
          }
        }
      }
    } else if (notif.tipo == 'NUEVO_REPORTE' || notif.tipo == 'NUEVA_PROPUESTA_TIENDA') {
      if (notif.idComunidad != null) {
        final res = await _servicioComunidades.obtenerComunidad(notif.idComunidad!);
        if (mounted && res.exito && res.datos != null) {
          int initialTab = notif.tipo == 'NUEVO_REPORTE' ? 2 : 3;
          Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaAdminComunidad(comunidad: res.datos!, initialTab: initialTab)));
        }
      }
    } else if (['PROPUESTA_TIENDA_ACEPTADA', 'PROPUESTA_TIENDA_RECHAZADA', 'ROL_ACTUALIZADO', 'CONTENIDO_BORRADO'].contains(notif.tipo)) {
      if (notif.idComunidad != null) {
        final res = await _servicioComunidades.obtenerComunidad(notif.idComunidad!);
        if (mounted && res.exito && res.datos != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaDetalleComunidad(comunidad: res.datos!, initialIndex: (notif.tipo.contains('TIENDA')) ? 1 : 0)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEF5F1),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC35E34))),
      );
    }

    final interacciones = _notificaciones.where((n) => ['LIKE', 'COMENTARIO', 'VOTO'].contains(n.tipo)).toList();
    final solicitudes = _notificaciones.where((n) => ['PETICION_UNION', 'PETICION_CO_ADMIN', 'PETICION_SEGUIMIENTO', 'NUEVO_REPORTE', 'NUEVA_PROPUESTA_TIENDA'].contains(n.tipo)).toList();
    final sistema = _notificaciones.where((n) => !['LIKE', 'COMENTARIO', 'VOTO', 'PETICION_UNION', 'PETICION_CO_ADMIN', 'PETICION_SEGUIMIENTO', 'NUEVO_REPORTE', 'NUEVA_PROPUESTA_TIENDA'].contains(n.tipo)).toList();

    return DefaultTabController(
      length: 3,
      child: TranslationWidget(
        builder: (context, tr) => Scaffold(
          backgroundColor: const Color(0xFFFEF5F1), // Peach Cream Universal
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            title: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                tr('notificationTitle'),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4A4440),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            bottom: TabBar(
              dividerColor: Colors.transparent,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
              unselectedLabelColor: Colors.grey.shade500,
              labelColor: const Color(0xFFC35E34),
              indicatorColor: const Color(0xFFC35E34),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: tr('notificationTabInteractions'), icon: const Icon(Icons.favorite_rounded)),
                Tab(text: tr('notificationTabRequests'), icon: const Icon(Icons.group_add_rounded)),
                Tab(text: tr('notificationTabAlerts'), icon: const Icon(Icons.notifications_rounded)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildListaTab(interacciones, tr('notificationEmptyInteractions'), Icons.favorite_border_rounded, tr),
              _buildListaTab(solicitudes, tr('notificationEmptyRequests'), Icons.group_add_rounded, tr),
              _buildListaTab(sistema, tr('notificationEmptyAlerts'), Icons.notifications_none_rounded, tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaTab(List<Notificacion> lista, String mensajeVacio, IconData iconoVacio, dynamic tr) {
    if (lista.isEmpty) return _buildVistaVaciaEspecial(mensajeVacio, iconoVacio, tr);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: lista.length,
      itemBuilder: (context, index) => _TarjetaNotificacion(
        notif: lista[index],
        isLast: index == lista.length - 1,
        onResponder: _responder,
        onTap: _navegarADetalle,
        tr: tr,
      ),
    );
  }

  Widget _buildVistaVaciaEspecial(String mensaje, IconData icono, dynamic tr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                 BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(icono, size: 64, color: Colors.grey.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            tr('notificationEmptyTitle'),
            style: GoogleFonts.outfit(color: const Color(0xFF4A4440), fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje, 
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14)
          ),
        ],
      ),
    );
  }

}

class _TarjetaNotificacion extends StatelessWidget {
  final Notificacion notif;
  final bool isLast;
  final Function(Notificacion, bool) onResponder;
  final Function(Notificacion) onTap;
  final dynamic tr;

  const _TarjetaNotificacion({
    required this.notif,
    this.isLast = false,
    required this.onResponder,
    required this.onTap,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    bool esPeticionPendiente = (notif.tipo == 'PETICION_CO_ADMIN' || notif.tipo == 'PETICION_SEGUIMIENTO' || notif.tipo == 'PETICION_UNION') && 
                                (notif.estadoPeticion == null || notif.estadoPeticion!.isEmpty);
    final color = _getColorTipo(notif.tipo);
    final icon = _getIconoTipo(notif.tipo);

    return BotonTactil(
      onTap: () => onTap(notif),
      child: Opacity(
        opacity: notif.leida ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF4A4440).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: notif.leida ? Colors.transparent : const Color(0xFFC35E34).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.mensaje,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: notif.leida ? FontWeight.w500 : FontWeight.w800,
                            color: const Color(0xFF4A4440),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd MMM · HH:mm').format(notif.fechaNotificacion),
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  if (!notif.leida)
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC35E34), shape: BoxShape.circle)),
                ],
              ),
              if (esPeticionPendiente) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BotonTactil(
                        onTap: () => onResponder(notif, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFFC35E34), borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text(tr('notificationAccept'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BotonTactil(
                        onTap: () => onResponder(notif, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text(tr('notificationReject'), style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo) {
      case 'LIKE': return Icons.favorite_rounded;
      case 'COMENTARIO': return Icons.chat_bubble_rounded;
      case 'PETICION_CO_ADMIN':
      case 'PETICION_UNION':
      case 'PETICION_SEGUIMIENTO': return Icons.group_add_rounded;
      case 'VOTO': return Icons.star_rounded;
      case 'PETICION_ACEPTADA': return Icons.check_circle_rounded;
      case 'PETICION_RECHAZADA': return Icons.error_outline_rounded;
      case 'NUEVO_REPORTE': return Icons.report_problem_rounded;
      case 'NUEVA_PROPUESTA_TIENDA': return Icons.storefront_rounded;
      case 'PROPUESTA_TIENDA_ACEPTADA': return Icons.shopping_bag_rounded;
      case 'PROPUESTA_TIENDA_RECHAZADA': return Icons.shopping_bag_outlined;
      case 'ROL_ACTUALIZADO': return Icons.verified_user_rounded;
      case 'CONTENIDO_BORRADO': return Icons.delete_sweep_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColorTipo(String tipo) {
    switch (tipo) {
      case 'LIKE': return const Color(0xFFD95F43);
      case 'COMENTARIO': return const Color(0xFF248EA6);
      case 'PETICION_CO_ADMIN':
      case 'PETICION_UNION':
      case 'PETICION_SEGUIMIENTO': return const Color(0xFFC35E34);
      case 'VOTO': return Colors.amber;
      case 'PETICION_ACEPTADA': return const Color(0xFF248EA6);
      case 'PETICION_RECHAZADA': return const Color(0xFFD95F43);
      case 'NUEVO_REPORTE': return Colors.redAccent;
      case 'NUEVA_PROPUESTA_TIENDA': return const Color(0xFFC35E34);
      case 'PROPUESTA_TIENDA_ACEPTADA': return const Color(0xFF248EA6);
      case 'PROPUESTA_TIENDA_RECHAZADA': return Colors.grey;
      case 'ROL_ACTUALIZADO': return Colors.blueAccent;
      case 'CONTENIDO_BORRADO': return const Color(0xFFD95F43);
      default: return const Color(0xFFF29C50);
    }
  }
}
