import 'package:flutter/material.dart';

/// Botón con estilo gradiente que integra un indicador de progreso.
/// 
/// Este componente reacciona a un [ValueNotifier] para mostrar un 
/// [CircularProgressIndicator] cuando se inicia una operación asíncrona,
/// deshabilitando las interacciones del usuario automáticamente.
class BotonCarga extends StatelessWidget {
  /// Función que se ejecuta al pulsar el botón.
  final VoidCallback alPresionar;

  /// Escucha los cambios de estado (cargando/no cargando).
  final ValueNotifier<bool> notificadorCargando;

  /// Texto opcional que se muestra en el botón.
  final String? texto;

  const BotonCarga({
    super.key,
    required this.alPresionar,
    required this.notificadorCargando,
    this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notificadorCargando,
      builder: (context, estaCargando, hijo) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: estaCargando ? null : alPresionar,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: estaCargando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        texto ?? 'Iniciar Sesión',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
