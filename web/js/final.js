// =====================================================================
//  GRAN FINAL
//  1) Cae ARDUNOL DESATADO → su ejército se apaga y explota.
//  2) Se anuncia el EQUIPO GANADOR: el que tiene más puntos.
//  3) GRAN FINAL: todos los alumnos aparecen lejos unos de otros alrededor
//     de la plaza. El ARDUINO SUPREMO flota sobre el pedestal del centro.
//     Tras una cuenta de 5 s: ¡todos contra todos, incluso tu equipo!
//     Quien cae queda eliminado (mira desde arriba).
//  4) El último en pie se lleva el ARDUINO SUPREMO.
//  5) Pantalla final: equipo ganador + jugador que tomó el Arduino.
//  En multijugador la computadora del profe decide cada paso y avisa a todos.
//  (el Arduino es el mismo modelo de Tinkercad de las piezas)
// =====================================================================
const Final = {
  estado: null,   // null · 'apagando' · 'ganador' · 'cuenta' · 'arena' · 'campeon'
  trofeo: null, t: 0, pos: null,
  ALTO: 3.2,      // metros que mide el Arduino trofeo
  SUBE: 3.2,      // altura a la que flota (sobre el pedestal)
  CUENTA: 5,      // segundos antes de que empiece la pelea
  RADIO: 50,      // distancia al centro de la plaza donde aparece cada jugador
  combate: false, // true = ya se puede pelear en la gran final
  ganador: null,  // { eq, pts } equipo con más puntos
  campeon: null,  // { id, nombre, eq } quien se quedó con el Arduino
  vivos: null,    // (profe) ids de los que siguen en pie
  quedan: 0,      // jugadores en pie (para el HUD)
  espectador: false,

  todosContraTodos() { return this.estado === 'cuenta' || this.estado === 'arena'; },

  // lo llama Robots.morir cuando muere el jefe final
  jefeCayo(r) {
    if (this.estado) return;
    this.estado = 'apagando'; this.t = 0;
    Jugador.invulnerable = 999;        // los robots ya no te hacen nada
    HUD.jefe(null);
    HUD.anuncio('¡EL ROBOT DE ARDUNOL CAYÓ!', 'Sin su creador, el ejército se apaga…', '#ffcf4a');
    if (Red.cliente) return;           // en los alumnos, el resto lo hace la computadora del profe
    Oleadas.cola.length = 0;           // no llegan más robots
    // el resto de robots explota en cadena
    const resto = Robots.vivos.filter((o) => o !== r && !o.muerto).sort(() => Math.random() - 0.5);
    resto.forEach((o, i) => { o.apagarEn = 0.6 + i * 0.18; });
    // las balas en el aire desaparecen
    for (const b of Robots.balas) { FX.chispazo(b.pos, '#ffcf4a', 6, 3); G.scene.remove(b.m); }
    Robots.balas.length = 0;
  },

  // ---------- 2) equipo ganador ----------
  equipoGanador() {
    // con sala: solo cuentan los equipos que tienen alumnos
    let eqs = Red.host ? [...new Set([...Red.remotos.values()].filter((j) => !j.profe).map((j) => j.equipo))] : [];
    if (!eqs.length) eqs = G.equiposActivos.length ? G.equiposActivos : [MI_EQUIPO];
    let mejor = eqs[0];
    for (const i of eqs) if ((G.puntosEq[i] || 0) > (G.puntosEq[mejor] || 0)) mejor = i;
    return { eq: mejor, pts: G.puntosEq[mejor] || 0 };
  },

  anunciarGanador(g) {
    if (this.estado === 'ganador' || this.todosContraTodos() || this.estado === 'campeon') return;
    this.estado = 'ganador'; this.t = 0; this.ganador = g;
    if (Red.host) Red.ev({ a: 'finGanador', eq: g.eq, pts: g.pts });
    const eq = EQUIPOS[g.eq];
    Clima.poner('dia');
    Sfx.play('oleada');
    HUD.anuncio('🏆 ¡GANA EL ' + eq.nombre.toUpperCase() + '!', 'Es el equipo con más puntos: ' + g.pts, eq.color);
    HUD.feed('🏆 El <b style="color:' + eq.color + '">' + eq.nombre + '</b> ganó la batalla con <b>' + g.pts + '</b> puntos');
    setTimeout(() => { if (this.estado === 'ganador') HUD.anuncio('⚔ GRAN FINAL ⚔', 'El último en pie se llevará el ARDUINO SUPREMO', '#ffcf4a'); }, 3400);
  },

  // ---------- 3) gran final ----------
  // (profe o un jugador solo) elige quién juega y dónde aparece cada uno
  empezarArena() {
    const lista = [];
    if (Red.activa) for (const j of Red.remotos.values()) { if (!j.profe) lista.push({ id: j.id, nombre: j.nombre, eq: j.equipo }); }
    if (!G.profe) lista.push({ id: Red.activa ? Red.id : 0, nombre: G.miNombre, eq: MI_EQUIPO });
    // con 0 o 1 jugador no hay pelea: se lo lleva directo
    if (lista.length <= 1) {
      const c = lista[0] || { id: Red.activa ? Red.id : 0, nombre: G.miNombre, eq: MI_EQUIPO };
      this.coronar(c);
      return;
    }
    // se reparten alternando equipos: así los compañeros quedan lejos entre sí
    const porEq = {};
    for (const j of lista.sort(() => Math.random() - 0.5)) (porEq[j.eq] = porEq[j.eq] || []).push(j);
    const orden = [], grupos = Object.values(porEq);
    while (orden.length < lista.length) for (const g of grupos) if (g.length) orden.push(g.shift());
    const giro = Math.random() * TAU;
    const pos = orden.map((j, i) => { const [x, z] = this.lugar(giro + (i / orden.length) * TAU); return [j.id, x, z]; });
    this.vivos = new Set(orden.map((j) => j.id));
    this.datos = new Map(orden.map((j) => [j.id, j]));
    this.ultimoCaido = null;
    if (Red.host) Red.ev({ a: 'arena', p: pos, g: [this.ganador.eq, this.ganador.pts] });
    this.empezarCuenta(pos);
  },

  // un punto libre (sin agua ni edificios) cerca del círculo de la gran final
  lugar(a) {
    for (const d of [0, 4, -4, 8, -8, 12, -12, 16, 20]) {
      const r = this.RADIO + d, x = Math.cos(a) * r, z = Math.sin(a) * r;
      if (Terreno.altura(x, z) < 1) continue;
      if (G.cajas.some((c) => c.max.y - c.min.y > 0.7 && x > c.min.x - 1.2 && x < c.max.x + 1.2 && z > c.min.z - 1.2 && z < c.max.z + 1.2)) continue;
      return [+x.toFixed(1), +z.toFixed(1)];
    }
    return [+(Math.cos(a) * 26).toFixed(1), +(Math.sin(a) * 26).toFixed(1)];
  },

  // todos: te lleva a tu lugar y empieza la cuenta regresiva
  empezarCuenta(pos) {
    this.estado = 'cuenta'; this.t = 0; this.combate = false; this._seg = null;
    this.quedan = pos.length;
    this.pos = V3(0, SUELO + 2.6, 0);  // sobre el pedestal de la plaza
    if (!this.trofeo) this.crearTrofeo();
    if (Torretas.montada) Torretas.bajar();
    if (Estacion.abierta) Estacion.cerrar();
    if (Tienda.abierta) Tienda.cerrar();
    const mio = pos.find(([id]) => id === (Red.activa ? Red.id : 0));
    if (mio) {
      const [, x, z] = mio;
      Poderes.volando = false;
      Jugador.muerto = false; Jugador.vida = Jugador.vidaMax; HUD.muerte(false);
      Jugador.pos.set(x, alturaSuelo(x, z, 60, 0.4), z); Jugador.vel.set(0, 0, 0); Jugador.empuje.set(0, 0, 0);
      Jugador.yaw = Math.atan2(x, z); Jugador.pitch = 0; // mirando al Arduino
      Jugador.invulnerable = this.CUENTA + 0.5;
      FX.chispazo(Jugador.centro(), '#ffcf4a', 24, 6);
    } else if (G.profe) {
      // el profe mira desde el aire (no pelea)
      Poderes.volando = true;
      Jugador.pos.set(0, 34, 30); Jugador.vel.set(0, 0, 0); Jugador.yaw = 0; Jugador.pitch = -0.7;
    } else {
      // llegó tarde a la sala: mira la final
      this.espectador = true; Jugador.muerto = true; Jugador.pos.y = SUELO + 20;
    }
    Sfx.play('jefe'); FX.sacudir(0.5);
    HUD.anuncio('⚔ ¡TODOS CONTRA TODOS! ⚔', 'Incluso contra tu equipo · el último en pie se lleva el ARDUINO SUPREMO', '#ffcf4a');
  },

  // (profe) un jugador cayó en la gran final
  alCaer(j) {
    if (!this.vivos || !this.vivos.has(j.id)) return;
    this.vivos.delete(j.id); this.ultimoCaido = this.datos.get(j.id);
    if (this.vivos.size > 1) { const t = '🧍 Quedan <b>' + this.vivos.size + '</b> en pie'; HUD.feed(t); Red.ev({ a: 'feed', txt: t }); }
  },

  // (alumno) te eliminaron en la gran final
  eliminado() {
    this.espectador = true;
    HUD.anuncio('💀 ¡ELIMINADO!', 'Mira desde arriba quién se lleva el Arduino', '#ff4d5e');
    setTimeout(() => { if (Jugador.muerto) HUD.muerte(false); }, 3000);
  },

  // (profe) ¿queda uno solo en pie?
  revisarArena() {
    if (!this.combate || !this.vivos) return;
    for (const id of [...this.vivos]) {
      const j = Red.remotos.get(id);
      if (!j || j.muerto) { this.vivos.delete(id); this.ultimoCaido = this.datos.get(id); }
    }
    this.quedan = this.vivos.size;
    if (this.vivos.size <= 1) this.coronar(this.datos.get([...this.vivos][0]) || this.ultimoCaido);
  },

  // (profe) botón del panel: termina ya; gana el que tiene más vida
  terminarYa() {
    if (this.estado !== 'arena' || !this.vivos) return;
    let mejor = null, mv = -1;
    for (const id of this.vivos) { const j = Red.remotos.get(id); if (j && !j.muerto && j.vida > mv) { mv = j.vida; mejor = id; } }
    this.coronar(this.datos.get(mejor) || this.ultimoCaido);
  },

  // ---------- 4) el último en pie se lleva el Arduino ----------
  coronar(c) {
    if (this.estado === 'campeon') return;
    if (!c) c = { id: Red.activa ? Red.id : 0, nombre: G.miNombre, eq: MI_EQUIPO }; // no quedó nadie (se fueron todos)
    if (!this.ganador) this.ganador = this.equipoGanador();
    if (Red.host) Red.ev({ a: 'campeon', id: c.id, q: c.nombre, eq: c.eq, g: [this.ganador.eq, this.ganador.pts] });
    this.entregar(c);
  },

  entregar(c) {
    this.estado = 'campeon'; this.t = 0; this.combate = false; this.vivos = null; this.campeon = c;
    Jugador.invulnerable = 999;
    if (!this.pos) this.pos = V3(0, SUELO + 2.6, 0);
    if (!this.trofeo) this.crearTrofeo();
    const yo = c.id === (Red.activa ? Red.id : 0);
    const eq = EQUIPOS[c.eq];
    HUD.anuncio('👑 ' + c.nombre.toUpperCase() + ' TOMÓ EL ARDUINO SUPREMO', yo ? '¡Eres el último en pie!' : 'del ' + eq.nombre, eq.color);
    HUD.feed('👑 <b style="color:' + eq.color + '">' + c.nombre + '</b> se llevó el ARDUINO SUPREMO');
    const T = this.trofeo;
    Sfx.play('recoger'); Sfx.play('oleada');
    FX.explosion(T.giro.getWorldPosition(V3()), 5, '#ffcf4a');
    FX.aro(this.pos, 30, '#ffffff', 1.4); FX.sacudir(0.6);
    Clima.flash = 1;
    // el Arduino vuela hacia el campeón y se encoge
    const remoto = Red.activa ? Red.remotos.get(c.id) : null;
    const hacia = () => (yo ? Jugador.ojo() : remoto && remoto.av.raiz.visible ? remoto.visto.clone().setY(remoto.visto.y + 1.6) : this.pos.clone().setY(this.pos.y + 30));
    const desde = T.giro.getWorldPosition(V3()), t0 = G.t;
    T.et.visible = false;
    const f = () => {
      const e = Math.min(1, (G.t - t0) / 1.2);
      T.giro.position.copy(desde.clone().lerp(hacia(), e * e).sub(T.g.position));
      T.giro.scale.setScalar(Math.max(0.01, 1 - e * 0.9));
      T.columna.material.opacity *= 0.95; T.luz.intensity *= 0.95;
      if (e >= 1) { G.anim.splice(G.anim.indexOf(f), 1); G.scene.remove(T.g); }
    };
    G.anim.push(f);
    if (yo) sumarPuntos(500);
    setTimeout(() => HUD.victoria(), 1500);
  },

  // ---------- mensajes de la computadora del profe (alumnos) ----------
  recibirGanador(e) { this.anunciarGanador({ eq: e.eq, pts: e.pts }); },
  recibirArena(e) {
    if (!this.ganador && e.g) this.ganador = { eq: e.g[0], pts: e.g[1] };
    if (this.estado === 'campeon') return;
    this.empezarCuenta(e.p || []);
  },
  recibirCampeon(e) {
    if (e.g) this.ganador = { eq: e.g[0], pts: e.g[1] };
    if (this.estado === 'campeon') return;
    this.entregar({ id: e.id, nombre: e.q, eq: e.eq });
  },

  crearTrofeo() {
    const g = new THREE.Group();
    g.position.copy(this.pos);
    // el Arduino parado de frente, un poco inclinado hacia atrás
    const pieza = PIEZAS.find((p) => p.id === 'arduino');
    const m = Componentes.malla(pieza);
    const bb = m.geometry.boundingBox, tam = bb.getSize(V3()), c = bb.getCenter(V3());
    const s = this.ALTO / Math.max(tam.x, tam.y, tam.z);
    m.scale.setScalar(s);
    m.position.copy(c).multiplyScalar(-s);             // centrado
    m.castShadow = true;
    const parado = new THREE.Group(); parado.add(m);
    parado.rotation.x = Math.PI / 2 - 0.15;            // la placa de pie, mirando al frente
    const giro = new THREE.Group(); giro.add(parado); g.add(giro);
    // halo dorado detrás
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: Terror.textura(), color: col('#ffcf4a').multiplyScalar(2.2), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    halo.scale.setScalar(5.5); halo.position.z = -0.6; giro.add(halo);
    // tres aros dorados que giran
    const matAro = new THREE.MeshBasicMaterial({ color: col('#ffcf4a').multiplyScalar(3) });
    const aros = [1.9, 2.3, 2.7].map((rad, i) => {
      const a = new THREE.Mesh(new THREE.TorusGeometry(rad, 0.045, 8, 64), matAro);
      a.rotation.set(Math.PI / 2 + i * 0.5, i * 0.7, 0); giro.add(a); return a;
    });
    // columna de luz hasta el cielo
    const columna = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 0.5, 160, 24, 1, true),
      new THREE.MeshBasicMaterial({ color: col('#ffd86a').multiplyScalar(1.6), transparent: true, opacity: 0, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }));
    columna.position.y = this.SUBE + 2.2 + 80; g.add(columna);   // sale desde arriba del Arduino
    // círculo brillante en el suelo
    const suelo = new THREE.Mesh(new THREE.CircleGeometry(4, 40).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ map: Terror.textura(), color: col('#ffcf4a').multiplyScalar(0.9), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    suelo.position.y = 0.08; g.add(suelo);
    const luz = new THREE.PointLight('#fff1c4', 0, 30, 1.5); luz.position.y = this.SUBE; g.add(luz);
    const et = Componentes.etiqueta('🏆 ARDUINO SUPREMO', 'El último en pie se lo lleva'); et.position.y = this.SUBE + 2.6; et.scale.multiplyScalar(1.6); g.add(et);
    for (const o of [halo, columna, suelo, et]) o.raycast = () => {};
    G.scene.add(g);
    this.trofeo = { g, giro, aros, columna, suelo, luz, et, halo, t0: G.t };
    FX.explosion(this.pos.clone().setY(this.pos.y + 1), 4, '#ffcf4a');
    FX.aro(this.pos, 18, '#ffcf4a', 1.2);
  },

  update(dt) {
    if (!this.estado) return;
    this.t += dt;
    // robots que quedaban: se apagan y explotan
    for (const o of [...Robots.vivos]) {
      if (o.apagarEn === undefined) continue;
      o.apagarEn -= dt;
      if (o.apagarEn <= 0) { o.apagarEn = undefined; Robots.danar(o, 1e7, o.centro()); }
    }
    const manda = !Red.cliente; // la computadora del profe (o tú, si juegas solo) decide cada paso
    if (this.estado === 'apagando') {
      HUD.oleada('🏆 ¡VICTORIA!', 'El ejército de ARDUNOL se apaga…');
      if (manda && this.t > 3.6) this.anunciarGanador(this.equipoGanador());
    } else if (this.estado === 'ganador') {
      const eq = EQUIPOS[this.ganador.eq];
      HUD.oleada('🏆 GANA EL ' + eq.nombre.toUpperCase(), 'La GRAN FINAL empieza en ' + Math.max(0, Math.ceil(8 - this.t)) + ' s');
      if (manda && this.t > 8) this.empezarArena();
    } else if (this.estado === 'cuenta') {
      const seg = Math.ceil(this.CUENTA - this.t);
      HUD.oleada('⚔ GRAN FINAL ⚔', 'La pelea empieza en ' + Math.max(0, seg) + ' s');
      if (seg !== this._seg && seg > 0 && seg <= 3) { this._seg = seg; HUD.anuncio(String(seg), '', '#ffcf4a'); Sfx.play('trampolin'); }
      if (this.t >= this.CUENTA) {
        this.estado = 'arena'; this.combate = true;
        if (!this.espectador && !G.profe) Jugador.invulnerable = 0;
        HUD.anuncio('⚔ ¡A PELEAR! ⚔', 'El último en pie se lleva el ARDUINO SUPREMO', '#ff5533');
        Sfx.play('oleada'); FX.sacudir(0.6);
      }
    } else if (this.estado === 'arena') {
      if (Red.host) this.revisarArena();
      HUD.oleada('⚔ GRAN FINAL ⚔', '🧍 ' + this.quedan + ' en pie · gana el último' + (this.espectador ? ' · 👀 estás mirando (WASD para moverte)' : ''));
    } else if (this.estado === 'campeon' && this.campeon) {
      HUD.oleada('👑 ' + this.campeon.nombre + ' tiene el ARDUINO SUPREMO', '🏆 Equipo ganador: ' + EQUIPOS[this.ganador.eq].nombre);
    }
    const T = this.trofeo;
    if (!T || this.estado === 'campeon') return;
    // animación del trofeo: sube del pedestal y flota
    const sube = smooth(0, 1, (G.t - T.t0) / 2.8);
    T.giro.position.y = 0.4 + sube * (this.SUBE - 0.4) + Math.sin(G.t * 2) * 0.15 * sube;
    T.giro.rotation.y += dt * (0.8 + (1 - sube) * 6);
    T.aros.forEach((a, i) => { a.rotation.x += dt * (0.6 + i * 0.4); a.rotation.y += dt * (0.9 - i * 0.3); });
    T.halo.material.opacity = 0.3 + Math.sin(G.t * 3) * 0.1;
    T.columna.material.opacity = sube * 0.3 * (0.8 + Math.sin(G.t * 5) * 0.2);
    T.luz.intensity = sube * 60;
    // la luz va del lado de la cámara para que se vea bien la placa
    const haciaCam = G.camera.getWorldPosition(V3()).sub(this.pos).setY(0).normalize().multiplyScalar(3);
    T.luz.position.set(haciaCam.x, T.giro.position.y + 1, haciaCam.z);
    if (Math.random() < dt * 30) {
      const a = Math.random() * TAU, rr = rand(0.5, 3);
      FX.chispas.emitir(this.pos.x + Math.cos(a) * rr, this.pos.y + rand(0, 1), this.pos.z + Math.sin(a) * rr, 0, rand(2, 6), 0, FX.c('#ffcf4a', 3), rand(0.08, 0.2), rand(1, 2));
    }
  },
};
