// Cambia la clave del profe sin escribirla en el código.
// Uso (desde la carpeta del proyecto):
//    node herramientas/clave-profe.mjs "tu clave nueva"
// Guarda en web/js/profe.js solo la "huella" SHA-256 de la clave: quien lea el
// código no puede saber cuál es. (Con el multijugador la revisará el servidor.)
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const clave = (process.argv[2] || '').trim();
if (clave.length < 6) {
  console.error('Escribe una clave de al menos 6 caracteres:  node herramientas/clave-profe.mjs "mi clave"');
  process.exit(1);
}
const huella = createHash('sha256').update('roba-un-arduino:' + clave).digest('hex');
const ruta = fileURLToPath(new URL('../web/js/profe.js', import.meta.url));
const s = readFileSync(ruta, 'utf8');
const nuevo = s.replace(/const HUELLA_CLAVE_PROFE = '[0-9a-f]{64}';/, `const HUELLA_CLAVE_PROFE = '${huella}';`);
if (nuevo === s) { console.error('No encontré HUELLA_CLAVE_PROFE en web/js/profe.js'); process.exit(1); }
writeFileSync(ruta, nuevo);
console.log('✅ Clave del profe cambiada. Recuerda guardar (commit) y publicar de nuevo.');
