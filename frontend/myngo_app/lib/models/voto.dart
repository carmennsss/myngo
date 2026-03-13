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
      id: json['id'],
      votanteId: json['votante'],
      receptorUsuarioId: json['receptor_usuario'],
      receptorComunidadId: json['receptor_comunidad'],
      estrellas: json['estrellas'] ?? 0,
      fechaVoto: DateTime.parse(json['fecha_voto']),
    );
  }
}