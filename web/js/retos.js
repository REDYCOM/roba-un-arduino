// =====================================================================
//  ESTACIÓN ARDUINO: RETOS DE PROGRAMACIÓN (de src/compartido/Retos.luau)
//  Ventana estilo ArduinoBlocks:
//    🔧 Inicializar     (bloques fijos, de contexto)
//    🔁 Bucle principal (bloques que se ARRASTRAN para ordenar)
//  + placa virtual con LEDs y consola serial que EJECUTA tu programa.
//  Al ordenar bien: puntos + un PODER permanente + "SIGUIENTE RETO".
// =====================================================================
const RETOS = (() => {
  const DIG = '#3498db', TIME = '#e67e22', SER = '#1abc9c', CON = '#9b59b6', VAR = '#e74c3c', SET = '#78828c';
  const b = (id, texto, simbolo, color) => ({ id, texto, simbolo, color });
  return [
    { titulo: 'Parpadear el LED (Blink)', descripcion: 'En el bucle: enciende el LED, espera, apágalo y espera.', puntos: 10, poder: 1,
      inicializar: [['configurar pin 13 como SALIDA', SET]],
      bucle: [b('on', 'escribir pin digital 13 → HIGH', 'ON13', DIG), b('w1', 'esperar 1000 milisegundos', 'WAIT', TIME), b('off', 'escribir pin digital 13 → LOW', 'OFF13', DIG), b('w2', 'esperar 1000 milisegundos', 'WAIT', TIME)],
      leds: ['13'] },
    { titulo: 'LED con consola serial', descripcion: 'En el bucle: envía un aviso por serial, enciende el LED y espera.', puntos: 15, poder: 2,
      inicializar: [['configurar pin 13 como SALIDA', SET], ['Puerto serie: iniciar (9600)', SER]],
      bucle: [b('prt', 'Puerto serie: enviar "Encendiendo LED"', 'SPRINT', SER), b('on', 'escribir pin digital 13 → HIGH', 'ON13', DIG), b('w', 'esperar 1000 milisegundos', 'WAIT', TIME)],
      leds: ['13'] },
    { titulo: 'Dos LEDs alternando', descripcion: 'Enciende y apaga el LED 13, luego el LED 12 (efecto alternado).', puntos: 20, poder: 3,
      inicializar: [['configurar pin 13 como SALIDA', SET], ['configurar pin 12 como SALIDA', SET]],
      bucle: [b('on13', 'escribir pin digital 13 → HIGH', 'ON13', DIG), b('w1', 'esperar 500 milisegundos', 'WAIT', TIME), b('of13', 'escribir pin digital 13 → LOW', 'OFF13', DIG),
        b('on12', 'escribir pin digital 12 → HIGH', 'ON12', DIG), b('w2', 'esperar 500 milisegundos', 'WAIT', TIME), b('of12', 'escribir pin digital 12 → LOW', 'OFF12', DIG)],
      leds: ['13', '12'] },
    { titulo: 'Secuencia de 3 LEDs', descripcion: 'Enciende los LEDs 11, 12 y 13 uno tras otro (efecto barrido).', puntos: 25, poder: 4,
      inicializar: [['configurar pines 11, 12 y 13 como SALIDA', SET]],
      bucle: [b('on11', 'escribir pin digital 11 → HIGH', 'ON11', DIG), b('w1', 'esperar 300 milisegundos', 'WAIT', TIME), b('on12', 'escribir pin digital 12 → HIGH', 'ON12', DIG),
        b('w2', 'esperar 300 milisegundos', 'WAIT', TIME), b('on13', 'escribir pin digital 13 → HIGH', 'ON13', DIG), b('w3', 'esperar 300 milisegundos', 'WAIT', TIME)],
      leds: ['11', '12', '13'] },
    { titulo: 'Semáforo corto (verde/rojo)', descripcion: 'Verde: enciende, espera, apaga. Luego rojo: enciende, espera, apaga.', puntos: 30, poder: 5,
      inicializar: [['configurar LED VERDE y LED ROJO como SALIDA', SET]],
      bucle: [b('onv', 'LED VERDE → HIGH', 'ONV', DIG), b('w1', 'esperar 2000 milisegundos', 'WAIT', TIME), b('ofv', 'LED VERDE → LOW', 'OFFV', DIG),
        b('onr', 'LED ROJO → HIGH', 'ONR', DIG), b('w2', 'esperar 2000 milisegundos', 'WAIT', TIME), b('ofr', 'LED ROJO → LOW', 'OFFR', DIG)],
      leds: ['V', 'R'] },
    { titulo: 'LED con pulsador (condicional SI)', descripcion: 'Lee el pulsador. SI está presionado, enciende el LED; SINO, apágalo.', puntos: 35, poder: 6,
      inicializar: [['configurar pin 13 como SALIDA', SET], ['configurar pin 2 como ENTRADA (pulsador)', SET]],
      bucle: [b('rd', 'leer pin digital 2 (pulsador)', 'READ', DIG), b('if', 'si <pulsador = HIGH> hacer', 'IF', CON), b('on', '   escribir pin 13 → HIGH', 'ON13', DIG),
        b('els', 'si no (sino)', 'ELSE', CON), b('off', '   escribir pin 13 → LOW', 'OFF13', DIG)],
      leds: ['13'], boton: true },
    { titulo: 'Semáforo completo', descripcion: 'Verde → Amarillo → Rojo. Cada uno: encender, esperar y apagar.', puntos: 40, poder: 7,
      inicializar: [['configurar VERDE, AMARILLO y ROJO como SALIDA', SET]],
      bucle: [b('onv', 'LED VERDE → HIGH', 'ONV', DIG), b('w1', 'esperar 2000 milisegundos', 'WAIT', TIME), b('ofv', 'LED VERDE → LOW', 'OFFV', DIG),
        b('ona', 'LED AMARILLO → HIGH', 'ONA', DIG), b('w2', 'esperar 1000 milisegundos', 'WAIT', TIME), b('ofa', 'LED AMARILLO → LOW', 'OFFA', DIG),
        b('onr', 'LED ROJO → HIGH', 'ONR', DIG), b('w3', 'esperar 2000 milisegundos', 'WAIT', TIME), b('ofr', 'LED ROJO → LOW', 'OFFR', DIG)],
      leds: ['V', 'A', 'R'] },
    { titulo: 'Semáforo peatonal', descripcion: 'SI el peatón pulsa: pon rojo a los autos, deja pasar al peatón y regresa.', puntos: 45, poder: 8,
      inicializar: [['configurar LEDs (autos y peatón) como SALIDA', SET], ['configurar pulsador como ENTRADA', SET]],
      bucle: [b('rd', 'leer pulsador del peatón', 'READ', DIG), b('if', 'si <peatón presionó> hacer', 'IF', CON), b('onr', '   ROJO (autos) → HIGH', 'ONR', DIG),
        b('w1', '   esperar 1000 ms', 'WAIT', TIME), b('onp', '   VERDE (peatón) → HIGH', 'ONVP', DIG), b('w2', '   esperar 3000 ms', 'WAIT', TIME),
        b('ofp', '   VERDE (peatón) → LOW', 'OFFVP', DIG), b('ofr', '   ROJO (autos) → LOW', 'OFFR', DIG)],
      leds: ['R', 'VP'], boton: true },
    { titulo: 'LED con variable', descripcion: "Ya creamos la variable 'led'. En el bucle úsala para parpadear.", puntos: 50, poder: 9,
      inicializar: [['número entero  led = 13', VAR], ['configurar pin (led) como SALIDA', SET]],
      bucle: [b('on', 'escribir pin (led) → HIGH', 'ONVAR', DIG), b('w1', 'esperar 1000 milisegundos', 'WAIT', TIME), b('off', 'escribir pin (led) → LOW', 'OFFVAR', DIG), b('w2', 'esperar 1000 milisegundos', 'WAIT', TIME)],
      leds: ['13'] },
    { titulo: 'Semáforo inteligente', descripcion: 'En el bucle: lee el sensor en un booleano. SI hay auto, pon verde; SINO, rojo.', puntos: 60, poder: 10,
      inicializar: [['configurar VERDE y ROJO como SALIDA', SET], ['configurar sensor como ENTRADA', SET]],
      bucle: [b('var', 'booleano hayAuto = leer sensor', 'VARBOOL', VAR), b('if', 'si <hayAuto = verdadero> hacer', 'IF', CON), b('onv', '   LED VERDE → HIGH', 'ONV', DIG),
        b('els', 'si no (sino)', 'ELSE', CON), b('onr', '   LED ROJO → HIGH', 'ONR', DIG), b('w', 'esperar 1000 milisegundos', 'WAIT', TIME)],
      leds: ['V', 'R'], sensor: true },
  ];
})();

const Estacion = {
  abierta: null, orden: [], actual: 0, resueltos: 0, sim: null, arrastrando: null,
  COLORES_LED: { 13: '#ff3b3b', 12: '#ffd23b', 11: '#3bff7a', V: '#3bff7a', A: '#ffd23b', R: '#ff3b3b', VP: '#3bff7a' },
  NOMBRES_LED: { 13: 'pin 13', 12: 'pin 12', 11: 'pin 11', V: 'VERDE', A: 'AMARILLO', R: 'ROJO', VP: 'PEATÓN' },

  cerca() {
    const eq = EQUIPOS[MI_EQUIPO];
    const [ex, ez] = baseAMundo(eq, 8, -19);
    return Math.hypot(Jugador.pos.x - ex, Jugador.pos.z - ez) < 3.2;
  },

  update() {
    if (this.abierta || Tienda.abierta || Torretas.montada || Jugador.muerto) return;
    if (!this.cerca()) return;
    const sig = this.resueltos < RETOS.length ? 'Reto ' + (this.resueltos + 1) : 'todos resueltos ✅';
    G.aviso = '<kbd>E</kbd> Estación Arduino (' + sig + ') · <kbd>T</kbd> Tienda';
    if (Input.pulso('KeyE')) this.abrir();
    else if (Input.pulso('KeyT')) Tienda.abrir();
  },

  modo: 'retos', acertadas: new Set(), preg: null, pregRespondida: false,

  abrir(modo) {
    this.modo = modo || (this.resueltos >= RETOS.length ? 'preguntas' : 'retos');
    if (this.resueltos < RETOS.length) {
      this.actual = this.resueltos;
      const r = RETOS[this.actual];
      this.abierta = r;
      // barajar el bucle (que no quede ya resuelto)
      do { this.orden = [...r.bucle].sort(() => Math.random() - 0.5); } while (this.esCorrecto());
    } else this.abierta = { terminado: true };
    if (this.modo === 'preguntas' && !this.preg) this.siguientePregunta();
    G.sinPausa = true;
    if (document.exitPointerLock) document.exitPointerLock();
    this.dibujar();
    document.getElementById('estacion').classList.remove('oculto');
    Sfx.play('recoger');
  },

  cerrar() {
    this.abierta = null; clearTimeout(this.sim);
    document.getElementById('estacion').classList.add('oculto');
    G.sinPausa = false;
    const p = G.renderer.domElement.requestPointerLock(); if (p && p.catch) p.catch(() => {});
  },

  esCorrecto() { return this.orden.every((bq, i) => bq.simbolo === this.abierta.bucle[i].simbolo); },

  // pestañas: retos de bloques / preguntas
  pestanas() {
    return `<div class="tabs"><button data-m="retos" class="${this.modo === 'retos' ? 'sel' : ''}">🧩 Retos de bloques (${this.resueltos}/${RETOS.length})</button>` +
      `<button data-m="preguntas" class="${this.modo === 'preguntas' ? 'sel' : ''}">❓ Preguntas (${this.acertadas.size}/${PREGUNTAS.length})</button></div>`;
  },
  conectarPestanas() {
    document.getElementById('estCerrar').onclick = () => this.cerrar();
    for (const b of document.querySelectorAll('#estacion .tabs button')) b.onclick = () => {
      clearTimeout(this.sim); this.modo = b.dataset.m;
      if (this.modo === 'preguntas' && !this.preg) this.siguientePregunta();
      this.dibujar();
    };
  },

  // ---------- pestaña de preguntas: +20 la primera vez que aciertas cada una ----------
  siguientePregunta() {
    const actual = this.preg && this.preg.original;
    let libres = PREGUNTAS.map((_, i) => i).filter((i) => !this.acertadas.has(i) && PREGUNTAS[i] !== actual);
    if (!libres.length) libres = PREGUNTAS.map((_, i) => i).filter((i) => PREGUNTAS[i] !== actual);
    this.pregIdx = pick(libres);
    this.preg = barajarPregunta(PREGUNTAS[this.pregIdx]); this.pregRespondida = false;
  },
  dibujarPreguntas() {
    const el = document.getElementById('estacion'), q = this.preg, i = this.pregIdx;
    const yaGano = this.acertadas.has(i);
    el.innerHTML = `<div class="ventana">
      <div class="cab"><b>🤖 Estación Arduino</b><span>Preguntas de Arduino y electrónica · +20 la primera vez que aciertas cada una</span><button class="x" id="estCerrar">✕</button></div>
      ${this.pestanas()}
      <h2>${q.p}</h2>
      <div class="opciones">${q.op.map((o, k) => `<button class="opcion" data-k="${k}"><kbd>${k + 1}</kbd> ${o}</button>`).join('')}</div>
      <div class="pie"><span id="pregMsg">${yaGano ? '✅ Esta ya la acertaste antes (no da puntos otra vez).' : 'Elige una respuesta (clic o teclas 1-4).'}</span>
      <button id="pregSig">Siguiente pregunta ▶</button></div></div>`;
    this.conectarPestanas();
    for (const b of el.querySelectorAll('.opcion')) b.onclick = () => this.responderPregunta(+b.dataset.k);
    document.getElementById('pregSig').onclick = () => { this.siguientePregunta(); this.dibujar(); };
  },
  responderPregunta(k) {
    if (this.pregRespondida) return;
    this.pregRespondida = true;
    const q = this.preg, i = this.pregIdx, bien = k === q.ok;
    const ops = document.querySelectorAll('#estacion .opcion');
    ops[q.ok].classList.add('bien'); if (!bien) ops[k].classList.add('mal');
    let txt = bien ? '✅ ¡Correcto!' : '❌ Era la opción ' + (q.ok + 1) + '.';
    if (bien && !this.acertadas.has(i)) { this.acertadas.add(i); sumarPuntos(20); txt += ' <b>+20 puntos</b>.'; Sfx.play('recoger'); }
    else if (!bien) Sfx.play('sinMunicion');
    document.getElementById('pregMsg').innerHTML = txt + ' ' + q.exp;
    const tab = document.querySelector('#estacion .tabs button[data-m="preguntas"]');
    if (tab) tab.textContent = `❓ Preguntas (${this.acertadas.size}/${PREGUNTAS.length})`;
  },

  dibujar(resultado) {
    if (this.modo === 'preguntas') return this.dibujarPreguntas();
    const r = this.abierta, el = document.getElementById('estacion');
    if (r.terminado) {
      el.innerHTML = `<div class="ventana"><div class="cab"><b>🤖 Estación Arduino</b><span></span><button class="x" id="estCerrar">✕</button></div>${this.pestanas()}
        <h2>✅ ¡Completaste los ${RETOS.length} retos!</h2><p class="desc">Ya desbloqueaste los ${PODERES.length} poderes. Sigue sumando puntos con las preguntas.</p></div>`;
      this.conectarPestanas();
      return;
    }
    const leds = r.leds.map((l) => `<div class="led" data-led="${l}" style="--c:${this.COLORES_LED[l]}"><i></i><span>${this.NOMBRES_LED[l]}</span></div>`).join('');
    el.innerHTML = `
      <div class="ventana">
        <div class="cab"><b>🤖 Estación Arduino</b><span>Reto ${this.actual + 1} de ${RETOS.length} · +${r.puntos} pts · Poder ${r.poder}: ${PODERES[r.poder - 1].icono} ${PODERES[r.poder - 1].nombre}</span><button class="x" id="estCerrar">✕</button></div>
        ${this.pestanas()}
        <h2>${r.titulo}</h2><p class="desc">${r.descripcion}</p>
        <div class="cuerpo">
          <div class="codigo">
            <div class="seccion">🔧 Inicializar</div>
            ${r.inicializar.map(([t, c]) => `<div class="bloque fijo" style="--c:${c}">${t}</div>`).join('')}
            <div class="seccion">🔁 Bucle principal <small>(arrastra para ordenar)</small></div>
            <div id="bucle">${this.orden.map((bq, i) => `<div class="bloque" draggable="true" data-i="${i}" style="--c:${bq.color}"><em>⋮⋮</em>${bq.texto}</div>`).join('')}</div>
          </div>
          <div class="placa">
            <div class="arduino"><div class="leds">${leds}</div>${r.boton ? '<div class="pulsador">🔘 pulsador: <b id="estBoton">PRESIONADO</b></div>' : ''}${r.sensor ? '<div class="pulsador">📡 sensor: <b>hay auto</b></div>' : ''}</div>
            <div class="consola" id="estConsola"><div>&gt; Monitor serie</div></div>
          </div>
        </div>
        <div class="pie">
          <span id="estMsg">${resultado || 'Ordena los bloques del bucle y pulsa <b>Probar</b>.'}</span>
          <button id="estProbar">▶ Probar</button>
        </div>
      </div>`;
    this.conectarPestanas();
    document.getElementById('estProbar').onclick = () => this.probar();
    // arrastrar y soltar para ordenar
    const lista = document.getElementById('bucle');
    for (const n of lista.children) {
      n.addEventListener('dragstart', (e) => { this.arrastrando = +n.dataset.i; n.classList.add('moviendo'); e.dataTransfer.effectAllowed = 'move'; });
      n.addEventListener('dragend', () => n.classList.remove('moviendo'));
      n.addEventListener('dragover', (e) => { e.preventDefault(); n.classList.add('encima'); });
      n.addEventListener('dragleave', () => n.classList.remove('encima'));
      n.addEventListener('drop', (e) => {
        e.preventDefault();
        const a = this.arrastrando, b2 = +n.dataset.i;
        if (a === null || a === b2) return;
        const [x] = this.orden.splice(a, 1); this.orden.splice(b2, 0, x);
        this.arrastrando = null; Sfx.play('golpeRobot'); this.dibujar();
      });
    }
  },

  // ejecuta el programa en la placa virtual (2 vueltas del bucle)
  probar() {
    clearTimeout(this.sim);
    const r = this.abierta, estado = {}, consola = document.getElementById('estConsola');
    consola.innerHTML = '<div>&gt; Monitor serie</div>';
    const set = (led, on) => { const n = document.querySelector(`#estacion .led[data-led="${led}"]`); if (n) n.classList.toggle('on', on); };
    r.leds.forEach((l) => set(l, false));
    const pasos = [...this.orden, ...this.orden];
    const filas = document.querySelectorAll('#bucle .bloque');
    let i = 0, saltar = false;
    document.getElementById('estProbar').disabled = true;
    const paso = () => {
      filas.forEach((f) => f.classList.remove('corriendo'));
      if (i >= pasos.length) { this.revisar(); return; }
      if (i % this.orden.length === 0) saltar = false; // cada vuelta del bucle empieza de cero
      const bq = pasos[i], fila = filas[i % this.orden.length];
      if (fila) fila.classList.add('corriendo');
      i++;
      let espera = 260;
      const s = bq.simbolo;
      if (saltar && s !== 'ELSE') { this.sim = setTimeout(paso, 120); return; }
      if (s === 'ELSE') { saltar = !saltar ? true : false; this.sim = setTimeout(paso, 160); return; }
      const m = s.match(/^(ON|OFF)(.+)$/);
      if (m) { const led = m[2] === 'VAR' ? '13' : m[2]; set(led, m[1] === 'ON'); estado[led] = m[1] === 'ON'; }
      else if (s === 'WAIT') espera = 520;
      else if (s === 'SPRINT') consola.insertAdjacentHTML('beforeend', '<div>Encendiendo LED</div>');
      else if (s === 'READ') consola.insertAdjacentHTML('beforeend', '<div>pulsador = HIGH</div>');
      else if (s === 'VARBOOL') consola.insertAdjacentHTML('beforeend', '<div>hayAuto = verdadero</div>');
      else if (s === 'IF') saltar = false; // la condición es verdadera en la simulación
      consola.scrollTop = consola.scrollHeight;
      this.sim = setTimeout(paso, espera);
    };
    paso();
  },

  revisar() {
    const r = this.abierta;
    document.getElementById('estProbar').disabled = false;
    if (!this.esCorrecto()) {
      const bien = this.orden.filter((bq, i) => bq.simbolo === r.bucle[i].simbolo).length;
      document.getElementById('estMsg').innerHTML = `❌ Todavía no. <b>${bien} de ${r.bucle.length}</b> bloques están en su lugar. ¡Revisa el orden!`;
      Sfx.play('sinMunicion');
      return;
    }
    // ¡correcto!
    this.resueltos++;
    sumarPuntos(r.puntos);
    Poderes.desbloquear(r.poder);
    Sfx.play('oleada');
    const pie = document.querySelector('#estacion .pie');
    pie.innerHTML = `<span>✅ ¡Correcto! <b>+${r.puntos} puntos</b> y desbloqueaste <b>${PODERES[r.poder - 1].icono} ${PODERES[r.poder - 1].nombre}</b></span>` +
      (this.resueltos < RETOS.length ? '<button id="estSig">SIGUIENTE RETO ▶</button>' : '<button id="estSig">¡Terminaste! ✕</button>');
    document.getElementById('estSig').onclick = () => { if (this.resueltos < RETOS.length) this.abrir(); else this.cerrar(); };
    document.querySelectorAll('#estacion .led').forEach((n) => n.classList.add('fiesta'));
  },
};

addEventListener('keydown', (e) => {
  if (!Estacion.abierta) return;
  if (e.code === 'Escape') Estacion.cerrar();
  // en la pestaña de preguntas también se responde con 1-4
  const k = ['Digit1', 'Digit2', 'Digit3', 'Digit4'].indexOf(e.code);
  if (k >= 0 && Estacion.modo === 'preguntas') Estacion.responderPregunta(k);
});
