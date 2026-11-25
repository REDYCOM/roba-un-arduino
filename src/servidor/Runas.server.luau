--=====================================================================
--  RUNAS TEMPORALES (servidor)
--  Aparecen en el mapa con un haz de luz. Quien las toca recibe un efecto:
--    ⚡ Turbo       velocidad ×1.8 (15 s)
--    ⚔️ Sobrecarga  doble daño con bazuca, láser y armas de caja (15 s)
--    🛡️ Escudo      invencible (8 s)
--    🔋 Batería     vida al máximo (al instante)
--    🔥 Furia       recarga ultra rápida (12 s)
--  Si tomas la misma runa otra vez, se alarga el tiempo.
--  El profe puede soltar una cerca suyo con [U].
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local OWNER_USERID = 9330695994

--====================== CONFIGURACIÓN (edítala) ======================
local CONFIG = {
	INTERVALO = 20,         -- cada cuántos segundos intenta aparecer una runa
	MAX_ACTIVAS = 3,        -- runas en el mapa al mismo tiempo
	DURACION_EN_MAPA = 45,  -- si nadie la toma, desaparece
}
--=====================================================================

local RGB = Color3.fromRGB
local RUNAS = {
	Turbo      = { icono = "⚡", nombre = "TURBO",      color = RGB(255, 220, 60),  dur = 15, desc = "¡Velocidad ×1.8!" },
	Sobrecarga = { icono = "⚔️", nombre = "SOBRECARGA", color = RGB(255, 60, 60),   dur = 15, desc = "¡Doble daño!" },
	Escudo     = { icono = "🛡️", nombre = "ESCUDO",     color = RGB(80, 170, 255),  dur = 8,  desc = "¡Invencible!" },
	Bateria    = { icono = "🔋", nombre = "BATERÍA",    color = RGB(80, 255, 120),  dur = 0,  desc = "¡Vida al máximo!" },
	Furia      = { icono = "🔥", nombre = "FURIA",      color = RGB(190, 80, 255),  dur = 12, desc = "¡Recarga ultra rápida!" },
}
local NOMBRES = { "Turbo", "Sobrecarga", "Escudo", "Bateria", "Furia" }

local estado = ReplicatedStorage:WaitForChild("EstadoRobots")
local anuncioEvent = ReplicatedStorage:WaitForChild("AnuncioRobots")
local controlEvent = ReplicatedStorage:WaitForChild("ControlRobots")

local function ahora() return workspace:GetServerTimeNow() end

-- ===== Efectos =====
local function estallido(pos, color)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(pos); p.Parent = workspace
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = 6; l.Range = 18; l.Parent = p
	local att = Instance.new("Attachment"); att.Parent = p
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.4, 0.9); sp.Speed = NumberRange.new(15, 35)
	sp.SpreadAngle = Vector2.new(180, 180); sp.Rate = 0
	sp.Color = ColorSequence.new(color)
	sp.Parent = att
	sp:Emit(50)
	Debris:AddItem(p, 1)
end

local function aura(hrp, nombre, color, dur)
	local att = Instance.new("Attachment")
	att.Name = "AuraRuna_" .. nombre
	att.Parent = hrp
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.5, 0.9); sp.Rate = 25
	sp.Speed = NumberRange.new(1, 3); sp.SpreadAngle = Vector2.new(180, 180)
	sp.Size = NumberSequence.new(0.6, 0)
	sp.Color = ColorSequence.new(color)
	sp.Parent = att
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = 2; l.Range = 10; l.Parent = att
	Debris:AddItem(att, dur)
end

-- ===== Aplicar / quitar efectos =====
local function quitar(plr, nombre, char, hum)
	plr:SetAttribute("Runa_" .. nombre, nil)
	if nombre == "Turbo" then
		plr:SetAttribute("MultVel", nil)
		if hum and hum.Parent then hum.WalkSpeed = hum.WalkSpeed / 1.8 end
	elseif nombre == "Sobrecarga" then
		plr:SetAttribute("MultDano", nil)
	elseif nombre == "Furia" then
		plr:SetAttribute("MultRecarga", nil)
	elseif nombre == "Escudo" then
		local ff = char and char:FindFirstChild("EscudoRuna")
		if ff then ff:Destroy() end
	end
end

local function revisarFin(plr, nombre, char, hum)
	local fin = plr:GetAttribute("Runa_" .. nombre)
	if not fin or plr.Character ~= char then return end
	if fin > ahora() + 0.05 then
		-- la alargaron: esperar lo que falta
		task.delay(fin - ahora() + 0.1, function() revisarFin(plr, nombre, char, hum) end)
		return
	end
	quitar(plr, nombre, char, hum)
end

local function aplicarRuna(plr, nombre)
	local r = RUNAS[nombre]
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then return false end

	if nombre == "Bateria" then
		hum.Health = hum.MaxHealth
		aura(hrp, nombre, r.color, 1.5)
		return true
	end

	local yaActiva = (plr:GetAttribute("Runa_" .. nombre) or 0) > ahora()
	plr:SetAttribute("Runa_" .. nombre, ahora() + r.dur)
	if not yaActiva then
		if nombre == "Turbo" then
			plr:SetAttribute("MultVel", 1.8)
			hum.WalkSpeed = hum.WalkSpeed * 1.8
		elseif nombre == "Sobrecarga" then
			plr:SetAttribute("MultDano", 2)
		elseif nombre == "Furia" then
			plr:SetAttribute("MultRecarga", 0.4)
		elseif nombre == "Escudo" then
			local ff = Instance.new("ForceField")
			ff.Name = "EscudoRuna"
			ff.Parent = char
		end
		task.delay(r.dur + 0.1, function() revisarFin(plr, nombre, char, hum) end)
	end
	aura(hrp, nombre, r.color, r.dur)
	return true
end

-- Al morir se pierden todas las runas
local function limpiarRunas(plr, char, hum)
	for _, n in ipairs(NOMBRES) do
		if plr:GetAttribute("Runa_" .. n) then quitar(plr, n, char, hum) end
	end
end
local function prepararJugador(plr)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function() limpiarRunas(plr, char, hum) end)
	end)
end
Players.PlayerAdded:Connect(prepararJugador)
for _, plr in ipairs(Players:GetPlayers()) do prepararJugador(plr) end

-- ===== Runas en el mapa =====
local activas = 0

local function crearRuna(nombre, pos)
	local r = RUNAS[nombre]
	local modelo = Instance.new("Model")
	modelo.Name = "Runa" .. nombre

	local function pieza(size, forma, transp)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Material = Enum.Material.Neon; p.Color = r.color
		p.Size = size; p.Transparency = transp or 0
		if forma then p.Shape = forma end
		p.Parent = modelo
		return p
	end

	local base = pos + Vector3.new(0, 3, 0)
	local nucleo = pieza(Vector3.new(2, 2, 2), Enum.PartType.Ball)
	local aro1 = pieza(Vector3.new(0.2, 3.6, 3.6), Enum.PartType.Cylinder, 0.5)
	local aro2 = pieza(Vector3.new(0.2, 3.6, 3.6), Enum.PartType.Cylinder, 0.5)
	local haz = pieza(Vector3.new(80, 1.2, 1.2), Enum.PartType.Cylinder, 0.75)  -- se ve desde lejos
	haz.CFrame = CFrame.new(pos + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local zona = Instance.new("Part")  -- zona invisible para tomarla
	zona.Name = "Zona"
	zona.Anchored = true; zona.CanCollide = false; zona.CanQuery = false
	zona.Transparency = 1
	zona.Size = Vector3.new(5, 6, 5)
	zona.CFrame = CFrame.new(base)
	zona.Parent = modelo

	local luz = Instance.new("PointLight"); luz.Color = r.color; luz.Brightness = 3; luz.Range = 16; luz.Parent = nucleo
	local att = Instance.new("Attachment"); att.Parent = nucleo
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.6, 1.2); sp.Rate = 18
	sp.Speed = NumberRange.new(2, 5); sp.SpreadAngle = Vector2.new(180, 180)
	sp.Color = ColorSequence.new(r.color)
	sp.Parent = att

	local bb = Instance.new("BillboardGui")
	-- tamaño en studs + oculto tras paredes + solo de cerca (de lejos se ve el rayo al cielo)
	bb.Size = UDim2.new(7, 0, 1.6, 0); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = false
	bb.MaxDistance = 80; bb.LightInfluence = 0
	bb.Parent = nucleo
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = r.icono .. " " .. r.nombre
	t.TextColor3 = r.color; t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.Parent = bb

	modelo.Parent = workspace
	activas += 1

	local tomada = false
	local function retirar()
		if modelo.Parent then
			modelo:Destroy()
			activas -= 1
		end
	end

	-- flota y gira
	task.spawn(function()
		local t0 = os.clock()
		while modelo.Parent do
			local tt = os.clock() - t0
			local cf = CFrame.new(base + Vector3.new(0, math.sin(tt * 2.5) * 0.6, 0))
			nucleo.CFrame = cf
			aro1.CFrame = cf * CFrame.Angles(0, tt * 2, 0)
			aro2.CFrame = cf * CFrame.Angles(0, -tt * 2 + math.pi / 2, 0)
			task.wait(0.03)
		end
	end)

	zona.Touched:Connect(function(hit)
		if tomada then return end
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then return end
		if aplicarRuna(plr, nombre) then
			tomada = true
			estallido(base, r.color)
			anuncioEvent:FireClient(plr, r.icono .. " " .. r.nombre .. ": " .. r.desc, r.color, 2.5)
			retirar()
		end
	end)

	task.delay(CONFIG.DURACION_EN_MAPA, retirar)
end

-- ===== Dónde aparecen =====
local function puntoAleatorio()
	local excl = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(excl, plr.Character) end
	end
	local robots = workspace:FindFirstChild("RobotsEnemigos")
	if robots then table.insert(excl, robots) end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = excl

	-- durante la gran final, las runas aparecen dentro de la arena
	if estado:GetAttribute("Fase") == "final" then
		local arena = workspace:FindFirstChild("ArenaFinal")
		local c = arena and arena:GetAttribute("Centro")
		if c then
			local a = math.random() * math.pi * 2
			local r = math.random() * 70
			return Vector3.new(c.X + math.cos(a) * r, c.Y + 2, c.Z + math.sin(a) * r)
		end
	end

	-- si el profe crea una carpeta "PuntosRunas" con partes, se usan esas
	local f = workspace:FindFirstChild("PuntosRunas")
	if f and #f:GetChildren() > 0 then
		local hijos = f:GetChildren()
		local p = hijos[math.random(#hijos)]
		if p:IsA("BasePart") then
			local res = workspace:Raycast(p.Position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rp)
			return res and res.Position or p.Position
		end
	end

	-- si no: alrededor del centro de las bases
	local suma, n, maxD = Vector3.new(0, 0, 0), 0, 0
	local bases = {}
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:match("^BaseEquipo%d+$") and obj.PrimaryPart then
			suma += obj.PrimaryPart.Position; n += 1; table.insert(bases, obj.PrimaryPart.Position)
		end
	end
	local centro = n > 0 and suma / n or Vector3.new(0, 0, 0)
	for _, b in ipairs(bases) do
		maxD = math.max(maxD, (Vector3.new(b.X, 0, b.Z) - Vector3.new(centro.X, 0, centro.Z)).Magnitude)
	end
	local radio = math.max(50, maxD)
	for _ = 1, 10 do
		local ang = math.random() * math.pi * 2
		local r = radio * math.random() * 0.9
		local res = workspace:Raycast(
			Vector3.new(centro.X + math.cos(ang) * r, centro.Y + 250, centro.Z + math.sin(ang) * r),
			Vector3.new(0, -800, 0), rp)
		if res then return res.Position end
	end
	return nil
end

task.spawn(function()
	while true do
		task.wait(CONFIG.INTERVALO)
		local enJuego = workspace:GetAttribute("JuegoIniciado") or estado:GetAttribute("Fase") ~= "espera"
		if enJuego and activas < CONFIG.MAX_ACTIVAS then
			local p = puntoAleatorio()
			if p then crearRuna(NOMBRES[math.random(#NOMBRES)], p) end
		end
	end
end)

-- El profe suelta una runa cerca suyo con [U] (para probar)
controlEvent.OnServerEvent:Connect(function(plr, accion)
	if accion ~= "runa" then return end
	if not (plr.UserId == OWNER_USERID or plr:GetAttribute("IsGameMaster") == true) then return end
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local pos = (hrp.CFrame * CFrame.new(0, -2.5, -8)).Position
		crearRuna(NOMBRES[math.random(#NOMBRES)], pos)
	end
end)

print("✅ Runas temporales listas")
