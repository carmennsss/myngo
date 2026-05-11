export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // --- Configuración: usa el dominio nip.io (o tu dominio propio) ---
    const BACKEND_HOST = env.BACKEND_HOST || "api.107-20-99-104.nip.io";
    const BACKEND_IP_FALLBACK = env.BACKEND_IP || "107.20.99.104"; // solo para Host header si necesitas

    // --- 1. CORS Preflight ---
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": url.origin,
          "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, X-CSRFToken, X-Requested-With, Accept, Origin, Referer, Cookie",
          "Access-Control-Allow-Credentials": "true",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    // --- 2. WebSocket proxy ---
    if (url.pathname.startsWith("/ws")) {
      const upgradeHeader = request.headers.get("Upgrade");
      if (!upgradeHeader || upgradeHeader.toLowerCase() !== "websocket") {
        return new Response("Expected Upgrade: websocket", { status: 426 });
      }

      // Usar dominio, no IP
      const targetWsUrl = `ws://${BACKEND_HOST}${url.pathname}${url.search}`;
      try {
        const [clientSide, workerSide] = new WebSocketPair();
        const wsHeaders = new Headers();
        wsHeaders.set("Upgrade", "websocket");
        wsHeaders.set("Connection", "Upgrade");
        wsHeaders.set("Host", BACKEND_HOST);
        const auth = request.headers.get("Authorization");
        if (auth) wsHeaders.set("Authorization", auth);

        const backendRes = await fetch(targetWsUrl, { headers: wsHeaders });
        if (backendRes.status !== 101) {
          return new Response("Backend WS upgrade failed", { status: 502 });
        }
        const serverSocket = backendRes.webSocket;
        if (!serverSocket) return new Response("No socket", { status: 502 });

        handleSession(workerSide, serverSocket);
        return new Response(null, { status: 101, webSocket: clientSide });
      } catch (err) {
        return new Response(JSON.stringify({ error: "WS proxy error", details: err.message }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // --- 3. API HTTP proxy (/api/*) ---
    if (url.pathname.startsWith("/api/")) {
      const apiPath = url.pathname.replace("/api/", "");
      const backendUrl = `http://${BACKEND_HOST}/${apiPath}${url.search}`;

      // Filtro de cabeceras (igual que antes)
      const cleanHeaders = new Headers();
      const allowedHeaders = [
        "content-type", "authorization", "accept", "user-agent",
        "cookie", "x-csrftoken", "x-requested-with", "referer", "origin"
      ];
      for (let [key, value] of request.headers.entries()) {
        if (allowedHeaders.includes(key.toLowerCase())) {
          cleanHeaders.set(key, value);
        }
      }
      // Host: usar BACKEND_HOST (dominio) – así el backend puede usar virtual hosts si quiere
      cleanHeaders.set("Host", BACKEND_HOST);

      try {
        const proxyRequest = new Request(backendUrl, {
          method: request.method,
          headers: cleanHeaders,
          body: request.method !== "GET" && request.method !== "HEAD" ? request.body : null,
          redirect: "manual",
        });

        const response = await fetch(proxyRequest);

        // Si la respuesta del backend es un error (>=400), devolvemos JSON para no romper Flutter
        if (response.status >= 400) {
          const errorText = await response.text();
          console.error("Backend error:", errorText);
          return new Response(JSON.stringify({
            error: true,
            status: response.status,
            message: errorText.substring(0, 200) // limitamos longitud
          }), {
            status: response.status,
            headers: { "Content-Type": "application/json" },
          });
        }

        // Respuesta OK → clonar y añadir CORS
        const newResponse = new Response(response.body, response);
        newResponse.headers.set("Access-Control-Allow-Origin", url.origin);
        newResponse.headers.set("Access-Control-Allow-Credentials", "true");
        return newResponse;
      } catch (e) {
        return new Response(JSON.stringify({ error: true, message: "Proxy Connection Error", details: e.message }), {
          status: 502,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    // --- 4. Servir el frontend estático ---
    return env.ASSETS.fetch(request);
  },
};

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