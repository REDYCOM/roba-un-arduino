// =====================================================================
//  TIENDA (de src/compartido/Catalogo.luau) — [T] en la estación de tu base
//  Se canjea con los PUNTOS PERSONALES: gastar NO baja el puntaje del equipo.
//    arma        → tuya para siempre
//    mejora      → permanente, hasta "max" veces
//    consumible  → se usa al momento
// =====================================================================
const CATALOGO = [
  { id: 'Botiquin', tipo: 'consumible', icono: '🩹', nombre: 'Botiquín', precio: 60, desc: 'Recupera toda tu vida al instante.' },
  { id: 'Escudo', tipo: 'consumible', icono: '🛡️', nombre: 'Escudo de energía', precio: 150, desc: '15 segundos sin recibir daño.' },
  { id: 'Torreta', tipo: 'consumible', icono: '🗼', nombre: 'Torreta Arduino', precio: 400, desc: 'Una torreta con sensor ultrasónico que dispara a los robots por 45 s.' },
  { id: 'Blindaje', tipo: 'mejora', icono: '🦺', nombre: 'Blindaje +50', precio: 200, max: 4, desc: '+50 de vida máxima para siempre (hasta 4 veces).' },
  { id: 'Escopeta', tipo: 'arma', arma: 'escopeta', icono: '💥', nombre: 'Escopeta de chispas', precio: 300, desc: '7 perdigones. Tuya para siempre.' },
  { id: 'Granada', tipo: 'arma', arma: 'granada', icono: '🔋', nombre: 'Granada condensador', precio: 350, desc: 'Rebota y explota. Tuya para siempre.' },
  { id: 'Tesla', tipo: 'arma', arma: 'tesla', icono: '🌩️', nombre: 'Pistola Tesla', precio: 450, desc: 'Rayo que salta entre robots. Tuya para siempre.' },
  { id: 'Laser', tipo: 'arma', arma: 'laser', icono: '🔆', nombre: 'Láser', precio: 800, desc: 'Sin tener que resolver el reto 6.' },
  { id: 'Bazuca', tipo: 'arma', arma: 'bazuca', icono: '🚀', nombre: 'Bazuca M1', precio: 900, desc: 'Sin tener que resolver el reto 4.' },
];

const Tienda = {
  abierta: false, torretas: [],

  abrir() {
    this.abierta = true;
    G.sinPausa = true;
    if (document.exitPointerLock) document.exitPointerLock();
    this.dibujar();
    document.getElementById('tienda').classList.remove('oculto');
    Sfx.play('recoger');
  },
  cerrar() {
    this.abierta = false;
    document.getElementById('tienda').classList.add('oculto');
    G.sinPausa = false;
    const p = G.renderer.domElement.requestPointerLock(); if (p && p.catch) p.catch(() => {});
  },

  estado(it) {
    if (it.tipo === 'arma' && Armas.lista.find((a) => a.id === it.arma).tiene) return { ok: false, txt: '✅ Ya es tuya' };
    if (it.tipo === 'mejora' && Poderes.blindajes >= it.max) return { ok: false, txt: '✅ Máximo' };
    if (G.canje < it.precio) return { ok: false, txt: '💰 ' + it.precio, falta: true };
    return { ok: true, txt: '💰 ' + it.precio };
  },

  dibujar(msg) {
    const el = document.getElementById('tienda');
    const grupos = { consumible: '🧪 Consumibles', mejora: '⬆️ Mejoras permanentes', arma: '🔫 Armas (tuyas para siempre)' };
    let html = `<div class="ventana"><div class="cab"><b>🛒 Tienda</b><span>Canjea tus puntos personales · gastarlos no baja el puntaje de tu equipo</span><button class="x" id="tiCerrar">✕</button></div>
      <div class="saldo">💰 Tienes <b>${G.canje}</b> puntos para canjear</div><div class="items">`;
    for (const [tipo, titulo] of Object.entries(grupos)) {
      html += `<div class="grupo">${titulo}</div>`;
      for (const it of CATALOGO.filter((x) => x.tipo === tipo)) {
        const e = this.estado(it);
        const extra = it.tipo === 'mejora' ? ` <small>(${Poderes.blindajes}/${it.max})</small>` : '';
        html += `<div class="item ${e.ok ? '' : 'no'}"><div class="ico">${it.icono}</div><div class="txt"><b>${it.nombre}${extra}</b><p>${it.desc}</p></div>
          <button data-id="${it.id}" ${e.ok ? '' : 'disabled'} class="${e.falta ? 'falta' : ''}">${e.txt}</button></div>`;
      }
    }
    html += `</div><div class="pie"><span id="tiMsg">${msg || 'Ganas puntos destruyendo robots, entregando piezas y resolviendo retos.'}</span></div></div>`;
    el.innerHTML = html;
    document.getElementById('tiCerrar').onclick = () => this.cerrar();
    for (const b of el.querySelectorAll('.item button')) b.onclick = () => this.comprar(b.dataset.id);
  },

  comprar(id) {
    const it = CATALOGO.find((x) => x.id === id);
    if (!this.estado(it).ok) return;
    G.canje -= it.precio; HUD.puntos();
    switch (it.id) {
      case 'Botiquin': Jugador.curar(Jugador.vidaMax); break;
      case 'Escudo': Runas.activas.Escudo = (Runas.activas.Escudo || 0) + 15; break;
      case 'Torreta': this.ponerTorreta(); break;
      case 'Blindaje': Poderes.blindajes++; Poderes.actualizarVida(); break;
      default: Armas.desbloquear(it.arma);
    }
    Sfx.play('recoger');
    HUD.feed(it.icono + ' Compraste <b>' + it.nombre + '</b>');
    this.dibujar('✅ Compraste ' + it.icono + ' ' + it.nombre + (it.id === 'Torreta' ? ' — ya está frente a tu base' : ''));
  },

  // ---------- Torreta Arduino (consumible): 45 s disparando sola ----------
  ponerTorreta() {
    const eq = EQUIPOS[MI_EQUIPO];
    const [x, z] = baseAMundo(eq, -2 + rand(-6, 6), -34);
    const y = Terreno.altura(x, z);
    const M = (c, o = {}) => new THREE.MeshStandardMaterial({ color: c, metalness: o.m ?? 0.4, roughness: o.r ?? 0.45 });
    const g = new THREE.Group(); g.position.set(x, y, z);
    const pata = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.35, 0.9, 10), M('#3a3f4a', { m: 0.7 })); pata.position.y = 0.45; g.add(pata);
    const cab = new THREE.Group(); cab.position.y = 1.0; g.add(cab);
    cab.add(new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.06, 0.7), M('#0a7f8c', { m: 0.2 })));          // placa Arduino
    const chip = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.05, 0.12), M('#111')); chip.position.set(0.05, 0.05, 0.05); cab.add(chip);
    const sonar = new THREE.Mesh(new THREE.BoxGeometry(0.48, 0.2, 0.05), M('#1f5fb4', { m: 0.2 })); sonar.position.set(0, 0.16, -0.32); cab.add(sonar);
    const ojos = [];
    for (const s of [-1, 1]) {
      const o = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.08, 0.1, 14).rotateX(Math.PI / 2), M('#c7ccd6', { m: 0.9, r: 0.2 }));
      o.position.set(s * 0.12, 0.16, -0.37); cab.add(o);
      const luz = new THREE.Mesh(new THREE.CircleGeometry(0.05, 12), new THREE.MeshBasicMaterial({ color: col('#36c5ff').multiplyScalar(3) }));
      luz.position.set(s * 0.12, 0.16, -0.425); luz.rotation.y = Math.PI; cab.add(luz); ojos.push(luz);
    }
    const canon = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.06, 0.6, 10).rotateX(Math.PI / 2), M('#222', { m: 0.8 })); canon.position.set(0, -0.06, -0.45); cab.add(canon);
    const boca = new THREE.Object3D(); boca.position.set(0, -0.06, -0.78); cab.add(boca);
    G.scene.add(g);
    FX.aro(V3(x, y, z), 3, '#36c5ff', 0.6); FX.chispazo(V3(x, y + 1, z), '#36c5ff', 20, 4);
    this.torretas.push({ g, cab, boca, ojos, vida: 45, cd: 0.5, pos: V3(x, y + 1.1, z) });
  },

  update(dt) {
    if (this.abierta && Input.pulso('Escape')) this.cerrar();
    for (let i = this.torretas.length - 1; i >= 0; i--) {
      const t = this.torretas[i];
      t.vida -= dt; t.cd -= dt;
      let obj = null, md = 32;
      for (const r of Robots.vivos) { const d = r.centro().distanceTo(t.pos); if (d < md) { md = d; obj = r; } }
      if (obj) {
        const c = obj.centro();
        t.cab.rotation.y = damp(t.cab.rotation.y, Math.atan2(-(c.x - t.pos.x), -(c.z - t.pos.z)), 10, dt);
        if (t.cd <= 0 && hayVista(t.pos, c)) {
          t.cd = 0.35;
          const b = V3(); t.boca.getWorldPosition(b);
          FX.segmento(b, c, 0.04, '#36c5ff', 0.08, 3.5); FX.chispazo(c, '#36c5ff', 5, 3);
          Robots.danar(obj, 20, c, false);
          Sfx.play('blaster', b.distanceTo(Jugador.pos));
        }
      } else t.cab.rotation.y += dt * 0.8; // "escanea" con el sensor
      for (const o of t.ojos) o.material.color.copy(col(obj ? '#ff3b3b' : '#36c5ff')).multiplyScalar(3);
      if (t.vida < 5) t.g.visible = Math.sin(t.vida * 20) > 0;
      if (t.vida <= 0) { FX.explosion(t.pos, 1.5, '#36c5ff'); G.scene.remove(t.g); this.torretas.splice(i, 1); }
    }
  },
};
addEventListener('keydown', (e) => { if (e.code === 'Escape' && Tienda.abierta) Tienda.cerrar(); });
