import 'package:flutter/material.dart';
import '../../../models/publicacion.dart';
import 'package:intl/intl.dart';

class TarjetaPublicacion extends StatelessWidget {
  final Publicacion publicacion;

  const TarjetaPublicacion({super.key, required this.publicacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Autor e Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.purple.shade50, child: const Icon(Icons.person, color: Color(0xFF6C63FF))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(publicacion.autorNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(DateFormat('dd MMM · HH:mm').format(publicacion.fechaCreacion), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey)),
              ],
            ),
          ),

          // Título y Texto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (publicacion.titulo.isNotEmpty)
                  Text(publicacion.titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2D3142))),
                const SizedBox(height: 8),
                Text(publicacion.contenidoTexto, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Imagen/Multimedia
          if (publicacion.urlArchivoS3.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: publicacion.relacionAspecto > 0 ? publicacion.relacionAspecto : 16 / 9,
                child: Image.network(publicacion.urlArchivoS3, fit: BoxFit.cover),
              ),
            ),

          // Acciones (Likes, Comentarios)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildAction(Icons.favorite_border_rounded, '12', Colors.redAccent),
                const SizedBox(width: 16),
                _buildAction(Icons.chat_bubble_outline_rounded, '4', Colors.blueAccent),
                const Spacer(),
                const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}
