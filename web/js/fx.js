// =====================================================================
//  EFECTOS: partículas, trazadoras, rayos, explosiones, luces
// =====================================================================
class Particulas {
  constructor(scene, max, aditivo) {
    this.max = max; this.lista = [];
    const g = new THREE.BufferGeometry();
    this.pos = new Float32Array(max * 3); this.colr = new Float32Array(max * 3);
    this.tam = new Float32Array(max); this.alfa = new Float32Array(max);
    g.setAttribute('position', new THREE.BufferAttribute(this.pos, 3));
    g.setAttribute('aColor', new THREE.BufferAttribute(this.colr, 3));
    g.setAttribute('aSize', new THREE.BufferAttribute(this.tam, 1));
    g.setAttribute('aAlpha', new THREE.BufferAttribute(this.alfa, 1));
    this.mat = new THREE.ShaderMaterial({
      uniforms: { escala: { value: innerHeight / 2 } },
      vertexShader: `uniform float escala; attribute vec3 aColor; attribute float aSize; attribute float aAlpha;
        varying vec3 vC; varying float vA;
        void main(){ vC = aColor; vA = aAlpha; vec4 mv = modelViewMatrix * vec4(position, 1.0);
          gl_PointSize = aSize * escala / max(-mv.z, 0.1); gl_Position = projectionMatrix * mv; }`,
      fragmentShader: `varying vec3 vC; varying float vA;
        void main(){ float r = length(gl_PointCoord - 0.5); if (r > 0.5) discard;
          float a = smoothstep(0.5, 0.05, r); gl_FragColor = vec4(vC, vA * a); }`,
      transparent: true, depthWrite: false,
      blending: aditivo ? THREE.AdditiveBlending : THREE.NormalBlending,
    });
    this.puntos = new THREE.Points(g, this.mat);
    this.puntos.frustumCulled = false;
    scene.add(this.puntos);
  }
  emitir(x, y, z, vx, vy, vz, color, tam, vida, o = {}) {
    if (this.lista.length >= this.max) this.lista.shift();
    this.lista.push({ x, y, z, vx, vy, vz, c: color, tam, crece: o.crece || 0, vida, v0: vida, g: o.g ?? 0, roce: o.roce ?? 1, a: o.a ?? 1, suelo: o.suelo });
  }
  update(dt) {
    const L = this.lista;
    for (let i = L.length - 1; i >= 0; i--) {
      const p = L[i];
      p.vida -= dt;
      if (p.vida <= 0) { L[i] = L[L.length - 1]; L.pop(); continue; }
      p.vy += p.g * dt;
      const k = Math.max(0, 1 - p.roce * dt);
      p.vx *= k; p.vy *= k; p.vz *= k;
      p.x += p.vx * dt; p.y += p.vy * dt; p.z += p.vz * dt;
      if (p.suelo && p.y < p.suelo) { p.y = p.suelo; p.vy *= -0.3; p.vx *= 0.6; p.vz *= 0.6; }
      p.tam += p.crece * dt;
    }
    for (let i = 0; i < L.length; i++) {
      const p = L[i];
      this.pos[i * 3] = p.x; this.pos[i * 3 + 1] = p.y; this.pos[i * 3 + 2] = p.z;
      this.colr[i * 3] = p.c.r; this.colr[i * 3 + 1] = p.c.g; this.colr[i * 3 + 2] = p.c.b;
      this.tam[i] = p.tam; this.alfa[i] = p.a * Math.min(1, (p.vida / p.v0) * 1.6);
    }
    const g = this.puntos.geometry;
    g.setDrawRange(0, L.length);
    for (const k of ['position', 'aColor', 'aSize', 'aAlpha']) g.attributes[k].needsUpdate = true;
  }
}

const FX = {
  chispas: null, humo: null, segs: [], luces: [], aros: [], flashes: [], sacudida: 0,
  colores: {},

  crear(scene) {
    this.scene = scene;
    this.chispas = new Particulas(scene, 2500, true);
    this.humo = new Particulas(scene, 900, false);
    this.geoSeg = new THREE.CylinderGeometry(1, 1, 1, 6, 1, true).rotateX(Math.PI / 2).translate(0, 0, 0.5);
    for (let i = 0; i < 4; i++) {
      const l = new THREE.PointLight('#ffaa55', 0, 20, 2);
      l.vida = 0; scene.add(l); this.luces.push(l);
    }
    this.geoFlash = new THREE.IcosahedronGeometry(1, 2);
    this.geoAro = new THREE.RingGeometry(0.85, 1, 48).rotateX(-Math.PI / 2);
    addEventListener('resize', () => { this.chispas.mat.uniforms.escala.value = innerHeight / 2; this.humo.mat.uniforms.escala.value = innerHeight / 2; });
  },

  c(hex, k = 1) { const key = hex + k; return this.colores[key] || (this.colores[key] = col(hex).multiplyScalar(k)); },

  // segmento brillante entre a y b (trazadoras, rayos, láser)
  segmento(a, b, radio, color, vida, k = 3) {
    let s = this.segs.find((x) => x.vida <= 0 && !x.m.visible);
    if (!s) {
      if (this.segs.length > 120) s = this.segs.reduce((m, x) => (x.vida < m.vida ? x : m));
      else {
        const m = new THREE.Mesh(this.geoSeg, new THREE.MeshBasicMaterial({ transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
        m.frustumCulled = false; this.scene.add(m); s = { m }; this.segs.push(s);
      }
    }
    const L = a.distanceTo(b);
    s.m.position.copy(a); s.m.lookAt(b); s.m.scale.set(radio, radio, L);
    s.m.material.color.copy(col(color)).multiplyScalar(k);
    s.m.material.opacity = 1; s.m.visible = true;
    s.vida = vida; s.v0 = vida; s.r0 = radio;
    return s;
  },

  luz(pos, color, intens, dist, vida) {
    const l = this.luces.reduce((m, x) => (x.vida < m.vida ? x : m));
    l.position.copy(pos); l.color.set(color); l.i0 = intens; l.intensity = intens; l.distance = dist; l.vida = vida; l.v0 = vida;
  },

  flash(pos, radio, color, vida) {
    const m = new THREE.Mesh(this.geoFlash, new THREE.MeshBasicMaterial({ color: col(color).multiplyScalar(3), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }));
    m.position.copy(pos); m.scale.setScalar(radio * 0.3);
    this.scene.add(m); this.flashes.push({ m, vida, v0: vida, r: radio });
  },

  aro(pos, radio, color, vida, alto = 0.15) {
    const m = new THREE.Mesh(this.geoAro, new THREE.MeshBasicMaterial({ color: col(color).multiplyScalar(2.5), transparent: true, side: THREE.DoubleSide, blending: THREE.AdditiveBlending, depthWrite: false }));
    m.position.set(pos.x, pos.y + alto, pos.z); m.scale.setScalar(0.5);
    this.scene.add(m); this.aros.push({ m, vida, v0: vida, r: radio });
  },

  chispazo(pos, color, n = 10, vel = 8, tam = 0.18) {
    const c = this.c(color, 3);
    for (let i = 0; i < n; i++)
      this.chispas.emitir(pos.x, pos.y, pos.z, rand(-1, 1) * vel, rand(-0.3, 1.2) * vel, rand(-1, 1) * vel, c, tam * rand(0.6, 1.3), rand(0.2, 0.5), { g: -18, roce: 2, suelo: Terreno.altura(pos.x, pos.z) + 0.05 });
  },

  explosion(pos, radio, color = '#ff9a3c') {
    const dist = pos.distanceTo(G.camera.position);
    Sfx.play(radio > 3 ? 'explosion' : 'explosionChica', dist);
    this.flash(pos, radio * 1.2, color, 0.35);
    this.luz(pos, color, radio * 60, radio * 6, 0.45);
    const fuego = this.c(color, 3), amarillo = this.c('#ffe27a', 3);
    for (let i = 0; i < 26 + radio * 6; i++) {
      const d = V3(rand(-1, 1), rand(-0.2, 1), rand(-1, 1)).normalize().multiplyScalar(rand(0.3, 1) * radio * 3);
      this.chispas.emitir(pos.x, pos.y, pos.z, d.x, d.y, d.z, i % 3 ? fuego : amarillo, rand(0.6, 1.4) * radio * 0.5, rand(0.3, 0.7), { roce: 3, crece: radio * 0.6 });
    }
    for (let i = 0; i < 14 + radio * 2; i++) {
      const d = V3(rand(-1, 1), rand(0, 1), rand(-1, 1)).normalize().multiplyScalar(rand(0.5, 1.5) * radio);
      const gris = rand(0.08, 0.2);
      this.humo.emitir(pos.x, pos.y, pos.z, d.x, d.y + 1, d.z, new THREE.Color(gris, gris, gris), radio * rand(0.5, 0.9), rand(1.2, 2.4), { roce: 1.5, crece: radio * 0.8, a: 0.7, g: 1.5 });
    }
    this.chispazo(pos, '#ffcc66', 24, radio * 4, 0.16);
    this.aro(V3(pos.x, Terreno.altura(pos.x, pos.z), pos.z), radio * 1.6, color, 0.5);
    this.sacudir(clamp(radio * 0.25 - dist * 0.012, 0, 1));
  },

  // rayo eléctrico zigzagueante (tesla, relámpagos)
  arco(a, b, color, vida, grosor = 0.05, desvio = 0.6) {
    const n = Math.max(3, Math.floor(a.distanceTo(b) / 1.6));
    let prev = a.clone();
    for (let i = 1; i <= n; i++) {
      const p = a.clone().lerp(b, i / n);
      if (i < n) p.add(V3(rand(-1, 1), rand(-1, 1), rand(-1, 1)).multiplyScalar(desvio));
      this.segmento(prev, p, grosor, color, vida, 4);
      prev = p;
    }
  },

  rayo(desde, hasta, fuerte) {
    const n = 14;
    let prev = desde.clone();
    for (let i = 1; i <= n; i++) {
      const p = desde.clone().lerp(hasta, i / n);
      if (i < n) p.add(V3(rand(-5, 5), rand(-2, 2), rand(-5, 5)));
      this.segmento(prev, p, fuerte ? 0.45 : 0.3, '#e8eeff', 0.28, 5);
      if (Math.random() < 0.3) {
        const r = p.clone().add(V3(rand(-12, 12), rand(-10, -3), rand(-12, 12)));
        this.segmento(p, r, 0.14, '#b9c8ff', 0.22, 4);
      }
      prev = p;
    }
    this.luz(hasta.clone().setY(hasta.y + 3), '#c7d4ff', 400, 70, 0.3);
    this.chispazo(hasta, '#d8e2ff', 30, 12, 0.3);
    this.aro(hasta, 6, '#c7d4ff', 0.5);
  },

  sacudir(k) { this.sacudida = Math.min(1.2, this.sacudida + k); },

  update(dt) {
    this.chispas.update(dt);
    this.humo.update(dt);
    for (const s of this.segs) {
      if (s.vida <= 0) { s.m.visible = false; continue; }
      s.vida -= dt;
      const k = Math.max(0, s.vida / s.v0);
      s.m.material.opacity = k;
      s.m.scale.x = s.m.scale.y = s.r0 * (0.4 + 0.6 * k);
      if (s.vida <= 0) s.m.visible = false;
    }
    for (const l of this.luces) {
      if (l.vida > 0) { l.vida -= dt; l.intensity = l.i0 * Math.max(0, l.vida / l.v0); } else l.intensity = 0;
    }
    for (let i = this.flashes.length - 1; i >= 0; i--) {
      const f = this.flashes[i]; f.vida -= dt;
      const k = 1 - f.vida / f.v0;
      f.m.scale.setScalar(f.r * (0.3 + k * 0.9)); f.m.material.opacity = Math.max(0, 1 - k);
      if (f.vida <= 0) { this.scene.remove(f.m); f.m.material.dispose(); this.flashes.splice(i, 1); }
    }
    for (let i = this.aros.length - 1; i >= 0; i--) {
      const f = this.aros[i]; f.vida -= dt;
      const k = 1 - f.vida / f.v0;
      f.m.scale.setScalar(f.r * (0.2 + k)); f.m.material.opacity = Math.max(0, 1 - k);
      if (f.vida <= 0) { this.scene.remove(f.m); f.m.material.dispose(); this.aros.splice(i, 1); }
    }
    this.sacudida = Math.max(0, this.sacudida - dt * 1.8);
  },
};
