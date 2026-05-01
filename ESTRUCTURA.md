# Estructura del Proyecto Myngo

Este documento describe la arquitectura y organización de archivos del proyecto Myngo, sirviendo como guía para desarrolladores y mantenimiento futuro.

## 📁 Jerarquía General

```text
myngo/
├── backend/            # Lógica de servidor y API (Django)
├── frontend/           # Aplicación móvil y web (Flutter)
└── myngodb.sql         # Respaldo de la base de datos
```

---

## 🐍 Backend (Django REST Framework)

El backend sigue una arquitectura modular basada en aplicaciones de Django independientes pero comunicadas.

### `backend/myngo_api/`
- **`core/`**: Configuración central del proyecto, ajustes de seguridad, base de datos y middlewares.
- **`apps/`**: Módulos funcionales del sistema.
    - **`usuarios/`**: Gestión de perfiles, autenticación (Token Auth) y reputación.
    - **`comunidades/`**: Lógica de grupos, moderadores, membresías y eventos.
    - **`contenido/`**: Publicaciones, feeds (galería/social), etiquetas y búsqueda.
    - **`mensajeria/`**: Chat en tiempo real mediante WebSockets (Django Channels).
    - **`notificaciones/`**: Sistema de alertas internas y push.
    - **`mejoras/`**: Tienda de puntos y moderación de contenido premiado.

---

## 📱 Frontend (Flutter)

El frontend está estructurado para separar claramente la lógica de comunicación con la API de la interfaz de usuario.

### `frontend/myngo_app/lib/`
- **`services/`**: Capa de comunicación. Contiene servicios estandarizados en español:
    - `ServicioUsuarios`: Autenticación y perfil.
    - `ServicioGaleria`: Gestión de imágenes y multimedia.
    - `ServicioInteraccion`: Likes, comentarios y guardado.
    - `ServicioInicio`: Feeds principales y paginación.
    - `ServicioMensajeria`: Chat y WebSockets.
    - `ServicioNotificaciones`: Gestión de tokens y avisos.
    - `ServicioMejoras`: Tienda y puntos.
    - `ServicioModeracion`: Denuncias y panel de admin.
- **`models/`**: Clases de datos (POJOs) con serialización JSON.
- **`providers/`**: Gestión de estado reactivo (Riverpod/Provider).
- **`screens/`**: Pantallas completas de la aplicación.
- **`widgets/`**: Componentes de interfaz reutilizables.
- **`utils/`**: Configuraciones de entorno y constantes.
- **`router.dart`**: Definición centralizada de rutas (GoRouter).

---

## 🛠️ Estándares de Código

### 1. Nomenclatura
- **Idioma**: Español para todo el dominio de negocio (variables, funciones, clases propias).
- **Excepciones**: Términos técnicos (API, Chat, Widget, Token, Endpoint).

### 2. Documentación
- Se utiliza el formato **Google Style Docstrings**.
- Cada servicio y método público debe describir su propósito, argumentos y posibles errores.

### 3. Comunicación API
- Todas las peticiones deben pasar por el sistema de cabeceras centralizado (`_obtenerCabeceras()`).
- El manejo de errores debe ser uniforme mediante la clase `RespuestaApi<T>`.
- Tiempo de espera (timeout) configurado entre 15s y 40s según la complejidad de la tarea.
