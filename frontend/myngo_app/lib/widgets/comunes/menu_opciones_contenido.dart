import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myngo_app/services/servicio_moderacion.dart';
import 'package:myngo_app/services/servicio_usuarios.dart';
import 'package:myngo_app/services/servicio_galeria.dart';
import 'package:myngo_app/services/servicio_comunidades.dart';
import 'package:myngo_app/models/respuesta_api.dart';

class MenuOpcionesContenido extends StatelessWidget {
  final String tipoObjeto; // 'POST', 'IMAGEN', 'COMUNIDAD', 'COMENTARIO'
  final int objetoId;
  final int? autorId;
  final int? comunidadId;
  final int? creadorComunidadId;
  final VoidCallback? onEliminado;
  final VoidCallback? onEditado;
  final String? tituloPreview;

  const MenuOpcionesContenido({
    super.key,
    required this.tipoObjeto,
    required this.objetoId,
    this.autorId,
    this.comunidadId,
    this.creadorComunidadId,
    this.onEliminado,
    this.onEditado,
    this.tituloPreview,
  });

  @override
  Widget build(BuildContext context) {
    final servicioUsuarios = ServicioUsuarios();
    
    return FutureBuilder<int?>(
      future: servicioUsuarios.obtenerIdUsuario(),
      builder: (context, snapshot) {
        final userId = snapshot.data;
        if (userId == null) return const SizedBox.shrink();

        final esDuenio = userId == autorId;
        final esAdminComunidad = userId == creadorComunidadId;

        return PopupMenuButton<String>(
          key: ValueKey('menu_${tipoObjeto}_$objetoId'),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) => _manejarOpcion(context, val, userId),
          itemBuilder: (context) => [
            if (esDuenio) ...[
              _buildItem('editar', Icons.edit_outlined, 'Editar'),
              _buildItem('eliminar', Icons.delete_outline_rounded, 'Eliminar', color: Colors.redAccent),
            ] else if (esAdminComunidad) ...[
              _buildItem('eliminar_admin', Icons.gavel_rounded, 'Moderar (Borrar)', color: Colors.orangeAccent),
            ] else ...[
              _buildItem('reportar', Icons.report_problem_outlined, 'Reportar', color: Colors.yellowAccent),
            ],
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildItem(String val, IconData icon, String text, {Color? color}) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(color: color ?? Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  void _manejarOpcion(BuildContext context, String opcion, int userId) {
    if (opcion == 'eliminar' || opcion == 'eliminar_admin') {
      _confirmarEliminacion(context, opcion == 'eliminar_admin');
    } else if (opcion == 'reportar') {
      _mostrarDialogoReporte(context);
    } else if (opcion == 'editar') {
      if (onEditado != null) onEditado!();
    }
  }

  void _confirmarEliminacion(BuildContext context, bool esModeracion) {
    final TextEditingController razonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(esModeracion ? 'Moderar Contenido' : '¿Eliminar Contenido?', style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esModeracion 
                  ? 'Indica el motivo del borrado. El autor recibirá una notificación.' 
                  : 'Esta acción no se puede deshacer.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
              if (esModeracion) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: razonController,
                  maxLines: 2,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ej: Spam, lenguaje ofensivo...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: esModeracion ? Colors.orange : Colors.red),
              onPressed: (esModeracion && razonController.text.trim().isEmpty) ? null : () async {
                final razon = razonController.text.trim();
                Navigator.pop(context);
                
                RespuestaApi res = RespuestaApi(exito: false, mensaje: 'Operación cancelada');
                final servicioGaleria = ServicioGaleria();
                final servicioComunidades = ServicioComunidades();

                if (tipoObjeto == 'POST') {
                  res = await servicioComunidades.eliminarPublicacion(objetoId, razon: esModeracion ? razon : null);
                } else if (tipoObjeto == 'IMAGEN') {
                  res = await servicioGaleria.eliminarImagen(objetoId, razon: esModeracion ? razon : null);
                } else if (tipoObjeto == 'COMUNIDAD') {
                  res = await servicioComunidades.eliminarComunidad(objetoId);
                } else if (tipoObjeto == 'COMENTARIO') {
                  res = await servicioComunidades.eliminarComentario(objetoId, razon: esModeracion ? razon : null);
                }

                if (res.exito) {
                  if (onEliminado != null) onEliminado!();
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.mensaje), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoReporte(BuildContext context) {
    final servicioModeracion = ServicioModeracion();
    String? motivoSeleccionado;
    final motivos = ['Spam', 'Acoso', 'Contenido Inadecuado', 'Odio/Discriminación', 'Otros'];
    final TextEditingController comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Reportar Contenido', style: GoogleFonts.outfit(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...motivos.map((m) => RadioListTile<String>(
                  title: Text(m, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  value: m,
                  groupValue: motivoSeleccionado,
                  onChanged: (v) => setState(() => motivoSeleccionado = v),
                  activeColor: const Color(0xFF248EA6),
                  dense: true,
                )).toList(),
                const SizedBox(height: 16),
                TextField(
                  controller: comentarioController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Comentario opcional (miau...)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: motivoSeleccionado == null ? null : () async {
                final res = await servicioModeracion.reportarContenido(
                  tipoObjeto: tipoObjeto,
                  objetoId: objetoId,
                  motivo: motivoSeleccionado!,
                  comentario: comentarioController.text.trim().isEmpty ? null : comentarioController.text.trim(),
                  comunidadId: comunidadId,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.mensaje), backgroundColor: res.exito ? Colors.green : Colors.red),
                  );
                }
              },
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
