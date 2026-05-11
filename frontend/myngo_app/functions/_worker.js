/**
 * Cloudflare Pages: Advanced Mode Worker (Versión Final Blindada)
 * 
 * Cambios realizados:
 * 1. Uso de env.BACKEND_IP para flexibilidad.
 * 2. Inclusión de X-CSRFToken y cabeceras de origen en la lista blanca.
 * 3. Filtrado estricto en WebSockets para evitar rechazos del servidor.
 * 4. Forzado de cabecera 'Host' a la IP del backend.
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // Priorizamos la variable de entorno configurada en el panel de Cloudflare Pages
    const BACKEND_IP = env.BACKEND_IP || "107.20.99.104";

    // --- 1. MANEJO DE CORS PREFLIGHT (OPTIONS) ---
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": url.origin,
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, X-CSRFToken, X-Requested-With, Accept, Origin, Referer",
          "Access-Control-Allow-Credentials": "true",
          "Max-Age": "86400",
        },
      });
    }

    // --- 2. MANEJO DE WEBSOCKETS (/ws) ---
    if (url.pathname.startsWith("/ws")) {
      const upgradeHeader = request.headers.get("Upgrade");
      if (!upgradeHeader || upgradeHeader.toLowerCase() !== "websocket") {
        return new Response("Expected Upgrade: websocket", { status: 426 });
      }

      const targetWsUrl = `ws://${BACKEND_IP}${url.pathname}${url.search}`;
      
      try {
        const [clientSide, workerSide] = new WebSocketPair();

        // Creamos cabeceras limpias para el WebSocket
        const wsHeaders = new Headers();
        wsHeaders.set("Upgrade", "websocket");
        wsHeaders.set("Connection", "Upgrade");
        wsHeaders.set("Host", BACKEND_IP); // Evita 403 en servidores con virtual hosts
        
        const auth = request.headers.get("Authorization");
        if (auth) wsHeaders.set("Authorization", auth);

        const backendRes = await fetch(targetWsUrl, {
          headers: wsHeaders,
          method: "GET",
        });

        if (backendRes.status !== 101) {
          return new Response("Backend WebSocket failed: " + backendRes.status, { status: 502 });
        }

        const serverSocket = backendRes.webSocket;
        if (!serverSocket) return new Response("No socket found", { status: 502 });

        handleSession(workerSide, serverSocket);

        return new Response(null, {
          status: 101,
          webSocket: clientSide,
        });
      } catch (err) {
        return new Response(JSON.stringify({ error: "WS Proxy Error", details: err.message }), { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        });
      }
    }

    // --- 3. MANEJO DE API HTTP (/api/*) ---
    if (url.pathname.startsWith("/api/")) {
      const apiPath = url.pathname.replace("/api/", "");
      const backendUrl = `http://${BACKEND_IP}/${apiPath}${url.search}`;

      // Lista blanca de cabeceras permitidas (incluyendo seguridad de Django/Laravel)
      const cleanHeaders = new Headers();
      const allowedHeaders = [
        "content-type", 
        "authorization", 
        "accept", 
        "user-agent", 
        "cookie", 
        "x-csrftoken", 
        "x-requested-with", 
        "referer", 
        "origin"
      ];
      
      for (let [key, value] of request.headers.entries()) {
        if (allowedHeaders.includes(key.toLowerCase())) {
          cleanHeaders.set(key, value);
        }
      }

      // Forzamos el Host a la IP para que el backend reconozca la petición
      cleanHeaders.set("Host", BACKEND_IP);

      try {
        const proxyRequest = new Request(backendUrl, {
          method: request.method,
          headers: cleanHeaders,
          body: request.method !== "GET" && request.method !== "HEAD" ? request.body : null,
          redirect: "manual",
        });

        const response = await fetch(proxyRequest);
        
        // Clonamos la respuesta para inyectar cabeceras CORS
        const newResponse = new Response(response.body, response);
        newResponse.headers.set("Access-Control-Allow-Origin", url.origin);
        newResponse.headers.set("Access-Control-Allow-Credentials", "true");
        
        return newResponse;
      } catch (e) {
        return new Response(
          JSON.stringify({ 
            error: true, 
            message: "Proxy Connection Error", 
            details: e.message 
          }), 
          { 
            status: 502, 
            headers: { "Content-Type": "application/json" } 
          }
        );
      }
    }

    // --- 4. SERVIR FRONTEND (Fallback) ---
    return env.ASSETS.fetch(request);
  },
};

/**
 * Gestiona el reenvío de mensajes y eventos entre el cliente y el backend.
 */
function handleSession(workerSocket, serverSocket) {
  workerSocket.accept();
  serverSocket.accept();

  workerSocket.addEventListener("message", (ev) => serverSocket.send(ev.data));
  serverSocket.addEventListener("message", (ev) => workerSocket.send(ev.data));

  const closePair = (evt) => {
    workerSocket.close(evt.code || 1000, evt.reason || "");
    serverSocket.close(evt.code || 1000, evt.reason || "");
  };

  workerSocket.addEventListener("close", closePair);
  serverSocket.addEventListener("close", closePair);
  
  const errorHandler = (msg) => {
    console.error(msg);
    workerSocket.close(1011, "Proxy Error");
    serverSocket.close(1011, "Proxy Error");
  };

  workerSocket.addEventListener("error", () => errorHandler("Worker Socket Error"));
  serverSocket.addEventListener("error", () => errorHandler("Server Socket Error"));
}
