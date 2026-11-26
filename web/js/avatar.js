// =====================================================================
//  CUERPOS DE LOS JUGADORES: soldados de bloques (proporciones tipo
//  Roblox: piernas 1×2, torso 2×2, brazos 1×2, cabeza ~1.2 studs)
//  - color del soldado elegido por el alumno; emblema y cinturón con
//    el color de su equipo
//  - etiqueta con nombre + barra de vida:
//      VERDE  = aliado (tu equipo)   · se ve a través de las paredes
//      ROJA   = rival (otro equipo)
//      DORADA = 👑 PROFE
//  - Companeros: jugadores de prueba manejados por la computadora,
//    para ver los cuerpos hasta que llegue el multijugador
// =====================================================================
const Avatar = {
  COLORES: ['#e8423f', '#ff8a2a', '#ffd23f', '#3ee08f', '#1fb5a8', '#36c5ff', '#3d6cff', '#8a5cff', '#ff5fb8', '#ffffff', '#6b7385', '#2a2f3c'],
  PIEL: '#f1c27d',
  REL: { aliado: '#3ee08f', rival: '#ff4d5e', profe: '#ffcf4a', yo: '#36c5ff' },
  _cara: null,

  texCara() {
    if (this._cara) return this._cara;
    const N = 64, cv = document.createElement('canvas'); cv.width = cv.height = N;
    const c = cv.getContext('2d');
    c.fillStyle = this.PIEL; c.fillRect(0, 0, N, N);
    c.fillStyle = '#1d1d24';
    c.beginPath(); c.ellipse(21, 26, 4, 6, 0, 0, TAU); c.ellipse(43, 26, 4, 6, 0, 0, TAU); c.fill();
    c.strokeStyle = '#1d1d24'; c.lineWidth = 4; c.lineCap = 'round';
    c.beginPath(); c.arc(32, 36, 12, 0.25 * Math.PI, 0.75 * Math.PI); c.stroke();
    this._cara = new THREE.CanvasTexture(cv); this._cara.colorSpace = THREE.SRGBColorSpace;
    this._cara.magFilter = THREE.NearestFilter;
    return this._cara;
  },

  // o = { nombre, color, equipo, profe }
  crear(o) {
    const S = 0.36; // metros por stud
    const M = (c, r = 0.75, m = 0) => new THREE.MeshStandardMaterial({ color: c, roughness: r, metalness: m });
    const colEq = EQUIPOS[o.equipo] ? EQUIPOS[o.equipo].color : '#ffffff';
    const mats = {
      ropa: M(o.color), oscuro: M(col(o.color).multiplyScalar(0.55)), piel: M(this.PIEL, 0.8), pantalon: M('#2b2f3a'),
      bota: M('#16181f', 0.6), equipo: new THREE.MeshStandardMaterial({ color: colEq, emissive: colEq, emissiveIntensity: 0.6, roughness: 0.5 }),
      arma: M('#3a4256', 0.4, 0.6), oro: M('#ffcf4a', 0.3, 0.9),
    };
    const caja = (padre, w, h, d, mat, x = 0, y = 0, z = 0) => {
      const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
      m.position.set(x, y, z); m.castShadow = true; padre.add(m); return m;
    };
    const raiz = new THREE.Group(), cuerpo = new THREE.Group(); raiz.add(cuerpo);
    // piernas (pivote en la cadera)
    const pierna = (lado) => {
      const g = new THREE.Group(); g.position.set(lado * 0.5 * S, 2 * S, 0); cuerpo.add(g);
      caja(g, S * 0.98, 1.6 * S, S * 0.98, mats.pantalon, 0, -0.8 * S, 0);
      caja(g, S, 0.4 * S, S * 1.1, mats.bota, 0, -1.8 * S, -0.04);
      return g;
    };
    const piernaI = pierna(-1), piernaD = pierna(1);
    // torso
    const torso = new THREE.Group(); torso.position.y = 3 * S; cuerpo.add(torso);
    caja(torso, 2 * S, 2 * S, S, mats.ropa);
    caja(torso, 2.04 * S, 0.22 * S, 1.06 * S, mats.equipo, 0, -0.78 * S, 0);           // cinturón del equipo
    caja(torso, 0.55 * S, 0.55 * S, 0.06, mats.equipo, -0.45 * S, 0.35 * S, -0.5 * S - 0.02); // emblema del equipo
    caja(torso, 1.5 * S, 1.2 * S, 0.5 * S, mats.oscuro, 0, 0.2 * S, 0.7 * S);           // mochila
    caja(torso, 0.08, 0.9 * S, 0.08, mats.equipo, 0.5 * S, 1.1 * S, 0.8 * S);            // antena
    // brazos (pivote en el hombro)
    const brazo = (lado) => {
      const g = new THREE.Group(); g.position.set(lado * 1.5 * S, 3.85 * S, 0); torso.parent.add(g);
      caja(g, S * 0.98, 1.3 * S, S * 0.98, mats.ropa, 0, -0.5 * S, 0);
      caja(g, S * 0.92, 0.7 * S, S * 0.92, mats.piel, 0, -1.5 * S, 0);
      return g;
    };
    const brazoI = brazo(-1), brazoD = brazo(1);
    // arma en la mano derecha (apunta hacia -Z cuando el brazo está levantado)
    const arma = new THREE.Group(); arma.position.set(0, -1.75 * S, -0.1); brazoD.add(arma);
    caja(arma, 0.12, 0.42, 0.16, mats.arma, 0, -0.12, 0);
    caja(arma, 0.06, 0.08, 0.06, new THREE.MeshBasicMaterial({ color: col(o.profe ? '#ffcf4a' : '#36c5ff').multiplyScalar(3) }), 0, -0.36, 0);
    // cabeza con casco
    const cabeza = new THREE.Group(); cabeza.position.y = 4.6 * S; cuerpo.add(cabeza);
    const matsCabeza = [mats.piel, mats.piel, mats.piel, mats.piel, mats.piel, new THREE.MeshStandardMaterial({ map: this.texCara(), roughness: 0.8 })];
    const cab = new THREE.Mesh(new THREE.BoxGeometry(1.2 * S, 1.2 * S, 1.2 * S), matsCabeza); cab.castShadow = true; cabeza.add(cab);
    if (o.profe) {
      // corona dorada
      for (let i = 0; i < 5; i++) {
        const a = (i / 5) * TAU;
        caja(cabeza, 0.09, 0.16, 0.09, mats.oro, Math.cos(a) * 0.17, 0.32, Math.sin(a) * 0.17);
      }
      caja(cabeza, 1.3 * S, 0.12, 1.3 * S, mats.oro, 0, 0.24, 0);
      // capa dorada
      const capa = caja(torso, 1.9 * S, 2.6 * S, 0.04, new THREE.MeshStandardMaterial({ color: '#c9971f', roughness: 0.6, side: THREE.DoubleSide }), 0, -0.3 * S, 0.5 * S + 0.25);
      capa.rotation.x = 0.12;
    } else {
      caja(cabeza, 1.32 * S, 0.5 * S, 1.32 * S, mats.ropa, 0, 0.45 * S, 0);             // casco
      caja(cabeza, 1.34 * S, 0.12 * S, 0.3 * S, mats.oscuro, 0, 0.25 * S, -0.6 * S);      // visera
    }
    // etiqueta (nombre + barra de vida)
    const cv = document.createElement('canvas'); cv.width = 256; cv.height = 84;
    const tex = new THREE.CanvasTexture(cv); tex.colorSpace = THREE.SRGBColorSpace;
    const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }));
    sp.scale.set(1.9, 0.62, 1); sp.position.y = 2.5; sp.renderOrder = 5;
    raiz.add(sp);
    const av = {
      raiz, cuerpo, torso, cabeza, piernaI, piernaD, brazoI, brazoD, arma, mats, tag: { sp, cv, tex, clave: '' },
      nombre: o.nombre, color: o.color, equipo: o.equipo, profe: !!o.profe, vida: 100, vidaMax: 100, fase: 0, disparo: 0,
    };
    this.etiqueta(av);
    return av;
  },

  relacion(av) {
    if (av.profe) return 'profe';
    if (av.yo) return 'yo';
    return av.equipo === MI_EQUIPO ? 'aliado' : 'rival';
  },

  // dibuja nombre y barra (solo si algo cambió)
  etiqueta(av) {
    const rel = this.relacion(av), v = Math.max(0, Math.round((av.vida / av.vidaMax) * 20));
    const clave = rel + v + av.nombre;
    if (clave === av.tag.clave) return;
    av.tag.clave = clave;
    const c = av.tag.cv.getContext('2d'), W = 256, colRel = this.REL[rel];
    c.clearRect(0, 0, W, 84);
    // nombre
    const texto = (rel === 'profe' ? '👑 ' : '') + av.nombre;
    c.font = 'bold 30px "Baloo 2", system-ui, sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.lineWidth = 6; c.strokeStyle = 'rgba(0,0,0,.75)'; c.strokeText(texto, W / 2 + 10, 24);
    c.fillStyle = rel === 'profe' ? '#ffe28a' : '#ffffff'; c.fillText(texto, W / 2 + 10, 24);
    // cuadradito del color del equipo
    const anchoTxt = Math.min(c.measureText(texto).width, 200);
    c.fillStyle = rel === 'profe' ? '#ffcf4a' : EQUIPOS[av.equipo].color;
    c.strokeStyle = '#000'; c.lineWidth = 3;
    c.beginPath(); c.roundRect(W / 2 + 10 - anchoTxt / 2 - 26, 13, 20, 20, 5); c.fill(); c.stroke();
    // barra: marco y relleno del color de la relación (verde aliado / rojo rival / dorado profe)
    const bx = 28, by = 50, bw = 200, bh = 22;
    c.fillStyle = 'rgba(8,12,24,.85)'; c.beginPath(); c.roundRect(bx - 4, by - 4, bw + 8, bh + 8, 10); c.fill();
    c.strokeStyle = colRel; c.lineWidth = 4; c.stroke();
    c.fillStyle = colRel; c.beginPath(); c.roundRect(bx, by, Math.max(4, (bw * v) / 20), bh, 6); c.fill();
    c.fillStyle = 'rgba(255,255,255,.35)'; c.fillRect(bx + 4, by + 3, Math.max(0, (bw * v) / 20 - 8), 5);
    // símbolo a la izquierda de la barra
    c.font = 'bold 22px system-ui, sans-serif'; c.fillStyle = colRel;
    c.fillText(rel === 'rival' ? '✖' : rel === 'profe' ? '★' : '✚', 12, by + bh / 2 + 1);
    av.tag.tex.needsUpdate = true;
    // aliados y profe se ven a través de las paredes; los rivales no
    av.tag.sp.material.depthTest = rel === 'rival';
  },

  // vel = rapidez horizontal (m/s), apuntando = levanta el arma
  animar(av, dt, vel, apuntando) {
    const mov = clamp(vel / 5, 0, 1.4);
    av.fase += dt * (4 + vel * 1.6);
    const s = Math.sin(av.fase) * 0.75 * mov;
    av.piernaI.rotation.x = s; av.piernaD.rotation.x = -s;
    av.brazoI.rotation.x = -s * 0.8;
    av.disparo = Math.max(0, av.disparo - dt);
    const objetivo = apuntando ? Math.PI / 2 - (av.disparo > 0 ? 0.12 : 0) : s * 0.8; // +90°: el brazo apunta al frente (-Z)
    av.brazoD.rotation.x = damp(av.brazoD.rotation.x, objetivo, 14, dt);
    av.cuerpo.position.y = Math.abs(Math.cos(av.fase)) * 0.05 * mov;
    av.cabeza.rotation.y = Math.sin(G.t * 0.8 + av.fase * 0.1) * 0.15;
    this.etiqueta(av);
  },

  bocaArma(av) { return av.arma.localToWorld(V3(0, -0.4, 0)); },
};

// =====================================================================
//  VISTA PREVIA DEL MENÚ: tu soldado girando con tu nombre y color
// =====================================================================
const Previa = {
  iniciar(canvas) {
    this.canvas = canvas;
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.setSize(canvas.clientWidth || 130, canvas.clientHeight || 170, false);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.escena = new THREE.Scene();
    this.escena.add(new THREE.HemisphereLight('#dfe9ff', '#3a3550', 2.2));
    const sol = new THREE.DirectionalLight('#ffffff', 2.4); sol.position.set(2, 4, -3); this.escena.add(sol);
    this.cam = new THREE.PerspectiveCamera(32, (canvas.clientWidth || 130) / (canvas.clientHeight || 170), 0.1, 50);
    this.cam.position.set(0, 1.4, -4.1); this.cam.lookAt(0, 1.22, 0);
    this.t = 0;
    const bucle = () => {
      requestAnimationFrame(bucle);
      if (!this.av || this.canvas.offsetParent === null) return; // menú oculto: no dibuja
      this.t += 0.016;
      this.av.raiz.rotation.y = Math.sin(this.t * 0.7) * 0.6;
      this.av.fase += 0.016 * 3;
      this.av.brazoD.rotation.x = -0.25 + Math.sin(this.t * 2) * 0.05;
      this.renderer.render(this.escena, this.cam);
    };
    bucle();
  },
  actualizar(nombre, color, profe) {
    if (!this.escena) return;
    if (this.av) this.escena.remove(this.av.raiz);
    this.av = Avatar.crear({ nombre, color, equipo: MI_EQUIPO, profe });
    this.av.yo = !profe; this.av.tag.clave = ''; Avatar.etiqueta(this.av);
    this.av.tag.sp.position.y = 2.25;
    this.escena.add(this.av.raiz);
  },
};

// =====================================================================
//  COMPAÑEROS DE PRUEBA (hasta que exista el multijugador)
//  Con el selector de jugadores > 1 aparecen soldados manejados por la
//  computadora: tu equipo (barra verde), rivales (roja) y el profe (dorada)
// =====================================================================
const Companeros = {
  lista: [],
  NOMBRES: ['Sofi', 'Mateo', 'Valen', 'Thiago', 'Luana', 'Benja', 'Cami', 'Joaco', 'Mía', 'Santi', 'Lucía', 'Tomi', 'Emi', 'Agus', 'Pili', 'Nico'],
  MAX: 10, // cuerpos de prueba como máximo (rendimiento)

  iniciar() {
    if (G.jugadores <= 1) return;
    const n = Math.min(G.jugadores - 1, this.MAX - 1);
    const nombres = [...this.NOMBRES].sort(() => Math.random() - 0.5);
    for (let i = 1; i <= n; i++) {
      // se llenan los equipos de a 5 empezando por el tuyo (como en la partida)
      const equipo = G.equiposActivos[Math.min(Math.floor(i / 5), G.equiposActivos.length - 1)];
      this.agregar({ nombre: nombres[i % nombres.length], color: pick(Avatar.COLORES), equipo });
    }
    // si tú eres el profe, no hace falta la profe de prueba
    if (!G.profe) this.agregar({ nombre: 'Profe Ana', color: '#ffcf4a', equipo: MI_EQUIPO, profe: true });
  },

  agregar(o) {
    const av = Avatar.crear(o);
    const eq = EQUIPOS[o.equipo];
    const [hx, hz] = o.profe ? [rand(-6, 6), rand(-6, 6) + 14] : eq.puerta;
    const b = { av, casa: V3(hx, 0, hz), pos: V3(hx + rand(-3, 3), 0, hz + rand(-3, 3)), yaw: 0, destino: null, cdTiro: rand(0.3, 1), objetivo: null, pensar: 0 };
    b.pos.y = alturaSuelo(b.pos.x, b.pos.z, 30, 0.4);
    av.raiz.position.copy(b.pos);
    G.scene.add(av.raiz);
    this.lista.push(b);
  },

  update(dt) {
    for (const b of this.lista) {
      const av = b.av;
      // buscar un robot cerca (los rivales también pelean contra los robots: es PvE)
      b.pensar -= dt;
      if (b.pensar <= 0) {
        b.pensar = rand(0.4, 0.8);
        let mejor = null, dm = av.profe ? 0 : 28;
        for (const r of Robots.vivos) { const d = Math.hypot(r.pos.x - b.pos.x, r.pos.z - b.pos.z); if (d < dm && !r.muerto) { dm = d; mejor = r; } }
        b.objetivo = mejor;
        if (!b.destino || Math.hypot(b.destino.x - b.pos.x, b.destino.z - b.pos.z) < 1.5 || Math.random() < 0.05) {
          const rad = av.profe ? 12 : 10;
          b.destino = V3(b.casa.x + rand(-rad, rad), 0, b.casa.z + rand(-rad, rad));
        }
      }
      let tx = b.destino.x, tz = b.destino.z, vel = av.profe ? 3.2 : 5;
      const r = b.objetivo && !b.objetivo.muerto ? b.objetivo : null;
      if (r) {
        // mantener distancia y moverse de costado mientras dispara
        const dx = b.pos.x - r.pos.x, dz = b.pos.z - r.pos.z, d = Math.hypot(dx, dz) || 1;
        const lejos = 11 + r.radio;
        tx = r.pos.x + (dx / d) * lejos + (-dz / d) * Math.sin(G.t + av.fase) * 4;
        tz = r.pos.z + (dz / d) * lejos + (dx / d) * Math.sin(G.t + av.fase) * 4;
        vel = 5.5;
      }
      const mx = tx - b.pos.x, mz = tz - b.pos.z, md = Math.hypot(mx, mz);
      const antes = b.pos.clone();
      if (md > 0.6) { b.pos.x += (mx / md) * vel * dt; b.pos.z += (mz / md) * vel * dt; }
      empujarFuera(b.pos, 0.42, 1.75);
      b.pos.y = damp(b.pos.y, alturaSuelo(b.pos.x, b.pos.z, b.pos.y + 0.7, 0.4), 14, dt);
      const rapidez = Math.hypot(b.pos.x - antes.x, b.pos.z - antes.z) / Math.max(dt, 1e-4);
      // mirar al robot o hacia donde camina
      const lx = r ? r.pos.x - b.pos.x : mx, lz = r ? r.pos.z - b.pos.z : mz;
      if (Math.hypot(lx, lz) > 0.1) {
        let dy = Math.atan2(-lx, -lz) - b.yaw; while (dy > Math.PI) dy -= TAU; while (dy < -Math.PI) dy += TAU;
        b.yaw += dy * Math.min(1, dt * 8);
      }
      // disparar
      if (r && !av.profe) {
        b.cdTiro -= dt;
        const c = r.centro();
        if (b.cdTiro <= 0 && b.pos.distanceTo(c) < 32 && hayVista(b.pos.clone().setY(b.pos.y + 1.5), c)) {
          b.cdTiro = rand(0.45, 0.7);
          av.disparo = 0.12;
          const boca = Avatar.bocaArma(av);
          const fin = c.clone().add(V3(rand(-0.4, 0.4), rand(-0.4, 0.4), rand(-0.4, 0.4)));
          FX.segmento(boca, fin, 0.025, EQUIPOS[av.equipo].color, 0.06, 3.5);
          // daño directo (sin números en pantalla ni puntos para ti: el robot lo destruye otro)
          r.vida -= 9; r.flash = 0.09;
          if (r.cfg.jefe) HUD.jefe(r.cfg.nombre, Math.max(0, r.vida / r.vidaMax));
          if (r.vida <= 0) Robots.morir(r, av);
        }
        // los robots que los tocan les bajan vida (para ver la barra)
        if (Math.hypot(r.pos.x - b.pos.x, r.pos.z - b.pos.z) < r.radio + r.cfg.alcance + 0.8) av.vida -= dt * 25;
      }
      if (!r) av.vida = Math.min(av.vidaMax, av.vida + dt * 6);
      if (av.vida <= 0) {
        // derribado: reaparece en su base
        FX.chispazo(b.pos.clone().setY(b.pos.y + 1), EQUIPOS[av.equipo].color, 18, 5);
        HUD.feed((av.equipo === MI_EQUIPO ? '💚 ' : '❤ ') + av.nombre + ' fue derribado');
        av.vida = av.vidaMax; b.pos.set(b.casa.x, alturaSuelo(b.casa.x, b.casa.z, 30, 0.4), b.casa.z);
      }
      av.raiz.position.copy(b.pos);
      av.raiz.rotation.y = b.yaw;
      Avatar.animar(av, dt, rapidez, !!r && !av.profe);
    }
  },
};
