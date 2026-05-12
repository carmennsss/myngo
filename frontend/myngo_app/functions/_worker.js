/**
 * Cloudflare Pages: _worker.js
 * 
 * Se ha simplificado para actuar únicamente como servidor de archivos estáticos,
 * ya que el frontend ahora se comunica directamente con el túnel de Cloudflare.
 */

export default {
  async fetch(request, env) {
    // Servir los archivos estáticos de la App (Assets)
    return env.ASSETS.fetch(request);
  },
};