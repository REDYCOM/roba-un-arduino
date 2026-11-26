// =====================================================================
//  CONVERTIDOR DE MODELOS DE TINKERCAD → web/datos/componentes.js
//  Lee .obj (los colores vienen en "usemtl color_NNNNNN") y .glb (colores
//  por vértice) y los deja centrados, en milímetros, con índices y colores.
//  Uso:  node herramientas/modelos/convertir.mjs "D:\ROBA UN ARDUINO\modelos"
// =====================================================================
import fs from 'node:fs';
import path from 'node:path';

const carpeta = process.argv[2];
// nombre en el juego → archivo, y qué eje del archivo apunta hacia arriba
const LISTA = {
  arduino:   { archivo: 'arduino.obj', arriba: 'z' },
  l298n:     { archivo: 'puente h l298n.obj', arriba: 'z' },
  motor:     { archivo: 'motor.obj', arriba: 'z' },
  llanta:    { archivo: 'llanta.obj', arriba: 'z' },
  portapila: { archivo: 'portapila.obj', arriba: 'z' },
  chasis:    { archivo: 'chasis robot.glb', arriba: 'z' },
  pilas:     { archivo: 'pilas.glb', arriba: 'z' },
  sensor:    { archivo: 'sensor ultrasonico.glb', arriba: 'z' },
};

function leerObj(texto) {
  const v = [], pos = [], colr = [], idx = [], mapa = new Map();
  let color = [0.8, 0.8, 0.8];
  for (const linea of texto.split(/\r?\n/)) {
    if (linea.startsWith('v ')) { const p = linea.split(/\s+/); v.push([+p[1], +p[2], +p[3]]); }
    else if (linea.startsWith('usemtl')) {
      const n = parseInt(linea.split('color_')[1], 10);
      color = isNaN(n) ? [0.8, 0.8, 0.8] : [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
    } else if (linea.startsWith('f ')) {
      const ids = linea.trim().split(/\s+/).slice(1).map((t) => parseInt(t.split('/')[0], 10) - 1);
      const vert = ids.map((i) => {
        const clave = i + '|' + color.join(',');
        if (!mapa.has(clave)) { mapa.set(clave, pos.length / 3); pos.push(...v[i]); colr.push(...color); }
        return mapa.get(clave);
      });
      for (let k = 1; k < vert.length - 1; k++) idx.push(vert[0], vert[k], vert[k + 1]);
    }
  }
  return { pos, colr, idx };
}

function leerGlb(buf) {
  const lenJ = buf.readUInt32LE(12);
  const j = JSON.parse(buf.toString('utf8', 20, 20 + lenJ));
  const bin = buf.subarray(20 + lenJ + 8);
  const leer = (iAcc) => {
    const a = j.accessors[iAcc], bv = j.bufferViews[a.bufferView];
    const n = { SCALAR: 1, VEC3: 3, VEC4: 4 }[a.type];
    const off = (bv.byteOffset || 0) + (a.byteOffset || 0), stride = bv.byteStride || 0;
    const out = [];
    const tam = { 5126: 4, 5123: 2, 5125: 4, 5121: 1 }[a.componentType];
    for (let i = 0; i < a.count; i++) {
      const base = off + i * (stride || tam * n);
      for (let k = 0; k < n; k++) {
        const o = base + k * tam;
        let x;
        switch (a.componentType) {
          case 5126: x = bin.readFloatLE(o); break;
          case 5123: x = bin.readUInt16LE(o); if (a.normalized) x /= 65535; break;
          case 5125: x = bin.readUInt32LE(o); break;
          case 5121: x = bin[o]; if (a.normalized) x /= 255; break;
        }
        out.push(x);
      }
    }
    return { datos: out, n };
  };
  const pos = [], colr = [], idx = [];
  for (const m of j.meshes) for (const p of m.primitives) {
    const base = pos.length / 3;
    const P = leer(p.attributes.POSITION).datos; pos.push(...P);
    if (p.attributes.COLOR_0 !== undefined) {
      const c = leer(p.attributes.COLOR_0);
      for (let i = 0; i < c.datos.length / c.n; i++) colr.push(c.datos[i * c.n], c.datos[i * c.n + 1], c.datos[i * c.n + 2]);
    } else for (let i = 0; i < P.length / 3; i++) colr.push(0.8, 0.8, 0.8);
    if (p.indices !== undefined) idx.push(...leer(p.indices).datos.map((i) => i + base));
    else for (let i = 0; i < P.length / 3; i++) idx.push(base + i);
  }
  return { pos, colr, idx };
}

const salida = {};
for (const [nombre, cfg] of Object.entries(LISTA)) {
  const ruta = path.join(carpeta, cfg.archivo);
  const m = cfg.archivo.endsWith('.obj') ? leerObj(fs.readFileSync(ruta, 'utf8')) : leerGlb(fs.readFileSync(ruta));
  // Tinkercad usa Z hacia arriba; en el juego Y es arriba: (x, y, z) → (x, z, -y)
  if (cfg.arriba === 'z') for (let i = 0; i < m.pos.length; i += 3) { const y = m.pos[i + 1]; m.pos[i + 1] = m.pos[i + 2]; m.pos[i + 2] = -y; }
  // centrar en X/Z y apoyar en el suelo (y = 0)
  const mn = [Infinity, Infinity, Infinity], mx = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < m.pos.length; i += 3) for (let k = 0; k < 3; k++) { mn[k] = Math.min(mn[k], m.pos[i + k]); mx[k] = Math.max(mx[k], m.pos[i + k]); }
  const c = [(mn[0] + mx[0]) / 2, mn[1], (mn[2] + mx[2]) / 2];
  const tam = [mx[0] - mn[0], mx[1] - mn[1], mx[2] - mn[2]];
  // posiciones cuantizadas a 16 bits dentro de la caja (suficiente precisión y pesa la mitad)
  const q = new Int16Array(m.pos.length);
  for (let i = 0; i < m.pos.length; i += 3) for (let k = 0; k < 3; k++) {
    const t = tam[k] || 1;
    q[i + k] = Math.round(((m.pos[i + k] - c[k]) / t) * 32767); // x,z en [-0.5, 0.5]; y en [0, 1]
  }
  const col = Uint8Array.from(m.colr.map((x) => Math.round(Math.max(0, Math.min(1, x)) * 255)));
  const nV = m.pos.length / 3;
  const ind = nV < 65536 ? Uint16Array.from(m.idx) : Uint32Array.from(m.idx);
  salida[nombre] = {
    tam: tam.map((x) => +x.toFixed(3)), v: nV, t: m.idx.length / 3,
    pos: Buffer.from(q.buffer).toString('base64'),
    col: Buffer.from(col.buffer).toString('base64'),
    idx: Buffer.from(ind.buffer).toString('base64'), idx32: !(ind instanceof Uint16Array),
  };
  console.log(nombre.padEnd(10), 'tamaño', tam.map((x) => x.toFixed(1)).join(' x ').padEnd(24), 'vértices', String(nV).padStart(6), 'triángulos', m.idx.length / 3);
}
const destino = path.resolve(import.meta.dirname, '../../web/datos/componentes.js');
fs.writeFileSync(destino, '// Generado por herramientas/modelos/convertir.mjs (modelos de Tinkercad) - no editar a mano\nwindow.DATOS_COMPONENTES = ' + JSON.stringify(salida) + ';\n');
console.log('→', destino, (fs.statSync(destino).size / 1024).toFixed(0) + ' KB');
