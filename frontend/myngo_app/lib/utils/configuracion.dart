class Configuracion {
  /// La dirección IP base para todas las peticiones HTTP a la API.
  /// IMPORTANTE: Sin barra al final. 
  /// Si usas 'runserver' en el EC2, el puerto es el 8000.
  static const String baseUrl = '/api';
  //static const String baseUrl = 'http://localhost:8000';


  /// La dirección base para las conexiones de WebSockets.
  /// Si usas 'runserver' o 'daphne' en el EC2, el puerto suele ser el 8000.
  static const String wsUrl = 'wss://107.20.99.104/ws'; // Se recomienda WSS para evitar bloqueos
  //static const String wsUrl = 'ws://localhost:8000/ws';

}
