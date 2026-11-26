// =====================================================================
//  ARRANQUE Y BUCLE PRINCIPAL
// =====================================================================
window.iniciarJuego = function () {
  Mech.cargar(); // jefe final (oleada 8): se descarga mientras juegas
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
  Object.assign(G, { renderer, scene, camera, puntos: 0, canje: 0, misPuntos: 0, puntosEq: [0, 0, 0, 0, 0, 0], bajas: 0, uTiempo: { value: 0 } });

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
  Componentes.crear(scene);
  HUD.init();
  Poderes.init();
  HUD.puntos();
  Jugador.revivir();

  addEventListener('resize', () => {
    camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight); composer.setSize(innerWidth, innerHeight);
  });

  // ---------- elegir equipo y jugadores ----------
  const cajaEq = document.getElementById('equiposBtns'), slider = document.getElementById('sliderJug');
  // ---------- perfil: nombre o apodo + color del soldado (se recuerdan en este navegador) ----------
  const leer = (k, d) => { try { return localStorage.getItem(k) || d; } catch (e) { return d; } };
  const guardar = (k, v) => { try { localStorage.setItem(k, v); } catch (e) {} };
  const inpNombre = document.getElementById('nombreJug'), cajaCol = document.getElementById('coloresBtns');
  const limpiarNombre = (s) => s.replace(/[^\p{L}\p{N} _.-]/gu, '').replace(/\s+/g, ' ').trim().slice(0, 14);
  G.miNombre = limpiarNombre(leer('rua.nombre', '')) || 'Jugador' + randi(10, 99);
  G.miColor = leer('rua.color', Avatar.COLORES[5]);
  inpNombre.value = G.miNombre;
  const perfil = { previa() { Previa.actualizar(G.miNombre, G.miColor, G.profe); } };
  // ---------- entrar como profe (con clave) ----------
  const claveZona = document.getElementById('profeClave'), inpClave = document.getElementById('claveProfe');
  document.getElementById('btnSoyProfe').onclick = () => { claveZona.classList.toggle('oculto'); inpClave.focus(); };
  const probarClave = async () => {
    if (await Profe.comprobar(inpClave.value)) {
      G.profe = true;
      document.getElementById('profeZona').innerHTML = '<div class="profeOk">👑 Modo profe activado · en la partida pulsa <kbd>F1</kbd> para tu panel</div>';
      perfil.previa();
    } else { inpClave.value = ''; inpClave.placeholder = 'Clave incorrecta'; inpClave.classList.add('error'); }
  };
  document.getElementById('btnClaveOk').onclick = probarClave;
  inpClave.addEventListener('keydown', (e) => { e.stopPropagation(); if (e.key === 'Enter') probarClave(); });
  Avatar.COLORES.forEach((c) => {
    const b = document.createElement('button');
    b.style.background = c; b.title = c;
    if (c === G.miColor) b.classList.add('sel');
    b.onclick = () => { G.miColor = c; guardar('rua.color', c); for (const x of cajaCol.children) x.classList.remove('sel'); b.classList.add('sel'); perfil.previa(); };
    cajaCol.appendChild(b);
  });
  inpNombre.oninput = () => { const n = limpiarNombre(inpNombre.value); G.miNombre = n || 'Jugador'; guardar('rua.nombre', n); perfil.previa(); };
  inpNombre.addEventListener('keydown', (e) => e.stopPropagation()); // escribir no mueve al jugador
  Previa.iniciar(document.getElementById('previa'));
  perfil.previa();
  EQUIPOS.forEach((eq, i) => {
    const b = document.createElement('button');
    b.textContent = 'EQUIPO ' + (i + 1); b.style.background = eq.color;
    if (i === MI_EQUIPO) b.classList.add('sel');
    b.onclick = () => { MI_EQUIPO = i; for (const x of cajaEq.children) x.classList.remove('sel'); b.classList.add('sel'); perfil.previa(); };
    cajaEq.appendChild(b);
  });
  slider.oninput = () => { document.getElementById('numJug').textContent = slider.value; };
  const Partida = (window.Partida = {
    iniciado: false,
    iniciar() {
      if (this.iniciado) return;
      this.iniciado = true;
      G.jugadores = +slider.value;
      // los jugadores llenan equipos de a 5, empezando por el tuyo
      const k = Math.ceil(G.jugadores / 5);
      G.equiposActivos = [MI_EQUIPO];
      for (let i = 1; G.equiposActivos.length < k; i++) G.equiposActivos.push((MI_EQUIPO + i) % EQUIPOS.length);
      Armas.matManga.color.set(G.miColor); // tus mangas son del color de tu soldado
      Companeros.iniciar();
      if (G.profe) document.getElementById('insigniaProfe').classList.remove('oculto');
      // regalo de bienvenida para la tienda
      G.canje += PUNTOS.regalo; HUD.puntos();
      HUD.anuncio('🎁 ' + PUNTOS.regalo + ' PUNTOS DE REGALO', 'Canjéalos en la 🛒 Tienda de tu base', '#ffcf4a');
      Jugador.revivir();
      Componentes.iniciar();
      document.getElementById('hudEquipo').textContent = EQUIPOS[MI_EQUIPO].nombre;
      document.getElementById('hudEquipo').style.color = EQUIPOS[MI_EQUIPO].color;
      document.getElementById('hudJug').textContent = G.jugadores;
    },
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
    Partida.iniciar();
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
      G.aviso = null;
      if (Torretas.montada) Torretas.updateMontada(dt); else Jugador.update(dt);
      Torretas.update(dt);
      Armas.update(dt);
      Oleadas.update(dt);
      Componentes.update(dt);
      Final.update(dt);
      Companeros.update(dt);
      Profe.update(dt);
      Runas.update(dt);
      Poderes.update(dt);
      Estacion.update();
      Tienda.update(dt);
      Info.update();
      Quiz.update(dt);
      Robots.update(dt);
      for (const f of [...G.anim]) f(dt, G.t);
      FX.update(dt);
      Clima.update(dt, scene);
      Agua.update(dt);
      HUD.update(dt);
      HUD.aviso(G.aviso);
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
