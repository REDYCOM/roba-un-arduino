// =====================================================================
//  GRAN FINAL: cae el robot de ARDUNOL → su ejército se apaga →
//  del corazón del robot sube el ARDUINO SUPREMO como trofeo →
//  el jugador lo roba con E → ¡la paz vuelve al Reino Tecnológico!
//  (el Arduino es el mismo modelo de Tinkercad de las piezas)
// =====================================================================
const Final = {
  estado: null,   // null · 'apagando' · 'subiendo' · 'listo' · 'robado'
  trofeo: null, t: 0, pos: null,
  ALTO: 3.2,      // metros que mide el Arduino trofeo
  SUBE: 3.2,      // altura a la que flota

  // lo llama Robots.morir cuando muere el jefe final
  jefeCayo(r) {
    if (this.estado) return;
    this.estado = 'apagando'; this.t = 0;
    this.pos = V3(r.pos.x, Terreno.altura(r.pos.x, r.pos.z), r.pos.z);
    Jugador.invulnerable = 999;        // nadie te quita el final
    HUD.jefe(null);
    HUD.anuncio('¡EL ROBOT DE ARDUNOL CAYÓ!', 'Sin su creador, el ejército se apaga…', '#ffcf4a');
    if (Red.cliente) return;           // en los alumnos, el resto lo hace la computadora del profe
    Oleadas.cola.length = 0;           // no llegan más robots
    // el resto de robots explota en cadena
    const resto = Robots.vivos.filter((o) => o !== r && !o.muerto).sort(() => Math.random() - 0.5);
    resto.forEach((o, i) => { o.apagarEn = 0.6 + i * 0.18; });
    // las balas en el aire desaparecen
    for (const b of Robots.balas) { FX.chispazo(b.pos, '#ffcf4a', 6, 3); G.scene.remove(b.m); }
    Robots.balas.length = 0;
  },

  crearTrofeo() {
    const g = new THREE.Group();
    g.position.copy(this.pos);
    // el Arduino parado de frente, un poco inclinado hacia atrás
    const pieza = PIEZAS.find((p) => p.id === 'arduino');
    const m = Componentes.malla(pieza);
    const bb = m.geometry.boundingBox, tam = bb.getSize(V3()), c = bb.getCenter(V3());
    const s = this.ALTO / Math.max(tam.x, tam.y, tam.z);
    m.scale.setScalar(s);
    m.position.copy(c).multiplyScalar(-s);             // centrado
    m.castShadow = true;
    const parado = new THREE.Group(); parado.add(m);
    parado.rotation.x = Math.PI / 2 - 0.15;            // la placa de pie, mirando al frente
    const giro = new THREE.Group(); giro.add(parado); g.add(giro);
    // halo dorado detrás
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: Terror.textura(), color: col('#ffcf4a').multiplyScalar(2.2), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    halo.scale.setScalar(5.5); halo.position.z = -0.6; giro.add(halo);
    // tres aros dorados que giran
    const matAro = new THREE.MeshBasicMaterial({ color: col('#ffcf4a').multiplyScalar(3) });
    const aros = [1.9, 2.3, 2.7].map((rad, i) => {
      const a = new THREE.Mesh(new THREE.TorusGeometry(rad, 0.045, 8, 64), matAro);
      a.rotation.set(Math.PI / 2 + i * 0.5, i * 0.7, 0); giro.add(a); return a;
    });
    // columna de luz hasta el cielo
    const columna = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 0.5, 160, 24, 1, true),
      new THREE.MeshBasicMaterial({ color: col('#ffd86a').multiplyScalar(1.6), transparent: true, opacity: 0, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }));
    columna.position.y = this.SUBE + 2.2 + 80; g.add(columna);   // sale desde arriba del Arduino
    // círculo brillante en el suelo
    const suelo = new THREE.Mesh(new THREE.CircleGeometry(4, 40).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ map: Terror.textura(), color: col('#ffcf4a').multiplyScalar(0.9), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
    suelo.position.y = 0.08; g.add(suelo);
    const luz = new THREE.PointLight('#fff1c4', 0, 30, 1.5); luz.position.y = this.SUBE; g.add(luz);
    const et = Componentes.etiqueta('🏆 ARDUINO SUPREMO', 'Pulsa E para robarlo'); et.position.y = this.SUBE + 2.6; et.scale.multiplyScalar(1.6); et.visible = false; g.add(et);
    for (const o of [halo, columna, suelo, et]) o.raycast = () => {};
    G.scene.add(g);
    this.trofeo = { g, giro, aros, columna, suelo, luz, et, halo };
  },

  update(dt) {
    if (!this.estado) return;
    this.t += dt;
    // robots que quedaban: se apagan y explotan
    for (const o of [...Robots.vivos]) {
      if (o.apagarEn === undefined) continue;
      o.apagarEn -= dt;
      if (o.apagarEn <= 0) { o.apagarEn = undefined; Robots.danar(o, 1e7, o.centro()); }
    }
    if (this.estado === 'apagando' && this.t > 3.6) {
      // del corazón del robot caído sale el Arduino
      this.estado = 'subiendo'; this.t = 0;
      this.crearTrofeo();
      Clima.poner('dia');
      FX.explosion(this.pos.clone().setY(this.pos.y + 1), 4, '#ffcf4a');
      FX.aro(this.pos, 18, '#ffcf4a', 1.2);
      Sfx.play('oleada');
      HUD.anuncio('🏆 ¡EL ARDUINO SUPREMO! 🏆', 'Ve a robarlo para devolver la paz', '#ffcf4a');
    }
    const T = this.trofeo;
    if (!T) return;
    // animación del trofeo
    const sube = this.estado === 'subiendo' ? smooth(0, 1, this.t / 2.8) : 1;
    T.giro.position.y = 0.4 + sube * (this.SUBE - 0.4) + Math.sin(G.t * 2) * 0.15 * sube;
    T.giro.rotation.y += dt * (0.8 + (1 - sube) * 6);
    T.aros.forEach((a, i) => { a.rotation.x += dt * (0.6 + i * 0.4); a.rotation.y += dt * (0.9 - i * 0.3); });
    T.halo.material.opacity = 0.3 + Math.sin(G.t * 3) * 0.1;
    T.columna.material.opacity = sube * 0.3 * (0.8 + Math.sin(G.t * 5) * 0.2);
    T.luz.intensity = sube * 60;
    // la luz va del lado de la cámara para que se vea bien la placa
    const haciaCam = G.camera.getWorldPosition(V3()).sub(this.pos).setY(0).normalize().multiplyScalar(3);
    T.luz.position.set(haciaCam.x, T.giro.position.y + 1, haciaCam.z);
    if (Math.random() < dt * 30) {
      const a = Math.random() * TAU, rr = rand(0.5, 3);
      FX.chispas.emitir(this.pos.x + Math.cos(a) * rr, this.pos.y + rand(0, 1), this.pos.z + Math.sin(a) * rr, 0, rand(2, 6), 0, FX.c('#ffcf4a', 3), rand(0.08, 0.2), rand(1, 2));
    }
    if (this.estado === 'subiendo' && this.t > 2.8) { this.estado = 'listo'; T.et.visible = true; }
    if (this.estado !== 'listo') return;
    // robarlo
    const d = Math.hypot(Jugador.pos.x - this.pos.x, Jugador.pos.z - this.pos.z);
    if (d < 5 && !Jugador.muerto) {
      G.aviso = 'Pulsa <kbd>E</kbd> para robar el <b>🏆 ARDUINO SUPREMO</b>';
      if (Input.pulso('KeyE')) {
        if (Red.cliente) { Red.ev({ a: 'robar' }, 'host'); HUD.feed('🏆 ¡Intentando robar el Arduino!'); }
        else this.robar();
      }
    }
  },

  // quien = nombre del jugador que lo robó (en multijugador puede ser otro)
  robar(quien) {
    if (this.estado === 'robado') return;
    this.estado = 'robado';
    if (Red.host) Red.ev({ a: 'robado', q: quien || G.miNombre });
    if (quien && quien !== G.miNombre) HUD.feed('🏆 <b>' + quien + '</b> robó el ARDUINO SUPREMO');
    const T = this.trofeo;
    if (!T) { sumarPuntos(500); HUD.victoria(); return; }
    Sfx.play('recoger'); Sfx.play('oleada');
    FX.explosion(T.giro.getWorldPosition(V3()), 5, '#ffcf4a');
    FX.aro(this.pos, 30, '#ffffff', 1.4); FX.sacudir(0.6);
    Clima.flash = 1;
    // el Arduino vuela hacia ti y se encoge
    const desde = T.giro.getWorldPosition(V3()), t0 = G.t;
    T.et.visible = false;
    const f = () => {
      const e = Math.min(1, (G.t - t0) / 0.8);
      const hacia = Jugador.ojo();
      T.giro.position.copy(desde.clone().lerp(hacia, e * e).sub(T.g.position));
      T.giro.scale.setScalar(Math.max(0.01, 1 - e));
      T.columna.material.opacity *= 0.92; T.luz.intensity *= 0.92;
      if (e >= 1) { G.anim.splice(G.anim.indexOf(f), 1); G.scene.remove(T.g); }
    };
    G.anim.push(f);
    sumarPuntos(500);
    HUD.victoria();
  },
};
