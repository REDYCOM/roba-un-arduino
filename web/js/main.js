// =====================================================================
//  ARRANQUE Y BUCLE PRINCIPAL
// =====================================================================
window.iniciarJuego = function () {
  const app = document.getElementById('app');
  const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
  renderer.setSize(innerWidth, innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap; // sombras nítidas como Roblox Future
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  app.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(75, innerWidth / innerHeight, 0.05, 2500);
  scene.add(camera);
  Object.assign(G, { renderer, scene, camera, puntos: 0, bajas: 0, uTiempo: { value: 0 } });

  // post-proceso: brillo (bloom) para luces, láseres y ojos de robots
  const composer = new ADD.EffectComposer(renderer);
  composer.addPass(new ADD.RenderPass(scene, camera));
  const bloom = new ADD.UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.5, 0.45, 1.5);
  composer.addPass(bloom);
  composer.addPass(new ADD.OutputPass());
  G.composer = composer; G.bloom = bloom;

  Input.init(renderer.domElement);
  Cielo.crear(scene);
  Agua.crear(scene);
  Mapa.construir(scene);
  Clima.crear(scene, renderer);
  FX.crear(scene);
  Armas.init(camera);
  HUD.init();
  HUD.puntos();
  Jugador.revivir();

  addEventListener('resize', () => {
    camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight); composer.setSize(innerWidth, innerHeight);
  });

  // ---------- menús ----------
  const menu = document.getElementById('menu'), pausa = document.getElementById('pausa'), hud = document.getElementById('hud');
  const btn = document.getElementById('btnJugar');
  btn.disabled = false; btn.textContent = '¡JUGAR!';
  const bloquear = () => { const p = renderer.domElement.requestPointerLock(); if (p && p.catch) p.catch(() => {}); };
  btn.onclick = () => {
    Sfx.init();
    menu.classList.add('oculto'); hud.classList.remove('oculto');
    G.estado = 'jugando';
    if (Oleadas.fase === 'espera') Oleadas.iniciar();
    bloquear();
  };
  document.getElementById('btnSeguir').onclick = () => { pausa.classList.add('oculto'); G.estado = 'jugando'; Sfx.init(); bloquear(); };
  renderer.domElement.addEventListener('click', () => { if (G.estado === 'jugando' && !Input.bloqueado) bloquear(); });
  document.addEventListener('pointerlockchange', () => {
    if (!Input.bloqueado && G.estado === 'jugando' && !G.sinPausa) { G.estado = 'pausa'; pausa.classList.remove('oculto'); }
  });

  // ---------- calidad ----------
  const aplicarCalidad = () => {
    renderer.setPixelRatio(G.calidad ? Math.min(devicePixelRatio, 1.5) : 0.75);
    renderer.setSize(innerWidth, innerHeight); composer.setSize(innerWidth, innerHeight);
    bloom.enabled = !!G.calidad;
    Clima.sol.shadow.mapSize.set(G.calidad ? 2048 : 1024, G.calidad ? 2048 : 1024);
    if (Clima.sol.shadow.map) { Clima.sol.shadow.map.dispose(); Clima.sol.shadow.map = null; }
    if (G.pasto) G.pasto.visible = !!G.calidad;
    HUD.feed(G.calidad ? '⚙️ Calidad <b>ALTA</b>' : '⚙️ Calidad <b>BAJA</b> (más rápido)');
  };

  // ---------- bucle ----------
  const reloj = new THREE.Clock();
  let fpsT = 0, fpsN = 0, lentos = 0;
  function cuadro() {
    requestAnimationFrame(cuadro);
    const dt = Math.min(reloj.getDelta(), 0.05);
    G.dt = dt;
    if (G.estado === 'jugando') {
      G.t += dt;
      G.uTiempo.value = G.t;
      if (Input.pulso('KeyQ')) { G.calidad = G.calidad ? 0 : 1; aplicarCalidad(); }
      if (Torretas.montada) Torretas.updateMontada(dt); else Jugador.update(dt);
      Torretas.update(dt);
      Armas.update(dt);
      Oleadas.update(dt);
      Robots.update(dt);
      for (const f of [...G.anim]) f(dt, G.t);
      FX.update(dt);
      Clima.update(dt, scene);
      Agua.update(dt);
      HUD.update(dt);
      // si va muy lento varios segundos, baja la calidad sola
      fpsT += dt; fpsN++;
      if (fpsT > 3) { if (fpsN / fpsT < 28 && G.calidad) { lentos++; if (lentos >= 2) { G.calidad = 0; aplicarCalidad(); } } else lentos = 0; fpsT = 0; fpsN = 0; }
    } else if (G.estado === 'menu') {
      // cámara del menú: vuelo lento alrededor de la isla
      G.t += dt; G.uTiempo.value = G.t;
      const a = G.t * 0.05;
      camera.position.set(Math.cos(a) * 95, 38, Math.sin(a) * 95);
      camera.lookAt(0, 6, 0);
      for (const f of [...G.anim]) f(dt, G.t);
      FX.update(dt);
      Clima.update(dt, scene);
      Agua.update(dt);
    }
    Armas.soporte.visible = G.estado !== 'menu' && !Torretas.montada;
    Input.fin();
    composer.render();
  }
  cuadro();
};
