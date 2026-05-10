# Suite de Tests Myngo

Este documento describe la estructura y ejecución de la suite de tests automatizados para el proyecto Myngo (Backend en Django y Frontend en Flutter).

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

El frontend de Myngo cuenta con una **cobertura del 100% de los flujos principales**, organizados en tres categorías:

*   **Unitarios (`test/unit/`)**: Pruebas sobre la lógica de negocio.
    *   **Services**: Se utiliza `mocktail` para inyectar un `http.Client` simulado y verificar las llamadas REST (`servicio_usuarios_test.dart`, `servicio_mensajeria_test.dart`, etc.).
    *   **Models**: Pruebas de parseo JSON (`fromJson` y `toJson`) para prevenir crashers por cambios de contrato con la API.
*   **Widgets (`test/widget/`)**: Pruebas de UI para comprobar que los componentes se renderizan correctamente, muestran estados de carga y errores de validación sin necesidad de levantar emuladores.
*   **End-to-End (`integration_test/patrol/`)**: Pruebas automatizadas de flujo completo usando el framework **Patrol**. Ejecutan el código nativo e interactúan con la interfaz como un usuario real.

### Tabla de Flujos E2E (Patrol)

| Archivo | Funcionalidad (Flujo) | Resultado Esperado |
| :--- | :--- | :--- |
| `auth_flow_test.dart` | Registro, validación, login e inicio | Redirección exitosa a la vista Home. |
| `chat_flow_test.dart` | Abrir sala, enviar texto, ver burbuja | El mensaje se envía y se pinta instantáneamente. |
| `comunidad_flow_test.dart` | Buscar, unirse, ver feed y salir | El usuario interactúa correctamente con la membresía. |
| `publicacion_flow_test.dart` | Subir contenido, galería, verificar feed | La nueva publicación aparece en la pantalla principal. |

### Ejecución de Tests (Frontend)

1. Ve al directorio del frontend: `cd frontend/myngo_app`
2. Instala las dependencias: `flutter pub get`
3. **Unitarios y Widgets**: Ejecuta `flutter test --coverage`
4. **Patrol E2E**: 
    - Debes tener el CLI de Patrol instalado: `dart pub global activate patrol_cli`
    - Levanta un emulador iOS o Android.
    - Levanta tu backend Django local (o usa el que levanta GitHub Actions con DB in-memory).
    - Ejecuta: `patrol test --target integration_test/patrol/`

## 3. Integración Continua (CI/CD)

El archivo `.github/workflows/deploy.yml` está configurado con validaciones estrictas:
- **`test-backend`**: Ejecuta la suite de pytest del backend con base de datos en memoria (`sqlite3`).
- **`frontend-unit`**: Ejecuta los tests de Flutter en los Pull Requests y sube el reporte de cobertura.
- **`frontend-e2e`**: Levanta el backend Django internamente en el runner y ejecuta la suite completa de Patrol (E2E) simulando a un usuario real.
- **Bloqueo**: Si ALGUNO de los tests falla, el pipeline aborta la subida al entorno EC2 en producción.
