# Suite de Tests Myngo

Este documento describe la estructura y ejecución de la suite de tests automatizados para el proyecto Myngo (Backend y Frontend).

## 1. Backend (Django)

Los tests del backend están ubicados en `backend/myngo_api/tests/` y utilizan `pytest`, `pytest-django`, y `factory_boy`. Se agrupan por app:

*   **usuarios**: Tests de modelos de usuario, perfiles, seguimientos, y endpoints de autenticación y gestión de perfiles.
*   **contenido**: Tests de modelos de publicaciones, imágenes, colecciones y sus endpoints correspondientes.
*   **mensajeria**: Tests de salas de chat, mensajes y WebSockets con Django Channels.
*   **comunidades**: Tests de gestión de comunidades y membresías.
*   **mejoras**: Tests de la tienda de personalización, votos y peticiones de mejoras.
*   **notificaciones**: Tests de generación y lectura de notificaciones push y en la app.

### Tabla de Tests (Ejemplos Principales)

| Nombre del Test | Funcionalidad | Tipo | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| `test_login_invalid_credentials` | Autenticación | API | 401 Unauthorized |
| `test_crear_sala` | Salas de chat | API | 201 Created |
| `test_chat_consumer_message` | WebSockets de Chat | Integración | Conexión y envío de mensaje exitosos |
| `test_marcar_todas_leidas` | Notificaciones | API | 200 OK y actualización de DB |

### Ejecución de Tests (Backend)

1. Activa el entorno virtual: `.\venv\Scripts\activate` (Windows) o `source venv/bin/activate` (Linux/Mac).
2. Instala dependencias: `pip install -r requirements.txt`.
3. Ejecuta los tests: `pytest` (en la carpeta `backend/myngo_api`).
4. Para ver la cobertura: `pytest --cov=. --cov-report=html`. La cobertura esperada es > 80% en los módulos principales.

## 2. Frontend (Flutter)

Los tests del frontend están ubicados en `frontend/myngo_app/test/` y se dividen en tres categorías:

*   **unit**: Pruebas unitarias para servicios (`ServicioUsuario`, `ServicioMensajeria`, etc.). Utilizan `mocktail` para mockear respuestas HTTP.
*   **widget**: Pruebas de UI para comprobar que los componentes se renderizan correctamente (ej: `login_screen_test.dart`).
*   **integration**: Pruebas End-to-End simulando la interacción completa del usuario usando `integration_test`.

### Ejecución de Tests (Frontend)

1. Ve al directorio del frontend: `cd frontend/myngo_app`
2. Ejecuta los tests unitarios y de widgets: `flutter test`
3. Ejecuta los tests de integración: `flutter test integration_test/app_test.dart` (requiere un dispositivo o emulador corriendo).

## 3. Integración Continua (CI/CD)

El archivo `.github/workflows/deploy.yml` ha sido actualizado para incluir un job que ejecuta la suite de tests del backend antes de desplegar. Si los tests fallan, el despliegue a producción se bloquea.
Además, existe `.github/workflows/deploy_frontend.yml` que construye el frontend Flutter y lo despliega a Cloudflare Pages en cada push a main.
