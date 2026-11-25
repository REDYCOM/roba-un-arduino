--=====================================================================
--  ARMAS ESPECIALES (cliente)
--  - Al disparar, envía al servidor a dónde apuntas.
--  - Cruz de puntería, 1ª persona y barra de recarga.
--  - ARMAS ANIMADAS: balanceo en la mano, retroceso al disparar y una
--    animación propia por arma (bomba de la escopeta, chispas de la Tesla,
--    pulso del láser, tubo de la bazuca que baja al recargar...).
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local dispararEvent = ReplicatedStorage:WaitForChild("DispararArma")

local ARMAS = { Bazuca = true, Laser = true, Escopeta = true, Tesla = true, Granada = true }
-- (deben coincidir con CONFIG en Armas.server.luau)
local RECARGA = { Bazuca = 3.0, Laser = 0.6, Escopeta = 0.9, Tesla = 1.1, Granada = 1.5 }
-- fuerza del retroceso de cada arma
local RETROCESO = { Bazuca = 1.0, Laser = 0.35, Escopeta = 0.85, Tesla = 0.4, Granada = 0.7 }

-- ===== Crosshair =====
local cruzGui = Instance.new("ScreenGui")
cruzGui.Name = "CruzArmas"
cruzGui.ResetOnSpawn = false
cruzGui.IgnoreGuiInset = true
cruzGui.Enabled = false
cruzGui.Parent = playerGui

local centro = Instance.new("Frame")
centro.AnchorPoint = Vector2.new(0.5, 0.5)
centro.Position = UDim2.new(0.5, 0, 0.5, 0)
centro.Size = UDim2.new(0, 34, 0, 34)
centro.BackgroundTransparency = 1
centro.Parent = cruzGui
local escalaCruz = Instance.new("UIScale"); escalaCruz.Parent = centro

local COLOR = Color3.fromRGB(120, 240, 255)
local function linea(w, h, px, py)
	local l = Instance.new("Frame")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5, px, 0.5, py)
	l.Size = UDim2.new(0, w, 0, h)
	l.BackgroundColor3 = COLOR
	l.BorderSizePixel = 0
	l.Parent = centro
end
linea(3, 12, 0, -13)
linea(3, 12, 0, 13)
linea(12, 3, -13, 0)
linea(12, 3, 13, 0)
local punto = Instance.new("Frame")
punto.AnchorPoint = Vector2.new(0.5, 0.5)
punto.Position = UDim2.new(0.5, 0, 0.5, 0)
punto.Size = UDim2.new(0, 4, 0, 4)
punto.BackgroundColor3 = COLOR
punto.BorderSizePixel = 0
punto.Parent = centro
local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1, 0); uc.Parent = punto

-- ===== Barra de recarga =====
local recargaGui = Instance.new("ScreenGui")
recargaGui.Name = "RecargaArma"; recargaGui.ResetOnSpawn = false
recargaGui.IgnoreGuiInset = true; recargaGui.Enabled = false; recargaGui.Parent = playerGui

local fondoR = Instance.new("Frame")
fondoR.AnchorPoint = Vector2.new(0.5, 0.5)
fondoR.Position = UDim2.new(0.5, 0, 0.5, 46)
fondoR.Size = UDim2.new(0, 170, 0, 14)
fondoR.BackgroundColor3 = Color3.fromRGB(15, 15, 20); fondoR.BackgroundTransparency = 0.25
fondoR.Parent = recargaGui
local ucR = Instance.new("UICorner"); ucR.CornerRadius = UDim.new(1, 0); ucR.Parent = fondoR
local fillR = Instance.new("Frame")
fillR.Size = UDim2.new(0, 0, 1, 0); fillR.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
fillR.Parent = fondoR
local ucF = Instance.new("UICorner"); ucF.CornerRadius = UDim.new(1, 0); ucF.Parent = fillR
local txtR = Instance.new("TextLabel")
txtR.Size = UDim2.new(1, 0, 1, 0); txtR.BackgroundTransparency = 1
txtR.Text = "RECARGANDO"; txtR.TextColor3 = Color3.fromRGB(255, 255, 255)
txtR.Font = Enum.Font.GothamBold; txtR.TextSize = 10; txtR.Parent = fondoR

local idRecarga = 0
local function mostrarRecarga(cd)
	idRecarga += 1
	local miId = idRecarga
	recargaGui.Enabled = true
	fillR.Size = UDim2.new(0, 0, 1, 0)
	TweenService:Create(fillR, TweenInfo.new(cd, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) }):Play()
	task.delay(cd, function()
		if miId == idRecarga then recargaGui.Enabled = false end
	end)
end

local function recargaDe(nombre)
	return (RECARGA[nombre] or 0) * (player:GetAttribute("MultRecarga") or 1)  -- runa Furia
end

-- ===== Estado del arma equipada (para animarla) =====
local actual = nil         -- { tool, nombre, partes, grip, gripC0 }
local retroceso = 0        -- 1 al disparar, baja solo
local ultimoTiro = {}      -- [nombre] = os.clock() del último disparo
local ultimoArco = 0

local function alEquipar(tool)
	cruzGui.Enabled = true
	-- (la cámara y el cursor ahora los controla PrimeraPersona.client: siempre 1ª persona)

	local info = { tool = tool, nombre = tool.Name, partes = {} }
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") then
			local w = p:FindFirstChild("Union")
			info.partes[p.Name] = { part = p, weld = w, c0 = w and w.C0, size = p.Size, color = p.Color }
		end
	end
	actual = info

	-- la unión mano–arma la crea Roblox al equipar: la buscamos para moverla
	task.spawn(function()
		for _ = 1, 30 do
			if actual ~= info then return end
			local char = player.Character
			local grip = char and char:FindFirstChild("RightGrip", true)
			if grip and grip.Part1 == tool:FindFirstChild("Handle") then
				info.grip = grip
				info.gripC0 = grip.C0
				return
			end
			task.wait(0.05)
		end
	end)
end

local function alDesequipar(tool)
	cruzGui.Enabled = false
	local a = actual
	if a and a.tool == tool then
		for _, d in pairs(a.partes) do  -- dejar todo como estaba
			if d.part.Parent then
				d.part.Size = d.size
				d.part.Color = d.color
				d.part.LocalTransparencyModifier = 0
				if d.weld and d.weld.Parent then d.weld.C0 = d.c0 end
			end
		end
		actual = nil
	end
end

-- ===== Conectar armas =====
local function conectarTool(tool)
	if not ARMAS[tool.Name] then return end
	if tool:GetAttribute("_conectada") then return end
	tool:SetAttribute("_conectada", true)

	tool.Activated:Connect(function()
		local cd = recargaDe(tool.Name)
		local ahora = os.clock()
		if ultimoTiro[tool.Name] and (ahora - ultimoTiro[tool.Name]) < cd then return end
		ultimoTiro[tool.Name] = ahora
		local target = mouse.Hit and mouse.Hit.Position
		if target then
			dispararEvent:FireServer(tool.Name, target)
		end
		retroceso = 1
		escalaCruz.Scale = 1.7  -- la cruz "salta" al disparar
		TweenService:Create(escalaCruz, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if cd >= 1 then mostrarRecarga(cd) end
	end)
	tool.Equipped:Connect(function() alEquipar(tool) end)
	tool.Unequipped:Connect(function() alDesequipar(tool) end)
end

-- ===== Animación (cada cuadro) =====
local BLANCO = Color3.fromRGB(255, 255, 255)
local CHISPA = Color3.fromRGB(255, 235, 160)

RunService.RenderStepped:Connect(function(dt)
	local a = actual
	-- con una ventana abierta (estación/tienda) el mouse está libre: ocultar la cruz
	cruzGui.Enabled = a ~= nil and not UserInputService.MouseIconEnabled
	if not a then return end
	local t = os.clock()
	retroceso = math.max(0, retroceso - dt * 5)
	local desdeTiro = t - (ultimoTiro[a.nombre] or -100)

	-- 1) el arma en la mano: balanceo suave + pasos + retroceso
	if a.grip and a.grip.Parent then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local andar = hum and hum.MoveDirection.Magnitude or 0
		local balanceo = CFrame.new(
			math.sin(t * 1.6) * 0.03,
			math.sin(t * 2.1) * 0.03 + math.abs(math.sin(t * 9)) * 0.06 * andar,
			0
		)
		local r = retroceso * (RETROCESO[a.nombre] or 0.4)
		local patada = CFrame.new(0, 0, r * 0.5) * CFrame.Angles(math.rad(r * 14), 0, 0)
		if a.nombre == "Bazuca" then
			-- mientras recarga, el tubo baja y vuelve a subir
			local cd = recargaDe("Bazuca")
			if desdeTiro < cd then
				local k = math.sin(math.clamp(desdeTiro / cd, 0, 1) * math.pi)
				patada *= CFrame.Angles(math.rad(-16 * k), 0, 0)
			end
		end
		a.grip.C0 = a.gripC0 * balanceo * patada
	end

	-- 2) animación propia de cada arma
	if a.nombre == "Escopeta" then
		local b = a.partes.Bomba
		if b and b.weld and b.weld.Parent then
			local k = (desdeTiro < 0.45) and math.sin(desdeTiro / 0.45 * math.pi) or 0
			b.weld.C0 = b.c0 * CFrame.new(0, 0, k * 0.55)  -- la bomba va atrás y vuelve
		end

	elseif a.nombre == "Tesla" then
		local e = a.partes.Esfera
		if e and e.part.Parent then
			local pulso = 1 + math.sin(t * 12) * 0.12 + ((desdeTiro < 0.25) and 0.5 or 0)
			e.part.Size = e.size * pulso
			-- mini arcos eléctricos alrededor de la esfera (solo los ves tú)
			if t - ultimoArco > 0.09 then
				ultimoArco = t
				local p0 = e.part.Position
				local p1 = p0 + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.6
				local arco = Instance.new("Part")
				arco.Anchored = true; arco.CanCollide = false; arco.CanQuery = false; arco.CanTouch = false
				arco.Material = Enum.Material.Neon; arco.Color = Color3.fromRGB(170, 230, 255)
				arco.Size = Vector3.new(0.04, 0.04, (p1 - p0).Magnitude)
				arco.CFrame = CFrame.new(p0:Lerp(p1, 0.5), p1)
				arco.Parent = workspace.CurrentCamera
				Debris:AddItem(arco, 0.07)
			end
		end
		for i = 1, 4 do  -- las bobinas se "cargan" en ola
			local bob = a.partes["Bobina" .. i]
			if bob and bob.part.Parent then
				local k = (math.sin(t * 8 - i * 0.9) + 1) / 2
				bob.part.Color = bob.color:Lerp(CHISPA, k * 0.7)
			end
		end

	elseif a.nombre == "Laser" then
		local k = (desdeTiro < 0.15) and 1 or ((math.sin(t * 5) + 1) / 2) * 0.4
		for _, n in ipairs({ "Neon", "Emisor" }) do
			local d = a.partes[n]
			if d and d.part.Parent then d.part.Color = d.color:Lerp(BLANCO, k) end
		end

	elseif a.nombre == "Granada" then
		-- tras lanzarla, la mano queda vacía un momento
		local oculto = (desdeTiro < 0.7) and 1 or 0
		for _, d in pairs(a.partes) do
			if d.part.Parent then d.part.LocalTransparencyModifier = oculto end
		end
	end
end)

local function escanear(contenedor)
	for _, tl in ipairs(contenedor:GetChildren()) do
		if tl:IsA("Tool") then conectarTool(tl) end
	end
	contenedor.ChildAdded:Connect(function(tl)
		if tl:IsA("Tool") then conectarTool(tl) end
	end)
end

local function onChar(char)
	cruzGui.Enabled = false
	actual = nil
	local bp = player:WaitForChild("Backpack")
	escanear(bp)
	escanear(char)
end

if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

print("✅ Cliente de armas listo (crosshair + armas animadas)")
