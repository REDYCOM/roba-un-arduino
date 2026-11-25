// =====================================================================
//  MUNDO: terreno de la isla, agua, cielo, clima y el mapa
// =====================================================================

// ---------------------------------------------------------------------
//  TERRENO (mapa de alturas + malla low-poly con colores)
// ---------------------------------------------------------------------
const AGUA_Y = 0;
const SUELO = 1.6; // altura de las zonas planas (plaza, bases, caminos)

// 5 equipos en pentágono (colores del TeamSelector de Roblox)
const ESC_ROBLOX = 0.36;   // metros por stud
const R_BASES = 88;
const EQUIPOS = ['#ff5050', '#5096ff', '#50ff50', '#ffc850', '#c850ff'].map((color, i) => {
  const a = (i / 5) * TAU;
  // la puerta de la base (lado -z local) mira hacia la plaza; giro en múltiplos de 90° (colisiones exactas)
  const giro = Math.round(Math.atan2(Math.cos(a), Math.sin(a)) / (Math.PI / 2)) * (Math.PI / 2);
  return { nombre: 'Equipo ' + (i + 1), color, ang: a, x: Math.cos(a) * R_BASES, z: Math.sin(a) * R_BASES, giro };
});
// convierte coordenadas locales de la base (studs) a metros en el mundo
function baseAMundo(eq, lx, lz) {
  const c = Math.cos(eq.giro), s = Math.sin(eq.giro);
  return [eq.x + (lx * c + lz * s) * ESC_ROBLOX, eq.z + (-lx * s + lz * c) * ESC_ROBLOX];
}
for (const eq of EQUIPOS) {
  eq.puerta = baseAMundo(eq, -8.8, -16);  // justo afuera de la reja
}
const MI_EQUIPO = 1; // el jugador es del Equipo 2 (azul)

// lugares entre las bases
const POS_VIGIA = [Math.cos(TAU * 0.3) * 76, Math.sin(TAU * 0.3) * 76];
const POS_ARDUNOL = [Math.cos(TAU * 0.7) * 78, Math.sin(TAU * 0.7) * 78];

const Terreno = {
  TAM: 360, SEG: 220, grid: null, celda: 0,
  planas: [
    { x: 0, z: 0, r: 30 },
    ...EQUIPOS.map((e) => ({ x: e.x, z: e.z, r: 15 })),
    { x: POS_VIGIA[0], z: POS_VIGIA[1], r: 10 },
  ],
  caminos: [
    // de la plaza a la puerta de cada base
    ...EQUIPOS.map((e) => { const L = Math.hypot(...e.puerta); return { a: [e.puerta[0] / L * 24, e.puerta[1] / L * 24], b: e.puerta, w: 7, aplanar: true }; }),
    { a: [POS_VIGIA[0] * 0.3, POS_VIGIA[1] * 0.3], b: [POS_VIGIA[0] * 0.88, POS_VIGIA[1] * 0.88], w: 4.5, aplanar: true },
    { a: [POS_ARDUNOL[0] * 0.3, POS_ARDUNOL[1] * 0.3], b: [POS_ARDUNOL[0] * 0.9, POS_ARDUNOL[1] * 0.9], w: 4.5 },
  ],
  canal: [[45, 22], [45, -40], [112, -122]],
  estanque: { x: 45, z: 32, r: 11 },
  colinas: [
    { x: POS_ARDUNOL[0], z: POS_ARDUNOL[1], r: 30, h: 13 },
    { x: -76, z: 0, r: 20, h: 6 },
  ],
  distCanal(x, z) {
    const k = this.canal;
    let d = Math.hypot(x - this.estanque.x, z - this.estanque.z) - this.estanque.r + 4.5;
    for (let i = 0; i < k.length - 1; i++) d = Math.min(d, distSeg(x, z, k[i][0], k[i][1], k[i + 1][0], k[i + 1][1]));
    return d;
  },
  borde(a) { return 122 + 7 * Math.sin(a * 3 + 0.5) + 4 * Math.sin(a * 7 + 2) + 2.5 * Math.sin(a * 13 + 4); },

  bruta(x, z) {
    let h = SUELO + (fbm(x * 0.018 + 10, z * 0.018 + 10) - 0.5) * 3.2;
    for (const c of this.colinas) {
      const t = clamp(1 - Math.hypot(x - c.x, z - c.z) / c.r, 0, 1);
      h += c.h * t * t * (3 - 2 * t) + t * (fbm(x * 0.08, z * 0.08, 2) - 0.5) * 2;
    }
    for (const p of this.planas) {
      const w = smooth(p.r + 10, p.r, Math.hypot(x - p.x, z - p.z));
      h = lerp(h, SUELO, w);
    }
    for (const c of this.caminos) {
      if (!c.aplanar) continue;
      const w = smooth(c.w / 2 + 5, c.w / 2, distSeg(x, z, c.a[0], c.a[1], c.b[0], c.b[1]));
      h = lerp(h, SUELO, w);
    }
    // canal y estanque (agua dulce que cruza la isla)
    h = lerp(h, -1.4, smooth(4.5 + 3, 4.5 - 1.5, this.distCanal(x, z)));
    // costa: la isla baja hacia el mar
    const r = Math.hypot(x, z), a = Math.atan2(z, x);
    const b = this.borde(a);
    const m = smooth(b + 8, b - 16, r);
    h = lerp(-7 - (r - b) * 0.05, h, m);
    return h;
  },

  init() {
    const n = this.SEG + 1;
    this.celda = this.TAM / this.SEG;
    this.grid = new Float32Array(n * n);
    for (let j = 0; j < n; j++)
      for (let i = 0; i < n; i++)
        this.grid[j * n + i] = this.bruta(-this.TAM / 2 + i * this.celda, -this.TAM / 2 + j * this.celda);
  },

  altura(x, z) {
    const n = this.SEG + 1;
    const fx = (x + this.TAM / 2) / this.celda, fz = (z + this.TAM / 2) / this.celda;
    if (fx < 0 || fz < 0 || fx >= this.SEG || fz >= this.SEG) return -9;
    const i = Math.floor(fx), j = Math.floor(fz), u = fx - i, v = fz - j;
    const g = this.grid;
    const a = g[j * n + i], b = g[j * n + i + 1], c = g[(j + 1) * n + i], d = g[(j + 1) * n + i + 1];
    // mismo triángulo que la malla
    if (u + v <= 1) return a + (b - a) * u + (c - a) * v;
    return d + (c - d) * (1 - u) + (b - d) * (1 - v);
  },

  enCamino(x, z) {
    let m = 99;
    for (const c of this.caminos) m = Math.min(m, distSeg(x, z, c.a[0], c.a[1], c.b[0], c.b[1]) - c.w / 2);
    return m; // <0 = sobre el camino
  },

  malla() {
    const n = this.SEG + 1;
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(n * n * 3), colr = new Float32Array(n * n * 3);
    // paleta estilo Roblox: "Bright green", "Brick yellow", "Medium stone grey"...
    const cArenaMoj = col('#c9b98a'), cArena = col('#e2d6a6'), cPasto1 = col('#3fa34d'), cPasto2 = col('#36964a'),
      cPasto3 = col('#5bb04f'), cRoca = col('#8f8e90'), cCamino = col('#d6d6d1'), cFondo = col('#5f8a86'), cTierra = col('#9a7b55');
    const c = new THREE.Color();
    for (let j = 0; j < n; j++) {
      for (let i = 0; i < n; i++) {
        const k = j * n + i;
        const x = -this.TAM / 2 + i * this.celda, z = -this.TAM / 2 + j * this.celda, h = this.grid[k];
        pos[k * 3] = x; pos[k * 3 + 1] = h; pos[k * 3 + 2] = z;
        const hx = this.grid[j * n + Math.min(i + 1, n - 1)] - h, hz = this.grid[Math.min(j + 1, n - 1) * n + i] - h;
        const pend = Math.hypot(hx, hz) / this.celda;
        const r = fbm(x * 0.05, z * 0.05, 3);
        if (h < -0.6) c.copy(cFondo).lerp(cArenaMoj, clamp((h + 4) / 3.4, 0, 1));
        else if (h < 0.35) c.copy(cArenaMoj);
        else if (h < 1.0) c.copy(cArena);
        else {
          c.copy(cPasto2).lerp(cPasto1, smooth(0.35, 0.6, r));
          c.lerp(cPasto3, smooth(0.62, 0.8, fbm(x * 0.02 + 40, z * 0.02, 2)) * 0.7);
          c.lerp(cArena, smooth(1.05, 0.85, h));
          const dcam = this.enCamino(x, z);
          if (dcam < 1.2) c.lerp(cCamino, smooth(1.2, -0.4, dcam));
          if (pend > 0.55) c.lerp(cRoca, smooth(0.55, 0.9, pend));
          else if (pend > 0.35) c.lerp(cTierra, smooth(0.35, 0.55, pend) * 0.5);
        }
        // pequeña variación para que no se vea plano
        const v = 0.97 + hash2(i, j) * 0.05;
        colr[k * 3] = c.r * v; colr[k * 3 + 1] = c.g * v; colr[k * 3 + 2] = c.b * v;
      }
    }
    const idx = [];
    for (let j = 0; j < this.SEG; j++)
      for (let i = 0; i < this.SEG; i++) {
        const a = j * n + i, b = a + 1, cc = a + n, d = cc + 1;
        idx.push(a, cc, b, b, cc, d);
      }
    geo.setIndex(idx);
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('color', new THREE.BufferAttribute(colr, 3));
    geo.computeVertexNormals();
    const mat = granoRoblox(new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.9, metalness: 0, flatShading: true }), 0.07);
    const m = new THREE.Mesh(geo, mat);
    m.receiveShadow = true;
    return m;
  },
};

// ---------------------------------------------------------------------
//  GRANO ROBLOX: el plástico/concreto de Roblox tiene un ruido fino.
//  Se agrega en el shader según la posición en el mundo (sin texturas).
// ---------------------------------------------------------------------
function granoRoblox(mat, fuerza) {
  mat.onBeforeCompile = (sh) => {
    sh.vertexShader = 'varying vec3 vPosMundo;\n' + sh.vertexShader.replace('#include <worldpos_vertex>',
      '#include <worldpos_vertex>\n vPosMundo = (modelMatrix * vec4(transformed, 1.0)).xyz;');
    sh.fragmentShader = 'varying vec3 vPosMundo;\n' + sh.fragmentShader.replace('#include <color_fragment>',
      `#include <color_fragment>
      {
        vec3 q = floor(vPosMundo * 7.0);
        float h = fract(sin(dot(q, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
        vec3 q2 = floor(vPosMundo * 1.3);
        float h2 = fract(sin(dot(q2, vec3(39.346, 11.135, 83.155))) * 43758.5453);
        diffuseColor.rgb *= 1.0 + (h - 0.5) * ${(fuerza * 2).toFixed(3)} + (h2 - 0.5) * ${fuerza.toFixed(3)};
      }`);
  };
  return mat;
}

// ---------------------------------------------------------------------
//  OBRA: junta muchas piezas en pocas mallas (rápido de dibujar)
// ---------------------------------------------------------------------
const Obra = {
  listas: { std: [], metal: [], brillo: [], farol: [], vidrio: [] },
  mats: {},
  agregar(g, color, tipo = 'std', intens = 1) {
    if (g.index) g = g.toNonIndexed();
    if (!g.attributes.uv) g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(g.attributes.position.count * 2), 2));
    const c = col(color).multiplyScalar(intens);
    const n = g.attributes.position.count, arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i * 3] = c.r; arr[i * 3 + 1] = c.g; arr[i * 3 + 2] = c.b; }
    g.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    this.listas[tipo].push(g);
    return g;
  },
  // caja con la BASE en y
  caja(x, y, z, sx, sy, sz, color, o = {}) {
    const g = new THREE.BoxGeometry(sx, sy, sz);
    if (o.rotY) g.rotateY(o.rotY);
    if (o.rotX) g.rotateX(o.rotX);
    if (o.rotZ) g.rotateZ(o.rotZ);
    g.translate(x, y + sy / 2, z);
    this.agregar(g, color, o.tipo || 'std', o.intens || 1);
    if (o.solido !== false && !o.rotY && !o.rotX && !o.rotZ && (o.tipo || 'std') !== 'brillo')
      agregarCaja(x - sx / 2, y, z - sz / 2, x + sx / 2, y + sy, z + sz / 2, o);
    else if (o.solido === true) agregarCaja(x - sx / 2, y, z - sz / 2, x + sx / 2, y + sy, z + sz / 2, o);
  },
  cil(x, y, z, rt, rb, h, color, o = {}) {
    const g = new THREE.CylinderGeometry(rt, rb, h, o.seg || 12, 1);
    if (o.rotZ) g.rotateZ(o.rotZ);
    if (o.rotX) g.rotateX(o.rotX);
    g.translate(x, y + h / 2, z);
    this.agregar(g, color, o.tipo || 'std', o.intens || 1);
    if (o.solido) { const r = Math.max(rt, rb) * 0.9; agregarCaja(x - r, y, z - r, x + r, y + h, z + r, o); }
  },
  cono(x, y, z, r, h, color, o = {}) {
    const g = new THREE.ConeGeometry(r, h, o.seg || 8, 1);
    if (o.rotY) g.rotateY(o.rotY);
    g.translate(x, y + h / 2, z);
    this.agregar(g, color, o.tipo || 'std', o.intens || 1);
  },
  bola(x, y, z, r, color, o = {}) {
    const g = new THREE.IcosahedronGeometry(r, o.det ?? 1);
    if (o.esc) g.scale(o.esc[0], o.esc[1], o.esc[2]);
    g.translate(x, y, z);
    this.agregar(g, color, o.tipo || 'std', o.intens || 1);
  },
  anillo(x, y, z, r, tubo, color, o = {}) {
    const g = new THREE.TorusGeometry(r, tubo, 6, o.seg || 40);
    g.rotateX(Math.PI / 2);
    g.translate(x, y, z);
    this.agregar(g, color, o.tipo || 'brillo', o.intens || 1);
  },
  construir(scene) {
    this.mats.std = granoRoblox(new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.68, metalness: 0.0 }), 0.09);
    this.mats.metal = granoRoblox(new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.35, metalness: 0.7 }), 0.05);
    this.mats.brillo = new THREE.MeshBasicMaterial({ vertexColors: true });
    this.mats.farol = new THREE.MeshBasicMaterial({ vertexColors: true });
    this.mats.vidrio = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.05, metalness: 0.2, transparent: true, opacity: 0.55 });
    for (const [tipo, lista] of Object.entries(this.listas)) {
      if (!lista.length) continue;
      const g = ADD.mergeGeometries(lista, false);
      const m = new THREE.Mesh(g, this.mats[tipo]);
      const sombra = tipo === 'std' || tipo === 'metal';
      m.castShadow = sombra; m.receiveShadow = sombra;
      scene.add(m);
      lista.length = 0;
    }
  },
};

// ---------------------------------------------------------------------
//  MAPA
// ---------------------------------------------------------------------
const Mapa = {
  piedra: '#a9a294', piedraOsc: '#7d786d', piedraClara: '#d4ccba', madera: '#8a5a33', maderaOsc: '#5e3b20',
  metalOsc: '#2a3348', concreto: '#a3a6a8',

  construir(scene) {
    this.pendientes = [];
    Terreno.init();
    scene.add(Terreno.malla());
    this.plaza();
    for (let i = 0; i < EQUIPOS.length; i++) this.base(EQUIPOS[i], i);
    this.torreArdunol(scene);
    this.torreVigia();
    this.puente();
    this.muelle();
    this.bunkers();
    this.trampolines();
    this.faroles();
    this.coberturas();
    Obra.construir(scene);
    for (const m of this.pendientes) scene.add(m);
    this.vegetacion(scene);
    this.islasLejanas(scene);
    this.banderas(scene);
    this.holograma(scene);
  },

  // ---------- Plaza central: donde estaba el ARDUINO SUPREMO ----------
  plaza() {
    const y = SUELO;
    Obra.cil(0, y - 0.3, 0, 26, 26.5, 0.36, '#a39a86', { seg: 64 });
    Obra.cil(0, y - 0.3, 0, 21, 21, 0.38, '#6f675b', { seg: 64 });
    Obra.cil(0, y - 0.3, 0, 20.3, 20.3, 0.4, '#b3a991', { seg: 64 });
    Obra.cil(0, y - 0.3, 0, 12, 12, 0.42, '#8f8572', { seg: 48 });
    Obra.anillo(0, y + 0.13, 0, 16, 0.08, '#3fd2ff', { intens: 2.2, seg: 80 });
    // losas radiales
    for (let i = 0; i < 16; i++) {
      const a = (i / 16) * TAU;
      Obra.caja(Math.cos(a) * 16, y + 0.1, Math.sin(a) * 16, 0.35, 0.04, 8, '#9a917f', { rotY: -a + Math.PI / 2, solido: false });
    }
    // pedestal escalonado
    Obra.cil(0, y, 0, 6, 6.4, 0.5, this.piedra, { seg: 8 });
    agregarCaja(-5.2, y, -5.2, 5.2, y + 0.5, 5.2);
    Obra.cil(0, y + 0.5, 0, 4.4, 4.6, 0.5, this.piedraClara, { seg: 8 });
    agregarCaja(-3.8, y, -3.8, 3.8, y + 1.0, 3.8);
    Obra.cil(0, y + 1.0, 0, 2.6, 3.2, 1.6, '#4a4f63', { seg: 8 });
    agregarCaja(-2.4, y, -2.4, 2.4, y + 2.6, 2.4);
    Obra.anillo(0, y + 2.65, 0, 2.5, 0.12, '#3fd2ff', { intens: 2.5 });
    // 8 pilares con cristales
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TAU + Math.PI / 8, x = Math.cos(a) * 22.5, z = Math.sin(a) * 22.5;
      Obra.cil(x, y, z, 1.25, 1.35, 0.6, this.piedraOsc, { seg: 8 });
      Obra.cil(x, y + 0.6, z, 0.85, 0.95, 5.2, this.piedra, { seg: 8, solido: true });
      Obra.cil(x, y + 5.8, z, 1.2, 1.0, 0.5, this.piedraOsc, { seg: 8 });
      Obra.bola(x, y + 7.1, z, 0.75, '#5ee7ff', { tipo: 'brillo', intens: 2.4, det: 0, esc: [0.8, 1.6, 0.8] });
    }
    // arcos en las entradas de los caminos
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * TAU, ca = Math.cos(a), sa = Math.sin(a);
      const cx = ca * 28, cz = sa * 28, px = -sa * 5, pz = ca * 5;
      for (const s of [-1, 1]) {
        Obra.caja(cx + px * s, y, cz + pz * s, 1.6, 6.5, 1.6, this.piedra);
        Obra.caja(cx + px * s, y + 6.5, cz + pz * s, 2, 0.4, 2, this.piedraOsc, { solido: false });
      }
      const largoX = Math.abs(px) * 2 + 2, largoZ = Math.abs(pz) * 2 + 2;
      Obra.caja(cx, y + 6.9, cz, Math.max(largoX, 2), 1.1, Math.max(largoZ, 2), this.piedraClara);
      Obra.caja(cx, y + 7.2, cz, Math.max(largoX, 2) * 0.5 + (largoX > 3 ? 0 : 1.2), 0.5, Math.max(largoZ, 2) * 0.5 + (largoZ > 3 ? 0 : 1.2), '#3fd2ff', { tipo: 'brillo', intens: 1.8, solido: false });
    }
  },

  // ---------- Base de equipo: la BaseEquipo de Roblox, pieza por pieza ----------
  base(eq, idx) {
    const S = ESC_ROBLOX, y0 = SUELO + 0.25;
    const giro = new THREE.Matrix4().makeRotationY(eq.giro);
    const m = new THREE.Matrix4(), rot = new THREE.Matrix4(), tmp = V3();
    const rejas = [];
    eq.cajasRejas = [];
    for (const p of DATOS_BASE.partes) {
      const r = p.r;
      rot.set(r[0], r[1], r[2], 0, r[3], r[4], r[5], 0, r[6], r[7], r[8], 0, 0, 0, 0, 1);
      let g;
      if (p.f === 2) { // cilindro de Roblox: eje en X
        g = new THREE.CylinderGeometry(0.5, 0.5, 1, 20).rotateZ(Math.PI / 2);
        g.scale(p.s[0], Math.min(p.s[1], p.s[2]), Math.min(p.s[1], p.s[2]));
      } else g = new THREE.BoxGeometry(p.s[0], p.s[1], p.s[2]);
      g.applyMatrix4(rot);
      g.translate(p.p[0], p.p[1], p.p[2]);
      g.scale(S, S, S);
      g.applyMatrix4(giro);
      g.translate(eq.x, y0, eq.z);
      // color y material de Roblox (la lona lleva el color del equipo)
      let color = '#' + new THREE.Color(p.c[0] / 255, p.c[1] / 255, p.c[2] / 255).getHexString();
      let tipo = 'std', intens = 1;
      if (p.m === 1088) tipo = 'metal';
      if (p.m === 288) { tipo = 'brillo'; intens = 2.6; color = '#fff6dd'; }
      if (p.n === 'Lona GN') color = eq.color;
      // caja de colisión exacta (todas las piezas están a 90°)
      g.computeBoundingBox();
      const bb = g.boundingBox;
      const esReja = p.g === 'Rejas';
      if (esReja) {
        if (g.index) g = g.toNonIndexed();
        rejas.push(g);
        eq.cajasRejas.push(agregarCaja(bb.min.x, bb.min.y, bb.min.z, bb.max.x, bb.max.y, bb.max.z));
        continue;
      }
      Obra.agregar(g, color, tipo, intens);
      if (tipo !== 'brillo' && p.n !== 'Lona GN' && bb.max.y > SUELO) agregarCaja(bb.min.x, Math.max(bb.min.y, SUELO - 2), bb.min.z, bb.max.x, bb.max.y, bb.max.z);
    }
    // rejas: malla aparte para poder quitarlas al empezar la partida
    if (rejas.length) {
      const geo = ADD.mergeGeometries(rejas.map((g) => { g.deleteAttribute('uv'); return g; }));
      const malla = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ color: '#353536', roughness: 0.35, metalness: 0.8 }));
      malla.castShadow = true; malla.receiveShadow = true;
      eq.mallaRejas = malla;
      this.pendientes.push(malla);
    }
    // patio con el color del equipo, zona de entrega y estación junto a la puerta
    const [px, pz] = eq.puerta;
    const [fx, fz] = baseAMundo(eq, -8.8, -26);
    Obra.cil(fx, SUELO - 0.3, fz, 5.2, 5.4, 0.36, '#a7a8ab', { seg: 40 });
    Obra.cil(fx, SUELO - 0.3, fz, 4.2, 4.2, 0.38, '#' + col('#a7a8ab').lerp(col(eq.color), 0.35).getHexString(), { seg: 40 });
    Obra.anillo(fx, SUELO + 0.1, fz, 4.7, 0.1, eq.color, { intens: 1.8 });
    eq.zona = [fx, fz];
    const [ex, ez] = baseAMundo(eq, 8, -19);
    Obra.caja(ex, SUELO, ez, 1.2, 1.4, 1.2, '#5b6478');
    Obra.caja(ex, SUELO + 1.4, ez, 1.0, 0.8, 1.0, '#7b859c', { solido: false });
    Obra.bola(ex, SUELO + 2.55, ez, 0.42, '#c7cfdf', { tipo: 'metal' });
    Obra.bola(ex, SUELO + 3.05, ez, 0.12, eq.color, { tipo: 'brillo', intens: 3, det: 0 });
    eq.bandera = baseAMundo(eq, -15, -19);
    // aparición: el TeamSpawn de Roblox, mirando hacia la puerta
    const [sx, sz] = baseAMundo(eq, 0, 0);
    eq.spawn = { x: sx, z: sz, y: y0, yaw: eq.giro };
  },

  quitarRejas() {
    for (const eq of EQUIPOS) {
      for (const c of eq.cajasRejas || []) { const i = G.cajas.indexOf(c); if (i >= 0) G.cajas.splice(i, 1); }
      eq.cajasRejas = [];
      const m = eq.mallaRejas;
      if (!m || !m.parent) continue;
      const t0 = G.t;
      const f = (dt, t) => {
        const k = (t - t0) / 1.4;
        m.position.y = -smooth(0, 1, k) * 7;
        if (k >= 1) { m.parent.remove(m); G.anim.splice(G.anim.indexOf(f), 1); }
      };
      G.anim.push(f);
      FX.chispazo(V3(eq.puerta[0], SUELO + 1.5, eq.puerta[1]), '#ffcf4a', 30, 6);
    }
    Sfx.play('pisoton', 30);
  },

  // ---------- Torre del hechicero ARDUNOL (en la colina grande) ----------
  torreArdunol(scene) {
    const [x, z] = POS_ARDUNOL, y = Terreno.altura(x, z) - 0.5;
    const morado = '#3a2a55', moradoOsc = '#261a3a';
    Obra.cil(x, y, z, 6.5, 7.5, 1.2, moradoOsc, { seg: 10, solido: true });
    Obra.cil(x, y + 1.2, z, 4.6, 5.4, 15, morado, { seg: 10, solido: true });
    for (let i = 0; i < 4; i++) Obra.cil(x, y + 3 + i * 3.6, z, 5.1 - i * 0.12, 5.1 - i * 0.12, 0.4, '#8a5cff', { seg: 10, tipo: 'brillo', intens: 1.4 });
    Obra.cil(x, y + 16.2, z, 6, 4.8, 1.2, moradoOsc, { seg: 10 });
    for (let i = 0; i < 10; i++) {
      const a = (i / 10) * TAU;
      Obra.caja(x + Math.cos(a) * 5.4, y + 17.4, z + Math.sin(a) * 5.4, 1.1, 1.3, 1.1, morado, { solido: false });
    }
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU;
      Obra.caja(x + Math.cos(a) * 4.7, y + 7 + (i % 3) * 3, z + Math.sin(a) * 4.7, 0.5, 1.4, 0.5, '#c79bff', { tipo: 'brillo', intens: 1.6, solido: false });
    }
    // cristal flotante + rocas que orbitan (animado)
    const grupo = new THREE.Group(); grupo.position.set(x, y + 24, z);
    const cristal = new THREE.Mesh(new THREE.OctahedronGeometry(2.4, 0),
      new THREE.MeshBasicMaterial({ color: col('#b77bff').multiplyScalar(2.4) }));
    cristal.scale.set(1, 1.7, 1);
    grupo.add(cristal);
    const rocas = [];
    const matRoca = new THREE.MeshStandardMaterial({ color: '#3b3150', roughness: 0.9, flatShading: true });
    for (let i = 0; i < 5; i++) {
      const r = new THREE.Mesh(new THREE.DodecahedronGeometry(rand(0.6, 1.2), 0), matRoca);
      r.castShadow = true; grupo.add(r); rocas.push({ m: r, a: (i / 5) * TAU, rad: rand(4.5, 6), h: rand(-2, 2) });
    }
    scene.add(grupo);
    const luz = new THREE.PointLight('#b06bff', 40, 45, 1.6); luz.position.set(x, y + 22, z); scene.add(luz);
    G.anim.push((dt, t) => {
      cristal.rotation.y += dt * 0.8;
      cristal.position.y = Math.sin(t * 1.3) * 0.6;
      for (const r of rocas) {
        const a = r.a + t * 0.4;
        r.m.position.set(Math.cos(a) * r.rad, r.h + Math.sin(t + r.a) * 0.5, Math.sin(a) * r.rad);
        r.m.rotation.x += dt; r.m.rotation.y += dt * 0.7;
      }
      luz.intensity = 35 + Math.sin(t * 3) * 8;
    });
  },

  // ---------- Torre vigía de 3 pisos con escaleras ----------
  torreVigia() {
    const x0 = POS_VIGIA[0] - 4, x1 = POS_VIGIA[0] + 4, z0 = POS_VIGIA[1] - 4, z1 = POS_VIGIA[1] + 4, y = SUELO, azul = '#2b3d6b';
    for (const px of [x0 + 0.3, x1 - 0.3]) for (const pz of [z0 + 0.3, z1 - 0.3])
      Obra.caja(px, y, pz, 0.55, 15.2, 0.55, azul, { tipo: 'metal' });
    const pisos = [y + 4, y + 8, y + 12];
    pisos.forEach((h, i) => {
      Obra.caja((x0 + x1) / 2, h - 0.3, (z0 + z1) / 2, 8, 0.3, 8, i === 2 ? '#3fa9f5' : '#d9e3f0');
      // vigas en cruz
      Obra.caja((x0 + x1) / 2, h - 0.7, z0 + 0.3, 8, 0.4, 0.3, azul, { tipo: 'metal', solido: false });
      Obra.caja((x0 + x1) / 2, h - 0.7, z1 - 0.3, 8, 0.4, 0.3, azul, { tipo: 'metal', solido: false });
    });
    // escaleras: tramo 1 (norte, hacia +x), tramo 2 (sur, hacia -x), tramo 3 (norte, hacia +x)
    const tramo = (base, zA, zB, dir) => {
      for (let i = 1; i <= 10; i++) {
        const top = base + 0.4 * i;
        const xc = dir > 0 ? x1 - 0.275 - 0.55 * (10 - i) : x1 - 0.275 - 0.55 * (i - 1);
        Obra.caja(xc, top - 0.35, (zA + zB) / 2, 0.55, 0.35, zB - zA, '#f2c230');
      }
    };
    tramo(y, z0 - 1.6, z0, 1);
    tramo(y + 4, z1, z1 + 1.6, -1);
    tramo(y + 8, z0 - 1.6, z0, 1);
    // barandas del piso de arriba
    const top = pisos[2];
    Obra.caja((x0 + x1) / 2, top, z0 + 0.1, 8, 1.1, 0.2, azul, { tipo: 'metal' });
    Obra.caja((x0 + x1) / 2, top, z1 - 0.1, 8, 1.1, 0.2, azul, { tipo: 'metal' });
    Obra.caja(x0 + 0.1, top, (z0 + z1) / 2, 0.2, 1.1, 8, azul, { tipo: 'metal' });
    Obra.caja(x1 - 0.1, top, (z0 + z1) / 2, 0.2, 1.1, 8, azul, { tipo: 'metal' });
    // techo y baliza
    Obra.caja((x0 + x1) / 2, y + 15.2, (z0 + z1) / 2, 8.6, 0.35, 8.6, '#e8ecf2', { solido: false });
    Obra.bola((x0 + x1) / 2, y + 16.2, (z0 + z1) / 2, 0.7, '#ff5050', { tipo: 'farol', det: 0 });
  },

  // ---------- Puente en arco sobre el canal ----------
  puente() {
    const zc = 0, xa = 35, xb = 55, n = 18, ancho = 5;
    for (let i = 0; i < n; i++) {
      const t0 = i / n, t1 = (i + 1) / n, tm = (t0 + t1) / 2;
      const h = SUELO + 2.4 * Math.sin(Math.PI * tm);
      const x = lerp(xa, xb, tm), L = (xb - xa) / n;
      Obra.caja(x, h - 0.4, zc, L + 0.02, 0.4, ancho, i % 2 ? '#c08a52' : '#b07d48');
      for (const s of [-1, 1]) {
        Obra.caja(x, h, zc + s * (ancho / 2 - 0.15), 0.18, 1.0, 0.18, '#f2c230', { solido: false });
        Obra.caja(x, h + 0.95, zc + s * (ancho / 2 - 0.15), L + 0.05, 0.14, 0.22, '#f2c230', { solido: false });
      }
      // muros invisibles de la baranda (no te caes del puente)
      for (const s of [-1, 1]) agregarCaja(x - L / 2, h, zc + s * (ancho / 2) - 0.2, x + L / 2, h + 1.1, zc + s * (ancho / 2) + 0.2, { sinBala: true });
    }
    // estribos de piedra
    for (const xx of [xa - 1, xb + 1]) Obra.caja(xx, SUELO - 1.6, zc, 2.4, 1.7, ancho + 1, this.piedra);
  },

  muelle() {
    const x = -52, z0 = 104, z1 = 134;
    for (let z = z0; z < z1; z += 1.2) Obra.caja(x, 0.9, z + 0.6, 4, 0.25, 1.1, (Math.round(z) % 2) ? '#a8774a' : '#9a6b40');
    for (let z = z0; z <= z1; z += 4)
      for (const s of [-1, 1]) Obra.cil(x + s * 2.1, -3, z, 0.22, 0.25, 4.6, this.maderaOsc, { seg: 6 });
    Obra.caja(x, 0.9, z1 + 1.5, 7, 0.25, 4, '#a8774a');
    agregarCaja(x - 3.5, 0.9, z1 - 0.5, x + 3.5, 1.15, z1 + 3.5);
    // bote
    Obra.caja(x + 5.5, -0.2, z1 - 4, 2.2, 0.9, 5, '#e8e2d6', { solido: false });
    Obra.caja(x + 5.5, 0.55, z1 - 4, 1.8, 0.15, 4.4, '#c43c3c', { solido: false });
  },

  bunkers() {
    for (const [x, z, r] of this.lugares(7, 46, 70, 6, 11)) {
      const y = Terreno.altura(x, z) - 0.2;
      const sx = r ? 5 : 6.5, sz = r ? 6.5 : 5;
      Obra.caja(x, y, z, sx, 3.2, sz, this.concreto);
      Obra.caja(x, y + 3.2, z, sx + 0.4, 0.35, sz + 0.4, '#8d9093', { solido: false });
      // rendijas oscuras
      if (r) { for (const s of [-1, 1]) Obra.caja(x + s * (sx / 2 + 0.01), y + 2, z, 0.04, 0.5, 3.6, '#1a1c20', { solido: false }); }
      else { for (const s of [-1, 1]) Obra.caja(x, y + 2, z + s * (sz / 2 + 0.01), 3.6, 0.5, 0.04, '#1a1c20', { solido: false }); }
      // sacos de arena
      for (let i = -1; i <= 1; i++) Obra.cil(x + (r ? sx / 2 + 1.2 : i * 1.2), y + 0.2, z + (r ? i * 1.2 : sz / 2 + 1.2), 0.55, 0.6, 0.55, '#c2ad7f', { seg: 7 });
    }
  },

  trampolines() {
    for (const [x, z] of this.lugares(5, 38, 52, 4, 5)) {
      const y = Terreno.altura(x, z);
      Obra.cil(x, y - 0.3, z, 2.2, 2.4, 0.7, '#2c3140', { seg: 16, tipo: 'metal' });
      Obra.cil(x, y + 0.4, z, 1.8, 1.8, 0.05, '#36d1ff', { seg: 24, tipo: 'brillo', intens: 2 });
      Obra.anillo(x, y + 0.42, z, 2.05, 0.12, '#f2c230', { tipo: 'std' });
      G.pads.push({ x, z, r: 2.1, y: y + 0.45 });
    }
  },

  faroles() {
    for (const c of Terreno.caminos.slice(0, 6)) {
      const L = Math.hypot(c.b[0] - c.a[0], c.b[1] - c.a[1]), n = Math.floor(L / 14);
      const dx = (c.b[0] - c.a[0]) / L, dz = (c.b[1] - c.a[1]) / L;
      for (let i = 0; i <= n; i++) {
        if ((n - i) * 14 > L - 9 || L - i * 14 < 9) continue; // ni pegado a la plaza ni frente a la puerta
        const s = i % 2 ? 1 : -1, d = c.w / 2 + 1;
        const x = c.a[0] + dx * i * 14 - dz * d * s, z = c.a[1] + dz * i * 14 + dx * d * s;
        const y = Terreno.altura(x, z);
        Obra.cil(x, y, z, 0.12, 0.16, 4, '#262b36', { seg: 6, tipo: 'metal', solido: true });
        Obra.caja(x, y + 4, z, 0.7, 0.12, 0.7, '#262b36', { tipo: 'metal', solido: false });
        Obra.caja(x, y + 3.45, z, 0.45, 0.55, 0.45, '#ffcf7a', { tipo: 'farol', solido: false });
      }
    }
  },

  coberturas() {
    // pilas de cajas y barriles repartidas por el mapa
    for (const [gx, gz] of this.lugares(14, 30, 105, 3, 23)) {
      const y = Terreno.altura(gx, gz);
      if (y < 0.8) continue;
      Obra.caja(gx, y - 0.1, gz, 1.8, 1.8, 1.8, this.madera);
      Obra.caja(gx + 1.9, y - 0.1, gz + 0.2, 1.6, 1.6, 1.6, this.maderaOsc);
      if (hash2(gx, gz) > 0.4) Obra.caja(gx + 0.3, y + 1.7, gz, 1.4, 1.4, 1.4, this.madera);
      Obra.cil(gx - 1.6, y - 0.1, gz + 1.2, 0.55, 0.55, 1.4, hash2(gz, gx) > 0.5 ? '#c0392b' : '#2e86de', { solido: true, seg: 10 });
      Obra.cil(gx - 1.6, y + 1.3, gz + 1.2, 0.57, 0.57, 0.1, '#222', { seg: 10 });
    }
  },

  // n lugares libres repartidos en un anillo (siempre los mismos: semilla fija)
  lugares(n, rMin, rMax, margen, semilla) {
    const res = [];
    for (let k = 0; k < 300 && res.length < n; k++) {
      const a = hash2(k, semilla) * TAU, r = lerp(rMin, rMax, hash2(semilla, k));
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      if (!this.libre(x, z, margen)) continue;
      if (res.some((p) => Math.hypot(p[0] - x, p[1] - z) < 14)) continue;
      res.push([x, z, k % 2]);
    }
    return res;
  },

  // ¿se puede poner algo en (x,z) sin pisar caminos, bases, etc.?
  libre(x, z, margen = 2) {
    const h = Terreno.altura(x, z);
    if (h < 1.0) return false;
    if (Terreno.enCamino(x, z) < margen + 1) return false;
    for (const p of Terreno.planas) if (Math.hypot(x - p.x, z - p.z) < p.r + margen + 1) return false;
    if (Terreno.distCanal(x, z) < 8) return false;
    if (Math.hypot(x - POS_ARDUNOL[0], z - POS_ARDUNOL[1]) < 10) return false;
    for (const pd of G.pads) if (Math.hypot(x - pd.x, z - pd.z) < 4) return false;
    for (const c of G.cajas) {
      if (x > c.min.x - margen && x < c.max.x + margen && z > c.min.z - margen && z < c.max.z + margen) return false;
    }
    return true;
  },

  // ---------- Vegetación instanciada (árboles, pinos, rocas, pasto, flores) ----------
  vegetacion(scene) {
    const dummy = new THREE.Object3D();
    const conViento = (mat, fuerza) => {
      mat.onBeforeCompile = (sh) => {
        sh.uniforms.uTiempo = G.uTiempo;
        sh.vertexShader = 'uniform float uTiempo;\n' + sh.vertexShader.replace('#include <begin_vertex>',
          `#include <begin_vertex>
          #ifdef USE_INSTANCING
            vec3 wp = instanceMatrix[3].xyz;
            float sw = sin(uTiempo * 1.7 + wp.x * 0.35 + wp.z * 0.21) + 0.4 * sin(uTiempo * 3.1 + wp.z * 0.5);
            transformed.x += sw * max(position.y, 0.0) * ${fuerza.toFixed(3)};
            transformed.z += sw * 0.5 * max(position.y, 0.0) * ${fuerza.toFixed(3)};
          #endif`);
      };
      return mat;
    };
    // puntos válidos
    const puntos = [];
    let intentos = 0;
    while (puntos.length < 330 && intentos++ < 8000) {
      const a = Math.random() * TAU, r = Math.sqrt(Math.random()) * 120;
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      if (r > Terreno.borde(a) - 14) continue;
      if (!this.libre(x, z, 2.5)) continue;
      if (puntos.some((p) => Math.hypot(p.x - x, p.z - z) < 4.5)) continue;
      puntos.push({ x, z, y: Terreno.altura(x, z) });
    }
    const redondos = puntos.filter((p, i) => (p.y > 5 ? i % 4 === 0 : i % 3 !== 0));
    const pinos = puntos.filter((p) => !redondos.includes(p));

    // árbol redondo: tronco + copa
    const troncoG = new THREE.CylinderGeometry(0.22, 0.34, 2.6, 6); troncoG.translate(0, 1.3, 0);
    const copaG = ADD.mergeGeometries([
      new THREE.IcosahedronGeometry(1.9, 1).translate(0, 3.6, 0),
      new THREE.IcosahedronGeometry(1.3, 1).translate(0.9, 3.0, 0.5),
      new THREE.IcosahedronGeometry(1.2, 1).translate(-0.8, 3.2, -0.4),
    ]);
    const matTronco = new THREE.MeshStandardMaterial({ color: '#6d4a2c', roughness: 1, flatShading: true });
    const matCopa = conViento(new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 0.9, flatShading: true }), 0.03);
    const tr = new THREE.InstancedMesh(troncoG, matTronco, redondos.length + pinos.length);
    const cp = new THREE.InstancedMesh(copaG, matCopa, redondos.length);
    const verdes = ['#4fae3c', '#3c9a3a', '#6cc04a', '#7fb83a', '#e39b3b', '#58a845'].map(col);
    redondos.forEach((p, i) => {
      const s = rand(0.85, 1.45);
      dummy.position.set(p.x, p.y - 0.1, p.z); dummy.rotation.set(0, rand(0, TAU), 0); dummy.scale.set(s, s, s);
      dummy.updateMatrix(); tr.setMatrixAt(i, dummy.matrix); cp.setMatrixAt(i, dummy.matrix);
      cp.setColorAt(i, i % 13 === 0 ? verdes[4] : pick(verdes.filter((v, k) => k !== 4)));
      agregarCaja(p.x - 0.35 * s, p.y, p.z - 0.35 * s, p.x + 0.35 * s, p.y + 2.6 * s, p.z + 0.35 * s);
    });
    // pino: conos apilados
    const pinoG = ADD.mergeGeometries([
      new THREE.ConeGeometry(2.0, 2.6, 7).translate(0, 2.6, 0),
      new THREE.ConeGeometry(1.6, 2.3, 7).translate(0, 3.9, 0),
      new THREE.ConeGeometry(1.1, 2.0, 7).translate(0, 5.1, 0),
    ]);
    const matPino = conViento(new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 0.9, flatShading: true }), 0.02);
    const pn = new THREE.InstancedMesh(pinoG, matPino, pinos.length);
    const verdesPino = ['#2f7d4a', '#24693d', '#3a8f55', '#2b7356'].map(col);
    pinos.forEach((p, i) => {
      const s = rand(0.9, 1.6), k = redondos.length + i;
      dummy.position.set(p.x, p.y - 0.1, p.z); dummy.rotation.set(0, rand(0, TAU), 0); dummy.scale.set(s, s * rand(0.9, 1.2), s);
      dummy.updateMatrix(); tr.setMatrixAt(k, dummy.matrix); pn.setMatrixAt(i, dummy.matrix); pn.setColorAt(i, pick(verdesPino));
      agregarCaja(p.x - 0.35 * s, p.y, p.z - 0.35 * s, p.x + 0.35 * s, p.y + 2.6 * s, p.z + 0.35 * s);
    });
    for (const m of [tr, cp, pn]) { m.castShadow = true; m.receiveShadow = true; scene.add(m); }

    // rocas
    const nR = 90, rocaG = new THREE.DodecahedronGeometry(1, 0);
    const rocas = new THREE.InstancedMesh(rocaG, new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 0.95, flatShading: true }), nR);
    const grises = ['#8f8b84', '#a29d94', '#7a776f', '#9a958a'].map(col);
    let nRoca = 0;
    for (let k = 0; k < 600 && nRoca < nR; k++) {
      const a = Math.random() * TAU, r = Math.sqrt(Math.random()) * 125;
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      const y = Terreno.altura(x, z);
      if (y < -0.5 || Terreno.enCamino(x, z) < 1.5) continue;
      if (Terreno.planas.some((p) => Math.hypot(x - p.x, z - p.z) < p.r + 2)) continue;
      const s = y > 6 ? rand(0.8, 2.4) : rand(0.4, 1.3);
      dummy.position.set(x, y + s * 0.1, z); dummy.rotation.set(rand(0, 3), rand(0, 3), rand(0, 3));
      dummy.scale.set(s * rand(0.8, 1.4), s * rand(0.5, 0.9), s * rand(0.8, 1.4)); dummy.updateMatrix();
      rocas.setMatrixAt(nRoca, dummy.matrix); rocas.setColorAt(nRoca, pick(grises)); nRoca++;
      if (s > 1.2) agregarCaja(x - s * 0.8, y - 1, z - s * 0.8, x + s * 0.8, y + s * 0.7, z + s * 0.8);
    }
    rocas.count = nRoca; rocas.castShadow = true; rocas.receiveShadow = true; scene.add(rocas);

    // pasto (matas de 3 hojas)
    const hoja = (ang) => {
      const g = new THREE.BufferGeometry();
      const v = new Float32Array([-0.08, 0, 0, 0.08, 0, 0, 0, 0.55, 0]);
      g.setAttribute('position', new THREE.BufferAttribute(v, 3));
      g.setAttribute('normal', new THREE.BufferAttribute(new Float32Array([0, 1, 0, 0, 1, 0, 0, 1, 0]), 3));
      g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(6), 2));
      g.rotateZ(rand(-0.3, 0.3)); g.rotateY(ang);
      return g;
    };
    const mataG = ADD.mergeGeometries([hoja(0), hoja(2.1), hoja(4.2), hoja(1.0).translate(0.1, 0, 0.1)]);
    const matPasto = conViento(new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 1, side: THREE.DoubleSide }), 0.25);
    const nP = 6000;
    const pasto = new THREE.InstancedMesh(mataG, matPasto, nP);
    const vPasto = ['#5fb246', '#4ea23d', '#77c454', '#8ccc58'].map(col);
    let k2 = 0;
    for (let k = 0; k < nP * 3 && k2 < nP; k++) {
      const a = Math.random() * TAU, r = Math.sqrt(Math.random()) * 120;
      const x = Math.cos(a) * r, z = Math.sin(a) * r, y = Terreno.altura(x, z);
      if (y < 1.1 || Terreno.enCamino(x, z) < 0.5) continue;
      if (Terreno.planas.some((p) => Math.hypot(x - p.x, z - p.z) < p.r - 4 + (p.r > 25 ? 8 : 0))) continue;
      const s = rand(0.7, 1.5);
      dummy.position.set(x, y - 0.05, z); dummy.rotation.set(0, rand(0, TAU), 0); dummy.scale.set(s, s, s); dummy.updateMatrix();
      pasto.setMatrixAt(k2, dummy.matrix); pasto.setColorAt(k2, pick(vPasto)); k2++;
    }
    pasto.count = k2; pasto.receiveShadow = true; scene.add(pasto);
    G.pasto = pasto;

    // flores
    const nF = 900;
    const flores = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(0.13, 0).translate(0, 0.35, 0),
      new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 0.7, flatShading: true }), nF);
    const cFlor = ['#ffffff', '#ffd84a', '#ff7eb3', '#b28dff', '#ff8a4a'].map(col);
    let k3 = 0;
    for (let k = 0; k < nF * 4 && k3 < nF; k++) {
      const x = rand(-120, 120), z = rand(-120, 120), y = Terreno.altura(x, z);
      if (y < 1.2 || Terreno.enCamino(x, z) < 1 || fbm(x * 0.04 + 7, z * 0.04, 2) < 0.52) continue;
      if (Terreno.planas.some((p) => Math.hypot(x - p.x, z - p.z) < p.r)) continue;
      dummy.position.set(x, y - 0.05, z); dummy.rotation.set(0, 0, 0); dummy.scale.setScalar(rand(0.8, 1.3)); dummy.updateMatrix();
      flores.setMatrixAt(k3, dummy.matrix); flores.setColorAt(k3, pick(cFlor)); k3++;
    }
    flores.count = k3; scene.add(flores);
  },

  islasLejanas(scene) {
    const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1, flatShading: true });
    const geos = [];
    for (let i = 0; i < 9; i++) {
      const a = (i / 9) * TAU + rand(-0.2, 0.2), r = rand(480, 820), h = rand(25, 90), rad = rand(60, 140);
      const g = new THREE.ConeGeometry(rad, h, 9, 3).translate(Math.cos(a) * r, h / 2 - 6, Math.sin(a) * r);
      const n = g.attributes.position.count, c = new Float32Array(n * 3);
      const p = g.attributes.position;
      for (let k = 0; k < n; k++) {
        p.setX(k, p.getX(k) + rand(-6, 6)); p.setZ(k, p.getZ(k) + rand(-6, 6));
        const yy = p.getY(k), cc = yy < 0 ? col('#d9c48f') : yy > h * 0.6 ? col('#8c8f8a') : col('#3f7d45');
        c[k * 3] = cc.r; c[k * 3 + 1] = cc.g; c[k * 3 + 2] = cc.b;
      }
      g.setAttribute('color', new THREE.BufferAttribute(c, 3));
      g.computeVertexNormals();
      geos.push(g.toNonIndexed());
    }
    scene.add(new THREE.Mesh(ADD.mergeGeometries(geos), mat));
    // fondo marino
    const fondo = new THREE.Mesh(new THREE.PlaneGeometry(4000, 4000).rotateX(-Math.PI / 2),
      new THREE.MeshStandardMaterial({ color: '#2d5a62', roughness: 1 }));
    fondo.position.y = -9; scene.add(fondo);
  },

  banderas(scene) {
    G.banderas = [];
    for (const eq of EQUIPOS) {
      const [x, z] = eq.bandera;
      const y = SUELO - 0.2;
      const mastil = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.1, 7, 6), new THREE.MeshStandardMaterial({ color: '#cfd5df', metalness: 0.8, roughness: 0.3 }));
      mastil.position.set(x, y + 3.5, z); mastil.castShadow = true; scene.add(mastil);
      const g = new THREE.PlaneGeometry(3.2, 1.9, 14, 6); g.translate(1.6, 0, 0);
      const bandera = new THREE.Mesh(g, new THREE.MeshStandardMaterial({ color: eq.color, side: THREE.DoubleSide, roughness: 0.8 }));
      bandera.position.set(x + 0.1, y + 6, z); bandera.castShadow = true; scene.add(bandera);
      const base = g.attributes.position.array.slice();
      G.banderas.push({ m: bandera, base, fase: rand(0, 6) });
    }
    G.anim.push((dt, t) => {
      for (const b of G.banderas) {
        const p = b.m.geometry.attributes.position;
        for (let i = 0; i < p.count; i++) {
          const x = b.base[i * 3];
          p.setZ(i, Math.sin(x * 1.6 - t * 5 + b.fase) * 0.22 * (x / 3.2));
        }
        p.needsUpdate = true;
        b.m.rotation.y = Math.sin(t * 0.3 + b.fase) * 0.4;
      }
    });
  },

  // Arduino holográfico roto sobre el pedestal (lo que quedó tras el robo)
  holograma(scene) {
    const g = new THREE.Group(); g.position.set(0, SUELO + 4.6, 0);
    const matH = new THREE.MeshBasicMaterial({ color: col('#3fd2ff').multiplyScalar(1.6), transparent: true, opacity: 0.55, depthWrite: false, blending: THREE.AdditiveBlending });
    const placa = new THREE.Mesh(new THREE.BoxGeometry(3.4, 0.12, 2.6), matH); g.add(placa);
    const bordeP = new THREE.LineSegments(new THREE.EdgesGeometry(new THREE.BoxGeometry(3.4, 0.12, 2.6)), new THREE.LineBasicMaterial({ color: col('#9ff0ff').multiplyScalar(2) }));
    g.add(bordeP);
    for (let i = 0; i < 7; i++) { const c = new THREE.Mesh(new THREE.BoxGeometry(rand(0.3, 0.8), 0.2, rand(0.3, 0.6)), matH); c.position.set(rand(-1.3, 1.3), 0.16, rand(-1, 1)); g.add(c); }
    const signo = new THREE.Mesh(new THREE.TorusGeometry(0.9, 0.08, 6, 24), matH); signo.position.y = 1.4; g.add(signo);
    const cono = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 2.4, 2.2, 24, 1, true),
      new THREE.MeshBasicMaterial({ color: col('#3fd2ff').multiplyScalar(0.8), transparent: true, opacity: 0.12, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending }));
    cono.position.set(0, SUELO + 3.6, 0); scene.add(cono);
    scene.add(g);
    G.anim.push((dt, t) => {
      g.rotation.y += dt * 0.5;
      g.position.y = SUELO + 4.6 + Math.sin(t * 1.5) * 0.2;
      matH.opacity = 0.45 + Math.sin(t * 13) * 0.08 + (Math.random() < 0.03 ? -0.3 : 0);
      signo.rotation.x = t;
    });
  },
};

// ---------------------------------------------------------------------
//  AGUA
// ---------------------------------------------------------------------
const Agua = {
  mesh: null, mat: null,
  crear(scene) {
    // mapa normal de olas generado con canvas
    const N = 256, cv = document.createElement('canvas'); cv.width = cv.height = N;
    const ctx = cv.getContext('2d'), img = ctx.createImageData(N, N);
    const alt = (x, y) => {
      let h = 0;
      for (let k = 0; k < 6; k++) {
        const f = (k + 1) * 2, a = k * 1.3 + 0.4;
        h += Math.sin(((x * Math.cos(a) + y * Math.sin(a)) / N) * TAU * f + k) / (k + 1);
      }
      return h;
    };
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const dx = alt(x + 1, y) - alt(x - 1, y), dy = alt(x, y + 1) - alt(x, y - 1);
      const n = V3(-dx * 0.9, -dy * 0.9, 1).normalize();
      const i = (y * N + x) * 4;
      img.data[i] = (n.x * 0.5 + 0.5) * 255; img.data[i + 1] = (n.y * 0.5 + 0.5) * 255; img.data[i + 2] = (n.z * 0.5 + 0.5) * 255; img.data[i + 3] = 255;
    }
    ctx.putImageData(img, 0, 0);
    const tex = new THREE.CanvasTexture(cv);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping; tex.repeat.set(160, 160);
    this.mat = new THREE.MeshStandardMaterial({ color: '#1f8fb8', roughness: 0.06, metalness: 0.15, normalMap: tex,
      normalScale: new THREE.Vector2(0.35, 0.35), transparent: true, opacity: 0.84 });
    this.mesh = new THREE.Mesh(new THREE.PlaneGeometry(4000, 4000).rotateX(-Math.PI / 2), this.mat);
    this.mesh.position.y = AGUA_Y; this.mesh.receiveShadow = true;
    scene.add(this.mesh);
  },
  update(dt) {
    this.mat.normalMap.offset.x += dt * 0.012;
    this.mat.normalMap.offset.y += dt * 0.007;
  },
};

// ---------------------------------------------------------------------
//  CIELO (shader propio: degradado, sol/luna y estrellas)
// ---------------------------------------------------------------------
const Cielo = {
  mat: null, mesh: null, envEscena: null,
  crear(scene) {
    this.mat = new THREE.ShaderMaterial({
      side: THREE.BackSide, depthWrite: false, fog: false,
      uniforms: {
        cTop: { value: col('#2f7fd8') }, cHor: { value: col('#a9d8ff') }, cBot: { value: col('#4d86a8') },
        sunDir: { value: V3(-0.45, 0.62, 0.35).normalize() }, sunCol: { value: col('#fff1d0') },
        estrellas: { value: 0 }, tiempo: { value: 0 }, flash: { value: 0 }, solTam: { value: 1 },
      },
      vertexShader: `varying vec3 vDir;
        void main(){ vDir = position; vec4 p = projectionMatrix * modelViewMatrix * vec4(position,1.0); gl_Position = p.xyww; }`,
      fragmentShader: `uniform vec3 cTop, cHor, cBot, sunDir, sunCol; uniform float estrellas, tiempo, flash, solTam; varying vec3 vDir;
        float h3(vec3 p){ p = fract(p*0.3183099+0.1); p *= 17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
        void main(){
          vec3 d = normalize(vDir); float y = d.y;
          vec3 c = mix(cHor, cTop, pow(clamp(y,0.0,1.0), 0.45));
          c = mix(c, cBot, smoothstep(0.0, -0.25, y));
          float s = max(dot(d, normalize(sunDir)), 0.0);
          c += sunCol * (pow(s, 900.0) * 40.0 * solTam + pow(s, 10.0) * 0.3 + pow(s, 3.0) * 0.08);
          if (estrellas > 0.0 && y > 0.0) {
            vec3 q = floor(d * 260.0); float r = h3(q);
            float st = step(0.996, r) * (0.55 + 0.45 * sin(tiempo * 2.0 + r * 300.0));
            c += vec3(st) * estrellas * smoothstep(0.0, 0.25, y) * 2.0;
          }
          c += flash * vec3(0.75, 0.8, 1.0);
          gl_FragColor = vec4(c, 1.0);
          #include <tonemapping_fragment>
          #include <colorspace_fragment>
        }`,
    });
    this.mesh = new THREE.Mesh(new THREE.SphereGeometry(1200, 32, 16), this.mat);
    this.mesh.renderOrder = -1; this.mesh.frustumCulled = false;
    scene.add(this.mesh);
    this.envEscena = new THREE.Scene();
    this.envEscena.add(new THREE.Mesh(new THREE.SphereGeometry(50, 32, 16), this.mat));
  },
};

// ---------------------------------------------------------------------
//  CLIMA: día (descanso), noche (oleada), tormenta (jefe), niebla (drones)
// ---------------------------------------------------------------------
const CLIMAS = {
  dia: { top: '#3d8fe0', hor: '#c4dcf0', bot: '#6d8fa8', sol: [-0.45, 0.66, 0.35], solCol: '#fff6e6', solI: 2.9, solTam: 1,
    hemiC: '#d4dae2', hemiS: '#7a776e', hemiI: 0.5, niebla: '#c2d2e0', nieblaD: 0.0026, estrellas: 0, nubes: '#ffffff',
    agua: '#1f8fb8', lluvia: 0, farol: 0.9, expo: 1.0, cristal: 1 },
  noche: { top: '#030616', hor: '#16244a', bot: '#081226', sol: [0.35, 0.55, -0.45], solCol: '#9db8ff', solI: 1.0, solTam: 0.35,
    hemiC: '#4a62a8', hemiS: '#1a2418', hemiI: 0.4, niebla: '#121c38', nieblaD: 0.0062, estrellas: 1, nubes: '#2c3656',
    agua: '#0b2442', lluvia: 0, farol: 3.2, expo: 1.1, cristal: 1.4 },
  tormenta: { top: '#12040a', hor: '#5a1c18', bot: '#1d0707', sol: [0.25, 0.4, 0.5], solCol: '#ff6a48', solI: 1.0, solTam: 0,
    hemiC: '#9a4040', hemiS: '#2a1410', hemiI: 0.45, niebla: '#3a1612', nieblaD: 0.0105, estrellas: 0, nubes: '#341a1a',
    agua: '#2a1210', lluvia: 1, farol: 3.2, expo: 1.05, cristal: 1.6 },
  niebla: { top: '#1f3326', hor: '#7d9a7e', bot: '#2d3d30', sol: [0.4, 0.5, 0.3], solCol: '#d6ffd0', solI: 0.9, solTam: 0.2,
    hemiC: '#a6cda8', hemiS: '#2d3a28', hemiI: 0.55, niebla: '#6e8a70', nieblaD: 0.02, estrellas: 0, nubes: '#8aa58c',
    agua: '#244c3a', lluvia: 0.35, farol: 2.2, expo: 1.0, cristal: 1.2 },
};

const Clima = {
  nombre: 'dia', actual: null, desde: null, hacia: null, t: 1, envT: 0, pmrem: null, env: null,
  sol: null, hemi: null, flash: 0, proxRayo: 5, lluvia: null, nubes: [], matNubes: null,

  crear(scene, renderer) {
    this.pmrem = new THREE.PMREMGenerator(renderer);
    this.hemi = new THREE.HemisphereLight('#cfe8ff', '#55733a', 1.2); scene.add(this.hemi);
    this.sol = new THREE.DirectionalLight('#fff1d0', 3);
    this.sol.castShadow = true;
    this.sol.shadow.mapSize.set(2048, 2048);
    const s = this.sol.shadow.camera; s.left = -70; s.right = 70; s.top = 70; s.bottom = -70; s.near = 1; s.far = 400;
    this.sol.shadow.bias = -0.0004; this.sol.shadow.normalBias = 0.04;
    scene.add(this.sol); scene.add(this.sol.target);
    scene.fog = new THREE.FogExp2('#b8daf2', 0.0038);
    this.actual = this.copiar(CLIMAS.dia);
    this.crearLluvia(scene);
    this.crearNubes(scene);
    this.aplicar();
    this.regenerarEnv(scene);
  },
  copiar(p) {
    const o = {};
    for (const [k, v] of Object.entries(p)) o[k] = typeof v === 'string' ? col(v) : Array.isArray(v) ? V3(...v).normalize() : v;
    return o;
  },
  poner(nombre) {
    if (nombre === this.nombre && this.t >= 1) return;
    this.nombre = nombre;
    this.desde = {}; for (const [k, v] of Object.entries(this.actual)) this.desde[k] = v.clone ? v.clone() : v;
    this.hacia = this.copiar(CLIMAS[nombre]);
    this.t = 0;
  },
  aplicar() {
    const a = this.actual, u = Cielo.mat.uniforms;
    u.cTop.value.copy(a.top); u.cHor.value.copy(a.hor); u.cBot.value.copy(a.bot);
    u.sunDir.value.copy(a.sol); u.sunCol.value.copy(a.solCol); u.estrellas.value = a.estrellas; u.solTam.value = a.solTam;
    this.sol.color.copy(a.solCol); this.sol.intensity = a.solI;
    this.hemi.color.copy(a.hemiC); this.hemi.groundColor.copy(a.hemiS); this.hemi.intensity = a.hemiI + this.flash * 3;
    G.scene.fog.color.copy(a.niebla); G.scene.fog.density = a.nieblaD;
    Agua.mat.color.copy(a.agua);
    if (this.matNubes) { this.matNubes.color.copy(a.nubes); this.matNubes.emissive.copy(a.nubes); }
    if (Obra.mats.farol) Obra.mats.farol.color.setScalar(a.farol);
    if (Obra.mats.brillo) Obra.mats.brillo.color.setScalar(a.cristal);
    G.renderer.toneMappingExposure = a.expo;
    u.flash.value = this.flash;
  },
  regenerarEnv(scene) {
    if (this.env) this.env.dispose();
    this.env = this.pmrem.fromScene(Cielo.envEscena, 0.04);
    scene.environment = this.env.texture;
  },
  crearLluvia(scene) {
    const N = 4000, pos = new Float32Array(N * 6);
    this.gotas = [];
    for (let i = 0; i < N; i++) this.gotas.push({ x: rand(-40, 40), y: rand(0, 40), z: rand(-40, 40), v: rand(28, 38) });
    const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    this.lluvia = new THREE.LineSegments(g, new THREE.LineBasicMaterial({ color: '#a9bcd8', transparent: true, opacity: 0, depthWrite: false }));
    this.lluvia.frustumCulled = false;
    scene.add(this.lluvia);
  },
  crearNubes(scene) {
    this.matNubes = new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 1, flatShading: true, emissive: '#ffffff', emissiveIntensity: 0.15, fog: false });
    for (let i = 0; i < 26; i++) {
      const gs = [];
      const n = randi(4, 7);
      for (let k = 0; k < n; k++) gs.push(new THREE.IcosahedronGeometry(rand(8, 15), 1).translate(k * 9 - n * 4.5 + rand(-3, 3), rand(-2, 4), rand(-6, 6)));
      const m = new THREE.Mesh(ADD.mergeGeometries(gs), this.matNubes);
      m.scale.y = 0.55;
      const a = rand(0, TAU), r = rand(80, 550);
      m.position.set(Math.cos(a) * r, rand(110, 170), Math.sin(a) * r);
      m.rotation.y = rand(0, TAU);
      scene.add(m); this.nubes.push(m);
    }
  },
  update(dt, scene) {
    if (this.t < 1) {
      this.t = Math.min(1, this.t + dt / 4);
      const k = smooth(0, 1, this.t);
      for (const key of Object.keys(this.hacia)) {
        const a = this.desde[key], b = this.hacia[key];
        if (b.isColor) this.actual[key].copy(a).lerp(b, k);
        else if (b.isVector3) this.actual[key].copy(a).lerp(b, k).normalize();
        else this.actual[key] = lerp(a, b, k);
      }
      this.envT -= dt;
      if (this.envT <= 0 || this.t >= 1) { this.regenerarEnv(scene); this.envT = 0.5; }
    }
    // relámpagos en la tormenta
    this.flash = Math.max(0, this.flash - dt * 3.5);
    if (this.nombre === 'tormenta' && this.t > 0.5) {
      this.proxRayo -= dt;
      if (this.proxRayo <= 0) {
        this.proxRayo = rand(3, 8);
        const p = Jugador.pos;
        const dst = V3(p.x + rand(-90, 90), 0, p.z + rand(-90, 90));
        dst.y = Math.max(Terreno.altura(dst.x, dst.z), 0);
        this.relampago(dst);
      }
    }
    this.aplicar();
    // sol sigue al jugador (sombras nítidas cerca)
    const p = Jugador.pos;
    this.sol.target.position.set(p.x, 0, p.z);
    this.sol.position.set(p.x + this.actual.sol.x * 150, Math.max(this.actual.sol.y, 0.25) * 150, p.z + this.actual.sol.z * 150);
    Cielo.mesh.position.copy(G.camera.position);
    // lluvia
    const cant = this.actual.lluvia;
    this.lluvia.visible = cant > 0.02;
    Sfx.lluvia(cant);
    if (this.lluvia.visible) {
      this.lluvia.material.opacity = 0.35 * cant;
      const arr = this.lluvia.geometry.attributes.position.array;
      const n = Math.floor(this.gotas.length * cant * (G.calidad ? 1 : 0.4));
      const c = G.camera.position;
      for (let i = 0; i < this.gotas.length; i++) {
        const d = this.gotas[i];
        d.y -= d.v * dt;
        if (d.y < -5) { d.y = rand(30, 40); d.x = rand(-40, 40); d.z = rand(-40, 40); }
        const j = i * 6;
        if (i < n) {
          const x = c.x + d.x, y = c.y + d.y - 10, z = c.z + d.z;
          arr[j] = x; arr[j + 1] = y; arr[j + 2] = z; arr[j + 3] = x + 0.08; arr[j + 4] = y - 0.9; arr[j + 5] = z + 0.05;
        } else { arr[j + 1] = -999; arr[j + 4] = -999; }
      }
      this.lluvia.geometry.attributes.position.needsUpdate = true;
    }
    // nubes que se mueven
    for (const m of this.nubes) {
      m.position.x += dt * 2.2;
      if (m.position.x > 600) m.position.x = -600;
    }
  },
  relampago(dst, fuerte = false) {
    this.flash = fuerte ? 1.4 : 1;
    FX.rayo(V3(dst.x + rand(-20, 20), 120, dst.z + rand(-20, 20)), dst, fuerte);
    const dist = dst.distanceTo(Jugador.pos);
    setTimeout(() => Sfx.play('trueno', dist * 0.4), Math.min(dist * 6, 1800));
  },
};
