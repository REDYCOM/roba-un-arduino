// =====================================================================
//  SONIDO: efectos sintetizados con WebAudio (no necesita archivos)
// =====================================================================
const Sfx = {
  ctx: null, master: null, ruidoBuf: null, lluviaNodo: null, lluviaGain: null,
  init() {
    if (this.ctx) { if (this.ctx.state === 'suspended') this.ctx.resume(); return; }
    const C = window.AudioContext || window.webkitAudioContext;
    if (!C) return;
    this.ctx = new C();
    this.master = this.ctx.createGain(); this.master.gain.value = 0.55;
    const comp = this.ctx.createDynamicsCompressor();
    this.master.connect(comp); comp.connect(this.ctx.destination);
    const len = this.ctx.sampleRate * 2;
    this.ruidoBuf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const d = this.ruidoBuf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    // lluvia continua (volumen controlado por el clima)
    const src = this.ctx.createBufferSource(); src.buffer = this.ruidoBuf; src.loop = true;
    const f = this.ctx.createBiquadFilter(); f.type = 'bandpass'; f.frequency.value = 2500; f.Q.value = 0.4;
    this.lluviaGain = this.ctx.createGain(); this.lluviaGain.gain.value = 0;
    src.connect(f); f.connect(this.lluviaGain); this.lluviaGain.connect(this.master); src.start();
  },
  tono(freq, dur, tipo = 'square', vol = 0.2, hasta = null, retraso = 0) {
    const c = this.ctx; if (!c) return;
    const t = c.currentTime + retraso;
    const o = c.createOscillator(), g = c.createGain();
    o.type = tipo; o.frequency.setValueAtTime(freq, t);
    if (hasta) o.frequency.exponentialRampToValueAtTime(Math.max(hasta, 1), t + dur);
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g); g.connect(this.master); o.start(t); o.stop(t + dur + 0.05);
  },
  ruido(dur, vol = 0.3, freq = 1200, tipoF = 'lowpass', hasta = null, retraso = 0, q = 0.8) {
    const c = this.ctx; if (!c) return;
    const t = c.currentTime + retraso;
    const s = c.createBufferSource(); s.buffer = this.ruidoBuf;
    const f = c.createBiquadFilter(); f.type = tipoF; f.frequency.setValueAtTime(freq, t); f.Q.value = q;
    if (hasta) f.frequency.exponentialRampToValueAtTime(hasta, t + dur);
    const g = c.createGain(); g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    s.connect(f); f.connect(g); g.connect(this.master);
    s.start(t, Math.random() * 1.5); s.stop(t + dur + 0.05);
  },
  // vol se reduce con la distancia
  play(nombre, dist = 0) {
    if (!this.ctx) return;
    const v = 1 / (1 + dist * 0.045);
    if (v < 0.04) return;
    switch (nombre) {
      case 'blaster': this.tono(880, 0.12, 'square', 0.09 * v, 220); this.ruido(0.06, 0.12 * v, 4000, 'highpass'); break;
      case 'escopeta': this.ruido(0.35, 0.5 * v, 2500, 'lowpass', 300); this.tono(140, 0.2, 'sawtooth', 0.15 * v, 50); break;
      case 'bomba': this.ruido(0.06, 0.2 * v, 3000, 'bandpass'); this.ruido(0.06, 0.2 * v, 2000, 'bandpass', null, 0.12); break;
      case 'laser': this.tono(1800, 0.35, 'sawtooth', 0.1 * v, 120); this.tono(900, 0.35, 'sine', 0.15 * v, 60); break;
      case 'bazuca': this.ruido(0.6, 0.45 * v, 900, 'lowpass', 120); this.tono(90, 0.4, 'sine', 0.3 * v, 40); break;
      case 'tesla': for (let i = 0; i < 4; i++) this.ruido(0.07, 0.25 * v, rand(2000, 6000), 'bandpass', null, i * 0.05, 4); this.tono(120, 0.3, 'sawtooth', 0.12 * v, 60); break;
      case 'granada': this.tono(400, 0.15, 'triangle', 0.15 * v, 200); break;
      case 'explosion': this.ruido(1.2, 0.8 * v, 1200, 'lowpass', 60); this.tono(70, 0.9, 'sine', 0.6 * v, 25); break;
      case 'explosionChica': this.ruido(0.5, 0.4 * v, 1500, 'lowpass', 100); this.tono(110, 0.4, 'sine', 0.3 * v, 40); break;
      case 'impacto': this.ruido(0.05, 0.12 * v, 3000, 'bandpass', null, 0, 2); break;
      case 'golpeRobot': this.tono(rand(300, 380), 0.06, 'square', 0.06 * v, 150); break;
      case 'muereRobot': this.ruido(0.5, 0.35 * v, 2000, 'lowpass', 100); this.tono(500, 0.5, 'sawtooth', 0.12 * v, 40); break;
      case 'dano': this.tono(180, 0.25, 'sawtooth', 0.22, 70); this.ruido(0.15, 0.2, 800); break;
      case 'recoger': [523, 659, 784, 1047].forEach((f, i) => this.tono(f, 0.15, 'triangle', 0.15, null, i * 0.07)); break;
      case 'oleada': [392, 392, 523].forEach((f, i) => this.tono(f, i === 2 ? 0.5 : 0.15, 'square', 0.1, null, i * 0.18)); break;
      case 'jefe': for (let i = 0; i < 3; i++) this.tono(70, 0.8, 'sawtooth', 0.25, 45, i * 0.6); break;
      case 'trueno': this.ruido(2.5, 0.9 * v, 600, 'lowpass', 40); this.ruido(0.3, 0.5 * v, 3000, 'lowpass', 300); break;
      case 'pisoton': this.tono(50, 0.7, 'sine', 0.6 * v, 25); this.ruido(0.6, 0.5 * v, 400, 'lowpass', 50); break;
      case 'orbe': this.tono(600, 0.4, 'sine', 0.12 * v, 200); break;
      case 'disparoDron': this.tono(1200, 0.15, 'square', 0.07 * v, 600); break;
      case 'aparece': this.tono(200, 0.6, 'sine', 0.15 * v, 900); this.ruido(0.5, 0.1 * v, 5000, 'highpass'); break;
      case 'salto': this.tono(300, 0.1, 'sine', 0.06, 500); break;
      case 'trampolin': this.tono(200, 0.4, 'sine', 0.2, 900); break;
      case 'paso': this.ruido(0.05, 0.04, 600, 'lowpass'); break;
      case 'pasoGigante': this.tono(45, 0.4, 'sine', 0.5 * v, 30); this.ruido(0.3, 0.3 * v, 300, 'lowpass'); break;
      case 'metralla': this.ruido(0.07, 0.22 * v, 2600, 'lowpass', 500); this.tono(160, 0.06, 'square', 0.07 * v, 70); break;
      case 'sinMunicion': this.tono(200, 0.05, 'square', 0.05); break;
    }
  },
  lluvia(cant) { if (this.lluviaGain) this.lluviaGain.gain.value = cant * 0.12; },
};
