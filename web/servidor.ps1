# Servidor local mínimo para probar el juego (no necesita instalar nada)
# Uso:  powershell -ExecutionPolicy Bypass -File servidor.ps1   y abrir http://localhost:8080
param([int]$Puerto = 8080)
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$tipos = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8';
            '.png'='image/png'; '.jpg'='image/jpeg'; '.svg'='image/svg+xml'; '.json'='application/json'; '.ico'='image/x-icon'; '.glb'='model/gltf-binary' }
$http = New-Object System.Net.HttpListener
$http.Prefixes.Add("http://localhost:$Puerto/")
$http.Start()
Write-Host "Juego en http://localhost:$Puerto  (Ctrl+C para cerrar)"
while ($http.IsListening) {
  $ctx = $http.GetContext()
  $ruta = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  if ($ruta -eq '') { $ruta = 'index.html' }
  $archivo = [IO.Path]::GetFullPath((Join-Path $raiz $ruta))
  $res = $ctx.Response
  $res.Headers.Add('Cache-Control', 'no-store')
  if ($archivo.StartsWith($raiz) -and (Test-Path $archivo -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($archivo)
    $ext = [IO.Path]::GetExtension($archivo).ToLower()
    $res.ContentType = if ($tipos[$ext]) { $tipos[$ext] } else { 'application/octet-stream' }
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else { $res.StatusCode = 404 }
  $res.Close()
}
