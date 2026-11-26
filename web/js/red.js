// =====================================================================
//  MULTIJUGADOR (fase 3)
//  - El profe crea la sala (con su clave) y su computadora es la
//    "anfitriona": mueve robots y oleadas y manda una foto 10 veces/s.
//  - Los alumnos entran con el código: ven los robots de la foto,
//    les disparan (el daño se le avisa al profe) y reciben golpes.
//  - Todos ven a todos: soldados de bloques con nombre y barra.
//  Sin código de sala, el juego sigue siendo de un jugador.
// =====================================================================
const SERVIDOR = ['localhost', '127.0.0.1'].includes(location.hostname)
  ? 'ws://localhost:8090'
  : 'wss://roba-un-arduino.onrender.com';

const FASES = ['espera', 'esperaProfe', 'descanso', 'oleada', 'fin'];
const TIPOS_LISTA = Object.keys(TIPOS);
const BALAS_LISTA = ['rayo', 'orbe', 'misil'];

// un jugador de la sala, visto como "objetivo" por los robots del profe
class JugadorRemoto {
  constructor(d) {
    Object.assign(this, { id: d.id, nombre: d.nombre, color: d.color, equipo: d.equipo, profe: d.profe, remoto: true });
    this.pos = V3(0, -100, 0); this.vel = V3(); this.yaw = 0; this.pitch = 0; this.radio = 0.42;
    this.vida = 100; this.vidaMax = 100; this.muerto = true; this.enSuelo = true; this.tiros = 0;
    this.stats = [0, 0, 0, 0]; this.listo = false; this.t999 = -9;
    this.av = Avatar.crear({ nombre: d.nombre, color: d.color, equipo: d.equipo, profe: d.profe });
    this.av.raiz.visible = false;
    this.visto = V3(); this.yawVis = 0;
    G.scene.add(this.av.raiz);
  }
  centro(v = V3()) { return v.set(this.pos.x, this.pos.y + 1.0, this.pos.z); }
  ojo(v = V3()) { return v.set(this.pos.x, this.pos.y + 1.62, this.pos.z); }
  // los robots del profe le hacen daño: se le avisa a ese alumno
  danar(cant, origen, tipo) {
    if (this.muerto) return;
    if (cant >= 999) { if (G.t - this.t999 < 1) return; this.t999 = G.t; }
    Red.ev({ a: 'herido', c: Math.round(cant), x: +origen.x.toFixed(1), y: +origen.y.toFixed(1), z: +origen.z.toFixed(1), tp: tipo }, this.id);
  }
  quitar() { G.scene.remove(this.av.raiz); }
}

const Red = {
  activa: false, host: false, cliente: false, id: 0, codigo: '', ws: null,
  remotos: new Map(), robots: new Map(), balasVis: [], tiros: 0, ultSnap: 0,

  proxies() { return this.activa ? [...this.remotos.values()].filter((j) => j.listo) : []; },

  msg(t) { const el = document.getElementById('redMsg'); if (el) el.innerHTML = t || ''; },

  // o = { crear: true, clave } (profe)  ·  { codigo } (alumno)
  conectar(o) {
    return new Promise((ok) => {
      this.msg('🌐 Conectando al servidor… <small>(si estaba dormido puede tardar hasta 1 minuto)</small>');
      let ws;
      try { ws = new WebSocket(SERVIDOR); } catch (e) { this.msg('❌ No se pudo conectar al servidor.'); ok(false); return; }
      const limite = setTimeout(() => { this.msg('❌ El servidor no respondió. Intenta de nuevo en un momento.'); ws.close(); ok(false); }, 90000);
      ws.onopen = () => {
        const yo = { nombre: G.miNombre, color: G.miColor, equipo: MI_EQUIPO };
        ws.send(JSON.stringify(o.crear ? { t: 'crear', clave: o.clave, ...yo } : { t: 'unirse', codigo: o.codigo, ...yo }));
      };
      ws.onmessage = (e) => {
        const m = JSON.parse(e.data);
        if (m.t === 'sala') {
          clearTimeout(limite);
          Object.assign(this, { ws, activa: true, host: m.host, cliente: !m.host, id: m.id, codigo: m.codigo });
          for (const d of m.jugadores) this.agregar(d);
          ws.onmessage = (ev) => this.recibir(JSON.parse(ev.data));
          ws.onclose = () => this.perdida();
          this.msg('');
          this.intervalo = setInterval(() => this.tick(), 100);
          ok(true);
        } else if (m.t === 'error') {
          clearTimeout(limite);
          this.msg({ clave: '❌ El servidor no aceptó la clave del profe.', nosala: '❌ No existe una sala con ese código. Revisa los números.', llena: '❌ La sala está llena (30 alumnos).' }[m.e] || '❌ Error: ' + m.e);
          ws.close(); ok(false);
        }
      };
      ws.onerror = () => { clearTimeout(limite); this.msg('❌ No se pudo conectar al servidor. ¿Hay internet?'); ok(false); };
    });
  },

  enviar(m) { if (this.ws && this.ws.readyState === 1) this.ws.send(JSON.stringify(m)); },
  // evento: para = id de un jugador · 'host' (alumno → profe) · nada (profe → todos)
  ev(e, para) { if (this.activa) this.enviar({ t: 'ev', e, para: para === 'host' ? undefined : para }); },

  agregar(d) {
    if (d.id === this.id || this.remotos.has(d.id)) return;
    this.remotos.set(d.id, new JugadorRemoto(d));
    this.actualizarConteo();
  },
  actualizarConteo() {
    G.jugadores = 1 + this.remotos.size;
    if (this.host) {
      const eqs = new Set([MI_EQUIPO, ...[...this.remotos.values()].map((j) => j.equipo)]);
      G.equiposActivos = [...eqs];
    }
    document.getElementById('hudJug').textContent = G.jugadores;
    this.hudSala();
  },
  hudSala() {
    const el = document.getElementById('salaHud'); if (!el) return;
    el.classList.toggle('oculto', !this.activa);
    el.innerHTML = '🌐 Sala <b>' + this.codigo + '</b> · ' + G.jugadores + ' 👥';
  },

  perdida() {
    if (!this.activa) return;
    this.activa = false; clearInterval(this.intervalo);
    HUD.anuncio('📡 SE PERDIÓ LA CONEXIÓN', 'Recarga la página para volver a entrar', '#ff4d5e');
  },

  // ---------- mensajes que llegan ----------
  recibir(m) {
    switch (m.t) {
      case 'entra': this.agregar(m.j); HUD.feed('👋 <b>' + m.j.nombre + '</b> entró a la sala'); break;
      case 'sale': {
        const j = this.remotos.get(m.id); if (!j) break;
        j.quitar(); this.remotos.delete(m.id); this.actualizarConteo();
        HUD.feed('🚪 <b>' + j.nombre + '</b> salió de la sala');
        break;
      }
      case 'js': for (const [id, d] of m.l) if (id !== this.id) this.posicion(id, d); break;
      case 'snap': this.aplicarSnap(m); break;
      case 'ev': this.evento(m.e, m.de); break;
      case 'cerrada': this.activa = false; HUD.anuncio('🚪 EL PROFE CERRÓ LA SALA', 'Gracias por jugar', '#ffcf4a'); setTimeout(() => location.reload(), 5000); break;
      case 'expulsado': this.activa = false; HUD.anuncio('🚪 EL PROFE TE SACÓ DE LA SALA', '', '#ff4d5e'); setTimeout(() => location.reload(), 4000); break;
    }
  },

  posicion(id, d) {
    const j = this.remotos.get(id); if (!j) return;
    const [x, y, z, yaw, pitch, vida, vidaMax, muerto, enSuelo, tiros, vx, vz, ...stats] = d;
    j.pos.set(x, y, z); j.vel.set(vx, 0, vz); j.yaw = yaw; j.pitch = pitch;
    j.vida = vida; j.vidaMax = vidaMax; j.muerto = !!muerto; j.enSuelo = !!enSuelo; j.stats = stats;
    if (!j.listo) { j.listo = true; j.visto.copy(j.pos); j.yawVis = yaw; }
    if (tiros > j.tiros && j.av.raiz.visible) this.disparoDe(j);
    j.tiros = tiros;
    j.av.vida = vida; j.av.vidaMax = vidaMax;
  },

  disparoDe(j) {
    j.av.disparo = 0.12; j.dispT = 0.6;
    const boca = Avatar.bocaArma(j.av);
    const dir = V3(-Math.sin(j.yaw) * Math.cos(j.pitch), Math.sin(j.pitch), -Math.cos(j.yaw) * Math.cos(j.pitch));
    const fin = j.ojo().addScaledVector(dir, Math.min(30, rayoMundo(j.ojo(), dir, 30)));
    FX.segmento(boca, fin, 0.035, EQUIPOS[j.equipo].color, 0.07, 3.5);
    FX.segmento(boca, fin, 0.011, '#ffffff', 0.05, 5);
    FX.chispazo(boca, EQUIPOS[j.equipo].color, 4, 3, 0.06);
  },

  // ---------- eventos ----------
  evento(e, de) {
    const j = this.remotos.get(de);
    switch (e.a) {
      // --- al profe ---
      case 'dano': {
        const r = Robots.vivos.find((x) => x.id === e.rid);
        if (r && !r.muerto && j) Robots.danar(r, Math.min(+e.c || 0, 5000), null, !!e.k, j);
        break;
      }
      case 'suma': if (j) { const n = Math.max(0, Math.min(2000, +e.n || 0)); G.puntosEq[j.equipo] += n; if (j.equipo === MI_EQUIPO) { G.puntos += n; HUD.puntos(); } } break;
      case 'robar': if (Final.estado === 'listo') Final.robar(j ? j.nombre : null); break;
      // --- a los alumnos ---
      case 'herido': if (!Jugador.muerto) Jugador.danar(e.c, V3(e.x, e.y, e.z), e.tp); break;
      case 'puntos': G.canje += e.n; G.misPuntos += e.n; G.bajas++; HUD.puntos(); HUD.feed('⭐ ¡Robot destruido! <b>+' + e.n + '</b>'); break;
      case 'muere': {
        const r = this.robots.get(e.rid); if (!r || r.muerto) break;
        this.robots.delete(e.rid);
        Robots.morir(r, { nombre: e.q || '👑 el profe', equipo: -1 });
        break;
      }
      case 'quiz': if (!Quiz.activa) Quiz.lanzar(); break;
      case 'curar': Jugador.curar(9999); HUD.feed('👑 El profe curó a todos ❤️'); break;
      case 'robado': if (Final.estado !== 'robado') Final.robar(e.q); break;
      case 'feed': HUD.feed(e.txt); break;
    }
  },

  // ---------- 10 veces por segundo ----------
  tick() {
    if (!this.activa) return;
    const J = Jugador, s = [Estacion.resueltos, Estacion.acertadas.size + (Quiz.aciertos || 0)];
    this.enviar({ t: 'yo', d: [+J.pos.x.toFixed(2), +J.pos.y.toFixed(2), +J.pos.z.toFixed(2), +J.yaw.toFixed(3), +J.pitch.toFixed(3),
      Math.round(J.vida), J.vidaMax, J.muerto ? 1 : 0, J.enSuelo ? 1 : 0, this.tiros, +J.vel.x.toFixed(1), +J.vel.z.toFixed(1),
      G.misPuntos, G.bajas, ...s] });
    if (this.host) this.enviarSnap();
  },

  enviarSnap() {
    const R = (v) => Math.round(v * 100) / 100;
    const O = Oleadas;
    const robots = Robots.vivos.filter((r) => !r.muerto).map((r) => {
      const fl = (r.furia ? 1 : 0) | (r.rafaga > 0 ? 2 : 0);
      let laser = 0;
      if (r.laser && r.laser.punto) laser = [R(r.laser.punto.x), R(r.laser.punto.y), R(r.laser.punto.z), r.laser.t < 1 ? 1 : 0];
      return [r.id, TIPOS_LISTA.indexOf(r.tipo), R(r.pos.x), R(r.pos.y + r.salto), R(r.pos.z), R(r.yaw), Math.round((r.vida / r.vidaMax) * 1000), fl, laser];
    });
    const balas = Robots.balas.slice(0, 50).map((b) => [BALAS_LISTA.indexOf(b.tipo), R(b.pos.x), R(b.pos.y), R(b.pos.z)]);
    const quedan = O.cola.length + Robots.vivos.length;
    this.enviar({ t: 'snap', r: robots, b: balas, o: [O.n, FASES.indexOf(O.fase), R(O.cuenta), O.tipo, quedan], p: G.puntosEq, d: Profe.nivel,
      z: G.estado === 'pausaProfe' ? 1 : 0, eq: G.equiposActivos });
  },

  // ---------- el alumno recibe la foto del profe ----------
  aplicarSnap(s) {
    this.ultSnap = performance.now();
    const vistos = new Set();
    for (const [id, ti, x, y, z, yaw, vf, fl, laser] of s.r) {
      vistos.add(id);
      let r = this.robots.get(id);
      if (!r) {
        const tipo = TIPOS_LISTA[ti]; if (!tipo) continue;
        r = Robots.crear(tipo, x, z, 1);
        r.rid = id; r.remoto = true; r.pos.set(x, y, z); r.destino = V3(x, y, z);
        this.robots.set(id, r);
      }
      r.faltas = 0;
      r.destino.set(x, y, z); r.yawDestino = yaw;
      r.vida = (vf / 1000) * r.vidaMax;
      if ((fl & 1) && !r.furia) { r.furia = true; if (!r.mech) for (const m of r.mats) m.emissive.set('#ff2200'); }
      r.rafaga = fl & 2 ? 1 : 0;
      r.laserRed = laser || null;
      if (r.cfg.jefe) HUD.jefe(r.cfg.nombre, vf / 1000);
    }
    // robots que ya no están (sin aviso de muerte): se quitan
    for (const [id, r] of this.robots) {
      if (vistos.has(id)) continue;
      if (++r.faltas > 4) { this.robots.delete(id); if (!r.muerto) Robots.morir(r, { nombre: '', equipo: -1, silencio: true }); }
    }
    // balas enemigas
    while (this.balasVis.length > s.b.length) G.scene.remove(this.balasVis.pop().m);
    s.b.forEach(([ti, x, y, z], i) => {
      let b = this.balasVis[i];
      if (!b || b.ti !== ti) {
        if (b) G.scene.remove(b.m);
        const m = ti === 1 ? new THREE.Mesh(RM.SP(0.45, 12, 8), RM.L('#ff8a2a', 4)) : ti === 2 ? new THREE.Mesh(RM.CY(0.18, 0.18, 1.2, 10), RM.M('#3b3f4a', { m: 0.7 })) : new THREE.Mesh(RM.SP(0.16, 8, 6), RM.L('#ff2a2a', 5));
        G.scene.add(m); b = this.balasVis[i] = { ti, m };
      }
      b.m.position.set(x, y, z);
      if (ti === 2) FX.humo.emitir(x, y, z, 0, 0.5, 0, new THREE.Color(0.35, 0.35, 0.35), 0.3, 1, { crece: 1.2, a: 0.5 });
    });
    // oleada, puntos, dificultad, pausa
    Oleadas.aplicarRed(s.o[0], FASES[s.o[1]], s.o[2], s.o[3], s.o[4]);
    G.puntosEq = s.p; G.puntos = s.p[MI_EQUIPO] || 0; HUD.puntos();
    if (Profe.nivel !== s.d) Profe.nivel = s.d;
    if (!!s.z !== (G.estado === 'pausaProfe') && G.estado !== 'menu') Profe.pausar(!!s.z);
    if (s.eq) G.equiposActivos = s.eq;
  },

  // ---------- cada cuadro ----------
  update(dt) {
    if (!this.activa) return;
    for (const j of this.remotos.values()) {
      const av = j.av;
      av.raiz.visible = j.listo && !j.muerto;
      if (!av.raiz.visible) continue;
      const antes = j.visto.clone();
      j.visto.lerp(j.pos, 1 - Math.exp(-14 * dt));
      let dy = j.yaw - j.yawVis; while (dy > Math.PI) dy -= TAU; while (dy < -Math.PI) dy += TAU;
      j.yawVis += dy * Math.min(1, dt * 14);
      av.raiz.position.copy(j.visto); av.raiz.rotation.y = j.yawVis;
      j.dispT = Math.max(0, (j.dispT || 0) - dt);
      Avatar.animar(av, dt, Math.hypot(j.visto.x - antes.x, j.visto.z - antes.z) / Math.max(dt, 1e-4), j.dispT > 0);
    }
  },

  sacar(id) { this.enviar({ t: 'sacar', id }); },
};
