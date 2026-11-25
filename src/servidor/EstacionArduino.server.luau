--=====================================================================
--  ESTACIÓN ARDUINO (servidor)
--  - Crea el robot-estación en la base del Equipo 1.
--  - Al usarlo (tecla E), abre el SIGUIENTE reto no resuelto del jugador.
--  (Los puntos y poderes los maneja Poderes.server cuando se resuelve.)
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getRemote(nombre)
	local r = ReplicatedStorage:FindFirstChild(nombre)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = nombre
		r.Parent = ReplicatedStorage
	end
	return r
end

local abrirEvent     = getRemote("AbrirEstacionArduino")  -- servidor → cliente
local siguienteEvent = getRemote("SiguienteRetoEvent")    -- cliente → servidor (pedir el siguiente)
local tiendaEvent    = getRemote("AbrirTienda")           -- servidor → cliente (abrir la tienda)

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Retos = require(sistema:WaitForChild("Retos"))

-- Devuelve el id del siguiente reto que al jugador le falta, o nil si ya los hizo todos
local function siguienteReto(plr)
	local folder = plr:FindFirstChild("RetosResueltos")
	for _, id in ipairs(Retos.orden) do
		if not (folder and folder:FindFirstChild(id)) then
			return id
		end
	end
	return nil
end

-- El cliente pide avanzar al siguiente reto (botón "Siguiente")
siguienteEvent.OnServerEvent:Connect(function(plr)
	abrirEvent:FireClient(plr, siguienteReto(plr) or "__completo__")
end)

-- === Crear la estación (ROBOTITO ANIMADO) en una base ===
local function crearEstacion(base)
	if not base or not base.PrimaryPart then
		warn("[EstacionArduino] La base no tiene PrimaryPart:", base and base.Name)
		return
	end

	local anterior = base:FindFirstChild("EstacionArduino")
	if anterior then anterior:Destroy() end

	-- posición frente a la base + girado 180° para que mire hacia el jugador
	local baseCF = base.PrimaryPart.CFrame * CFrame.new(0, 3.5, -6) * CFrame.Angles(0, math.pi, 0)

	local robot = Instance.new("Model")
	robot.Name = "EstacionArduino"

	local function parte(nombre, size, color, material, offset, shape)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		if shape then p.Shape = shape end
		p.CFrame = baseCF * offset
		p.Parent = robot
		return p
	end

	local AZUL  = Color3.fromRGB(45, 110, 210)
	local AZUL2 = Color3.fromRGB(70, 140, 235)
	local NEON  = Color3.fromRGB(120, 255, 240)

	local cuerpo = parte("Cuerpo", Vector3.new(3, 3, 1.8), AZUL, Enum.Material.SmoothPlastic, CFrame.new(0, 0, 0))
	parte("Cabeza",   Vector3.new(2.4, 1.7, 1.6),  AZUL2, Enum.Material.SmoothPlastic, CFrame.new(0, 2.4, 0))
	parte("OjoIzq",   Vector3.new(0.5, 0.5, 0.25), NEON,  Enum.Material.Neon,          CFrame.new(-0.55, 2.5, -0.82))
	parte("OjoDer",   Vector3.new(0.5, 0.5, 0.25), NEON,  Enum.Material.Neon,          CFrame.new(0.55, 2.5, -0.82))
	parte("Boca",     Vector3.new(1.2, 0.18, 0.2), NEON,  Enum.Material.Neon,          CFrame.new(0, 1.95, -0.82))
	parte("BrazoIzq", Vector3.new(0.5, 1.8, 0.5),  AZUL,  Enum.Material.SmoothPlastic, CFrame.new(-1.9, 0.1, 0))
	parte("BrazoDer", Vector3.new(0.5, 1.8, 0.5),  AZUL,  Enum.Material.SmoothPlastic, CFrame.new(1.9, 0.1, 0))
	parte("Pecho",    Vector3.new(1.6, 1.0, 0.1),  Color3.fromRGB(15, 90, 80), Enum.Material.Neon, CFrame.new(0, 0.1, -0.92))
	parte("Antena",   Vector3.new(0.12, 1.2, 0.12), Color3.fromRGB(30, 30, 40), Enum.Material.SmoothPlastic, CFrame.new(0, 3.6, 0))
	local foco = parte("Foco", Vector3.new(0.55, 0.55, 0.55), Color3.fromRGB(255, 70, 70), Enum.Material.Neon, CFrame.new(0, 4.35, 0), Enum.PartType.Ball)

	local luz = Instance.new("PointLight")
	luz.Color = NEON; luz.Brightness = 2; luz.Range = 12; luz.Parent = cuerpo

	robot.PrimaryPart = cuerpo
	robot.Parent = base

	local bb = Instance.new("BillboardGui")
	-- en studs, tapado por paredes y solo de cerca (antes se veían las 5 desde todo el mapa)
	bb.Size = UDim2.new(8, 0, 1.7, 0)
	bb.StudsOffset = Vector3.new(0, 4.6, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Adornee = cuerpo
	bb.Parent = cuerpo
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "💡 Programa el Arduino"
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.4
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Programar"
	prompt.ObjectText = "Estación Arduino"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = cuerpo

	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.Triggered:Connect(function(plr)
		local retoId = siguienteReto(plr)
		abrirEvent:FireClient(plr, retoId or "__completo__")
	end)

	-- Segundo botón: la tienda (canjear puntos)
	local promptTienda = Instance.new("ProximityPrompt")
	promptTienda.ActionText = "Canjear puntos"
	promptTienda.ObjectText = "Tienda"
	promptTienda.KeyboardKeyCode = Enum.KeyCode.T
	promptTienda.MaxActivationDistance = 10
	promptTienda.RequiresLineOfSight = false
	promptTienda.HoldDuration = 0
	promptTienda.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	promptTienda.UIOffset = Vector2.new(0, -75)
	promptTienda.Parent = cuerpo
	promptTienda.Triggered:Connect(function(plr)
		tiendaEvent:FireClient(plr)
	end)

	-- 🎬 Animación: flota, se balancea y la antena parpadea
	task.spawn(function()
		local t = 0
		while robot.Parent do
			t += task.wait()
			local bob = math.sin(t * 2) * 0.4
			local yaw = math.sin(t * 0.8) * 0.35
			robot:PivotTo(baseCF * CFrame.new(0, bob, 0) * CFrame.Angles(0, yaw, 0))
			if math.floor(t * 2) % 2 == 0 then
				foco.Color = Color3.fromRGB(255, 70, 70)
			else
				foco.Color = Color3.fromRGB(70, 255, 120)
			end
		end
	end)

	print("[EstacionArduino] Robot-estación creado en", base.Name)
end

-- Colocar una estación en la base de CADA equipo
for i = 1, 5 do
	task.spawn(function()
		local base = workspace:WaitForChild("BaseEquipo" .. i, 15)
		if base then crearEstacion(base) end
	end)
end

print("✅ EstacionArduino (servidor) iniciada")
