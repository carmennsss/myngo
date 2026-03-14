/// Modelo genérico para representar las respuestas estandarizadas enviadas por el backend.
///
/// La clase está parametrizada con [T] para permitir que los datos devueltos 
/// sean de cualquier tipo, facilitando su reutilización en diferentes servicios.
class RespuestaApi<T> {
  /// Indica si la operación en el servidor fue exitosa.
  final bool exito;

  /// Mensaje descriptivo del resultado de la operación (ej. "Login exitoso").
  final String mensaje;

  /// Datos resultantes de la operación, opcionales.
  final T? datos;

  /// Detalles sobre errores ocurridos, comúnmente un Map con campos y sus errores.
  final dynamic errores;

  /// Constructor básico para crear una instancia de [RespuestaApi].
  RespuestaApi({
    required this.exito,
    required this.mensaje,
    this.datos,
    this.errores,
  });

  /// Factory method para deserializar una respuesta JSON del backend Django.
  ///
  /// El parámetro opcional [transformador] permite convertir el Map de 'datos'
  /// en una instancia de un modelo específico (ej. convertir un Map en un objeto Usuario).
  factory RespuestaApi.fromJson(Map<String, dynamic> json, {T Function(Map<String, dynamic>)? transformador}) {
    return RespuestaApi(
      exito: json['exito'] ?? false,
      mensaje: json['mensaje'] ?? '',
      datos: (json['datos'] != null && transformador != null) 
          ? transformador(json['datos'] as Map<String, dynamic>) 
          : json['datos'] as T?,
      errores: json['errores'],
    );
  }
}
