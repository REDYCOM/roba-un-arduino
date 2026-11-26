// =====================================================================
//  COMPONENTES DEL ROBOT SEGUIDOR DE LÍNEA (modelos de Tinkercad)
//  - Flotan por el mapa, girando y brillando (como ComponentesBrillan).
//  - [E] para recoger uno; llévalo al anillo de tu base (+100 puntos).
//  - En tu base hay un holograma del robot: cada pieza que entregas se
//    vuelve real. Con las 9 piezas, el robot se arma y te ayuda a pelear.
//  - Si un robot te golpea fuerte mientras llevas una pieza, se te cae.
// =====================================================================
const PIEZAS = [
  { id: 'arduino', modelo: 'arduino', nombre: 'Arduino UNO', icono: '🧠', info: 'Es el cerebro del robot: lee los sensores y decide qué hacer.' },
  { id: 'chasis', modelo: 'chasis', nombre: 'Chasis', icono: '🛹', info: 'La base donde se atornillan todas las piezas del robot.' },
  { id: 'l298n', modelo: 'l298n', nombre: 'Puente H L298N', icono: '🎛️', info: 'Controla la velocidad y el sentido de giro de los dos motores.' },
  { id: 'motorIzq', modelo: 'motor', nombre: 'Motor izquierdo', icono: '⚙️', info: 'Convierte la electricidad en movimiento para la rueda izquierda.' },
  { id: 'motorDer', modelo: 'motor', nombre: 'Motor derecho', icono: '⚙️', info: 'Convierte la electricidad en movimiento para la rueda derecha.' },
  { id: 'llantas', modelo: 'llanta', nombre: 'Llantas', icono: '🛞', info: 'Pasan el giro de los motores al suelo para que el robot avance.' },
  { id: 'portapila', modelo: 'portapila', nombre: 'Portapila 18650', icono: '🔌', info: 'Sostiene las baterías y las conecta al circuito.' },
  { id: 'pilas', modelo: 'pilas', nombre: 'Baterías 18650', icono: '🔋', info: 'Dan la energía: cada una entrega 3,7 voltios.' },
  { id: 'sensor', modelo: 'sensor', nombre: 'Sensor ultrasónico', icono: '📡', info: 'Mide distancias con sonido, como un murciélago.' },
];

// dónde va cada pieza en el robot armado (milímetros; el frente mira a -z)
const ARMADO = {
  chasis: [{ p: [0, 33, 0] }],
  llantas: [{ p: [-96, 0, 45] }, { p: [96, 0, 45] }],
  motorIzq: [{ p: [-50, 10, 45], ry: Math.PI / 2 }],
  motorDer: [{ p: [50, 10, 45], ry: -Math.PI / 2 }],
  l298n: [{ p: [0, 35.5, 50] }],
  arduino: [{ p: [0, 35.5, -30] }],
  portapila: [{ p: [-48, 35.5, -5] }],
  pilas: [{ p: [48, 35.5, -5], esc: 0.6 }],
  sensor: [{ p: [0, 35.5, -95] }],
};

const Componentes = {
  geos: {}, sueltas: [], llevando: null, entregadas: new Set(), mano: null, armado: null, armados: {}, mat: null, matHolo: null, aliado: null,
  ESC_ARMADO: 0.009, // 1 mm → 9 mm: el robot armado mide casi 2 m

  geometria(nombre) {
    if (this.geos[nombre]) return this.geos[nombre];
    const d = DATOS_COMPONENTES[nombre];
    const b64 = (s) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0)).buffer;
    const q = new Int16Array(b64(d.pos)), c8 = new Uint8Array(b64(d.col));
    const pos = new Float32Array(q.length);
    for (let i = 0; i < q.length; i += 3) {
      pos[i] = (q[i] / 32767) * d.tam[0]; pos[i + 1] = (q[i + 1] / 32767) * d.tam[1]; pos[i + 2] = (q[i + 2] / 32767) * d.tam[2];
    }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    // los colores de Tinkercad vienen en sRGB: pasarlos a lineal
    const colr = new Float32Array(c8.length), tmp = new THREE.Color();
    for (let i = 0; i < c8.length; i += 3) { tmp.setRGB(c8[i] / 255, c8[i + 1] / 255, c8[i + 2] / 255, THREE.SRGBColorSpace); colr[i] = tmp.r; colr[i + 1] = tmp.g; colr[i + 2] = tmp.b; }
    g.setAttribute('color', new THREE.BufferAttribute(colr, 3));
    g.setIndex(new THREE.BufferAttribute(d.idx32 ? new Uint32Array(b64(d.idx)) : new Uint16Array(b64(d.idx)), 1));
    g.computeVertexNormals();
    g.computeBoundingBox();
    this.geos[nombre] = g;
    return g;
  },
  malla(pieza, mat) {
    const m = new THREE.Mesh(this.geometria(pieza.modelo), mat || this.mat);
    m.castShadow = true; m.receiveShadow = true;
    return m;
  },
  // escala para que la pieza flotante mida ~1.2 m (se ve de lejos)
  escalaFlotante(pieza) { const t = DATOS_COMPONENTES[pieza.modelo].tam; return Math.min(0.016, 1.2 / Math.max(...t)); },

  etiqueta(texto, sub) {
    const cv = document.createElement('canvas'); cv.width = 512; cv.height = 160;
    const c = cv.getContext('2d');
    c.fillStyle = 'rgba(10,16,32,0.75)'; c.beginPath(); c.roundRect(6, 6, 500, 148, 30); c.fill();
    c.strokeStyle = '#36c5ff'; c.lineWidth = 6; c.stroke();
    c.fillStyle = '#ffffff'; c.font = 'bold 56px "Baloo 2", system-ui, sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.fillText(texto, 256, 62);
    c.fillStyle = '#ffcf4a'; c.font = 'bold 40px "Baloo 2", system-ui, sans-serif'; c.fillText(sub, 256, 120);
    const tex = new THREE.CanvasTexture(cv); tex.colorSpace = THREE.SRGBColorSpace;
    const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, depthWrite: false, transparent: true }));
    sp.scale.set(2.4, 0.75, 1);
    return sp;
  },

  crear(scene) {
    this.mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.5, metalness: 0.15, flatShading: true });
    this.matHolo = new THREE.MeshBasicMaterial({ color: col('#36c5ff').multiplyScalar(1.4), transparent: true, opacity: 0.22, depthWrite: false, blending: THREE.AdditiveBlending });
    // la mano (lo que llevas se ve abajo a la izquierda)
    this.mano = new THREE.Group(); this.mano.position.set(-0.34, -0.3, -0.62); G.camera.add(this.mano);
  },

  // al empezar la partida: un kit de 9 piezas por cada equipo con jugadores
  iniciar() {
    const kits = G.equiposActivos.length;
    const lugares = Mapa.lugares(PIEZAS.length * kits, 30, 108, 3, 77);
    const lista = [];
    for (let k = 0; k < kits; k++) lista.push(...PIEZAS);
    lista.sort(() => Math.random() - 0.5);
    lista.forEach((p, i) => { if (lugares[i]) this.soltar(p, lugares[i][0], lugares[i][1]); });
    for (const i of G.equiposActivos) this.crearArmado(G.scene, i);
    this.armado = this.armados[MI_EQUIPO];
  },

  soltar(pieza, x, z, scene = G.scene) {
    const y = Terreno.altura(x, z);
    const g = new THREE.Group(); g.position.set(x, y, z);
    const giro = new THREE.Group(); giro.position.y = 1.2; g.add(giro);
    const m = this.malla(pieza); const s = this.escalaFlotante(pieza);
    const bb = m.geometry.boundingBox;
    m.scale.setScalar(s); m.position.y = -((bb.max.y + bb.min.y) / 2) * s;
    giro.add(m);
    // dos aros como las runas + brillo en el suelo + etiqueta con nombre y puntos
    const matAro = new THREE.MeshBasicMaterial({ color: col('#36c5ff').multiplyScalar(2.2) });
    const a1 = new THREE.Mesh(new THREE.TorusGeometry(0.75, 0.025, 6, 40), matAro); a1.rotation.x = Math.PI / 2; a1.position.y = 1.2;
    const a2 = new THREE.Mesh(new THREE.TorusGeometry(0.6, 0.02, 6, 40), matAro); a2.position.y = 1.2;
    g.add(a1, a2);
    const brillo = new THREE.Mesh(new THREE.CircleGeometry(1.3, 32).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ map: Terror.textura(), color: col('#36c5ff').multiplyScalar(1.2), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    brillo.position.y = 0.06; g.add(brillo);
    const et = this.etiqueta(pieza.icono + ' ' + pieza.nombre, '+100 puntos'); et.position.y = 2.45; g.add(et);
    scene.add(g);
    this.sueltas.push({ pieza, g, giro, a1, a2, pos: V3(x, y, z), t: rand(0, 6) });
  },

  // holograma del robot armado en el patio de tu base
  crearArmado(scene, idx) {
    const eq = EQUIPOS[idx];
    const [zx, zz] = eq.zona;
    const g = new THREE.Group(); g.position.set(zx, SUELO + 0.25, zz);
    g.rotation.y = eq.giro + Math.PI; // de frente hacia la puerta de la base
    // pedestal
    const ped = new THREE.Mesh(new THREE.CylinderGeometry(1.5, 1.7, 0.25, 32), new THREE.MeshStandardMaterial({ color: '#3a3f4a', metalness: 0.6, roughness: 0.4 }));
    ped.position.y = -0.12; ped.receiveShadow = true; g.add(ped);
    const cuerpo = new THREE.Group(); cuerpo.scale.setScalar(this.ESC_ARMADO); g.add(cuerpo);
    const partes = {};
    for (const p of PIEZAS) {
      partes[p.id] = [];
      for (const lugar of ARMADO[p.id]) {
        const m = this.malla(p, this.matHolo);
        m.castShadow = false;
        const bb = m.geometry.boundingBox;
        m.position.set(lugar.p[0], lugar.p[1] - bb.min.y * (lugar.esc || 1), lugar.p[2]);
        if (lugar.ry) m.rotation.y = lugar.ry;
        if (lugar.esc) m.scale.setScalar(lugar.esc);
        cuerpo.add(m); partes[p.id].push(m);
      }
    }
    const et = this.etiqueta('🤖 Robot seguidor', '0 / 9 piezas'); et.position.y = 2.6; g.add(et);
    scene.add(g);
    this.armados[idx] = { g, cuerpo, partes, et, base: g.position.clone() };
  },

  actualizarEtiqueta() {
    const a = this.armado; a.g.remove(a.et);
    const n = this.entregadas.size;
    a.et = this.etiqueta(n === PIEZAS.length ? '🤖 ¡Robot armado!' : '🤖 Robot seguidor', n + ' / ' + PIEZAS.length + ' piezas');
    a.et.position.y = 2.6; a.g.add(a.et);
  },

  recoger(s) {
    this.llevando = s.pieza;
    G.scene.remove(s.g);
    this.sueltas.splice(this.sueltas.indexOf(s), 1);
    // copia chiquita en la mano
    this.mano.clear();
    const m = this.malla(s.pieza); m.castShadow = false;
    const bb = m.geometry.boundingBox, t = DATOS_COMPONENTES[s.pieza.modelo].tam;
    const k = 0.32 / Math.max(...t); m.scale.setScalar(k); m.position.y = -((bb.max.y + bb.min.y) / 2) * k;
    m.rotation.set(0.5, 0.6, 0);
    this.mano.add(m);
    Sfx.play('recoger');
    HUD.feed(s.pieza.icono + ' Recogiste: <b>' + s.pieza.nombre + '</b>. ¡Llévalo a tu base!');
    HUD.info(s.pieza);
  },

  soltarLlevada() {
    if (!this.llevando) return;
    const p = this.llevando; this.llevando = null; this.mano.clear();
    this.soltar(p, Jugador.pos.x + rand(-1, 1), Jugador.pos.z + rand(-1, 1));
    HUD.feed('💥 ¡Se te cayó: <b>' + p.nombre + '</b>!');
  },

  entregar() {
    const p = this.llevando; this.llevando = null; this.mano.clear();
    // tu equipo ya tenía esa pieza: cuenta como repuesto
    if (this.entregadas.has(p.id)) {
      sumarPuntos(25); Sfx.play('recoger');
      HUD.feed(p.icono + ' Tu equipo ya tenía <b>' + p.nombre + '</b>: repuesto <b>+25</b>');
      return;
    }
    this.entregadas.add(p.id);
    for (const m of this.armado.partes[p.id]) { m.material = this.mat; m.castShadow = true; }
    sumarPuntos(100);
    Sfx.play('oleada');
    FX.chispazo(this.armado.base.clone().setY(this.armado.base.y + 1), '#36c5ff', 40, 6);
    FX.aro(this.armado.base, 5, '#36c5ff', 0.7);
    this.actualizarEtiqueta();
    const n = this.entregadas.size;
    if (n === PIEZAS.length) {
      sumarPuntos(500);
      HUD.anuncio('🤖 ¡ROBOT ARMADO!', '+500 · Tu robot seguidor ahora te ayuda a pelear', '#36c5ff');
      this.aliado = { t: 0, cd: 1 };
    } else HUD.anuncio(p.icono + ' ¡' + p.nombre.toUpperCase() + ' ENTREGADO!', '+100 · Faltan ' + (PIEZAS.length - n) + ' piezas', '#36c5ff');
  },

  // si te pegan fuerte mientras llevas una pieza, se te cae
  alRecibirDano(cant) { if (this.llevando && (cant >= 20 || Jugador.vida <= 0)) this.soltarLlevada(); },

  update(dt) {
    for (const s of this.sueltas) {
      s.t += dt;
      s.giro.rotation.y += dt * 0.9;
      s.giro.position.y = 1.2 + Math.sin(s.t * 2) * 0.15;
      s.a1.rotation.z += dt * 1.6; s.a2.rotation.y += dt * 2.2;
      s.a1.position.y = s.a2.position.y = s.giro.position.y;
      if (Math.random() < dt * 3) FX.chispas.emitir(s.pos.x + rand(-0.6, 0.6), s.pos.y + 0.4, s.pos.z + rand(-0.6, 0.6), 0, 1.2, 0, FX.c('#36c5ff', 2.5), 0.08, 1);
    }
    if (G.estado !== 'jugando' || Jugador.muerto) return;
    // recoger
    if (!this.llevando && !Torretas.montada) {
      for (const s of this.sueltas) {
        if (Math.hypot(Jugador.pos.x - s.pos.x, Jugador.pos.z - s.pos.z) < 2.4 && Math.abs(Jugador.pos.y - s.pos.y) < 3) {
          G.aviso = 'Pulsa <kbd>E</kbd> para recoger: ' + s.pieza.icono + ' <b>' + s.pieza.nombre + '</b>';
          if (Input.pulso('KeyE')) this.recoger(s);
          break;
        }
      }
    }
    // entregar en el anillo de tu base
    if (this.llevando) {
      const [zx, zz] = EQUIPOS[MI_EQUIPO].zona;
      const d = Math.hypot(Jugador.pos.x - zx, Jugador.pos.z - zz);
      if (d < 5.2) this.entregar();
      this.mano.rotation.y += dt * 0.8;
      this.mano.position.y = -0.3 + Math.sin(G.t * 3) * 0.01;
    }
    // el holograma parpadea suavemente
    this.matHolo.opacity = 0.18 + Math.sin(G.t * 3) * 0.06 + (Math.random() < 0.02 ? 0.15 : 0);
    if (this.aliado) this.updateAliado(dt);
  },

  // con las 9 piezas, el robot recorre el patio y dispara a los robots cercanos
  updateAliado(dt) {
    const a = this.aliado, ar = this.armado;
    a.t += dt;
    const ang = a.t * 0.45;
    ar.g.position.set(ar.base.x + Math.cos(ang) * 3.2, ar.base.y, ar.base.z + Math.sin(ang) * 3.2);
    ar.g.rotation.y = -ang + Math.PI;
    a.cd -= dt;
    if (a.cd > 0) return;
    let obj = null, md = 30;
    const ojo = ar.g.position.clone().setY(ar.g.position.y + 0.6);
    for (const r of Robots.vivos) { const d = r.centro().distanceTo(ojo); if (d < md && hayVista(ojo, r.centro())) { md = d; obj = r; } }
    if (!obj) return;
    a.cd = 0.9;
    const c = obj.centro();
    FX.segmento(ojo, c, 0.06, '#36c5ff', 0.18, 3);
    FX.chispazo(c, '#36c5ff', 8, 4);
    Robots.danar(obj, 35, c, false);
    Sfx.play('laser', ojo.distanceTo(Jugador.pos));
  },
};
