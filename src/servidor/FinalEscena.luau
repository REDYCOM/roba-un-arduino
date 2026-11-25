--=====================================================================
--  ESCENA DE LA GRAN FINAL (ModuleScript)
--  · ARDUNOL: el hechicero malvado. Flota sobre la arena, se burla de los
--    jugadores y huye cuando pierde.
--  · ARDUINO SUPREMO: trofeo épico (placa Arduino UNO detallada que gira
--    sobre un pedestal dorado) que aparece frente al equipo ganador.
--  Robots.server lo usa así:
--    Escena.aparecerArdunol(pos, mirarA)  Escena.hablar(texto)
--    Escena.rayoArdunol(destino)          Escena.ardunolHuye(gano)
--    Escena.crearTrofeo(posSuelo, mirarA, nEquipo, nombre, color, celebrar)
--=====================================================================

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local M = {}

local V = Vector3.new
local RGB = Color3.fromRGB
local CIL, BOLA = Enum.PartType.Cylinder, Enum.PartType.Ball
local MAT = Enum.Material

local ORO = RGB(255, 200, 60)
local TEAL = RGB(0, 129, 132)
local MAGIA = RGB(200, 60, 255)

-- pieza anclada, sin colisión (solo decoración)
local function pieza(padre, nombre, size, color, mat, cf, forma, transp)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Size = size; p.Color = color; p.Material = mat
	if forma then p.Shape = forma end
	p.Transparency = transp or 0
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = cf
	p.Parent = padre
	return p
end
local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- cilindro "parado"

-- Suelda todas las piezas de un modelo a una "raíz" anclada: así, para moverlo
-- entero, el servidor solo actualiza UNA pieza (menos lag en la red).
local function soldarA(modelo, raiz)
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("BasePart") and d ~= raiz then
			d.Anchored = false
			d.Massless = true
			local w = Instance.new("WeldConstraint"); w.Part0 = raiz; w.Part1 = d; w.Parent = d
		end
	end
end

local function particulas(padre, color, tasa, vel, tam, textura)
	local att = Instance.new("Attachment"); att.Parent = padre
	local e = Instance.new("ParticleEmitter")
	e.Texture = textura or "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.Rate = tasa; e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Speed = NumberRange.new(vel * 0.5, vel); e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(tam, 0); e.LightEmission = 1
	e.Parent = att
	return e
end

local function explosionColor(pos, color, radio)
	local bola = pieza(workspace, "Explosion", V(2, 2, 2), color, MAT.Neon, CFrame.new(pos), BOLA)
	TweenService:Create(bola, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = V(radio, radio, radio), Transparency = 1 }):Play()
	Debris:AddItem(bola, 0.6)
	local luz = Instance.new("PointLight"); luz.Color = color; luz.Brightness = 8; luz.Range = radio * 3; luz.Parent = bola
	local e = particulas(bola, color, 0, 30, 1.2)
	e:Emit(40)
end

--=====================================================================
--  ARDUNOL, EL HECHICERO
--=====================================================================
local ardunol = nil
local burbuja = nil

function M.aparecerArdunol(pos, mirarA)
	if ardunol then ardunol:Destroy() end
	local modelo = Instance.new("Model")
	modelo.Name = "Ardunol"
	local s = 3.2 -- tamaño
	local base = CFrame.lookAt(pos, V(mirarA.X, pos.Y, mirarA.Z))
	local function at(x, y, z) return base * CFrame.new(x * s, y * s, z * s) end
	local tunica, tunicaOsc = RGB(70, 25, 105), RGB(40, 14, 62)

	-- túnica (escalonada, se ensancha abajo) y capa
	pieza(modelo, "Tunica1", V(1.2, 2.6, 2.6) * s, tunicaOsc, MAT.Fabric, at(0, 0.6, 0) * VERTICAL, CIL)
	pieza(modelo, "Tunica2", V(1.2, 2.1, 2.1) * s, tunica, MAT.Fabric, at(0, 1.8, 0) * VERTICAL, CIL)
	pieza(modelo, "Tunica3", V(1.0, 1.7, 1.7) * s, tunica, MAT.Fabric, at(0, 2.9, 0) * VERTICAL, CIL)
	pieza(modelo, "Torso", V(1.6, 1.4, 1.0) * s, tunica, MAT.Fabric, at(0, 4.0, 0))
	pieza(modelo, "Cinto", V(1.65, 0.22, 1.05) * s, ORO, MAT.Foil, at(0, 3.4, 0))
	pieza(modelo, "Hebilla", V(0.35, 0.3, 0.1) * s, MAGIA, MAT.Neon, at(0, 3.4, -0.55))
	pieza(modelo, "Capa", V(2.1, 4.2, 0.15) * s, tunicaOsc, MAT.Fabric, at(0, 2.6, 0.62) * CFrame.Angles(math.rad(-8), 0, 0))
	-- cabeza encapuchada: cara oscura con ojos que brillan y barba
	pieza(modelo, "Capucha", V(1.25, 1.25, 1.25) * s, tunicaOsc, MAT.Fabric, at(0, 5.15, 0.05), BOLA)
	pieza(modelo, "Cara", V(0.85, 0.85, 0.85) * s, RGB(15, 10, 20), MAT.SmoothPlastic, at(0, 5.05, -0.2), BOLA)
	pieza(modelo, "OjoIzq", V(0.18, 0.12, 0.1) * s, MAGIA, MAT.Neon, at(-0.17, 5.12, -0.6))
	pieza(modelo, "OjoDer", V(0.18, 0.12, 0.1) * s, MAGIA, MAT.Neon, at(0.17, 5.12, -0.6))
	pieza(modelo, "Barba", V(0.7, 1.1, 0.3) * s, RGB(225, 225, 230), MAT.Fabric, at(0, 4.45, -0.48) * CFrame.Angles(math.rad(10), 0, 0))
	-- sombrero de mago (ala + cono escalonado + banda dorada + estrella)
	pieza(modelo, "Ala", V(0.15, 2.3, 2.3) * s, tunicaOsc, MAT.Fabric, at(0, 5.7, 0) * VERTICAL, CIL)
	local alto = 5.8
	for i, d in ipairs({ 1.15, 0.95, 0.78, 0.6, 0.44, 0.3, 0.18 }) do
		pieza(modelo, "Cono" .. i, V(0.32, d, d) * s, tunica, MAT.Fabric,
			at(0.04 * i * i * 0.08, alto, 0.02 * i) * VERTICAL, CIL)
		alto += 0.3
	end
	pieza(modelo, "Banda", V(0.2, 1.18, 1.18) * s, ORO, MAT.Foil, at(0, 5.85, 0) * VERTICAL, CIL)
	pieza(modelo, "Estrella", V(0.35, 0.35, 0.35) * s, RGB(255, 240, 120), MAT.Neon, at(0.3, 6.5, -0.42), BOLA)
	-- brazos: el derecho sostiene el báculo, el izquierdo lanza magia
	pieza(modelo, "MangaDer", V(0.55, 1.5, 0.55) * s, tunica, MAT.Fabric, at(1.05, 3.9, -0.2) * CFrame.Angles(math.rad(30), 0, math.rad(15)))
	pieza(modelo, "MangaIzq", V(0.55, 1.5, 0.55) * s, tunica, MAT.Fabric, at(-1.1, 4.3, -0.4) * CFrame.Angles(math.rad(60), 0, math.rad(-35)))
	local manoIzq = pieza(modelo, "ManoIzq", V(0.4, 0.4, 0.4) * s, MAGIA, MAT.Neon, at(-1.5, 4.9, -0.9), BOLA)
	pieza(modelo, "Baculo", V(0.18, 5.6, 0.18) * s, RGB(90, 55, 30), MAT.Wood, at(1.3, 3.2, -0.45))
	pieza(modelo, "Garra", V(0.5, 0.5, 0.5) * s, ORO, MAT.Foil, at(1.3, 6.05, -0.45), BOLA)
	local orbe = pieza(modelo, "Orbe", V(0.75, 0.75, 0.75) * s, MAGIA, MAT.Neon, at(1.3, 6.45, -0.45), BOLA)

	-- magia: luces y partículas
	local luz = Instance.new("PointLight"); luz.Color = MAGIA; luz.Brightness = 5; luz.Range = 40; luz.Parent = orbe
	particulas(orbe, MAGIA, 25, 6, 1.4)
	particulas(manoIzq, RGB(255, 120, 255), 18, 5, 1)
	local niebla = particulas(modelo.Tunica1, RGB(90, 30, 130), 12, 3, 6, "rbxasset://textures/particles/smoke_main.dds")
	niebla.Lifetime = NumberRange.new(1.5, 2.5)
	niebla.Transparency = NumberSequence.new(0.5, 1)

	-- nombre arriba
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 50); bb.StudsOffset = V(0, 4 * s, 0); bb.AlwaysOnTop = true
	bb.MaxDistance = 600; bb.Adornee = modelo.Capucha; bb.Parent = modelo.Capucha
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = "🧙 ARDUNOL"; t.TextColor3 = RGB(220, 120, 255); t.TextStrokeTransparency = 0
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.Parent = bb

	-- burbuja para hablar
	burbuja = Instance.new("BillboardGui")
	burbuja.Size = UDim2.new(0, 520, 0, 110); burbuja.StudsOffset = V(0, 6.2 * s, 0); burbuja.AlwaysOnTop = true
	burbuja.MaxDistance = 600; burbuja.Enabled = false
	burbuja.Adornee = modelo.Capucha; burbuja.Parent = modelo.Capucha
	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.new(1, 0, 1, 0); fondo.BackgroundColor3 = RGB(25, 8, 40); fondo.BackgroundTransparency = 0.15
	fondo.Parent = burbuja
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 18); uc.Parent = fondo
	local st = Instance.new("UIStroke"); st.Color = MAGIA; st.Thickness = 3; st.Parent = fondo
	local dicho = Instance.new("TextLabel")
	dicho.Name = "Texto"
	dicho.Size = UDim2.new(1, -24, 1, -16); dicho.Position = UDim2.new(0, 12, 0, 8); dicho.BackgroundTransparency = 1
	dicho.Text = ""; dicho.TextColor3 = RGB(255, 230, 255); dicho.TextWrapped = true; dicho.TextScaled = true
	dicho.Font = Enum.Font.FredokaOne; dicho.Parent = fondo

	-- aparece entre humo morado
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("BasePart") then
			local tr = d.Transparency
			d.Transparency = 1
			TweenService:Create(d, TweenInfo.new(1.2), { Transparency = tr }):Play()
		end
	end
	-- flota subiendo y bajando: todo soldado a una raíz que se mueve
	local raiz = pieza(modelo, "Raiz", V(1, 1, 1), MAGIA, MAT.SmoothPlastic, base, nil, 1)
	soldarA(modelo, raiz)
	modelo.PrimaryPart = raiz
	modelo.Parent = workspace
	explosionColor(pos + V(0, 3 * s, 0), MAGIA, 26)
	task.spawn(function()
		local t0 = os.clock()
		while raiz.Parent do
			raiz.CFrame = base * CFrame.new(0, math.sin((os.clock() - t0) * 1.3) * 1.5, 0)
			task.wait(1 / 20)
		end
	end)
	ardunol = modelo
	return modelo
end

-- Ardunol dice algo (burbuja sobre su cabeza)
local idHabla = 0
function M.hablar(texto, duracion)
	if not (ardunol and burbuja and burbuja.Parent) then return end
	idHabla += 1
	local miId = idHabla
	burbuja.Enabled = true
	burbuja:FindFirstChild("Texto", true).Text = texto
	task.delay(duracion or 4, function()
		if miId == idHabla and burbuja and burbuja.Parent then burbuja.Enabled = false end
	end)
end

-- rayo mágico desde el orbe de su báculo hasta un punto (al despertar al robot)
function M.rayoArdunol(destino)
	local orbe = ardunol and ardunol:FindFirstChild("Orbe")
	if not orbe then return end
	local o = orbe.Position
	local rayo = pieza(workspace, "RayoMagia", V(2.2, 2.2, (destino - o).Magnitude), MAGIA, MAT.Neon,
		CFrame.lookAt(o:Lerp(destino, 0.5), destino), nil, 0.1)
	TweenService:Create(rayo, TweenInfo.new(1.5), { Transparency = 1, Size = V(0.2, 0.2, rayo.Size.Z) }):Play()
	Debris:AddItem(rayo, 1.6)
	explosionColor(destino, MAGIA, 30)
end

-- se acabó la final: si perdió, grita y desaparece; si ganó, se ríe y se va
function M.ardunolHuye(perdio)
	if not ardunol then return end
	local modelo = ardunol
	if perdio then
		M.hablar("¡¡NOOOO!! ¡Mi ARDUINO SUPREMO!... ¡Esto no se queda así!", 3.5)
	else
		M.hablar("¡JA, JA, JA! ¡El ARDUINO SUPREMO sigue siendo MÍO!", 3.5)
	end
	task.wait(3.6)
	if modelo.Parent then
		explosionColor(modelo:GetPivot().Position + V(0, 8, 0), MAGIA, 40)
		modelo:Destroy()
	end
	if ardunol == modelo then ardunol = nil end
end

function M.quitarArdunol()
	if ardunol then ardunol:Destroy(); ardunol = nil end
end

--=====================================================================
--  ARDUINO SUPREMO (trofeo)
--=====================================================================

-- Placa Arduino UNO detallada. Se arma acostada (componentes hacia +Y)
-- alrededor de "centro" y luego se para. Devuelve el Model y su eje.
local function placaArduino(padre, centroCF, s)
	local placa = Instance.new("Model")
	placa.Name = "ArduinoSupremo"
	-- todo se ubica relativo a la placa acostada; "parar" la pone vertical mirando a -Z
	local parar = centroCF * CFrame.Angles(math.rad(-90), 0, 0)
	local function at(x, y, z) return parar * CFrame.new(x * s, y * s, z * s) end
	local P = function(nombre, size, color, mat, x, y, z, forma, giro)
		local cf = at(x, y, z) * (giro or CFrame.new())
		return pieza(placa, nombre, size * s, color, mat, cf, forma)
	end
	local negro, plata, blanco = RGB(25, 25, 28), RGB(200, 202, 208), RGB(240, 240, 240)

	local tablero = P("Placa", V(6.9, 0.16, 5.3), TEAL, MAT.SmoothPlastic, 0, 0, 0)
	-- marco dorado (trofeo)
	P("MarcoA", V(7.3, 0.3, 0.2), ORO, MAT.Foil, 0, 0, 2.75)
	P("MarcoB", V(7.3, 0.3, 0.2), ORO, MAT.Foil, 0, 0, -2.75)
	P("MarcoC", V(0.2, 0.3, 5.7), ORO, MAT.Foil, 3.55, 0, 0)
	P("MarcoD", V(0.2, 0.3, 5.7), ORO, MAT.Foil, -3.55, 0, 0)
	-- conectores
	P("USB", V(1.6, 1.1, 1.2), plata, MAT.Metal, -3.1, 0.63, 1.35)
	P("USBHueco", V(0.1, 0.6, 0.8), negro, MAT.SmoothPlastic, -3.92, 0.63, 1.35)
	P("JackDC", V(1.4, 1.1, 0.9), negro, MAT.SmoothPlastic, -3.15, 0.63, -1.75)
	P("JackHueco", V(0.1, 0.5, 0.5), RGB(60, 60, 60), MAT.Metal, -3.88, 0.63, -1.75, CIL)
	-- tiras de pines (headers)
	P("HeaderDigital", V(4.8, 0.85, 0.28), negro, MAT.SmoothPlastic, 0.8, 0.5, 2.45)
	P("HeaderPower", V(2.0, 0.85, 0.28), negro, MAT.SmoothPlastic, -0.7, 0.5, -2.45)
	P("HeaderAnalog", V(1.6, 0.85, 0.28), negro, MAT.SmoothPlastic, 1.6, 0.5, -2.45)
	for i = 0, 13 do
		P("PinD" .. i, V(0.12, 0.06, 0.12), ORO, MAT.Foil, -1.45 + i * 0.33, 0.95, 2.45)
	end
	for i = 0, 5 do
		P("PinA" .. i, V(0.12, 0.06, 0.12), ORO, MAT.Foil, 0.95 + i * 0.26, 0.95, -2.45)
		P("PinP" .. i, V(0.12, 0.06, 0.12), ORO, MAT.Foil, -1.5 + i * 0.32, 0.95, -2.45)
	end
	-- microcontrolador ATmega328P (DIP) con sus patitas
	P("ATmega328P", V(3.5, 0.35, 0.95), negro, MAT.SmoothPlastic, 1.3, 0.3, -1.0)
	P("PatasA", V(3.4, 0.22, 0.14), plata, MAT.Metal, 1.3, 0.2, -1.53)
	P("PatasB", V(3.4, 0.22, 0.14), plata, MAT.Metal, 1.3, 0.2, -0.47)
	P("Muesca", V(0.15, 0.05, 0.15), RGB(60, 60, 60), MAT.SmoothPlastic, -0.3, 0.49, -1.0, CIL, CFrame.Angles(0, 0, math.rad(90)))
	-- textos: en láminas invisibles delante de la placa (así nunca salen de cabeza)
	-- (en la placa parada: x = derecha, y = arriba, -z = hacia el que mira)
	local function lamina(nombre, x, y, z, ancho, alto, lineas)
		local l = pieza(placa, nombre, V(ancho * s, alto * s, 0.05), blanco, MAT.SmoothPlastic,
			centroCF * CFrame.new(x * s, y * s, -z * s), nil, 1)
		local g = Instance.new("SurfaceGui"); g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 40; g.Parent = l
		local lista = Instance.new("UIListLayout"); lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
		lista.VerticalAlignment = Enum.VerticalAlignment.Center; lista.Parent = g
		for _, ln in ipairs(lineas) do
			local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, ln[2], 0); t.Text = ln[1]; t.TextColor3 = ln[3] or blanco
			t.Font = ln[4] or Enum.Font.GothamBlack; t.TextScaled = true; t.Parent = g
		end
	end
	lamina("TextoChip", 1.3, -1.0, 0.5, 3.2, 0.8, { { "ATMEGA328P", 1, RGB(200, 200, 200), Enum.Font.Code } })
	lamina("Logo", 0.75, 0.75, 0.12, 2.4, 1.9,{ { "∞", 0.4 }, { "ARDUINO", 0.28 }, { "UNO", 0.32 } })
	-- otros componentes
	P("ChipUSB", V(0.6, 0.14, 0.6), negro, MAT.SmoothPlastic, -1.5, 0.15, 1.35)
	P("Cristal", V(0.9, 0.35, 0.35), plata, MAT.Metal, -1.0, 0.25, 0.25)
	P("Regulador", V(0.6, 0.3, 0.5), negro, MAT.SmoothPlastic, -2.3, 0.23, -0.9)
	P("Capacitor1", V(0.65, 0.55, 0.55), plata, MAT.Metal, -2.2, 0.4, -1.9, CIL, CFrame.Angles(0, 0, math.rad(90)))
	P("Capacitor2", V(0.65, 0.55, 0.55), plata, MAT.Metal, -1.5, 0.4, -1.9, CIL, CFrame.Angles(0, 0, math.rad(90)))
	P("ICSP", V(0.55, 0.5, 0.8), negro, MAT.SmoothPlastic, 3.0, 0.33, 0.0)
	P("ResetBase", V(0.5, 0.25, 0.5), plata, MAT.Metal, -2.4, 0.2, 2.1)
	P("ResetBoton", V(0.32, 0.32, 0.32), RGB(220, 40, 40), MAT.SmoothPlastic, -2.4, 0.38, 2.1, BOLA)
	-- LEDs
	P("LED_ON", V(0.22, 0.12, 0.14), RGB(80, 255, 90), MAT.Neon, 2.6, 0.15, 1.1)
	P("LED_L", V(0.22, 0.12, 0.14), RGB(255, 160, 40), MAT.Neon, -0.5, 0.15, 1.75)
	P("LED_TX", V(0.22, 0.12, 0.14), RGB(255, 230, 60), MAT.Neon, -0.5, 0.15, 1.35)
	P("LED_RX", V(0.22, 0.12, 0.14), RGB(255, 230, 60), MAT.Neon, -0.5, 0.15, 1.15)
	-- agujeros de montaje
	for i, e in ipairs({ { -2.9, 2.2 }, { 3.0, 2.2 }, { 3.0, -1.9 }, { -2.0, 0.9 } }) do
		P("Agujero" .. i, V(0.05, 0.3, 0.3), ORO, MAT.Foil, e[1], 0.08, e[2], CIL, CFrame.Angles(0, 0, math.rad(90)))
	end
	placa.Parent = padre
	return placa
end

-- disco/aro de energía (como las runas)
local function aro(padre, nombre, diametro, color, cf)
	return pieza(padre, nombre, V(0.25, diametro, diametro), color, MAT.Neon, cf, CIL, 0.55)
end

-- gira un grupo de piezas alrededor de un eje vertical que pasa por "centro"
-- (el servidor manda pocas actualizaciones; cada pieza va soldada a un eje)
local function hacerGirar(modelo, centroCF, velocidad, flotar)
	local eje = pieza(modelo, "Eje", V(0.5, 0.5, 0.5), ORO, MAT.Neon, centroCF, nil, 1)
	soldarA(modelo, eje)
	task.spawn(function()
		local t0 = os.clock()
		while eje.Parent do
			local tt = os.clock() - t0
			eje.CFrame = centroCF * CFrame.new(0, flotar and math.sin(tt * 1.6) * 0.8 or 0, 0)
				* CFrame.Angles(0, tt * velocidad, 0)
			task.wait(1 / 30)
		end
	end)
	return eje
end

local trofeoActual = nil

-- Crea el trofeo parado en "posSuelo", mirando hacia "mirarA".
-- celebrar = true: aparición épica con rayo dorado y fuegos artificiales.
function M.crearTrofeo(posSuelo, mirarA, nEquipo, nombreEquipo, colorEquipo, celebrar)
	if trofeoActual then trofeoActual:Destroy() end
	local modelo = Instance.new("Model")
	modelo.Name = "TrofeoArduinoSupremo"
	local base = CFrame.lookAt(posSuelo, V(mirarA.X, posSuelo.Y, mirarA.Z))
	local function at(x, y, z) return base * CFrame.new(x, y, z) end
	local marmol = RGB(30, 28, 38)

	-- pedestal escalonado de mármol con bordes dorados y anillos del color del equipo
	local pedestal = Instance.new("Model"); pedestal.Name = "Pedestal"; pedestal.Parent = modelo
	pieza(pedestal, "Escalon1", V(1.4, 13, 13), marmol, MAT.Marble, at(0, 0.7, 0) * VERTICAL, CIL)
	pieza(pedestal, "Borde1", V(0.35, 13.4, 13.4), ORO, MAT.Foil, at(0, 1.45, 0) * VERTICAL, CIL)
	pieza(pedestal, "Escalon2", V(1.2, 10, 10), marmol, MAT.Marble, at(0, 2.2, 0) * VERTICAL, CIL)
	pieza(pedestal, "Borde2", V(0.35, 10.4, 10.4), ORO, MAT.Foil, at(0, 2.85, 0) * VERTICAL, CIL)
	pieza(pedestal, "Columna", V(6, 4, 4), ORO, MAT.Foil, at(0, 6, 0) * VERTICAL, CIL)
	for i, y in ipairs({ 4.3, 6, 7.7 }) do
		pieza(pedestal, "AnilloEquipo" .. i, V(0.3, 4.4, 4.4), colorEquipo, MAT.Neon, at(0, y, 0) * VERTICAL, CIL)
	end
	pieza(pedestal, "Copa", V(0.8, 7, 7), ORO, MAT.Foil, at(0, 9.3, 0) * VERTICAL, CIL)
	pieza(pedestal, "CopaLuz", V(0.2, 7.3, 7.3), colorEquipo, MAT.Neon, at(0, 9.75, 0) * VERTICAL, CIL)
	-- placa con el nombre de los campeones
	local placaNombre = pieza(pedestal, "PlacaCampeones", V(7.5, 1.6, 0.3), ORO, MAT.Foil, at(0, 2.2, -5.05))
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.Parent = placaNombre
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1
	tl.Text = "🏆 CAMPEONES: EQUIPO " .. string.upper(nombreEquipo) .. " 🏆"
	tl.TextColor3 = RGB(40, 25, 5); tl.TextScaled = true; tl.Font = Enum.Font.FredokaOne; tl.Parent = sg

	-- la placa ARDUINO SUPREMO flotando y girando sobre la copa
	local centroPlaca = at(0, 16.5, 0)
	local girador = Instance.new("Model"); girador.Name = "Girador"; girador.Parent = modelo
	placaArduino(girador, centroPlaca, 1.6)
	local eje = hacerGirar(girador, centroPlaca, 0.7, true)
	local luz = Instance.new("PointLight"); luz.Color = ORO; luz.Brightness = 6; luz.Range = 45; luz.Parent = eje
	local brillo = particulas(eje, ORO, 30, 6, 1.3)
	brillo.SpreadAngle = Vector2.new(180, 180)

	-- aros de energía que giran alrededor (como las runas)
	local aros = Instance.new("Model"); aros.Name = "Aros"; aros.Parent = modelo
	aro(aros, "Aro1", 15, ORO, centroPlaca)
	hacerGirar(aros, centroPlaca, 1.8, true)
	local aros2 = Instance.new("Model"); aros2.Name = "Aros2"; aros2.Parent = modelo
	aro(aros2, "Aro2", 15, colorEquipo, centroPlaca * CFrame.Angles(0, math.pi / 2, 0))
	hacerGirar(aros2, centroPlaca, -1.8, true)

	-- cartel de felicitación
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 560, 0, 130); bb.StudsOffset = V(0, 9, 0); bb.AlwaysOnTop = true
	bb.MaxDistance = 400; bb.Adornee = eje; bb.Parent = eje
	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0.6, 0); t1.BackgroundTransparency = 1
	t1.Text = "🏆 ¡FELICIDADES, EQUIPO " .. string.upper(nombreEquipo) .. "! 🏆"
	t1.TextColor3 = ORO; t1.TextStrokeTransparency = 0; t1.TextScaled = true; t1.Font = Enum.Font.FredokaOne
	t1.Parent = bb
	local t2 = Instance.new("TextLabel")
	t2.Position = UDim2.new(0, 0, 0.6, 0); t2.Size = UDim2.new(1, 0, 0.4, 0); t2.BackgroundTransparency = 1
	t2.Text = "Recuperaron el ARDUINO SUPREMO"
	t2.TextColor3 = colorEquipo; t2.TextStrokeTransparency = 0; t2.TextScaled = true; t2.Font = Enum.Font.FredokaOne
	t2.Parent = bb
	modelo:SetAttribute("Equipo", nEquipo)

	if celebrar then
		-- aparición: todo se "materializa" mientras cae un rayo dorado del cielo
		for _, d in ipairs(modelo:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "Eje" then
				local tr = d.Transparency
				d.Transparency = 1
				TweenService:Create(d, TweenInfo.new(2.2, Enum.EasingStyle.Quad), { Transparency = tr }):Play()
			end
		end
		local pilar = pieza(workspace, "PilarDorado", V(140, 9, 9), ORO, MAT.Neon, at(0, 70, 0) * VERTICAL, CIL, 0.1)
		TweenService:Create(pilar, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = V(140, 0.5, 0.5), Transparency = 1 }):Play()
		Debris:AddItem(pilar, 2.6)
		local onda = pieza(workspace, "Onda", V(0.3, 4, 4), ORO, MAT.Neon, at(0, 0.5, 0) * VERTICAL, CIL, 0.2)
		TweenService:Create(onda, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = V(0.3, 90, 90), Transparency = 1 }):Play()
		Debris:AddItem(onda, 1.3)
		explosionColor(at(0, 16, 0).Position, ORO, 30)

		-- fuegos artificiales alrededor durante 12 segundos
		task.spawn(function()
			local colores = { ORO, colorEquipo, RGB(255, 255, 255), RGB(255, 90, 200), RGB(90, 220, 255) }
			local fin = os.clock() + 12
			while os.clock() < fin and modelo.Parent do
				local a = math.random() * math.pi * 2
				local r = 10 + math.random() * 20
				local p = at(math.cos(a) * r, 25 + math.random() * 20, math.sin(a) * r).Position
				local c = colores[math.random(#colores)]
				-- cohete que sube y explota
				local cohete = pieza(workspace, "Cohete", V(0.5, 0.5, 2), c, MAT.Neon,
					CFrame.lookAt(V(p.X, posSuelo.Y + 1, p.Z), p), nil, 0)
				TweenService:Create(cohete, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = CFrame.lookAt(p, p + V(0, 1, 0)) }):Play()
				task.delay(0.6, function()
					cohete:Destroy()
					explosionColor(p, c, 14)
				end)
				task.wait(0.35)
			end
		end)
	end

	modelo.Parent = workspace
	trofeoActual = modelo
	return modelo
end

-- mueve el trofeo (por ejemplo, de la arena a la base del ganador)
function M.trofeoActual()
	return trofeoActual
end

return M
