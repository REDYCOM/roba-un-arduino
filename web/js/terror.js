// =====================================================================
//  TERROR: que los robots den miedo
//  - ojos rojos brillantes con halo
//  - aura que late en el suelo
//  - brasas que suben a su alrededor
//  (los jefes conservan el color de sus ojos y tienen aura propia)
// =====================================================================
const Terror = {
  tex: null, matOjo: null,

  textura() {
    if (this.tex) return this.tex;
    const N = 64, cv = document.createElement('canvas'); cv.width = cv.height = N;
    const c = cv.getContext('2d'), g = c.createRadialGradient(N / 2, N / 2, 0, N / 2, N / 2, N / 2);
    g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.25, 'rgba(255,255,255,0.55)');
    g.addColorStop(0.6, 'rgba(255,255,255,0.12)'); g.addColorStop(1, 'rgba(255,255,255,0)');
    c.fillStyle = g; c.fillRect(0, 0, N, N);
    this.tex = new THREE.CanvasTexture(cv);
    this.matOjo = new THREE.MeshBasicMaterial({ color: col('#ff1414').multiplyScalar(4.5) });
    return this.tex;
  },

  decorar(mod, cfg) {
    const tex = this.textura();
    const sinRayo = () => {};
    for (const ojo of mod.ojos) {
      let c;
      if (cfg.jefe && !cfg.tinte) c = ojo.material.color.clone().multiplyScalar(0.6);
      else { ojo.material = this.matOjo; c = col('#ff2020').multiplyScalar(1.6); }
      ojo.geometry.computeBoundingSphere();
      const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, color: c, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
      sp.scale.setScalar(ojo.geometry.boundingSphere.radius * (cfg.jefe ? 4 : 6));
      sp.raycast = sinRayo;
      ojo.add(sp);
    }
    // si el jefe está corrompido, toda su energía se vuelve roja
    if (cfg.tinte) mod.raiz.traverse((o) => { if (o.isMesh && o.material.isMeshBasicMaterial && o.material !== this.matOjo) o.material.color.copy(col(cfg.tinte)).multiplyScalar(2.8); });
    // aura en el suelo
    const tam = mod.med.ancho * (cfg.escala || 1) * 1.7 + 1.6;
    const aura = new THREE.Mesh(new THREE.PlaneGeometry(tam, tam).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ map: tex, color: col(cfg.aura || '#ff1a1a').multiplyScalar(1.3), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    aura.position.y = cfg.vuela ? -6 : 0.07;
    aura.raycast = sinRayo; aura.userData.noResto = true;
    if (!cfg.vuela) mod.raiz.add(aura);
    mod.aura = aura;
    mod.colorBrasa = col(cfg.aura || '#ff2a10').multiplyScalar(2.5);
  },

  update(r, dt) {
    const a = r.mod.aura;
    if (a && a.parent) a.material.opacity = 0.5 + Math.sin(G.t * 4 + r.zig) * 0.2 + (r.furia ? 0.2 : 0);
    // brasas
    if (Math.random() < dt * (2 + r.cfg.fx * 2.5)) {
      const ang = Math.random() * TAU, rad = r.radio * rand(0.4, 1.1);
      const y = r.pos.y + (r.cfg.vuela ? rand(-0.3, 0.3) : rand(0.1, r.cfg.alto * 0.7));
      FX.chispas.emitir(r.pos.x + Math.cos(ang) * rad, y, r.pos.z + Math.sin(ang) * rad, rand(-0.3, 0.3), rand(0.8, 2.2), rand(-0.3, 0.3),
        r.mod.colorBrasa, rand(0.06, 0.16) * Math.sqrt(r.cfg.fx), rand(0.8, 1.6), { roce: 0.5 });
    }
  },

  quitar(r) {},
};
