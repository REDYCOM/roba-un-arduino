// =====================================================================
//  RUNAS TEMPORALES (igual que Runas.server.luau)
//  Aparecen en el mapa con un haz de luz. Al tocarlas:
//    ⚡ Turbo       velocidad ×1.8 (15 s)
//    ⚔️ Sobrecarga  doble daño (15 s)
//    🛡️ Escudo      invencible (8 s)
//    🔋 Batería     vida al máximo (al instante)
//    🔥 Furia       recarga ultra rápida (12 s)
//  Si tomas la misma runa otra vez, se alarga el tiempo.
// =====================================================================
const RUNAS = {
  Turbo:      { icono: '⚡', nombre: 'TURBO', color: '#ffdc3c', dur: 15, desc: '¡Velocidad ×1.8!' },
  Sobrecarga: { icono: '⚔️', nombre: 'SOBRECARGA', color: '#ff3c3c', dur: 15, desc: '¡Doble daño!' },
  Escudo:     { icono: '🛡️', nombre: 'ESCUDO', color: '#50aaff', dur: 8, desc: '¡Invencible!' },
  Bateria:    { icono: '🔋', nombre: 'BATERÍA', color: '#50ff78', dur: 0, desc: '¡Vida al máximo!' },
  Furia:      { icono: '🔥', nombre: 'FURIA', color: '#be50ff', dur: 12, desc: '¡Recarga ultra rápida!' },
};

const Runas = {
  INTERVALO: 20, MAX_ACTIVAS: 3, DURACION_EN_MAPA: 45,
  enMapa: [], activas: {}, proxima: 6, geoCristal: null,

  activa(n) { return (this.activas[n] || 0) > 0; },
  // más jugadores: más runas a la vez y aparecen más seguido
  maxActivas() { return this.MAX_ACTIVAS + Math.floor((G.jugadores - 1) / 3); },
  intervalo() { return Math.max(4, this.INTERVALO / (1 + (G.jugadores - 1) / 5)); },

  iconoTextura(icono, color) {
    const cv = document.createElement('canvas'); cv.width = cv.height = 128;
    const c = cv.getContext('2d');
    c.fillStyle = 'rgba(10,16,32,0.7)'; c.beginPath(); c.arc(64, 64, 58, 0, TAU); c.fill();
    c.strokeStyle = color; c.lineWidth = 8; c.stroke();
    c.font = '70px system-ui, "Segoe UI Emoji", sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.fillText(icono, 64, 70);
    const t = new THREE.CanvasTexture(cv); t.colorSpace = THREE.SRGBColorSpace;
    return t;
  },

  aparecer() {
    const nombres = Object.keys(RUNAS);
    const n = pick(nombres), R = RUNAS[n];
    let x, z;
    // cerca de un equipo con jugadores (así hay runas para todos)
    const eq = EQUIPOS[pick(G.equiposActivos)];
    for (let k = 0; k < 40; k++) {
      const a = eq.ang + rand(-0.55, 0.55), r = rand(25, 100);
      x = Math.cos(a) * r; z = Math.sin(a) * r;
      if (Mapa.libre(x, z, 1.5)) break;
    }
    const y = Terreno.altura(x, z);
    const g = new THREE.Group(); g.position.set(x, y, z);
    const c = col(R.color);
    const cristal = new THREE.Mesh(this.geoCristal || (this.geoCristal = new THREE.OctahedronGeometry(0.45, 0)),
      new THREE.MeshBasicMaterial({ color: c.clone().multiplyScalar(2.4) }));
    cristal.scale.y = 1.5; cristal.position.y = 1.3; g.add(cristal);
    const matAro = new THREE.MeshBasicMaterial({ color: c.clone().multiplyScalar(2) });
    const a1 = new THREE.Mesh(new THREE.TorusGeometry(0.85, 0.03, 6, 40), matAro); a1.position.y = 1.3; a1.rotation.x = Math.PI / 2;
    const a2 = new THREE.Mesh(new THREE.TorusGeometry(0.7, 0.025, 6, 40), matAro); a2.position.y = 1.3;
    g.add(a1, a2);
    // haz de luz al cielo
    const haz = new THREE.Mesh(new THREE.CylinderGeometry(0.35, 0.6, 60, 16, 1, true),
      new THREE.MeshBasicMaterial({ color: c.clone().multiplyScalar(0.9), transparent: true, opacity: 0.25, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }));
    haz.position.y = 30; g.add(haz);
    const suelo = new THREE.Mesh(new THREE.CircleGeometry(1.6, 32).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ map: Terror.textura(), color: c.clone().multiplyScalar(1.4), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    suelo.position.y = 0.06; g.add(suelo);
    const icono = new THREE.Sprite(new THREE.SpriteMaterial({ map: this.iconoTextura(R.icono, R.color), depthWrite: false, transparent: true }));
    icono.scale.setScalar(0.9); icono.position.y = 2.5; g.add(icono);
    G.scene.add(g);
    this.enMapa.push({ n, g, cristal, a1, a2, haz, pos: V3(x, y, z), vida: this.DURACION_EN_MAPA, t: 0 });
  },

  tomar(r) {
    const R = RUNAS[r.n];
    G.scene.remove(r.g);
    this.enMapa.splice(this.enMapa.indexOf(r), 1);
    FX.chispazo(r.pos.clone().setY(r.pos.y + 1.3), R.color, 50, 8, 0.2);
    FX.luz(r.pos.clone().setY(r.pos.y + 1.5), R.color, 40, 18, 0.6);
    FX.aro(r.pos, 4, R.color, 0.5);
    Sfx.play('recoger');
    if (r.n === 'Bateria') Jugador.curar(Jugador.vidaMax);
    else this.activas[r.n] = (this.activas[r.n] || 0) + R.dur; // se alarga si repites
    HUD.anuncio(R.icono + ' ' + R.nombre, R.desc, R.color);
    sumarPuntos(PUNTOS.runa);
    HUD.feed(R.icono + ' Runa <b>' + R.nombre + '</b> <b>+' + PUNTOS.runa + '</b>');
  },

  update(dt) {
    // aparecer cada INTERVALO segundos (máximo 3 a la vez)
    if (Oleadas.n > 0 && Oleadas.fase !== 'fin') {
      this.proxima -= dt;
      if (this.proxima <= 0) { this.proxima = this.intervalo(); if (this.enMapa.length < this.maxActivas()) this.aparecer(); }
    }
    for (let i = this.enMapa.length - 1; i >= 0; i--) {
      const r = this.enMapa[i];
      r.t += dt; r.vida -= dt;
      r.cristal.rotation.y += dt * 2; r.cristal.position.y = 1.3 + Math.sin(r.t * 2.5) * 0.2;
      r.a1.rotation.z += dt * 1.8; r.a2.rotation.y += dt * 2.6;
      r.a1.position.y = r.a2.position.y = r.cristal.position.y;
      r.haz.material.opacity = 0.18 + Math.sin(r.t * 4) * 0.07;
      // parpadea al final de su tiempo
      r.g.visible = r.vida > 6 || Math.sin(r.t * 18) > 0;
      if (r.vida <= 0) { G.scene.remove(r.g); this.enMapa.splice(i, 1); continue; }
      if (!Jugador.muerto && Math.hypot(Jugador.pos.x - r.pos.x, Jugador.pos.z - r.pos.z) < 1.8 && Math.abs(Jugador.pos.y - r.pos.y) < 2.5) this.tomar(r);
    }
    // efectos activos
    for (const n of Object.keys(this.activas)) {
      this.activas[n] -= dt;
      if (this.activas[n] <= 0) { delete this.activas[n]; HUD.feed(RUNAS[n].icono + ' Se acabó <b>' + RUNAS[n].nombre + '</b>'); continue; }
      // brillo de la runa alrededor tuyo
      if (Math.random() < dt * 12) {
        const p = Jugador.pos, a = Math.random() * TAU;
        FX.chispas.emitir(p.x + Math.cos(a) * 0.7, p.y + rand(0.2, 1.6), p.z + Math.sin(a) * 0.7, 0, rand(0.5, 1.5), 0, FX.c(RUNAS[n].color, 2.5), 0.07, 0.6);
      }
    }
    G.mods.vel = this.activa('Turbo') ? 1.8 : 1;
    G.mods.dano = this.activa('Sobrecarga') ? 2 : 1;
    G.mods.cad = this.activa('Furia') ? 0.4 : 1;
    G.mods.escudo = this.activa('Escudo');
    HUD.runas(this.activas);
  },
};
