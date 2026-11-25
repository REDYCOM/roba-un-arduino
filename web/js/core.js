// =====================================================================
//  NÚCLEO: estado global, utilidades, entrada y colisiones
// =====================================================================
const G = (window.G = {
  t: 0, dt: 0,
  scene: null, camera: null, renderer: null, composer: null,
  estado: 'menu',          // menu | jugando | pausa | muerto
  anim: [],                // funciones (dt, t) que se llaman cada cuadro
  cajas: [],               // colisionadores AABB {min, max, solido, sinBala}
  pads: [],                // trampolines {x, z, r, y}
  calidad: 1,              // 1 alta, 0 baja
});

const V3 = (x = 0, y = 0, z = 0) => new THREE.Vector3(x, y, z);
const rand = (a, b) => a + Math.random() * (b - a);
const randi = (a, b) => Math.floor(rand(a, b + 1));
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const damp = (a, b, l, dt) => lerp(a, b, 1 - Math.exp(-l * dt));
const smooth = (e0, e1, x) => { const t = clamp((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t); };
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const col = (c) => new THREE.Color(c);
const TAU = Math.PI * 2;

// Ruido de valor 2D (rápido y suficiente para el terreno)
function hash2(x, y) {
  const s = Math.sin(x * 127.1 + y * 311.7) * 43758.5453;
  return s - Math.floor(s);
}
function ruido(x, y) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const xf = x - xi, yf = y - yi;
  const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  const a = hash2(xi, yi), b = hash2(xi + 1, yi), c = hash2(xi, yi + 1), d = hash2(xi + 1, yi + 1);
  return lerp(lerp(a, b, u), lerp(c, d, u), v);
}
function fbm(x, y, oct = 4) {
  let s = 0, a = 0.5, f = 1;
  for (let i = 0; i < oct; i++) { s += a * ruido(x * f, y * f); f *= 2; a *= 0.5; }
  return s;
}
function distSeg(px, pz, ax, az, bx, bz) {
  const dx = bx - ax, dz = bz - az;
  const t = clamp(((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz), 0, 1);
  return Math.hypot(px - (ax + dx * t), pz - (az + dz * t));
}

// ---------------------------------------------------------------------
//  Entrada
// ---------------------------------------------------------------------
const Input = {
  teclas: {}, presionadas: {}, mouseAbajo: false, clic: false, dx: 0, dy: 0, rueda: 0, bloqueado: false,
  init(canvas) {
    addEventListener('keydown', (e) => {
      if (!this.teclas[e.code]) this.presionadas[e.code] = true;
      this.teclas[e.code] = true;
      if (['Space', 'Tab'].includes(e.code)) e.preventDefault();
    });
    addEventListener('keyup', (e) => { this.teclas[e.code] = false; });
    addEventListener('mousedown', (e) => { if (e.button === 0) { this.mouseAbajo = true; this.clic = true; } });
    addEventListener('mouseup', (e) => { if (e.button === 0) this.mouseAbajo = false; });
    addEventListener('mousemove', (e) => {
      if (!this.bloqueado) return;
      this.dx += e.movementX || 0; this.dy += e.movementY || 0;
    });
    addEventListener('wheel', (e) => { this.rueda += Math.sign(e.deltaY); }, { passive: true });
    addEventListener('blur', () => { this.teclas = {}; this.mouseAbajo = false; });
    document.addEventListener('pointerlockchange', () => {
      this.bloqueado = document.pointerLockElement === canvas;
    });
  },
  fin() { this.presionadas = {}; this.clic = false; this.dx = 0; this.dy = 0; this.rueda = 0; },
  tecla(c) { return !!this.teclas[c]; },
  pulso(c) { return !!this.presionadas[c]; },
};

// ---------------------------------------------------------------------
//  Colisiones del mapa (cajas alineadas a los ejes + terreno)
// ---------------------------------------------------------------------
const PASO = 0.6; // altura máxima que se sube caminando (escalones)

function agregarCaja(minX, minY, minZ, maxX, maxY, maxZ, opts = {}) {
  const c = { min: V3(minX, minY, minZ), max: V3(maxX, maxY, maxZ), sinBala: !!opts.sinBala };
  G.cajas.push(c);
  return c;
}

// Altura del suelo bajo (x,z) para alguien con los pies en "pies"
function alturaSuelo(x, z, pies, radio = 0.3) {
  let h = Terreno.altura(x, z);
  for (const c of G.cajas) {
    if (c.max.y > pies + PASO + 0.001) continue;
    if (x + radio * 0.5 < c.min.x || x - radio * 0.5 > c.max.x) continue;
    if (z + radio * 0.5 < c.min.z || z - radio * 0.5 > c.max.z) continue;
    if (c.max.y > h) h = c.max.y;
  }
  return h;
}

// Empuja un cilindro (pos = pies) fuera de las cajas. Devuelve true si chocó.
function empujarFuera(pos, radio, alto) {
  let choco = false;
  for (const c of G.cajas) {
    if (c.max.y <= pos.y + PASO || c.min.y >= pos.y + alto) continue;
    const cx = clamp(pos.x, c.min.x, c.max.x), cz = clamp(pos.z, c.min.z, c.max.z);
    let dx = pos.x - cx, dz = pos.z - cz;
    const d2 = dx * dx + dz * dz;
    if (d2 >= radio * radio) continue;
    choco = true;
    if (d2 > 1e-8) {
      const d = Math.sqrt(d2), k = (radio - d) / d;
      pos.x += dx * k; pos.z += dz * k;
    } else {
      // dentro de la caja: salir por el lado más cercano
      const izq = pos.x - c.min.x, der = c.max.x - pos.x, atr = pos.z - c.min.z, del = c.max.z - pos.z;
      const m = Math.min(izq, der, atr, del);
      if (m === izq) pos.x = c.min.x - radio; else if (m === der) pos.x = c.max.x + radio;
      else if (m === atr) pos.z = c.min.z - radio; else pos.z = c.max.z + radio;
    }
  }
  return choco;
}

// Techo: altura de la caja más baja encima de la cabeza
function techoSobre(pos, radio, alto) {
  let t = Infinity;
  for (const c of G.cajas) {
    if (c.min.y < pos.y + alto - 0.5 || c.min.y > pos.y + alto + 0.6) continue;
    if (pos.x + radio < c.min.x || pos.x - radio > c.max.x || pos.z + radio < c.min.z || pos.z - radio > c.max.z) continue;
    t = Math.min(t, c.min.y);
  }
  return t;
}

// Rayo contra cajas (slab test). Devuelve distancia o Infinity
function rayoCajas(o, d, maxD) {
  let mejor = maxD;
  for (const c of G.cajas) {
    if (c.sinBala) continue;
    let tmin = 0, tmax = mejor;
    let ok = true;
    for (const ax of ['x', 'y', 'z']) {
      if (Math.abs(d[ax]) < 1e-9) {
        if (o[ax] < c.min[ax] || o[ax] > c.max[ax]) { ok = false; break; }
      } else {
        let t1 = (c.min[ax] - o[ax]) / d[ax], t2 = (c.max[ax] - o[ax]) / d[ax];
        if (t1 > t2) { const s = t1; t1 = t2; t2 = s; }
        tmin = Math.max(tmin, t1); tmax = Math.min(tmax, t2);
        if (tmin > tmax) { ok = false; break; }
      }
    }
    if (ok && tmin < mejor) mejor = tmin;
  }
  return mejor;
}

// Rayo contra el terreno (avanza a pasos y refina)
function rayoTerreno(o, d, maxD) {
  let paso = 0.8, t = 0, prev = 0;
  while (t < maxD) {
    const x = o.x + d.x * t, y = o.y + d.y * t, z = o.z + d.z * t;
    if (y < Terreno.altura(x, z)) {
      let a = prev, b = t;
      for (let i = 0; i < 6; i++) {
        const m = (a + b) / 2;
        if (o.y + d.y * m < Terreno.altura(o.x + d.x * m, o.z + d.z * m)) b = m; else a = m;
      }
      return b;
    }
    prev = t; t += paso; paso = Math.min(paso * 1.04, 2.5);
  }
  return Infinity;
}

// Primer impacto contra el mundo (terreno o estructuras)
function rayoMundo(o, d, maxD) {
  const a = rayoCajas(o, d, maxD);
  const b = rayoTerreno(o, d, Math.min(a, maxD));
  return Math.min(a, b);
}

// ¿Hay vista despejada entre dos puntos?
function hayVista(a, b) {
  const d = b.clone().sub(a); const L = d.length(); d.divideScalar(L);
  return rayoMundo(a, d, L - 0.3) >= L - 0.3;
}
