import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../models/perfil.dart';
import '../../services/servicio_perfiles.dart';
import 'pantalla_detalle_perfil.dart';

class PantallaPerfiles extends StatefulWidget {
  final bool esModoIncrustado;
  const PantallaPerfiles({super.key, this.esModoIncrustado = false});

  @override
  State<PantallaPerfiles> createState() => _PantallaPerfilesState();
}

class _PantallaPerfilesState extends State<PantallaPerfiles> {
  final _servicio = ServicioPerfiles();
  final _controladorBusqueda = TextEditingController();
  List<Perfil> _perfiles = [];
  bool _estaCargando = true;
  @override
  void initState() {
    super.initState();
    _cargarPerfiles();
  }

  Future<void> _cargarPerfiles({String? filtro}) async {
    setState(() => _estaCargando = true);
    final respuesta = await _servicio.listarPerfiles(busqueda: filtro);
    if (mounted) {
      setState(() {
        _perfiles = respuesta.exito ? (respuesta.datos ?? []) : [];
        _estaCargando = false;
      });
      // Avisamos gentilmente en caso de fallo (por ejemplo si el backend no lo has creado todavía)
      if (!respuesta.exito && _perfiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(respuesta.mensaje),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.esModoIncrustado ? Colors.transparent : const Color(0xFFF8F9FE),
      appBar: widget.esModoIncrustado ? null : AppBar(
        title: const Text('Explorar Perfiles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _controladorBusqueda,
              onChanged: (valor) => _cargarPerfiles(filtro: valor),
              decoration: InputDecoration(
                hintText: 'Buscar usuarios o perfiles...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: _estaCargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _perfiles.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron perfiles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9094A6)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _cargarPerfiles(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _perfiles.length,
                      itemBuilder: (context, index) {
                        final perfil = _perfiles[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                           leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                          // backgroundImage intentará cargar la URL de S3
                          backgroundImage: (perfil.urlAvatar != null && perfil.urlAvatar!.isNotEmpty)
                              ? NetworkImage(perfil.urlAvatar!)
                              : null,
                          // El child solo se muestra si backgroundImage es null o está cargando
                          child: (perfil.urlAvatar == null || perfil.urlAvatar!.isEmpty)
                              ? Text(
                                  perfil.nombreUsuario.isNotEmpty 
                                      ? perfil.nombreUsuario[0].toUpperCase() 
                                      : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                )
                              : null
                            ),
                            title: Text(
                              perfil.nombreUsuario, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            subtitle: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                 perfil.ratingActual.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (perfil.esVerificado) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB0B3C6)),
                            onTap: () {
                            if (perfil.datosUsuario != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Le pasas directamente el objeto Usuario que ya viene dentro del Perfil
                                  builder: (context) => PantallaDetallePerfil(usuario: perfil.datosUsuario!),
                                ),
                              );
                            }
                            }
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
