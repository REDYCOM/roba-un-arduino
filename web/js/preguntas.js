// =====================================================================
//  PREGUNTAS DE ARDUINO Y ELECTRÓNICA
//  - En la Estación Arduino (pestaña "❓ Preguntas"): +20 la primera vez
//    que aciertas cada una.
//  - Entre oleadas: una pregunta rápida para todos (teclas 1-4, 15 s): +25.
//  Fallar no quita nada: se muestra la respuesta correcta y por qué.
//  Para agregar o cambiar preguntas, edita esta lista:
//    p = pregunta, op = 4 opciones, ok = número de la correcta (0 a 3), exp = explicación
// =====================================================================
const PREGUNTAS = [
  // --- programación (como en los retos) ---
  { p: '¿Qué hace el bloque "esperar 1000 milisegundos"?', op: ['Pausa el programa 1 segundo', 'Pausa el programa 1000 segundos', 'Apaga el Arduino', 'Repite el bucle 1000 veces'], ok: 0, exp: '1000 milisegundos son 1 segundo.' },
  { p: '¿Cuántos milisegundos tiene 1 segundo?', op: ['10', '100', '1000', '60'], ok: 2, exp: '"Mili" significa milésima: 1 s = 1000 ms.' },
  { p: 'En un pin digital, HIGH significa…', op: ['0 voltios (apagado)', '5 voltios (encendido)', 'Leer el pin', 'Borrar el programa'], ok: 1, exp: 'HIGH = 5 V (encendido) y LOW = 0 V (apagado) en el Arduino UNO.' },
  { p: '¿Para qué sirve "configurar pin 13 como SALIDA"?', op: ['Para leer un botón', 'Para que el pin pueda encender cosas como un LED', 'Para conectarse a internet', 'Para medir la temperatura'], ok: 1, exp: 'Una SALIDA manda voltaje hacia afuera: sirve para LEDs, zumbadores, relés…' },
  { p: 'Un pulsador (botón) se configura como…', op: ['SALIDA', 'ENTRADA', 'Variable', 'Puerto serie'], ok: 1, exp: 'El Arduino LEE el botón, por eso es una ENTRADA.' },
  { p: '¿Qué parte del programa se repite una y otra vez?', op: ['Inicializar (setup)', 'Bucle principal (loop)', 'Puerto serie', 'La variable'], ok: 1, exp: 'El bucle (loop) se repite para siempre mientras el Arduino tenga energía.' },
  { p: '¿Qué parte del programa se ejecuta una sola vez, al encender?', op: ['Inicializar (setup)', 'Bucle principal (loop)', 'El bloque "esperar"', 'El bloque "si"'], ok: 0, exp: 'En "inicializar" (setup) se configura todo una vez, antes de que empiece el bucle.' },
  { p: '¿Qué hace "Puerto serie: enviar"?', op: ['Enciende un LED', 'Mueve un motor', 'Manda un mensaje a la computadora (monitor serie)', 'Borra la memoria'], ok: 2, exp: 'El monitor serie muestra en la computadora los mensajes que envía el Arduino.' },
  { p: 'En "Puerto serie: iniciar (9600)", el número 9600 es…', op: ['El número de pin', 'La velocidad de comunicación (baudios)', 'El voltaje', 'Los segundos de espera'], ok: 1, exp: '9600 baudios es la velocidad a la que el Arduino y la computadora se hablan.' },
  { p: 'El bloque "si … si no" sirve para…', op: ['Esperar un tiempo', 'Tomar decisiones según una condición', 'Repetir para siempre', 'Sumar números'], ok: 1, exp: 'Si la condición se cumple hace una cosa; si no, hace otra.' },
  { p: '¿Qué es una variable?', op: ['Un tipo de LED', 'Un cable', 'Un espacio con nombre para guardar un dato', 'Un sensor'], ok: 2, exp: 'Ejemplo: "led = 13" guarda el número 13 con el nombre led.' },
  { p: 'Una variable booleana solo puede valer…', op: ['Cualquier número', 'Verdadero o falso', 'Un texto', 'De 0 a 255'], ok: 1, exp: 'Booleano = sí/no, verdadero/falso. Como "hayAuto" en el semáforo inteligente.' },
  { p: 'Para que un LED parpadee, después de apagarlo hay que…', op: ['Esperar un tiempo', 'Volver a configurar el pin', 'Reiniciar el Arduino', 'Nada más'], ok: 0, exp: 'Sin el último "esperar", el LED se volvería a encender al instante.' },
  { p: 'Si quitas los "esperar" del programa Blink, el LED…', op: ['Explota', 'Parpadea tan rápido que parece siempre encendido', 'No compila', 'Se apaga para siempre'], ok: 1, exp: 'Cambia miles de veces por segundo: el ojo humano no alcanza a verlo.' },
  { p: 'En un semáforo, ¿cuál es el orden correcto?', op: ['Rojo → Verde → Amarillo', 'Verde → Amarillo → Rojo', 'Amarillo → Rojo → Verde', 'Verde → Rojo → Amarillo'], ok: 1, exp: 'El amarillo avisa que el verde termina antes de pasar a rojo.' },
  { p: 'En el semáforo peatonal, cuando el peatón pulsa, primero hay que…', op: ['Poner verde al peatón aunque pasen autos', 'Poner rojo a los autos', 'Apagar todos los LEDs', 'Esperar 10 minutos'], ok: 1, exp: 'Primero se detienen los autos y después pasa el peatón, ¡por seguridad!' },
  { p: 'Un pin digital puede tener…', op: ['Dos estados: HIGH o LOW', 'Cualquier valor de 0 a 1023', 'Un texto', 'Muchos colores'], ok: 0, exp: 'Digital = solo dos estados. Para valores intermedios se usan los pines analógicos.' },
  { p: 'En el Arduino UNO, "leer pin analógico" devuelve valores entre…', op: ['0 y 1', '0 y 255', '0 y 1023', '-100 y 100'], ok: 2, exp: 'El convertidor del UNO es de 10 bits: 2^10 = 1024 valores (0 a 1023).' },
  { p: '¿En qué lenguaje se programa el Arduino por debajo de los bloques?', op: ['Python', 'C/C++', 'HTML', 'Scratch'], ok: 1, exp: 'ArduinoBlocks convierte tus bloques en código C/C++ para el Arduino.' },
  // --- placa y electrónica ---
  { p: '¿Cuántos pines digitales tiene el Arduino UNO?', op: ['6', '14 (del 0 al 13)', '20', '100'], ok: 1, exp: 'Tiene 14 digitales (0-13) y además 6 analógicos (A0-A5).' },
  { p: '¿Qué tiene de especial el pin 13 del Arduino UNO?', op: ['Tiene un LED integrado en la placa', 'Tiene un parlante', 'Tiene wifi', 'No se puede usar'], ok: 0, exp: 'Por eso el primer reto (Blink) usa el pin 13: el LED ya viene en la placa.' },
  { p: 'Un LED tiene dos patas. La más larga es…', op: ['El cátodo (−)', 'El ánodo (+)', 'La tierra', 'Da igual'], ok: 1, exp: 'Pata larga = ánodo (+). Si lo conectas al revés, no enciende.' },
  { p: '¿Para qué se pone una resistencia junto al LED?', op: ['Para que brille más', 'Para limitar la corriente y que no se queme', 'Para cambiarle el color', 'Para guardar energía'], ok: 1, exp: 'Sin resistencia pasa demasiada corriente y el LED (o el pin) se daña.' },
  { p: '¿Qué significa GND?', op: ['Gran voltaje', 'Tierra (0 V, el negativo)', 'Señal digital', 'Generador'], ok: 1, exp: 'GND (ground) es la referencia de 0 V. Todos los circuitos la comparten.' },
  // --- robot seguidor de línea ---
  { p: '¿Cuál es el "cerebro" del robot seguidor de línea?', op: ['El L298N', 'La batería', 'El Arduino', 'La llanta'], ok: 2, exp: 'El Arduino lee los sensores y decide cómo mover los motores.' },
  { p: '¿Qué hace el puente H L298N?', op: ['Mide distancias', 'Controla la velocidad y el sentido de giro de los motores', 'Guarda energía', 'Es una rueda'], ok: 1, exp: 'El Arduino no tiene fuerza para mover motores: el L298N hace de "músculo".' },
  { p: 'El sensor ultrasónico HC-SR04 mide…', op: ['La temperatura', 'La distancia usando sonido', 'El color', 'La luz'], ok: 1, exp: 'Lanza un sonido muy agudo y mide cuánto tarda el eco, como un murciélago.' },
  { p: 'El sensor TCRT5000 de un seguidor de línea detecta…', op: ['Sonidos', 'Si debajo hay línea negra o suelo blanco', 'La temperatura', 'Distancias de varios metros'], ok: 1, exp: 'Usa luz infrarroja: el blanco la refleja y el negro la absorbe.' },
  { p: '¿Qué voltaje da aproximadamente una batería 18650?', op: ['1,5 V', '3,7 V', '12 V', '220 V'], ok: 1, exp: 'Es una batería de litio de unos 3,7 V. Con dos en serie tienes unos 7,4 V.' },
  { p: '¿Qué hace un motor DC?', op: ['Convierte electricidad en movimiento giratorio', 'Guarda electricidad', 'Mide la velocidad', 'Enciende LEDs'], ok: 0, exp: 'Al pasarle corriente gira. Si inviertes la corriente, gira al revés.' },
  { p: 'Para que el robot avance en línea recta, los dos motores deben…', op: ['Girar en sentidos contrarios', 'Girar a la misma velocidad hacia adelante', 'Estar apagados', 'Girar solo el izquierdo'], ok: 1, exp: 'Si un motor va más rápido que el otro, el robot se desvía.' },
  { p: 'Para que el robot gire a la derecha, normalmente…', op: ['El motor izquierdo avanza y el derecho frena o va más lento', 'Los dos motores van iguales', 'Se apaga el Arduino', 'El motor derecho va más rápido'], ok: 0, exp: 'La rueda que va más rápido "empuja" al robot hacia el lado contrario.' },
];

// Mezcla las opciones (la correcta no siempre queda en el mismo lugar)
function barajarPregunta(q) {
  const orden = [0, 1, 2, 3].sort(() => Math.random() - 0.5);
  return { p: q.p, op: orden.map((k) => q.op[k]), ok: orden.indexOf(q.ok), exp: q.exp, original: q };
}

// ---------------------------------------------------------------------
//  Pregunta rápida entre oleadas (no pausa el juego: se responde con 1-4)
// ---------------------------------------------------------------------
const Quiz = {
  activa: null, t: 0, DURACION: 15, PREMIO: 25, usadas: new Set(), respondida: false,

  elegir() {
    let libres = PREGUNTAS.map((_, i) => i).filter((i) => !this.usadas.has(i));
    if (!libres.length) { this.usadas.clear(); libres = PREGUNTAS.map((_, i) => i); }
    const i = pick(libres); this.usadas.add(i);
    return barajarPregunta(PREGUNTAS[i]);
  },

  lanzar() {
    this.activa = this.elegir(); this.t = this.DURACION; this.respondida = false;
    const el = document.getElementById('quiz');
    el.innerHTML = `<div class="tit">❓ Pregunta rápida <span>responde con las teclas <kbd>1</kbd>-<kbd>4</kbd> · +${this.PREMIO} puntos</span></div>
      <div class="preg">${this.activa.p}</div>
      <div class="ops">${this.activa.op.map((o, k) => `<div class="op" data-k="${k}"><kbd>${k + 1}</kbd>${o}</div>`).join('')}</div>
      <div class="exp" id="quizExp"></div><div class="barra fina"><div id="quizT"></div></div>`;
    for (const n of el.querySelectorAll('.op')) n.onclick = () => this.responder(+n.dataset.k);
    el.classList.remove('oculto', 'sale');
    Sfx.play('oleada');
  },

  responder(k) {
    if (!this.activa || this.respondida) return;
    this.respondida = true;
    const q = this.activa, bien = k === q.ok;
    const ops = document.querySelectorAll('#quiz .op');
    ops[q.ok].classList.add('bien');
    if (!bien && k >= 0) ops[k].classList.add('mal');
    document.getElementById('quizExp').innerHTML = (bien ? `✅ ¡Correcto! <b>+${this.PREMIO}</b> · ` : k < 0 ? '⏱ Se acabó el tiempo · ' : '❌ Era la opción ' + (q.ok + 1) + ' · ') + q.exp;
    if (bien) { sumarPuntos(this.PREMIO); this.aciertos = (this.aciertos || 0) + 1; Sfx.play('recoger'); } else Sfx.play('sinMunicion');
    this.t = Math.min(this.t, 0) + 5; // deja ver la explicación 5 s
  },

  cerrar() { this.activa = null; document.getElementById('quiz').classList.add('sale'); },

  update(dt) {
    if (!this.activa) return;
    this.t -= dt;
    if (!this.respondida) {
      document.getElementById('quizT').style.width = Math.max(0, (this.t / this.DURACION) * 100) + '%';
      for (let k = 0; k < 4; k++) if (Input.pulso('Digit' + (k + 1))) this.responder(k);
      if (this.t <= 0) this.responder(-1);
    } else if (this.t <= 0) this.cerrar();
  },
};
