// =====================================================================
//  MODO PROFE: el profe juega y observa
//  - entra desde el menú con la clave de profe
//  - no puede caer (invencible) y puede volar para observar
//  - [F1] abre el PANEL DEL PROFE (solo el profe):
//      dificultad en tiempo real · puntos de cada equipo y de cada alumno ·
//      pausar a todos · siguiente oleada · lanzar pregunta · curar ·
//      dar puntos · ir a una base · sacar a un alumno
//  (sin servidor la clave se revisa aquí; con el multijugador la revisará
//   el servidor y nadie podrá verla)
// =====================================================================
const CLAVE_PROFE = 'arduino2026'; // ← cámbiala por la tuya

const DIFICULTADES = [
  { nombre: 'Muy fácil', icono: '🐣', dano: 0.4, vida: 0.5, vel: 0.75, cant: 0.5 },
  { nombre: 'Fácil', icono: '🙂', dano: 0.7, vida: 0.75, vel: 0.9, cant: 0.75 },
  { nombre: 'Normal', icono: '⚔️', dano: 1, vida: 1, vel: 1, cant: 1 },
  { nombre: 'Difícil', icono: '🔥', dano: 1.4, vida: 1.4, vel: 1.12, cant: 1.3 },
  { nombre: 'Extremo', icono: '☠️', dano: 2, vida: 2, vel: 1.25, cant: 1.6 },
];

const Profe = {
  abierto: false, nivel: 2, inmune: true, refrescoT: 0,

  get dif() { return DIFICULTADES[this.nivel]; },

  comprobar(clave) { return clave.trim() === CLAVE_PROFE; },

  // ---------- dificultad en tiempo real ----------
  ponerDificultad(n) {
    const antes = this.dif;
    this.nivel = clamp(n, 0, DIFICULTADES.length - 1);
    const d = this.dif, k = d.vida / antes.vida;
    // los robots que ya están en el mapa cambian su vida al instante (mismo porcentaje)
    for (const r of Robots.vivos) { r.vida *= k; r.vidaMax *= k; if (r.cfg.jefe) HUD.jefe(r.cfg.nombre, r.vida / r.vidaMax); }
    HUD.feed('👑 El profe puso la dificultad en <b>' + d.icono + ' ' + d.nombre + '</b>');
    this.dibujar();
  },

  // ---------- pausa para todos ----------
  pausar(si) {
    if (si && G.estado === 'jugando') G.estado = 'pausaProfe';
    else if (!si && G.estado === 'pausaProfe') G.estado = 'jugando';
    document.getElementById('pausaProfe').classList.toggle('oculto', G.estado !== 'pausaProfe');
    this.dibujar();
  },

  // ---------- panel ----------
  alternar() { if (this.abierto) this.cerrar(); else this.abrir(); },
  abrir() {
    if (!G.profe || G.estado === 'menu' || Estacion.abierta || Tienda.abierta) return;
    this.abierto = true;
    G.sinPausa = true;
    if (document.exitPointerLock) document.exitPointerLock();
    document.getElementById('panelProfe').classList.remove('oculto');
    this.dibujar();
  },
  cerrar() {
    this.abierto = false;
    document.getElementById('panelProfe').classList.add('oculto');
    G.sinPausa = false;
    if (G.estado === 'jugando') { const p = G.renderer.domElement.requestPointerLock(); if (p && p.catch) p.catch(() => {}); }
  },

  // lista de jugadores: tú (profe) + los demás
  jugadores() {
    const yo = { nombre: G.miNombre, equipo: MI_EQUIPO, puntos: G.misPuntos, bajas: G.bajas, retos: Estacion.resueltos,
      preguntas: Estacion.acertadas.size + (Quiz.aciertos || 0), vida: Jugador.vida / Jugador.vidaMax, profe: true, yo: true };
    const otros = Companeros.lista.filter((b) => !b.av.profe).map((b) => ({
      nombre: b.av.nombre, equipo: b.av.equipo, puntos: b.av.puntos || 0, bajas: b.av.bajas || 0, retos: '—', preguntas: '—',
      vida: b.av.vida / b.av.vidaMax, bot: b,
    }));
    return [yo, ...otros];
  },

  dibujar() {
    if (!this.abierto) return;
    const el = document.getElementById('panelProfe');
    if (!el.firstChild) this.armar(el);
    // estado de la partida
    const O = Oleadas, tiempo = Math.floor(G.t / 60) + ':' + String(Math.floor(G.t % 60)).padStart(2, '0');
    const fase = O.fase === 'descanso' ? (O.n === 0 ? 'Preparándose' : 'Descanso') + ' · ' + Math.ceil(O.cuenta) + ' s'
      : O.fase === 'oleada' ? 'Oleada ' + O.n + ' de ' + O.TOTAL : O.fase === 'fin' ? 'Terminada' : 'Esperando';
    document.getElementById('ppEstado').innerHTML =
      `<div><small>Partida</small><b>${fase}</b></div><div><small>Robots vivos</small><b>${Robots.vivos.length}</b></div>` +
      `<div><small>Jugadores</small><b>${G.jugadores}</b></div><div><small>Tiempo</small><b>${tiempo}</b></div>`;
    const pausado = G.estado === 'pausaProfe';
    const bp = document.getElementById('ppPausa');
    bp.textContent = pausado ? '▶ Reanudar para todos' : '⏸ Pausar para todos';
    bp.classList.toggle('activo', pausado);
    // dificultad
    document.querySelectorAll('#ppDif button').forEach((b, i) => b.classList.toggle('sel', i === this.nivel));
    const d = this.dif;
    document.getElementById('ppDifInfo').textContent = `Daño de robots ×${d.dano} · Vida de robots ×${d.vida} · Velocidad ×${d.vel} · Cantidad ×${d.cant}`;
    // equipos (ordenados por puntos)
    const eqs = G.equiposActivos.map((i) => ({ i, eq: EQUIPOS[i], pts: G.puntosEq[i] || 0, n: this.jugadores().filter((j) => j.equipo === i).length }))
      .sort((a, b) => b.pts - a.pts);
    document.getElementById('ppEquipos').innerHTML = eqs.map((e, pos) =>
      `<tr><td>${['🥇', '🥈', '🥉'][pos] || pos + 1}</td><td><i class="punto" style="background:${e.eq.color}"></i>${e.eq.nombre}${e.i === MI_EQUIPO ? ' <small>(tú)</small>' : ''}</td>` +
      `<td>${e.n}</td><td><b>${e.pts}</b></td><td><button data-acc="darPuntos" data-i="${e.i}">+50</button></td></tr>`).join('');
    // alumnos
    document.getElementById('ppJugadores').innerHTML = this.jugadores().sort((a, b) => b.puntos - a.puntos).map((j, k) =>
      `<tr><td><i class="punto" style="background:${EQUIPOS[j.equipo].color}"></i>${j.yo ? '👑 ' : ''}${j.nombre}</td>` +
      `<td>${j.puntos}</td><td>${j.bajas}</td><td>${j.retos}</td><td>${j.preguntas}</td>` +
      `<td><span class="mini"><span style="width:${Math.round(j.vida * 100)}%"></span></span></td>` +
      `<td>${j.bot ? `<button class="peligro" data-acc="sacar" data-n="${Companeros.lista.indexOf(j.bot)}">Sacar</button>` : ''}</td></tr>`).join('');
    document.getElementById('ppInmune').classList.toggle('activo', this.inmune);
    document.getElementById('ppVolar').classList.toggle('activo', Poderes.volando);
  },

  armar(el) {
    el.innerHTML = `<div class="ventana profe">
      <div class="cab"><b>👑 PANEL DEL PROFE</b><span>Solo tú lo ves · todo cambia en tiempo real</span><button class="x" data-acc="cerrar">✕ <kbd>F1</kbd></button></div>
      <div class="ppEstado" id="ppEstado"></div>
      <div class="ppGrid">
        <section>
          <div class="seccion">🎮 Partida</div>
          <div class="ppBotones">
            <button id="ppPausa" data-acc="pausa"></button>
            <button data-acc="siguiente">⏭ Siguiente oleada</button>
            <button data-acc="pregunta">❓ Lanzar pregunta</button>
            <button data-acc="curar">❤️ Curar a todos</button>
            <button class="peligro" data-acc="limpiar">💥 Destruir robots</button>
          </div>
          <div class="seccion">⚖️ Dificultad <small>(cambia al instante)</small></div>
          <div class="ppBotones dif" id="ppDif">${DIFICULTADES.map((d, i) => `<button data-acc="dif" data-i="${i}">${d.icono} ${d.nombre}</button>`).join('')}</div>
          <div class="ppInfo" id="ppDifInfo"></div>
          <div class="seccion">👑 Tú</div>
          <div class="ppBotones">
            <button id="ppInmune" data-acc="inmune">🛡 Invencible</button>
            <button id="ppVolar" data-acc="volar">🕊 Volar <small>(Espacio sube · Shift baja)</small></button>
          </div>
          <div class="ppBotones bases">${G.equiposActivos.map((i) => `<button data-acc="ir" data-i="${i}" style="background:${EQUIPOS[i].color}">📍 ${EQUIPOS[i].nombre}</button>`).join('')}</div>
        </section>
        <section>
          <div class="seccion">🏆 Puntos por equipo</div>
          <table class="ppTabla"><thead><tr><th></th><th>Equipo</th><th>👥</th><th>⭐</th><th></th></tr></thead><tbody id="ppEquipos"></tbody></table>
          <div class="seccion">👦 Alumnos</div>
          <div class="ppScroll"><table class="ppTabla"><thead><tr><th>Nombre</th><th>⭐</th><th>🤖</th><th>🧩</th><th>❓</th><th>❤️</th><th></th></tr></thead><tbody id="ppJugadores"></tbody></table></div>
          <div class="ppInfo">🧩 retos resueltos · ❓ preguntas acertadas. Con el multijugador verás los de cada alumno y podrás silenciarlos.</div>
        </section>
      </div>
    </div>`;
    el.onclick = (e) => {
      const b = e.target.closest('[data-acc]'); if (!b) return;
      this.accion(b.dataset.acc, +b.dataset.i, +b.dataset.n);
    };
  },

  accion(acc, i, n) {
    const O = Oleadas;
    switch (acc) {
      case 'cerrar': this.cerrar(); return;
      case 'pausa': this.pausar(G.estado !== 'pausaProfe'); return;
      case 'dif': this.ponerDificultad(i); return;
      case 'siguiente':
        if (O.fase === 'descanso') O.cuenta = 0.01;
        else if (O.fase === 'oleada') { O.cola.length = 0; this.destruirTodo(); }
        HUD.feed('👑 El profe adelantó la oleada');
        break;
      case 'limpiar': this.destruirTodo(); HUD.feed('👑 El profe destruyó a los robots'); break;
      case 'pregunta':
        if (Quiz.activa) { HUD.feed('❓ Ya hay una pregunta en pantalla'); break; }
        Quiz.lanzar(); break;
      case 'curar':
        Jugador.curar(9999);
        for (const b of Companeros.lista) b.av.vida = b.av.vidaMax;
        HUD.feed('👑 El profe curó a todos ❤️'); Sfx.play('recoger'); break;
      case 'darPuntos':
        G.puntosEq[i] = (G.puntosEq[i] || 0) + 50;
        if (i === MI_EQUIPO) { G.puntos += 50; HUD.puntos(); }
        HUD.feed('👑 El profe le dio <b>+50</b> al ' + EQUIPOS[i].nombre); break;
      case 'inmune': this.inmune = !this.inmune; break;
      case 'volar':
        Poderes.volando = !Poderes.volando;
        HUD.feed(Poderes.volando ? '🕊️ Volando · <b>[Espacio]</b> sube · <b>[Shift]</b> baja' : '🕊️ Aterrizaste'); break;
      case 'ir': {
        const [x, z] = EQUIPOS[i].puerta;
        Jugador.pos.set(x, alturaSuelo(x, z, 60, 0.4) + (Poderes.volando ? 6 : 0), z); Jugador.vel.set(0, 0, 0);
        Jugador.yaw = Math.atan2(x, z); // mirando hacia la plaza
        FX.chispazo(Jugador.centro(), '#ffcf4a', 20, 5);
        break;
      }
      case 'sacar': {
        const b = Companeros.lista[n]; if (!b) break;
        G.scene.remove(b.av.raiz); Companeros.lista.splice(n, 1);
        HUD.feed('👑 ' + b.av.nombre + ' salió de la partida'); break;
      }
    }
    this.dibujar();
  },

  destruirTodo() {
    for (const r of [...Robots.vivos]) if (!r.muerto) Robots.morir(r, { nombre: '👑 el profe', equipo: -1 });
  },

  update(dt) {
    // invencible: no recibe daño mientras juega
    if (G.profe && this.inmune) Jugador.invulnerable = Math.max(Jugador.invulnerable, 0.2);
    if (this.abierto && (this.refrescoT -= dt) <= 0) { this.refrescoT = 0.5; this.dibujar(); }
  },
};

// F1 (y Esc para cerrar). F1 funciona aunque el juego esté pausado por el profe
addEventListener('keydown', (e) => {
  if (e.code === 'F1') {
    e.preventDefault();
    if (G.profe) Profe.alternar();
  } else if (e.code === 'Escape' && Profe.abierto) Profe.cerrar();
});
