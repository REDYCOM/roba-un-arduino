// =====================================================================
//  JEFE FINAL (oleada 8): ARDUNOL DESATADO en su mech de guerra
//  Modelo: Mech Robot "KW-II" de nick_bragg (Sketchfab) — licencia CC BY 4.0
//  (comprimido con herramientas/modelos → web/modelos/jefe-final.glb)
//  Trae esqueleto y animación de caminar; los ataques se programan aquí:
//   - ametralladoras giratorias en los dos brazos
//   - cañones que lanzan misiles teledirigidos
//   - láser de barrido desde las cámaras (sus ojos)
//   - entrada cayendo del cielo y caída final con explosiones
// =====================================================================
const Mech = {
  ALTO: 13,          // metros de alto en el juego
  gltf: null, listo: false,

  cargar() {
    const loader = new ADD.GLTFLoader();
    loader.setMeshoptDecoder(ADD.MeshoptDecoder);
    return loader.loadAsync('modelos/jefe-final.glb')
      .then((g) => { this.gltf = g; this.listo = true; })
      .catch((e) => console.warn('No se pudo cargar el jefe final (se usa el provisorio):', e));
  },

  // devuelve un "mod" compatible con los robots de modelos-robots.js
  construir() {
    const escena = ADD.SkeletonUtils.clone(this.gltf.scene);
    const raiz = new THREE.Group(), cuerpo = new THREE.Group(), giro = new THREE.Group();
    raiz.add(cuerpo); cuerpo.add(giro); giro.add(escena);
    const mats = new Map();
    const sinRayo = () => {};
    escena.traverse((o) => {
      if (!o.isMesh) return;
      o.castShadow = true; o.receiveShadow = true;
      o.frustumCulled = false;       // la caja de la pose original no sigue a la animación
      o.raycast = sinRayo;           // los disparos pegan en cajas invisibles (mucho más rápido)
      if (!mats.has(o.material)) {
        const m = o.material.clone();
        if (m.emissiveMap) { m.emissive.set('#ffffff'); m.emissiveIntensity = 1.8; } else m.emissive.set('#000000');
        mats.set(o.material, m);
      }
      o.material = mats.get(o.material);
    });
    const hueso = (re) => { let h = null; escena.traverse((o) => { if (!h && o.isBone && re.test(o.name)) h = o; }); return h; };
    const H = {
      camaras: hueso(/DEF-CAMERAS-BASE/), minigunL: hueso(/DEF-MINIGUN\.?L/), minigunR: hueso(/DEF-MINIGUN\.?R/),
      canonL: hueso(/DEF-CANON\.?L/), canonR: hueso(/DEF-CANON\.?R/),
    };

    // tamaño: ALTO metros, apoyado en el suelo y centrado
    raiz.updateMatrixWorld(true);
    let bb = new THREE.Box3().setFromObject(escena);
    escena.scale.multiplyScalar(this.ALTO / (bb.max.y - bb.min.y));
    raiz.updateMatrixWorld(true);
    bb = new THREE.Box3().setFromObject(escena);
    const c = bb.getCenter(V3());
    escena.position.x -= c.x; escena.position.z -= c.z; escena.position.y -= bb.min.y;
    raiz.updateMatrixWorld(true);
    // los robots del juego miran hacia -Z: si sus ojos quedan hacia +Z, se gira
    const pOjos = H.camaras ? H.camaras.getWorldPosition(V3()) : V3(0, this.ALTO, -1);
    if (pOjos.z > 0) giro.rotation.y = Math.PI;
    raiz.updateMatrixWorld(true);
    bb = new THREE.Box3().setFromObject(escena);
    const ancho = bb.max.x - bb.min.x, prof = bb.max.z - bb.min.z, alto = bb.max.y - bb.min.y;

    // puntos de disparo (en el espacio del cuerpo, para que sigan saltos y giros)
    const local = (h, def) => (h ? cuerpo.worldToLocal(h.getWorldPosition(V3())) : def);
    const frente = bb.min.z - 0.3;
    const boca = (h, lado) => { const p = local(h, V3(lado * ancho * 0.4, alto * 0.55, 0)); p.z = frente; return p; };
    const puntos = {
      minigun: [boca(H.minigunL, -1), boca(H.minigunR, 1)],
      canon: [boca(H.canonL, -1), boca(H.canonR, 1)],
      ojos: local(H.camaras, V3(0, alto * 0.85, bb.min.z * 0.6)),
    };
    for (const p of puntos.canon) p.y += 0.6; // los cañones van un poco más arriba que las ametralladoras

    // cajas invisibles para recibir disparos (la cabeza es crítico)
    const matCaja = new THREE.MeshBasicMaterial({ visible: false });
    const caja = (w, h, d, x, y, z, critico) => {
      const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), matCaja);
      m.position.set(x, y, z); m.userData.noResto = true; m.userData.critico = !!critico;
      cuerpo.add(m);
    };
    caja(ancho * 0.5, alto * 0.48, prof * 0.55, 0, alto * 0.24, 0);
    caja(ancho * 0.95, alto * 0.38, prof * 0.8, 0, alto * 0.64, 0);
    caja(3.2, 2.4, 3.2, puntos.ojos.x, puntos.ojos.y, puntos.ojos.z, true);

    // animación de caminar (esqueleto del modelo)
    const mixer = new THREE.AnimationMixer(escena);
    const clip = this.gltf.animations.find((a) => /walk/i.test(a.name)) || this.gltf.animations[0];
    const caminar = clip ? mixer.clipAction(clip) : null;
    if (caminar) caminar.play();

    return {
      raiz, cuerpo, segs: {}, partes: {}, mats: [...mats.values()], spec: { anim: 'mech', escala: 1, pasoFreq: 4 },
      med: { alto, ancho: Math.max(ancho, prof) * 0.8, minY: 0, maxY: alto }, ojos: [],
      mech: { mixer, caminar, puntos, H, escena },
    };
  },

  // estado inicial de los ataques del mech (se guarda en el robot)
  preparar(r) {
    r.mech = r.mod.mech;
    Object.assign(r, { cdMetralla: 3, rafaga: 0, cadRafaga: 0, ladoBala: 0, cdCanon: 6, cdLaser: 9, laser: null });
  },

  brillo(r) {
    const furia = r.furia;
    for (const m of r.mats) {
      if (!m.emissiveMap) {
        // piezas sin luces propias: solo destellan al recibir un golpe (o rojo tenue con furia)
        m.emissive.set(r.flash > 0 ? '#ffffff' : furia ? '#ff1020' : '#000000');
        m.emissiveIntensity = r.flash > 0 ? 0.6 : furia ? 0.12 + Math.sin(G.t * 9) * 0.06 : 0;
        continue;
      }
      m.emissive.set(furia ? '#ff2a3a' : '#ffffff');
      m.emissiveIntensity = r.flash > 0 ? 4.5 : furia ? 2.6 + Math.sin(G.t * 9) * 0.9 : 1.8 + Math.sin(G.t * 2.5) * 0.35;
    }
  },

  animar(r, dt, rapidez) {
    const m = r.mech;
    const ritmo = clamp(rapidez / Math.max(r.cfg.vel, 0.1), 0, 1.6);
    // camina al ritmo del movimiento; quieto respira despacio
    m.mixer.timeScale = damp(m.mixer.timeScale, r.rafaga > 0 ? 0.25 : Math.max(0.18, ritmo * 1.1), 6, dt);
    m.mixer.update(dt);
    // apuntar: inclina el cuerpo hacia el jugador cuando está arriba o abajo
    const dy = (r.obj || Jugador).pos.y - r.pos.y;
    if (!r.brinco) r.mod.cuerpo.rotation.x = damp(r.mod.cuerpo.rotation.x, clamp(dy * 0.01, -0.08, 0.08), 3, dt);
  },

  mundo(r, p) { return r.mod.cuerpo.localToWorld(p.clone()); },

  ataques(r, dt, dist) {
    const pj = OBJ.centro(), k = r.furia ? 0.65 : 1;
    r.cdMetralla -= dt; r.cdCanon -= dt; r.cdLaser -= dt;
    const vista = hayVista(this.mundo(r, r.mech.puntos.ojos), pj);

    // ---- ametralladoras: ráfaga alternando brazos ----
    if (r.rafaga <= 0 && r.cdMetralla <= 0 && dist < 70 && vista && !r.laser) {
      r.rafaga = r.furia ? 3 : 2.2; r.cdMetralla = 5.5 * k; r.cadRafaga = 0.5; // medio segundo de "giro" antes de disparar
      Sfx.play('metralla', dist * 0.5);
      HUD.feed('⚠ ¡Ametralladoras del mech!');
    }
    if (r.rafaga > 0) {
      r.rafaga -= dt; r.cadRafaga -= dt;
      const boca = this.mundo(r, r.mech.puntos.minigun[r.ladoBala]);
      if (Math.random() < dt * 30) FX.chispas.emitir(boca.x, boca.y, boca.z, rand(-1, 1), rand(-1, 1), rand(-1, 1), FX.c('#ffb347', 3), 0.12, 0.15);
      if (r.cadRafaga <= 0) {
        r.cadRafaga = r.furia ? 0.07 : 0.1;
        r.ladoBala = 1 - r.ladoBala;
        const d = pj.clone().add(V3(rand(-1.2, 1.2), rand(-0.6, 0.8), rand(-1.2, 1.2))).sub(boca).normalize();
        this.balaMech(boca, d);
        if (Math.random() < 0.5) Sfx.play('disparoDron', dist * 0.6);
      }
    }

    // ---- cañones: misiles teledirigidos ----
    if (r.cdCanon <= 0 && dist > 10 && dist < 90) {
      r.cdCanon = 8 * k;
      const n = r.furia ? 4 : 2;
      for (let i = 0; i < n; i++) {
        setTimeout(() => {
          if (r.muerto) return;
          const boca = this.mundo(r, r.mech.puntos.canon[i % 2]);
          const d = V3(rand(-0.4, 0.4), 1, 0).add((r.obj || Jugador).centro().sub(boca).normalize()).normalize();
          Robots.bala('misil', boca, d.multiplyScalar(16), 22, { vida: 7, radio: 0.6, giro: 2 });
          FX.luz(boca, '#ff7030', 30, 12, 0.15); FX.chispazo(boca, '#ffaa44', 14, 6);
          Sfx.play('bazuca', dist * 0.5);
        }, i * 280);
      }
      HUD.feed('🚀 ¡Misiles de los cañones!');
    }

    // ---- láser de barrido desde los ojos ----
    if (!r.laser && r.cdLaser <= 0 && dist < 55 && r.rafaga <= 0) {
      r.cdLaser = (r.furia ? 9 : 14) * k;
      const lado = V3(-(pj.z - r.pos.z), 0, pj.x - r.pos.x).normalize().multiplyScalar(r.furia ? 14 : 11);
      if (Math.random() < 0.5) lado.negate();
      r.laser = { t: 0, a: OBJ.pos.clone().add(lado), b: OBJ.pos.clone().sub(lado), cdDano: 0, punto: null };
      HUD.anuncio('🔴 ¡LÁSER!', 'Salta o aléjate de la línea roja', '#ff4466');
      Sfx.play('laser', dist * 0.3);
    }
    if (r.laser) this.updateLaser(r, dt);
  },

  updateLaser(r, dt) {
    const L = r.laser, AVISO = 1.0, BARRIDO = r.furia ? 1.6 : 2.2;
    L.t += dt; L.cdDano -= dt;
    const ojos = this.mundo(r, r.mech.puntos.ojos);
    const u = clamp((L.t - AVISO) / BARRIDO, 0, 1);
    const p = L.a.clone().lerp(L.b, smooth(0, 1, u));
    p.y = alturaSuelo(p.x, p.z, Math.max(p.y, r.pos.y) + 6, 0.2);
    L.punto = p;
    if (L.t < AVISO) {
      // aviso: rayo fino que parpadea
      if (Math.sin(G.t * 40) > 0) FX.segmento(ojos, p, 0.05, '#ff2040', 0.03, 4);
      return;
    }
    FX.segmento(ojos, p, 0.32, '#ff2040', 0.04, 6);
    FX.luz(p, '#ff2040', 40, 10, 0.05);
    if (Math.random() < dt * 40) FX.chispas.emitir(p.x, p.y + 0.1, p.z, rand(-3, 3), rand(2, 6), rand(-3, 3), FX.c('#ff6a3c', 3), 0.2, 0.5);
    if (Math.random() < dt * 8) Destruibles.explosion(p, 1.5);
    // daño: el jugador cerca del punto de impacto o atravesado por el rayo
    L.punto = p; // para dibujarlo en las pantallas de los alumnos
    if (L.cdDano <= 0) for (const j of jugadoresVivos()) {
      if (Math.hypot(j.pos.x - p.x, j.pos.z - p.z) < 1.8 && Math.abs(j.pos.y - p.y) < 1.6) { L.cdDano = 0.35; j.danar(r.furia ? 22 : 16, p, 'laser'); }
    }
    if (u >= 1) r.laser = null;
  },

  balaMech(boca, d) {
    Robots.bala('rayo', boca, d.multiplyScalar(38), 6, { radio: 0.3, vida: 3 });
    FX.luz(boca, '#ffb347', 12, 8, 0.05);
  },

  // entrada: cae del cielo como un meteorito
  entrada(r) {
    const y1 = Terreno.altura(r.pos.x, r.pos.z);
    r.brinco = { t: 0, dur: 2.6, x0: r.pos.x, z0: r.pos.z, y0: y1 + 90, x1: r.pos.x, z1: r.pos.z, y1, alto: 0, golpe: true, caida: true };
    r.pos.y = y1 + 90;
    HUD.anuncio('☠ OLEADA FINAL ☠', 'Llega el robot de ARDUNOL con el ARDUINO SUPREMO', '#ff3355');
  },

  aterrizar(r) {
    const p = V3(r.pos.x, Terreno.altura(r.pos.x, r.pos.z), r.pos.z);
    FX.aro(p, 26, '#ff2040', 1.0); FX.aro(p, 16, '#ffaa44', 0.8);
    FX.explosion(p.clone().setY(p.y + 1), 5, '#ff4422');
    Clima.relampago(p, true);
    Destruibles.explosion(p, 14);
    FX.sacudir(1.4);
    HUD.anuncio('¡ARDUNOL DESATADO!', 'Destrúyelo y roba el ARDUINO', '#ff3355');
    Sfx.play('jefe');
    for (const j of jugadoresVivos()) if (Math.hypot(j.pos.x - p.x, j.pos.z - p.z) < 16) j.danar(30, p, 'pisoton');
  },

  // muerte: se tambalea, explota por partes y cae
  caer(r) {
    const raiz = r.raiz, t0 = G.t, DUR = 3.2, lado = Math.random() < 0.5 ? -1 : 1;
    const base = raiz.position.clone(), alto = r.cfg.alto;
    r.mech.mixer.timeScale = 0.05;
    const f = () => {
      const e = (G.t - t0) / DUR;
      r.mech.mixer.update(0.016);
      raiz.rotation.z = lado * smooth(0.25, 1, e) * 1.45;
      raiz.position.y = base.y - smooth(0.6, 1, e) * 1.5;
      raiz.position.x = base.x + Math.sin(G.t * 40) * 0.08 * (1 - e);
      if (Math.random() < 0.22) {
        const p = r.mod.cuerpo.localToWorld(V3(rand(-4, 4), rand(1, alto), rand(-3, 3)));
        FX.explosion(p, rand(1.5, 3.5), pick(['#ff5522', '#ffaa33', '#ff2040']));
        Sfx.play('explosionChica', p.distanceTo(Jugador.pos) * 0.5);
      }
      if (e >= 1) {
        G.anim.splice(G.anim.indexOf(f), 1);
        const p = raiz.position.clone().setY(base.y + 2);
        FX.explosion(p, 9, '#ffcc55'); FX.aro(p, 30, '#ffcf4a', 1.2); FX.sacudir(1.5);
        Sfx.play('explosion');
        Destruibles.explosion(p, 12);
        G.scene.remove(raiz);
      }
    };
    G.anim.push(f);
  },
};
