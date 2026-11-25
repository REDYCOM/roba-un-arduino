// =====================================================================
//  LECTOR DE ARCHIVOS .rbxl (formato binario de Roblox)
//  Uso:  node leer-rbxl.mjs "archivo.rbxl" salida.json
//  Saca todas las instancias con sus propiedades (posición, tamaño,
//  color, material, forma...) para poder reconstruir el mapa en la web.
// =====================================================================
import fs from 'node:fs';
import zlib from 'node:zlib';

// ---------- descompresión LZ4 (bloque) ----------
function lz4(src, tam) {
  const out = Buffer.alloc(tam);
  let i = 0, o = 0;
  while (i < src.length) {
    const tok = src[i++];
    let lit = tok >> 4;
    if (lit === 15) { let b; do { b = src[i++]; lit += b; } while (b === 255); }
    src.copy(out, o, i, i + lit); i += lit; o += lit;
    if (i >= src.length) break;
    const off = src[i] | (src[i + 1] << 8); i += 2;
    let len = tok & 15;
    if (len === 15) { let b; do { b = src[i++]; len += b; } while (b === 255); }
    len += 4;
    for (let k = 0; k < len; k++) { out[o] = out[o - off]; o++; }
  }
  return out;
}

class Lector {
  constructor(b) { this.b = b; this.o = 0; }
  u8() { return this.b[this.o++]; }
  u32() { const v = this.b.readUInt32LE(this.o); this.o += 4; return v; }
  i32() { const v = this.b.readInt32LE(this.o); this.o += 4; return v; }
  f32() { const v = this.b.readFloatLE(this.o); this.o += 4; return v; }
  f64() { const v = this.b.readDoubleLE(this.o); this.o += 8; return v; }
  str() { const n = this.u32(); const s = this.b.toString('utf8', this.o, this.o + n); this.o += n; return s; }
  bytes(n) { const s = this.b.subarray(this.o, this.o + n); this.o += n; return s; }
  // n valores de 4 bytes intercalados (big endian por columnas)
  inter32(n) {
    const r = new Uint32Array(n), b = this.b, o = this.o;
    for (let i = 0; i < n; i++) r[i] = ((b[o + i] << 24) | (b[o + n + i] << 16) | (b[o + 2 * n + i] << 8) | b[o + 3 * n + i]) >>> 0;
    this.o += 4 * n;
    return r;
  }
  enteros(n) { return Array.from(this.inter32(n), (v) => (v >>> 1) ^ -(v & 1)); }
  flotantes(n) {
    const dv = new DataView(new ArrayBuffer(4));
    return Array.from(this.inter32(n), (v) => { dv.setUint32(0, ((v >>> 1) | (v << 31)) >>> 0); return dv.getFloat32(0); });
  }
  refs(n) { const v = this.enteros(n); for (let i = 1; i < n; i++) v[i] += v[i - 1]; return v; }
}

// rotaciones "rápidas" de los CFrame (múltiplos de 90°)
const NORMAL = [[1, 0, 0], [0, 1, 0], [0, 0, 1], [-1, 0, 0], [0, -1, 0], [0, 0, -1]];
function rotRapida(id) {
  const a = NORMAL[Math.floor((id - 1) / 6)], b = NORMAL[(id - 1) % 6];
  const c = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
  return [...a, ...b, ...c];
}

function leerValores(L, tipo, n) {
  switch (tipo) {
    case 0x01: return Array.from({ length: n }, () => L.str());
    case 0x02: return Array.from({ length: n }, () => L.u8() !== 0);
    case 0x03: return L.enteros(n);
    case 0x04: return L.flotantes(n);
    case 0x05: return Array.from({ length: n }, () => L.f64());
    case 0x0C: { const r = L.flotantes(n), g = L.flotantes(n), b = L.flotantes(n); return r.map((v, i) => [v, g[i], b[i]]); }
    case 0x0E: { const x = L.flotantes(n), y = L.flotantes(n), z = L.flotantes(n); return x.map((v, i) => [v, y[i], z[i]]); }
    case 0x10: case 0x11: {
      const rots = [];
      for (let i = 0; i < n; i++) {
        const id = L.u8();
        if (id === 0) rots.push(Array.from({ length: 9 }, () => L.f32()));
        else rots.push(rotRapida(id));
      }
      const x = L.flotantes(n), y = L.flotantes(n), z = L.flotantes(n);
      if (tipo === 0x11) L.bytes(n); // OptionalCFrame: banderas
      return rots.map((r, i) => ({ p: [x[i], y[i], z[i]], r }));
    }
    case 0x12: return Array.from(L.inter32(n));
    case 0x13: return L.refs(n);
    case 0x1A: { const r = L.bytes(n), g = L.bytes(n), b = L.bytes(n); return Array.from(r, (v, i) => [v, g[i], b[i]]); }
    case 0x1C: return L.enteros(n); // SharedString: índice
    default: return null; // tipos que no necesitamos
  }
}

export function leerRbxl(ruta) {
  const b = fs.readFileSync(ruta);
  if (b.toString('latin1', 0, 8) !== '<roblox!') throw new Error('No es un archivo .rbxl binario');
  let o = 32;
  const clases = {}, inst = {};
  const padres = {};
  while (o < b.length) {
    const nombre = b.toString('latin1', o, o + 4).replace(/\0/g, '');
    const comp = b.readUInt32LE(o + 4), tam = b.readUInt32LE(o + 8);
    o += 16;
    let datos;
    if (comp === 0) { datos = b.subarray(o, o + tam); o += tam; }
    else {
      const raw = b.subarray(o, o + comp); o += comp;
      datos = raw.readUInt32BE(0) === 0x28b52ffd ? zlib.zstdDecompressSync(raw) : lz4(raw, tam);
    }
    const L = new Lector(datos);
    if (nombre === 'INST') {
      const id = L.u32(), clase = L.str(), fmt = L.u8(), n = L.u32();
      const refs = L.refs(n);
      clases[id] = { clase, refs };
      for (const r of refs) inst[r] = { ref: r, clase, props: {}, hijos: [] };
    } else if (nombre === 'PROP') {
      const id = L.u32(), prop = L.str(), tipo = L.u8();
      const c = clases[id];
      const vals = leerValores(L, tipo, c.refs.length);
      if (vals) c.refs.forEach((r, i) => { inst[r].props[prop] = vals[i]; });
    } else if (nombre === 'PRNT') {
      L.u8(); const n = L.u32();
      const hijos = L.refs(n), ps = L.refs(n);
      hijos.forEach((h, i) => { padres[h] = ps[i]; });
    } else if (nombre === 'END') break;
  }
  for (const [h, p] of Object.entries(padres)) {
    inst[h].padre = p;
    if (inst[p]) inst[p].hijos.push(Number(h));
  }
  return inst;
}

// ---------- uso desde la consola ----------
if (process.argv[1] && process.argv[1].endsWith('leer-rbxl.mjs')) {
  const [, , entrada, salida] = process.argv;
  const inst = leerRbxl(entrada);
  if (salida) fs.writeFileSync(salida, JSON.stringify(inst));
  const porClase = {};
  for (const i of Object.values(inst)) porClase[i.clase] = (porClase[i.clase] || 0) + 1;
  console.log(Object.entries(porClase).sort((a, b) => b[1] - a[1]).map(([c, n]) => `${c}: ${n}`).join('\n'));
}
