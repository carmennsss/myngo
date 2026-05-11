/**
 * Cloudflare Pages: Advanced Mode Worker
 * Maneja Proxy HTTP (/api) y Proxy WebSocket (/ws)
 * 
 * Este archivo unifica la lógica de proxy para evitar errores de Mixed Content
 * y permitir conexiones WebSocket seguras (wss) hacia un backend inseguro (ws).
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const BACKEND_IP = "107.20.99.104";

    // --- 1. MANEJO DE WEBSOCKETS (/ws) ---
    // Detectamos si la ruta es /ws y si el cliente quiere mejorar la conexión
    if (url.pathname.startsWith("/ws")) {
      const upgradeHeader = request.headers.get("Upgrade");
      if (!upgradeHeader || upgradeHeader.toLowerCase() !== "websocket") {
        return new Response("Expected Upgrade: websocket", { status: 426 });
      }

      // Definimos la URL del backend real (EC2)
      // Nota: Usamos ws:// porque el backend no tiene SSL
      const targetWsUrl = `ws://${BACKEND_IP}${url.pathname}${url.search}`;
      
      try {
        // Realizamos el fetch al backend solicitando el upgrade
        const backendRes = await fetch(targetWsUrl, {
          headers: request.headers,
          method: "GET",
        });

        // El backend debe responder con 101 Switching Protocols
        if (backendRes.status !== 101) {
          const errorText = await backendRes.text();
          return new Response("Backend failed to upgrade: " + errorText, { status: 502 });
        }

        // Obtenemos el socket del lado del backend
        const serverSocket = backendRes.webSocket;
        if (!serverSocket) {
          return new Response("No server socket found", { status: 502 });
        }

        // Creamos un par de sockets para el lado del cliente (Navegador <-> Worker)
        const [clientSide, workerSide] = new WebSocketPair();

        // Conectamos el Worker con el Backend de forma bidireccional
        handleSession(workerSide, serverSocket);

        // Devolvemos el socket del lado del cliente al navegador
        return new Response(null, {
          status: 101,
          webSocket: clientSide,
        });
      } catch (err) {
        return new Response("WebSocket Proxy Error: " + err.message, { status: 500 });
      }
    }

    // --- 2. MANEJO DE API HTTP (/api/*) ---
    // Mantenemos la funcionalidad de proxy para peticiones REST normales
    if (url.pathname.startsWith("/api/")) {
      // Extraemos la ruta después de /api/ (ej: /api/usuarios/login -> usuarios/login)
      const apiPath = url.pathname.replace("/api/", "");
      const backendUrl = `http://${BACKEND_IP}/${apiPath}${url.search}`;
      
      // Clonamos la petición original pero dirigida al backend
      const newRequest = new Request(backendUrl, {
        method: request.method,
        headers: request.headers,
        body: request.method !== 'GET' && request.method !== 'HEAD' ? await request.blob() : null,
        redirect: "manual",
      });

      try {
        const response = await fetch(newRequest);
        const newResponse = new Response(response.body, response);
        // Aseguramos CORS para evitar problemas de origen
        newResponse.headers.set("Access-Control-Allow-Origin", "*");
        newResponse.headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        return newResponse;
      } catch (e) {
        return new Response("API Proxy Error: " + e.message, { status: 502 });
      }
    }

    // --- 3. SERVIR FRONTEND (Fallback) ---
    // Si la ruta no es /api ni /ws, servimos los archivos estáticos del proyecto de Pages
    return env.ASSETS.fetch(request);
  },
};

/**
 * Gestiona el reenvío de mensajes y eventos entre el cliente y el backend.
 */
function handleSession(workerSocket, serverSocket) {
  // Activamos ambos sockets
  workerSocket.accept();
  serverSocket.accept();

  // Cliente (Browser) -> Backend (EC2)
  workerSocket.addEventListener("message", (event) => {
    try {
      serverSocket.send(event.data);
    } catch (e) {
      console.error("Error sending to server:", e);
    }
  });

  // Backend (EC2) -> Cliente (Browser)
  serverSocket.addEventListener("message", (event) => {
    try {
      workerSocket.send(event.data);
    } catch (e) {
      console.error("Error sending to client:", e);
    }
  });

  // Manejo de cierres sincronizados
  workerSocket.addEventListener("close", (event) => {
    serverSocket.close(event.code, event.reason);
  });
  serverSocket.addEventListener("close", (event) => {
    workerSocket.close(event.code, event.reason);
  });

  // Manejo de errores
  const errorHandler = (msg) => {
    console.error(msg);
    workerSocket.close(1011, "Proxy Error");
    serverSocket.close(1011, "Proxy Error");
  };

  workerSocket.addEventListener("error", () => errorHandler("Worker Socket Error"));
  serverSocket.addEventListener("error", () => errorHandler("Server Socket Error"));
}
