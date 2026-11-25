// =====================================================================
//  HUD: vida, armas, oleadas, jefe, minimapa, números de daño, avisos
// =====================================================================
const HUD = {
  el: {}, nums: [], mini: null, miniFondo: null, hitT: 0, vinT: 0,

  init() {
    for (const id of ['hud', 'vinieta', 'hitmarker', 'oleadaTitulo', 'oleadaSub', 'jefeBox', 'jefeNombre', 'jefeVida', 'puntos', 'bajas',
      'feed', 'vida', 'vidaNum', 'armaNombre', 'recarga', 'hotbar', 'anuncio', 'numeros', 'muerte', 'muerteCuenta', 'minimapa', 'mira'])
      this.el[id] = document.getElementById(id);
    this.mini = this.el.minimapa.getContext('2d');
    this.fondoMinimapa();
    this.hotbar();
  },

  fondoMinimapa() {
    const N = 360, cv = document.createElement('canvas'); cv.width = cv.height = N;
    const c = cv.getContext('2d'), img = c.createImageData(N, N);
    for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
      const x = -180 + i, z = -180 + j, h = Terreno.altura(x, z), k = (j * N + i) * 4;
      let r, g, b;
      if (h < 0) { r = 30; g = 110; b = 160; }
      else if (h < 1) { r = 225; g = 205; b = 150; }
      else if (Terreno.enCamino(x, z) < 0) { r = 215; g = 200; b = 165; }
      else { const v = clamp(h / 15, 0, 1); r = 80 + v * 60; g = 160 - v * 20; b = 70 + v * 40; }
      img.data[k] = r; img.data[k + 1] = g; img.data[k + 2] = b; img.data[k + 3] = 255;
    }
    c.putImageData(img, 0, 0);
    // estructuras
    c.fillStyle = 'rgba(60,60,70,.9)';
    for (const b of G.cajas) if (b.max.y - b.min.y > 2 && (b.max.x - b.min.x) * (b.max.z - b.min.z) > 4) c.fillRect(b.min.x + 180, b.min.z + 180, b.max.x - b.min.x, b.max.z - b.min.z);
    for (const e of EQUIPOS) { c.fillStyle = e.color; c.globalAlpha = 0.55; c.fillRect(e.x + 180 - 6, e.z + 180 - 6, 12, 12); c.globalAlpha = 1; }
    c.fillStyle = '#3fd2ff'; c.beginPath(); c.arc(180, 180, 5, 0, TAU); c.fill();
    this.miniFondo = cv;
  },

  dibujarMinimapa() {
    const c = this.mini, W = this.el.minimapa.width, p = Jugador.pos, esc = 1.0, rango = W / 2 / esc;
    c.save();
    c.clearRect(0, 0, W, W);
    c.beginPath(); c.arc(W / 2, W / 2, W / 2, 0, TAU); c.clip();
    c.translate(W / 2, W / 2);
    c.rotate(Jugador.yaw);
    c.scale(esc, esc);
    c.drawImage(this.miniFondo, -p.x - 180, -p.z - 180);
    for (const r of Robots.vivos) {
      const dx = r.pos.x - p.x, dz = r.pos.z - p.z;
      if (Math.abs(dx) > rango * 1.5 || Math.abs(dz) > rango * 1.5) continue;
      c.fillStyle = r.cfg.jefe ? '#ff7a1a' : r.cfg.vuela ? '#ff6fd8' : '#ff3b4a';
      const s = r.cfg.jefe ? 6 : r.cfg.fx >= 2 ? 4 : 2.6;
      c.beginPath(); c.arc(dx, dz, s / esc, 0, TAU); c.fill();
    }
    for (const b of Robots.botin) { c.fillStyle = '#ffcf4a'; c.fillRect(b.pos.x - p.x - 2.5, b.pos.z - p.z - 2.5, 5, 5); }
    c.restore();
    // flecha del jugador
    c.fillStyle = '#fff'; c.strokeStyle = '#000'; c.lineWidth = 1.5;
    c.beginPath(); c.moveTo(W / 2, W / 2 - 8); c.lineTo(W / 2 + 6, W / 2 + 6); c.lineTo(W / 2, W / 2 + 3); c.lineTo(W / 2 - 6, W / 2 + 6); c.closePath(); c.fill(); c.stroke();
    // norte
    c.save(); c.translate(W / 2, W / 2); c.rotate(Jugador.yaw);
    c.fillStyle = '#ffcf4a'; c.font = 'bold 13px Baloo 2, sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.fillText('N', 0, -W / 2 + 11); c.restore();
  },

  hotbar() {
    if (!this.el.hotbar) return;
    this.el.hotbar.innerHTML = Armas.lista.map((a, i) =>
      `<div class="slot ${a.tiene ? '' : 'bloqueado'} ${Armas.actual === a ? 'activo' : ''}"><small>${i + 1}</small>${a.tiene ? a.icono : '🔒'}</div>`).join('');
  },
  arma() { if (!this.el.armaNombre) return; this.el.armaNombre.textContent = Armas.actual.nombre; this.hotbar(); },
  recarga(p) { this.el.recarga.style.width = (p * 100).toFixed(1) + '%'; this.el.recarga.style.opacity = p >= 1 ? 0.5 : 1; },
  puntos() { this.el.puntos.textContent = G.puntos; this.el.bajas.textContent = G.bajas; },
  oleada(t, s) { if (this._ot !== t) { this.el.oleadaTitulo.textContent = t; this._ot = t; } if (this._os !== s) { this.el.oleadaSub.textContent = s; this._os = s; } },

  jefe(nombre, frac) {
    if (!nombre) { this.el.jefeBox.classList.add('oculto'); return; }
    this.el.jefeBox.classList.remove('oculto');
    this.el.jefeNombre.textContent = '☠ ' + nombre + ' ☠';
    this.el.jefeVida.style.width = (frac * 100).toFixed(1) + '%';
  },

  anuncio(texto, sub, color) {
    const a = this.el.anuncio;
    a.innerHTML = texto + (sub ? `<small>${sub}</small>` : '');
    a.style.color = color || '#fff';
    a.classList.remove('ver'); void a.offsetWidth; a.classList.add('ver');
  },

  feed(html) {
    const d = document.createElement('div'); d.innerHTML = html;
    this.el.feed.prepend(d);
    while (this.el.feed.children.length > 5) this.el.feed.lastChild.remove();
    setTimeout(() => d.remove(), 5000);
  },

  hit(mata) {
    const h = this.el.hitmarker;
    h.classList.toggle('mata', mata); this.hitT = mata ? 0.35 : 0.15;
  },

  numero(pos, cant, critico) {
    const d = document.createElement('div');
    d.textContent = cant; if (critico) d.className = 'critico';
    this.el.numeros.appendChild(d);
    this.nums.push({ d, pos: pos.clone(), t: 0, vx: rand(-0.6, 0.6) });
    if (this.nums.length > 30) { const n = this.nums.shift(); n.d.remove(); }
  },

  dano(cant) { this.vinT = Math.min(1, this.vinT + cant / 35); },

  muerte(si, tipo) {
    this.el.muerte.classList.toggle('oculto', !si);
    if (si) {
      const p = this.el.muerte.querySelector('.logo');
      p.textContent = tipo === 'Tanque' || tipo === 'Coloso' || tipo === 'Jefe' ? '¡TE APLASTARON!' : '¡TE DERRIBARON!';
    }
  },
  cuentaMuerte(n) { this.el.muerteCuenta.textContent = Math.max(0, n); },

  update(dt) {
    const v = Jugador.vida / Jugador.vidaMax;
    this.el.vida.style.width = (v * 100).toFixed(1) + '%';
    this.el.vidaNum.textContent = Math.ceil(Jugador.vida);
    // viñeta roja: al recibir daño y late con poca vida
    this.vinT = Math.max(0, this.vinT - dt * 1.5);
    const late = v < 0.3 && !Jugador.muerto ? (0.35 + Math.sin(G.t * 6) * 0.2) * (1 - v / 0.3) : 0;
    this.el.vinieta.style.opacity = Math.max(this.vinT, late).toFixed(3);
    this.hitT = Math.max(0, this.hitT - dt);
    this.el.hitmarker.style.opacity = this.hitT > 0 ? 1 : 0;
    // mira se abre al disparar
    const ab = 1 + Armas.retroceso * 0.8 + (Armas.apunta ? -0.4 : 0);
    if (this._ab !== ab) { this._ab = ab; for (const s of this.el.mira.children) s.style.transform = `scale(${1}) translate(0,0)`; this.el.mira.style.transform = `scale(${ab.toFixed(2)})`; }
    // números de daño flotantes
    const cam = G.camera, W = innerWidth, H = innerHeight, tmp = V3();
    for (let i = this.nums.length - 1; i >= 0; i--) {
      const n = this.nums[i]; n.t += dt;
      tmp.copy(n.pos); tmp.y += n.t * 1.6; tmp.project(cam);
      if (n.t > 0.8 || tmp.z > 1) { n.d.remove(); this.nums.splice(i, 1); continue; }
      n.d.style.left = ((tmp.x * 0.5 + 0.5) * W + n.vx * n.t * 60) + 'px';
      n.d.style.top = ((-tmp.y * 0.5 + 0.5) * H) + 'px';
      n.d.style.opacity = 1 - Math.max(0, n.t - 0.5) / 0.3;
    }
    this.dibujarMinimapa();
  },
};
