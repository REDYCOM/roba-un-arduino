--=====================================================================
--  HUD DE ROBOTS (cliente)
--  - Barra del jefe arriba (nombre + vida)
--  - Oleada actual / robots restantes / cuenta regresiva
--  - Anuncios grandes en pantalla y temblor de cámara
--  - Solo el profe (GM): [K] iniciar oleadas · [J] jefe · [L] limpiar
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local OWNER_USERID = 9330695994

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local estado       = ReplicatedStorage:WaitForChild("EstadoRobots")
local anuncioEvent = ReplicatedStorage:WaitForChild("AnuncioRobots")
local sacudirEvent = ReplicatedStorage:WaitForChild("SacudirCamara")
local controlEvent = ReplicatedStorage:WaitForChild("ControlRobots")

local function esquina(p, r)
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, r or 8); uc.Parent = p
end
local function borde(p, color, grosor)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = grosor or 2; s.Parent = p
	return s
end

local gui = Instance.new("ScreenGui")
gui.Name = "RobotsHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = playerGui

-- ===== Barra del jefe =====
local jefe = Instance.new("Frame")
jefe.AnchorPoint = Vector2.new(0.5, 0)
jefe.Position = UDim2.new(0.5, 0, 0, 12)
jefe.Size = UDim2.new(0, 520, 0, 60)
jefe.BackgroundTransparency = 1
jefe.Visible = false
jefe.Parent = gui

local jefeNombre = Instance.new("TextLabel")
jefeNombre.Size = UDim2.new(1, 0, 0, 26)
jefeNombre.BackgroundTransparency = 1
jefeNombre.Font = Enum.Font.FredokaOne
jefeNombre.TextSize = 24
jefeNombre.TextColor3 = Color3.fromRGB(255, 220, 80)
jefeNombre.TextStrokeTransparency = 0.2
jefeNombre.Parent = jefe

local barra = Instance.new("Frame")
barra.Position = UDim2.new(0, 0, 0, 30)
barra.Size = UDim2.new(1, 0, 0, 26)
barra.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
barra.Parent = jefe
esquina(barra, 10)
borde(barra, Color3.fromRGB(0, 0, 0), 3)

local relleno = Instance.new("Frame")
relleno.Size = UDim2.new(1, 0, 1, 0)
relleno.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
relleno.Parent = barra
esquina(relleno, 10)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(255, 170, 40), Color3.fromRGB(255, 90, 30))
grad.Parent = relleno

local vidaTxt = Instance.new("TextLabel")
vidaTxt.Size = UDim2.new(1, 0, 1, 0)
vidaTxt.BackgroundTransparency = 1
vidaTxt.Font = Enum.Font.GothamBlack
vidaTxt.TextSize = 16
vidaTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
vidaTxt.TextStrokeTransparency = 0.3
vidaTxt.ZIndex = 3
vidaTxt.Parent = barra

-- ===== Oleada =====
local oleada = Instance.new("TextLabel")
oleada.AnchorPoint = Vector2.new(0.5, 0)
oleada.Position = UDim2.new(0.5, 0, 0, 12)
oleada.Size = UDim2.new(0, 460, 0, 30)
oleada.BackgroundTransparency = 1
oleada.Font = Enum.Font.FredokaOne
oleada.TextSize = 22
oleada.TextColor3 = Color3.fromRGB(255, 255, 255)
oleada.TextStrokeTransparency = 0.2
oleada.Visible = false
oleada.Parent = gui

-- ===== Marcador de la gran final =====
local EQUIPOS = {
	{ nombre = "Rojo",    color = Color3.fromRGB(220, 40, 40) },
	{ nombre = "Azul",    color = Color3.fromRGB(30, 130, 255) },
	{ nombre = "Verde",   color = Color3.fromRGB(30, 200, 60) },
	{ nombre = "Naranja", color = Color3.fromRGB(255, 160, 0) },
	{ nombre = "Morado",  color = Color3.fromRGB(150, 60, 235) },
}
local finalLbl = Instance.new("TextLabel")
finalLbl.AnchorPoint = Vector2.new(0.5, 0)
finalLbl.Position = UDim2.new(0.5, 0, 0, 76)
finalLbl.Size = UDim2.new(0, 640, 0, 34)
finalLbl.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
finalLbl.BackgroundTransparency = 0.35
finalLbl.Font = Enum.Font.FredokaOne
finalLbl.TextSize = 22
finalLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
finalLbl.TextStrokeTransparency = 0.3
finalLbl.RichText = true
finalLbl.Visible = false
finalLbl.Parent = gui
esquina(finalLbl, 10)

local function equipoTxt(i, dano)
	local e = EQUIPOS[i]
	if not e then return nil end
	return string.format('<font color="#%s">%s</font> %d', e.color:ToHex(), e.nombre, dano)
end

local function actualizar()
	local fase = estado:GetAttribute("Fase")
	if fase == "final" or fase == "fin" then
		local a = equipoTxt(estado:GetAttribute("FinalA") or 0, estado:GetAttribute("DanoA") or 0)
		local b = equipoTxt(estado:GetAttribute("FinalB") or 0, estado:GetAttribute("DanoB") or 0)
		local cuenta = estado:GetAttribute("Cuenta") or 0
		local reloj = string.format("⏱ %d:%02d", cuenta // 60, cuenta % 60)
		local partes = {}
		if a then table.insert(partes, a) end
		if b then table.insert(partes, b) end
		finalLbl.Text = "⚔️ DAÑO AL JEFE:  " .. table.concat(partes, "   vs   ") .. "     " .. reloj
		finalLbl.Visible = true
	else
		finalLbl.Visible = false
	end
	local nombreJefe = estado:GetAttribute("JefeNombre") or ""
	local hayJefe = nombreJefe ~= ""

	jefe.Visible = hayJefe
	if hayJefe then
		local v = estado:GetAttribute("JefeVida") or 0
		local vmax = math.max(1, estado:GetAttribute("JefeVidaMax") or 1)
		jefeNombre.Text = "👹 " .. nombreJefe
		vidaTxt.Text = string.format("%d / %d", v, vmax)
		TweenService:Create(relleno, TweenInfo.new(0.15), { Size = UDim2.new(math.clamp(v / vmax, 0, 1), 0, 1, 0) }):Play()
	end

	oleada.Position = UDim2.new(0.5, 0, 0, hayJefe and 76 or 12)
	if fase == "oleada" then
		oleada.Visible = true
		oleada.Text = string.format("🤖 OLEADA %d   ·   Robots: %d",
			estado:GetAttribute("Oleada") or 0, estado:GetAttribute("Restantes") or 0)
	elseif fase == "descanso" then
		oleada.Visible = true
		oleada.Text = string.format("⏳ Siguiente oleada en %d...", estado:GetAttribute("Cuenta") or 0)
	else
		oleada.Visible = false
	end
end

for _, k in ipairs({ "Fase", "Oleada", "Restantes", "Cuenta", "JefeNombre", "JefeVida", "JefeVidaMax",
	"FinalA", "FinalB", "DanoA", "DanoB" }) do
	estado:GetAttributeChangedSignal(k):Connect(actualizar)
end
actualizar()

-- ===== Anuncios grandes =====
local anuncio = Instance.new("TextLabel")
anuncio.AnchorPoint = Vector2.new(0.5, 0.5)
anuncio.Position = UDim2.new(0.5, 0, 0.3, 0)
anuncio.Size = UDim2.new(0.9, 0, 0, 70)
anuncio.BackgroundTransparency = 1
anuncio.Font = Enum.Font.FredokaOne
anuncio.TextSize = 46
anuncio.TextStrokeTransparency = 0
anuncio.TextTransparency = 1
anuncio.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
anuncio.Parent = gui
local escalaAnuncio = Instance.new("UIScale")
escalaAnuncio.Parent = anuncio

local idAnuncio = 0
anuncioEvent.OnClientEvent:Connect(function(texto, color, duracion)
	idAnuncio += 1
	local miId = idAnuncio
	anuncio.Text = texto
	anuncio.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	anuncio.TextTransparency = 0
	anuncio.TextStrokeTransparency = 0
	escalaAnuncio.Scale = 0.4
	TweenService:Create(escalaAnuncio, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(duracion or 3, function()
		if miId ~= idAnuncio then return end
		TweenService:Create(anuncio, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end)

-- ===== Temblor de cámara =====
local temblorHasta, temblorInt, temblorDur = 0, 0, 1
sacudirEvent.OnClientEvent:Connect(function(intensidad, duracion)
	-- si ya está temblando más fuerte, no lo reemplaza
	local restante = temblorHasta - tick()
	if restante > 0 and temblorInt * (restante / temblorDur) > intensidad then return end
	temblorInt, temblorDur = intensidad, duracion
	temblorHasta = tick() + duracion
end)

local temblando = false
RunService.RenderStepped:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local resto = temblorHasta - tick()
	if resto > 0 then
		temblando = true
		local i = temblorInt * (resto / temblorDur)
		hum.CameraOffset = Vector3.new(
			(math.random() - 0.5) * i,
			(math.random() - 0.5) * i,
			(math.random() - 0.5) * i
		)
	elseif temblando then
		temblando = false
		hum.CameraOffset = Vector3.new(0, 0, 0)
	end
end)

-- ===== Controles del profe =====
local function esGM()
	return player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster") == true
end

local ayudaGM = Instance.new("TextLabel")
ayudaGM.AnchorPoint = Vector2.new(0, 1)
ayudaGM.Position = UDim2.new(0, 12, 1, -50)
ayudaGM.Size = UDim2.new(0, 680, 0, 28)
ayudaGM.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
ayudaGM.BackgroundTransparency = 0.25
ayudaGM.Font = Enum.Font.GothamBold
ayudaGM.TextSize = 13
ayudaGM.TextColor3 = Color3.fromRGB(255, 200, 120)
ayudaGM.Text = "👑 Profe: [N] empezar partida · [K] oleadas · [J] jefe · [H] drones · [U] runa · [P] +500 · [G] FINAL · [L] limpiar"
ayudaGM.Visible = false
ayudaGM.Parent = gui
esquina(ayudaGM, 8)

task.spawn(function()
	task.wait(2)  -- dar tiempo a que se marque el atributo de GM
	ayudaGM.Visible = esGM()
end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then return end
	-- [N] empezar partida: el profe, o cualquiera mientras se prueba en Studio
	if input.KeyCode == Enum.KeyCode.N and (esGM() or game:GetService("RunService"):IsStudio()) then
		controlEvent:FireServer("empezar") -- abre las rejas en 5 s (TeamSystem)
		return
	end
	if not esGM() then return end
	if input.KeyCode == Enum.KeyCode.K then
		controlEvent:FireServer("iniciar")
	elseif input.KeyCode == Enum.KeyCode.J then
		controlEvent:FireServer("jefe")
	elseif input.KeyCode == Enum.KeyCode.L then
		controlEvent:FireServer("limpiar")
	elseif input.KeyCode == Enum.KeyCode.H then
		controlEvent:FireServer("drones")
	elseif input.KeyCode == Enum.KeyCode.U then
		controlEvent:FireServer("runa")
	elseif input.KeyCode == Enum.KeyCode.P then
		controlEvent:FireServer("puntos")
	elseif input.KeyCode == Enum.KeyCode.G then
		controlEvent:FireServer("final")
	end
end)

print("✅ HUD de robots listo")
