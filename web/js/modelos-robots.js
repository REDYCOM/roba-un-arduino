// =====================================================================
//  MODELOS DE ROBOTS — traducción de src/servidor/RobotsModelos.luau
//  Mismas piezas, tamaños (studs), colores, materiales y articulaciones
//  que en Roblox. El frente mira hacia -Z.
// =====================================================================
const RB = (() => {
  const V = (x, y, z) => [x, y, z];
  const RGB = (r, g, b) => [r, g, b];
  const MET = 'Metal', PLA = 'SmoothPlastic', NEO = 'Neon', OXI = 'CorrodedMetal', TEL = 'Fabric', VID = 'Glass';
  const BOLA = 'Ball', CIL = 'Cylinder';
  const C = {
    teal: RGB(0, 129, 132), oscuro: RGB(42, 45, 54), negro: RGB(22, 22, 26),
    plata: RGB(190, 192, 198), rojo: RGB(130, 28, 28), blanco: RGB(240, 240, 232),
    neonRojo: RGB(255, 45, 45), neonNaranja: RGB(255, 130, 20), neonAmarillo: RGB(255, 230, 70),
    neonVerde: RGB(80, 255, 90), neonAzul: RGB(70, 160, 255),
    gris: RGB(112, 110, 106), oxido: RGB(150, 72, 38), oxidoOsc: RGB(95, 45, 25),
    negro2: RGB(28, 28, 34), grisOsc: RGB(55, 58, 66),
    verde: RGB(110, 135, 85), verdeOsc: RGB(82, 102, 62),
    azulPLA: RGB(30, 90, 220), blancoPLA: RGB(235, 228, 210), azulAlu: RGB(40, 115, 205),
    cristal: RGB(210, 225, 235), cableNaranja: RGB(230, 120, 30), azulPlaca: RGB(30, 90, 180),
    amarillo: RGB(240, 220, 40),
  };
  const P = (nombre, size, color, mat, pos, op = {}) => ({ nombre, size, color, mat, pos, forma: op.forma, seg: op.seg, rot: op.rot, transp: op.transp });
  const GIRO_Z = V(0, 90, 0);
  const LADOS = [[-1, 'Izq'], [1, 'Der']];

  // ================== SEGUIDOR (pequeño, ruedas) ==================
  function specSeguidor() {
    const p = [
      P('Chasis', V(2.8, 0.5, 3.4), C.oscuro, MET, V(0, 1.3, 0)),
      P('Placa', V(2.3, 0.15, 2.7), C.teal, PLA, V(0, 1.62, 0.1)),
      P('Chip', V(1, 0.2, 0.5), C.negro, PLA, V(0, 1.78, 0.4)),
      P('Puerto', V(0.6, 0.35, 0.5), C.plata, MET, V(-0.7, 1.8, 1.15)),
      P('RuedaLoca', V(0.6, 0.6, 0.6), C.plata, MET, V(0, 0.3, -1.3), { forma: BOLA }),
      P('Sensor', V(2.2, 0.25, 0.4), C.negro, PLA, V(0, 0.6, -1.8)),
      P('Antena', V(0.1, 1.2, 0.1), C.oscuro, MET, V(0.9, 2.3, 1.2)),
      P('Punta', V(0.3, 0.3, 0.3), C.neonRojo, NEO, V(0.9, 2.95, 1.2), { forma: BOLA }),
      P('SoporteSonar', V(0.3, 0.5, 0.3), C.oscuro, MET, V(0, 1.75, -1.4)),
      P('PlacaSonar', V(1.7, 0.75, 0.12), C.azulPlaca, PLA, V(0, 2.25, -1.45)),
    ];
    for (const [sx, n] of LADOS) {
      p.push(P('Rueda' + n, V(0.5, 1.8, 1.8), C.negro, PLA, V(sx * 1.6, 0.9, 0.5), { forma: CIL }));
      p.push(P('Sonar' + n, V(0.35, 0.62, 0.62), C.plata, MET, V(sx * 0.45, 2.25, -1.62), { forma: CIL, rot: GIRO_Z }));
      p.push(P('Ojo' + n, V(0.06, 0.42, 0.42), C.neonRojo, NEO, V(sx * 0.45, 2.25, -1.81), { forma: CIL, rot: GIRO_Z }));
      p.push(P('Ceja' + n, V(0.6, 0.12, 0.2), C.negro, PLA, V(sx * 0.45, 2.72, -1.55), { rot: V(0, 0, -sx * 25) }));
    }
    return { escala: 1, rootY: 1.6, anim: 'ruedas', ojos: ['OjoIzq', 'OjoDer', 'Punta'], cabeza: ['PlacaSonar', 'OjoIzq', 'OjoDer', 'SonarIzq', 'SonarDer'], partes: p };
  }

  // ================== TANQUE estilo "Ranger" (orugas + aluminio azul) ==================
  function specTanque() {
    const p = [
      P('Marco', V(2.4, 0.9, 3.0), C.azulAlu, MET, V(0, 1.4, 0)),
      P('Caja', V(1.9, 0.9, 2.0), C.cristal, VID, V(0, 2.3, 0.4), { transp: 0.45 }),
      P('PlacaInt', V(1.6, 0.1, 1.7), C.teal, PLA, V(0, 1.95, 0.4)),
      P('ChipInt', V(0.6, 0.15, 0.6), C.negro, PLA, V(0.2, 2.05, 0.5)),
      P('Soporte', V(0.3, 0.6, 0.3), C.azulAlu, MET, V(0, 1.95, -1.35)),
      P('SonarPlaca', V(1.6, 0.75, 0.12), C.negro, PLA, V(0, 2.4, -1.45)),
    ];
    for (let k = 0; k <= 3; k++) p.push(P('Puerto' + k, V(0.12, 0.28, 0.28), C.blanco, PLA, V(0.97, 2.15, -0.2 + k * 0.35)));
    for (const [sx, n] of LADOS) {
      p.push(P('Oruga' + n, V(0.9, 1.3, 4.6), C.negro, PLA, V(sx * 1.65, 0.65, 0)));
      p.push(P('RuedaF' + n, V(1.0, 1.3, 1.3), C.oscuro, MET, V(sx * 1.65, 0.65, -2.05), { forma: CIL }));
      p.push(P('RuedaT' + n, V(1.0, 1.3, 1.3), C.oscuro, MET, V(sx * 1.65, 0.65, 2.05), { forma: CIL }));
      p.push(P('Barra' + n, V(0.2, 0.35, 3.4), C.azulAlu, MET, V(sx * 1.22, 1.95, 0)));
      p.push(P('Sonar' + n, V(0.3, 0.55, 0.55), C.plata, MET, V(sx * 0.42, 2.4, -1.62), { forma: CIL, rot: GIRO_Z }));
      p.push(P('Ojo' + n, V(0.05, 0.38, 0.38), C.neonRojo, NEO, V(sx * 0.42, 2.4, -1.79), { forma: CIL, rot: GIRO_Z }));
    }
    return { escala: 1.8, rootY: 1.7, anim: 'ruedas', ojos: ['OjoIzq', 'OjoDer'], cabeza: ['SonarPlaca', 'OjoIzq', 'OjoDer', 'SonarIzq', 'SonarDer'], partes: p };
  }

  // ================== ARAÑA de 4 patas con servos ==================
  function specArana() {
    const p = [
      P('Cuerpo', V(1.8, 0.5, 1.8), C.blancoPLA, PLA, V(0, 1.6, 0)),
      P('Base2', V(1.4, 0.3, 1.4), C.blancoPLA, PLA, V(0, 1.25, 0)),
      P('Nano', V(0.5, 0.12, 1.1), C.azulPlaca, PLA, V(0, 1.92, 0.1)),
      P('USB', V(0.3, 0.15, 0.25), C.plata, MET, V(0, 1.98, 0.65)),
      P('Brida', V(1.3, 0.07, 0.07), C.amarillo, PLA, V(0, 2.0, 0), { rot: V(0, 45, 0) }),
      P('OjoIzq', V(0.3, 0.3, 0.3), C.neonRojo, NEO, V(-0.3, 1.7, -0.92), { forma: BOLA }),
      P('OjoDer', V(0.3, 0.3, 0.3), C.neonRojo, NEO, V(0.3, 1.7, -0.92), { forma: BOLA }),
    ];
    const segmentos = [];
    [45, 135, 225, 315].forEach((ang, k) => {
      const i = k + 1, a = (ang * Math.PI) / 180, dx = Math.cos(a), dz = Math.sin(a);
      const seg = 'Pata' + i, giro = V(0, (Math.atan2(-dz, dx) * 180) / Math.PI, 0);
      segmentos.push({ nombre: seg, padre: 'root', pos: V(dx * 0.85, 1.6, dz * 0.85), dir: [dx, dz] });
      p.push(P('Servo' + i, V(0.55, 0.5, 0.55), C.azulPLA, PLA, V(dx * 0.85, 1.6, dz * 0.85), { seg, rot: giro }));
      p.push(P('Femur' + i, V(1.3, 0.28, 0.4), C.blancoPLA, PLA, V(dx * 1.55, 1.85, dz * 1.55), { seg, rot: giro }));
      p.push(P('Rodilla' + i, V(0.5, 0.55, 0.5), C.azulPLA, PLA, V(dx * 2.2, 1.85, dz * 2.2), { seg, rot: giro }));
      p.push(P('Tibia' + i, V(0.28, 1.8, 0.28), C.blancoPLA, PLA, V(dx * 2.35, 0.95, dz * 2.35), { seg, rot: giro }));
      p.push(P('Cable' + i, V(1.2, 0.06, 0.06), C.cableNaranja, PLA, V(dx * 1.5, 2.02, dz * 1.5), { seg, rot: giro }));
    });
    return { escala: 1.3, rootY: 1.6, anim: 'arana', pasoFreq: 9, segmentos, ojos: ['OjoIzq', 'OjoDer'], cabeza: ['OjoIzq', 'OjoDer', 'Nano'], partes: p };
  }

  // ================== SOLDADO humanoide de servos (azul y negro) ==================
  function specSoldado() {
    const p = [
      P('Pelvis', V(2.0, 0.8, 1.3), C.azulPLA, PLA, V(0, 3.6, 0)),
      P('PechoInf', V(2.0, 0.8, 1.4), C.azulPLA, PLA, V(0, 4.2, 0), { seg: 'Torso' }),
      P('Pecho', V(2.6, 1.9, 1.6), C.azulPLA, PLA, V(0, 5.45, 0), { seg: 'Torso' }),
      P('LedL', V(0.45, 0.45, 0.1), C.neonRojo, NEO, V(0, 5.6, -0.83), { seg: 'Torso' }),
      P('Placa', V(1.2, 0.8, 0.08), C.teal, PLA, V(0, 5.0, 0.83), { seg: 'Torso' }),
      P('Cubo', V(1.3, 1.2, 1.2), C.negro, PLA, V(0, 6.95, 0), { seg: 'Cabeza' }),
      P('VisorIzq', V(0.6, 0.22, 0.1), C.neonRojo, NEO, V(-0.28, 7.05, -0.62), { seg: 'Cabeza', rot: V(0, 0, -15) }),
      P('VisorDer', V(0.6, 0.22, 0.1), C.neonRojo, NEO, V(0.28, 7.05, -0.62), { seg: 'Cabeza', rot: V(0, 0, 15) }),
    ];
    for (const [sx, n] of LADOS) {
      const pierna = 'Pierna' + n, brazo = 'Brazo' + n;
      p.push(P('ServoCadera' + n, V(0.8, 0.6, 0.9), C.negro, PLA, V(sx * 0.55, 3.2, 0), { seg: pierna }));
      p.push(P('Muslo' + n, V(0.8, 1.2, 0.9), C.azulPLA, PLA, V(sx * 0.55, 2.45, 0), { seg: pierna }));
      p.push(P('ServoRodilla' + n, V(0.85, 0.55, 0.9), C.negro, PLA, V(sx * 0.55, 1.65, 0), { seg: pierna }));
      p.push(P('Canilla' + n, V(0.8, 1.0, 0.9), C.azulPLA, PLA, V(sx * 0.55, 0.95, 0), { seg: pierna }));
      p.push(P('Pie' + n, V(1.0, 0.35, 1.5), C.negro, PLA, V(sx * 0.55, 0.2, -0.15), { seg: pierna }));
      p.push(P('CableP' + n, V(0.06, 1.8, 0.06), C.cableNaranja, PLA, V(sx * 0.98, 2.4, 0.3), { seg: pierna }));
      p.push(P('ServoHombro' + n, V(0.7, 0.9, 0.9), C.negro, PLA, V(sx * 1.6, 6.0, 0), { seg: brazo }));
      p.push(P('Brazo' + n, V(0.5, 1.4, 0.8), C.azulPLA, PLA, V(sx * 1.75, 5.0, 0), { seg: brazo }));
      p.push(P('ServoCodo' + n, V(0.6, 0.6, 0.8), C.negro, PLA, V(sx * 1.75, 4.1, 0), { seg: brazo }));
      p.push(P('Pinza' + n, V(0.5, 1.0, 0.7), C.negro, PLA, V(sx * 1.75, 3.35, -0.1), { seg: brazo }));
      p.push(P('GarraA' + n, V(0.15, 0.6, 0.15), C.negro, PLA, V(sx * 1.75, 2.65, -0.35), { seg: brazo, rot: V(15, 0, 0) }));
      p.push(P('GarraB' + n, V(0.15, 0.6, 0.15), C.negro, PLA, V(sx * 1.75, 2.65, 0.15), { seg: brazo, rot: V(-10, 0, 0) }));
    }
    return {
      escala: 1.1, rootY: 3.6, pasoFreq: 7,
      segmentos: [
        { nombre: 'Torso', padre: 'root', pos: V(0, 3.9, 0) }, { nombre: 'Cabeza', padre: 'Torso', pos: V(0, 6.4, 0) },
        { nombre: 'BrazoIzq', padre: 'Torso', pos: V(-1.6, 6.0, 0) }, { nombre: 'BrazoDer', padre: 'Torso', pos: V(1.6, 6.0, 0) },
        { nombre: 'PiernaIzq', padre: 'root', pos: V(-0.55, 3.35, 0) }, { nombre: 'PiernaDer', padre: 'root', pos: V(0.55, 3.35, 0) },
      ],
      ojos: ['VisorIzq', 'VisorDer', 'LedL'], partes: p,
    };
  }

  // ================== CHATARRA (zombi oxidado) ==================
  function specChatarra() {
    const p = [
      P('Pelvis', V(2.4, 1.1, 1.6), C.gris, OXI, V(0, 4.2, 0)),
      P('Pecho', V(2.6, 2.6, 1.8), C.gris, OXI, V(0, 6.0, -0.35), { seg: 'Torso', rot: V(-14, 0, 0) }),
      P('Parche1', V(1.0, 0.8, 0.1), C.oxido, OXI, V(-0.6, 6.4, -1.32), { seg: 'Torso', rot: V(-14, 0, 10) }),
      P('Parche2', V(0.7, 1.1, 0.1), C.oxidoOsc, OXI, V(0.7, 5.6, -1.2), { seg: 'Torso', rot: V(-14, 0, -8) }),
      P('Nucleo', V(0.6, 0.6, 0.6), C.neonNaranja, NEO, V(0.1, 6.1, -1.28), { seg: 'Torso', forma: BOLA }),
      P('Cuello', V(0.6, 0.6, 0.6), C.oscuro, MET, V(0, 7.3, -0.85), { seg: 'Torso' }),
      P('Craneo', V(2.2, 1.9, 2.0), C.gris, OXI, V(0, 8.25, -1.25), { seg: 'Cabeza' }),
      P('ParcheC', V(0.9, 0.6, 0.12), C.oxido, OXI, V(0.5, 8.9, -2.27), { seg: 'Cabeza' }),
      P('Cuenca', V(1.0, 1.0, 1.0), C.negro, PLA, V(-0.5, 8.45, -2.2), { seg: 'Cabeza', forma: BOLA }),
      P('OjoIzq', V(0.7, 0.7, 0.7), C.neonNaranja, NEO, V(-0.5, 8.45, -2.45), { seg: 'Cabeza', forma: BOLA }),
      P('OjoDer', V(0.4, 0.4, 0.4), C.neonRojo, NEO, V(0.55, 8.55, -2.28), { seg: 'Cabeza', forma: BOLA }),
      P('CejaDer', V(0.75, 0.15, 0.2), C.negro, PLA, V(0.55, 8.88, -2.3), { seg: 'Cabeza', rot: V(0, 0, 22) }),
      P('Rejilla', V(1.3, 0.55, 0.15), C.negro, PLA, V(0, 7.75, -2.25), { seg: 'Cabeza' }),
      P('Antena', V(0.08, 1.2, 0.08), C.oscuro, MET, V(0.8, 9.7, -1.0), { seg: 'Cabeza', rot: V(0, 0, -15) }),
      P('Punta', V(0.25, 0.25, 0.25), C.neonRojo, NEO, V(0.95, 10.3, -1.0), { seg: 'Cabeza', forma: BOLA }),
    ];
    [-0.45, -0.15, 0.15, 0.45].forEach((x, i) => p.push(P('Barra' + (i + 1), V(0.08, 0.5, 0.17), C.gris, OXI, V(x, 7.75, -2.32), { seg: 'Cabeza' })));
    for (const [sx, n] of LADOS) {
      const pierna = 'Pierna' + n, brazo = 'Brazo' + n;
      p.push(P('Muslo' + n, V(0.7, 1.8, 0.7), C.gris, OXI, V(sx * 0.75, 2.85, 0), { seg: pierna }));
      p.push(P('Rodilla' + n, V(0.95, 0.95, 0.95), C.oxido, OXI, V(sx * 0.75, 1.95, 0), { seg: pierna, forma: BOLA }));
      p.push(P('Canilla' + n, V(0.85, 1.6, 0.85), C.gris, OXI, V(sx * 0.75, 1.05, 0), { seg: pierna }));
      p.push(P('Pie' + n, V(1.3, 0.5, 1.9), C.oxidoOsc, OXI, V(sx * 0.75, 0.25, -0.35), { seg: pierna }));
      p.push(P('Hombro' + n, V(1.1, 1.1, 1.1), C.oxido, OXI, V(sx * 1.7, 6.8, -0.4), { seg: brazo, forma: BOLA }));
      p.push(P('BrazoSup' + n, V(0.55, 1.8, 0.55), C.gris, OXI, V(sx * 1.85, 5.8, -0.5), { seg: brazo }));
      p.push(P('Codo' + n, V(0.75, 0.75, 0.75), C.oxidoOsc, OXI, V(sx * 1.9, 4.9, -0.55), { seg: brazo, forma: BOLA }));
      p.push(P('Antebrazo' + n, V(0.95, 1.9, 0.95), C.gris, OXI, V(sx * 1.95, 3.95, -0.6), { seg: brazo }));
      [-0.3, 0, 0.3].forEach((dz, k) => {
        const j = k + 1;
        p.push(P('Garra' + n + j, V(0.18, 1.0, 0.18), C.oscuro, MET, V(sx * 1.95, 2.6, -0.6 + dz), { seg: brazo, rot: V(18, 0, sx * (j - 2) * 12) }));
      });
    }
    return {
      escala: 1.45, rootY: 4.2, pasoFreq: 6,
      segmentos: [
        { nombre: 'Torso', padre: 'root', pos: V(0, 4.6, 0) }, { nombre: 'Cabeza', padre: 'Torso', pos: V(0, 7.3, -0.9) },
        { nombre: 'BrazoIzq', padre: 'Torso', pos: V(-1.7, 6.8, -0.4) }, { nombre: 'BrazoDer', padre: 'Torso', pos: V(1.7, 6.8, -0.4) },
        { nombre: 'PiernaIzq', padre: 'root', pos: V(-0.75, 3.8, 0) }, { nombre: 'PiernaDer', padre: 'root', pos: V(0.75, 3.8, 0) },
      ],
      ojos: ['OjoIzq', 'OjoDer', 'Punta', 'Nucleo'], partes: p,
    };
  }

  // ================== COLOSO (gigante negro y naranja) ==================
  function specColoso() {
    const p = [
      P('Pelvis', V(3.6, 1.3, 2.4), C.grisOsc, MET, V(0, 6.5, 0)),
      P('Cinturon', V(4.4, 0.7, 2.9), C.grisOsc, MET, V(0, 7.5, 0), { seg: 'Torso' }),
      P('Pecho', V(5.0, 4.0, 3.4), C.negro2, MET, V(0, 9.7, 0), { seg: 'Torso' }),
      P('LineaIzq', V(0.18, 3.4, 0.1), C.neonNaranja, NEO, V(-1.3, 9.7, -1.72), { seg: 'Torso' }),
      P('LineaDer', V(0.18, 3.4, 0.1), C.neonNaranja, NEO, V(1.3, 9.7, -1.72), { seg: 'Torso' }),
      P('LineaArriba', V(2.8, 0.18, 0.1), C.neonNaranja, NEO, V(0, 11.3, -1.72), { seg: 'Torso' }),
      P('Nucleo', V(1.0, 1.0, 1.0), C.neonNaranja, NEO, V(0, 8.6, -1.7), { seg: 'Torso', forma: BOLA }),
      P('Cuello', V(1.6, 0.8, 1.6), C.grisOsc, MET, V(0, 12.0, -0.1), { seg: 'Cabeza' }),
      P('Craneo', V(4.2, 3.2, 3.6), C.negro2, MET, V(0, 13.8, -0.2), { seg: 'Cabeza' }),
      P('CascoLinea', V(4.3, 0.2, 3.7), C.neonNaranja, NEO, V(0, 15.0, -0.2), { seg: 'Cabeza' }),
      P('Boca', V(2.6, 0.55, 0.3), C.grisOsc, MET, V(0, 12.85, -2.05), { seg: 'Cabeza' }),
    ];
    for (let i = 0; i <= 5; i++) p.push(P('Puntada' + i, V(0.08, 0.7, 0.34), C.plata, PLA, V(-1.0 + i * 0.4, 12.85, -2.08), { seg: 'Cabeza' }));
    for (const [sx, n] of LADOS) {
      const pierna = 'Pierna' + n, brazo = 'Brazo' + n;
      p.push(P('Ojo' + n, V(1.3, 1.0, 0.3), C.neonNaranja, NEO, V(sx * 0.95, 14.0, -2.05), { seg: 'Cabeza' }));
      p.push(P('Ceja' + n, V(1.7, 0.4, 0.45), C.grisOsc, MET, V(sx * 0.9, 14.75, -2.1), { seg: 'Cabeza', rot: V(0, 0, -sx * 22) }));
      p.push(P('Antena' + n, V(0.16, 1.8, 0.16), C.grisOsc, MET, V(sx * 1.3, 16.1, -0.2), { seg: 'Cabeza', rot: V(0, 0, -sx * 22) }));
      p.push(P('Bola' + n, V(0.45, 0.45, 0.45), C.negro2, MET, V(sx * 1.65, 16.9, -0.2), { seg: 'Cabeza', forma: BOLA }));
      p.push(P('Muslo' + n, V(1.3, 2.4, 1.3), C.negro2, MET, V(sx * 1.4, 4.7, 0), { seg: pierna }));
      p.push(P('FranjaA' + n, V(1.4, 0.18, 1.4), C.neonNaranja, NEO, V(sx * 1.4, 5.3, 0), { seg: pierna }));
      p.push(P('FranjaB' + n, V(1.4, 0.18, 1.4), C.neonNaranja, NEO, V(sx * 1.4, 4.3, 0), { seg: pierna }));
      p.push(P('Rodilla' + n, V(1.6, 1.6, 1.6), C.negro2, MET, V(sx * 1.4, 3.4, 0), { seg: pierna, forma: BOLA }));
      p.push(P('RodLuz' + n, V(0.5, 0.5, 0.5), C.neonNaranja, NEO, V(sx * 1.4, 3.4, -0.75), { seg: pierna, forma: BOLA }));
      p.push(P('Canilla' + n, V(1.5, 2.3, 1.5), C.negro2, MET, V(sx * 1.4, 2.1, 0), { seg: pierna }));
      p.push(P('FranjaC' + n, V(1.6, 0.18, 1.6), C.neonNaranja, NEO, V(sx * 1.4, 2.4, 0), { seg: pierna }));
      p.push(P('Bota' + n, V(2.4, 1.0, 3.1), C.grisOsc, MET, V(sx * 1.4, 0.5, -0.45), { seg: pierna }));
      p.push(P('Hombro' + n, V(2.4, 2.4, 2.4), C.negro2, MET, V(sx * 3.4, 11.0, 0), { seg: brazo, forma: BOLA }));
      p.push(P('HombroLuz' + n, V(0.8, 0.8, 0.8), C.neonNaranja, NEO, V(sx * 3.4, 11.0, -1.15), { seg: brazo, forma: BOLA }));
      p.push(P('BrazoSup' + n, V(1.1, 2.8, 1.1), C.negro2, MET, V(sx * 3.6, 8.9, 0), { seg: brazo }));
      p.push(P('FranjaD' + n, V(1.2, 0.16, 1.2), C.neonNaranja, NEO, V(sx * 3.6, 9.4, 0), { seg: brazo }));
      p.push(P('FranjaE' + n, V(1.2, 0.16, 1.2), C.neonNaranja, NEO, V(sx * 3.6, 8.5, 0), { seg: brazo }));
      p.push(P('Antebrazo' + n, V(1.3, 2.8, 1.3), C.negro2, MET, V(sx * 3.7, 6.3, 0), { seg: brazo }));
      p.push(P('FranjaF' + n, V(1.4, 0.16, 1.4), C.neonNaranja, NEO, V(sx * 3.7, 6.8, 0), { seg: brazo }));
      p.push(P('FranjaG' + n, V(1.4, 0.16, 1.4), C.neonNaranja, NEO, V(sx * 3.7, 5.9, 0), { seg: brazo }));
      p.push(P('Mano' + n, V(1.6, 1.6, 1.6), C.grisOsc, MET, V(sx * 3.7, 4.5, 0), { seg: brazo, forma: BOLA }));
      [-0.5, 0, 0.5].forEach((dx, k) => {
        p.push(P('Garra' + n + (k + 1), V(0.35, 1.5, 0.35), C.negro2, MET, V(sx * 3.7 + dx, 3.3, -0.45), { seg: brazo, rot: V(20, 0, dx * 30) }));
      });
    }
    return {
      escala: 1.6, rootY: 6.5, pasoFreq: 3.2,
      segmentos: [
        { nombre: 'Torso', padre: 'root', pos: V(0, 7.0, 0) }, { nombre: 'Cabeza', padre: 'Torso', pos: V(0, 11.9, -0.2) },
        { nombre: 'BrazoIzq', padre: 'Torso', pos: V(-3.4, 11.0, 0) }, { nombre: 'BrazoDer', padre: 'Torso', pos: V(3.4, 11.0, 0) },
        { nombre: 'PiernaIzq', padre: 'root', pos: V(-1.4, 6.0, 0) }, { nombre: 'PiernaDer', padre: 'root', pos: V(1.4, 6.0, 0) },
      ],
      ojos: ['OjoIzq', 'OjoDer', 'Nucleo'], partes: p,
    };
  }

  // ================== JEFE MEGA-ARDUINO (verde, encorvado, cerebro Arduino) ==================
  // Basado en tu diseño de Roblox, con piernas, cuerpo y boca 100% robóticos.
  function specJefe() {
    const acero = C.grisOsc, aceroOsc = C.oscuro;
    const p = [
      P('Pelvis', V(4, 1.4, 3), aceroOsc, MET, V(0, 5.2, 0)),
      P('Barriga', V(5.2, 3.4, 4.2), acero, MET, V(0, 7.4, 0.25), { seg: 'Torso' }),
      P('Pecho', V(6.4, 3.6, 4.8), acero, MET, V(0, 10.2, -0.4), { seg: 'Torso', rot: V(-16, 0, 0) }),
      P('PlacaPecho', V(4.2, 2.2, 0.3), C.teal, PLA, V(0, 9.4, -2.65), { seg: 'Torso', rot: V(-16, 0, 0) }),
      P('Nucleo', V(1.4, 1.4, 1.4), C.neonVerde, NEO, V(0, 9.4, -2.85), { seg: 'Torso', forma: BOLA }),
      P('TuboIzq', V(3.0, 0.55, 0.55), C.plata, MET, V(-1.4, 12.4, 0.9), { seg: 'Torso', forma: CIL, rot: V(0, 0, 60) }),
      P('TuboDer', V(3.0, 0.55, 0.55), C.plata, MET, V(1.4, 12.4, 0.9), { seg: 'Torso', forma: CIL, rot: V(0, 0, -60) }),
      // cabeza con cerebro Arduino
      P('Cabeza', V(3.6, 2.6, 3.4), C.verde, MET, V(0, 11.1, -4.6), { seg: 'Cabeza' }),
      P('Mandibula', V(3.8, 1.2, 3.6), C.verdeOsc, MET, V(0, 9.3, -4.7), { seg: 'Cabeza' }),
      P('Placa', V(2.8, 0.25, 2.4), C.teal, PLA, V(0, 12.5, -4.6), { seg: 'Cabeza' }),
      P('Chip', V(1.0, 0.25, 0.6), C.negro, PLA, V(0.3, 12.7, -4.4), { seg: 'Cabeza' }),
      P('Pines', V(2.0, 0.3, 0.25), C.negro, PLA, V(0, 12.75, -3.6), { seg: 'Cabeza' }),
    ];
    // boca: rejilla de ventilación con luz verde (en vez de dientes)
    for (let i = 0; i <= 4; i++) p.push(P('Rejilla' + i, V(0.25, 0.7, 0.2), i % 2 ? aceroOsc : C.neonVerde, i % 2 ? MET : NEO, V(-1.0 + i * 0.5, 9.5, -6.55), { seg: 'Cabeza' }));
    [[-1.85, 10.2], [1.85, 10.2], [-1.85, 8.6], [1.85, 8.6]].forEach(([x, y], k) =>
      p.push(P('Tornillo' + k, V(0.4, 0.4, 0.4), C.plata, MET, V(x, y, -2.75), { seg: 'Torso', forma: BOLA })));
    const leds = [[C.neonRojo, V(-1.0, 12.75, -5.4)], [C.neonVerde, V(-0.4, 12.75, -5.5)], [C.neonAzul, V(0.6, 12.75, -5.4)], [C.neonAmarillo, V(1.0, 12.75, -4.0)], [C.neonNaranja, V(-0.9, 12.75, -3.9)]];
    leds.forEach(([c, pos], i) => p.push(P('LED' + (i + 1), V(0.32, 0.32, 0.32), c, NEO, pos, { seg: 'Cabeza', forma: BOLA })));
    for (const [sx, n] of LADOS) {
      const pierna = 'Pierna' + n, brazo = 'Brazo' + n;
      p.push(P('Ojo' + n, V(1.35, 1.35, 1.35), C.neonAmarillo, NEO, V(sx * 0.85, 11.4, -6.1), { seg: 'Cabeza', forma: BOLA }));
      p.push(P('Parpado' + n, V(1.7, 0.8, 0.7), C.verdeOsc, MET, V(sx * 0.85, 11.95, -6.15), { seg: 'Cabeza', rot: V(0, 0, -sx * 18) }));
      p.push(P('Perno' + n, V(0.8, 0.35, 0.35), C.plata, MET, V(sx * 2.2, 11.6, -5.2), { seg: 'Cabeza', forma: CIL }));
      p.push(P('AntenaLuz' + n, V(0.6, 0.6, 0.6), C.neonVerde, NEO, V(sx * 2.75, 11.6, -5.2), { seg: 'Cabeza', forma: BOLA }));
      // piernas robóticas: pistones y pies de garra
      p.push(P('Muslo' + n, V(1.7, 2.6, 1.7), C.verdeOsc, MET, V(sx * 1.3, 3.6, 0), { seg: pierna }));
      p.push(P('RodillaJ' + n, V(1.9, 1.9, 1.9), acero, MET, V(sx * 1.3, 2.2, 0), { seg: pierna, forma: BOLA }));
      p.push(P('Piston' + n, V(0.5, 1.6, 0.5), C.plata, MET, V(sx * 1.3, 1.4, 0.6), { seg: pierna }));
      p.push(P('Canilla' + n, V(1.6, 1.6, 1.6), C.verde, MET, V(sx * 1.3, 1.2, 0), { seg: pierna }));
      p.push(P('Pie' + n, V(2.6, 0.8, 3.2), aceroOsc, MET, V(sx * 1.3, 0.4, -0.5), { seg: pierna }));
      [-0.8, 0, 0.8].forEach((dx, k) => p.push(P('Dedo' + n + 'P' + k, V(0.5, 0.5, 0.9), acero, MET, V(sx * 1.3 + dx, 0.3, -2.4), { seg: pierna })));
      // brazos enormes
      p.push(P('Hombro' + n, V(4, 4, 4), C.verde, MET, V(sx * 4.0, 11.0, -0.4), { seg: brazo, forma: BOLA }));
      p.push(P('PernoH' + n, V(0.3, 1.4, 1.4), C.plata, MET, V(sx * 5.95, 11.6, -0.6), { seg: brazo, forma: CIL }));
      p.push(P('BrazoSup' + n, V(2.4, 3.2, 2.4), C.verde, MET, V(sx * 4.3, 8.6, -0.8), { seg: brazo }));
      p.push(P('Codo' + n, V(2.7, 2.7, 2.7), C.verdeOsc, MET, V(sx * 4.35, 6.9, -0.9), { seg: brazo, forma: BOLA }));
      p.push(P('Antebrazo' + n, V(2.8, 2.8, 2.8), C.verde, MET, V(sx * 4.4, 5.3, -1.0), { seg: brazo }));
      p.push(P('Mano' + n, V(2.4, 1.3, 2.4), C.verde, MET, V(sx * 4.4, 3.5, -1.1), { seg: brazo }));
      p.push(P('Boca' + n, V(0.9, 0.9, 0.9), C.neonVerde, NEO, V(sx * 4.4, 3.5, -2.35), { seg: brazo, forma: BOLA }));
      [-0.8, -0.27, 0.27, 0.8].forEach((dx, k) => p.push(P('Dedo' + n + (k + 1), V(0.5, 1.4, 0.55), C.verdeOsc, MET, V(sx * 4.4 + dx, 2.4, -1.9), { seg: brazo, rot: V(25, 0, 0) })));
    }
    return {
      escala: 2.4, rootY: 5.2, pasoFreq: 2.6,
      segmentos: [
        { nombre: 'Torso', padre: 'root', pos: V(0, 5.6, 0) }, { nombre: 'Cabeza', padre: 'Torso', pos: V(0, 10.9, -2.7) },
        { nombre: 'BrazoIzq', padre: 'Torso', pos: V(-4.0, 11.0, -0.4) }, { nombre: 'BrazoDer', padre: 'Torso', pos: V(4.0, 11.0, -0.4) },
        { nombre: 'PiernaIzq', padre: 'root', pos: V(-1.3, 4.8, 0) }, { nombre: 'PiernaDer', padre: 'root', pos: V(1.3, 4.8, 0) },
      ],
      ojos: ['OjoIzq', 'OjoDer', 'AntenaLuzIzq', 'AntenaLuzDer'], partes: p,
    };
  }

  // ================== DRON cuadricóptero ==================
  function specDron() {
    const p = [
      P('Cuerpo', V(1.6, 0.5, 1.6), C.grisOsc, MET, V(0, 14, 0)),
      P('Tapa', V(1.1, 0.3, 1.1), C.negro, PLA, V(0, 14.38, 0)),
      P('Placa', V(0.9, 0.08, 0.9), C.teal, PLA, V(0, 14.57, 0)),
      P('Bateria', V(0.55, 0.35, 1.0), C.azulPlaca, PLA, V(0, 13.6, 0.1)),
      P('Camara', V(0.5, 0.5, 0.5), C.negro, PLA, V(0, 13.7, -0.75), { forma: BOLA }),
      P('Lente', V(0.28, 0.28, 0.28), C.neonRojo, NEO, V(0, 13.7, -0.98), { forma: BOLA }),
      P('Brazo1', V(3.6, 0.18, 0.25), C.negro, PLA, V(0, 14, 0), { rot: V(0, 45, 0) }),
      P('Brazo2', V(3.6, 0.18, 0.25), C.negro, PLA, V(0, 14, 0), { rot: V(0, -45, 0) }),
      P('PataIzq', V(0.12, 0.12, 1.4), C.negro, PLA, V(-0.5, 13.35, 0)),
      P('PataDer', V(0.12, 0.12, 1.4), C.negro, PLA, V(0.5, 13.35, 0)),
    ];
    const segmentos = [];
    [[1, -1], [-1, -1], [-1, 1], [1, 1]].forEach((e, k) => {
      const i = k + 1, x = e[0] * 1.27, z = e[1] * 1.27, seg = 'Helice' + i;
      segmentos.push({ nombre: seg, padre: 'root', pos: V(x, 14.42, z) });
      p.push(P('Motor' + i, V(0.4, 0.45, 0.45), C.oscuro, MET, V(x, 14.15, z), { forma: CIL, rot: V(0, 0, 90) }));
      p.push(P('Aspa' + i, V(1.7, 0.05, 0.2), C.negro, PLA, V(x, 14.42, z), { seg }));
      p.push(P('AspaB' + i, V(0.2, 0.05, 1.7), C.negro, PLA, V(x, 14.42, z), { seg, transp: 0.4 }));
      p.push(P('Led' + i, V(0.2, 0.2, 0.2), e[1] < 0 ? C.neonRojo : C.neonVerde, NEO, V(x, 13.95, z), { forma: BOLA }));
    });
    return { escala: 1.3, rootY: 14, anim: 'dron', segmentos, ojos: ['Lente'], cabeza: ['Camara', 'Lente'], partes: p };
  }

  // ================== JEFE FINAL: el robot gigante del hechicero ARDUNOL ==================
  function specJefeFinal() {
    const morado = RGB(70, 40, 120), moradoOsc = RGB(38, 24, 66), placa = RGB(190, 185, 210), oro = RGB(230, 180, 50);
    const cian = RGB(70, 220, 255), cianClaro = RGB(170, 245, 255), naranja = RGB(255, 140, 40);
    const p = [
      P('Pelvis', V(4.2, 1.4, 3.0), moradoOsc, MET, V(0, 5.6, 0)),
      P('CintoOro', V(4.5, 0.4, 3.2), oro, MET, V(0, 6.3, 0), { seg: 'Torso' }),
      P('Abdomen', V(3.6, 2.0, 2.8), moradoOsc, MET, V(0, 7.4, 0), { seg: 'Torso' }),
      P('Pecho', V(7.0, 4.2, 4.4), morado, MET, V(0, 10.3, 0), { seg: 'Torso' }),
      P('PlacaPecho', V(5.6, 3.4, 0.5), placa, MET, V(0, 10.3, -2.35), { seg: 'Torso' }),
      P('BordeOro', V(5.9, 0.3, 0.6), oro, MET, V(0, 12.05, -2.35), { seg: 'Torso' }),
      P('BordeOro2', V(5.9, 0.3, 0.6), oro, MET, V(0, 8.55, -2.35), { seg: 'Torso' }),
      P('Nucleo', V(1.9, 1.9, 1.9), cian, NEO, V(0, 10.3, -2.65), { seg: 'Torso', forma: BOLA }),
      P('Cuello', V(1.8, 0.8, 1.8), moradoOsc, MET, V(0, 12.7, -0.1), { seg: 'Torso' }),
      P('Mochila', V(4.2, 3.2, 1.6), moradoOsc, MET, V(0, 10.4, 2.9), { seg: 'Torso' }),
      P('PlacaArduino', V(2.6, 1.8, 0.15), C.teal, PLA, V(0, 10.6, 3.75), { seg: 'Torso' }),
      P('Cabeza', V(3.4, 2.6, 3.2), morado, MET, V(0, 14.2, -0.3), { seg: 'Cabeza' }),
      P('Frente', V(3.0, 0.7, 0.5), placa, MET, V(0, 15.0, -1.85), { seg: 'Cabeza' }),
      P('Mandibula', V(2.6, 0.9, 0.7), moradoOsc, MET, V(0, 13.1, -1.75), { seg: 'Cabeza' }),
      P('Rejilla', V(1.8, 0.25, 0.1), cian, NEO, V(0, 13.1, -2.12), { seg: 'Cabeza' }),
      P('Cresta', V(0.45, 0.9, 3.0), C.teal, NEO, V(0, 15.7, -0.2), { seg: 'Cabeza' }),
    ];
    const grietas = [[-1.1, 0.7, 30], [1.0, 0.9, -25], [-0.8, -0.9, -40], [1.2, -0.6, 50], [0.2, 1.3, 10], [-0.1, -1.3, 70]];
    grietas.forEach((g, k) => p.push(P('Grieta' + (k + 1), V(0.35, 1.0, 0.3), cianClaro, NEO, V(g[0], 10.3 + g[1], -2.62), { seg: 'Torso', rot: V(0, 0, g[2]) })));
    for (const [sx, n] of LADOS) p.push(P('Tobera' + n, V(1.0, 1.0, 1.0), naranja, NEO, V(sx * 1.2, 8.7, 3.0), { seg: 'Torso', forma: BOLA }));
    for (const [sx, n] of LADOS) {
      const pierna = 'Pierna' + n, brazo = 'Brazo' + n;
      p.push(P('Visor' + n, V(1.5, 0.45, 0.2), cian, NEO, V(sx * 0.75, 14.15, -1.93), { seg: 'Cabeza', rot: V(0, 0, sx * 14) }));
      p.push(P('Cuerno' + n, V(0.5, 2.0, 0.5), oro, MET, V(sx * 1.75, 15.6, -0.3), { seg: 'Cabeza', rot: V(0, 0, -sx * 28) }));
      p.push(P('Oreja' + n, V(0.4, 1.2, 1.2), placa, MET, V(sx * 1.85, 14.1, -0.3), { seg: 'Cabeza', forma: CIL }));
      p.push(P('Muslo' + n, V(1.8, 2.6, 1.9), moradoOsc, MET, V(sx * 1.5, 4.1, 0), { seg: pierna }));
      p.push(P('Rodillera' + n, V(2.0, 1.3, 0.9), placa, MET, V(sx * 1.5, 2.95, -0.9), { seg: pierna }));
      p.push(P('Canilla' + n, V(2.0, 2.4, 2.2), morado, MET, V(sx * 1.5, 1.75, 0), { seg: pierna }));
      p.push(P('Raya' + n, V(0.2, 2.0, 0.1), C.teal, NEO, V(sx * 1.5, 1.75, -1.12), { seg: pierna }));
      p.push(P('Propulsor' + n, V(1.1, 0.5, 1.1), naranja, NEO, V(sx * 1.5, 1.2, 1.15), { seg: pierna }));
      p.push(P('Pie' + n, V(2.6, 0.9, 3.6), moradoOsc, MET, V(sx * 1.5, 0.45, -0.5), { seg: pierna }));
      p.push(P('Hombro' + n, V(2.8, 2.8, 2.8), moradoOsc, MET, V(sx * 4.2, 11.6, 0), { seg: brazo, forma: BOLA }));
      p.push(P('Hombrera' + n, V(3.2, 1.5, 3.6), morado, MET, V(sx * 4.5, 12.8, 0), { seg: brazo, rot: V(0, 0, -sx * 12) }));
      p.push(P('BordeHombrera' + n, V(3.3, 0.25, 3.7), oro, MET, V(sx * 4.5, 12.05, 0), { seg: brazo, rot: V(0, 0, -sx * 12) }));
    }
    const bi = 'BrazoIzq';
    p.push(P('BrazoSupIzq', V(1.8, 3.0, 1.8), moradoOsc, MET, V(-4.5, 9.4, 0), { seg: bi }));
    p.push(P('CodoIzq', V(2.0, 2.0, 2.0), placa, MET, V(-4.6, 7.8, 0), { seg: bi, forma: BOLA }));
    p.push(P('AntebrazoIzq', V(2.4, 3.0, 2.4), morado, MET, V(-4.7, 6.1, -0.2), { seg: bi }));
    p.push(P('CanonIzq', V(2.6, 1.4, 1.4), moradoOsc, MET, V(-4.7, 4.6, -0.9), { seg: bi, forma: CIL, rot: GIRO_Z }));
    p.push(P('AnilloCanon', V(0.4, 1.7, 1.7), oro, MET, V(-4.7, 4.6, -2.0), { seg: bi, forma: CIL, rot: GIRO_Z }));
    p.push(P('BocaIzq', V(1.0, 1.0, 1.0), cian, NEO, V(-4.7, 4.6, -2.3), { seg: bi, forma: BOLA }));
    const bd = 'BrazoDer';
    p.push(P('EnergiaSup', V(1.7, 3.0, 1.7), cian, NEO, V(4.5, 9.4, 0), { seg: bd, transp: 0.35 }));
    p.push(P('AnilloA', V(2.1, 0.3, 2.1), oro, MET, V(4.5, 10.3, 0), { seg: bd }));
    p.push(P('CodoDer', V(2.0, 2.0, 2.0), cianClaro, NEO, V(4.6, 7.8, 0), { seg: bd, forma: BOLA, transp: 0.2 }));
    p.push(P('EnergiaAnt', V(2.1, 3.0, 2.1), cian, NEO, V(4.7, 6.1, -0.2), { seg: bd, transp: 0.3 }));
    p.push(P('AnilloB', V(2.5, 0.3, 2.5), oro, MET, V(4.7, 5.2, -0.2), { seg: bd }));
    p.push(P('BocaDer', V(2.8, 2.4, 2.8), cianClaro, NEO, V(4.7, 3.9, -0.4), { seg: bd, transp: 0.1 }));
    [-0.9, -0.3, 0.3, 0.9].forEach((dx, k) => p.push(P('Nudillo' + (k + 1), V(0.5, 0.55, 0.6), cian, NEO, V(4.7 + dx, 4.6, -1.85), { seg: bd, forma: BOLA })));
    return {
      escala: 3.4, rootY: 5.6, pasoFreq: 2.2,
      segmentos: [
        { nombre: 'Torso', padre: 'root', pos: V(0, 6.0, 0) }, { nombre: 'Cabeza', padre: 'Torso', pos: V(0, 12.8, -0.2) },
        { nombre: 'BrazoIzq', padre: 'Torso', pos: V(-4.2, 11.6, 0) }, { nombre: 'BrazoDer', padre: 'Torso', pos: V(4.2, 11.6, 0) },
        { nombre: 'PiernaIzq', padre: 'root', pos: V(-1.5, 5.2, 0) }, { nombre: 'PiernaDer', padre: 'root', pos: V(1.5, 5.2, 0) },
      ],
      ojos: ['VisorIzq', 'VisorDer', 'Nucleo', 'Rejilla'], partes: p,
    };
  }

  const SPECS = {
    Dron: specDron(), Seguidor: specSeguidor(), Arana: specArana(), Soldado: specSoldado(), Tanque: specTanque(),
    Chatarra: specChatarra(), Coloso: specColoso(), Jefe: specJefe(), JefeFinal: specJefeFinal(),
  };

  // ---------------------------------------------------------------------
  //  Constructor: igual que M.construir de Roblox, pero en Three.js
  // ---------------------------------------------------------------------
  const geoCache = new Map();
  function geometria(p) {
    const clave = p.forma + p.size.join(',');
    let g = geoCache.get(clave);
    if (g) return g;
    const [sx, sy, sz] = p.size;
    if (p.forma === BOLA) g = new THREE.SphereGeometry(0.5, 16, 12).scale(sx, sy, sz);
    else if (p.forma === CIL) { const d = Math.min(sy, sz); g = new THREE.CylinderGeometry(0.5, 0.5, 1, 18).rotateZ(Math.PI / 2).scale(sx, d, d); }
    else g = new THREE.BoxGeometry(sx, sy, sz);
    geoCache.set(clave, g);
    return g;
  }
  function material(cache, p) {
    const clave = p.color.join(',') + p.mat + (p.transp || 0);
    let m = cache.get(clave);
    if (m) return m;
    const c = new THREE.Color(p.color[0] / 255, p.color[1] / 255, p.color[2] / 255);
    const o = p.transp ? { transparent: true, opacity: 1 - p.transp, depthWrite: p.transp < 0.3 } : {};
    switch (p.mat) {
      case NEO: m = new THREE.MeshBasicMaterial({ color: c.multiplyScalar(2.6), ...o }); break;
      case MET: m = new THREE.MeshStandardMaterial({ color: c, metalness: 0.55, roughness: 0.38, ...o }); break;
      case OXI: m = new THREE.MeshStandardMaterial({ color: c, metalness: 0.35, roughness: 0.92, flatShading: true, ...o }); break;
      case TEL: m = new THREE.MeshStandardMaterial({ color: c, metalness: 0, roughness: 1, ...o }); break;
      case VID: m = new THREE.MeshStandardMaterial({ color: c, metalness: 0.1, roughness: 0.05, transparent: true, opacity: 1 - (p.transp || 0.5), depthWrite: false }); break;
      default: m = new THREE.MeshStandardMaterial({ color: c, metalness: 0, roughness: 0.42, ...o });
    }
    cache.set(clave, m);
    return m;
  }

  const ESC = 0.36; // metros por stud (igual que las bases)
  const eu = new THREE.Euler();
  function construir(tipo) {
    const spec = SPECS[tipo], s = spec.escala * ESC;
    const raiz = new THREE.Group();
    const cuerpo = new THREE.Group(); raiz.add(cuerpo); // se mueve todo junto (bamboleo, salto)
    // el dron se dibuja centrado en su cuerpo (vuela)
    const y0 = spec.anim === 'dron' ? -spec.rootY : 0;
    const segs = { root: { g: cuerpo, abs: [0, y0, 0] } };
    for (const sg of spec.segmentos || []) {
      const padre = segs[sg.padre];
      const g = new THREE.Group();
      const abs = [sg.pos[0], sg.pos[1] + y0, sg.pos[2]];
      g.position.set((abs[0] - padre.abs[0]) * s, (abs[1] - padre.abs[1]) * s, (abs[2] - padre.abs[2]) * s);
      padre.g.add(g);
      segs[sg.nombre] = { g, abs, dir: sg.dir };
    }
    const cache = new Map(), partes = {}, mats = [];
    const cabeza = new Set(spec.cabeza || []);
    for (const p of spec.partes) {
      const seg = segs[p.seg || 'root'];
      const mesh = new THREE.Mesh(geometria(p), material(cache, p));
      mesh.scale.setScalar(s);
      mesh.position.set((p.pos[0] - seg.abs[0]) * s, (p.pos[1] + y0 - seg.abs[1]) * s, (p.pos[2] - seg.abs[2]) * s);
      if (p.rot) { eu.set((p.rot[0] * Math.PI) / 180, (p.rot[1] * Math.PI) / 180, (p.rot[2] * Math.PI) / 180, 'XYZ'); mesh.rotation.copy(eu); }
      mesh.castShadow = p.mat !== NEO && !p.transp;
      if (p.seg === 'Cabeza' || cabeza.has(p.nombre)) mesh.userData.critico = true;
      seg.g.add(mesh);
      partes[p.nombre] = mesh;
    }
    for (const m of cache.values()) if (m.isMeshStandardMaterial) mats.push(m);
    // medidas reales del modelo (para colisiones y puntería)
    raiz.updateMatrixWorld(true);
    const bb = new THREE.Box3().setFromObject(raiz);
    const med = { alto: bb.max.y - Math.max(bb.min.y, 0), ancho: Math.max(bb.max.x - bb.min.x, bb.max.z - bb.min.z), minY: bb.min.y, maxY: bb.max.y };
    return { raiz, cuerpo, segs, partes, mats, spec, med, ojos: spec.ojos.map((n) => partes[n]).filter(Boolean) };
  }

  return { SPECS, construir, ESC };
})();
