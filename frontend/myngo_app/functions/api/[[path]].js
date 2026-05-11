/**
 * Cloudflare Pages Function: Reverse Proxy
 * Forwards requests from /api/* (HTTPS) to AWS EC2 (HTTP)
 * Resolves "Mixed Content" errors in the browser.
 */

export async function onRequest(context) {
  const { request, params } = context;
  const url = new URL(request.url);
  
  // 1. Extract the path after /api/
  // If params.path is an array (from [[path]].js), we join it.
  const apiPath = Array.isArray(params.path) ? params.path.join('/') : params.path;
  
  // 2. Define the backend target (AWS EC2)
  const BACKEND_IP = "107.20.99.104";
  const backendUrl = `http://${BACKEND_IP}/${apiPath}${url.search}`;
  
  // 3. Prepare the headers
  // We clone the headers and modify them if necessary
  const headers = new Headers(request.headers);
  headers.set("Host", BACKEND_IP);
  
  // 4. Create the proxied request
  const proxyRequest = new Request(backendUrl, {
    method: request.method,
    headers: headers,
    body: request.method !== 'GET' && request.method !== 'HEAD' ? await request.blob() : null,
    redirect: 'manual'
  });

  try {
    // 5. Fetch from backend
    const response = await fetch(proxyRequest);
    
    // 6. Handle the response
    // We create a new response to ensure we can modify headers (like CORS)
    const newResponse = new Response(response.body, response);
    
    // Add CORS headers to be safe (Cloudflare might add them, but this ensures it)
    newResponse.headers.set('Access-Control-Allow-Origin', '*');
    newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    return newResponse;
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: "Proxy Error", 
      message: error.message,
      target: backendUrl 
    }), { 
      status: 502,
      headers: { "Content-Type": "application/json" }
    });
  }
}
