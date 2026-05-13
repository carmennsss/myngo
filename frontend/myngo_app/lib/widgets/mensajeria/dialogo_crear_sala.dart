import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/usuario.dart';
import 'package:tolgee/tolgee.dart';
import 'package:myngo_app/utils/tr_helper.dart';


// Bottom sheet para crear una sala de chat nueva.
// Permite poner nombre, buscar y seleccionar participantes, y en comunidades elegir si el chat será público o privado.
class DialogoCrearSala extends StatefulWidget {
  final List<Usuario> potencialesParticipantes; // Lista de usuarios que se pueden añadir
  final Function(String nombre, bool esPublica, List<int> miembrosIds) alCrear; // Callback cuando se pulsa 'Crear'
  final String titulo;        // El título del bottom sheet
  final bool esDeComunidad;   // Si es true, muestra el interruptor público/privado

  const DialogoCrearSala({
    super.key,
    required this.potencialesParticipantes,
    required this.alCrear,
    this.titulo = 'Nuevo Chat 🐾',
    this.esDeComunidad = false,
  });

  @override
  State<DialogoCrearSala> createState() => _DialogoCrearSalaState();
}

class _DialogoCrearSalaState extends State<DialogoCrearSala> {
  final _nombreController = TextEditingController();
  bool _esPublica = false;
  final List<int> _miembrosSeleccionados = [];
  String _busqueda = '';
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    final participantesFiltrados = widget.potencialesParticipantes.where((u) {
      if (_busqueda.isEmpty) return true;
      return u.nombreUsuario.toLowerCase().contains(_busqueda.toLowerCase());
    }).toList();

    return Builder(
      builder: (context) {
        // Si el título es el por defecto (Nuevo Chat 🐾), lo localizamos
        final tituloFinal = widget.titulo == 'Nuevo Chat 🐾' ? tr('chatNew') : widget.titulo;
        return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tirador superior
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            widget.titulo,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D2D2D),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),

          // Nombre de la sala
          TextField(
            controller: _nombreController,
            onChanged: (val) => setState(() {}),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: tr('chatNameLabel'),
              labelStyle: GoogleFonts.outfit(color: Colors.grey),
              hintText: tr('chatNameHint'),
              prefixIcon: const Icon(Icons.edit_rounded, color: Color(0xFFC35E34)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFC35E34), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interruptor Público/Privado (Solo para comunidades)
          if (widget.esDeComunidad) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF5EBE6)),
              ),
              child: Row(
                children: [
                  Icon(
                    _esPublica ? Icons.public_rounded : Icons.lock_rounded,
                    color: const Color(0xFFC35E34),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _esPublica ? tr('chatPublic') : tr('chatPrivate'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _esPublica 
                            ? tr('chatPublicDesc') 
                            : tr('chatPrivateDesc'),
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _esPublica,
                    onChanged: (val) => setState(() => _esPublica = val),
                    activeColor: const Color(0xFFC35E34),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            tr('chatParticipantsCount', {'count': _miembrosSeleccionados.length.toString()}),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),

          // Buscador de participantes
          TextField(
            onChanged: (val) => setState(() => _busqueda = val),
            decoration: InputDecoration(
              hintText: tr('chatSearchParticipantsHint'),
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Lista de participantes
          Expanded(
            child: participantesFiltrados.isEmpty 
              ? Center(child: Text(tr('chatNoParticipantsFound'), style: GoogleFonts.outfit(color: Colors.grey)))
              : ListView.builder(
                  itemCount: participantesFiltrados.length,
                  itemBuilder: (context, index) {
                    final u = participantesFiltrados[index];
                    final seleccionado = _miembrosSeleccionados.contains(u.id);
                    
                    return CheckboxListTile(
                      value: seleccionado,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _miembrosSeleccionados.add(u.id);
                          } else {
                            _miembrosSeleccionados.remove(u.id);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundImage: u.urlAvatar != null ? NetworkImage(u.urlAvatar!) : null,
                        child: u.urlAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(u.nombreUsuario, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.email, style: GoogleFonts.outfit(fontSize: 12)),
                      activeColor: const Color(0xFFC35E34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  },
                ),
          ),

          const SizedBox(height: 16),

          // Botón Crear
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_nombreController.text.trim().isNotEmpty && _miembrosSeleccionados.isNotEmpty && !_cargando)
                ? () async {
                    setState(() => _cargando = true);
                    await widget.alCrear(_nombreController.text.trim(), _esPublica, _miembrosSeleccionados);
                    if (mounted) setState(() => _cargando = false);
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC35E34),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _cargando 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Text(
                    tr('chatCreateAction'),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
