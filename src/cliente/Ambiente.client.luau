--=====================================================================
--  AMBIENTE (cliente): lluvia, rayos y efectos de pantalla
--  - Tormenta: lluvia fuerte + relámpagos que iluminan todo.
--  - Niebla: llovizna.
--  - Al recibir daño: borde rojo en la pantalla; con poca vida, late.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local estado = ReplicatedStorage:WaitForChild("EstadoRobots")
local RGB = Color3.fromRGB

-- ===== Lluvia (una "nube" invisible sobre la cámara que suelta gotas) =====
local nube = Instance.new("Part")
nube.Name = "NubeLluvia"
nube.Anchored = true; nube.CanCollide = false; nube.CanQuery = false; nube.CanTouch = false
nube.Transparency = 1
nube.Size = Vector3.new(140, 1, 140)
nube.Parent = workspace.CurrentCamera

local lluvia = Instance.new("ParticleEmitter")
lluvia.Texture = "rbxasset://textures/particles/sparkles_main.dds"
lluvia.Color = ColorSequence.new(RGB(170, 195, 235))
lluvia.LightEmission = 0.2
lluvia.Size = NumberSequence.new(0.14)
lluvia.Squash = NumberSequence.new(-2.5)
lluvia.Transparency = NumberSequence.new(0.35)
lluvia.Lifetime = NumberRange.new(0.8, 1)
lluvia.Speed = NumberRange.new(90, 110)
lluvia.EmissionDirection = Enum.NormalId.Bottom
lluvia.SpreadAngle = Vector2.new(4, 4)
lluvia.Orientation = Enum.ParticleOrientation.VelocityParallel
lluvia.Rate = 0
lluvia.Parent = nube

local function actualizarLluvia()
	local clima = estado:GetAttribute("Clima")
	if clima == "tormenta" then
		lluvia.Rate = 700
	elseif clima == "niebla" then
		lluvia.Rate = 180
	else
		lluvia.Rate = 0
	end
end
estado:GetAttributeChangedSignal("Clima"):Connect(actualizarLluvia)
actualizarLluvia()

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		nube.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 45, 0))
	end
end)

-- ===== Relámpagos (solo en tormenta) =====
local destelloCC = Instance.new("ColorCorrectionEffect")
destelloCC.Name = "DestelloRelampago"
destelloCC.Parent = Lighting

local COLORES_RAYO = { RGB(220, 230, 255), RGB(190, 170, 255), RGB(255, 235, 200) }

local function segmento(desde, hasta, grosor, color, padre)
	local seg = Instance.new("Part")
	seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false
	seg.CastShadow = false
	seg.Material = Enum.Material.Neon; seg.Color = color
	seg.Size = Vector3.new(grosor, grosor, (hasta - desde).Magnitude)
	seg.CFrame = CFrame.new(desde:Lerp(hasta, 0.5), hasta)
	seg.Parent = padre
	TweenService:Create(seg, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	Debris:AddItem(seg, 0.27)
end

-- un rayo con zigzag; a veces se ramifica (las ramas son más finas)
local function dibujarRayo(desde, hasta, grosor, color, ramas, padre)
	local tramos = math.clamp(math.floor((hasta - desde).Magnitude / 16), 4, 14)
	local punto = desde
	for i = 1, tramos do
		local siguiente = desde:Lerp(hasta, i / tramos)
		if i < tramos then
			siguiente += Vector3.new(math.random(-60, 60) / 10, 0, math.random(-60, 60) / 10)
		end
		segmento(punto, siguiente, grosor, color, padre)
		if ramas > 0 and i < tramos - 1 and math.random() < 0.3 then
			local finRama = siguiente + Vector3.new(math.random(-30, 30), -math.random(15, 35), math.random(-30, 30))
			dibujarRayo(siguiente, finRama, grosor * 0.45, color, ramas - 1, padre)
		end
		punto = siguiente
	end
end

-- dónde toca el suelo (para que el rayo llegue abajo)
local function sueloBajo(pos)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { workspace.CurrentCamera }
	local res = workspace:Raycast(pos, Vector3.new(0, -600, 0), rp)
	return res and res.Position
end

local function rayoEnElCielo(cercano)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local dist = cercano and 70 or 220
	local base = cam.CFrame.Position + Vector3.new(math.random(-dist, dist), 0, math.random(-dist, dist))
	local inicio = base + Vector3.new(0, 160, 0)
	local fin = sueloBajo(inicio) or (base - Vector3.new(0, 20, 0))
	local color = COLORES_RAYO[math.random(#COLORES_RAYO)]
	dibujarRayo(inicio, fin, cercano and 1.6 or 1.1, color, 2, cam)

	-- luz en el suelo donde cae
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(fin + Vector3.new(0, 6, 0)); p.Parent = cam
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = 10; l.Range = 60; l.Parent = p
	TweenService:Create(l, TweenInfo.new(0.35), { Brightness = 0 }):Play()
	Debris:AddItem(p, 0.4)
end

local function flash(fuerza)
	destelloCC.Brightness = 0.5 * fuerza
	task.wait(0.07)
	destelloCC.Brightness = 0
	task.wait(0.08)
	destelloCC.Brightness = 0.3 * fuerza
	task.wait(0.06)
	destelloCC.Brightness = 0
end

local function relampago(fuerza, cercano)
	rayoEnElCielo(cercano)
	if math.random() < 0.35 then -- a veces caen dos casi juntos
		task.delay(0.12, rayoEnElCielo, false)
	end
	flash(fuerza)
end

-- ¿cada cuánto cae un rayo? (segundos mín, máx) según el clima
local function frecuencia()
	local clima = estado:GetAttribute("Clima")
	if estado:GetAttribute("Fase") == "final" then return 1.2, 3.5 end -- la final: tormenta brutal
	if clima == "tormenta" then return 2, 5 end
	if clima == "noche" then return 12, 25 end -- relámpagos lejanos de vez en cuando
	return nil
end

task.spawn(function()
	while true do
		local minimo, maximo = frecuencia()
		if minimo then
			task.wait(minimo + math.random() * (maximo - minimo))
			local m2 = frecuencia()
			if m2 then
				local noche = estado:GetAttribute("Clima") == "noche"
				relampago(noche and 0.5 or 1, not noche and math.random() < 0.3)
			end
		else
			task.wait(1)
		end
	end
end)

-- rayos que lanza el JEFE: destello fuerte en la pantalla si estás cerca
task.spawn(function() -- (en otro hilo para no frenar el resto del script)
	local relampagoEvent = ReplicatedStorage:WaitForChild("RelampagoRobots", 60)
	if not relampagoEvent then return end
	relampagoEvent.OnClientEvent:Connect(function(pos)
		local cam = workspace.CurrentCamera
		local d = (cam and typeof(pos) == "Vector3") and (cam.CFrame.Position - pos).Magnitude or 100
		local fuerza = math.clamp(1.4 - d / 150, 0.25, 1.4)
		task.spawn(flash, fuerza)
	end)
end)

-- ===== Borde rojo al recibir daño =====
local gui = Instance.new("ScreenGui")
gui.Name = "EfectosPantalla"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1
gui.Parent = playerGui

-- (sin CanvasGroup: en algunas PCs se quedaba pegado en rojo)
local contenedor = Instance.new("Frame")
contenedor.Size = UDim2.new(1, 0, 1, 0)
contenedor.BackgroundTransparency = 1
contenedor.Visible = false
contenedor.Parent = gui

local bordes = {}
local function borde(pos, size, rotacion)
	local f = Instance.new("Frame")
	f.Position = pos; f.Size = size
	f.BackgroundColor3 = RGB(210, 0, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = contenedor
	local g = Instance.new("UIGradient")
	g.Rotation = rotacion
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = f
	table.insert(bordes, f)
end
borde(UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.18, 0), 90)       -- arriba
borde(UDim2.new(0, 0, 0.82, 0), UDim2.new(1, 0, 0.18, 0), -90)   -- abajo
borde(UDim2.new(0, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), 0)        -- izquierda
borde(UDim2.new(0.86, 0, 0, 0), UDim2.new(0.14, 0, 1, 0), 180)   -- derecha

-- "grupo" imita al CanvasGroup de antes: grupo.Value = transparencia (1 = invisible)
local grupo = Instance.new("NumberValue")
grupo.Value = 1
grupo.Changed:Connect(function(v)
	for _, f in ipairs(bordes) do f.BackgroundTransparency = v end
	contenedor.Visible = v < 0.99
end)

local poca = false
local function conectar(char)
	local hum = char:WaitForChild("Humanoid")
	local previa = hum.Health
	hum.HealthChanged:Connect(function(h)
		poca = h > 0 and h / hum.MaxHealth < 0.3
		if h < previa - 0.5 then
			grupo.Value = 0.15
			TweenService:Create(grupo, TweenInfo.new(0.45), { Value = poca and 0.55 or 1 }):Play()
		end
		previa = h
	end)
end
if player.Character then task.spawn(conectar, player.Character) end
player.CharacterAdded:Connect(function(char)
	poca = false
	grupo.Value = 1
	conectar(char)
end)

-- con poca vida el borde "late" como un corazón; si te curas, se apaga del todo
task.spawn(function()
	local latiendo = false
	while true do
		if poca then
			latiendo = true
			TweenService:Create(grupo, TweenInfo.new(0.35), { Value = 0.45 }):Play()
			task.wait(0.4)
			TweenService:Create(grupo, TweenInfo.new(0.45), { Value = 0.8 }):Play()
			task.wait(0.5)
		else
			if latiendo then
				latiendo = false
				TweenService:Create(grupo, TweenInfo.new(0.4), { Value = 1 }):Play()
			end
			task.wait(0.3)
		end
	end
end)
-- seguro extra: al volver a la ventana del juego, borrar cualquier rojo que haya quedado
game:GetService("UserInputService").WindowFocused:Connect(function()
	if not poca then grupo.Value = 1 end
end)

print("✅ Ambiente del cliente listo (lluvia, rayos, borde de daño)")
