// =====================================================================
//  JUGADOR: movimiento en primera persona, colisiones, vida
// =====================================================================
const Jugador = {
  pos: V3(84, SUELO + 0.3, 0), vel: V3(), yaw: Math.PI / 2, pitch: 0,
  radio: 0.42, alto: 1.75, ojos: 1.62,
  enSuelo: false, vida: 100, vidaMax: 100, muerto: false, cuentaRevivir: 0,
  invulnerable: 0, bob: 0, bobAmp: 0, pasoT: 0, sens: 0.0022, fov: 75,
  ultimoDano: 0, aterrizaje: 0, empuje: V3(),

  revivir() {
    const eq = EQUIPOS[MI_EQUIPO];
    this.pos.set(eq.spawn.x, eq.spawn.y, eq.spawn.z);
    this.vel.set(0, 0, 0);
    this.yaw = eq.spawn.yaw; this.pitch = 0;
    this.vida = this.vidaMax; this.muerto = false; this.invulnerable = 2.5;
    HUD.muerte(false);
  },

  adelante(v = V3()) { return v.set(-Math.sin(this.yaw) * Math.cos(this.pitch), Math.sin(this.pitch), -Math.cos(this.yaw) * Math.cos(this.pitch)); },
  ojo(v = V3()) { return v.set(this.pos.x, this.pos.y + this.ojos, this.pos.z); },
  centro(v = V3()) { return v.set(this.pos.x, this.pos.y + 1.0, this.pos.z); },

  danar(cant, origen, tipo) {
    if (this.muerto || this.invulnerable > 0 || G.estado !== 'jugando') return;
    // runa ESCUDO: no te hacen daño, solo chispas azules
    if (G.mods.escudo) { FX.chispazo(this.centro(), '#50aaff', 10, 4); HUD.escudoGolpe(); return; }
    this.vida -= cant;
    this.ultimoDano = G.t;
    Sfx.play('dano');
    HUD.dano(cant, origen);
    FX.sacudir(Math.min(0.6, 0.15 + cant / 60));
    // retroceso: el golpe te empuja lejos del enemigo
    if (origen) {
      const dx = this.pos.x - origen.x, dz = this.pos.z - origen.z, L = Math.hypot(dx, dz) || 1;
      const k = clamp(6 + cant * 0.3, 6, 18);
      this.empuje.set((dx / L) * k, 0, (dz / L) * k);
      this.vel.y = Math.max(this.vel.y, cant >= 25 ? 6 : 4);
      this.enSuelo = false;
    }
    Componentes.alRecibirDano(cant);
    if (this.vida <= 0) {
      this.vida = 0; this.muerto = true; this.cuentaRevivir = 4;
      HUD.muerte(true, tipo);
      FX.sacudir(1);
    }
  },
  curar(cant) { this.vida = Math.min(this.vidaMax, this.vida + cant); },

  update(dt) {
    if (this.muerto) {
      this.cuentaRevivir -= dt;
      HUD.cuentaMuerte(Math.ceil(this.cuentaRevivir));
      if (this.cuentaRevivir <= 0) this.revivir();
      this.camara(dt);
      return;
    }
    this.invulnerable = Math.max(0, this.invulnerable - dt);
    this.empuje.multiplyScalar(Math.exp(-5 * dt));
    // regeneración lenta si no te pegan por 6 s
    if (G.t - this.ultimoDano > 6) this.curar(dt * 6);

    // mirar
    this.yaw -= Input.dx * this.sens;
    this.pitch = clamp(this.pitch - Input.dy * this.sens, -1.5, 1.5);

    // mover
    let fx = 0, fz = 0;
    if (Input.tecla('KeyW') || Input.tecla('ArrowUp')) fz -= 1;
    if (Input.tecla('KeyS') || Input.tecla('ArrowDown')) fz += 1;
    if (Input.tecla('KeyA') || Input.tecla('ArrowLeft')) fx -= 1;
    if (Input.tecla('KeyD') || Input.tecla('ArrowRight')) fx += 1;
    const corre = Input.tecla('ShiftLeft') || Input.tecla('ShiftRight');
    const enAgua = this.pos.y < AGUA_Y - 0.5;
    let vel = (corre && fz < 0 ? 11 : 7) * (enAgua ? 0.55 : 1) * (Armas.actual?.lento || 1) * G.mods.vel;
    const volando = Poderes.volando;
    if (volando) vel = 16 * G.mods.vel; // Shift sirve para bajar, no para correr
    const len = Math.hypot(fx, fz);
    const deseo = V3();
    if (len > 0) {
      fx /= len; fz /= len;
      const s = Math.sin(this.yaw), c = Math.cos(this.yaw);
      deseo.set((fx * c + fz * s) * vel, 0, (-fx * s + fz * c) * vel);
    }
    const acel = this.enSuelo ? 14 : volando ? 8 : 3.5;
    this.vel.x = damp(this.vel.x, deseo.x, acel, dt);
    this.vel.z = damp(this.vel.z, deseo.z, acel, dt);

    if (volando) {
      // estilo Superman: estable, sin caerse
      const sube = (Input.tecla('Space') ? 1 : 0) - (Input.tecla('ShiftLeft') || Input.tecla('ShiftRight') ? 1 : 0);
      this.vel.y = damp(this.vel.y, sube * 10, 6, dt);
      if (this.pos.y > 75 && this.vel.y > 0) this.vel.y = 0;
      if (Math.random() < dt * 20) FX.chispas.emitir(this.pos.x + rand(-0.3, 0.3), this.pos.y + 0.3, this.pos.z + rand(-0.3, 0.3), 0, -2, 0, FX.c('#9fdcff', 2), 0.06, 0.4);
    } else {
      if (this.enSuelo && Input.pulso('Space')) { this.vel.y = 8; this.enSuelo = false; Sfx.play('salto'); }
      this.vel.y -= 24 * dt;
    }
    if (enAgua) this.vel.y = Math.max(this.vel.y, -3);

    // integrar en sub-pasos para no atravesar paredes
    const pasos = Math.ceil(Math.max(Math.abs(this.vel.x), Math.abs(this.vel.z), Math.abs(this.vel.y)) * dt / 0.3) || 1;
    const h = dt / pasos;
    const eraSuelo = this.enSuelo, vyAntes = this.vel.y;
    for (let i = 0; i < pasos; i++) {
      this.pos.x += (this.vel.x + this.empuje.x) * h; this.pos.z += (this.vel.z + this.empuje.z) * h;
      empujarFuera(this.pos, this.radio, this.alto);
      // límite de la isla (agua profunda)
      const r = Math.hypot(this.pos.x, this.pos.z);
      if (r > 150) { this.pos.x *= 150 / r; this.pos.z *= 150 / r; }
      const ny = this.pos.y + this.vel.y * h;
      const suelo = alturaSuelo(this.pos.x, this.pos.z, this.pos.y, this.radio);
      if (this.vel.y > 0) {
        const techo = techoSobre(this.pos, this.radio * 0.7, this.alto);
        if (ny + this.alto > techo) { this.vel.y = 0; continue; }
      }
      if (ny <= suelo) {
        this.pos.y = suelo;
        this.vel.y = Math.max(0, this.vel.y);
        this.enSuelo = true;
      } else {
        this.pos.y = ny;
        this.enSuelo = ny - suelo < 0.05;
      }
    }
    if (!eraSuelo && this.enSuelo && vyAntes < -9) { this.aterrizaje = Math.min(1, -vyAntes / 25); Sfx.play('paso'); }

    // trampolines
    for (const p of G.pads) {
      if (Math.hypot(this.pos.x - p.x, this.pos.z - p.z) < p.r && this.pos.y < p.y + 0.4 && this.vel.y <= 0.1) {
        this.vel.y = 21; this.enSuelo = false; Sfx.play('trampolin');
        FX.chispazo(V3(p.x, p.y + 0.3, p.z), '#36d1ff', 30, 6);
        FX.aro(V3(p.x, p.y, p.z), 4, '#36d1ff', 0.5);
      }
    }

    // pasos y balanceo de la cabeza
    const rapidez = Math.hypot(this.vel.x, this.vel.z);
    this.bobAmp = damp(this.bobAmp, this.enSuelo ? Math.min(rapidez / 7, 1.4) : 0, 10, dt);
    this.bob += dt * rapidez * 1.45;
    if (this.enSuelo && rapidez > 2) {
      this.pasoT -= dt * rapidez;
      if (this.pasoT <= 0) { this.pasoT = 3.2; Sfx.play('paso'); }
    }
    this.camara(dt);
  },

  camara(dt) {
    const cam = G.camera;
    this.aterrizaje = Math.max(0, this.aterrizaje - dt * 3);
    const bobY = Math.abs(Math.sin(this.bob)) * 0.06 * this.bobAmp - this.aterrizaje * 0.25;
    const bobX = Math.cos(this.bob) * 0.035 * this.bobAmp;
    const sh = FX.sacudida * FX.sacudida;
    const yObj = this.muerto ? this.pos.y + 0.4 : this.pos.y + this.ojos;
    // suaviza solo al subir (escalones); al caer sigue directo
    this.camY = this.camY === undefined || yObj < this.camY || yObj - this.camY > 2 ? yObj : damp(this.camY, yObj, 18, dt);
    const y = this.camY + bobY;
    cam.position.set(this.pos.x + bobX * Math.cos(this.yaw), y, this.pos.z - bobX * Math.sin(this.yaw));
    cam.rotation.order = 'YXZ';
    cam.rotation.y = this.yaw + (Math.random() - 0.5) * sh * 0.05;
    cam.rotation.x = this.pitch + (Math.random() - 0.5) * sh * 0.05 + Armas.retroceso * 0.04;
    cam.rotation.z = this.muerto ? 0.4 : (Math.random() - 0.5) * sh * 0.03 - bobX * 0.15;
    const corre = (Input.tecla('ShiftLeft') || Input.tecla('ShiftRight')) && Math.hypot(this.vel.x, this.vel.z) > 8;
    // en pantallas angostas se abre el campo de visión para no ver todo "de cerca"
    const fovBase = clamp(THREE.MathUtils.radToDeg(2 * Math.atan(Math.tan(THREE.MathUtils.degToRad(50)) / cam.aspect)), this.fov, 100);
    const fovObj = fovBase + (corre ? 6 : 0) - (Armas.apunta ? 18 : 0);
    if (Math.abs(cam.fov - fovObj) > 0.05) { cam.fov = damp(cam.fov, fovObj, 10, dt); cam.updateProjectionMatrix(); }
  },
};
