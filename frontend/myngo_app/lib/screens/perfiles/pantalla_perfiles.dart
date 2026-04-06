import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/usuario.dart';
import '../../models/perfil.dart';
import '../../services/servicio_perfiles.dart';
import '../../widgets/comunes/boton_tactil.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F1),
      body: Column(
        children: [
          // Barra de Búsqueda Harmonizada
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A4440).withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _controladorBusqueda,
                style: GoogleFonts.outfit(color: const Color(0xFF4A4440)),
                onChanged: (valor) => _cargarPerfiles(filtro: valor),
                decoration: InputDecoration(
                  hintText: 'Busca exploradores Myngo... 🔍',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 20, right: 12),
                    child: Icon(Icons.person_search_rounded, color: Color(0xFFF28B50), size: 24),
                  ),
                  suffixIcon: _controladorBusqueda.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _controladorBusqueda.clear();
                          _cargarPerfiles();
                        },
                      ) 
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),
          
          // Lista de resultados
          Expanded(
            child: _estaCargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28B50)))
              : _perfiles.isEmpty
                ? _buildVistaVacia()
                : RefreshIndicator(
                    color: const Color(0xFFC35E34),
                    backgroundColor: Colors.white,
                    onRefresh: () => _cargarPerfiles(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: _perfiles.length,
                      itemBuilder: (context, index) {
                        final perfil = _perfiles[index];
                        return _TarjetaPerfilBusqueda(perfil: perfil);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded, size: 64, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            'No hay nadie por aquí...',
            style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPerfilBusqueda extends StatelessWidget {
  final Perfil perfil;
  const _TarjetaPerfilBusqueda({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return BotonTactil(
      onTap: () {
        if (perfil.datosUsuario != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDetallePerfil(usuario: perfil.datosUsuario!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A4440).withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC35E34).withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFEF5F1),
              backgroundImage: (perfil.urlAvatar != null && perfil.urlAvatar!.isNotEmpty)
                  ? NetworkImage(perfil.urlAvatar!)
                  : null,
              child: (perfil.urlAvatar == null || perfil.urlAvatar!.isEmpty)
                  ? Text(
                      perfil.nombreUsuario.isNotEmpty ? perfil.nombreUsuario[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(color: const Color(0xFFC35E34), fontWeight: FontWeight.w900, fontSize: 20),
                    )
                  : null
            ),
          ),
          title: Row(
            children: [
              Text(
                perfil.nombreUsuario, 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF4A4440))
              ),
              if (perfil.esVerificado) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Color(0xFF248EA6), size: 16),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Icon(Icons.star_rounded, color: const Color(0xFFF29C50).withOpacity(0.7), size: 16),
              const SizedBox(width: 4),
              Text(
                perfil.ratingActual.toString(),
                style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF28B50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFF28B50), size: 20),
          ),
        ),
      ),
    );
  }
}
