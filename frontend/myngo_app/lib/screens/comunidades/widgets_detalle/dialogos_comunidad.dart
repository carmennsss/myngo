import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tolgee/tolgee.dart';
import '../../../services/servicio_galeria.dart';
import 'package:myngo_app/utils/tr_helper.dart';


/// Clase de utilidad para mostrar diálogos comunes en la comunidad.
class DialogosComunidad {
  /// Muestra el diálogo para crear una nueva colección de galería.
  static void mostrarDialogoNuevaColeccion(
    BuildContext context, {
    required int idComunidad,
    required VoidCallback onCreada,
  }) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool esPrivada = false;
    bool cargando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('collectionCreateTitle'),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A4440),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nombreCtrl,
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                  decoration: InputDecoration(
                    hintText: tr('dialogNewCollectionNameHint'),
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFFBF9F8),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                  decoration: InputDecoration(
                    hintText: tr('dialogNewCollectionDescHint'),
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFFBF9F8),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    esPrivada ? tr('commonPrivate') : tr('commonPublic'),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF4A4440),
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    esPrivada
                        ? tr('galleryCollectionPrivateDesc')
                        : tr('galleryCollectionPublicDesc'),
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                  ),
                  value: esPrivada,
                  activeColor: const Color(0xFF248EA6),
                  onChanged: (val) => setModalState(() => esPrivada = val),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cargando
                        ? null
                        : () async {
                            if (nombreCtrl.text.isEmpty) return;
                            setModalState(() => cargando = true);
                            final res = await ServicioGaleria().crearColeccion(
                              nombre: nombreCtrl.text,
                              descripcion: descCtrl.text,
                              esPrivada: esPrivada,
                              idComunidad: idComunidad,
                            );
    
                            if (context.mounted) {
                              setModalState(() => cargando = false);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.mensaje),
                                  backgroundColor:
                                      res.exito ? Colors.green : Colors.red,
                                ),
                              );
                              if (res.exito) onCreada();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF248EA6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(tr('collectionCreateTitle'),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
      }),
    );

  }
}
