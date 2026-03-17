import 'package:flutter/material.dart';
import '../../../widgets/campo_texto_personalizado.dart';
import '../../../widgets/boton_carga.dart';
import '../../../services/servicio_comunidades.dart';
import '../../../models/comunidad.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Modal para la creación de nuevas comunidades.
class FormularioCreacionComunidad extends StatefulWidget {
  final VoidCallback alConfirmar;

  const FormularioCreacionComunidad({super.key, required this.alConfirmar});

  @override
  State<FormularioCreacionComunidad> createState() => _FormularioCreacionComunidadState();
}

class _FormularioCreacionComunidadState extends State<FormularioCreacionComunidad> {
  final _llaveFormulario = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorDescripcion = TextEditingController();
  final _nodoNombre = FocusNode();
  final _nodoDescripcion = FocusNode();
  
  bool _esPublica = true;
  XFile? _imagenSeleccionada;
  final _estaCargando = ValueNotifier<bool>(false);
  final _servicio = ServicioComunidades();
  final _picker = ImagePicker();

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
      });
    }
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorDescripcion.dispose();
    _nodoNombre.dispose();
    _nodoDescripcion.dispose();
    _estaCargando.dispose();
    super.dispose();
  }

  Future<void> _crearComunidad() async {
    if (_llaveFormulario.currentState!.validate()) {
      _estaCargando.value = true;
      
      final nuevaComunidad = Comunidad(
        id: 0,
        nombre: _controladorNombre.text.trim(),
        descripcion: _controladorDescripcion.text.trim(),
        creadorNombre: '', // Lo asigna el backend
        urlPortada: '', // Se enviará vía Multipart si hay imagen
        esPublica: _esPublica,
        esVerificada: false,
        ratingMedio: 0.0,
        fechaCreacion: DateTime.now(),
      );

      final respuesta = await _servicio.crearComunidad(nuevaComunidad, imagen: _imagenSeleccionada);
      _estaCargando.value = false;

      if (mounted) {
        if (respuesta.exito) {
          Navigator.pop(context);
          widget.alConfirmar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Comunidad creada 🐾!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(respuesta.mensaje), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _llaveFormulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva Comunidad 🐾',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Selector de Imagen
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                  image: _imagenSeleccionada != null
                      ? DecorationImage(
                          image: kIsWeb 
                            ? NetworkImage(_imagenSeleccionada!.path) as ImageProvider
                            : FileImage(File(_imagenSeleccionada!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imagenSeleccionada == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF6C63FF)),
                          SizedBox(height: 8),
                          Text('Añadir foto de portada', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            SizedBox(height: 24),
            
            CampoTextoPersonalizado(
              etiqueta: 'Nombre de la comunidad',
              icono: Icons.groups_outlined,
              controlador: _controladorNombre,
              nodoEnfoque: _nodoNombre,
              validador: (v) => (v == null || v.isEmpty) ? 'Escribe un nombre' : null,
            ),
            SizedBox(height: 16),
            
            CampoTextoPersonalizado(
              etiqueta: 'Descripción / Reglas',
              icono: Icons.description_outlined,
              controlador: _controladorDescripcion,
              nodoEnfoque: _nodoDescripcion,
              maxLineas: 5,
              minLineas: 3,
            ),
            SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF7F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: Text(
                  _esPublica ? 'Comunidad Pública 🌍' : 'Comunidad Privada 🔒',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _esPublica ? 'Cualquier miau puede unirse libremente' : 'Solo con invitación o solicitud aceptada',
                  style: TextStyle(fontSize: 12),
                ),
                secondary: Icon(
                  _esPublica ? Icons.pets_rounded : Icons.lock_person_rounded,
                  color: Color(0xFF6C63FF),
                ),
                value: _esPublica,
                onChanged: (v) => setState(() => _esPublica = v),
                activeColor: Color(0xFF6C63FF),
              ),
            ),
            SizedBox(height: 24),
            
            BotonCarga(
              alPresionar: _crearComunidad,
              notificadorCargando: _estaCargando,
              texto: 'CREAR COMUNIDAD 🐾',
            ),
          ],
        ),
      ),
    );
  }
}
