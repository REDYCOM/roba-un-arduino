// =====================================================================
//  ROBOTS ENEMIGOS: modelos, IA, oleadas, jefe MEGA-ARDUINO, botín
//  (valores de Robots.server.luau, escalados de studs a metros)
// =====================================================================
const ST = 0.36; // metros por stud

// ---------- objetivos: tú + los demás jugadores de la sala (multijugador) ----------
function jugadoresVivos() {
  const l = Jugador.muerto ? [] : [Jugador];
  for (const j of Red.proxies()) if (!j.muerto) l.push(j);
  return l;
}
function masCercano(p) {
  let m = null, dm = Infinity;
  for (const j of jugadoresVivos()) { const d = Math.hypot(j.pos.x - p.x, j.pos.z - p.z); if (d < dm) { dm = d; m = j; } }
  return m;
}
let OBJ = Jugador; // a quién persigue el robot que se está pensando ahora
const TIPOS = {
  Seguidor:  { vida: 120, vel: 7.4, dano: 20, alcance: 3.6 * ST, puntos: 15, fx: 1, mov: 'salto' },
  Arana:     { vida: 70, vel: 9.0, dano: 15, alcance: 3.4 * ST, puntos: 10, fx: 0.8, nombre: 'Araña', mov: 'salto' },
  Soldado:   { vida: 180, vel: 6.2, dano: 25, alcance: 3.8 * ST, puntos: 20, fx: 1.4, caja: 0.08, mov: 'carga' },
  Dron:      { vida: 90, vel: 8.2, dano: 0, alcance: 0, puntos: 20, fx: 1, vuela: true, caja: 0.05, disparo: { dano: 12, cad: 2.4, alcance: 32 } },
  Tanque:    { vida: 600, vel: 4.1, mata: true, alcance: 5.8 * ST, puntos: 40, fx: 2, caja: 0.15, mov: 'carga', rompe: true },
  Chatarra:  { vida: 320, vel: 5.7, dano: 35, alcance: 4.6 * ST, puntos: 25, fx: 2, caja: 0.25, mov: 'carga', rompe: true },
  Coloso:    { vida: 1000, vidaPorJugador: 150, vel: 4.5, mata: true, alcance: 9 * ST, puntos: 80, fx: 3.5, caja: 1, pasos: true, mov: 'golpe', rompe: true },
  Jefe:      { vida: 1500, vidaPorJugador: 800, vel: 3.8, mata: true, alcance: 11.5 * ST, puntos: 150, fx: 4, pasos: true, jefe: true, nombre: 'MEGA-ARDUINO', mov: 'golpe', rompe: true, aura: '#7dff4a' },
  JefeFinal: { vida: 4000, vidaPorJugador: 1500, vel: 3.4, mata: true, alcance: 16 * ST, puntos: 400, fx: 6, pasos: true, jefe: true, nombre: 'ROBOT DE ARDUNOL', mov: 'golpe', rompe: true, aura: '#b06bff' },
  // Oleada 8: ARDUNOL DESATADO en su mech (modelo KW-II). Si el modelo no carga, usa el robot de Ardunol corrompido
  Desatado:  { vida: 9000, vidaPorJugador: 1500, vel: 3.8, mata: true, alcance: 16 * ST, puntos: 1000, fx: 7, pasos: true, jefe: true, final: true, nombre: 'ARDUNOL DESATADO',
               mov: 'golpe', rompe: true, mech: true, modelo: 'JefeFinal', escala: 1.25, tinte: '#ff2040', aura: '#ff2040' },
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

};

// =====================================================================
const Robots = {
  vivos: [], balas: [], restos: [], botin: [], sigId: 0,

  centroDe(r) { return V3(r.pos.x, r.pos.y + (r.cfg.vuela ? 0 : r.cfg.alto * 0.55), r.pos.z); },
  objetivosRayo() { return this.vivos.map((r) => r.raiz); },

  crear(tipo, x, z, mult = 1) {
    const cfg = TIPOS[tipo];
    const esMech = cfg.mech && Mech.listo;
    const mod = esMech ? Mech.construir() : RB.construir(cfg.modelo || tipo);
    const k = esMech ? 1 : cfg.escala || 1;
    if (k !== 1) mod.cuerpo.scale.setScalar(k);
    // medidas reales del modelo de Roblox
    if (!cfg.alto || esMech) { cfg.alto = cfg.vuela ? 0.8 : mod.med.alto * k; cfg.radio = Math.max(0.45, mod.med.ancho * k * (cfg.vuela ? 0.45 : 0.32)); }
    Terror.decorar(mod, cfg);
    const r = {
      tipo, cfg, mod, raiz: mod.raiz, partes: mod.partes, segs: mod.segs,
      vida: (cfg.vida * mult + (cfg.vidaPorJugador || 0) * (G.jugadores - 1)) * Profe.dif.vida,
      vidaMax: (cfg.vida * mult + (cfg.vidaPorJugador || 0) * (G.jugadores - 1)) * Profe.dif.vida, radio: cfg.radio,
      pos: V3(x, Terreno.altura(x, z), z), yaw: 0, fase: rand(0, 6), ataque: 0, cdAtaque: 0, flash: 0,
      aparecer: 0, esquivar: 0, ladoEsq: 1, cdDisparo: rand(1, 2.5), orbita: rand(0, TAU), altVuelo: rand(6, 9),
      cdOrbes: 4, cdPisoton: 3, cdRayos: 8, cdMisil: 6, furia: false, pasoT: 0, muerto: false, salto: 0,
      cdMov: rand(2, 5), atasco: 0, brinco: null, carga: 0, zig: rand(0, 6),
      mats: mod.mats,
    };
    if (cfg.vuela) r.pos.y += r.altVuelo;
    r.centro = () => this.centroDe(r);
    r.id = ++this.sigId;
    if (esMech) Mech.preparar(r);
    else if (cfg.tinte) { r.furia = true; for (const m of r.mats) { m.emissive.set(cfg.tinte); m.emissiveIntensity = 0.3; } }
    r.raiz.traverse((o) => {
      if (!o.isMesh) return;
      o.userData.robot = r;
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

  danar(r, cant, punto, critico, quien) {
    if (r.muerto) return;
    if (r.remoto) {
      // alumno: la vida real la lleva el profe; aquí solo se ve el golpe
      cant = Math.round(cant * G.mods.dano);
      r.flash = 0.09; HUD.numero(punto || r.centro(), cant, critico); Sfx.play('golpeRobot'); HUD.hit(false);
      Red.ev({ a: 'dano', rid: r.rid, c: cant, k: critico ? 1 : 0 }, 'host');
      return;
    }
    cant = quien ? Math.round(cant) : Math.round(cant * G.mods.dano); // runa SOBRECARGA: doble daño
    r.vida -= cant;
    r.flash = 0.09;
    if (!quien) { HUD.numero(punto || r.centro(), cant, critico); Sfx.play('golpeRobot'); }
    if (r.cfg.jefe) {
      HUD.jefe(r.cfg.nombre, Math.max(0, r.vida / r.vidaMax));
      if (!r.furia && r.vida < r.vidaMax * 0.5) {
        r.furia = true;
        HUD.anuncio('¡FURIA!', r.mech ? '¡El mech de ARDUNOL se sobrecalienta!' : '¡' + r.cfg.nombre + ' se enoja!', '#ff5533');
        Sfx.play('jefe'); FX.sacudir(0.8);
        if (!r.mech) for (const m of r.mats) m.emissive.set('#ff2200');
      }
    }
    if (r.vida <= 0) { this.morir(r, quien); if (!quien) HUD.hit(true); } else if (!quien) HUD.hit(false);
  },

  // quien = otro jugador que lo destruyó { nombre, equipo } (sus puntos van a su equipo)
  morir(r, quien) {
    r.muerto = true;
    const c = r.centro();
    FX.explosion(c, 1.2 + r.cfg.fx * 0.9, r.cfg.jefe ? '#ff5522' : '#ffa040');
    Sfx.play('muereRobot', c.distanceTo(Jugador.pos));
    if (r.cfg.fx >= 3.5) { setTimeout(() => FX.explosion(c.clone().add(V3(rand(-2, 2), rand(0, 3), rand(-2, 2))), 3, '#ff7733'), 250); setTimeout(() => FX.explosion(c.clone().add(V3(rand(-2, 2), rand(-1, 2), rand(-2, 2))), 4, '#ffcc55'), 550); }
    // piezas que salen volando (el mech tiene su propia caída)
    const piezas = [];
    if (r.mech) Mech.caer(r); else {
    r.raiz.updateMatrixWorld(true);
    r.raiz.traverse((o) => { if (o.isMesh && !o.userData.noResto && o.geometry.type !== 'ConeGeometry') piezas.push(o); });
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
    }
    Terror.quitar(r);
    this.vivos.splice(this.vivos.indexOf(r), 1);
    // puntos
    const pts = r.cfg.puntos;
    if (quien) {
      // lo destruyó otro jugador: los puntos van a su equipo
      if (!quien.silencio) HUD.feed(`🤖 ${r.cfg.nombre || r.tipo} destruido por <b>${quien.nombre}</b>`);
      if (quien.equipo >= 0) {
        G.puntosEq[quien.equipo] += pts; quien.puntos = (quien.puntos || 0) + pts; quien.bajas = (quien.bajas || 0) + 1;
        if (quien.equipo === MI_EQUIPO) { G.puntos += pts; HUD.puntos(); }
      }
    } else {
      G.bajas++;
      sumarPuntos(pts);
      HUD.feed(`🤖 ${r.cfg.nombre || r.tipo} destruido <b>+${pts}</b>`);
    }
    if (Red.host) {
      Red.ev({ a: 'muere', rid: r.id, q: quien ? quien.nombre : G.miNombre });
      if (quien && quien.remoto) Red.ev({ a: 'puntos', n: pts }, quien.id);
    }
    if (r.cfg.final) Final.jefeCayo(r);
    else if (r.cfg.jefe) {
      HUD.jefe(null);
      HUD.anuncio('¡JEFE DERROTADO!', quien ? 'por ' + quien.nombre : '+' + pts + ' puntos', '#ffcf4a');
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
          sumarPuntos(PUNTOS.caja); HUD.feed('📦 Caja <b>+' + PUNTOS.caja + '</b>');
        } else { Jugador.curar(30); sumarPuntos(PUNTOS.bateria); HUD.feed('🔋 Batería <b>+30 vida · +' + PUNTOS.bateria + '</b>'); }
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
    const vivos = jugadoresVivos();
    for (let i = this.balas.length - 1; i >= 0; i--) {
      const b = this.balas[i];
      b.vida -= dt;
      if (b.tipo === 'misil') {
        // teledirigido al jugador más cercano
        const pj = (masCercano(b.pos) || Jugador).centro();
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
      for (const j of vivos) if (b.pos.distanceTo(j.centro()) < b.radio + 0.6) { j.danar(b.dano, b.pos, b.tipo); fin = true; break; }
      if (fin || b.vida <= 0) {
        if (b.tipo === 'misil') { FX.explosion(b.pos, 3, '#ff6633'); Destruibles.explosion(b.pos, 4); }
        else if (b.tipo === 'orbe') { FX.explosion(b.pos, 1.4, '#ff8a2a'); Destruibles.explosion(b.pos, 2); }
        else FX.chispazo(b.pos, '#ff3030', 8, 4);
        if (b.tipo === 'misil') for (const j of vivos) { const dj = b.pos.distanceTo(j.centro()); if (dj < 3.5 && dj >= b.radio + 0.6) j.danar(b.dano * 0.5, b.pos, 'misil'); }
        G.scene.remove(b.m);
        this.balas.splice(i, 1);
      }
    }
  },

  // ---------- IA ----------
  update(dt) {
    if (Red.cliente) { this.updateRemoto(dt); return; }
    for (const r of [...this.vivos]) {
      const cfg = r.cfg;
      // cada medio segundo elige al jugador más cercano
      if ((r.cdObj = (r.cdObj || 0) - dt) <= 0 || !r.obj || r.obj.muerto) { r.cdObj = 0.5; r.obj = masCercano(r.pos) || Jugador; }
      OBJ = r.obj; const pj = OBJ.pos;
      r.aparecer = Math.min(1, r.aparecer + dt * 1.6);
      r.raiz.scale.setScalar(Math.max(0.01, smooth(0, 1, r.aparecer)));
      r.flash = Math.max(0, r.flash - dt);
      if (r.mech) Mech.brillo(r);
      else if (!r.furia) for (const m of r.mats) m.emissive.setScalar(r.flash > 0 ? 0.9 : 0);
      else for (const m of r.mats) m.emissiveIntensity = r.flash > 0 ? 3 : 0.35 + Math.sin(G.t * 8) * 0.15;
      r.cdAtaque -= dt; r.ataque = Math.max(0, r.ataque - dt);

      const objetivo = OBJ.muerto ? V3(0, SUELO, 0) : pj;
      const dx = objetivo.x - r.pos.x, dz = objetivo.z - r.pos.z;
      const dist = Math.hypot(dx, dz) || 0.001;
      const velBase = cfg.vel * Profe.dif.vel * (r.furia ? 1.35 : 1) * (r.aparecer < 1 ? 0 : 1);

      if (cfg.vuela) { this.iaDron(r, dt, dist); Terror.update(r, dt); continue; }
      Terror.update(r, dt);
      // en pleno salto: sigue la curva y no hace nada más
      if (r.brinco) { this.updateBrinco(r, dt); continue; }
      r.cdMov -= dt; r.carga = Math.max(0, r.carga - dt);
      if (r.aparecer >= 1 && !OBJ.muerto) this.moverEspecial(r, dist, dx, dz);
      if (r.brinco) continue;

      // dirección deseada + separación de otros robots
      let mx = dx / dist, mz = dz / dist;
      for (const o of this.vivos) {
        if (o === r || o.cfg.vuela) continue;
        const ox = r.pos.x - o.pos.x, oz = r.pos.z - o.pos.z, dd = Math.hypot(ox, oz), min = r.radio + o.radio + 0.3;
        if (dd < min && dd > 0.001) { const k = (min - dd) / min * 2.5; mx += (ox / dd) * k; mz += (oz / dd) * k; }
      }
      if (r.esquivar > 0) { r.esquivar -= dt; mx += -dz / dist * r.ladoEsq * 1.5; mz += dx / dist * r.ladoEsq * 1.5; }
      // zigzag de los chicos (más difíciles de apuntar)
      if (!cfg.rompe && dist > 5) { const zz = Math.sin(G.t * 2.3 + r.zig) * 0.6; mx += -dz / dist * zz; mz += dx / dist * zz; }
      const ml = Math.hypot(mx, mz) || 1; mx /= ml; mz /= ml;
      const cerca = dist < r.radio + cfg.alcance + OBJ.radio;
      const v = (cerca && !cfg.mata ? 0 : velBase) * (r.carga > 0 ? 2.3 : 1);
      const antes = r.pos.clone();
      r.pos.x += mx * v * dt; r.pos.z += mz * v * dt;
      // los grandes rompen árboles, cajas y barriles a su paso
      if (cfg.rompe) Destruibles.romperCerca(r.pos, r.radio + 0.8, r.pos);
      empujarFuera(r.pos, Math.min(r.radio, 2.2), Math.max(cfg.alto, 1.5));
      const movido = Math.hypot(r.pos.x - antes.x, r.pos.z - antes.z);
      if (v > 0 && movido < v * dt * 0.35 && r.esquivar <= 0) { r.esquivar = rand(0.6, 1.4); r.ladoEsq = Math.random() < 0.5 ? -1 : 1; }
      // ¿atascado? salta por encima del obstáculo hacia el jugador
      if (v > 0 && movido < v * dt * 0.3) r.atasco += dt; else r.atasco = Math.max(0, r.atasco - dt * 2);
      if (r.atasco > (cfg.jefe ? 0.7 : 1.4)) {
        r.atasco = 0;
        const L = Math.min(dist, cfg.jefe ? 26 : 16);
        this.saltar(r, r.pos.x + dx / dist * L, r.pos.z + dz / dist * L, cfg.rompe ? 7 : 4, cfg.rompe ? 1.1 : 0.8);
        continue;
      }
      const suelo = alturaSuelo(r.pos.x, r.pos.z, r.pos.y, r.radio);
      r.pos.y = suelo > r.pos.y ? damp(r.pos.y, suelo, 18, dt) : Math.max(suelo, r.pos.y - 12 * dt);
      // girar hacia el objetivo
      const yawObj = Math.atan2(-dx, -dz);
      let dy = yawObj - r.yaw; while (dy > Math.PI) dy -= TAU; while (dy < -Math.PI) dy += TAU;
      r.yaw += dy * Math.min(1, dt * (cfg.alto > 5 ? 2.5 : 7));

      // atacar
      const dV = Math.abs(pj.y - r.pos.y);
      if (!OBJ.muerto && cerca && dV < cfg.alto + 0.5) {
        if (cfg.mata) OBJ.danar(999, r.pos, r.tipo);
        else if (r.cdAtaque <= 0) { r.cdAtaque = 1.0; r.ataque = 0.45; OBJ.danar(cfg.dano, r.pos, r.tipo); }
      }
      if (cfg.jefe) this.iaJefe(r, dt, dist);

      // pasos de gigante
      r.fase += movido * (r.mod.spec.pasoFreq || 5) / Math.max(cfg.alto, 0.8) * 0.55;
      if (cfg.pasos) {
        r.pasoT += movido;
        if (r.pasoT > cfg.alto * 0.45) {
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
    this.updateRestos(dt);
  },

  // ---------- alumno: los robots se mueven según la foto que manda el profe ----------
  updateRemoto(dt) {
    for (const r of [...this.vivos]) {
      if (!r.remoto) continue;
      r.aparecer = Math.min(1, r.aparecer + dt * 1.6);
      r.raiz.scale.setScalar(Math.max(0.01, smooth(0, 1, r.aparecer)));
      r.flash = Math.max(0, r.flash - dt);
      if (r.mech) Mech.brillo(r);
      else if (!r.furia) for (const m of r.mats) m.emissive.setScalar(r.flash > 0 ? 0.9 : 0);
      else for (const m of r.mats) m.emissiveIntensity = r.flash > 0 ? 3 : 0.35 + Math.sin(G.t * 8) * 0.15;
      Terror.update(r, dt);
      const antes = r.pos.clone();
      r.pos.lerp(r.destino, 1 - Math.exp(-12 * dt));
      let dy = r.yawDestino - r.yaw; while (dy > Math.PI) dy -= TAU; while (dy < -Math.PI) dy += TAU;
      r.yaw += dy * Math.min(1, dt * 10);
      const rapidez = Math.hypot(r.pos.x - antes.x, r.pos.z - antes.z) / Math.max(dt, 1e-4);
      if (r.cfg.vuela) {
        r.mod.cuerpo.rotation.x = -0.15 + Math.sin(G.t * 2 + r.fase) * 0.05;
        r.mod.cuerpo.rotation.z = Math.sin(G.t * 1.3 + r.fase) * 0.12;
        for (let i = 1; i <= 4; i++) if (r.segs['Helice' + i]) r.segs['Helice' + i].g.rotation.y += dt * 40;
      } else {
        r.fase += rapidez * dt * (r.mod.spec.pasoFreq || 5) / Math.max(r.cfg.alto, 0.8) * 0.55;
        this.animar(r, dt, rapidez);
      }
      // láser del mech (lo dispara el profe; aquí se dibuja)
      if (r.mech && r.laserRed) {
        const ojos = Mech.mundo(r, r.mech.puntos.ojos), p = V3(r.laserRed[0], r.laserRed[1], r.laserRed[2]);
        if (r.laserRed[3]) { if (Math.sin(G.t * 40) > 0) FX.segmento(ojos, p, 0.05, '#ff2040', 0.03, 4); }
        else { FX.segmento(ojos, p, 0.32, '#ff2040', 0.04, 6); FX.luz(p, '#ff2040', 40, 10, 0.05); }
      }
      r.raiz.position.copy(r.pos);
      r.raiz.rotation.y = r.yaw;
    }
    this.updateBotin(dt);
    this.updateRestos(dt);
  },

  updateRestos(dt) {
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

  // ataques de movimiento: los chicos saltan sobre ti, los medianos cargan, los gigantes caen encima
  moverEspecial(r, dist, dx, dz) {
    const cfg = r.cfg;
    if (r.cdMov > 0 || r.salto > 0) return;
    const k = r.furia ? 0.6 : 1;
    if (cfg.mov === 'salto' && dist > 3 && dist < 11) {
      r.cdMov = rand(3, 6) * k;
      const pj = OBJ.pos, adelanto = 0.35;
      this.saltar(r, pj.x + OBJ.vel.x * adelanto, pj.z + OBJ.vel.z * adelanto, 2.2, 0.55);
    } else if (cfg.mov === 'carga' && dist > 7 && dist < 24) {
      r.cdMov = rand(4, 7) * k; r.carga = 1.1;
      FX.chispazo(r.centro(), '#ff3030', 12, 4);
      Sfx.play('golpeRobot', dist);
    } else if (cfg.mov === 'golpe' && dist > 12 && dist < 42) {
      r.cdMov = rand(7, 10) * k;
      // aviso en el suelo donde va a caer
      const pj = OBJ.pos, tx = pj.x, tz = pj.z;
      FX.aro(V3(tx, Terreno.altura(tx, tz), tz), r.radio + 5, '#ff2a2a', 1.0);
      HUD.feed('⚠ ¡' + (cfg.nombre || r.tipo) + ' salta hacia ti!');
      this.saltar(r, tx, tz, 10 + cfg.alto * 0.4, 1.4, true);
    }
  },

  saltar(r, tx, tz, alto, dur, golpe = false) {
    const lim = Math.hypot(tx, tz); if (lim > 128) { tx *= 128 / lim; tz *= 128 / lim; }
    r.brinco = { t: 0, dur, x0: r.pos.x, z0: r.pos.z, y0: r.pos.y, x1: tx, z1: tz, y1: Terreno.altura(tx, tz), alto, golpe: golpe || !!r.cfg.rompe };
    r.yaw = Math.atan2(-(tx - r.pos.x), -(tz - r.pos.z));
    if (r.cfg.rompe) FX.humo.emitir(r.pos.x, r.pos.y + 0.3, r.pos.z, 0, 2, 0, new THREE.Color(0.5, 0.45, 0.4), r.radio, 1, { crece: 3, a: 0.5 });
  },

  updateBrinco(r, dt) {
    const b = r.brinco;
    b.t = Math.min(1, b.t + dt / b.dur);
    const t = b.t;
    r.pos.x = lerp(b.x0, b.x1, t); r.pos.z = lerp(b.z0, b.z1, t);
    r.pos.y = lerp(b.y0, b.y1, t) + b.alto * 4 * t * (1 - t);
    if (r.cfg.rompe) Destruibles.romperCerca(r.pos, r.radio + 0.5, r.pos);
    r.raiz.position.copy(r.pos);
    r.raiz.rotation.y = r.yaw;
    if (b.caida) {
      // cae del cielo acelerando, con fuego
      r.pos.y = lerp(b.y0, b.y1, t * t);
      for (let i = 0; i < 4; i++) FX.chispas.emitir(r.pos.x + rand(-2, 2), r.pos.y + rand(0, 3), r.pos.z + rand(-2, 2), rand(-2, 2), rand(4, 10), rand(-2, 2), FX.c(pick(['#ff6a2a', '#ffb347', '#ff2040']), 3), rand(0.2, 0.5), 0.6);
      FX.humo.emitir(r.pos.x, r.pos.y + 4, r.pos.z, 0, 3, 0, new THREE.Color(0.25, 0.22, 0.22), 2.5, 1.5, { crece: 2, a: 0.5 });
      r.raiz.position.copy(r.pos);
      if (t >= 1) { r.brinco = null; Mech.aterrizar(r); }
      return;
    }
    r.mod.cuerpo.rotation.x = Math.sin(t * Math.PI) * -0.25;
    if (t >= 1) {
      r.brinco = null; r.mod.cuerpo.rotation.x = 0;
      empujarFuera(r.pos, Math.min(r.radio, 2.2), Math.max(r.cfg.alto, 1.5));
      r.pos.y = alturaSuelo(r.pos.x, r.pos.z, r.pos.y + 1, r.radio);
      const dj = Math.hypot(Jugador.pos.x - r.pos.x, Jugador.pos.z - r.pos.z);
      if (b.golpe) {
        // aterrizaje pesado: onda expansiva
        const p = V3(r.pos.x, Terreno.altura(r.pos.x, r.pos.z), r.pos.z), rad = r.radio + 5;
        FX.aro(p, rad * 1.4, '#ffaa44', 0.6); FX.aro(p, rad, '#ff5522', 0.5);
        for (let i = 0; i < 24; i++) FX.humo.emitir(p.x + rand(-2, 2), p.y + 0.3, p.z + rand(-2, 2), rand(-9, 9), rand(1, 4), rand(-9, 9), new THREE.Color(0.5, 0.45, 0.38), 2, 1.4, { crece: 3, a: 0.5, roce: 2 });
        Sfx.play('pisoton', dj); FX.sacudir(clamp(1.1 - dj * 0.02, 0.1, 1));
        Destruibles.explosion(p, rad);
        for (const j of jugadoresVivos()) if (Math.hypot(j.pos.x - p.x, j.pos.z - p.z) < rad && j.enSuelo) j.danar(r.cfg.jefe ? 35 : 25, p, 'pisoton');
      } else {
        for (const j of jugadoresVivos()) if (Math.hypot(j.pos.x - r.pos.x, j.pos.z - r.pos.z) < r.radio + 1.4) j.danar(r.cfg.dano || 15, r.pos, r.tipo);
      }
    }
  },

  iaDron(r, dt, dist) {
    const pj = OBJ.pos, cfg = r.cfg;
    r.orbita += dt * 0.5;
    const rad = 14;
    const ox = pj.x + Math.cos(r.orbita) * rad, oz = pj.z + Math.sin(r.orbita) * rad;
    const oy = Math.max(Terreno.altura(ox, oz), pj.y) + r.altVuelo + Math.sin(G.t * 1.5 + r.fase) * 0.8;
    const v = cfg.vel * (r.aparecer < 1 ? 0 : 1);
    const d = V3(ox - r.pos.x, oy - r.pos.y, oz - r.pos.z);
    const L = d.length();
    if (L > 0.1) r.pos.addScaledVector(d.divideScalar(L), Math.min(v * dt, L));
    const c = OBJ.centro();
    r.yaw = Math.atan2(-(c.x - r.pos.x), -(c.z - r.pos.z));
    r.raiz.position.copy(r.pos);
    r.raiz.rotation.y = r.yaw;
    r.mod.cuerpo.rotation.x = -0.15 + Math.sin(G.t * 2 + r.fase) * 0.05;
    r.mod.cuerpo.rotation.z = Math.sin(G.t * 1.3 + r.fase) * 0.12;
    for (let i = 1; i <= 4; i++) r.segs['Helice' + i].g.rotation.y += dt * 40;
    r.cdDisparo -= dt;
    const dd = r.pos.distanceTo(c);
    if (r.cdDisparo <= 0 && !OBJ.muerto && dd < cfg.disparo.alcance && hayVista(r.pos, c)) {
      r.cdDisparo = cfg.disparo.cad * rand(0.8, 1.2);
      const dir = c.clone().add(V3(OBJ.vel.x, 0, OBJ.vel.z).multiplyScalar(dd / 24 * 0.5)).sub(r.pos).normalize();
      this.bala('rayo', r.pos.clone().addScaledVector(dir, 0.6), dir.multiplyScalar(24), cfg.disparo.dano, { radio: 0.3 });
      Sfx.play('disparoDron', dd);
      FX.luz(r.pos, '#ff3030', 4, 6, 0.1);
    }
  },

  iaJefe(r, dt, dist) {
    const pj = OBJ.centro(), k = r.furia ? 0.65 : 1;
    r.cdOrbes -= dt; r.cdPisoton -= dt; r.cdRayos -= dt; r.cdMisil -= dt;
    for (let i = 1; i <= 5; i++) { const led = r.partes['LED' + i]; if (led) led.visible = Math.sin(G.t * (r.furia ? 18 : 6) + i * 1.3) > -0.3; }
    if (r.partes.Nucleo) r.partes.Nucleo.scale.setScalar(r.mod.spec.escala * ST * (1 + Math.sin(G.t * 5) * 0.15));
    if (OBJ.muerto || r.aparecer < 1) return;
    const boca = r.centro().add(V3(0, r.cfg.alto * 0.25, 0));
    if (r.mech) this.mechAtaques(r, dt, dist);
    // orbes en abanico
    if (!r.mech && r.cdOrbes <= 0 && dist < 60) {
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
    if (r.cdPisoton <= 0 && dist < r.radio + 6) {
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
        for (const j of jugadoresVivos()) if (Math.hypot(j.pos.x - p.x, j.pos.z - p.z) < 12 && j.enSuelo) j.danar(35, p, 'pisoton');
      }
    }
    // tormenta eléctrica: círculos de aviso y luego rayos
    if (r.cdRayos <= 0) {
      r.cdRayos = 11 * k;
      HUD.anuncio('⚡ ¡TORMENTA ELÉCTRICA!', 'Sal de los círculos rojos', '#ff7766');
      const n = r.furia ? 7 : 5;
      for (let i = 0; i < n; i++) {
        const p = i === 0 ? OBJ.pos.clone() : OBJ.pos.clone().add(V3(rand(-12, 12), 0, rand(-12, 12)));
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
            Destruibles.explosion(p, 3);
            for (const j of jugadoresVivos()) if (Math.hypot(j.pos.x - p.x, j.pos.z - p.z) < 3.2) j.danar(30, p, 'rayo');
          }
        };
        G.anim.push(f);
      }
    }
    // misil teledirigido si te alejas (el mech usa sus cañones)
    if (!r.mech && r.cdMisil <= 0 && dist > 28) {
      r.cdMisil = 6 * k;
      const d = V3(0, 1, 0).add(pj.clone().sub(boca).normalize()).normalize();
      this.bala('misil', boca.clone().addScaledVector(d, 2), d.multiplyScalar(16), 30, { vida: 7, radio: 0.6, giro: 2.2 });
      HUD.feed('🚀 ¡Misil teledirigido!');
    }
  },

  mechAtaques(r, dt, dist) { Mech.ataques(r, dt, dist); },

  animar(r, dt, rapidez) {
    if (r.mech) { Mech.animar(r, dt, rapidez); return; }
    const sg = r.segs, f = r.fase, mov = clamp(rapidez / Math.max(r.cfg.vel, 0.1), 0, 1), anim = r.mod.spec.anim;
    const atk = r.ataque > 0;
    if (anim === 'ruedas') {
      for (const n of ['RuedaIzq', 'RuedaDer', 'RuedaFIzq', 'RuedaFDer', 'RuedaTIzq', 'RuedaTDer']) if (r.partes[n]) r.partes[n].rotation.x -= rapidez * dt * 2.2;
      r.mod.cuerpo.position.y = Math.abs(Math.sin(G.t * 22)) * 0.02 * mov;
      r.mod.cuerpo.rotation.x = atk ? -0.15 : 0;
    } else if (anim === 'arana') {
      for (let i = 1; i <= 4; i++) {
        const p = sg['Pata' + i]; if (!p) continue;
        const fase = f * 1.6 + (i % 2) * Math.PI;
        p.g.rotation.y = Math.sin(fase) * 0.35 * mov;
        p.g.position.y = (p.abs[1] * r.mod.spec.escala * ST) + Math.max(0, Math.cos(fase)) * 0.12 * mov;
      }
      r.mod.cuerpo.position.y = Math.abs(Math.sin(f * 3.2)) * 0.05 * mov;
    } else if (sg.PiernaIzq) {
      const amp = 0.6 * mov;
      sg.PiernaIzq.g.rotation.x = Math.sin(f) * amp;
      sg.PiernaDer.g.rotation.x = -Math.sin(f) * amp;
      const brazo = atk ? -1.6 + Math.sin(G.t * 24) * 0.15 : 0;
      sg.BrazoIzq.g.rotation.x = atk ? brazo : -Math.sin(f) * amp * 0.7;
      sg.BrazoDer.g.rotation.x = atk ? brazo : Math.sin(f) * amp * 0.7;
      sg.BrazoIzq.g.rotation.z = -0.08; sg.BrazoDer.g.rotation.z = 0.08;
      sg.Torso.g.rotation.z = Math.sin(f) * 0.04 * mov;
      sg.Torso.g.rotation.x = r.tipo === 'Chatarra' ? 0.12 + Math.sin(G.t * 1.7) * 0.04 : 0;
      sg.Cabeza.g.rotation.y = Math.sin(G.t * 0.7 + r.fase) * 0.25;
      r.mod.cuerpo.position.y = Math.abs(Math.cos(f)) * 0.03 * r.cfg.alto * mov;
    }
  },

  limpiar() {
    for (const r of this.vivos) { G.scene.remove(r.raiz); Terror.quitar(r); }
    for (const b of this.balas) G.scene.remove(b.m);
    this.vivos = []; this.balas = [];
    HUD.jefe(null);
  },
};

// =====================================================================
//  OLEADAS (mismo ritmo que el juego de Roblox)
// =====================================================================
const Oleadas = {
  n: 0, fase: 'espera', cuenta: 10, cola: [], genT: 0, tipo: 'normal', MAX_VIVOS: 18, DESCANSO: 60, quizEn: 0, // DESCANSO = tiempo libre entre oleadas (s)

  // plan de la partida: 8 oleadas
  PLAN: [null, 'normal', 'normal', 'jefe', 'drones', 'morado', 'normal', 'mixta', 'final'],
  TOTAL: 8,
  iniciar() {
    this.n = 0; Clima.poner('dia');
    if (G.profe) {
      // con profe: las rejas esperan su orden (panel F1)
      this.fase = 'esperaProfe';
      setTimeout(() => HUD.anuncio('👑 TÚ ABRES LAS REJAS', 'Pulsa F1 → 🔓 Abrir rejas cuando todos estén listos', '#ffcf4a'), 4500);
    } else { this.fase = 'descanso'; this.cuenta = 10; }
  },
  abrirRejas(seg = 10) {
    if (this.fase !== 'esperaProfe') return;
    this.fase = 'descanso'; this.cuenta = seg;
    HUD.anuncio('🔓 ¡EL PROFE ABRE LAS REJAS!', 'En ' + seg + ' segundos empieza la batalla', '#ffcf4a');
  },

  componer() {
    const n = this.n, cola = [];
    const pesos = [['Seguidor', 6], ['Arana', 4]];
    if (n >= 2) pesos.push(['Soldado', 3], ['Chatarra', 2], ['Tanque', 1]);
    if (n >= 5) pesos.push(['Dron', 2]);
    const total = pesos.reduce((s, p) => s + p[1], 0);
    const elegir = () => { let x = Math.random() * total; for (const [t, w] of pesos) { x -= w; if (x <= 0) return t; } return 'Seguidor'; };
    if (this.tipo === 'final') {
      cola.push('Desatado');
      for (let i = 0; i < 14; i++) cola.push(pick(['Soldado', 'Chatarra', 'Dron', 'Arana', 'Tanque']));
      cola.splice(6, 0, 'Coloso');
    } else if (this.tipo === 'morado') {
      cola.push('JefeFinal');
      for (let i = 0; i < 10; i++) cola.push(pick(['Soldado', 'Chatarra', 'Dron', 'Seguidor']));
    } else if (this.tipo === 'mixta') {
      for (let i = 0; i < 30; i++) cola.push(i % 3 === 2 ? 'Dron' : elegir());
      cola.splice(4, 0, 'Coloso'); cola.splice(16, 0, 'Coloso');
    } else if (this.tipo === 'jefe') {
      cola.push('Jefe');
      for (let i = 0; i < 4 + n * 2; i++) cola.push(elegir());
      if (n >= 6) cola.push('Coloso');
    } else if (this.tipo === 'drones') {
      for (let i = 0; i < 6 + n * 2; i++) cola.push(i % 4 === 3 ? 'Arana' : 'Dron');
    } else {
      for (let i = 0; i < Math.min(6 + n * 3, 40); i++) cola.push(elegir());
      if (n >= 5) { cola.splice(randi(2, 6), 0, 'Coloso'); if (n >= 8) cola.push('Coloso'); }
    }
    // MÁS JUGADORES = MÁS ROBOTS (+12% por cada jugador extra)
    const k = 1 + (G.jugadores - 1) * 0.12;
    const normales = cola.filter((t) => !TIPOS[t].jefe && t !== 'Coloso');
    const extra = Math.round(normales.length * (k - 1));
    for (let i = 0; i < extra; i++) cola.splice(randi(1, cola.length), 0, pick(normales));
    if (cola.includes('Coloso')) { if (G.jugadores > 10) cola.push('Coloso'); if (G.jugadores > 20) cola.push('Coloso'); }
    return cola;
  },

  // mientras el jefe final siga vivo, ARDUNOL le manda refuerzos sin parar
  refuerzos(dt, mult) {
    const jefe = Robots.vivos.find((r) => r.cfg.final && !r.muerto);
    if (!jefe || jefe.brinco || Final.estado || jefe.aparecer < 1) return;
    this.refT -= dt;
    if (this.refT > 0) return;
    this.refT = jefe.furia ? 9 : 14;
    const libres = this.maxVivos() - Robots.vivos.length;
    const n = Math.min(libres, Math.round((jefe.furia ? 5 : 3) * (1 + (G.jugadores - 1) * 0.08)));
    if (n <= 0) return;
    const desde = jefe.mech ? Mech.mundo(jefe, jefe.mech.puntos.ojos) : jefe.centro().add(V3(0, jefe.cfg.alto * 0.3, 0));
    let hechos = 0;
    for (let k = 0; k < 30 && hechos < n; k++) {
      const a = Math.random() * TAU, d = rand(8, 16);
      const x = jefe.pos.x + Math.cos(a) * d, z = jefe.pos.z + Math.sin(a) * d;
      if (Terreno.altura(x, z) < 1 || Math.hypot(x, z) > 125) continue;
      if (G.cajas.some((c) => x > c.min.x - 1.5 && x < c.max.x + 1.5 && z > c.min.z - 1.5 && z < c.max.z + 1.5)) continue;
      const tipo = Math.random() < 0.12 ? 'Tanque' : pick(['Seguidor', 'Arana', 'Soldado', 'Chatarra', 'Dron']);
      Robots.crear(tipo, x, z, mult);
      FX.segmento(desde, V3(x, Terreno.altura(x, z) + 1, z), 0.12, '#ff2040', 0.35, 5);
      hechos++;
    }
    if (!hechos) return;
    jefe.ataque = 0.8;
    FX.chispazo(desde, '#ff2040', 24, 8);
    if (!this.refAviso) { this.refAviso = true; HUD.anuncio('⚠ ¡REFUERZOS!', 'Mientras su robot viva, ARDUNOL mandará más robots', '#ff4466'); }
    else HUD.feed('🤖 ¡ARDUNOL llama ' + hechos + ' refuerzos!');
  },

  // robots vivos a la vez: 18 + 1 por jugador extra, hasta 30 (como Roblox)
  maxVivos() { return clamp(Math.round(Math.min(18 + (G.jugadores - 1), 30) * Profe.dif.cant), 4, 40); },

  empezar() {
    this.n++;
    this.tipo = this.PLAN[this.n] || 'normal';
    this.cola = this.componer();
    this.fase = 'oleada'; this.genT = 1.5; this.refT = 12; this.refAviso = false;
    this.anunciar();
  },

  // anuncio, clima y rejas al empezar una oleada (lo usan el profe y los alumnos)
  anunciar() {
    if (this.n >= 1 && !this.rejasAbiertas) { this.rejasAbiertas = true; Mapa.quitarRejas(); HUD.feed('🔓 ¡Se abrieron las rejas!'); }
    Clima.poner(this.tipo === 'final' ? 'desatado' : this.tipo === 'morado' ? 'final' : this.tipo === 'jefe' ? 'tormenta' : this.tipo === 'drones' ? 'niebla' : 'noche');
    if (this.tipo === 'final') { HUD.anuncio('☠ OLEADA FINAL ☠', 'ARDUNOL lanza su arma suprema', '#ff3355'); Sfx.play('jefe'); FX.sacudir(1.2); }
    else if (this.tipo === 'morado') { HUD.anuncio('⚡ OLEADA ' + this.n + ' ⚡', 'ARDUNOL despierta a su robot gigante', '#c879ff'); Sfx.play('jefe'); FX.sacudir(1); }
    else if (this.tipo === 'jefe') { HUD.anuncio('⚠ OLEADA ' + this.n + ' ⚠', '¡Llega el MEGA-ARDUINO!', '#ff6a3c'); Sfx.play('jefe'); FX.sacudir(0.6); }
    else if (this.tipo === 'drones') { HUD.anuncio('OLEADA ' + this.n, '¡Enjambre de drones!', '#9fe6a0'); Sfx.play('oleada'); }
    else { HUD.anuncio('OLEADA ' + this.n, this.n === 1 ? 'Los robots de ARDUNOL atacan' : this.cola.includes('Coloso') ? '¡Cuidado con el COLOSO!' : 'Más robots en camino', '#36c5ff'); Sfx.play('oleada'); }
    // en la oleada no se pelea entre alumnos (pvp.js): solo en el minuto libre
    if (Red.activa) HUD.feed('🛡 En la oleada <b>no</b> se pelea entre alumnos: ¡todos contra los robots!');
  },

  puntoAparicion(vuela) {
    for (let k = 0; k < 40; k++) {
      const eq = EQUIPOS[pick(G.equiposActivos)];
      const a = Math.random() < 0.75 ? eq.ang + rand(-0.6, 0.6) : Math.random() * TAU, r = Terreno.borde(a) - rand(18, 26);
      const x = Math.cos(a) * r, z = Math.sin(a) * r;
      if (Terreno.altura(x, z) < 1) continue;
      if (Math.hypot(x - Jugador.pos.x, z - Jugador.pos.z) < 28) continue;
      if (!vuela && G.cajas.some((c) => x > c.min.x - 2 && x < c.max.x + 2 && z > c.min.z - 2 && z < c.max.z + 2)) continue;
      return [x, z];
    }
    return [0, -110];
  },

  update(dt) {
    if (Red.cliente) { this.updateCliente(dt); return; }
    if (this.fase === 'esperaProfe') { HUD.oleada('PREPÁRATE', '🔒 Esperando que el profe abra las rejas'); return; }
    if (this.fase === 'descanso') {
      this.cuenta -= dt;
      if (this.quizEn > 0 && (this.quizEn -= dt) <= 0) Quiz.lanzar();
      this.hudDescanso();
      if (this.cuenta <= 0) this.empezar();
      return;
    }
    if (this.fase === 'oleada') {
      this.genT -= dt;
      const mult = (1 + (this.n - 1) * 0.06) * (1 + (G.jugadores - 1) * 0.03); // +3% de vida por jugador extra
      if (this.cola.length && this.genT <= 0 && Robots.vivos.length < this.maxVivos()) {
        const tipo = this.cola.shift();
        const [x, z] = tipo === 'JefeFinal' || tipo === 'Desatado' ? [POS_ARDUNOL[0] * 0.5, POS_ARDUNOL[1] * 0.5] : this.puntoAparicion(TIPOS[tipo].vuela);
        const r = Robots.crear(tipo, x, z, mult);
        if (r.mech) Mech.entrada(r);
        if (tipo === 'Coloso') HUD.anuncio('¡COLOSO!', 'Si te toca, caes. Mantén distancia', '#ff9a3c');
        this.genT = tipo === 'Jefe' ? 3 : rand(0.5, 1.1) / Math.sqrt(1 + (G.jugadores - 1) * 0.1) / Profe.dif.cant;
        if (tipo === 'Jefe') r.yaw = Math.atan2(x, z);
      }
      if (this.tipo === 'final') this.refuerzos(dt, mult);
      const quedan = this.cola.length + Robots.vivos.length;
      HUD.oleada(this.tipo === 'final' ? '☠ OLEADA FINAL ☠' : 'OLEADA ' + this.n + ' / ' + this.TOTAL, '🤖 ' + quedan + ' robots restantes');
      if (quedan === 0 && this.tipo === 'final') {
        // lo que sigue (equipo ganador y gran final) lo hace js/final.js
        this.fase = 'fin';
        return;
      }
      if (quedan === 0) this.superada();
    }
  },

  superada() {
    const bono = 20 * this.n;
    sumarPuntos(bono);
    HUD.anuncio('¡OLEADA SUPERADA!', '+' + bono + ' puntos de bonus', '#3ee08f');
    Jugador.curar(40);
    this.fase = 'descanso'; this.cuenta = this.DESCANSO; this.quizEn = 7; // la pregunta rápida, después de los anuncios
    this.aviso10 = false;
    Clima.poner('dia');
    // tiempo libre entre oleadas: para pelear contra otros equipos y resolver retos
    const n = this.n;
    setTimeout(() => {
      if (this.fase !== 'descanso' || this.n !== n || Final.estado) return;
      HUD.anuncio('⏱ ' + this.textoTiempo(this.DESCANSO) + ' DE TIEMPO LIBRE', '⚔ Pelea contra otros equipos · 🧩 Resuelve retos en tu base', '#36c5ff');
      Sfx.play('oleada');
    }, 3300);
  },

  textoTiempo(seg) { return seg >= 60 && seg % 60 === 0 ? (seg / 60 === 1 ? '1 MINUTO' : seg / 60 + ' MINUTOS') : seg + ' SEGUNDOS'; },

  // arriba de la pantalla durante el descanso (lo usan el profe y los alumnos)
  hudDescanso() {
    const s = Math.ceil(this.cuenta);
    if (this.n === 0) { HUD.oleada('PREPÁRATE', 'Las rejas se abren en ' + s + ' s'); return; }
    const reloj = Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
    const sig = this.n + 1 === this.TOTAL ? '☠ la OLEADA FINAL' : 'la oleada ' + (this.n + 1) + ' de ' + this.TOTAL;
    HUD.oleada('⏱ TIEMPO LIBRE · ' + reloj, '⚔ Pelea contra otros equipos · 🧩 Resuelve retos · luego ' + (this.n + 1 === this.TOTAL ? '☠ oleada final' : 'oleada ' + (this.n + 1) + '/' + this.TOTAL));
    // aviso cuando faltan 10 segundos
    if (this.cuenta > 10.5) this.aviso10 = false;
    else if (!this.aviso10 && this.cuenta > 0) { this.aviso10 = true; HUD.anuncio('⚠ ¡QUEDAN 10 SEGUNDOS!', '¡Prepárate! Llega ' + sig, '#ff9a3c'); }
  },

  // ---------- alumno: la oleada la decide el profe ----------
  aplicarRed(n, fase, cuenta, tipo, quedan) {
    if (n > this.n) { this.n = n; this.tipo = tipo; this.cola = []; this.anunciar(); }
    if (this.fase === 'oleada' && fase === 'descanso') this.superada();
    this.n = n; this.fase = fase; this.cuenta = cuenta; this.tipo = tipo; this.quedan = quedan;
  },
  updateCliente(dt) {
    if (this.quizEn > 0 && (this.quizEn -= dt) <= 0) Quiz.lanzar();
    if (this.fase === 'esperaProfe') HUD.oleada('PREPÁRATE', '🔒 Esperando que el profe abra las rejas');
    else if (this.fase === 'descanso') {
      this.cuenta = Math.max(0, this.cuenta - dt);
      this.hudDescanso();
    } else if (this.fase === 'oleada') HUD.oleada(this.tipo === 'final' ? '☠ OLEADA FINAL ☠' : 'OLEADA ' + this.n + ' / ' + this.TOTAL, '🤖 ' + (this.quedan || 0) + ' robots restantes');
  },
};
