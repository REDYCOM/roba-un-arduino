// =====================================================================
//  AMETRALLADORA FIJA (una al lado de cada base)
//  - Acércate y pulsa [E] para subirte; [E] o [Espacio] para bajarte.
//  - Dispara seguido mientras mantienes el clic. Se recalienta: si llega
//    al máximo se traba unos segundos hasta enfriarse.
// =====================================================================
const Torretas = {
  lista: [], montada: null, calor: 0, trabada: false, enfriar: 0, retroceso: 0,
  CAD: 0.075, DANO: 16, ALCANCE: 180, CALOR_TIRO: 0.016, ENFRIA: 0.38,

  crear(eq, x, z, yaw, destino) {
    const y = Terreno.altura(x, z);
    const g = new THREE.Group(); g.position.set(x, y, z);
    const M = (c, o = {}) => new THREE.MeshStandardMaterial({ color: c, metalness: o.m ?? 0.7, roughness: o.r ?? 0.35 });
    const L = (c, k = 2.5) => new THREE.MeshBasicMaterial({ color: col(c).multiplyScalar(k) });
    const P = (padre, geo, mat, px = 0, py = 0, pz = 0) => { const m = new THREE.Mesh(geo, mat); m.position.set(px, py, pz); m.castShadow = true; m.receiveShadow = true; padre.add(m); return m; };
    const acero = M('#3a3f4a'), oscuro = M('#1d2027'), equipo = M(eq.color, { m: 0.3, r: 0.5 });
    // plataforma con escalón y anillo de luz
    P(g, new THREE.CylinderGeometry(1.6, 1.75, 0.45, 20), M('#5d6068', { m: 0.2, r: 0.8 }), 0, 0.22, 0);
    P(g, new THREE.TorusGeometry(1.62, 0.05, 6, 40).rotateX(Math.PI / 2), L(eq.color, 2.2), 0, 0.46, 0);
    P(g, new THREE.CylinderGeometry(0.32, 0.42, 0.75, 14), acero, 0, 0.82, 0);
    // cabeza que gira (yaw) y cañón que sube/baja (pitch)
    const giroY = new THREE.Group(); giroY.position.y = 1.25; g.add(giroY);
    P(giroY, new THREE.CylinderGeometry(0.45, 0.45, 0.18, 16), oscuro, 0, -0.02, 0);
    const pitch = new THREE.Group(); pitch.position.y = 0.2; giroY.add(pitch);
    P(pitch, new THREE.BoxGeometry(0.46, 0.38, 0.85), acero, 0, 0, -0.05);
    P(pitch, new THREE.BoxGeometry(0.48, 0.1, 0.5), equipo, 0, 0.23, 0.05);
    // escudo con franja del equipo
    const escudo = P(pitch, new THREE.BoxGeometry(1.1, 0.62, 0.06), acero, 0, 0.12, -0.42); escudo.rotation.x = -0.2;
    P(escudo, new THREE.BoxGeometry(1.12, 0.1, 0.07), L(eq.color, 2), 0, 0.18, 0);
    // caja de munición y cinta de balas
    P(pitch, new THREE.BoxGeometry(0.3, 0.32, 0.42), M('#4f5a2e', { m: 0.3, r: 0.6 }), 0.4, -0.08, 0.02);
    for (let i = 0; i < 5; i++) P(pitch, new THREE.CylinderGeometry(0.025, 0.025, 0.12, 6).rotateZ(Math.PI / 2), M('#d8a83a', { m: 0.9, r: 0.3 }), 0.3 - i * 0.05, 0.05, -0.08 + i * 0.01);
    // cañones giratorios (tipo gatling)
    const barriles = new THREE.Group(); barriles.position.set(0, 0, -0.55); pitch.add(barriles);
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU;
      P(barriles, new THREE.CylinderGeometry(0.035, 0.035, 1.15, 8).rotateX(Math.PI / 2), oscuro, Math.cos(a) * 0.09, Math.sin(a) * 0.09, -0.55);
    }
    P(barriles, new THREE.CylinderGeometry(0.16, 0.16, 0.08, 14).rotateX(Math.PI / 2), acero, 0, 0, -0.25);
    P(barriles, new THREE.CylinderGeometry(0.16, 0.16, 0.08, 14).rotateX(Math.PI / 2), acero, 0, 0, -1.05);
    const boca = new THREE.Object3D(); boca.position.set(0, 0, -1.15); barriles.add(boca);
    // manijas atrás
    for (const s of [-1, 1]) {
      P(pitch, new THREE.BoxGeometry(0.05, 0.05, 0.3), acero, s * 0.2, -0.02, 0.48);
      P(pitch, new THREE.CylinderGeometry(0.04, 0.04, 0.18, 8), M('#151515', { m: 0, r: 0.9 }), s * 0.2, -0.08, 0.62);
    }
    // luz de estado (verde = lista, rojo = recalentada)
    const led = P(pitch, new THREE.SphereGeometry(0.035, 8, 6), L('#3ee08f', 3), 0.2, 0.2, 0.12);
    g.rotation.y = 0;
    giroY.rotation.y = yaw;
    destino.push(g);
    // colisión de la plataforma (se sube caminando)
    agregarCaja(x - 1.5, y, z - 1.5, x + 1.5, y + 0.45, z + 1.5);
    agregarCaja(x - 0.35, y + 0.45, z - 0.35, x + 0.35, y + 1.6, z + 0.35, { sinBala: true });
    const t = { eq, g, giroY, pitch, barriles, boca, led, pos: V3(x, y, z), yawBase: yaw, yaw, pit: 0, giro: 0 };
    this.lista.push(t);
    return t;
  },

  // dónde se para el jugador cuando la usa (detrás de las manijas)
  asiento(t, yaw = t.yaw) {
    return V3(t.pos.x + Math.sin(yaw) * 1.05, t.pos.y + 0.45, t.pos.z + Math.cos(yaw) * 1.05);
  },

  update(dt) {
    if (this.montada) return;
    let cerca = null;
    if (!Jugador.muerto) for (const t of this.lista) {
      if (Math.hypot(Jugador.pos.x - t.pos.x, Jugador.pos.z - t.pos.z) < 2.6) { cerca = t; break; }
    }
    if (cerca) G.aviso = 'Pulsa <kbd>E</kbd> para usar la ametralladora';
    if (cerca && Input.pulso('KeyE') && G.t - (this.bajoEn || -9) > 0.4) this.subir(cerca);
    // las que nadie usa se enfrían y vuelven a mirar al frente
    for (const t of this.lista) {
      t.yaw = damp(t.yaw, t.yawBase + Math.sin(G.t * 0.4 + t.pos.x) * 0.5, 1.5, dt);
      t.pit = damp(t.pit, 0, 2, dt);
      t.giroY.rotation.y = t.yaw; t.pitch.rotation.x = t.pit;
    }
    this.calor = Math.max(0, this.calor - dt * this.ENFRIA);
  },

  subir(t) {
    this.montada = t;
    t.yaw = Jugador.yaw = t.yawBase; Jugador.pitch = 0;
    Jugador.vel.set(0, 0, 0); Jugador.empuje.set(0, 0, 0);
    Jugador.pos.copy(this.asiento(t));
    Sfx.play('recoger');
    HUD.feed('🔫 Ametralladora lista. <b>[E]</b> para bajarte');
    document.getElementById('armaNombre').textContent = 'AMETRALLADORA';
  },

  bajar() {
    const t = this.montada; if (!t) return;
    this.montada = null; this.bajoEn = G.t;
    // te deja parado detrás de la plataforma
    const p = this.asiento(t);
    Jugador.pos.set(t.pos.x + Math.sin(t.yaw) * 2.1, alturaSuelo(t.pos.x + Math.sin(t.yaw) * 2.1, t.pos.z + Math.cos(t.yaw) * 2.1, p.y + 1, 0.4), t.pos.z + Math.cos(t.yaw) * 2.1);
    HUD.arma();
  },

  // cuadro a cuadro mientras estás arriba (reemplaza al movimiento normal)
  updateMontada(dt) {
    const t = this.montada;
    if (Jugador.muerto) { this.bajar(); Jugador.update(dt); return; }
    if (Input.pulso('KeyE') || Input.pulso('Space')) { this.bajar(); return; }
    // apuntar con el mouse
    Jugador.yaw -= Input.dx * Jugador.sens;
    Jugador.pitch = clamp(Jugador.pitch - Input.dy * Jugador.sens, -0.45, 0.6);
    t.yaw = Jugador.yaw; t.pit = Jugador.pitch;
    t.giroY.rotation.y = t.yaw; t.pitch.rotation.x = t.pit;
    Jugador.pos.copy(this.asiento(t));
    Jugador.invulnerable = Math.max(0, Jugador.invulnerable - dt);
    if (G.t - Jugador.ultimoDano > 6) Jugador.curar(dt * 6);
    // disparar
    this.enfriar -= dt;
    if (this.trabada && this.calor < 0.3) { this.trabada = false; HUD.feed('✅ Ametralladora fría'); }
    const disparando = Input.mouseAbajo && Input.bloqueado && !this.trabada;
    t.giro = damp(t.giro, disparando ? 40 : 0, 4, dt);
    t.barriles.rotation.z += t.giro * dt;
    while (disparando && this.enfriar <= 0) { this.enfriar += this.CAD * G.mods.cad; this.disparar(t); }
    if (!disparando) this.enfriar = Math.max(this.enfriar, 0);
    this.calor = Math.max(0, this.calor - dt * this.ENFRIA * (disparando ? 0.2 : 1));
    if (this.calor >= 0.97 && !this.trabada) { this.trabada = true; Sfx.play('sinMunicion'); HUD.anuncio('🔥 ¡RECALENTADA!', 'Espera a que se enfríe', '#ff7a3c'); }
    t.led.material.color.copy(col(this.trabada ? '#ff3030' : this.calor > 0.7 ? '#ffb030' : '#3ee08f')).multiplyScalar(3);
    this.retroceso = damp(this.retroceso, 0, 18, dt);
    // cámara detrás de las manijas
    const cam = G.camera;
    const sh = FX.sacudida * FX.sacudida;
    // un poco más atrás y arriba que el jugador: se ve el arma sin tapar la vista
    cam.position.set(t.pos.x + Math.sin(t.yaw) * 1.45, t.pos.y + 2.2 + this.retroceso * 0.02, t.pos.z + Math.cos(t.yaw) * 1.45);
    cam.rotation.order = 'YXZ';
    cam.rotation.y = Jugador.yaw + (Math.random() - 0.5) * (sh * 0.05 + this.retroceso * 0.004);
    cam.rotation.x = Jugador.pitch + (Math.random() - 0.5) * (sh * 0.05 + this.retroceso * 0.004);
    cam.rotation.z = 0;
    HUD.recarga(1 - this.calor);
    document.getElementById('recarga').style.background = this.calor > 0.7 ? '#ff6a3c' : '';
  },

  disparar(t) {
    this.calor = Math.min(1, this.calor + this.CALOR_TIRO);
    this.retroceso = 1;
    const o = V3(); G.camera.getWorldPosition(o);
    const d = V3(-Math.sin(Jugador.yaw) * Math.cos(Jugador.pitch), Math.sin(Jugador.pitch), -Math.cos(Jugador.yaw) * Math.cos(Jugador.pitch));
    d.add(V3(rand(-1, 1), rand(-1, 1), rand(-1, 1)).multiplyScalar(0.012)).normalize();
    const tr = Armas.trazar(o, d, this.ALCANCE);
    const fin = tr.robots.length ? tr.robots[0].punto : o.clone().addScaledVector(d, tr.fin);
    const boca = V3(); t.boca.getWorldPosition(boca);
    FX.segmento(boca, fin, 0.035, '#ffd27a', 0.05, 3.5);
    if (tr.robots.length) {
      const h = tr.robots[0];
      Robots.danar(h.robot, this.DANO * (h.critico ? 1.5 : 1), h.punto, h.critico);
    } else if (tr.pared) {
      FX.chispazo(fin, '#ffd27a', 4, 5, 0.1);
      if (G.ultimaCaja && G.ultimaCaja.destr) Destruibles.danar(G.ultimaCaja.destr, this.DANO, fin);
    }
    FX.luz(boca, '#ffcc66', 8, 7, 0.05);
    FX.chispazo(boca, '#ffcc66', 3, 3, 0.06);
    // casquillos que saltan a un costado
    const lado = V3(Math.cos(t.yaw), 0, -Math.sin(t.yaw));
    FX.chispas.emitir(boca.x + lado.x * 0.3, boca.y, boca.z + lado.z * 0.3, lado.x * 3 + rand(-0.5, 0.5), rand(2, 3.5), lado.z * 3 + rand(-0.5, 0.5),
      FX.c('#d8a83a', 1.3), 0.06, 0.7, { g: -18, suelo: t.pos.y + 0.46 });
    Sfx.play('metralla');
  },
};
