// =====================================================================
//  ROBOTS ENEMIGOS: modelos, IA, oleadas, jefe MEGA-ARDUINO, botín
//  (valores de Robots.server.luau, escalados de studs a metros)
// =====================================================================
const TIPOS = {
  Seguidor: { vida: 120, vel: 7.4, dano: 20, alcance: 1.4, alto: 1.9, radio: 0.55, puntos: 15, fx: 1 },
  Arana:    { vida: 70, vel: 9.0, dano: 15, alcance: 1.3, alto: 1.1, radio: 0.9, puntos: 10, fx: 0.8, nombre: 'Araña' },
  Soldado:  { vida: 180, vel: 6.2, dano: 25, alcance: 1.5, alto: 2.3, radio: 0.65, puntos: 20, fx: 1.4, caja: 0.08 },
  Dron:     { vida: 90, vel: 8.2, dano: 0, alcance: 0, alto: 0.8, radio: 0.9, puntos: 20, fx: 1, vuela: true, caja: 0.05, disparo: { dano: 12, cad: 2.4, alcance: 32 } },
  Tanque:   { vida: 600, vel: 4.1, mata: true, alcance: 1.2, alto: 2.6, radio: 1.9, puntos: 40, fx: 2, caja: 0.15 },
  Chatarra: { vida: 320, vel: 5.7, dano: 35, alcance: 1.8, alto: 3.0, radio: 0.85, puntos: 25, fx: 2, caja: 0.25 },
  Coloso:   { vida: 1000, vel: 4.5, mata: true, alcance: 2.2, alto: 6.8, radio: 1.6, puntos: 80, fx: 3.5, caja: 1, pasos: true },
  Jefe:     { vida: 1500, vel: 3.8, mata: true, alcance: 2.6, alto: 8.6, radio: 2.2, puntos: 150, fx: 4, pasos: true, jefe: true, nombre: 'MEGA-ARDUINO' },
};

// ---------- utilidades de modelado ----------
const RM = {
  M: (c, o = {}) => new THREE.MeshStandardMaterial({ color: c, roughness: o.r ?? 0.45, metalness: o.m ?? 0.55, flatShading: !!o.flat }),
  L: (c, k = 3) => new THREE.MeshBasicMaterial({ color: col(c).multiplyScalar(k) }),
  P(padre, geo, mat, x = 0, y = 0, z = 0) { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = true; padre.add(m); return m; },
  BX: (a, b, c) => new THREE.BoxGeometry(a, b, c),
  CY: (r1, r2, h, s = 10) => new THREE.CylinderGeometry(r1, r2, h, s),
  SP: (r, w = 14, h = 10) => new THREE.SphereGeometry(r, w, h),
  G(padre, x = 0, y = 0, z = 0) { const g = new THREE.Group(); g.position.set(x, y, z); padre.add(g); return g; },

  // humanoide genérico (pies en y=0, mira hacia -z)
  humanoide(o) {
    const { P, BX, CY, G } = RM;
    const raiz = new THREE.Group(), s = o.alto / 2;
    const cuerpo = o.cuerpo, osc = o.oscuro, ojo = o.ojo;
    const torso = G(raiz, 0, 0.95 * s, 0);
    P(torso, BX(0.5 * s, 0.22 * s, 0.32 * s), osc, 0, 0.08 * s, 0);
    const pecho = P(torso, BX((o.ancho || 0.72) * s, 0.62 * s, 0.42 * s), cuerpo, 0, 0.5 * s, 0);
    P(torso, BX(0.3 * s, 0.25 * s, 0.05 * s), osc, 0, 0.5 * s, -0.22 * s);
    const piernas = [], brazos = [];
    for (const lado of [-1, 1]) {
      const p = G(raiz, lado * 0.2 * s, 0.95 * s, 0);
      P(p, BX(0.22 * s, 0.48 * s, 0.25 * s), cuerpo, 0, -0.24 * s, 0);
      P(p, CY(0.09 * s, 0.09 * s, 0.26 * s, 8).rotateZ(Math.PI / 2), osc, 0, -0.5 * s, 0);
      P(p, BX(0.2 * s, 0.42 * s, 0.22 * s), osc, 0, -0.72 * s, 0);
      P(p, BX(0.27 * s, 0.12 * s, 0.38 * s), cuerpo, 0, -0.9 * s, -0.06 * s);
      piernas.push(p);
      const b = G(torso, lado * ((o.ancho || 0.72) / 2 + 0.1) * s, 0.7 * s, 0);
      if (o.hombros) P(b, BX(0.3 * s, 0.18 * s, 0.34 * s), o.hombros, 0, 0.04 * s, 0);
      P(b, BX(0.16 * s, 0.42 * s, 0.17 * s), cuerpo, 0, -0.22 * s, 0);
      P(b, BX(0.15 * s, 0.4 * s, 0.16 * s), osc, 0, -0.58 * s, 0);
      // garras
      for (const k of [-1, 0, 1]) {
        const g = P(b, new THREE.ConeGeometry(0.035 * s, 0.18 * s, 5), o.garra || osc, k * 0.05 * s, -0.86 * s, -0.02 * s);
        g.rotation.x = Math.PI;
      }
      brazos.push(b);
    }
    const cabeza = G(torso, 0, 0.85 * s, 0);
    const cab = P(cabeza, BX(0.42 * s, 0.36 * s, 0.4 * s), o.cabeza || cuerpo, 0, 0.18 * s, 0);
    cab.userData.critico = true;
    const visor = P(cabeza, BX(0.32 * s, 0.08 * s, 0.03 * s), ojo, 0, 0.2 * s, -0.21 * s);
    visor.userData.critico = true;
    P(cabeza, CY(0.012 * s, 0.012 * s, 0.2 * s, 4), osc, 0.12 * s, 0.44 * s, 0);
    P(cabeza, RM.SP(0.035 * s, 6, 4), ojo, 0.12 * s, 0.55 * s, 0);
    return { raiz, partes: { torso, pecho, piernas, brazos, cabeza }, s };
  },
};

// ---------- constructores de cada tipo ----------
const MODELOS = {
  Seguidor() {
    const h = RM.humanoide({ alto: 1.9, cuerpo: RM.M('#d9dee8', { m: 0.3, r: 0.35 }), oscuro: RM.M('#2d3446'), ojo: RM.L('#ff3b3b', 4), ancho: 0.7 });
    RM.P(h.partes.torso, RM.BX(0.2, 0.2, 0.05), RM.L('#36c5ff', 2.5), 0, 0.5 * h.s, -0.24 * h.s);
    return h;
  },
  Soldado() {
    const h = RM.humanoide({ alto: 2.3, cuerpo: RM.M('#5d6b55', { m: 0.5 }), oscuro: RM.M('#262b25'), ojo: RM.L('#ff2a2a', 4), hombros: RM.M('#3f4a3a'), ancho: 0.8 });
    const b = h.partes.brazos[1];
    RM.P(b, RM.CY(0.08, 0.1, 0.5, 10).rotateX(Math.PI / 2), RM.M('#222'), 0, -0.62 * h.s, -0.2);
    RM.P(h.partes.torso, RM.BX(0.5, 0.4, 0.3), RM.M('#3f4a3a'), 0, 0.55 * h.s, 0.3 * h.s);
    return h;
  },
  Chatarra() {
    const oxido = RM.M('#8a4b2a', { m: 0.6, r: 0.8, flat: true }), osc = RM.M('#3b2a22', { r: 0.9 });
    const h = RM.humanoide({ alto: 3.0, cuerpo: oxido, oscuro: osc, ojo: RM.L('#7dff4a', 4), ancho: 0.85, hombros: RM.M('#6b5a4a', { m: 0.7, r: 0.7 }), garra: RM.M('#999', { m: 0.9 }) });
    h.partes.torso.rotation.x = 0.25; // encorvado
    h.partes.brazos[0].scale.set(1, 1.25, 1);
    for (let i = 0; i < 4; i++) RM.P(h.partes.torso, RM.BX(rand(0.1, 0.25), rand(0.1, 0.3), 0.05), RM.M(pick(['#6d6d6d', '#a65f2c', '#4c6b7a']), { m: 0.8 }), rand(-0.3, 0.3), rand(0.4, 1.1), -0.33);
    const cable = RM.L('#7dff4a', 2);
    RM.P(h.partes.torso, RM.CY(0.02, 0.02, 0.6, 4).rotateZ(0.6), cable, 0.2, 0.9, -0.3);
    return h;
  },
  Coloso() {
    const hierro = RM.M('#3a3f4b', { m: 0.7, r: 0.4 }), osc = RM.M('#1c1f26', { m: 0.6 }), lava = RM.L('#ff7a1a', 3);
    const h = RM.humanoide({ alto: 6.8, cuerpo: hierro, oscuro: osc, ojo: lava, ancho: 0.9, hombros: RM.M('#4c5260', { m: 0.8 }), garra: RM.M('#c9ccd3', { m: 0.9 }) });
    const s = h.s;
    for (let i = 0; i < 3; i++) RM.P(h.partes.torso, RM.BX(0.6 * s, 0.03 * s, 0.02 * s), lava, 0, (0.3 + i * 0.18) * s, -0.22 * s);
    RM.P(h.partes.torso, RM.SP(0.12 * s, 10, 8), lava, 0, 0.55 * s, -0.24 * s);
    for (const p of h.partes.piernas) RM.P(p, RM.BX(0.05 * s, 0.3 * s, 0.02 * s), lava, 0, -0.72 * s, -0.12 * s);
    return h;
  },
  Jefe() {
    const pcb = RM.M('#0a6b8c', { m: 0.3, r: 0.4 }), osc = RM.M('#1b2633', { m: 0.6 }), oro = RM.M('#e8c25a', { m: 0.9, r: 0.25 });
    const h = RM.humanoide({ alto: 8.6, cuerpo: RM.M('#14506a', { m: 0.5 }), oscuro: osc, ojo: RM.L('#ff3030', 5), ancho: 1.05, hombros: RM.M('#2b3d4f', { m: 0.7 }), cabeza: RM.M('#111318', { m: 0.4, r: 0.3 }), garra: oro });
    const s = h.s, t = h.partes.torso;
    // placa Arduino en el pecho
    RM.P(t, RM.BX(0.95 * s, 0.66 * s, 0.06 * s), pcb, 0, 0.5 * s, -0.24 * s);
    RM.P(t, RM.BX(0.36 * s, 0.12 * s, 0.05 * s), RM.M('#111'), 0.05 * s, 0.42 * s, -0.29 * s); // ATmega
    RM.P(t, RM.BX(0.22 * s, 0.16 * s, 0.14 * s), RM.M('#c7ccd6', { m: 0.95, r: 0.2 }), -0.36 * s, 0.7 * s, -0.3 * s); // USB
    RM.P(t, RM.BX(0.16 * s, 0.14 * s, 0.14 * s), RM.M('#111'), -0.36 * s, 0.32 * s, -0.3 * s); // jack
    for (let i = 0; i < 10; i++) RM.P(t, RM.BX(0.05 * s, 0.05 * s, 0.05 * s), RM.M('#111'), (-0.3 + i * 0.07) * s, 0.8 * s, -0.29 * s); // pines
    for (let i = 0; i < 8; i++) RM.P(t, RM.BX(0.05 * s, 0.05 * s, 0.05 * s), RM.M('#111'), (-0.1 + i * 0.07) * s, 0.2 * s, -0.29 * s);
    h.partes.led = RM.P(t, RM.BX(0.05 * s, 0.035 * s, 0.03 * s), RM.L('#ffaa00', 5), 0.3 * s, 0.68 * s, -0.29 * s);
    RM.P(t, RM.BX(0.05 * s, 0.035 * s, 0.03 * s), RM.L('#3dff6a', 4), 0.3 * s, 0.6 * s, -0.29 * s);
    // capacitores en los hombros y corona de pines
    for (const lado of [-1, 1]) {
      RM.P(t, RM.CY(0.1 * s, 0.1 * s, 0.3 * s, 12), RM.M('#2756a8', { m: 0.3 }), lado * 0.42 * s, 1.0 * s, 0.1 * s);
      RM.P(t, RM.CY(0.1 * s, 0.1 * s, 0.03 * s, 12), RM.M('#c7ccd6', { m: 0.9 }), lado * 0.42 * s, 1.16 * s, 0.1 * s);
    }
    for (let i = 0; i < 7; i++) RM.P(h.partes.cabeza, RM.BX(0.035 * s, 0.14 * s, 0.035 * s), oro, (-0.18 + i * 0.06) * s, 0.42 * s, 0);
    h.partes.nucleo = RM.P(t, RM.SP(0.09 * s, 12, 8), RM.L('#36c5ff', 3), 0.18 * s, 0.6 * s, -0.27 * s);
    return h;
  },
  Arana() {
    const { P, G } = RM;
    const raiz = new THREE.Group();
    const cuerpo = RM.M('#2a2f3c', { m: 0.7, r: 0.35 }), pata = RM.M('#4a5263', { m: 0.8 }), ojo = RM.L('#ff2244', 5);
    const torso = G(raiz, 0, 0.75, 0);
    P(torso, RM.SP(0.55, 12, 8).scale(1, 0.55, 1.2), cuerpo);
    P(torso, RM.SP(0.4, 10, 8).scale(1, 0.7, 1), RM.M('#3a4255', { m: 0.7 }), 0, 0.05, 0.6);
    const cab = P(torso, RM.SP(0.3, 10, 8), cuerpo, 0, 0.05, -0.65); cab.userData.critico = true;
    for (const [x, y] of [[-0.12, 0.12], [0.12, 0.12], [-0.06, 0.2], [0.06, 0.2]]) { const e = P(torso, RM.SP(0.05, 6, 4), ojo, x, y, -0.88); e.userData.critico = true; }
    const piernas = [];
    for (let i = 0; i < 6; i++) {
      const lado = i < 3 ? -1 : 1, k = i % 3;
      const p = G(torso, lado * 0.4, 0, -0.35 + k * 0.4);
      p.rotation.y = lado * (Math.PI / 2) + (k - 1) * 0.5 * -lado;
      const muslo = G(p);
      muslo.rotation.z = 0; // se anima
      P(muslo, RM.BX(0.08, 0.08, 0.7).translate(0, 0, -0.35).rotateX(-0.7), pata);
      P(muslo, RM.BX(0.07, 0.07, 0.8).translate(0, 0, -0.4).rotateX(0.9).translate(0, 0.45, -0.53), pata);
      piernas.push(muslo);
    }
    return { raiz, partes: { torso, patas: piernas }, s: 1 };
  },
  Dron() {
    const { P, G } = RM;
    const raiz = new THREE.Group();
    const torso = G(raiz);
    const cuerpo = RM.M('#e1e5ee', { m: 0.4, r: 0.3 }), osc = RM.M('#2b303d');
    P(torso, RM.SP(0.45, 14, 10).scale(1, 0.6, 1), cuerpo);
    const ojo = P(torso, RM.SP(0.16, 10, 8), RM.L('#ff2a2a', 5), 0, -0.05, -0.38); ojo.userData.critico = true;
    const helices = [];
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * TAU + Math.PI / 4, x = Math.cos(a) * 0.75, z = Math.sin(a) * 0.75;
      const brazo = P(torso, RM.BX(0.08, 0.06, 0.8), osc, x / 2, 0, z / 2); brazo.rotation.y = -a + Math.PI / 2;
      P(torso, RM.CY(0.08, 0.1, 0.12, 8), osc, x, 0.05, z);
      const hel = G(torso, x, 0.13, z);
      P(hel, RM.BX(0.7, 0.015, 0.08), RM.M('#111', { m: 0.2 }));
      P(hel, RM.BX(0.08, 0.015, 0.7), RM.M('#111', { m: 0.2 }));
      helices.push(hel);
    }
    P(torso, RM.CY(0.05, 0.05, 0.3, 6).rotateX(Math.PI / 2), osc, 0, -0.2, -0.3);
    return { raiz, partes: { torso, helices }, s: 1 };
  },
  Tanque() {
    const { P, G } = RM;
    const raiz = new THREE.Group();
    const verde = RM.M('#55606e', { m: 0.6, r: 0.45 }), osc = RM.M('#1d2129', { m: 0.5, r: 0.7 }), amarillo = RM.M('#f2c230', { m: 0.3 });
    const torso = G(raiz);
    for (const lado of [-1, 1]) {
      P(torso, RM.BX(0.9, 1.0, 3.6), osc, lado * 1.35, 0.55, 0);
      for (let i = 0; i < 5; i++) P(torso, RM.CY(0.38, 0.38, 0.95, 12).rotateZ(Math.PI / 2), RM.M('#3a3f48', { m: 0.7 }), lado * 1.35, 0.45, -1.4 + i * 0.7);
    }
    P(torso, RM.BX(2.3, 0.9, 3.2), verde, 0, 1.3, 0);
    P(torso, RM.BX(2.5, 0.12, 0.3), amarillo, 0, 1.15, -1.62);
    const torreta = G(torso, 0, 1.75, 0.2);
    P(torreta, RM.CY(0.85, 1.0, 0.7, 12), verde, 0, 0.35, 0);
    const cab = P(torreta, RM.BX(0.7, 0.2, 0.05), RM.L('#ff3030', 4), 0, 0.45, -0.85); cab.userData.critico = true;
    P(torreta, RM.CY(0.14, 0.17, 2.0, 10).rotateX(Math.PI / 2), osc, 0, 0.4, -1.6);
    for (let i = 0; i < 3; i++) P(torso, RM.BX(0.25, 0.06, 0.25), RM.L('#ff7a1a', 3), -0.7 + i * 0.7, 1.76, 1.3);
    return { raiz, partes: { torso, torreta }, s: 1 };
  },
};

// =====================================================================
const Robots = {
  vivos: [], balas: [], restos: [], botin: [],

  centroDe(r) { return V3(r.pos.x, r.pos.y + (r.cfg.vuela ? 0 : r.cfg.alto * 0.55), r.pos.z); },
  objetivosRayo() { return this.vivos.map((r) => r.raiz); },

  crear(tipo, x, z, mult = 1) {
    const cfg = TIPOS[tipo];
    const mod = MODELOS[tipo]();
    const r = {
      tipo, cfg, raiz: mod.raiz, partes: mod.partes, s: mod.s,
      vida: cfg.vida * mult, vidaMax: cfg.vida * mult, radio: cfg.radio,
      pos: V3(x, Terreno.altura(x, z), z), yaw: 0, fase: rand(0, 6), ataque: 0, cdAtaque: 0, flash: 0,
      aparecer: 0, esquivar: 0, ladoEsq: 1, cdDisparo: rand(1, 2.5), orbita: rand(0, TAU), altVuelo: rand(6, 9),
      cdOrbes: 4, cdPisoton: 3, cdRayos: 8, cdMisil: 6, furia: false, pasoT: 0, muerto: false, salto: 0,
      mats: [],
    };
    if (cfg.vuela) r.pos.y += r.altVuelo;
    r.centro = () => this.centroDe(r);
    r.raiz.traverse((o) => {
      if (!o.isMesh) return;
      o.userData.robot = r;
      if (o.material.isMeshStandardMaterial && !r.mats.includes(o.material)) { o.material = o.material.clone(); r.mats.push(o.material); }
    });
    r.raiz.position.copy(r.pos);
    r.raiz.scale.setScalar(0.01);
    G.scene.add(r.raiz);
    this.vivos.push(r);
    // efecto de aparición
    const base = V3(x, Terreno.altura(x, z), z);
    FX.segmento(base.clone().setY(base.y + 40), base, 0.4 + cfg.fx * 0.2, '#ff3355', 0.6, 3);
    FX.aro(base, 2 + cfg.fx, '#ff3355', 0.7);
    FX.chispazo(base.clone().setY(base.y + 0.5), '#ff6677', 16, 5);
    Sfx.play('aparece', base.distanceTo(Jugador.pos));
    if (cfg.jefe) HUD.jefe(cfg.nombre, 1);
    return r;
  },

  danar(r, cant, punto, critico) {
    if (r.muerto) return;
    cant = Math.round(cant);
    r.vida -= cant;
    r.flash = 0.09;
    HUD.numero(punto || r.centro(), cant, critico);
    Sfx.play('golpeRobot');
    if (r.cfg.jefe) {
      HUD.jefe(r.cfg.nombre, Math.max(0, r.vida / r.vidaMax));
      if (!r.furia && r.vida < r.vidaMax * 0.5) {
        r.furia = true;
        HUD.anuncio('¡FURIA!', 'El MEGA-ARDUINO se enoja', '#ff5533');
        Sfx.play('jefe'); FX.sacudir(0.8);
        for (const m of r.mats) m.emissive.set('#ff2200');
      }
    }
    if (r.vida <= 0) { this.morir(r); HUD.hit(true); } else HUD.hit(false);
  },

  morir(r) {
    r.muerto = true;
    const c = r.centro();
    FX.explosion(c, 1.2 + r.cfg.fx * 0.9, r.cfg.jefe ? '#ff5522' : '#ffa040');
    Sfx.play('muereRobot', c.distanceTo(Jugador.pos));
    if (r.cfg.fx >= 3.5) { setTimeout(() => FX.explosion(c.clone().add(V3(rand(-2, 2), rand(0, 3), rand(-2, 2))), 3, '#ff7733'), 250); setTimeout(() => FX.explosion(c.clone().add(V3(rand(-2, 2), rand(-1, 2), rand(-2, 2))), 4, '#ffcc55'), 550); }
    // piezas que salen volando
    const piezas = [];
    r.raiz.updateMatrixWorld(true);
    r.raiz.traverse((o) => { if (o.isMesh && o.geometry.type !== 'ConeGeometry') piezas.push(o); });
    const elegidas = piezas.sort(() => Math.random() - 0.5).slice(0, Math.min(10, piezas.length));
    for (const m of elegidas) {
      const wp = V3(), wq = new THREE.Quaternion(), ws = V3();
      m.matrixWorld.decompose(wp, wq, ws);
      const copia = new THREE.Mesh(m.geometry, m.material);
      copia.position.copy(wp); copia.quaternion.copy(wq); copia.scale.copy(ws); copia.castShadow = true;
      G.scene.add(copia);
      const imp = 4 + r.cfg.fx * 2;
      this.restos.push({ m: copia, vel: V3(rand(-imp, imp), rand(3, imp * 1.5), rand(-imp, imp)), giro: V3(rand(-6, 6), rand(-6, 6), rand(-6, 6)), vida: rand(2.5, 4), s0: ws.clone() });
    }
    G.scene.remove(r.raiz);
    this.vivos.splice(this.vivos.indexOf(r), 1);
    // puntos
    const pts = r.cfg.puntos;
    G.puntos += pts; G.bajas++;
    HUD.puntos();
    HUD.feed(`🤖 ${r.cfg.nombre || r.tipo} destruido <b>+${pts}</b>`);
    if (r.cfg.jefe) {
      HUD.jefe(null);
      HUD.anuncio('¡JEFE DERROTADO!', '+' + pts + ' puntos', '#ffcf4a');
      Clima.relampago(V3(r.pos.x, Terreno.altura(r.pos.x, r.pos.z), r.pos.z), true);
    }
    // botín
    const suelo = Terreno.altura(r.pos.x, r.pos.z);
    if (Math.random() < (r.cfg.caja || 0)) this.soltar('caja', V3(r.pos.x, suelo, r.pos.z));
    else if (Math.random() < 0.1) this.soltar('bateria', V3(r.pos.x, suelo, r.pos.z));
  },

  // ---------- botín ----------
  soltar(tipo, pos) {
    const g = new THREE.Group();
    if (tipo === 'caja') {
      RM.P(g, RM.BX(1, 1, 1), RM.M('#a8743f', { m: 0, r: 0.8 }));
      for (const y of [-0.45, 0.45]) RM.P(g, RM.BX(1.04, 0.1, 1.04), RM.M('#5b5f6b', { m: 0.8 }), 0, y, 0);
      for (const [x, z] of [[0, -0.52], [0, 0.52], [-0.52, 0], [0.52, 0]]) RM.P(g, RM.BX(z ? 0.5 : 0.02, 0.5, z ? 0.02 : 0.5), RM.L('#ffcf4a', 2.5), x, 0, z);
    } else {
      RM.P(g, RM.CY(0.25, 0.25, 0.7, 14), RM.M('#2fbf71', { m: 0.4 }));
      RM.P(g, RM.CY(0.12, 0.12, 0.12, 10), RM.M('#d7dde8', { m: 0.9 }), 0, 0.41, 0);
      RM.P(g, RM.BX(0.3, 0.06, 0.06), RM.L('#ffffff', 2.5), 0, 0.1, -0.26);
      RM.P(g, RM.BX(0.06, 0.3, 0.06), RM.L('#ffffff', 2.5), 0, 0.1, -0.26);
    }
    g.position.copy(pos).setY(pos.y + 1);
    G.scene.add(g);
    this.botin.push({ tipo, m: g, pos: pos.clone(), vida: 45, t: rand(0, 6) });
  },

  updateBotin(dt) {
    for (let i = this.botin.length - 1; i >= 0; i--) {
      const b = this.botin[i];
      b.vida -= dt; b.t += dt;
      b.m.position.y = b.pos.y + 1 + Math.sin(b.t * 2.5) * 0.2;
      b.m.rotation.y += dt * 1.5;
      b.m.visible = b.vida > 5 || Math.sin(b.t * 20) > 0;
      if (Math.random() < dt * 4) FX.chispas.emitir(b.pos.x + rand(-0.6, 0.6), b.pos.y + 0.3, b.pos.z + rand(-0.6, 0.6), 0, 1.5, 0, FX.c(b.tipo === 'caja' ? '#ffcf4a' : '#3ee08f', 3), 0.12, 0.8);
      const d = Math.hypot(Jugador.pos.x - b.pos.x, Jugador.pos.z - b.pos.z);
      if (!Jugador.muerto && d < 1.8 && Math.abs(Jugador.pos.y - b.pos.y) < 2.5) {
        Sfx.play('recoger');
        if (b.tipo === 'caja') {
          const faltan = ['escopeta', 'tesla', 'granada'].filter((id) => !Armas.lista.find((a) => a.id === id).tiene);
          if (faltan.length) {
            const id = pick(faltan); Armas.desbloquear(id);
            const a = Armas.lista.find((x) => x.id === id);
            HUD.anuncio(a.icono + ' ' + a.nombre.toUpperCase(), '¡Arma nueva! Tecla ' + (Armas.lista.indexOf(a) + 1), '#ffcf4a');
          } else { Jugador.curar(60); HUD.feed('🔋 Caja de energía <b>+60 vida</b>'); }
        } else { Jugador.curar(30); HUD.feed('🔋 Batería <b>+30 vida</b>'); }
        FX.chispazo(b.m.position, '#ffcf4a', 20, 5);
        G.scene.remove(b.m); this.botin.splice(i, 1); continue;
      }
      if (b.vida <= 0) { G.scene.remove(b.m); this.botin.splice(i, 1); }
    }
  },

  // ---------- proyectiles enemigos ----------
  bala(tipo, pos, vel, dano, o = {}) {
    let m;
    if (tipo === 'orbe') m = new THREE.Mesh(RM.SP(0.45, 12, 8), RM.L('#ff8a2a', 4));
    else if (tipo === 'misil') {
      m = new THREE.Group();
      RM.P(m, RM.CY(0.18, 0.18, 1.2, 10).rotateX(Math.PI / 2), RM.M('#3b3f4a', { m: 0.7 }));
      RM.P(m, new THREE.ConeGeometry(0.18, 0.4, 10).rotateX(-Math.PI / 2), RM.L('#ff3030', 3), 0, 0, -0.8);
    } else m = new THREE.Mesh(RM.SP(0.16, 8, 6).scale(1, 1, 3), RM.L('#ff2a2a', 5));
    m.position.copy(pos);
    G.scene.add(m);
    this.balas.push({ tipo, m, pos: pos.clone(), vel, dano, vida: o.vida || 5, radio: o.radio || 0.4, giro: o.giro || 0 });
  },

  updateBalas(dt) {
    const pj = Jugador.centro();
    for (let i = this.balas.length - 1; i >= 0; i--) {
      const b = this.balas[i];
      b.vida -= dt;
      if (b.tipo === 'misil') {
        // teledirigido
        const deseo = pj.clone().sub(b.pos).normalize().multiplyScalar(b.vel.length());
        b.vel.lerp(deseo, Math.min(1, dt * b.giro)).setLength(16);
        FX.humo.emitir(b.pos.x, b.pos.y, b.pos.z, 0, 0.5, 0, new THREE.Color(0.35, 0.35, 0.35), 0.3, 1, { crece: 1.2, a: 0.5 });
        FX.chispas.emitir(b.pos.x, b.pos.y, b.pos.z, 0, 0, 0, FX.c('#ff7030', 3), 0.35, 0.1);
      } else if (b.tipo === 'orbe') {
        FX.chispas.emitir(b.pos.x, b.pos.y, b.pos.z, rand(-1, 1), rand(-1, 1), rand(-1, 1), FX.c('#ff8a2a', 3), 0.3, 0.25);
      }
      const paso = b.vel.length() * dt, d = b.vel.clone().normalize();
      const dm = rayoMundo(b.pos, d, paso);
      let fin = false;
      if (dm < paso) { b.pos.addScaledVector(d, dm); fin = true; }
      else b.pos.addScaledVector(b.vel, dt);
      b.m.position.copy(b.pos);
      b.m.lookAt(b.pos.clone().sub(b.vel));
      if (!Jugador.muerto && b.pos.distanceTo(pj) < b.radio + 0.6) { Jugador.danar(b.dano, b.pos, b.tipo); fin = true; }
      if (fin || b.vida <= 0) {
        if (b.tipo === 'misil') FX.explosion(b.pos, 3, '#ff6633');
        else if (b.tipo === 'orbe') FX.explosion(b.pos, 1.4, '#ff8a2a');
        else FX.chispazo(b.pos, '#ff3030', 8, 4);
        if (b.tipo === 'misil' && !Jugador.muerto && b.pos.distanceTo(pj) < 3.5 && !(b.pos.distanceTo(pj) < b.radio + 0.6)) Jugador.danar(b.dano * 0.5, b.pos, 'misil');
        G.scene.remove(b.m);
        this.balas.splice(i, 1);
      }
    }
  },

  // ---------- IA ----------
  update(dt) {
    const pj = Jugador.pos;
    for (const r of [...this.vivos]) {
      const cfg = r.cfg;
      r.aparecer = Math.min(1, r.aparecer + dt * 1.6);
      r.raiz.scale.setScalar(Math.max(0.01, smooth(0, 1, r.aparecer)));
      r.flash = Math.max(0, r.flash - dt);
      if (!r.furia) for (const m of r.mats) m.emissive.setScalar(r.flash > 0 ? 0.9 : 0);
      else for (const m of r.mats) m.emissiveIntensity = r.flash > 0 ? 3 : 0.35 + Math.sin(G.t * 8) * 0.15;
      r.cdAtaque -= dt; r.ataque = Math.max(0, r.ataque - dt);

      const objetivo = Jugador.muerto ? V3(0, SUELO, 0) : pj;
      const dx = objetivo.x - r.pos.x, dz = objetivo.z - r.pos.z;
      const dist = Math.hypot(dx, dz) || 0.001;
      const velBase = cfg.vel * (r.furia ? 1.35 : 1) * (r.aparecer < 1 ? 0 : 1);

      if (cfg.vuela) { this.iaDron(r, dt, dist); continue; }

      // dirección deseada + separación de otros robots
      let mx = dx / dist, mz = dz / dist;
      for (const o of this.vivos) {
        if (o === r || o.cfg.vuela) continue;
        const ox = r.pos.x - o.pos.x, oz = r.pos.z - o.pos.z, dd = Math.hypot(ox, oz), min = r.radio + o.radio + 0.3;
        if (dd < min && dd > 0.001) { const k = (min - dd) / min * 2.5; mx += (ox / dd) * k; mz += (oz / dd) * k; }
      }
      if (r.esquivar > 0) { r.esquivar -= dt; mx += -dz / dist * r.ladoEsq * 1.5; mz += dx / dist * r.ladoEsq * 1.5; }
      const ml = Math.hypot(mx, mz) || 1; mx /= ml; mz /= ml;
      const cerca = dist < r.radio + cfg.alcance + Jugador.radio;
      const v = cerca && !cfg.mata ? 0 : velBase;
      const antes = r.pos.clone();
      r.pos.x += mx * v * dt; r.pos.z += mz * v * dt;
      empujarFuera(r.pos, r.radio, Math.max(cfg.alto, 1.5));
      const movido = Math.hypot(r.pos.x - antes.x, r.pos.z - antes.z);
      if (v > 0 && movido < v * dt * 0.35 && r.esquivar <= 0) { r.esquivar = rand(0.6, 1.4); r.ladoEsq = Math.random() < 0.5 ? -1 : 1; }
      const suelo = alturaSuelo(r.pos.x, r.pos.z, r.pos.y, r.radio);
      r.pos.y = suelo > r.pos.y ? damp(r.pos.y, suelo, 18, dt) : Math.max(suelo, r.pos.y - 12 * dt);
      // girar hacia el objetivo
      const yawObj = Math.atan2(-dx, -dz);
      let dy = yawObj - r.yaw; while (dy > Math.PI) dy -= TAU; while (dy < -Math.PI) dy += TAU;
      r.yaw += dy * Math.min(1, dt * (cfg.alto > 5 ? 2.5 : 7));

      // atacar
      const dV = Math.abs(pj.y - r.pos.y);
      if (!Jugador.muerto && cerca && dV < cfg.alto + 0.5) {
        if (cfg.mata) Jugador.danar(999, r.pos, r.tipo);
        else if (r.cdAtaque <= 0) { r.cdAtaque = 1.0; r.ataque = 0.45; Jugador.danar(cfg.dano, r.pos, r.tipo); }
      }
      if (cfg.jefe) this.iaJefe(r, dt, dist);

      // pasos de gigante
      r.fase += movido * (r.tipo === 'Arana' ? 3.2 : 4.2 / r.s);
      if (cfg.pasos) {
        r.pasoT += movido;
        if (r.pasoT > 2.6 * r.s / 1.5) {
          r.pasoT = 0;
          const dj = Math.hypot(pj.x - r.pos.x, pj.z - r.pos.z);
          Sfx.play('pasoGigante', dj); FX.sacudir(clamp(0.35 - dj * 0.012, 0, 0.35));
          FX.humo.emitir(r.pos.x, r.pos.y + 0.2, r.pos.z, 0, 0.5, 0, new THREE.Color(0.55, 0.5, 0.42), 1.5, 1.2, { crece: 3, a: 0.4 });
        }
      }
      this.animar(r, dt, movido / Math.max(dt, 1e-4));
      r.raiz.position.copy(r.pos);
      r.raiz.position.y += r.salto;
      r.raiz.rotation.y = r.yaw;
    }
    this.updateBalas(dt);
    this.updateBotin(dt);
    // piezas sueltas
    for (let i = this.restos.length - 1; i >= 0; i--) {
      const p = this.restos[i];
      p.vida -= dt; p.vel.y -= 20 * dt;
      p.m.position.addScaledVector(p.vel, dt);
      const s = Terreno.altura(p.m.position.x, p.m.position.z);
      if (p.m.position.y < s + 0.1) { p.m.position.y = s + 0.1; p.vel.multiplyScalar(0.5); p.vel.y = Math.abs(p.vel.y) * 0.3; p.giro.multiplyScalar(0.6); }
      p.m.rotation.x += p.giro.x * dt; p.m.rotation.y += p.giro.y * dt; p.m.rotation.z += p.giro.z * dt;
      if (p.vida < 1) p.m.scale.copy(p.s0).multiplyScalar(Math.max(0.01, p.vida));
      if (Math.random() < dt * 3) FX.humo.emitir(p.m.position.x, p.m.position.y, p.m.position.z, 0, 1, 0, new THREE.Color(0.2, 0.2, 0.2), 0.3, 0.8, { crece: 0.8, a: 0.4 });
      if (p.vida <= 0) { G.scene.remove(p.m); this.restos.splice(i, 1); }
    }
  },

  iaDron(r, dt, dist) {
    const pj = Jugador.pos, cfg = r.cfg;
    r.orbita += dt * 0.5;
    const rad = 14;
    const ox = pj.x + Math.cos(r.orbita) * rad, oz = pj.z + Math.sin(r.orbita) * rad;
    const oy = Math.max(Terreno.altura(ox, oz), pj.y) + r.altVuelo + Math.sin(G.t * 1.5 + r.fase) * 0.8;
    const v = cfg.vel * (r.aparecer < 1 ? 0 : 1);
    const d = V3(ox - r.pos.x, oy - r.pos.y, oz - r.pos.z);
    const L = d.length();
    if (L > 0.1) r.pos.addScaledVector(d.divideScalar(L), Math.min(v * dt, L));
    const c = Jugador.centro();
    r.yaw = Math.atan2(-(c.x - r.pos.x), -(c.z - r.pos.z));
    r.raiz.position.copy(r.pos);
    r.raiz.rotation.y = r.yaw;
    r.partes.torso.rotation.x = -0.25 + Math.sin(G.t * 2 + r.fase) * 0.05;
    r.partes.torso.rotation.z = Math.sin(G.t * 1.3 + r.fase) * 0.12;
    for (const h of r.partes.helices) h.rotation.y += dt * 40;
    r.cdDisparo -= dt;
    const dd = r.pos.distanceTo(c);
    if (r.cdDisparo <= 0 && !Jugador.muerto && dd < cfg.disparo.alcance && hayVista(r.pos, c)) {
      r.cdDisparo = cfg.disparo.cad * rand(0.8, 1.2);
      const dir = c.clone().add(V3(Jugador.vel.x, 0, Jugador.vel.z).multiplyScalar(dd / 24 * 0.5)).sub(r.pos).normalize();
      this.bala('rayo', r.pos.clone().addScaledVector(dir, 0.6), dir.multiplyScalar(24), cfg.disparo.dano, { radio: 0.3 });
      Sfx.play('disparoDron', dd);
      FX.luz(r.pos, '#ff3030', 4, 6, 0.1);
    }
  },

  iaJefe(r, dt, dist) {
    const pj = Jugador.centro(), k = r.furia ? 0.65 : 1;
    r.cdOrbes -= dt; r.cdPisoton -= dt; r.cdRayos -= dt; r.cdMisil -= dt;
    r.partes.led.visible = Math.sin(G.t * (r.furia ? 18 : 6)) > 0;
    r.partes.nucleo.scale.setScalar(1 + Math.sin(G.t * 5) * 0.2);
    if (Jugador.muerto || r.aparecer < 1) return;
    const boca = r.centro().add(V3(0, r.cfg.alto * 0.25, 0));
    // orbes en abanico
    if (r.cdOrbes <= 0 && dist < 60) {
      r.cdOrbes = 4 * k; r.ataque = 0.6;
      const base = pj.clone().sub(boca).normalize();
      const n = r.furia ? 7 : 5;
      for (let i = 0; i < n; i++) {
        const a = (i - (n - 1) / 2) * 0.16;
        const d = base.clone().applyAxisAngle(V3(0, 1, 0), a);
        this.bala('orbe', boca.clone().addScaledVector(d, 2), d.multiplyScalar(15), 15, { radio: 0.5, vida: 6 });
      }
      Sfx.play('orbe', dist);
    }
    // pisotón si estás cerca
    if (r.cdPisoton <= 0 && dist < 11) {
      r.cdPisoton = 5 * k;
      r.salto = 0.01; r.saltoV = 9;
    }
    if (r.salto > 0) {
      r.saltoV -= 30 * dt; r.salto += r.saltoV * dt;
      if (r.salto <= 0) {
        r.salto = 0;
        const p = V3(r.pos.x, Terreno.altura(r.pos.x, r.pos.z), r.pos.z);
        FX.aro(p, 12, '#ffaa44', 0.6); FX.aro(p, 8, '#ff5522', 0.5);
        for (let i = 0; i < 30; i++) FX.humo.emitir(p.x + rand(-3, 3), p.y + 0.3, p.z + rand(-3, 3), rand(-8, 8), rand(1, 4), rand(-8, 8), new THREE.Color(0.5, 0.45, 0.38), 2, 1.5, { crece: 3, a: 0.5, roce: 2 });
        Sfx.play('pisoton', dist); FX.sacudir(0.9);
        if (dist < 12 && Jugador.enSuelo) Jugador.danar(35, p, 'pisoton');
      }
    }
    // tormenta eléctrica: círculos de aviso y luego rayos
    if (r.cdRayos <= 0) {
      r.cdRayos = 11 * k;
      HUD.anuncio('⚡ ¡TORMENTA ELÉCTRICA!', 'Sal de los círculos rojos', '#ff7766');
      const n = r.furia ? 7 : 5;
      for (let i = 0; i < n; i++) {
        const p = i === 0 ? Jugador.pos.clone() : Jugador.pos.clone().add(V3(rand(-12, 12), 0, rand(-12, 12)));
        p.y = alturaSuelo(p.x, p.z, p.y + 0.5, 0.3);
        const aviso = new THREE.Mesh(new THREE.RingGeometry(2.6, 3, 40).rotateX(-Math.PI / 2), new THREE.MeshBasicMaterial({ color: col('#ff2a2a').multiplyScalar(2.5), transparent: true, opacity: 0.8, depthWrite: false, side: THREE.DoubleSide }));
        const disco = new THREE.Mesh(new THREE.CircleGeometry(3, 40).rotateX(-Math.PI / 2), new THREE.MeshBasicMaterial({ color: '#ff2a2a', transparent: true, opacity: 0.18, depthWrite: false }));
        aviso.position.copy(p).setY(p.y + 0.12); disco.position.copy(aviso.position);
        G.scene.add(aviso, disco);
        const t0 = G.t, demora = 1.3 + i * 0.12;
        const f = () => {
          const e = G.t - t0;
          aviso.scale.setScalar(1 + Math.sin(e * 20) * 0.04);
          disco.material.opacity = 0.1 + (e / demora) * 0.3;
          if (e >= demora) {
            G.scene.remove(aviso, disco); G.anim.splice(G.anim.indexOf(f), 1);
            Clima.flash = 1;
            FX.rayo(p.clone().add(V3(rand(-8, 8), 80, rand(-8, 8))), p, true);
            Sfx.play('trueno', p.distanceTo(Jugador.pos) * 0.3);
            if (Math.hypot(Jugador.pos.x - p.x, Jugador.pos.z - p.z) < 3.2) Jugador.danar(30, p, 'rayo');
          }
        };
        G.anim.push(f);
      }
    }
    // misil teledirigido si te alejas
    if (r.cdMisil <= 0 && dist > 28) {
      r.cdMisil = 6 * k;
      const d = V3(0, 1, 0).add(pj.clone().sub(boca).normalize()).normalize();
      this.bala('misil', boca.clone().addScaledVector(d, 2), d.multiplyScalar(16), 30, { vida: 7, radio: 0.6, giro: 2.2 });
      HUD.feed('🚀 ¡Misil teledirigido!');
    }
  },

  animar(r, dt, rapidez) {
    const p = r.partes, f = r.fase, mov = clamp(rapidez / Math.max(r.cfg.vel, 0.1), 0, 1);
    if (p.piernas) {
      const amp = 0.65 * mov;
      p.piernas[0].rotation.x = Math.sin(f) * amp;
      p.piernas[1].rotation.x = -Math.sin(f) * amp;
      const atk = r.ataque > 0 || (r.cfg.jefe && r.ataque > 0);
      const brazo = atk ? -1.7 + Math.sin(G.t * 25) * 0.2 : 0;
      p.brazos[0].rotation.x = atk ? brazo : -Math.sin(f) * amp * 0.8;
      p.brazos[1].rotation.x = atk ? brazo : Math.sin(f) * amp * 0.8;
      p.torso.position.y = 0.95 * r.s + Math.abs(Math.cos(f)) * 0.04 * r.s * mov;
      p.cabeza.rotation.y = Math.sin(G.t * 0.7 + r.fase) * 0.25;
      if (r.tipo === 'Chatarra') p.torso.rotation.z = Math.sin(f * 0.5) * 0.12;
    } else if (p.patas) {
      p.patas.forEach((m, i) => { const s = i % 2 ? 1 : -1; m.rotation.x = Math.sin(f + i) * 0.35 * mov * s; m.rotation.y = Math.cos(f + i) * 0.25 * mov; });
      p.torso.position.y = 0.75 + Math.abs(Math.sin(f * 2)) * 0.06 * mov;
    } else if (p.torreta) {
      const pj = Jugador.pos;
      const yawT = Math.atan2(-(pj.x - r.pos.x), -(pj.z - r.pos.z)) - r.yaw;
      p.torreta.rotation.y = damp(p.torreta.rotation.y, yawT, 3, dt);
      p.torso.position.y = Math.sin(G.t * 30) * 0.015 * mov;
    }
  },

  limpiar() {
    for (const r of this.vivos) G.scene.remove(r.raiz);
    for (const b of this.balas) G.scene.remove(b.m);
    this.vivos = []; this.balas = [];
    HUD.jefe(null);
  },
};

// =====================================================================
//  OLEADAS (mismo ritmo que el juego de Roblox)
// =====================================================================
const Oleadas = {
  n: 0, fase: 'espera', cuenta: 10, cola: [], genT: 0, tipo: 'normal', MAX_VIVOS: 18, DESCANSO: 12,

  iniciar() { this.n = 0; this.fase = 'descanso'; this.cuenta = 10; Clima.poner('dia'); },

  componer() {
    const n = this.n, cola = [];
    const pesos = [['Seguidor', 6], ['Arana', 4]];
    if (n >= 2) pesos.push(['Soldado', 3], ['Chatarra', 2], ['Tanque', 1]);
    if (n >= 5) pesos.push(['Dron', 2]);
    const total = pesos.reduce((s, p) => s + p[1], 0);
    const elegir = () => { let x = Math.random() * total; for (const [t, w] of pesos) { x -= w; if (x <= 0) return t; } return 'Seguidor'; };
    if (this.tipo === 'jefe') {
      cola.push('Jefe');
      for (let i = 0; i < 4 + n * 2; i++) cola.push(elegir());
      if (n >= 6) cola.push('Coloso');
    } else if (this.tipo === 'drones') {
      for (let i = 0; i < 6 + n * 2; i++) cola.push(i % 4 === 3 ? 'Arana' : 'Dron');
    } else {
      for (let i = 0; i < Math.min(6 + n * 3, 40); i++) cola.push(elegir());
      if (n >= 5) { cola.splice(randi(2, 6), 0, 'Coloso'); if (n >= 8) cola.push('Coloso'); }
    }
    return cola;
  },

  empezar() {
    this.n++;
    this.tipo = this.n % 3 === 0 ? 'jefe' : this.n % 4 === 0 ? 'drones' : 'normal';
    this.cola = this.componer();
    this.fase = 'oleada'; this.genT = 1.5;
    if (this.n === 1) { Mapa.quitarRejas(); HUD.feed('🔓 ¡Se abrieron las rejas!'); }
    Clima.poner(this.tipo === 'jefe' ? 'tormenta' : this.tipo === 'drones' ? 'niebla' : 'noche');
    if (this.tipo === 'jefe') { HUD.anuncio('⚠ OLEADA ' + this.n + ' ⚠', '¡Llega el MEGA-ARDUINO!', '#ff6a3c'); Sfx.play('jefe'); FX.sacudir(0.6); }
    else if (this.tipo === 'drones') { HUD.anuncio('OLEADA ' + this.n, '¡Enjambre de drones!', '#9fe6a0'); Sfx.play('oleada'); }
    else { HUD.anuncio('OLEADA ' + this.n, this.n === 1 ? 'Los robots de ARDUNOL atacan' : this.cola.includes('Coloso') ? '¡Cuidado con el COLOSO!' : 'Más robots en camino', '#36c5ff'); Sfx.play('oleada'); }
  },

  puntoAparicion(vuela) {
    for (let k = 0; k < 40; k++) {
      const a = Math.random() * TAU, r = Terreno.borde(a) - rand(18, 26);
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      if (Terreno.altura(x, z) < 1) continue;
      if (Math.hypot(x - Jugador.pos.x, z - Jugador.pos.z) < 35) continue;
      if (!vuela && G.cajas.some((c) => x > c.min.x - 2 && x < c.max.x + 2 && z > c.min.z - 2 && z < c.max.z + 2)) continue;
      return [x, z];
    }
    return [0, -110];
  },

  update(dt) {
    if (this.fase === 'descanso') {
      this.cuenta -= dt;
      HUD.oleada(this.n === 0 ? 'PREPÁRATE' : 'DESCANSO', (this.n === 0 ? 'Las rejas se abren en ' : 'La oleada ' + (this.n + 1) + ' llega en ') + Math.ceil(this.cuenta) + ' s');
      if (this.cuenta <= 0) this.empezar();
      return;
    }
    if (this.fase === 'oleada') {
      this.genT -= dt;
      const mult = 1 + (this.n - 1) * 0.06;
      if (this.cola.length && this.genT <= 0 && Robots.vivos.length < this.MAX_VIVOS) {
        const tipo = this.cola.shift();
        const [x, z] = this.puntoAparicion(TIPOS[tipo].vuela);
        const r = Robots.crear(tipo, x, z, mult);
        if (tipo === 'Coloso') HUD.anuncio('¡COLOSO!', 'Si te toca, caes. Mantén distancia', '#ff9a3c');
        this.genT = tipo === 'Jefe' ? 3 : rand(0.5, 1.1);
        if (tipo === 'Jefe') r.yaw = Math.atan2(x, z);
      }
      const quedan = this.cola.length + Robots.vivos.length;
      HUD.oleada('OLEADA ' + this.n, '🤖 ' + quedan + ' robots restantes');
      if (quedan === 0) {
        const bono = 20 * this.n;
        G.puntos += bono; HUD.puntos();
        HUD.anuncio('¡OLEADA SUPERADA!', '+' + bono + ' puntos de bonus', '#3ee08f');
        Jugador.curar(40);
        this.fase = 'descanso'; this.cuenta = this.DESCANSO;
        Clima.poner('dia');
      }
    }
  },
};
