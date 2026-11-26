// =====================================================================
//  PODERES PERMANENTES (de src/compartido/Poderes.luau y Poderes.server.luau)
//  Cada reto resuelto desbloquea uno (en orden). Duran toda la partida.
// =====================================================================
const PODERES = [
  { nombre: 'Pistola', icono: '🔫', desc: 'Bláster mejorado: más daño y dispara más rápido.' },
  { nombre: 'Armadura +100', icono: '🛡️', desc: '+100 de vida máxima.' },
  { nombre: 'Correr', icono: '🏃', desc: 'Te mueves más rápido.' },
  { nombre: 'Bazuca', icono: '🚀', desc: 'Lanzacohetes con explosión en área.' },
  { nombre: 'Punto de regeneración', icono: '♻️', desc: 'Cura a tu equipo en tu base.' },
  { nombre: 'Láser', icono: '🔦', desc: 'Rayo instantáneo de alto daño.' },
  { nombre: 'Punto de armadura', icono: '🛡️', desc: '+150 de vida máxima.' },
  { nombre: 'Armadura +200', icono: '🛡️', desc: '+200 de vida máxima.' },
  { nombre: 'Volar', icono: '🕊️', desc: '[F] volar · [Espacio] subir · [Shift] bajar.' },
  { nombre: 'Doble daño', icono: '⚔️', desc: 'Tus armas hacen el doble de daño.' },
];

const Poderes = {
  tiene: new Set(), volando: false, regen: null, blindajes: 0,

  init() {
    const el = document.getElementById('poderesHud');
    el.innerHTML = PODERES.map((p, i) => `<div class="poder" id="poder${i + 1}" title="${p.nombre}: ${p.desc}"><span>${p.icono}</span><i>🔒</i></div>`).join('');
  },

  // vida máxima = 100 + poderes de armadura + blindajes de la tienda
  vidaMax() {
    return 100 + (this.tiene.has(2) ? 100 : 0) + (this.tiene.has(7) ? 150 : 0) + (this.tiene.has(8) ? 200 : 0) + this.blindajes * 50;
  },
  actualizarVida() {
    const nueva = this.vidaMax(), subio = Math.max(0, nueva - Jugador.vidaMax);
    Jugador.vidaMax = nueva; Jugador.vida = Math.min(nueva, Jugador.vida + subio);
  },

  desbloquear(n) {
    if (this.tiene.has(n)) return;
    this.tiene.add(n);
    const p = PODERES[n - 1];
    const el = document.getElementById('poder' + n);
    if (el) { el.classList.add('activo'); el.querySelector('i').textContent = '✅'; }
    HUD.anuncio(p.icono + ' ¡PODER DESBLOQUEADO!', p.nombre + ' — ' + p.desc, '#ffcf4a');
    switch (n) {
      case 1: { const a = Armas.lista.find((x) => x.id === 'blaster'); a.dano = 35; a.cad = 0.15; break; }
      case 2: case 7: case 8: this.actualizarVida(); break;
      case 4: Armas.desbloquear('bazuca'); break;
      case 6: Armas.desbloquear('laser'); break;
      case 5: this.crearRegen(); break;
      case 9: HUD.feed('🕊️ Pulsa <b>[F]</b> para volar o aterrizar'); break;
    }
  },

  // velocidad: "Correr" (WalkSpeed 26 en vez de 16 en Roblox, aquí un poco menos)
  multVel() { return this.tiene.has(3) ? 1.4 : 1; },
  multDano() { return this.tiene.has(10) ? 2 : 1; },

  // punto de regeneración en tu base: cura +5 de vida cada medio segundo
  crearRegen() {
    const eq = EQUIPOS[MI_EQUIPO];
    const [x, z] = baseAMundo(eq, 15, -12);
    const g = new THREE.Group(); g.position.set(x, SUELO + 0.25, z);
    const pad = new THREE.Mesh(new THREE.CylinderGeometry(2.2, 2.4, 0.2, 32), new THREE.MeshStandardMaterial({ color: '#2a3a30', metalness: 0.4, roughness: 0.5 }));
    pad.position.y = 0.1; g.add(pad);
    const luz = new THREE.Mesh(new THREE.CircleGeometry(2, 32).rotateX(-Math.PI / 2), new THREE.MeshBasicMaterial({ color: col('#3ee08f').multiplyScalar(2), transparent: true, opacity: 0.5, depthWrite: false, blending: THREE.AdditiveBlending }));
    luz.position.y = 0.22; g.add(luz);
    const haz = new THREE.Mesh(new THREE.CylinderGeometry(2, 2, 6, 32, 1, true), new THREE.MeshBasicMaterial({ color: col('#3ee08f'), transparent: true, opacity: 0.12, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }));
    haz.position.y = 3; g.add(haz);
    const cruz = new THREE.Group(); cruz.position.y = 2.2; g.add(cruz);
    const mc = new THREE.MeshBasicMaterial({ color: col('#3ee08f').multiplyScalar(2.5) });
    cruz.add(new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.3, 0.3), mc), new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.9, 0.3), mc));
    G.scene.add(g);
    this.regen = { g, luz, haz, cruz, pos: V3(x, SUELO, z), t: 0 };
  },

  update(dt) {
    const r = this.regen;
    if (r) {
      r.cruz.rotation.y += dt * 1.5; r.cruz.position.y = 2.2 + Math.sin(G.t * 2) * 0.15;
      r.luz.material.opacity = 0.4 + Math.sin(G.t * 3) * 0.15;
      if (!Jugador.muerto && Math.hypot(Jugador.pos.x - r.pos.x, Jugador.pos.z - r.pos.z) < 2.3 && Jugador.vida < Jugador.vidaMax) {
        r.t += dt;
        if (r.t > 0.5) { r.t = 0; Jugador.curar(5); FX.chispazo(Jugador.centro(), '#3ee08f', 6, 2); }
        G.aviso = G.aviso || '♻️ Regenerándote…';
      }
    }
    // volar
    if (this.tiene.has(9) && !Torretas.montada && !Jugador.muerto && Input.pulso('KeyF')) {
      this.volando = !this.volando;
      Sfx.play(this.volando ? 'trampolin' : 'paso');
      HUD.feed(this.volando ? '🕊️ ¡Volando! <b>[Espacio]</b> sube · <b>[Shift]</b> baja · <b>[F]</b> aterriza' : '🕊️ Aterrizaste');
    }
    if (Jugador.muerto) this.volando = false;
    G.mods.vel = (G.mods.vel || 1) * this.multVel();
    G.mods.dano = (G.mods.dano || 1) * this.multDano();
  },
};
