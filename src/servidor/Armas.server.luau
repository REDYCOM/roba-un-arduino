--=====================================================================
--  ARMAS ESPECIALES (servidor)
--  Bazuca (estilo M1) y Láser: se desbloquean con los retos.
--  Escopeta de chispas, Pistola Tesla y Granada condensador: salen de las
--  cajas que sueltan los robots grandes.
--  - Usa TU modelo si pones una Tool con ese nombre (y con "Handle") en
--    ServerStorage; si no, crea una de piezas.
--  - Respeta equipos (no daña a tu propio equipo) usando TeamNumber.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function getRemote(nombre)
	local r = ReplicatedStorage:FindFirstChild(nombre)
	if not r then
		r = Instance.new("RemoteEvent"); r.Name = nombre; r.Parent = ReplicatedStorage
	end
	return r
end
local dispararEvent = getRemote("DispararArma")
local Registro = require(script.Parent:WaitForChild("RegistroDano"))

--====================== CONFIGURACIÓN (edítala) ======================
local CONFIG = {
	Bazuca   = { dano = 60, radio = 12, recarga = 3.0, alcance = 300, velocidad = 150 },
	Laser    = { dano = 100, recarga = 0.6, alcance = 400 },
	Escopeta = { dano = 18, perdigones = 7, dispersion = 0.09, recarga = 0.9, alcance = 90 },
	Tesla    = { dano = 50, danoCadena = 35, saltos = 4, radioCadena = 22, ayuda = 12, recarga = 1.1, alcance = 160 },
	Granada  = { dano = 75, radio = 11, recarga = 1.5, fusible = 1.8, velocidad = 70, arco = 25 },
}
--=====================================================================

local RGB = Color3.fromRGB
local MET, PLA, NEO, MAD = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Wood
local CIL, BOLA = Enum.PartType.Cylinder, Enum.PartType.Ball
local Z90 = CFrame.Angles(0, math.rad(90), 0)  -- cilindro apuntando hacia adelante

local function mismoEquipo(a, b)
	local t1, t2 = a:GetAttribute("TeamNumber"), b:GetAttribute("TeamNumber")
	if not t1 or not t2 then return false end
	return t1 == t2
end

-- ===== Construir las armas de piezas (si no pones las tuyas) =====
-- Cada pieza se une al mango con un Weld llamado "Union": el cliente mueve su C0
-- para animar el arma (retroceso de la corredera, pulsos, etc.)
local function pieza(tool, handle, nombre, size, color, material, offset, forma)
	local p = Instance.new("Part")
	p.Name = nombre; p.Size = size; p.Color = color; p.Material = material
	if forma then p.Shape = forma end
	p.CanCollide = false; p.Massless = true
	p.CFrame = handle.CFrame * offset; p.Parent = tool
	local w = Instance.new("Weld")
	w.Name = "Union"; w.Part0 = handle; w.Part1 = p; w.C0 = offset; w.Parent = p
	return p
end
local function nuevaTool(nombre, sizeMango, colorMango, matMango, formaMango)
	local tool = Instance.new("Tool")
	tool.Name = nombre; tool.CanBeDropped = false; tool.RequiresHandle = true
	local h = Instance.new("Part")
	h.Name = "Handle"; h.Size = sizeMango; h.Color = colorMango; h.Material = matMango
	if formaMango then h.Shape = formaMango end
	h.CanCollide = false; h.Parent = tool
	return tool, h
end

-- BAZUCA estilo M1: tubo verde oliva largo, boca acampanada, mira de anillo, dos empuñaduras
local function crearBazuca()
	local OLIVA, OLIVA2 = RGB(78, 88, 44), RGB(60, 68, 34)
	local NEGRO, GRIS = RGB(22, 22, 22), RGB(58, 58, 56)
	local tool, h = nuevaTool("Bazuca", Vector3.new(0.35, 1.0, 0.6), GRIS, MET)  -- empuñadura delantera
	pieza(tool, h, "Tubo",     Vector3.new(7.2, 0.75, 0.75), OLIVA, MET, CFrame.new(0, 0.85, -0.6) * Z90, CIL)
	pieza(tool, h, "Campana1", Vector3.new(0.35, 1.0, 1.0),  OLIVA, MET, CFrame.new(0, 0.85, -4.3) * Z90, CIL)
	pieza(tool, h, "Campana2", Vector3.new(0.3, 1.3, 1.3),   OLIVA, MET, CFrame.new(0, 0.85, -4.6) * Z90, CIL)
	pieza(tool, h, "Campana3", Vector3.new(0.25, 1.6, 1.6),  OLIVA, MET, CFrame.new(0, 0.85, -4.85) * Z90, CIL)
	pieza(tool, h, "Hueco",    Vector3.new(0.05, 1.35, 1.35), NEGRO, PLA, CFrame.new(0, 0.85, -4.96) * Z90, CIL)
	for i, z in ipairs({ -2.4, -0.4, 1.4 }) do
		pieza(tool, h, "Banda" .. i, Vector3.new(0.18, 0.85, 0.85), OLIVA2, MET, CFrame.new(0, 0.85, z) * Z90, CIL)
	end
	pieza(tool, h, "Cola", Vector3.new(0.4, 0.85, 0.85), OLIVA2, MET, CFrame.new(0, 0.85, 3.1) * Z90, CIL)
	-- mira trasera de anillo (aro de 8 piezas + cruz)
	local centro = Vector3.new(-0.6, 1.5, 2.7)
	for k = 0, 7 do
		local a = math.rad(k * 45)
		pieza(tool, h, "Aro" .. k, Vector3.new(0.1, 0.45, 0.08), OLIVA2, MET,
			CFrame.new(centro + Vector3.new(math.cos(a) * 0.55, math.sin(a) * 0.55, 0)) * CFrame.Angles(0, 0, a))
	end
	pieza(tool, h, "CruzH", Vector3.new(1.1, 0.06, 0.06), OLIVA2, MET, CFrame.new(centro))
	pieza(tool, h, "CruzV", Vector3.new(0.06, 1.1, 0.06), OLIVA2, MET, CFrame.new(centro))
	pieza(tool, h, "MiraPie", Vector3.new(0.12, 0.45, 0.12), OLIVA2, MET, CFrame.new(-0.45, 1.05, 2.7))
	-- segunda empuñadura, gatillo y abrazadera
	pieza(tool, h, "Empunadura2", Vector3.new(0.35, 1.1, 0.5), OLIVA, MET, CFrame.new(0, 0.05, 1.5) * CFrame.Angles(math.rad(-12), 0, 0))
	pieza(tool, h, "Guarda",      Vector3.new(0.12, 0.12, 0.7), GRIS, MET, CFrame.new(0, -0.25, -0.45))
	pieza(tool, h, "Gatillo",     Vector3.new(0.08, 0.3, 0.08), NEGRO, MET, CFrame.new(0, 0.05, -0.35))
	pieza(tool, h, "Abrazadera",  Vector3.new(0.3, 0.4, 0.6), OLIVA2, MET, CFrame.new(0, 0.5, 0))
	return tool
end

local function crearLaser()
	local tool, h = nuevaTool("Laser", Vector3.new(0.9, 1, 4.5), RGB(35, 40, 55), MET)
	pieza(tool, h, "Neon",   Vector3.new(0.35, 0.35, 3.4), RGB(80, 220, 255), NEO, CFrame.new(0, 0.45, 0))
	pieza(tool, h, "Emisor", Vector3.new(0.7, 0.7, 0.6),   RGB(120, 240, 255), NEO, CFrame.new(0, 0, -2.3))
	pieza(tool, h, "Mango",  Vector3.new(0.6, 1.4, 0.7),   RGB(45, 50, 65), MET, CFrame.new(0, -1.1, 1.2))
	return tool
end

-- ESCOPETA DE CHISPAS: doble cañón, culata de madera, franja naranja
local function crearEscopeta()
	local MADERA, METAL = RGB(105, 65, 35), RGB(45, 47, 52)
	local tool, h = nuevaTool("Escopeta", Vector3.new(0.35, 0.9, 0.55), MADERA, MAD)
	pieza(tool, h, "CanonIzq", Vector3.new(4.2, 0.32, 0.32), METAL, MET, CFrame.new(-0.17, 0.55, -1.9) * Z90, CIL)
	pieza(tool, h, "CanonDer", Vector3.new(4.2, 0.32, 0.32), METAL, MET, CFrame.new(0.17, 0.55, -1.9) * Z90, CIL)
	pieza(tool, h, "Cajon",    Vector3.new(0.55, 0.5, 1.4),  METAL, MET, CFrame.new(0, 0.45, 0.2))
	pieza(tool, h, "Culata",   Vector3.new(0.45, 0.7, 2.0),  MADERA, MAD, CFrame.new(0, 0.2, 1.6) * CFrame.Angles(math.rad(10), 0, 0))
	pieza(tool, h, "Bomba",    Vector3.new(0.6, 0.45, 1.0),  MADERA, MAD, CFrame.new(0, 0.25, -1.4))
	pieza(tool, h, "Franja",   Vector3.new(0.08, 0.08, 3.0), RGB(255, 140, 30), NEO, CFrame.new(0, 0.75, -1.9))
	pieza(tool, h, "Boca",     Vector3.new(0.1, 0.75, 0.75), RGB(255, 140, 30), NEO, CFrame.new(0, 0.55, -4.0) * Z90, CIL)
	return tool
end

-- PISTOLA TESLA: bobina de cobre y esfera eléctrica
local function crearTesla()
	local AZUL, COBRE = RGB(35, 45, 80), RGB(200, 110, 50)
	local tool, h = nuevaTool("Tesla", Vector3.new(0.35, 0.9, 0.55), RGB(30, 30, 35), MET)
	pieza(tool, h, "Cuerpo",  Vector3.new(0.6, 0.6, 1.6),   AZUL, MET, CFrame.new(0, 0.5, -0.3))
	pieza(tool, h, "Nucleo",  Vector3.new(1.4, 0.4, 0.4),   RGB(30, 30, 35), MET, CFrame.new(0, 0.5, -1.65) * Z90, CIL)
	for i, z in ipairs({ -1.15, -1.45, -1.75, -2.05 }) do
		pieza(tool, h, "Bobina" .. i, Vector3.new(0.18, 0.75, 0.75), COBRE, MET, CFrame.new(0, 0.5, z) * Z90, CIL)
	end
	pieza(tool, h, "Esfera",  Vector3.new(0.65, 0.65, 0.65), RGB(140, 220, 255), NEO, CFrame.new(0, 0.5, -2.6), BOLA)
	pieza(tool, h, "Bateria", Vector3.new(0.6, 0.28, 0.28),  RGB(40, 120, 220), PLA, CFrame.new(0, 0.95, -0.3) * Z90, CIL)
	pieza(tool, h, "Antena",  Vector3.new(0.08, 0.6, 0.08),  RGB(30, 30, 35), MET, CFrame.new(0, 1.0, 0.35))
	pieza(tool, h, "Chispa",  Vector3.new(0.2, 0.2, 0.2),    RGB(140, 220, 255), NEO, CFrame.new(0, 1.35, 0.35), BOLA)
	return tool
end

-- GRANADA CONDENSADOR: un capacitor electrolítico gigante
local AZUL_CAP = RGB(30, 90, 200)
local function crearGranada()
	local tool, h = nuevaTool("Granada", Vector3.new(1.0, 0.7, 0.7), AZUL_CAP, PLA, CIL)
	pieza(tool, h, "Tapa",   Vector3.new(0.06, 0.66, 0.66), RGB(200, 200, 205), MET, CFrame.new(0.53, 0, 0), CIL)
	pieza(tool, h, "Franja", Vector3.new(0.9, 0.3, 0.05),   RGB(220, 230, 240), PLA, CFrame.new(0, 0, 0.35))
	pieza(tool, h, "PataA",  Vector3.new(0.6, 0.05, 0.05),  RGB(200, 200, 205), MET, CFrame.new(-0.8, 0, 0.12))
	pieza(tool, h, "PataB",  Vector3.new(0.6, 0.05, 0.05),  RGB(200, 200, 205), MET, CFrame.new(-0.8, 0, -0.12))
	return tool
end

for nombre, crear in pairs({
	Bazuca = crearBazuca, Laser = crearLaser, Escopeta = crearEscopeta, Tesla = crearTesla, Granada = crearGranada,
}) do
	if not ServerStorage:FindFirstChild(nombre) then crear().Parent = ServerStorage end
end

-- ===== Efectos visuales (CanQuery = false: los efectos no detienen balas) =====
local function efectoPart()
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	return p
end

local function destello(pos, color, rango, tiempo)
	local p = efectoPart()
	p.Transparency = 1; p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(pos); p.Parent = workspace
	local l = Instance.new("PointLight")
	l.Color = color; l.Brightness = 8; l.Range = rango; l.Parent = p
	Debris:AddItem(p, tiempo or 0.25)
	return p
end

local function emitirChispas(pos, color, cantidad)
	local base = destello(pos, color, 6, 0.6)
	local att = Instance.new("Attachment"); att.Parent = base
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.3, 0.7)
	sp.Speed = NumberRange.new(18, 45)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Rate = 0
	sp.Color = ColorSequence.new(color)
	sp.Parent = att
	sp:Emit(cantidad or 30)
end

local function trazador(a, b, color, grosor, tiempo)
	local dist = (b - a).Magnitude
	if dist < 0.05 then return end
	local p = efectoPart()
	p.Material = NEO; p.Color = color
	p.Size = Vector3.new(grosor, grosor, dist)
	p.CFrame = CFrame.new(a:Lerp(b, 0.5), b)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(tiempo), { Transparency = 1 }):Play()
	Debris:AddItem(p, tiempo + 0.05)
end

local function efectoExplosion(pos, radio)
	destello(pos, RGB(255, 180, 80), radio * 2.2, 0.35)
	local bola = efectoPart()
	bola.Shape = BOLA; bola.Material = NEO; bola.Color = RGB(255, 150, 50)
	bola.Size = Vector3.new(2, 2, 2); bola.CFrame = CFrame.new(pos); bola.Parent = workspace
	TweenService:Create(bola, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(radio * 1.6, radio * 1.6, radio * 1.6), Transparency = 1 }):Play()
	Debris:AddItem(bola, 0.5)
	local onda = efectoPart()
	onda.Shape = CIL; onda.Material = NEO; onda.Color = RGB(255, 220, 120)
	onda.Size = Vector3.new(0.5, 3, 3); onda.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	onda.Parent = workspace
	TweenService:Create(onda, TweenInfo.new(0.4), { Size = Vector3.new(0.5, radio * 2.6, radio * 2.6), Transparency = 1 }):Play()
	Debris:AddItem(onda, 0.5)
	emitirChispas(pos, RGB(255, 180, 80), 45)
end

-- ===== Daño =====
local cooldowns = {}
local function puedeDisparar(plr, arma)
	cooldowns[plr] = cooldowns[plr] or {}
	local now = tick()
	local recarga = CONFIG[arma].recarga * (plr:GetAttribute("MultRecarga") or 1)  -- runa Furia
	if cooldowns[plr][arma] and (now - cooldowns[plr][arma]) < recarga - 0.05 then
		return false
	end
	cooldowns[plr][arma] = now
	return true
end

-- Daña lo que golpeó un rayo: jugador enemigo o robot. Devuelve true si hizo daño.
local function danarImpacto(plr, inst, dano)
	if not inst then return false end
	local modelo = inst:FindFirstAncestorOfClass("Model")
	local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	local victim = Players:GetPlayerFromCharacter(modelo)
	if victim == plr or (victim and mismoEquipo(plr, victim)) then return false end
	local total = dano * (plr:GetAttribute("MultDano") or 1)  -- runa Sobrecarga
	if not victim then  -- robot: registrar para puntos y gran final
		if not Registro.puedeDanar(plr, modelo) then return false end
		Registro.registrar(plr, modelo, total)
	else
		Registro.marcarJugador(plr, hum)  -- puntos si lo elimina
	end
	hum:TakeDamage(total)
	return true
end

local function danoArea(plr, centro, cfgBase)
	local cfg = { radio = cfgBase.radio, dano = cfgBase.dano * (plr:GetAttribute("MultDano") or 1) }
	for _, otro in ipairs(Players:GetPlayers()) do
		if otro ~= plr and not mismoEquipo(plr, otro) then
			local ch = otro.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local d = (hrp.Position - centro).Magnitude
				if d <= cfg.radio then
					Registro.marcarJugador(plr, hum)
					hum:TakeDamage(cfg.dano * (1 - (d / cfg.radio) * 0.6))
				end
			end
		end
	end
	-- Robots enemigos (los grandes reciben daño desde más lejos por su tamaño)
	local robots = workspace:FindFirstChild("RobotsEnemigos")
	if robots then
		for _, m in ipairs(robots:GetChildren()) do
			local hum = m:FindFirstChildOfClass("Humanoid")
			local r = m.PrimaryPart
			if hum and r and hum.Health > 0 then
				local alcance = cfg.radio + r.Size.X / 2
				local d = (r.Position - centro).Magnitude
				if d <= alcance and Registro.puedeDanar(plr, m) then
					local dd = cfg.dano * (1 - (d / alcance) * 0.6)
					Registro.registrar(plr, m, dd)
					hum:TakeDamage(dd)
				end
			end
		end
	end
end

-- Empujón con BodyVelocity: funciona aunque el personaje lo controle el cliente
local function impulso(hrp, vel)
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.P = 1e4
	bv.Velocity = vel
	bv.Parent = hrp
	Debris:AddItem(bv, 0.2)
end

-- Onda expansiva: empuja a TODOS (incluido el que dispara y sus aliados)
local function empujar(centro, radio, fuerzaBase)
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local delta = hrp.Position - centro
			local d = delta.Magnitude
			if d <= radio then
				local dir = (d > 0.1) and delta.Unit or Vector3.new(0, 1, 0)
				local factor = 1 - (d / radio)
				impulso(hrp, dir * (fuerzaBase * factor) + Vector3.new(0, 45 * factor, 0))
			end
		end
	end
end

-- Lista de blancos válidos (enemigos vivos y robots) para la Tesla
local function blancos(plr)
	local lista = {}
	for _, otro in ipairs(Players:GetPlayers()) do
		if otro ~= plr and not mismoEquipo(plr, otro) then
			local ch = otro.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local r = ch and ch:FindFirstChild("HumanoidRootPart")
			if hum and r and hum.Health > 0 then
				table.insert(lista, { modelo = ch, hum = hum, pos = r.Position, jugador = otro })
			end
		end
	end
	local robots = workspace:FindFirstChild("RobotsEnemigos")
	if robots then
		for _, m in ipairs(robots:GetChildren()) do
			local hum = m:FindFirstChildOfClass("Humanoid")
			local r = m.PrimaryPart
			if hum and r and hum.Health > 0 and Registro.puedeDanar(plr, m) then
				table.insert(lista, { modelo = m, hum = hum, pos = r.Position })
			end
		end
	end
	return lista
end

-- ===== Preparar un disparo: origen, dirección y raycast =====
local function apuntar(plr, target, alcance)
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local base = hrp.Position + Vector3.new(0, 1.5, 0)
	local dir = target - base
	if dir.Magnitude < 1 then return nil end
	dir = dir.Unit
	local origin = hrp.Position + Vector3.new(0, 1.2, 0) + dir * 2.5
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = { char }
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local res = alcance and workspace:Raycast(origin, dir * alcance, rp)
	return origin, dir, rp, res
end

-- ===== Disparos =====
local function dispararBazuca(plr, target)
	local cfg = CONFIG.Bazuca
	local origin, dir, _, res = apuntar(plr, target, cfg.alcance)
	if not origin then return end
	local impacto = res and res.Position or (origin + dir * cfg.alcance)

	destello(origin, RGB(255, 160, 60), 8, 0.1)  -- fogonazo

	-- rebufo: nube de humo por detrás del tubo
	local humoBase = destello(origin - dir * 6, RGB(255, 200, 150), 4, 1.3)
	local attH = Instance.new("Attachment"); attH.Parent = humoBase
	local humo = Instance.new("ParticleEmitter")
	humo.Texture = "rbxasset://textures/particles/smoke_main.dds"
	humo.Lifetime = NumberRange.new(0.6, 1.1); humo.Rate = 0
	humo.Speed = NumberRange.new(4, 10); humo.SpreadAngle = Vector2.new(180, 180)
	humo.Size = NumberSequence.new(1.5, 4); humo.Transparency = NumberSequence.new(0.3, 1)
	humo.Color = ColorSequence.new(RGB(200, 200, 200))
	humo.Parent = attH
	humo:Emit(14)

	local cohete = efectoPart()
	cohete.Size = Vector3.new(0.7, 0.7, 2.2)
	cohete.Color = RGB(255, 140, 40); cohete.Material = NEO
	cohete.CFrame = CFrame.new(origin, impacto); cohete.Parent = workspace
	local att = Instance.new("Attachment"); att.Parent = cohete
	local fuego = Instance.new("ParticleEmitter")
	fuego.Texture = "rbxasset://textures/particles/fire_main.dds"
	fuego.Lifetime = NumberRange.new(0.2, 0.4); fuego.Rate = 120
	fuego.Speed = NumberRange.new(0); fuego.Size = NumberSequence.new(1.4, 0)
	fuego.Color = ColorSequence.new(RGB(255, 180, 60), RGB(255, 80, 20))
	fuego.Parent = att

	local tviaje = math.clamp((impacto - origin).Magnitude / cfg.velocidad, 0.05, 2)
	local tw = TweenService:Create(cohete, TweenInfo.new(tviaje, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(impacto, impacto + dir) })
	tw:Play()
	tw.Completed:Connect(function()
		cohete:Destroy()
		efectoExplosion(impacto, cfg.radio)
		danoArea(plr, impacto, cfg)     -- daño solo a enemigos y robots
		empujar(impacto, cfg.radio, 70) -- empuje a TODOS (incluido tú y aliados)
	end)
	Debris:AddItem(cohete, tviaje + 1)
end

local function dispararLaser(plr, target)
	local cfg = CONFIG.Laser
	local origin, dir, _, res = apuntar(plr, target, cfg.alcance)
	if not origin then return end
	local impacto = res and res.Position or (origin + dir * cfg.alcance)
	if res then danarImpacto(plr, res.Instance, cfg.dano) end

	destello(origin, RGB(120, 240, 255), 7, 0.08)
	local dist = (impacto - origin).Magnitude
	local rayo = efectoPart()
	rayo.Material = NEO; rayo.Color = RGB(120, 240, 255)
	rayo.Size = Vector3.new(0.4, 0.4, dist)
	rayo.CFrame = CFrame.new(origin:Lerp(impacto, 0.5), impacto)
	rayo.Parent = workspace
	local halo = Instance.new("PointLight"); halo.Color = rayo.Color; halo.Brightness = 4; halo.Range = 8; halo.Parent = rayo
	TweenService:Create(rayo, TweenInfo.new(0.18), { Transparency = 1, Size = Vector3.new(0.05, 0.05, dist) }):Play()
	Debris:AddItem(rayo, 0.2)
	emitirChispas(impacto, RGB(120, 240, 255), 14)
end

local function dispararEscopeta(plr, target)
	local cfg = CONFIG.Escopeta
	local origin, dir, rp = apuntar(plr, target, nil)
	if not origin then return end
	destello(origin, RGB(255, 170, 60), 9, 0.08)
	for _ = 1, cfg.perdigones do
		local desvio = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * cfg.dispersion * 2
		local d = (dir + desvio).Unit
		local res = workspace:Raycast(origin, d * cfg.alcance, rp)
		local impacto = res and res.Position or (origin + d * cfg.alcance)
		if res then
			danarImpacto(plr, res.Instance, cfg.dano)
			emitirChispas(impacto, RGB(255, 170, 60), 5)
		end
		trazador(origin, impacto, RGB(255, 210, 100), 0.1, 0.08)
	end
end

local function rayoElectrico(a, b)
	local puntos = { a }
	local tramos = 6
	for i = 1, tramos - 1 do
		local desvio = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2.4
		table.insert(puntos, a:Lerp(b, i / tramos) + desvio)
	end
	table.insert(puntos, b)
	for i = 1, #puntos - 1 do
		trazador(puntos[i], puntos[i + 1], RGB(150, 225, 255), 0.22, 0.16)
	end
	destello(b, RGB(150, 225, 255), 10, 0.15)
end

local function dispararTesla(plr, target)
	local cfg = CONFIG.Tesla
	local origin, dir, _, res = apuntar(plr, target, cfg.alcance)
	if not origin then return end
	local impacto = res and res.Position or (origin + dir * cfg.alcance)
	local lista = blancos(plr)
	destello(origin, RGB(150, 225, 255), 8, 0.1)

	-- primer blanco: el que tocó el rayo, o el más cercano al impacto (ayuda de puntería)
	local actual
	if res then
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		for _, o in ipairs(lista) do
			if o.modelo == m then actual = o end
		end
	end
	if not actual then
		local mejor = cfg.ayuda
		for _, o in ipairs(lista) do
			local d = (o.pos - impacto).Magnitude
			if d < mejor then mejor = d; actual = o end
		end
	end
	if not actual then
		rayoElectrico(origin, impacto)
		return
	end

	-- cadena: salta al blanco más cercano que aún no recibió descarga
	local mult = plr:GetAttribute("MultDano") or 1
	local golpeados, desde, dano = {}, origin, cfg.dano
	for _ = 0, cfg.saltos do
		golpeados[actual.modelo] = true
		rayoElectrico(desde, actual.pos)
		if not actual.jugador then Registro.registrar(plr, actual.modelo, dano * mult)
		else Registro.marcarJugador(plr, actual.hum) end
		actual.hum:TakeDamage(dano * mult)
		emitirChispas(actual.pos, RGB(150, 225, 255), 10)
		local siguiente, mejor = nil, cfg.radioCadena
		for _, o in ipairs(lista) do
			if not golpeados[o.modelo] then
				local d = (o.pos - actual.pos).Magnitude
				if d < mejor then mejor = d; siguiente = o end
			end
		end
		if not siguiente then break end
		desde, actual, dano = actual.pos, siguiente, cfg.danoCadena
	end
end

local function lanzarGranada(plr, target)
	local cfg = CONFIG.Granada
	local origin, dir = apuntar(plr, target, nil)
	if not origin then return end

	local g = Instance.new("Part")
	g.Name = "GranadaLanzada"
	g.Shape = CIL; g.Size = Vector3.new(1.0, 0.7, 0.7)
	g.Color = AZUL_CAP; g.Material = PLA
	g.CanQuery = false
	g.CFrame = CFrame.new(origin)
	g.Parent = workspace
	pcall(function() g:SetNetworkOwner(nil) end)
	g.AssemblyLinearVelocity = dir * cfg.velocidad + Vector3.new(0, cfg.arco, 0)
	g.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
	local luz = Instance.new("PointLight")
	luz.Color = RGB(255, 60, 60); luz.Brightness = 4; luz.Range = 8; luz.Parent = g

	task.spawn(function()
		local t0 = os.clock()
		while g.Parent and os.clock() - t0 < cfg.fusible do
			luz.Enabled = not luz.Enabled  -- parpadea cada vez más rápido
			local resto = cfg.fusible - (os.clock() - t0)
			task.wait(math.clamp(resto * 0.15, 0.05, 0.25))
		end
		if g.Parent then
			local pos = g.Position
			g:Destroy()
			efectoExplosion(pos, cfg.radio)
			danoArea(plr, pos, cfg)
			empujar(pos, cfg.radio, 60)
		end
	end)
	Debris:AddItem(g, cfg.fusible + 2)
end

local DISPARO = {
	Bazuca = dispararBazuca,
	Laser = dispararLaser,
	Escopeta = dispararEscopeta,
	Tesla = dispararTesla,
	Granada = lanzarGranada,
}

dispararEvent.OnServerEvent:Connect(function(plr, arma, target)
	if type(arma) ~= "string" or typeof(target) ~= "Vector3" then return end
	local fn = DISPARO[arma]
	if not fn then return end
	-- solo si de verdad tiene esa arma EQUIPADA (evita trampas)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (char and char:FindFirstChild(arma) and hum and hum.Health > 0) then return end
	if puedeDisparar(plr, arma) then fn(plr, target) end
end)

Players.PlayerRemoving:Connect(function(plr) cooldowns[plr] = nil end)

print("✅ Armas especiales listas: Bazuca, Láser, Escopeta, Tesla, Granada")
