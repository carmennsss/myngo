import 'dart:html' as html;

/// Implementación de descarga específica para Web usando Blobs.
/// Esto fuerza la descarga incluso si el archivo es de otro dominio (S3),
/// siempre que el servidor permita CORS.
Future<void> descargarArchivoWeb(String url, String nombre) async {
  try {
    // Usamos HttpRequest para obtener el archivo como un Blob
    // Esto permite que el navegador lo trate como un archivo local para la descarga
    final xhr = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'blob',
    );

    final blob = xhr.response as html.Blob;
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: objectUrl)
      ..setAttribute('download', nombre)
      ..style.display = 'none';
    
    html.document.body?.append(anchor);
    anchor.click();
    
    // Limpieza inmediata
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
  } catch (e) {
    // FALLBACK: Si falla el CORS (muy común con S3 si no está configurado),
    // volvemos al comportamiento de abrir en pestaña para que el usuario pueda guardarlo manualmente.
    // Usamos window.open para mayor fiabilidad en Web.
    html.window.open(url, '_blank');
  }
}
