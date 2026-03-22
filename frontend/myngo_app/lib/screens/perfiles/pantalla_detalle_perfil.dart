import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/servicio_perfiles.dart';
import '../../services/servicio_usuarios.dart';
import 'package:intl/intl.dart';

/// Pantalla que muestra los detalles del perfil de un usuario.
class PantallaDetallePerfil extends StatefulWidget {
  final Usuario usuario;
  const PantallaDetallePerfil({super.key, required this.usuario});

  @override
  State<PantallaDetallePerfil> createState() => _PantallaDetallePerfilState();
}

class _PantallaDetallePerfilState extends State<PantallaDetallePerfil> {
  int? _currentUserId;
  bool _isLoading = false;
  String? _estadoSeguimiento;

  @override
  void initState() {
    super.initState();
    _estadoSeguimiento = widget.usuario.estadoSeguimiento;
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final id = await ServicioUsuarios().obtenerIdUsuario();
    if (mounted) {
      setState(() => _currentUserId = id);
    }
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final respuesta = await ServicioPerfiles().enviarSolicitud(widget.usuario.nombreUsuario);
    
    if (mounted) {
      if (respuesta.exito) {
        setState(() {
          _estadoSeguimiento = respuesta.datos; // Puede ser null si se dejó de seguir
        });
      }
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(respuesta.mensaje),
          backgroundColor: respuesta.exito ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _manejarPulsacionBoton() async {
    if (_estadoSeguimiento == 'ACEPTADO' || _estadoSeguimiento == 'SOLICITUD') {
      // Preguntar antes de dejar de seguir o cancelar
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: Text(_estadoSeguimiento == 'ACEPTADO' 
            ? '¿Quieres dejar de seguir a @${widget.usuario.nombreUsuario}?' 
            : '¿Quieres cancelar la solicitud enviada a @${widget.usuario.nombreUsuario}?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sí, desenlazar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    await _enviarSolicitud();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;
    final inicial = usuario.nombreUsuario.isNotEmpty 
        ? usuario.nombreUsuario[0].toUpperCase() 
        : '?';

    final String fecha = DateFormat('dd MMM yyyy').format(usuario.fechaRegistro);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header con la portada/avatar en grande
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFB39DDB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: (usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(usuario.urlAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (usuario.urlAvatar == null || usuario.urlAvatar!.isEmpty)
                        ? Center(
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y Verificación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '@${usuario.nombreUsuario}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: Color(0xFF2D3142),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (usuario.esVerificado) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 22, color: Colors.blue),
                            ],
                          ],
                        ),
                      ),
                      _ChipPrivacidad(esPublica: usuario.esPublico),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Seguidores y Seguidos
                  Row(
                    children: [
                      Text(
                        '${usuario.numeroSeguidores}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(width: 4),
                      const Text('Seguidores', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(width: 20),
                      Text(
                        '${usuario.numeroSeguidos}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(width: 4),
                      const Text('Siguiendo', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_currentUserId != null && _currentUserId != usuario.id)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 36,
                        child: _construirBotonAccion(usuario),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Fila de Info (Rating, Fecha, Puntos)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        icono: Icons.star_rounded,
                        color: Colors.amber,
                        valor: usuario.ratingActual.toStringAsFixed(1),
                        etiqueta: 'Rating',
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _StatColumn(
                        icono: Icons.calendar_today_rounded,
                        color: Colors.blueGrey,
                        valor: fecha,
                        etiqueta: 'Se unió',
                      ),
                      if (usuario.puntos != null) ...[
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _StatColumn(
                          icono: Icons.workspace_premium_rounded,
                          color: Colors.orange,
                          valor: usuario.puntos.toString(),
                          etiqueta: 'Puntos',
                        ),
                      ],
                    ],
                  ),
                  
                  const Divider(height: 48, thickness: 1, color: Color(0xFFF1F3F9)),
                  
                  // Biografía (Bloqueada si es privada)
                  const Text(
                    'Sobre Mí 🐾',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3142)
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!usuario.esPublico) 
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          children: [
                            const Icon(Icons.lock_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Esta cuenta es privada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sigue a este usuario para ver sus fotos y su biografía',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      (usuario.biografia == null || usuario.biografia!.isEmpty)
                        ? 'Este usuario es un poco tímido y aún no ha escrito su biografía.'
                        : usuario.biografia!,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey.shade700, 
                        height: 1.6
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Espacio para el botón anclado
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonAccion(Usuario usuario) {
    String texto;
    IconData icono;
    Color colorFondo;
    Color colorTexto = Colors.white;

    if (_estadoSeguimiento == 'ACEPTADO') {
      texto = 'Siguiendo';
      icono = Icons.person_remove_rounded;
      colorFondo = Colors.grey.shade200;
      colorTexto = const Color(0xFF2D3142);
    } else if (_estadoSeguimiento == 'SOLICITUD') {
      texto = 'Pendiente';
      icono = Icons.cancel_rounded;
      colorFondo = Colors.grey.shade200;
      colorTexto = const Color(0xFF2D3142);
    } else {
      // No le sigue o fue denegado
      texto = usuario.esPublico ? 'Seguir' : 'Solicitar';
      icono = usuario.esPublico ? Icons.person_add_alt_1_rounded : Icons.lock_person_rounded;
      colorFondo = const Color(0xFF6C63FF);
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _manejarPulsacionBoton,
      icon: Icon(icono, size: 18, color: colorTexto),
      label: Text(
        texto,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorTexto),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorFondo,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}


// Chip Auxiliar de Privacidad
class _ChipPrivacidad extends StatelessWidget {
  final bool esPublica;
  const _ChipPrivacidad({required this.esPublica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: esPublica ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esPublica ? Icons.visibility_rounded : Icons.lock_rounded,
            size: 14,
            color: esPublica ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            esPublica ? 'Público' : 'Privado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: esPublica ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para mostrar las métricas
class _StatColumn extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;

  const _StatColumn({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 18,
                color: Color(0xFF2D3142),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9094A6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
