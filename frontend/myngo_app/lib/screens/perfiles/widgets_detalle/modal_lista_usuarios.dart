import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../services/servicio_usuarios.dart';
import '../../../utils/tr_helper.dart';
import '../pantalla_detalle_perfil.dart';

class ModalListaUsuarios extends StatefulWidget {
  final int usuarioId;
  final String titulo;
  final bool esSeguidores;
  final bool esAppClara;
  final Color colorTextoPrincipal;
  final Color colorTextoSecundario;

  const ModalListaUsuarios({
    super.key,
    required this.usuarioId,
    required this.titulo,
    required this.esSeguidores,
    required this.esAppClara,
    required this.colorTextoPrincipal,
    required this.colorTextoSecundario,
  });

  @override
  State<ModalListaUsuarios> createState() => _ModalListaUsuariosState();
}

class _ModalListaUsuariosState extends State<ModalListaUsuarios> {
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();
  List<Usuario>? _usuarios;
  bool _estaCargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _estaCargando = true;
      _error = null;
    });

    final respuesta = widget.esSeguidores
        ? await _servicioUsuarios.obtenerSeguidores(widget.usuarioId)
        : await _servicioUsuarios.obtenerSeguidos(widget.usuarioId);

    if (mounted) {
      setState(() {
        _estaCargando = false;
        if (respuesta.exito) {
          _usuarios = respuesta.datos;
        } else {
          _error = respuesta.mensaje;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorFondo = Theme.of(context).colorScheme.surface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barra superior
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 5),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.colorTextoPrincipal,
                    fontFamily: 'Outfit',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: widget.colorTextoSecundario),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _estaCargando
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF28B50)))
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: widget.colorTextoSecundario),
                        ),
                      )
                    : _usuarios == null || _usuarios!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64,
                                    color: widget.colorTextoSecundario
                                        .withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  TrHelper.tr(context, 'no_data',
                                      defaultValue: 'No hay usuarios que mostrar'),
                                  style: TextStyle(
                                      color: widget.colorTextoSecundario),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _usuarios!.length,
                            separatorBuilder: (context, index) =>
                                const Divider(indent: 72, height: 1),
                            itemBuilder: (context, index) {
                              final usuario = _usuarios![index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  backgroundImage: usuario.urlAvatar != null
                                      ? NetworkImage(usuario.urlAvatar!)
                                      : null,
                                  child: usuario.urlAvatar == null
                                      ? Icon(Icons.person,
                                          color: widget.colorTextoSecundario)
                                      : null,
                                ),
                                title: Text(
                                  usuario.nombreUsuario,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.colorTextoPrincipal,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                subtitle: (usuario.biografia != null && usuario.biografia!.isNotEmpty)
                                    ? Text(
                                        usuario.biografia!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.colorTextoSecundario,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(context); // Cerrar modal
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PantallaDetallePerfil(
                                        idOrUsername: usuario.nombreUsuario,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
