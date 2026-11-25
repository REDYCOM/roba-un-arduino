--=====================================================================
--  MODELOS DE ROBOTS ENEMIGOS (ModuleScript)
--  Cada robot se arma con piezas. Los humanoides tienen ARTICULACIONES
--  (Motor6D) para que el cliente los anime (caminar, garras, etc.).
--  Posiciones en "coordenadas de suelo": y = altura sobre el piso.
--  El frente del robot mira hacia -Z.
--
--  ¿Quieres usar TU modelo 3D? Pon un Model en ServerStorage > ModelosRobots
--  con el nombre del tipo (Seguidor, Tanque, Chatarra, Coloso o Jefe),
--  mirando hacia el frente. Se usará ese en vez del de piezas.
--=====================================================================

local ServerStorage = game:GetService("ServerStorage")

local M = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local MET, PLA, NEO = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon
local OXI, TEL = Enum.Material.CorrodedMetal, Enum.Material.Fabric
local BOLA, CIL = Enum.PartType.Ball, Enum.PartType.Cylinder

local C = {
	teal = RGB(0, 129, 132), oscuro = RGB(42, 45, 54), negro = RGB(22, 22, 26),
	plata = RGB(190, 192, 198), rojo = RGB(130, 28, 28), blanco = RGB(240, 240, 232),
	neonRojo = RGB(255, 45, 45), neonNaranja = RGB(255, 130, 20), neonAmarillo = RGB(255, 230, 70),
	neonVerde = RGB(80, 255, 90), neonAzul = RGB(70, 160, 255),
	gris = RGB(112, 110, 106), oxido = RGB(150, 72, 38), oxidoOsc = RGB(95, 45, 25),
	negro2 = RGB(28, 28, 34), grisOsc = RGB(55, 58, 66),
	verde = RGB(110, 135, 85), verdeOsc = RGB(82, 102, 62), granate = RGB(105, 62, 58),
	jean = RGB(85, 100, 135), cafe = RGB(85, 55, 40),
	-- robots educativos (impresión 3D, aluminio Makeblock, servos)
	azulPLA = RGB(30, 90, 220), blancoPLA = RGB(235, 228, 210), azulAlu = RGB(40, 115, 205),
	cristal = RGB(210, 225, 235), cableNaranja = RGB(230, 120, 30), azulPlaca = RGB(30, 90, 180),
	amarillo = RGB(240, 220, 40),
}

-- P(nombre, tamaño, color, material, posición, { forma, seg = segmento, rot = grados XYZ, transp })
local function P(nombre, size, color, mat, pos, op)
	op = op or {}
	return { nombre = nombre, size = size, color = color, mat = mat, pos = pos,
		forma = op.forma, seg = op.seg, rot = op.rot, transp = op.transp }
end
local GIRO_Z = V(0, 90, 0)  -- gira un cilindro para que apunte hacia adelante

local LADOS = { { -1, "Izq" }, { 1, "Der" } }

-- ================== SEGUIDOR (pequeño, ruedas) ==================
local function specSeguidor()
	local p = {
		P("Chasis",    V(2.8, 0.5, 3.4),   C.oscuro, MET, V(0, 1.3, 0)),
		P("Placa",     V(2.3, 0.15, 2.7),  C.teal,   PLA, V(0, 1.62, 0.1)),
		P("Chip",      V(1, 0.2, 0.5),     C.negro,  PLA, V(0, 1.78, 0.4)),
		P("Puerto",    V(0.6, 0.35, 0.5),  C.plata,  MET, V(-0.7, 1.8, 1.15)),
		P("RuedaLoca", V(0.6, 0.6, 0.6),   C.plata,  MET, V(0, 0.3, -1.3), { forma = BOLA }),
		P("Sensor",    V(2.2, 0.25, 0.4),  C.negro,  PLA, V(0, 0.6, -1.8)),
		P("Antena",    V(0.1, 1.2, 0.1),   C.oscuro, MET, V(0.9, 2.3, 1.2)),
		P("Punta",     V(0.3, 0.3, 0.3),   C.neonRojo, NEO, V(0.9, 2.95, 1.2), { forma = BOLA }),
	}
	-- sensor ultrasónico HC-SR04 como "ojos"
	table.insert(p, P("SoporteSonar", V(0.3, 0.5, 0.3), C.oscuro, MET, V(0, 1.75, -1.4)))
	table.insert(p, P("PlacaSonar", V(1.7, 0.75, 0.12), C.azulPlaca, PLA, V(0, 2.25, -1.45)))
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		table.insert(p, P("Rueda" .. n, V(0.5, 1.8, 1.8), C.negro, PLA, V(sx * 1.6, 0.9, 0.5), { forma = CIL }))
		table.insert(p, P("Sonar" .. n, V(0.35, 0.62, 0.62), C.plata, MET, V(sx * 0.45, 2.25, -1.62), { forma = CIL, rot = GIRO_Z }))
		table.insert(p, P("Ojo" .. n, V(0.06, 0.42, 0.42), C.neonRojo, NEO, V(sx * 0.45, 2.25, -1.81), { forma = CIL, rot = GIRO_Z }))
		-- ceja de enojo (el extremo interior más bajo)
		table.insert(p, P("Ceja" .. n, V(0.6, 0.12, 0.2), C.negro, PLA, V(sx * 0.45, 2.72, -1.55), { rot = V(0, 0, -sx * 25) }))
	end
	return {
		escala = 1, rootY = 1.6, rootSize = V(3, 1.2, 3.6),
		ojos = { "OjoIzq", "OjoDer", "Punta" },
		partes = p,
	}
end

-- ================== TANQUE estilo "Ranger" (orugas + aluminio azul) ==================
local function specTanque()
	local p = {
		P("Marco",      V(2.4, 0.9, 3.0),   C.azulAlu, MET, V(0, 1.4, 0)),
		P("Caja",       V(1.9, 0.9, 2.0),   C.cristal, Enum.Material.Glass, V(0, 2.3, 0.4), { transp = 0.45 }),
		P("PlacaInt",   V(1.6, 0.1, 1.7),   C.teal,    PLA, V(0, 1.95, 0.4)),
		P("ChipInt",    V(0.6, 0.15, 0.6),  C.negro,   PLA, V(0.2, 2.05, 0.5)),
		P("Soporte",    V(0.3, 0.6, 0.3),   C.azulAlu, MET, V(0, 1.95, -1.35)),
		P("SonarPlaca", V(1.6, 0.75, 0.12), C.negro,   PLA, V(0, 2.4, -1.45)),
	}
	for k = 0, 3 do  -- puertos RJ25 al costado
		table.insert(p, P("Puerto" .. k, V(0.12, 0.28, 0.28), C.blanco, PLA, V(0.97, 2.15, -0.2 + k * 0.35)))
	end
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		table.insert(p, P("Oruga" .. n,  V(0.9, 1.3, 4.6),  C.negro,    PLA, V(sx * 1.65, 0.65, 0)))
		table.insert(p, P("RuedaF" .. n, V(1.0, 1.3, 1.3),  C.oscuro,   MET, V(sx * 1.65, 0.65, -2.05), { forma = CIL }))
		table.insert(p, P("RuedaT" .. n, V(1.0, 1.3, 1.3),  C.oscuro,   MET, V(sx * 1.65, 0.65, 2.05), { forma = CIL }))
		table.insert(p, P("Barra" .. n,  V(0.2, 0.35, 3.4), C.azulAlu,  MET, V(sx * 1.22, 1.95, 0)))
		table.insert(p, P("Sonar" .. n,  V(0.3, 0.55, 0.55), C.plata,   MET, V(sx * 0.42, 2.4, -1.62), { forma = CIL, rot = GIRO_Z }))
		table.insert(p, P("Ojo" .. n,    V(0.05, 0.38, 0.38), C.neonRojo, NEO, V(sx * 0.42, 2.4, -1.79), { forma = CIL, rot = GIRO_Z }))
	end
	return {
		escala = 1.8, rootY = 1.7, rootSize = V(3.4, 1.4, 4.2),
		ojos = { "OjoIzq", "OjoDer" },
		partes = p,
	}
end

-- ================== ARAÑA de 4 patas con servos (pequeña y rápida) ==================
local function specArana()
	local p = {
		P("Cuerpo",  V(1.8, 0.5, 1.8),  C.blancoPLA, PLA, V(0, 1.6, 0)),
		P("Base2",   V(1.4, 0.3, 1.4),  C.blancoPLA, PLA, V(0, 1.25, 0)),
		P("Nano",    V(0.5, 0.12, 1.1), C.azulPlaca, PLA, V(0, 1.92, 0.1)),
		P("USB",     V(0.3, 0.15, 0.25), C.plata,    MET, V(0, 1.98, 0.65)),
		P("Brida",   V(1.3, 0.07, 0.07), C.amarillo, PLA, V(0, 2.0, 0), { rot = V(0, 45, 0) }),
		P("OjoIzq",  V(0.3, 0.3, 0.3),  C.neonRojo,  NEO, V(-0.3, 1.7, -0.92), { forma = BOLA }),
		P("OjoDer",  V(0.3, 0.3, 0.3),  C.neonRojo,  NEO, V(0.3, 1.7, -0.92), { forma = BOLA }),
	}
	local segmentos = {}
	for i, ang in ipairs({ 45, 135, 225, 315 }) do
		local a = math.rad(ang)
		local dx, dz = math.cos(a), math.sin(a)
		local seg = "Pata" .. i
		local giro = V(0, math.deg(math.atan2(-dz, dx)), 0)  -- alinea la pata hacia afuera
		table.insert(segmentos, { seg, "root", V(dx * 0.85, 1.6, dz * 0.85), dir = { dx, dz } })
		table.insert(p, P("Servo" .. i,   V(0.55, 0.5, 0.55), C.azulPLA,   PLA, V(dx * 0.85, 1.6, dz * 0.85), { seg = seg, rot = giro }))
		table.insert(p, P("Femur" .. i,   V(1.3, 0.28, 0.4),  C.blancoPLA, PLA, V(dx * 1.55, 1.85, dz * 1.55), { seg = seg, rot = giro }))
		table.insert(p, P("Rodilla" .. i, V(0.5, 0.55, 0.5),  C.azulPLA,   PLA, V(dx * 2.2, 1.85, dz * 2.2), { seg = seg, rot = giro }))
		table.insert(p, P("Tibia" .. i,   V(0.28, 1.8, 0.28), C.blancoPLA, PLA, V(dx * 2.35, 0.95, dz * 2.35), { seg = seg, rot = giro }))
		table.insert(p, P("Cable" .. i,   V(1.2, 0.06, 0.06), C.cableNaranja, PLA, V(dx * 1.5, 2.02, dz * 1.5), { seg = seg, rot = giro }))
	end
	return {
		escala = 1.3, rootY = 1.6, rootSize = V(1.8, 0.9, 1.8), anim = "arana", pasoFreq = 9,
		segmentos = segmentos,
		ojos = { "OjoIzq", "OjoDer" },
		partes = p,
	}
end

-- ================== SOLDADO humanoide de servos (azul y negro) ==================
local function specSoldado()
	local p = {
		P("Pelvis",   V(2.0, 0.8, 1.3), C.azulPLA, PLA, V(0, 3.6, 0)),
		P("PechoInf", V(2.0, 0.8, 1.4), C.azulPLA, PLA, V(0, 4.2, 0), { seg = "Torso" }),
		P("Pecho",    V(2.6, 1.9, 1.6), C.azulPLA, PLA, V(0, 5.45, 0), { seg = "Torso" }),
		P("LedL",     V(0.45, 0.45, 0.1), C.neonRojo, NEO, V(0, 5.6, -0.83), { seg = "Torso" }),
		P("Placa",    V(1.2, 0.8, 0.08), C.teal, PLA, V(0, 5.0, 0.83), { seg = "Torso" }),
		P("Cubo",     V(1.3, 1.2, 1.2), C.negro, PLA, V(0, 6.95, 0), { seg = "Cabeza" }),
		-- visor en "V" de enojo
		P("VisorIzq", V(0.6, 0.22, 0.1), C.neonRojo, NEO, V(-0.28, 7.05, -0.62), { seg = "Cabeza", rot = V(0, 0, -15) }),
		P("VisorDer", V(0.6, 0.22, 0.1), C.neonRojo, NEO, V(0.28, 7.05, -0.62), { seg = "Cabeza", rot = V(0, 0, 15) }),
	}
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		local pierna, brazo = "Pierna" .. n, "Brazo" .. n
		table.insert(p, P("ServoCadera" .. n,  V(0.8, 0.6, 0.9),  C.negro,   PLA, V(sx * 0.55, 3.2, 0), { seg = pierna }))
		table.insert(p, P("Muslo" .. n,        V(0.8, 1.2, 0.9),  C.azulPLA, PLA, V(sx * 0.55, 2.45, 0), { seg = pierna }))
		table.insert(p, P("ServoRodilla" .. n, V(0.85, 0.55, 0.9), C.negro,  PLA, V(sx * 0.55, 1.65, 0), { seg = pierna }))
		table.insert(p, P("Canilla" .. n,      V(0.8, 1.0, 0.9),  C.azulPLA, PLA, V(sx * 0.55, 0.95, 0), { seg = pierna }))
		table.insert(p, P("Pie" .. n,          V(1.0, 0.35, 1.5), C.negro,   PLA, V(sx * 0.55, 0.2, -0.15), { seg = pierna }))
		table.insert(p, P("CableP" .. n,       V(0.06, 1.8, 0.06), C.cableNaranja, PLA, V(sx * 0.98, 2.4, 0.3), { seg = pierna }))
		table.insert(p, P("ServoHombro" .. n,  V(0.7, 0.9, 0.9),  C.negro,   PLA, V(sx * 1.6, 6.0, 0), { seg = brazo }))
		table.insert(p, P("Brazo" .. n,        V(0.5, 1.4, 0.8),  C.azulPLA, PLA, V(sx * 1.75, 5.0, 0), { seg = brazo }))
		table.insert(p, P("ServoCodo" .. n,    V(0.6, 0.6, 0.8),  C.negro,   PLA, V(sx * 1.75, 4.1, 0), { seg = brazo }))
		table.insert(p, P("Pinza" .. n,        V(0.5, 1.0, 0.7),  C.negro,   PLA, V(sx * 1.75, 3.35, -0.1), { seg = brazo }))
		table.insert(p, P("GarraA" .. n,       V(0.15, 0.6, 0.15), C.negro,  PLA, V(sx * 1.75, 2.65, -0.35), { seg = brazo, rot = V(15, 0, 0) }))
		table.insert(p, P("GarraB" .. n,       V(0.15, 0.6, 0.15), C.negro,  PLA, V(sx * 1.75, 2.65, 0.15), { seg = brazo, rot = V(-10, 0, 0) }))
	end
	return {
		escala = 1.1, rootY = 3.6, rootSize = V(2.0, 0.9, 1.3), pasoFreq = 7,
		segmentos = {
			{ "Torso", "root", V(0, 3.9, 0) },
			{ "Cabeza", "Torso", V(0, 6.4, 0) },
			{ "BrazoIzq", "Torso", V(-1.6, 6.0, 0) },
			{ "BrazoDer", "Torso", V(1.6, 6.0, 0) },
			{ "PiernaIzq", "root", V(-0.55, 3.35, 0) },
			{ "PiernaDer", "root", V(0.55, 3.35, 0) },
		},
		ojos = { "VisorIzq", "VisorDer", "LedL" },
		partes = p,
	}
end

-- ================== CHATARRA (zombi oxidado, oleada 2) ==================
local function specChatarra()
	local p = {
		P("Pelvis",  V(2.4, 1.1, 1.6), C.gris, OXI, V(0, 4.2, 0)),
		-- torso encorvado
		P("Pecho",   V(2.6, 2.6, 1.8), C.gris,     OXI, V(0, 6.0, -0.35), { seg = "Torso", rot = V(-14, 0, 0) }),
		P("Parche1", V(1.0, 0.8, 0.1), C.oxido,    OXI, V(-0.6, 6.4, -1.32), { seg = "Torso", rot = V(-14, 0, 10) }),
		P("Parche2", V(0.7, 1.1, 0.1), C.oxidoOsc, OXI, V(0.7, 5.6, -1.2), { seg = "Torso", rot = V(-14, 0, -8) }),
		P("Nucleo",  V(0.6, 0.6, 0.6), C.neonNaranja, NEO, V(0.1, 6.1, -1.28), { seg = "Torso", forma = BOLA }),
		P("Cuello",  V(0.6, 0.6, 0.6), C.oscuro,   MET, V(0, 7.3, -0.85), { seg = "Torso" }),
		-- cabeza tipo calavera
		P("Craneo",  V(2.2, 1.9, 2.0), C.gris,     OXI, V(0, 8.25, -1.25), { seg = "Cabeza" }),
		P("ParcheC", V(0.9, 0.6, 0.12), C.oxido,   OXI, V(0.5, 8.9, -2.27), { seg = "Cabeza" }),
		P("Cuenca",  V(1.0, 1.0, 1.0), C.negro,    PLA, V(-0.5, 8.45, -2.2), { seg = "Cabeza", forma = BOLA }),
		P("OjoIzq",  V(0.7, 0.7, 0.7), C.neonNaranja, NEO, V(-0.5, 8.45, -2.45), { seg = "Cabeza", forma = BOLA }),
		P("OjoDer",  V(0.4, 0.4, 0.4), C.neonRojo, NEO, V(0.55, 8.55, -2.28), { seg = "Cabeza", forma = BOLA }),
		P("CejaDer", V(0.75, 0.15, 0.2), C.negro,  PLA, V(0.55, 8.88, -2.3), { seg = "Cabeza", rot = V(0, 0, 22) }),
		P("Rejilla", V(1.3, 0.55, 0.15), C.negro,  PLA, V(0, 7.75, -2.25), { seg = "Cabeza" }),
		P("Antena",  V(0.08, 1.2, 0.08), C.oscuro, MET, V(0.8, 9.7, -1.0), { seg = "Cabeza", rot = V(0, 0, -15) }),
		P("Punta",   V(0.25, 0.25, 0.25), C.neonRojo, NEO, V(0.95, 10.3, -1.0), { seg = "Cabeza", forma = BOLA }),
	}
	for i, x in ipairs({ -0.45, -0.15, 0.15, 0.45 }) do
		table.insert(p, P("Barra" .. i, V(0.08, 0.5, 0.17), C.gris, OXI, V(x, 7.75, -2.32), { seg = "Cabeza" }))
	end
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		local pierna, brazo = "Pierna" .. n, "Brazo" .. n
		table.insert(p, P("Muslo" .. n,   V(0.7, 1.8, 0.7),   C.gris,     OXI, V(sx * 0.75, 2.85, 0), { seg = pierna }))
		table.insert(p, P("Rodilla" .. n, V(0.95, 0.95, 0.95), C.oxido,   OXI, V(sx * 0.75, 1.95, 0), { seg = pierna, forma = BOLA }))
		table.insert(p, P("Canilla" .. n, V(0.85, 1.6, 0.85), C.gris,     OXI, V(sx * 0.75, 1.05, 0), { seg = pierna }))
		table.insert(p, P("Pie" .. n,     V(1.3, 0.5, 1.9),   C.oxidoOsc, OXI, V(sx * 0.75, 0.25, -0.35), { seg = pierna }))
		table.insert(p, P("Hombro" .. n,  V(1.1, 1.1, 1.1),   C.oxido,    OXI, V(sx * 1.7, 6.8, -0.4), { seg = brazo, forma = BOLA }))
		table.insert(p, P("BrazoSup" .. n, V(0.55, 1.8, 0.55), C.gris,    OXI, V(sx * 1.85, 5.8, -0.5), { seg = brazo }))
		table.insert(p, P("Codo" .. n,    V(0.75, 0.75, 0.75), C.oxidoOsc, OXI, V(sx * 1.9, 4.9, -0.55), { seg = brazo, forma = BOLA }))
		table.insert(p, P("Antebrazo" .. n, V(0.95, 1.9, 0.95), C.gris,   OXI, V(sx * 1.95, 3.95, -0.6), { seg = brazo }))
		for j, dz in ipairs({ -0.3, 0, 0.3 }) do
			table.insert(p, P("Garra" .. n .. j, V(0.18, 1.0, 0.18), C.oscuro, MET,
				V(sx * 1.95, 2.6, -0.6 + dz), { seg = brazo, rot = V(18, 0, sx * (j - 2) * 12) }))
		end
	end
	return {
		escala = 1.45, rootY = 4.2, rootSize = V(2.4, 1.2, 1.6), pasoFreq = 6,
		segmentos = {
			{ "Torso", "root", V(0, 4.6, 0) },
			{ "Cabeza", "Torso", V(0, 7.3, -0.9) },
			{ "BrazoIzq", "Torso", V(-1.7, 6.8, -0.4) },
			{ "BrazoDer", "Torso", V(1.7, 6.8, -0.4) },
			{ "PiernaIzq", "root", V(-0.75, 3.8, 0) },
			{ "PiernaDer", "root", V(0.75, 3.8, 0) },
		},
		ojos = { "OjoIzq", "OjoDer", "Punta", "Nucleo" },
		partes = p,
	}
end

-- ================== COLOSO (gigante negro y naranja, oleada 3) ==================
local function specColoso()
	local p = {
		P("Pelvis",     V(3.6, 1.3, 2.4), C.grisOsc, MET, V(0, 6.5, 0)),
		P("Cinturon",   V(4.4, 0.7, 2.9), C.grisOsc, MET, V(0, 7.5, 0), { seg = "Torso" }),
		P("Pecho",      V(5.0, 4.0, 3.4), C.negro2,  MET, V(0, 9.7, 0), { seg = "Torso" }),
		P("LineaIzq",   V(0.18, 3.4, 0.1), C.neonNaranja, NEO, V(-1.3, 9.7, -1.72), { seg = "Torso" }),
		P("LineaDer",   V(0.18, 3.4, 0.1), C.neonNaranja, NEO, V(1.3, 9.7, -1.72), { seg = "Torso" }),
		P("LineaArriba", V(2.8, 0.18, 0.1), C.neonNaranja, NEO, V(0, 11.3, -1.72), { seg = "Torso" }),
		P("Nucleo",     V(1.0, 1.0, 1.0), C.neonNaranja, NEO, V(0, 8.6, -1.7), { seg = "Torso", forma = BOLA }),
		-- cabeza enojada
		P("Cuello",     V(1.6, 0.8, 1.6), C.grisOsc, MET, V(0, 12.0, -0.1), { seg = "Cabeza" }),
		P("Craneo",     V(4.2, 3.2, 3.6), C.negro2,  MET, V(0, 13.8, -0.2), { seg = "Cabeza" }),
		P("CascoLinea", V(4.3, 0.2, 3.7), C.neonNaranja, NEO, V(0, 15.0, -0.2), { seg = "Cabeza" }),
		P("Boca",       V(2.6, 0.55, 0.3), C.grisOsc, MET, V(0, 12.85, -2.05), { seg = "Cabeza" }),
	}
	for i = 0, 5 do
		table.insert(p, P("Puntada" .. i, V(0.08, 0.7, 0.34), C.plata, PLA, V(-1.0 + i * 0.4, 12.85, -2.08), { seg = "Cabeza" }))
	end
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		local pierna, brazo = "Pierna" .. n, "Brazo" .. n
		-- cabeza: ojos + cejas + antenas
		table.insert(p, P("Ojo" .. n,    V(1.3, 1.0, 0.3), C.neonNaranja, NEO, V(sx * 0.95, 14.0, -2.05), { seg = "Cabeza" }))
		table.insert(p, P("Ceja" .. n,   V(1.7, 0.4, 0.45), C.grisOsc, MET, V(sx * 0.9, 14.75, -2.1), { seg = "Cabeza", rot = V(0, 0, -sx * 22) }))
		table.insert(p, P("Antena" .. n, V(0.16, 1.8, 0.16), C.grisOsc, MET, V(sx * 1.3, 16.1, -0.2), { seg = "Cabeza", rot = V(0, 0, -sx * 22) }))
		table.insert(p, P("Bola" .. n,   V(0.45, 0.45, 0.45), C.negro2, MET, V(sx * 1.65, 16.9, -0.2), { seg = "Cabeza", forma = BOLA }))
		-- piernas con franjas
		table.insert(p, P("Muslo" .. n,   V(1.3, 2.4, 1.3), C.negro2, MET, V(sx * 1.4, 4.7, 0), { seg = pierna }))
		table.insert(p, P("FranjaA" .. n, V(1.4, 0.18, 1.4), C.neonNaranja, NEO, V(sx * 1.4, 5.3, 0), { seg = pierna }))
		table.insert(p, P("FranjaB" .. n, V(1.4, 0.18, 1.4), C.neonNaranja, NEO, V(sx * 1.4, 4.3, 0), { seg = pierna }))
		table.insert(p, P("Rodilla" .. n, V(1.6, 1.6, 1.6), C.negro2, MET, V(sx * 1.4, 3.4, 0), { seg = pierna, forma = BOLA }))
		table.insert(p, P("RodLuz" .. n,  V(0.5, 0.5, 0.5), C.neonNaranja, NEO, V(sx * 1.4, 3.4, -0.75), { seg = pierna, forma = BOLA }))
		table.insert(p, P("Canilla" .. n, V(1.5, 2.3, 1.5), C.negro2, MET, V(sx * 1.4, 2.1, 0), { seg = pierna }))
		table.insert(p, P("FranjaC" .. n, V(1.6, 0.18, 1.6), C.neonNaranja, NEO, V(sx * 1.4, 2.4, 0), { seg = pierna }))
		table.insert(p, P("Bota" .. n,    V(2.4, 1.0, 3.1), C.grisOsc, MET, V(sx * 1.4, 0.5, -0.45), { seg = pierna }))
		-- brazos con garras
		table.insert(p, P("Hombro" .. n,    V(2.4, 2.4, 2.4), C.negro2, MET, V(sx * 3.4, 11.0, 0), { seg = brazo, forma = BOLA }))
		table.insert(p, P("HombroLuz" .. n, V(0.8, 0.8, 0.8), C.neonNaranja, NEO, V(sx * 3.4, 11.0, -1.15), { seg = brazo, forma = BOLA }))
		table.insert(p, P("BrazoSup" .. n,  V(1.1, 2.8, 1.1), C.negro2, MET, V(sx * 3.6, 8.9, 0), { seg = brazo }))
		table.insert(p, P("FranjaD" .. n,   V(1.2, 0.16, 1.2), C.neonNaranja, NEO, V(sx * 3.6, 9.4, 0), { seg = brazo }))
		table.insert(p, P("FranjaE" .. n,   V(1.2, 0.16, 1.2), C.neonNaranja, NEO, V(sx * 3.6, 8.5, 0), { seg = brazo }))
		table.insert(p, P("Antebrazo" .. n, V(1.3, 2.8, 1.3), C.negro2, MET, V(sx * 3.7, 6.3, 0), { seg = brazo }))
		table.insert(p, P("FranjaF" .. n,   V(1.4, 0.16, 1.4), C.neonNaranja, NEO, V(sx * 3.7, 6.8, 0), { seg = brazo }))
		table.insert(p, P("FranjaG" .. n,   V(1.4, 0.16, 1.4), C.neonNaranja, NEO, V(sx * 3.7, 5.9, 0), { seg = brazo }))
		table.insert(p, P("Mano" .. n,      V(1.6, 1.6, 1.6), C.grisOsc, MET, V(sx * 3.7, 4.5, 0), { seg = brazo, forma = BOLA }))
		for j, dx in ipairs({ -0.5, 0, 0.5 }) do
			table.insert(p, P("Garra" .. n .. j, V(0.35, 1.5, 0.35), C.negro2, MET,
				V(sx * 3.7 + dx, 3.3, -0.45), { seg = brazo, rot = V(20, 0, dx * 30) }))
		end
	end
	return {
		escala = 1.6, rootY = 6.5, rootSize = V(3.6, 1.4, 2.4), pasoFreq = 3.2,
		segmentos = {
			{ "Torso", "root", V(0, 7.0, 0) },
			{ "Cabeza", "Torso", V(0, 11.9, -0.2) },
			{ "BrazoIzq", "Torso", V(-3.4, 11.0, 0) },
			{ "BrazoDer", "Torso", V(3.4, 11.0, 0) },
			{ "PiernaIzq", "root", V(-1.4, 6.0, 0) },
			{ "PiernaDer", "root", V(1.4, 6.0, 0) },
		},
		ojos = { "OjoIzq", "OjoDer", "Nucleo" },
		partes = p,
	}
end

-- ================== JEFE MEGA-ARDUINO (verde, encorvado, cerebro Arduino) ==================
local function specJefe()
	local p = {
		P("Pelvis",   V(4, 1.4, 3), C.jean, TEL, V(0, 5.2, 0)),
		-- cuerpo
		P("Barriga",  V(5.2, 3.4, 4.2), C.granate, PLA, V(0, 7.4, 0.25), { seg = "Torso" }),
		P("Pecho",    V(6.4, 3.6, 4.8), C.granate, PLA, V(0, 10.2, -0.4), { seg = "Torso", rot = V(-16, 0, 0) }),
		P("Collar",   V(0.9, 4.0, 4.0), C.rojo, MET, V(0, 11.0, -2.75), { seg = "Torso", forma = CIL, rot = V(0, 90, 0) }),
		P("Nucleo",   V(1.4, 1.4, 1.4), C.neonNaranja, NEO, V(0, 11.0, -3.1), { seg = "Torso", forma = BOLA }),
		P("TuboIzq",  V(3.0, 0.55, 0.55), C.plata, MET, V(-1.4, 12.4, 0.9), { seg = "Torso", forma = CIL, rot = V(0, 0, 60) }),
		P("TuboDer",  V(3.0, 0.55, 0.55), C.plata, MET, V(1.4, 12.4, 0.9), { seg = "Torso", forma = CIL, rot = V(0, 0, -60) }),
		-- cabeza con mandíbula y cerebro Arduino
		P("Cabeza",    V(3.6, 2.6, 3.4), C.verde, PLA, V(0, 11.1, -4.6), { seg = "Cabeza" }),
		P("Mandibula", V(3.8, 1.2, 3.6), C.verde, PLA, V(0, 9.3, -4.7), { seg = "Cabeza" }),
		P("Encia",     V(3.3, 0.5, 0.4), C.granate, PLA, V(0, 9.95, -6.3), { seg = "Cabeza" }),
		P("Placa",     V(2.8, 0.25, 2.4), C.teal, PLA, V(0, 12.5, -4.6), { seg = "Cabeza" }),
		P("Chip",      V(1.0, 0.25, 0.6), C.negro, PLA, V(0.3, 12.7, -4.4), { seg = "Cabeza" }),
		P("Pines",     V(2.0, 0.3, 0.25), C.negro, PLA, V(0, 12.75, -3.6), { seg = "Cabeza" }),
	}
	for k = 0, 5 do
		local a = math.rad(k * 60)
		table.insert(p, P("Tornillo" .. k, V(0.4, 0.4, 0.4), C.plata, MET,
			V(math.cos(a) * 1.65, 11.0 + math.sin(a) * 1.65, -3.25), { seg = "Torso", forma = BOLA }))
	end
	for i = 0, 4 do
		local x = -1.2 + i * 0.6
		table.insert(p, P("DienteA" .. i, V(0.5, 0.5, 0.25), C.blanco, PLA, V(x, 10.15, -6.42), { seg = "Cabeza", rot = V(0, 0, 45) }))
		table.insert(p, P("DienteB" .. i, V(0.5, 0.5, 0.25), C.blanco, PLA, V(x + 0.3, 9.85, -6.42), { seg = "Cabeza", rot = V(0, 0, 45) }))
	end
	local leds = {
		{ C.neonRojo, V(-1.0, 12.75, -5.4) }, { C.neonVerde, V(-0.4, 12.75, -5.5) },
		{ C.neonAzul, V(0.6, 12.75, -5.4) }, { C.neonAmarillo, V(1.0, 12.75, -4.0) },
		{ C.neonNaranja, V(-0.9, 12.75, -3.9) },
	}
	for i, led in ipairs(leds) do
		table.insert(p, P("LED" .. i, V(0.32, 0.32, 0.32), led[1], NEO, led[2], { seg = "Cabeza", forma = BOLA }))
	end
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		local pierna, brazo = "Pierna" .. n, "Brazo" .. n
		-- ojos amarillos con párpado de enojo
		table.insert(p, P("Ojo" .. n,     V(1.35, 1.35, 1.35), C.neonAmarillo, NEO, V(sx * 0.85, 11.4, -6.1), { seg = "Cabeza", forma = BOLA }))
		table.insert(p, P("Parpado" .. n, V(1.7, 0.8, 0.7), C.verdeOsc, PLA, V(sx * 0.85, 11.95, -6.15), { seg = "Cabeza", rot = V(0, 0, -sx * 18) }))
		table.insert(p, P("Perno" .. n,   V(0.8, 0.35, 0.35), C.plata, MET, V(sx * 2.2, 11.6, -5.2), { seg = "Cabeza", forma = CIL }))
		table.insert(p, P("AntenaLuz" .. n, V(0.6, 0.6, 0.6), C.neonVerde, NEO, V(sx * 2.75, 11.6, -5.2), { seg = "Cabeza", forma = BOLA }))
		-- piernas (pantalón y botas)
		table.insert(p, P("Pantalon" .. n, V(1.9, 2.8, 1.9), C.jean, TEL, V(sx * 1.3, 3.4, 0), { seg = pierna }))
		table.insert(p, P("Basta" .. n,    V(2.0, 1.6, 2.0), C.jean, TEL, V(sx * 1.3, 1.5, 0), { seg = pierna }))
		table.insert(p, P("Bota" .. n,     V(2.5, 1.1, 3.3), C.cafe, PLA, V(sx * 1.3, 0.55, -0.55), { seg = pierna }))
		-- brazos enormes
		table.insert(p, P("Hombro" .. n,    V(4, 4, 4), C.verde, PLA, V(sx * 4.0, 11.0, -0.4), { seg = brazo, forma = BOLA }))
		table.insert(p, P("PernoH" .. n,    V(0.3, 1.4, 1.4), C.plata, MET, V(sx * 5.95, 11.6, -0.6), { seg = brazo, forma = CIL }))
		table.insert(p, P("BrazoSup" .. n,  V(2.4, 3.2, 2.4), C.verde, PLA, V(sx * 4.3, 8.6, -0.8), { seg = brazo }))
		table.insert(p, P("Codo" .. n,      V(2.7, 2.7, 2.7), C.verdeOsc, PLA, V(sx * 4.35, 6.9, -0.9), { seg = brazo, forma = BOLA }))
		table.insert(p, P("Antebrazo" .. n, V(2.8, 2.8, 2.8), C.verde, PLA, V(sx * 4.4, 5.3, -1.0), { seg = brazo }))
		table.insert(p, P("Mano" .. n,      V(2.4, 1.3, 2.4), C.verde, PLA, V(sx * 4.4, 3.5, -1.1), { seg = brazo }))
		table.insert(p, P("Boca" .. n,      V(0.9, 0.9, 0.9), C.neonVerde, NEO, V(sx * 4.4, 3.5, -2.35), { seg = brazo, forma = BOLA }))
		for j, dx in ipairs({ -0.8, -0.27, 0.27, 0.8 }) do
			table.insert(p, P("Dedo" .. n .. j, V(0.5, 1.4, 0.55), C.verdeOsc, PLA,
				V(sx * 4.4 + dx, 2.4, -1.9), { seg = brazo, rot = V(25, 0, 0) }))
		end
	end
	return {
		escala = 2.4, rootY = 5.2, rootSize = V(4, 1.4, 3), pasoFreq = 2.6,
		segmentos = {
			{ "Torso", "root", V(0, 5.6, 0) },
			{ "Cabeza", "Torso", V(0, 10.9, -2.7) },
			{ "BrazoIzq", "Torso", V(-4.0, 11.0, -0.4) },
			{ "BrazoDer", "Torso", V(4.0, 11.0, -0.4) },
			{ "PiernaIzq", "root", V(-1.3, 4.8, 0) },
			{ "PiernaDer", "root", V(1.3, 4.8, 0) },
		},
		ojos = { "OjoIzq", "OjoDer", "AntenaLuzIzq", "AntenaLuzDer" },
		partes = p,
	}
end

-- ================== DRON cuadricóptero (vuela y dispara) ==================
local function specDron()
	local p = {
		P("Cuerpo",  V(1.6, 0.5, 1.6),   C.grisOsc, MET, V(0, 14, 0)),
		P("Tapa",    V(1.1, 0.3, 1.1),   C.negro,   PLA, V(0, 14.38, 0)),
		P("Placa",   V(0.9, 0.08, 0.9),  C.teal,    PLA, V(0, 14.57, 0)),
		P("Bateria", V(0.55, 0.35, 1.0), C.azulPlaca, PLA, V(0, 13.6, 0.1)),
		P("Camara",  V(0.5, 0.5, 0.5),   C.negro,   PLA, V(0, 13.7, -0.75), { forma = BOLA }),
		P("Lente",   V(0.28, 0.28, 0.28), C.neonRojo, NEO, V(0, 13.7, -0.98), { forma = BOLA }),
		P("Brazo1",  V(3.6, 0.18, 0.25), C.negro, PLA, V(0, 14, 0), { rot = V(0, 45, 0) }),
		P("Brazo2",  V(3.6, 0.18, 0.25), C.negro, PLA, V(0, 14, 0), { rot = V(0, -45, 0) }),
		P("PataIzq", V(0.12, 0.12, 1.4), C.negro, PLA, V(-0.5, 13.35, 0)),
		P("PataDer", V(0.12, 0.12, 1.4), C.negro, PLA, V(0.5, 13.35, 0)),
	}
	local segmentos = {}
	for i, e in ipairs({ { 1, -1 }, { -1, -1 }, { -1, 1 }, { 1, 1 } }) do
		local x, z = e[1] * 1.27, e[2] * 1.27
		local seg = "Helice" .. i
		table.insert(segmentos, { seg, "root", V(x, 14.42, z) })
		table.insert(p, P("Motor" .. i, V(0.4, 0.45, 0.45), C.oscuro, MET, V(x, 14.15, z), { forma = CIL, rot = V(0, 0, 90) }))
		table.insert(p, P("Aspa" .. i,  V(1.7, 0.05, 0.2), C.negro, PLA, V(x, 14.42, z), { seg = seg }))
		table.insert(p, P("AspaB" .. i, V(0.2, 0.05, 1.7), C.negro, PLA, V(x, 14.42, z), { seg = seg, transp = 0.4 }))
		-- luces de navegación: rojas adelante, verdes atrás
		table.insert(p, P("Led" .. i, V(0.2, 0.2, 0.2), (e[2] < 0) and C.neonRojo or C.neonVerde, NEO, V(x, 13.95, z), { forma = BOLA }))
	end
	return {
		escala = 1.3, rootY = 14, rootSize = V(1.6, 0.5, 1.6), anim = "dron",
		segmentos = segmentos,
		ojos = { "Lente" },
		partes = p,
	}
end

-- ================== JEFE FINAL: el robot gigante del hechicero ARDUNOL ==================
-- Armadura morada de Ardunol con detalles dorados y turquesa Arduino,
-- núcleo de cristal agrietado en el pecho, visor en V, cuernos dorados,
-- brazo izquierdo-cañón y brazo derecho de PURA ENERGÍA con un puño gigante.
local function specJefeFinal()
	local morado, moradoOsc = RGB(70, 40, 120), RGB(38, 24, 66)
	local placa, oro = RGB(190, 185, 210), RGB(230, 180, 50)
	local cian, cianClaro = RGB(70, 220, 255), RGB(170, 245, 255)
	local naranja = RGB(255, 140, 40)
	local p = {
		P("Pelvis",     V(4.2, 1.4, 3.0), moradoOsc, MET, V(0, 5.6, 0)),
		P("CintoOro",   V(4.5, 0.4, 3.2), oro, MET, V(0, 6.3, 0), { seg = "Torso" }),
		P("Abdomen",    V(3.6, 2.0, 2.8), moradoOsc, MET, V(0, 7.4, 0), { seg = "Torso" }),
		P("Pecho",      V(7.0, 4.2, 4.4), morado, MET, V(0, 10.3, 0), { seg = "Torso" }),
		P("PlacaPecho", V(5.6, 3.4, 0.5), placa, MET, V(0, 10.3, -2.35), { seg = "Torso" }),
		P("BordeOro",   V(5.9, 0.3, 0.6), oro, MET, V(0, 12.05, -2.35), { seg = "Torso" }),
		P("BordeOro2",  V(5.9, 0.3, 0.6), oro, MET, V(0, 8.55, -2.35), { seg = "Torso" }),
		-- núcleo de cristal agrietado
		P("Nucleo",     V(1.9, 1.9, 1.9), cian, NEO, V(0, 10.3, -2.65), { seg = "Torso", forma = BOLA }),
		P("Cuello",     V(1.8, 0.8, 1.8), moradoOsc, MET, V(0, 12.7, -0.1), { seg = "Torso" }),
		-- mochila con propulsores
		P("Mochila",    V(4.2, 3.2, 1.6), moradoOsc, MET, V(0, 10.4, 2.9), { seg = "Torso" }),
		P("PlacaArduino", V(2.6, 1.8, 0.15), C.teal, PLA, V(0, 10.6, 3.75), { seg = "Torso" }),
		-- cabeza (casco)
		P("Cabeza",     V(3.4, 2.6, 3.2), morado, MET, V(0, 14.2, -0.3), { seg = "Cabeza" }),
		P("Frente",     V(3.0, 0.7, 0.5), placa, MET, V(0, 15.0, -1.85), { seg = "Cabeza" }),
		P("Mandibula",  V(2.6, 0.9, 0.7), moradoOsc, MET, V(0, 13.1, -1.75), { seg = "Cabeza" }),
		P("Rejilla",    V(1.8, 0.25, 0.1), cian, NEO, V(0, 13.1, -2.12), { seg = "Cabeza" }),
		P("Cresta",     V(0.45, 0.9, 3.0), C.teal, NEO, V(0, 15.7, -0.2), { seg = "Cabeza" }),
	}
	-- grietas del cristal (pedacitos brillantes alrededor del núcleo)
	local grietas = { { -1.1, 0.7, 30 }, { 1.0, 0.9, -25 }, { -0.8, -0.9, -40 }, { 1.2, -0.6, 50 }, { 0.2, 1.3, 10 }, { -0.1, -1.3, 70 } }
	for k, g in ipairs(grietas) do
		table.insert(p, P("Grieta" .. k, V(0.35, 1.0, 0.3), cianClaro, NEO, V(g[1], 10.3 + g[2], -2.62),
			{ seg = "Torso", rot = V(0, 0, g[3]) }))
	end
	-- toberas de la mochila
	for _, l in ipairs(LADOS) do
		local sx = l[1]
		table.insert(p, P("Tobera" .. l[2], V(1.0, 1.0, 1.0), naranja, NEO, V(sx * 1.2, 8.7, 3.0), { seg = "Torso", forma = BOLA }))
	end
	for _, l in ipairs(LADOS) do
		local sx, n = l[1], l[2]
		local pierna, brazo = "Pierna" .. n, "Brazo" .. n
		-- visor en V y cuernos dorados
		table.insert(p, P("Visor" .. n,  V(1.5, 0.45, 0.2), cian, NEO, V(sx * 0.75, 14.15, -1.93), { seg = "Cabeza", rot = V(0, 0, sx * 14) }))
		table.insert(p, P("Cuerno" .. n, V(0.5, 2.0, 0.5), oro, MET, V(sx * 1.75, 15.6, -0.3), { seg = "Cabeza", rot = V(0, 0, -sx * 28) }))
		table.insert(p, P("Oreja" .. n,  V(0.4, 1.2, 1.2), placa, MET, V(sx * 1.85, 14.1, -0.3), { seg = "Cabeza", forma = CIL }))
		-- piernas
		table.insert(p, P("Muslo" .. n,    V(1.8, 2.6, 1.9), moradoOsc, MET, V(sx * 1.5, 4.1, 0), { seg = pierna }))
		table.insert(p, P("Rodillera" .. n, V(2.0, 1.3, 0.9), placa, MET, V(sx * 1.5, 2.95, -0.9), { seg = pierna }))
		table.insert(p, P("Canilla" .. n,  V(2.0, 2.4, 2.2), morado, MET, V(sx * 1.5, 1.75, 0), { seg = pierna }))
		table.insert(p, P("Raya" .. n,     V(0.2, 2.0, 0.1), C.teal, NEO, V(sx * 1.5, 1.75, -1.12), { seg = pierna }))
		table.insert(p, P("Propulsor" .. n, V(1.1, 0.5, 1.1), naranja, NEO, V(sx * 1.5, 1.2, 1.15), { seg = pierna }))
		table.insert(p, P("Pie" .. n,      V(2.6, 0.9, 3.6), moradoOsc, MET, V(sx * 1.5, 0.45, -0.5), { seg = pierna }))
		-- hombros (iguales en los dos lados)
		table.insert(p, P("Hombro" .. n,   V(2.8, 2.8, 2.8), moradoOsc, MET, V(sx * 4.2, 11.6, 0), { seg = brazo, forma = BOLA }))
		table.insert(p, P("Hombrera" .. n, V(3.2, 1.5, 3.6), morado, MET, V(sx * 4.5, 12.8, 0), { seg = brazo, rot = V(0, 0, -sx * 12) }))
		table.insert(p, P("BordeHombrera" .. n, V(3.3, 0.25, 3.7), oro, MET, V(sx * 4.5, 12.05, 0), { seg = brazo, rot = V(0, 0, -sx * 12) }))
	end
	-- brazo IZQUIERDO: armadura + cañón (dispara los orbes)
	local bi = "BrazoIzq"
	table.insert(p, P("BrazoSupIzq",  V(1.8, 3.0, 1.8), moradoOsc, MET, V(-4.5, 9.4, 0), { seg = bi }))
	table.insert(p, P("CodoIzq",      V(2.0, 2.0, 2.0), placa, MET, V(-4.6, 7.8, 0), { seg = bi, forma = BOLA }))
	table.insert(p, P("AntebrazoIzq", V(2.4, 3.0, 2.4), morado, MET, V(-4.7, 6.1, -0.2), { seg = bi }))
	table.insert(p, P("CanonIzq",     V(2.6, 1.4, 1.4), moradoOsc, MET, V(-4.7, 4.6, -0.9), { seg = bi, forma = CIL, rot = GIRO_Z }))
	table.insert(p, P("AnilloCanon",  V(0.4, 1.7, 1.7), oro, MET, V(-4.7, 4.6, -2.0), { seg = bi, forma = CIL, rot = GIRO_Z }))
	table.insert(p, P("BocaIzq",      V(1.0, 1.0, 1.0), cian, NEO, V(-4.7, 4.6, -2.3), { seg = bi, forma = BOLA }))
	-- brazo DERECHO: energía pura con un puño gigante
	local bd = "BrazoDer"
	table.insert(p, P("EnergiaSup",   V(1.7, 3.0, 1.7), cian, NEO, V(4.5, 9.4, 0), { seg = bd, transp = 0.35 }))
	table.insert(p, P("AnilloA",      V(2.1, 0.3, 2.1), oro, MET, V(4.5, 10.3, 0), { seg = bd }))
	table.insert(p, P("CodoDer",      V(2.0, 2.0, 2.0), cianClaro, NEO, V(4.6, 7.8, 0), { seg = bd, forma = BOLA, transp = 0.2 }))
	table.insert(p, P("EnergiaAnt",   V(2.1, 3.0, 2.1), cian, NEO, V(4.7, 6.1, -0.2), { seg = bd, transp = 0.3 }))
	table.insert(p, P("AnilloB",      V(2.5, 0.3, 2.5), oro, MET, V(4.7, 5.2, -0.2), { seg = bd }))
	table.insert(p, P("BocaDer",      V(2.8, 2.4, 2.8), cianClaro, NEO, V(4.7, 3.9, -0.4), { seg = bd, transp = 0.1 })) -- el PUÑO
	for j, dx in ipairs({ -0.9, -0.3, 0.3, 0.9 }) do
		table.insert(p, P("Nudillo" .. j, V(0.5, 0.55, 0.6), cian, NEO, V(4.7 + dx, 4.6, -1.85), { seg = bd, forma = BOLA }))
	end
	return {
		escala = 3.4, rootY = 5.6, rootSize = V(4.2, 1.4, 3), pasoFreq = 2.2,
		segmentos = {
			{ "Torso", "root", V(0, 6.0, 0) },
			{ "Cabeza", "Torso", V(0, 12.8, -0.2) },
			{ "BrazoIzq", "Torso", V(-4.2, 11.6, 0) },
			{ "BrazoDer", "Torso", V(4.2, 11.6, 0) },
			{ "PiernaIzq", "root", V(-1.5, 5.2, 0) },
			{ "PiernaDer", "root", V(1.5, 5.2, 0) },
		},
		ojos = { "VisorIzq", "VisorDer", "Nucleo", "Rejilla" },
		partes = p,
	}
end

local SPECS = {
	Dron = specDron(),
	Seguidor = specSeguidor(),
	Arana = specArana(),
	Soldado = specSoldado(),
	Tanque = specTanque(),
	Chatarra = specChatarra(),
	Coloso = specColoso(),
	Jefe = specJefe(),
	-- Jefe de la gran final: el robot gigante del hechicero Ardunol (diseño propio)
	JefeFinal = specJefeFinal(),
}

-- ===== Humanoid común =====
local function crearHumanoid(modelo, hipHeight)
	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.HipHeight = hipHeight
	hum.UseJumpPower = true
	hum.JumpPower = 45
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum.Parent = modelo
	return hum
end

local function soldar(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = b
end

-- ===== Modelo personalizado (de ServerStorage > ModelosRobots) =====
local function construirPersonalizado(tipo, plantilla, posSuelo)
	local modelo = plantilla:Clone()
	modelo.Name = "Robot" .. tipo

	-- Seguridad: se borra cualquier script que traiga (por ejemplo de la Toolbox)
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end

	local cf, size = modelo:GetBoundingBox()
	local fondo = cf.Position.Y - size.Y / 2
	modelo:PivotTo(modelo:GetPivot() + (posSuelo - Vector3.new(cf.Position.X, fondo, cf.Position.Z)))

	local alturaRoot = math.max(1.5, size.Y * 0.35)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Transparency = 1
	root.CanCollide = true
	root.Size = Vector3.new(math.max(1, size.X * 0.5), 1.5, math.max(1, size.Z * 0.5))
	root.CFrame = CFrame.new(posSuelo + Vector3.new(0, alturaRoot, 0))
	root.Parent = modelo

	local partes, ojos = {}, {}
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") and p ~= root then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			soldar(root, p)
			partes[p.Name] = partes[p.Name] or p
			if p.Material == NEO or p.Name:find("Ojo") then
				p:SetAttribute("ColorBase", p.Color)
				table.insert(ojos, p)
			end
		end
	end

	local hum = crearHumanoid(modelo, alturaRoot - 0.75)
	modelo.PrimaryPart = root
	modelo:SetAttribute("Animado", false)
	modelo:SetAttribute("Escala", size.Y / 10)
	return modelo, root, hum, partes, ojos
end

-- ===== Construir un robot parado sobre "posSuelo" =====
-- Devuelve: modelo, root, humanoid, partes (por nombre), ojos (lista)
function M.construir(tipo, posSuelo)
	local carpeta = ServerStorage:FindFirstChild("ModelosRobots")
	local plantilla = carpeta and carpeta:FindFirstChild(tipo)
	if plantilla and plantilla:IsA("Model") then
		return construirPersonalizado(tipo, plantilla, posSuelo)
	end

	local spec = SPECS[tipo]
	local s = spec.escala

	local modelo = Instance.new("Model")
	modelo.Name = "Robot" .. tipo

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = spec.rootSize * s
	root.Transparency = 1
	root.CanCollide = true
	root.CFrame = CFrame.new(posSuelo + V(0, spec.rootY * s, 0))
	root.Parent = modelo

	-- Articulaciones: una "ancla" invisible por segmento, unida con Motor6D
	local anclas = { root = root }
	for _, sg in ipairs(spec.segmentos or {}) do
		local nombre, padre, posJ = sg[1], sg[2], sg[3]
		local cfJ = CFrame.new(posSuelo + posJ * s)
		local ancla = Instance.new("Part")
		ancla.Name = "Seg" .. nombre
		ancla.Size = V(0.4, 0.4, 0.4)
		ancla.Transparency = 1
		ancla.CanCollide = false
		ancla.CanQuery = false
		ancla.CanTouch = false
		ancla.Massless = true
		ancla.CFrame = cfJ
		ancla.Parent = modelo
		local m6 = Instance.new("Motor6D")
		m6.Name = "J_" .. nombre
		m6.Part0 = anclas[padre]
		m6.Part1 = ancla
		m6.C0 = anclas[padre].CFrame:ToObjectSpace(cfJ)
		m6.C1 = CFrame.new()
		if sg.dir then  -- dirección de la pata (para animar la araña)
			m6:SetAttribute("DirX", sg.dir[1])
			m6:SetAttribute("DirZ", sg.dir[2])
		end
		m6.Parent = ancla
		anclas[nombre] = ancla
	end

	local partes = {}
	for _, p in ipairs(spec.partes) do
		local part = Instance.new("Part")
		part.Name = p.nombre
		part.Size = p.size * s
		part.Color = p.color
		part.Material = p.mat
		if p.forma then part.Shape = p.forma end
		part.Transparency = p.transp or 0
		part.CanCollide = false
		part.Massless = true
		local giro = p.rot and CFrame.Angles(math.rad(p.rot.X), math.rad(p.rot.Y), math.rad(p.rot.Z)) or CFrame.new()
		part.CFrame = CFrame.new(posSuelo + p.pos * s) * giro
		part.Parent = modelo
		soldar(anclas[p.seg or "root"] or root, part)
		partes[p.nombre] = part
	end

	local hum = crearHumanoid(modelo, (spec.rootY - spec.rootSize.Y / 2) * s)
	modelo.PrimaryPart = root
	modelo:SetAttribute("Animado", spec.segmentos ~= nil)
	modelo:SetAttribute("Anim", spec.anim or "humanoide")
	modelo:SetAttribute("PasoFreq", spec.pasoFreq or 5)
	modelo:SetAttribute("Escala", s)

	local ojos = {}
	for _, n in ipairs(spec.ojos) do
		local o = partes[n]
		if o then
			o:SetAttribute("ColorBase", o.Color)
			table.insert(ojos, o)
		end
	end

	return modelo, root, hum, partes, ojos
end

return M
