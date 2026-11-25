--=====================================================================
--  COMPONENTES QUE BRILLAN (cliente) — estilo RUNA
--  Los componentes electrónicos sueltos en el mapa (Arduino, L298N,
--  sensores, baterías...) se ven flotando, girando y brillando, con dos
--  aros como las runas y su nombre + puntos encima. SIN el rayo al cielo.
--
--  Es solo visual (en tu pantalla): el componente real sigue donde estaba,
--  así que recogerlo con [E], entregarlo y robarlo funciona igual que antes.
--  Cuando alguien lo recoge o ya está en una base, el efecto desaparece.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CONFIG = {
	ALTURA = 2.5,          -- cuánto flota sobre su lugar
	AMPLITUD = 0.6,        -- sube y baja (igual que las runas)
	VEL_FLOTAR = 2.5,
	VEL_GIRO = 1.2,
	COLOR = Color3.fromRGB(0, 230, 215), -- turquesa Arduino
	DISTANCIA_MAX = 300,   -- más lejos no se anima (rendimiento)
	DISTANCIA_TEXTO = 55,  -- más lejos no se ve el cartel (solo el brillo)
	DISTANCIA_NOMBRE = 22, -- más cerca que esto se ve el nombre del componente
}

local puntaje = ReplicatedStorage:WaitForChild("PuntajeEquipos", 30)
local function puntosComponente()
	return (puntaje and puntaje:GetAttribute("PorComponente")) or 100
end

local efectos = {} -- [modeloReal] = datos del efecto

-- ¿es un componente para recoger? (tiene el PickupScript del juego)
local function esComponente(m)
	return m:IsA("Model") and m:FindFirstChild("PickupScript") ~= nil and m.PrimaryPart ~= nil
end

-- ¿está suelto en el mapa? (no lo lleva nadie y no está en una base)
local function estaLibre(m)
	if m.Parent ~= workspace then return false end
	if m:GetAttribute("AnchoredToBase") then return false end
	local prompt = m.PrimaryPart and m.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	return prompt == nil or prompt.Enabled
end

local function ocultarReal(m, ocultar)
	local v = ocultar and 1 or 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
			d.LocalTransparencyModifier = v
		end
	end
end

local function neon(size, forma, transp, padre)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon; p.Color = CONFIG.COLOR
	p.Size = size; p.Transparency = transp or 0
	if forma then p.Shape = forma end
	p.Parent = padre
	return p
end

local function crearEfecto(m)
	local real = m.PrimaryPart
	local cfCaja, tamCaja = m:GetBoundingBox()
	local centro0 = cfCaja.Position
	local rot0 = real.CFrame.Rotation
	local radio = math.max(tamCaja.X, tamCaja.Z) * 0.65 + 1.2

	local carpeta = Instance.new("Folder")
	carpeta.Name = "BrilloComponente"
	carpeta.Parent = workspace.CurrentCamera

	-- copia visual del componente (sin scripts ni botones)
	local partes, offsets = {}, {}
	m.Archivable = true
	local ok, copia = pcall(function() return m:Clone() end)
	if ok and copia then
		local base = CFrame.new(centro0) * rot0
		for _, d in ipairs(copia:GetDescendants()) do
			if d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("JointInstance")
				or d:IsA("WeldConstraint") or d:IsA("BodyMover") or d:IsA("Constraint") or d:IsA("Light")
				or d:IsA("ParticleEmitter") then
				d:Destroy()
			end
		end
		for _, d in ipairs(copia:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
				d.LocalTransparencyModifier = 0
				table.insert(partes, d)
				table.insert(offsets, base:ToObjectSpace(d.CFrame))
			end
		end
		copia.Parent = carpeta
		ocultarReal(m, true)
	end

	-- aros que giran (como las runas) + luz + chispitas
	local aro1 = neon(Vector3.new(0.15, radio * 2, radio * 2), Enum.PartType.Cylinder, 0.45, carpeta)
	local aro2 = neon(Vector3.new(0.15, radio * 2, radio * 2), Enum.PartType.Cylinder, 0.45, carpeta)
	local halo = neon(Vector3.new(radio * 1.5, radio * 1.5, radio * 1.5), Enum.PartType.Ball, 0.88, carpeta)
	local brillo = neon(Vector3.new(0.1, radio * 1.4, radio * 1.4), Enum.PartType.Cylinder, 0.6, carpeta) -- reflejo en el suelo

	local luz = Instance.new("PointLight")
	luz.Color = CONFIG.COLOR; luz.Brightness = 3; luz.Range = 16; luz.Parent = halo
	local att = Instance.new("Attachment"); att.Parent = halo
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.6, 1.2); sp.Rate = 14
	sp.Speed = NumberRange.new(1.5, 4); sp.SpreadAngle = Vector2.new(180, 180)
	sp.Size = NumberSequence.new(0.35, 0)
	sp.Color = ColorSequence.new(CONFIG.COLOR)
	sp.LightEmission = 1
	sp.Parent = att

	-- cartel: tamaño en STUDS (se achica con la distancia como un objeto real),
	-- no se ve a través de paredes y desaparece de lejos (de lejos solo se ve el brillo)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(6, 0, 1.1, 0); bb.StudsOffset = Vector3.new(0, radio + 0.8, 0)
	bb.AlwaysOnTop = false; bb.MaxDistance = CONFIG.DISTANCIA_TEXTO; bb.LightInfluence = 0
	bb.Parent = halo
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.RichText = true
	t.TextColor3 = CONFIG.COLOR; t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.Parent = bb
	local textoCorto = '🔌 <font color="#ffe066">+' .. puntosComponente() .. "</font>"
	local textoLargo = m.Name .. '  <font color="#ffe066">+' .. puntosComponente() .. "</font>"
	t.Text = textoCorto

	efectos[m] = {
		carpeta = carpeta, partes = partes, offsets = offsets, rot0 = rot0,
		desfase = centro0 - real.Position, -- del PrimaryPart al centro del modelo
		aro1 = aro1, aro2 = aro2, halo = halo, brillo = brillo,
		etiqueta = t, textoCorto = textoCorto, textoLargo = textoLargo, cerca = false,
		t0 = os.clock() + math.random() * 3, -- cada uno flota a su ritmo
		alturaSuelo = tamCaja.Y / 2,
	}
end

local function quitarEfecto(m)
	local e = efectos[m]
	if not e then return end
	efectos[m] = nil
	e.carpeta:Destroy()
	if m.Parent then ocultarReal(m, false) end
end

-- revisar cada medio segundo qué componentes están libres
task.spawn(function()
	while true do
		local vistos = {}
		for _, m in ipairs(workspace:GetChildren()) do
			if esComponente(m) then
				vistos[m] = true
				local libre = estaLibre(m)
				if libre and not efectos[m] then
					crearEfecto(m)
				elseif not libre and efectos[m] then
					quitarEfecto(m)
				end
			end
		end
		for m in pairs(efectos) do
			if not vistos[m] then quitarEfecto(m) end -- lo recogieron o se borró
		end
		task.wait(0.5)
	end
end)

-- animación (como las runas: sube/baja y los aros giran)
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local ahora = os.clock()
	local partesMover, cfsMover = {}, {}
	for m, e in pairs(efectos) do
		local real = m.PrimaryPart
		if real and real.Parent then
			local centroSuelo = real.Position + e.desfase
			local dist = (centroSuelo - camPos).Magnitude
			-- muy cerca: nombre completo; más lejos: solo "🔌 +100"
			local cerca = dist < CONFIG.DISTANCIA_NOMBRE
			if cerca ~= e.cerca then
				e.cerca = cerca
				e.etiqueta.Text = cerca and e.textoLargo or e.textoCorto
			end
			if dist < CONFIG.DISTANCIA_MAX then
				local tt = ahora - e.t0
				local pos = centroSuelo + Vector3.new(0, CONFIG.ALTURA + math.sin(tt * CONFIG.VEL_FLOTAR) * CONFIG.AMPLITUD, 0)
				local cf = CFrame.new(pos)
				local giro = cf * CFrame.Angles(0, tt * CONFIG.VEL_GIRO, 0) * e.rot0
				for i, p in ipairs(e.partes) do
					table.insert(partesMover, p)
					table.insert(cfsMover, giro * e.offsets[i])
				end
				e.aro1.CFrame = cf * CFrame.Angles(0, tt * 2, 0)
				e.aro2.CFrame = cf * CFrame.Angles(0, -tt * 2 + math.pi / 2, 0)
				e.halo.CFrame = cf
				e.halo.Transparency = 0.86 + math.sin(tt * 4) * 0.04 -- late suave
				e.brillo.CFrame = CFrame.new(centroSuelo - Vector3.new(0, e.alturaSuelo - 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
	if #partesMover > 0 then
		workspace:BulkMoveTo(partesMover, cfsMover, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)

print("✅ Componentes con brillo de runa")
