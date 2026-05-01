/// Modelo que representa un voto emitido por un usuario.
///
/// Los votos pueden estar dirigidos a otros usuarios o a comunidades,
/// asignando una puntuación en estrellas (generalmente de 1 a 5).
class Voto {
  final int id;
  final int votanteId;
  final int? receptorUsuarioId;
  final int? receptorComunidadId;

  /// Puntuación otorgada (rango esperado: 1 a 5).
  final int estrellas;

  final DateTime fechaVoto;

  Voto({
    required this.id,
    required this.votanteId,
    this.receptorUsuarioId,
    this.receptorComunidadId,
    required this.estrellas,
    required this.fechaVoto,
  });

  /// Crea una instancia de [Voto] a partir de un mapa JSON.
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