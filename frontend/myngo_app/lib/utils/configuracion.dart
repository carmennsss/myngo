class Configuracion {
  /// La dirección IP base para todas las peticiones HTTP a la API.
  static const String baseUrl = 'http://107.20.99.104';


  /// La dirección base para las conexiones de WebSockets.
  /// Si usas 'runserver' o 'daphne' en el EC2, el puerto suele ser el 8000.
  static const String wsUrl = 'wss://forget-resulting-slides-momentum.trycloudflare.com/ws'; // Se recomienda WSS para evitar bloqueos
  //static const String wsUrl = 'ws://localhost:8000/ws';

}
