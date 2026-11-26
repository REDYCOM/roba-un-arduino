// =====================================================================
//  MENÚ DE INFORMACIÓN — [I] en la partida o ℹ️ en el menú
//  Se arma con los datos reales del juego (piezas, runas, poderes,
//  puntos), así siempre dice la verdad aunque cambien los valores.
// =====================================================================
const Info = {
  abierta: false, tab: 'historia',
  TABS: [['historia', '📖 Historia'], ['jugar', '🎯 Cómo jugar'], ['base', '🏠 Tu base'], ['puntos', '⭐ Puntos'], ['objetos', '🎁 Objetos'], ['controles', '⌨️ Controles']],

  abrir(tab) {
    this.abierta = true;
    if (tab) this.tab = tab;
    if (G.estado !== 'menu') { G.sinPausa = true; if (document.exitPointerLock) document.exitPointerLock(); }
    this.dibujar();
    document.getElementById('info').classList.remove('oculto');
  },
  cerrar() {
    this.abierta = false;
    document.getElementById('info').classList.add('oculto');
    if (G.estado === 'jugando') {
      G.sinPausa = false;
      const p = G.renderer.domElement.requestPointerLock(); if (p && p.catch) p.catch(() => {});
    }
  },

  update() {
    if (Input.pulso('KeyI') && !Estacion.abierta && !Tienda.abierta && !Profe.abierto) {
      if (this.abierta) this.cerrar(); else this.abrir();
    }
  },

  dibujar() {
    const el = document.getElementById('info');
    el.innerHTML = `<div class="ventana"><div class="cab"><b>ℹ️ INFORMACIÓN</b><span>Todo lo que necesitas saber para jugar</span><button class="x" data-cerrar>✕ <kbd>I</kbd></button></div>
      <div class="tabs">${this.TABS.map(([id, t]) => `<button data-tab="${id}" class="${id === this.tab ? 'sel' : ''}">${t}</button>`).join('')}</div>
      <div class="infoTxt">${this[this.tab]()}</div></div>`;
    el.onclick = (e) => {
      if (e.target.closest('[data-cerrar]') || e.target === el) { this.cerrar(); return; }
      const b = e.target.closest('[data-tab]'); if (b) { this.tab = b.dataset.tab; this.dibujar(); }
    };
  },

  historia() {
    return `<p>El mago <b>ARDUNOL</b> creó un robot malvado y le dio el arma más poderosa que existe: el <b>ARDUINO SUPREMO</b>.
      Con su ejército de robots quiere dominar el mundo y destruir <b>el último bastión del Reino Tecnológico</b>.</p>
      <p>Tú eres un soldado del Reino. Junto a tu equipo debes resistir sus ataques, aprender a programar Arduino para ganar poderes,
      destruir a su robot supremo y <b>robar el Arduino</b> para devolver la paz.</p>
      <h3>🏆 ¿Cómo se gana?</h3>
      <p>Sobrevive a las <b>8 oleadas</b>. En la última llega <b>ARDUNOL DESATADO</b>: cuando caiga, del lugar sale el ARDUINO SUPREMO.
      Acércate y pulsa <kbd>E</kbd> para robarlo.</p>`;
  },

  jugar() {
    return `<ul>
      <li>🔒 Al empezar, las <b>rejas de las bases están cerradas</b>: es el momento de prepararte y gastar tus <b>🎁 ${PUNTOS.regalo} puntos de regalo</b> en la Tienda.
        ${G.profe ? 'Tú, como profe, decides cuándo se abren (<kbd>F1</kbd>).' : 'El profe decide cuándo se abren.'}</li>
      <li>🤖 Son <b>8 oleadas</b> de robots. Entre oleadas hay <b>20 s de descanso</b> con una <b>pregunta rápida</b> (responde con <kbd>1</kbd>-<kbd>4</kbd>).</li>
      <li>⚠️ Oleada 3: <b>MEGA-ARDUINO</b> · Oleada 4: <b>enjambre de drones</b> · Oleada 5: <b>robot morado de ARDUNOL</b> · Oleada 8: <b>ARDUNOL DESATADO</b>
        (mientras viva, manda refuerzos).</li>
      <li>💀 Los robots gigantes (Tanque, Coloso y jefes) te derriban si te tocan: <b>¡mantén distancia!</b></li>
      <li>❤️ Si caes, reapareces en tu base a los 4 segundos. Tu vida se recupera sola si no te golpean.</li>
      <li>👥 Las barras de vida dicen quién es quién:
        <span class="chip" style="background:#3ee08f;color:#04210f">✚ aliado</span>
        <span class="chip" style="background:#ff4d5e;color:#fff">✖ rival</span>
        <span class="chip" style="background:#ffcf4a;color:#241a00">★ profe</span></li>
    </ul>`;
  },

  base() {
    return `<p>Tu base tiene el color de tu equipo. Adentro y alrededor encuentras:</p>
      <div class="tarjetas">
        <div class="tarj"><b>🧩 Estación Arduino</b><p>Adentro, en la pared derecha. Ordena los bloques del programa y pruébalo en el simulador.
          Cada reto resuelto te da <b>puntos y un poder para siempre</b>. También tiene preguntas.</p></div>
        <div class="tarj"><b>🛒 Tienda</b><p>Adentro, en la pared izquierda. Canjea tus <b>💰 puntos para canjear</b> por armas, mejoras y ayudas.
          Gastar <b>no</b> baja el puntaje de tu equipo.</p></div>
        <div class="tarj"><b>🔵 Anillo de entrega</b><p>Frente a la puerta. Trae aquí las piezas del robot seguidor de línea; con las 9 se arma un robot que pelea a tu lado.</p></div>
        <div class="tarj"><b>🔫 Ametralladora fija</b><p>Al costado de la base. Súbete con <kbd>E</kbd> y bájate con <kbd>E</kbd> o <kbd>Espacio</kbd>. ¡Cuidado, se recalienta!</p></div>
        <div class="tarj"><b>♻️ Punto de regeneración</b><p>Se activa con el poder 5: te cura mientras estés parado encima.</p></div>
      </div>`;
  },

  puntos() {
    const R = (t) => TIPOS[t].puntos;
    const fila = (a, b) => `<tr><td>${a}</td><td>${b}</td></tr>`;
    return `<p>Hay dos contadores: <b>⭐ Puntos</b> = el puntaje de tu equipo · <b>💰 Para canjear</b> = tus puntos para la Tienda.
      Todo lo que ganas suma a los dos; gastar en la Tienda solo baja los 💰.</p>
      <h3>🤖 Destruir robots</h3><table>
        ${fila('Araña · Seguidor · Soldado · Dron', `${R('Arana')} – ${R('Soldado')}`)}${fila('Chatarra · Tanque', `${R('Chatarra')} – ${R('Tanque')}`)}
        ${fila('Coloso', R('Coloso'))}${fila('MEGA-ARDUINO · Robot de Ardunol', `${R('Jefe')} – ${R('JefeFinal')}`)}${fila('ARDUNOL DESATADO', R('Desatado'))}</table>
      <h3>🎁 Recolectar objetos</h3><table>
        ${fila('🎁 Regalo al empezar (para canjear)', '+' + PUNTOS.regalo)}
        ${fila('Recoger una pieza del robot', '+' + PUNTOS.recogerPieza)}${fila('Entregarla en tu base', '+' + PUNTOS.entregarPieza)}
        ${fila('Pieza repetida (repuesto)', '+' + PUNTOS.repuesto)}${fila('🤖 Robot seguidor armado (9 piezas)', '+' + PUNTOS.robotArmado)}
        ${fila('Runa', '+' + PUNTOS.runa)}${fila('📦 Caja que suelta un robot', '+' + PUNTOS.caja)}${fila('🔋 Batería', '+' + PUNTOS.bateria)}</table>
      <h3>🧠 Aprender</h3><table>
        ${fila('Reto de la Estación Arduino', `+${Math.min(...RETOS.map((r) => r.puntos))} – ${Math.max(...RETOS.map((r) => r.puntos))}`)}
        ${fila('Pregunta de la Estación (primera vez)', '+20')}${fila('Pregunta rápida entre oleadas', '+' + Quiz.PREMIO)}</table>
      <h3>🏆 Batalla</h3><table>${fila('Superar una oleada', '+20 × nº de oleada')}${fila('Robar el ARDUINO SUPREMO', '+500')}</table>`;
  },

  objetos() {
    return `<h3>🔧 Piezas del robot seguidor de línea</h3><p>Flotan por el mapa con un anillo azul. <kbd>E</kbd> para recoger; si te golpean fuerte, se te caen.</p>
      <div class="tarjetas">${PIEZAS.map((p) => `<div class="tarj"><b>${p.icono} ${p.nombre}</b><p>${p.info}</p></div>`).join('')}</div>
      <h3>💎 Runas</h3><p>Cristales que aparecen durante las oleadas. Tócalas para activarlas.</p>
      <div class="tarjetas">${Object.values(RUNAS).map((r) => `<div class="tarj"><b style="color:${r.color}">${r.icono} ${r.nombre}</b><p>${r.desc}${r.dur ? ' · ' + r.dur + ' s' : ''}</p></div>`).join('')}</div>
      <h3>⚡ Poderes permanentes</h3><p>Se ganan resolviendo los retos de la Estación Arduino.</p>
      <div class="tarjetas">${PODERES.map((p, i) => `<div class="tarj"><b>${i + 1}. ${p.icono} ${p.nombre}</b><p>${p.desc}</p></div>`).join('')}</div>`;
  },

  controles() {
    const t = (k, d) => `<tr><td>${k}</td><td style="color:#fff;text-align:left;font-weight:500">${d}</td></tr>`;
    return `<table>
      ${t('<kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd>', 'Moverse')}${t('<kbd>Mouse</kbd>', 'Apuntar')}${t('<kbd>Click</kbd>', 'Disparar')}
      ${t('<kbd>Espacio</kbd>', 'Saltar (volando: subir)')}${t('<kbd>Shift</kbd>', 'Correr (volando: bajar)')}
      ${t('<kbd>1</kbd>-<kbd>6</kbd> / <kbd>Rueda</kbd>', 'Cambiar de arma (en una pregunta rápida: responder)')}
      ${t('<kbd>E</kbd>', 'Recoger piezas · usar la Estación, la Tienda y la ametralladora · robar el Arduino')}
      ${t('<kbd>F</kbd>', 'Volar (con el poder 9)')}${t('<kbd>I</kbd>', 'Este menú de información')}${t('<kbd>Q</kbd>', 'Calidad gráfica alta / baja')}
      ${t('<kbd>Esc</kbd>', 'Pausa / cerrar ventanas')}${G.profe ? t('<kbd>F1</kbd>', '👑 Panel del profe') : ''}</table>`;
  },
};

addEventListener('keydown', (e) => { if (e.code === 'Escape' && Info.abierta) Info.cerrar(); });
