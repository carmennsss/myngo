// lib/models/voto.dart

class Voto {
  final int id;
  final int votanteId;
  final int? receptorUsuarioId;
  final int? receptorComunidadId;
  final int estrellas; // Debe estar entre 0 y 5 
  final DateTime fechaVoto;

  Voto({
    required this.id,
    required this.votanteId,
    this.receptorUsuarioId,
    this.receptorComunidadId,
    required this.estrellas,
    required this.fechaVoto,
  });

  factory Voto.fromJson(Map<String, dynamic> json) {
    return Voto(
      id: json['id'] ?? 0,
      votanteId: json['votante'] ?? 0,
      receptorUsuarioId: json['receptor_usuario'] as int?,
      receptorComunidadId: json['receptor_comunidad'] as int?,
      estrellas: (json['estrellas'] ?? 0).toInt(),
      fechaVoto: json['fecha_voto'] != null 
          ? DateTime.parse(json['fecha_voto']) 
          : DateTime.now(),
    );
  }
}