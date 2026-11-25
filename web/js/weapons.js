// =====================================================================
//  ARMAS: modelos en primera persona, disparos, proyectiles
//  (daños y recargas tomados de Armas.server.luau)
// =====================================================================
const DEF_ARMAS = [
  { id: 'blaster', nombre: 'Bláster', icono: '🔫', dano: 25, cad: 0.2, auto: true, alcance: 220, disp: 0.006, tipo: 'bala', color: '#4fd8ff', tiene: true, sfx: 'blaster' },
  { id: 'escopeta', nombre: 'Escopeta de chispas', icono: '💥', dano: 18, perdigones: 7, disp: 0.07, cad: 0.9, alcance: 45, tipo: 'bala', color: '#ffb347', tiene: false, sfx: 'escopeta' },
  { id: 'laser', nombre: 'Láser', icono: '🔆', dano: 100, cad: 0.6, alcance: 300, tipo: 'laser', color: '#ff3df0', tiene: true, sfx: 'laser' },
  { id: 'bazuca', nombre: 'Bazuca', icono: '🚀', dano: 60, radio: 5, cad: 3.0, vel: 60, tipo: 'cohete', tiene: true, sfx: 'bazuca', lento: 0.85 },
  { id: 'tesla', nombre: 'Pistola Tesla', icono: '🌩️', dano: 50, danoCadena: 35, saltos: 4, radioCadena: 9, cad: 1.1, alcance: 60, tipo: 'tesla', color: '#8fb8ff', tiene: false, sfx: 'tesla' },
  { id: 'granada', nombre: 'Granada condensador', icono: '🔋', dano: 75, radio: 4.5, cad: 1.5, fusible: 1.8, vel: 22, tipo: 'granada', tiene: false, sfx: 'granada' },
];

const Armas = {
  lista: DEF_ARMAS, idx: 0, actual: null, enfriar: 0, retroceso: 0, apunta: false,
  cambio: 0, swayX: 0, swayY: 0, proyectiles: [], ray: new THREE.Raycaster(), soporte: null, modelos: {},

  init(camera) {
    this.soporte = new THREE.Group();
    camera.add(this.soporte);
    const luzMano = new THREE.PointLight('#ffffff', 1.2, 2.5, 2); luzMano.position.set(0.2, 0.1, -0.2); camera.add(luzMano);
    for (const a of this.lista) { const m = this.crearModelo(a); m.grupo.visible = false; this.soporte.add(m.grupo); this.modelos[a.id] = m; }
    this.elegir(0, true);
    addEventListener('mousedown', (e) => { if (e.button === 2) this.apunta = true; });
    addEventListener('mouseup', (e) => { if (e.button === 2) this.apunta = false; });
    addEventListener('contextmenu', (e) => e.preventDefault());
  },

  // ---------- Modelos 3D de cada arma ----------
  crearModelo(a) {
    const g = new THREE.Group(), partes = {};
    const M = (c, o = {}) => new THREE.MeshStandardMaterial({ color: c, roughness: o.r ?? 0.45, metalness: o.m ?? 0.5 });
    const B = (c, k = 2.5) => new THREE.MeshBasicMaterial({ color: col(c).multiplyScalar(k) });
    const caja = (sx, sy, sz, mat, x, y, z, padre = g) => { const m = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), mat); m.position.set(x, y, z); padre.add(m); return m; };
    const cil = (r1, r2, L, mat, x, y, z, padre = g, seg = 14) => { const m = new THREE.Mesh(new THREE.CylinderGeometry(r1, r2, L, seg), mat); m.rotation.x = Math.PI / 2; m.position.set(x, y, z); padre.add(m); return m; };
    const piel = M('#f1c27d', { r: 0.8, m: 0 }), manga = M(EQUIPOS[MI_EQUIPO].color, { r: 0.8, m: 0 });
    const mano = (x, y, z, padre = g) => { caja(0.075, 0.09, 0.11, piel, x, y, z, padre); caja(0.09, 0.1, 0.32, manga, x + 0.02, y - 0.03, z + 0.22, padre); };
    const boca = new THREE.Object3D(); g.add(boca);

    switch (a.id) {
      case 'blaster': {
        const cuerpo = M('#2b3550'), claro = M('#c9d3e6', { m: 0.7, r: 0.3 });
        caja(0.075, 0.1, 0.34, cuerpo, 0, 0, -0.1);
        caja(0.06, 0.04, 0.3, claro, 0, 0.065, -0.11);
        cil(0.024, 0.028, 0.18, claro, 0, 0.005, -0.33);
        partes.celda = caja(0.03, 0.05, 0.12, B('#4fd8ff'), 0, 0.1, -0.05);
        caja(0.078, 0.02, 0.2, B('#4fd8ff', 2), 0, -0.02, -0.12);
        const mango = caja(0.06, 0.15, 0.07, cuerpo, 0, -0.1, 0.03); mango.rotation.x = 0.25;
        mano(0, -0.13, 0.05);
        boca.position.set(0, 0.005, -0.43);
        break;
      }
      case 'escopeta': {
        const madera = M('#7a4a28', { r: 0.7, m: 0 }), acero = M('#3a3d44', { m: 0.8, r: 0.35 }), naranja = M('#ff8a2a', { r: 0.5, m: 0.2 });
        caja(0.08, 0.1, 0.3, acero, 0, 0, -0.05);
        cil(0.026, 0.026, 0.5, acero, -0.02, 0.03, -0.42);
        cil(0.026, 0.026, 0.5, acero, 0.02, 0.03, -0.42);
        caja(0.07, 0.11, 0.22, madera, 0, -0.02, 0.2);
        partes.bomba = caja(0.075, 0.06, 0.14, naranja, 0, -0.025, -0.36);
        for (let i = 0; i < 3; i++) caja(0.084, 0.012, 0.012, B('#ffb347', 3), 0, 0.045, -0.12 - i * 0.05);
        mano(0, -0.11, 0.08); mano(0, -0.07, -0.36);
        boca.position.set(0, 0.03, -0.68);
        break;
      }
      case 'laser': {
        const blanco = M('#eef1f7', { m: 0.3, r: 0.25 }), gris = M('#3b3f4d', { m: 0.6, r: 0.35 });
        caja(0.08, 0.11, 0.42, blanco, 0, 0, -0.12);
        caja(0.05, 0.05, 0.36, gris, 0, 0.075, -0.12);
        cil(0.04, 0.05, 0.12, gris, 0, 0, -0.38);
        partes.anillos = [];
        for (let i = 0; i < 4; i++) { const r = new THREE.Mesh(new THREE.TorusGeometry(0.052, 0.01, 6, 20), B('#ff3df0', 3)); r.position.set(0, 0, -0.06 - i * 0.07); g.add(r); partes.anillos.push(r); }
        partes.lente = cil(0.03, 0.03, 0.02, B('#ff8af7', 4), 0, 0, -0.445);
        const mango = caja(0.06, 0.15, 0.07, gris, 0, -0.11, 0.03); mango.rotation.x = 0.25;
        mano(0, -0.14, 0.05);
        boca.position.set(0, 0, -0.47);
        break;
      }
      case 'bazuca': {
        const oliva = M('#4e582c', { m: 0.35, r: 0.55 }), oliva2 = M('#3c4422', { m: 0.35, r: 0.6 }), negro = M('#161616', { m: 0.2, r: 0.8 });
        const tubo = new THREE.Group(); g.add(tubo); partes.tubo = tubo;
        cil(0.075, 0.075, 1.1, oliva, 0, 0.06, -0.25, tubo);
        cil(0.1, 0.085, 0.08, oliva, 0, 0.06, -0.83, tubo);
        cil(0.13, 0.1, 0.06, oliva, 0, 0.06, -0.89, tubo);
        cil(0.112, 0.112, 0.01, negro, 0, 0.06, -0.92, tubo);
        for (const z of [-0.45, -0.1, 0.2]) cil(0.08, 0.08, 0.03, oliva2, 0, 0.06, z, tubo);
        cil(0.08, 0.08, 0.06, oliva2, 0, 0.06, 0.32, tubo);
        const aro = new THREE.Mesh(new THREE.TorusGeometry(0.045, 0.006, 6, 16), oliva2); aro.position.set(-0.09, 0.17, 0.08); tubo.add(aro);
        caja(0.04, 0.14, 0.06, oliva2, 0, -0.05, 0.02, tubo);
        partes.ojiva = cil(0.05, 0.05, 0.06, M('#c0392b'), 0, 0.06, -0.82, tubo);
        mano(0, -0.1, 0.03, tubo); mano(0, -0.06, -0.3, tubo);
        boca.position.set(0, 0.06, -0.95);
        break;
      }
      case 'tesla': {
        const cobre = M('#c87533', { m: 0.9, r: 0.3 }), oscuro = M('#262a35', { m: 0.6, r: 0.4 });
        caja(0.08, 0.1, 0.26, oscuro, 0, 0, -0.04);
        for (let i = 0; i < 6; i++) { const r = new THREE.Mesh(new THREE.TorusGeometry(0.045, 0.012, 6, 16), cobre); r.position.set(0, 0.02, -0.18 - i * 0.03); g.add(r); }
        const vidrio = new THREE.Mesh(new THREE.SphereGeometry(0.06, 16, 12), new THREE.MeshStandardMaterial({ color: '#9fc8ff', transparent: true, opacity: 0.35, roughness: 0.05 }));
        vidrio.position.set(0, 0.02, -0.4); g.add(vidrio);
        partes.nucleo = new THREE.Mesh(new THREE.IcosahedronGeometry(0.028, 0), B('#9fd0ff', 4)); partes.nucleo.position.copy(vidrio.position); g.add(partes.nucleo);
        const mango = caja(0.06, 0.15, 0.07, oscuro, 0, -0.1, 0.05); mango.rotation.x = 0.25;
        mano(0, -0.13, 0.07);
        boca.position.set(0, 0.02, -0.42);
        break;
      }
      case 'granada': {
        const g2 = new THREE.Group(); g.add(g2); partes.gr = g2;
        const cuerpo = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, 0.16, 16), M('#2f6fd6', { m: 0.3, r: 0.4 })); g2.add(cuerpo);
        const tapa = new THREE.Mesh(new THREE.CylinderGeometry(0.058, 0.058, 0.025, 16), M('#d7dde8', { m: 0.9, r: 0.2 })); tapa.position.y = 0.09; g2.add(tapa);
        const banda = new THREE.Mesh(new THREE.CylinderGeometry(0.062, 0.062, 0.02, 16), B('#5ef0ff', 3)); g2.add(banda);
        for (const s of [-1, 1]) { const p = new THREE.Mesh(new THREE.CylinderGeometry(0.006, 0.006, 0.06), M('#ccc', { m: 1 })); p.position.set(s * 0.025, -0.11, 0); g2.add(p); }
        g2.position.set(0.02, -0.02, -0.12);
        mano(0.01, -0.08, -0.05);
        boca.position.set(0, 0, -0.2);
        break;
      }
    }
    g.traverse((o) => { if (o.isMesh) { o.castShadow = false; o.receiveShadow = false; } });
    return { grupo: g, boca, partes };
  },

  elegir(i, forzar = false) {
    const a = this.lista[i];
    if (!a || !a.tiene) { if (!forzar) Sfx.play('sinMunicion'); return; }
    if (this.actual === a && !forzar) return;
    if (this.actual) this.modelos[this.actual.id].grupo.visible = false;
    this.idx = i; this.actual = a;
    this.modelos[a.id].grupo.visible = true;
    this.cambio = 1;
    this.enfriar = Math.max(this.enfriar, 0.25);
    HUD.arma();
  },

  desbloquear(id) {
    const i = this.lista.findIndex((a) => a.id === id);
    const a = this.lista[i];
    if (a.tiene) return false;
    a.tiene = true; this.elegir(i);
    HUD.hotbar();
    return true;
  },

  // dirección de la mira con dispersión
  direccion(disp) {
    const d = Jugador.adelante();
    if (disp > 0) {
      const k = this.apunta ? 0.4 : 1;
      const r = V3(rand(-1, 1), rand(-1, 1), rand(-1, 1)).multiplyScalar(disp * k);
      d.add(r).normalize();
    }
    return d;
  },
  posBoca() { const v = V3(); this.modelos[this.actual.id].boca.getWorldPosition(v); return v; },

  // Rayo contra robots (y el mundo). Devuelve lista de impactos ordenados
  trazar(o, d, alcance, atraviesa = false) {
    const dm = rayoMundo(o, d, alcance);
    const fin = Math.min(dm, alcance);
    this.ray.set(o, d); this.ray.far = fin;
    const hits = this.ray.intersectObjects(Robots.objetivosRayo(), true);
    const res = [], vistos = new Set();
    for (const h of hits) {
      const r = h.object.userData.robot;
      if (!r || r.muerto || vistos.has(r)) continue;
      vistos.add(r); res.push({ robot: r, punto: h.point, critico: !!h.object.userData.critico, dist: h.distance });
      if (!atraviesa) break;
    }
    return { robots: res, fin, pared: dm < alcance };
  },

  disparar() {
    const a = this.actual, o = Jugador.ojo(), boca = this.posBoca();
    this.enfriar = a.cad;
    Sfx.play(a.sfx);
    switch (a.tipo) {
      case 'bala': {
        const n = a.perdigones || 1;
        for (let i = 0; i < n; i++) {
          const d = this.direccion(a.disp);
          const t = this.trazar(o, d, a.alcance);
          const fin = t.robots.length ? t.robots[0].punto : o.clone().addScaledVector(d, t.fin);
          FX.segmento(boca, fin, n > 1 ? 0.018 : 0.03, a.color, n > 1 ? 0.08 : 0.06, 3.5);
          if (t.robots.length) {
            const h = t.robots[0];
            Robots.danar(h.robot, a.dano * (h.critico ? 1.5 : 1), h.punto, h.critico);
          } else if (t.pared) {
            FX.chispazo(fin, a.color, n > 1 ? 3 : 6, 5, 0.12); Sfx.play('impacto', fin.distanceTo(o));
            if (G.ultimaCaja && G.ultimaCaja.destr) Destruibles.danar(G.ultimaCaja.destr, a.dano, fin);
          }
        }
        FX.luz(boca, a.color, 6, 6, 0.06);
        FX.chispazo(boca, a.color, n > 1 ? 10 : 4, 3, 0.05);
        this.retroceso = n > 1 ? 1 : 0.35;
        if (n > 1) setTimeout(() => Sfx.play('bomba'), 280);
        break;
      }
      case 'laser': {
        const d = this.direccion(0);
        const t = this.trazar(o, d, a.alcance, true);
        const fin = o.clone().addScaledVector(d, t.fin);
        FX.segmento(boca, fin, 0.09, a.color, 0.22, 3);
        FX.segmento(boca, fin, 0.03, '#ffffff', 0.16, 3);
        for (const h of t.robots) Robots.danar(h.robot, a.dano * (h.critico ? 1.5 : 1), h.punto, h.critico);
        if (t.pared) { FX.chispazo(fin, a.color, 14, 6, 0.15); FX.luz(fin, a.color, 15, 8, 0.2); if (G.ultimaCaja && G.ultimaCaja.destr) Destruibles.danar(G.ultimaCaja.destr, a.dano, fin); }
        FX.luz(boca, a.color, 10, 6, 0.15);
        this.retroceso = 0.6;
        break;
      }
      case 'cohete': {
        const d = this.direccion(0);
        // apunta al punto de la mira (no desde la boca, que está a un lado)
        const t = this.trazar(o, d, 300);
        const obj = t.robots.length ? t.robots[0].punto : o.clone().addScaledVector(d, t.fin);
        const dir = obj.sub(boca).normalize();
        this.lanzarCohete(boca, dir, a);
        FX.luz(boca, '#ffaa55', 15, 8, 0.2);
        for (let i = 0; i < 12; i++) FX.humo.emitir(boca.x, boca.y, boca.z, rand(-1, 1), rand(0, 1), rand(-1, 1), new THREE.Color(0.5, 0.5, 0.5), 0.4, 1.0, { crece: 1.2, a: 0.5, roce: 2 });
        this.retroceso = 1.6;
        break;
      }
      case 'tesla': {
        const d = this.direccion(0);
        let objetivo = null, mejor = 0.94;
        for (const r of Robots.vivos) {
          const c = r.centro(); const v = c.clone().sub(o); const L = v.length();
          if (L > a.alcance) continue;
          const dot = v.divideScalar(L).dot(d);
          if (dot > mejor && hayVista(o, c)) { mejor = dot; objetivo = r; }
        }
        if (!objetivo) {
          const t = this.trazar(o, d, a.alcance);
          if (t.robots.length) objetivo = t.robots[0].robot;
          else { const fin = o.clone().addScaledVector(d, t.fin); FX.arco(boca, fin, a.color, 0.15); FX.chispazo(fin, a.color, 8, 4); }
        }
        if (objetivo) {
          const tocados = new Set([objetivo]);
          let desde = boca, act = objetivo, dano = a.dano;
          for (let s = 0; s <= a.saltos && act; s++) {
            const c = act.centro();
            FX.arco(desde, c, a.color, 0.22, s ? 0.04 : 0.06, s ? 0.5 : 0.35);
            FX.chispazo(c, a.color, 10, 5);
            Robots.danar(act, dano, c, false);
            dano = a.danoCadena; desde = c;
            let sig = null, md = a.radioCadena;
            for (const r of Robots.vivos) { if (tocados.has(r) || r.muerto) continue; const dd = r.centro().distanceTo(c); if (dd < md) { md = dd; sig = r; } }
            if (sig) tocados.add(sig);
            act = sig;
          }
        }
        FX.luz(boca, a.color, 12, 8, 0.2);
        this.retroceso = 0.5;
        break;
      }
      case 'granada': {
        const d = this.direccion(0);
        const vel = d.clone().multiplyScalar(a.vel).add(V3(0, 5, 0)).add(V3(Jugador.vel.x, 0, Jugador.vel.z).multiplyScalar(0.5));
        this.lanzarGranada(boca, vel, a);
        this.retroceso = 0.3;
        break;
      }
    }
  },

  lanzarCohete(pos, dir, a) {
    const g = new THREE.Group();
    const cuerpo = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.07, 0.6, 10).rotateX(Math.PI / 2), new THREE.MeshStandardMaterial({ color: '#59612f', metalness: 0.4, roughness: 0.5 }));
    const punta = new THREE.Mesh(new THREE.ConeGeometry(0.07, 0.2, 10).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: '#c0392b' }));
    punta.position.z = -0.4;
    const fuego = new THREE.Mesh(new THREE.SphereGeometry(0.1, 8, 6), new THREE.MeshBasicMaterial({ color: col('#ffb050').multiplyScalar(4) }));
    fuego.position.z = 0.35;
    g.add(cuerpo, punta, fuego);
    g.position.copy(pos);
    g.lookAt(pos.clone().sub(dir));
    G.scene.add(g);
    this.proyectiles.push({ tipo: 'cohete', m: g, pos: pos.clone(), vel: dir.clone().multiplyScalar(a.vel), vida: 6, a });
  },

  lanzarGranada(pos, vel, a) {
    const g = new THREE.Group();
    g.add(new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.26, 12), new THREE.MeshStandardMaterial({ color: '#2f6fd6', roughness: 0.4 })));
    const banda = new THREE.Mesh(new THREE.CylinderGeometry(0.104, 0.104, 0.04, 12), new THREE.MeshBasicMaterial({ color: col('#5ef0ff').multiplyScalar(3) }));
    g.add(banda);
    g.position.copy(pos);
    G.scene.add(g);
    this.proyectiles.push({ tipo: 'granada', m: g, pos: pos.clone(), vel, vida: a.fusible, a, banda, giro: V3(rand(-8, 8), rand(-8, 8), rand(-8, 8)) });
  },

  explotar(pos, a) {
    FX.explosion(pos, a.radio, a.tipo === 'granada' ? '#5ef0ff' : '#ff9a3c');
    Destruibles.explosion(pos, a.radio + 0.5);
    for (const r of [...Robots.vivos]) {
      const d = r.centro().distanceTo(pos) - r.radio * 0.6;
      if (d < a.radio) Robots.danar(r, a.dano * (1 - 0.5 * clamp(d / a.radio, 0, 1)), r.centro(), false);
    }
  },

  updateProyectiles(dt) {
    for (let i = this.proyectiles.length - 1; i >= 0; i--) {
      const p = this.proyectiles[i];
      p.vida -= dt;
      let explota = p.vida <= 0;
      if (p.tipo === 'cohete') {
        const paso = p.vel.length() * dt, d = p.vel.clone().normalize();
        const dm = rayoMundo(p.pos, d, paso);
        if (dm < paso) { p.pos.addScaledVector(d, dm); explota = true; }
        else {
          p.pos.addScaledVector(p.vel, dt);
          for (const r of Robots.vivos) if (r.centro().distanceTo(p.pos) < r.radio + 0.3) { explota = true; break; }
        }
        // estela
        FX.humo.emitir(p.pos.x, p.pos.y, p.pos.z, rand(-0.3, 0.3), rand(0, 0.5), rand(-0.3, 0.3), new THREE.Color(0.6, 0.6, 0.6), 0.25, 1.2, { crece: 1.4, a: 0.45, roce: 1 });
        FX.chispas.emitir(p.pos.x, p.pos.y, p.pos.z, rand(-1, 1), rand(-1, 1), rand(-1, 1), FX.c('#ffb050', 3), 0.3, 0.12, { crece: -1 });
        p.m.position.copy(p.pos);
      } else if (p.tipo === 'granada') {
        p.vel.y -= 20 * dt;
        const nx = p.pos.clone().addScaledVector(p.vel, dt);
        const suelo = alturaSuelo(nx.x, nx.z, p.pos.y, 0.1);
        if (nx.y < suelo + 0.1) { nx.y = suelo + 0.1; p.vel.y = Math.abs(p.vel.y) * 0.4; p.vel.x *= 0.6; p.vel.z *= 0.6; if (Math.abs(p.vel.y) > 2) Sfx.play('impacto', nx.distanceTo(Jugador.pos)); }
        const antes = nx.clone();
        empujarFuera(nx, 0.15, 0.3);
        if (antes.x !== nx.x) p.vel.x *= -0.5;
        if (antes.z !== nx.z) p.vel.z *= -0.5;
        p.pos.copy(nx);
        p.m.position.copy(p.pos);
        p.m.rotation.x += p.giro.x * dt; p.m.rotation.z += p.giro.z * dt;
        p.banda.material.color.setScalar(Math.sin(p.vida * 30) > 0 ? 4 : 0.5).multiply(col('#5ef0ff'));
        for (const r of Robots.vivos) if (r.centro().distanceTo(p.pos) < r.radio * 0.8) { explota = true; break; }
      }
      if (explota) {
        this.explotar(p.pos, p.a);
        G.scene.remove(p.m);
        this.proyectiles.splice(i, 1);
      }
    }
  },

  update(dt) {
    // arriba de la ametralladora no se usan las armas de mano
    if (Torretas.montada) { this.updateProyectiles(dt); return; }
    // cambiar de arma
    for (let i = 0; i < this.lista.length; i++) if (Input.pulso('Digit' + (i + 1))) this.elegir(i);
    if (Input.rueda) {
      const dir = Input.rueda > 0 ? 1 : -1;
      for (let k = 1; k <= this.lista.length; k++) {
        const j = (this.idx + dir * k + this.lista.length * 2) % this.lista.length;
        if (this.lista[j].tiene) { this.elegir(j); break; }
      }
    }
    this.enfriar = Math.max(0, this.enfriar - dt);
    const a = this.actual;
    const quiere = a.auto ? Input.mouseAbajo : Input.clic;
    if (quiere && this.enfriar <= 0 && !Jugador.muerto && Input.bloqueado) this.disparar();
    this.updateProyectiles(dt);
    this.animar(dt);
  },

  // ---------- Animación del arma en la mano ----------
  animar(dt) {
    const a = this.actual, m = this.modelos[a.id], g = m.grupo, p = m.partes;
    this.retroceso = damp(this.retroceso, 0, 12, dt);
    this.cambio = Math.max(0, this.cambio - dt * 4);
    this.swayX = damp(this.swayX, clamp(-Input.dx * 0.0009, -0.06, 0.06), 8, dt);
    this.swayY = damp(this.swayY, clamp(Input.dy * 0.0009, -0.06, 0.06), 8, dt);
    const bob = Jugador.bob, amp = Jugador.bobAmp;
    const apunta = this.apunta && a.tipo !== 'granada';
    const bx = apunta ? 0.0 : 0.24, by = apunta ? -0.17 : -0.22, bz = apunta ? -0.32 : -0.42;
    const ox = (a.id === 'bazuca' ? 0.05 : 0), oy = (a.id === 'bazuca' ? 0.04 : 0);
    g.position.set(
      damp(g.position.x, bx + ox + Math.cos(bob) * 0.012 * amp + this.swayX, 14, dt),
      damp(g.position.y, by + oy - Math.abs(Math.sin(bob)) * 0.014 * amp + this.swayY - this.cambio * 0.25 - Jugador.aterrizaje * 0.05, 14, dt),
      bz + this.retroceso * 0.07);
    g.rotation.x = this.retroceso * 0.12 - this.cambio * 0.6;
    g.rotation.y = this.swayX * 0.8;
    g.rotation.z = -this.swayX * 1.2;
    const prog = 1 - this.enfriar / a.cad;
    const t = G.t;
    switch (a.id) {
      case 'blaster': p.celda.material.color.setScalar(1.5 + prog * 1.5).multiply(col('#4fd8ff')); break;
      case 'escopeta': {
        const k = prog > 0.25 && prog < 0.75 ? Math.sin(((prog - 0.25) / 0.5) * Math.PI) : 0;
        p.bomba.position.z = -0.36 + k * 0.1;
        break;
      }
      case 'laser':
        p.anillos.forEach((r, i) => { const on = prog >= (i + 1) / 4; r.material.color.copy(col('#ff3df0')).multiplyScalar(on ? 2.5 + Math.sin(t * 10 + i) * 0.8 : 0.3); });
        p.lente.material.color.copy(col('#ff8af7')).multiplyScalar(prog >= 1 ? 4 : 0.8);
        break;
      case 'bazuca': {
        const rec = prog < 1 ? Math.sin(Math.min(prog * 1.2, 1) * Math.PI) : 0;
        p.tubo.position.y = -rec * 0.25; p.tubo.rotation.x = -rec * 0.5;
        p.ojiva.visible = prog > 0.6;
        break;
      }
      case 'tesla':
        p.nucleo.rotation.y += dt * 6; p.nucleo.scale.setScalar(0.8 + prog * 0.5 + Math.sin(t * 30) * 0.1);
        if (prog >= 1 && Math.random() < dt * 6) {
          const c = V3(); p.nucleo.getWorldPosition(c);
          FX.chispas.emitir(c.x, c.y, c.z, rand(-0.3, 0.3), rand(-0.3, 0.3), rand(-0.3, 0.3), FX.c('#9fd0ff', 3), 0.03, 0.12);
        }
        break;
      case 'granada': p.gr.visible = prog > 0.5; p.gr.rotation.y += dt; break;
    }
    HUD.recarga(prog);
  },
};
