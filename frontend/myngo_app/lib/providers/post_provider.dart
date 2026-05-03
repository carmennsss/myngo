import 'package:flutter/material.dart';
import '../models/publicacion.dart';
import '../services/servicio_comunidades.dart';

enum PostState { initial, loading, success, error, moderationRejected }

class PostProvider with ChangeNotifier {
  final _servicio = ServicioComunidades();
  
  List<Publicacion> _posts = [];
  List<Publicacion> get posts => _posts;
  
  PostState _state = PostState.initial;
  PostState get state => _state;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> cargarPosts(int comunidadId) async {
    _state = PostState.loading;
    notifyListeners();
    
    try {
      final res = await _servicio.obtenerPublicacionesComunidad(comunidadId);
      if (res.exito) {
        _posts = res.datos ?? [];
        _state = PostState.success;
      } else {
        _errorMessage = res.mensaje;
        _state = PostState.error;
      }
    } catch (e) {
      _errorMessage = 'Error al conectar con Myngo';
      _state = PostState.error;
    }
    notifyListeners();
  }

  Future<bool> crearPost({
    int? comunidadId,
    required String texto,
    dynamic imagenes,
    String? etiquetas,
    void Function(int, int)? alProgresar,
  }) async {
    _state = PostState.loading;
    notifyListeners();

    try {
      final res = await _servicio.crearPublicacion(
        idComunidad: comunidadId,
        texto: texto,
        imagenes: imagenes,
        etiquetas: etiquetas,
        alProgresar: alProgresar,
      );

      if (res.exito) {
        // El backend responde con la publicación creada
        // Pero recordamos que las señales pueden haberla marcado como inválida
        final nueva = res.datos as Publicacion;
        
        if (!nueva.esValidoIa) {
          _state = PostState.moderationRejected;
          _errorMessage = 'Tu publicación infringe las normas de la comunidad (Moderación IA) 🐾';
          notifyListeners();
          return false;
        }

        _posts.insert(0, nueva);
        _state = PostState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.mensaje;
        _state = PostState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al subir el post';
      _state = PostState.error;
      notifyListeners();
      return false;
    }
  }
}
