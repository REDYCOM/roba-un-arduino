-- ServerScriptService > BaseDetector (CORREGIDO - SIN CUADRADO BLANCO)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- RemoteEvents
local notifyRemote = ReplicatedStorage:FindFirstChild("NotifyDelivery")
if not notifyRemote then
	notifyRemote = Instance.new("RemoteEvent")
	notifyRemote.Name = "NotifyDelivery"
	notifyRemote.Parent = ReplicatedStorage
end

local errorRemote = ReplicatedStorage:FindFirstChild("ShowError")
if not errorRemote then
	errorRemote = Instance.new("RemoteEvent")
	errorRemote.Name = "ShowError"
	errorRemote.Parent = ReplicatedStorage
end

-- 🎨 COLORES POR EQUIPO (DEFINITIVOS)
local TEAM_COLORS = {
	[1] = Color3.fromRGB(220, 20, 20),    -- 🔴 Rojo
	[2] = Color3.fromRGB(30, 130, 255),   -- 🔵 Azul
	[3] = Color3.fromRGB(20, 220, 20),    -- 🟢 Verde
	[4] = Color3.fromRGB(255, 165, 0),    -- 🟠 Naranja
	[5] = Color3.fromRGB(147, 51, 234),   -- 🟣 Púrpura
}

local GM_COLOR = Color3.fromRGB(20, 20, 20) -- ⚫ Negro para GM

local function getTeamColor(teamNumber)
	return TEAM_COLORS[teamNumber] or Color3.fromRGB(100, 100, 100)
end

local function getPlayerTeam(player)
	return player:GetAttribute("TeamNumber")
end
local function notifyTeam(teamNumber, itemName, baseName, notifType, thiefName)
	for _, player in pairs(Players:GetPlayers()) do
		local playerTeam = getPlayerTeam(player)
		if playerTeam == teamNumber then
			notifyRemote:FireClient(player, itemName, baseName, notifType, thiefName)
		end
	end
end

-- ✅ SISTEMA DE BARRAS DE EQUIPO SIMPLIFICADO (SIN DUPLICADOS)
local playerTeamBars = {}

-- ⚙️ CONFIGURACIÓN DEL OWNER/GM
local OWNER_USERID = 9330695994



local function isGameMaster(player)
	return player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster")
end

local function createTeamBar(player)
	local character = player.Character
	if not character or not character:FindFirstChild("Head") then return end

	-- Eliminar barra anterior si existe
	if playerTeamBars[player] then
		playerTeamBars[player]:Destroy()
		playerTeamBars[player] = nil
	end

	local head = character.Head

	-- 🎯 CREAR BILLBOARD GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TeamBar"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 150, 0, 35)  -- Tamaño ajustado
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)  -- ✅ MÁS ARRIBA (era 2.5)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = head

	-- 📦 FRAME PRINCIPAL (contenedor)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1  -- Transparente para no mostrar fondo
	mainFrame.Parent = billboard

	-- 🎨 FRAME DE EQUIPO (la barra de color)
	local teamFrame = Instance.new("Frame")
	teamFrame.Name = "TeamFrame"
	teamFrame.Size = UDim2.new(1, -4, 0.6, 0)
	teamFrame.Position = UDim2.new(0, 2, 0, 0)
	teamFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)  -- Color por defecto
	teamFrame.BorderSizePixel = 0
	teamFrame.Parent = mainFrame

	local teamCorner = Instance.new("UICorner")
	teamCorner.CornerRadius = UDim.new(0, 8)
	teamCorner.Parent = teamFrame

	-- 📝 LABEL DE EQUIPO
	local teamLabel = Instance.new("TextLabel")
	teamLabel.Name = "TeamLabel"
	teamLabel.Size = UDim2.new(1, 0, 1, 0)
	teamLabel.BackgroundTransparency = 1
	teamLabel.Text = "Sin Equipo"
	teamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	teamLabel.Font = Enum.Font.GothamBold
	teamLabel.TextScaled = true
	teamLabel.TextStrokeTransparency = 0.5
	teamLabel.Parent = teamFrame

	-- 👤 FRAME DE NOMBRE (opcional, debajo del equipo)
	local nameFrame = Instance.new("Frame")
	nameFrame.Name = "NameFrame"
	nameFrame.Size = UDim2.new(1, -4, 0.35, 0)
	nameFrame.Position = UDim2.new(0, 2, 0.65, 0)
	nameFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	nameFrame.BorderSizePixel = 0
	nameFrame.Parent = mainFrame

	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 6)
	nameCorner.Parent = nameFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextScaled = true
	nameLabel.TextStrokeTransparency = 0.7
	nameLabel.Parent = nameFrame

	playerTeamBars[player] = billboard

	-- Actualizar inmediatamente
	updateTeamBar(player)
end

function updateTeamBar(player)
	local bar = playerTeamBars[player]
	if not bar or not bar.Parent then return end

	local teamFrame = bar:FindFirstChild("TeamFrame", true)
	local teamLabel = teamFrame and teamFrame:FindFirstChild("TeamLabel")

	-- ✅ VERIFICAR SI ES GM PRIMERO
	if isGameMaster(player) then
		if teamFrame then
			teamFrame.BackgroundColor3 = GM_COLOR -- ⚫ Negro
		end
		if teamLabel then
			teamLabel.Text = "ARDUNOL"
		end
		return
	end

	local teamNumber = getPlayerTeam(player)

	-- ✅ ASIGNAR COLOR SEGÚN EL EQUIPO
	if teamFrame then
		if teamNumber then
			teamFrame.BackgroundColor3 = TEAM_COLORS[teamNumber] or Color3.fromRGB(100, 100, 100)
		else
			teamFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end
	end

	if teamLabel then
		if teamNumber then
			teamLabel.Text = "Equipo " .. teamNumber
		else
			teamLabel.Text = "Sin Equipo"
		end
	end
end

local function updateAllTeamBarsForViewer(viewerPlayer)
	-- ✅ AHORA TODOS VEN LOS COLORES REALES DE CADA EQUIPO
	for targetPlayer, bar in pairs(playerTeamBars) do
		if bar.Parent then
			local teamFrame = bar:FindFirstChild("TeamFrame", true)

			if teamFrame then
				-- ✅ SI EL OBJETIVO ES GM, MOSTRAR NEGRO
				if isGameMaster(targetPlayer) then
					teamFrame.BackgroundColor3 = GM_COLOR -- ⚫ Negro
				else
					-- ✅ MOSTRAR EL COLOR DEL EQUIPO AL QUE PERTENECE
					local targetTeam = getPlayerTeam(targetPlayer)
					if targetTeam then
						teamFrame.BackgroundColor3 = TEAM_COLORS[targetTeam] or Color3.fromRGB(100, 100, 100)
					else
						teamFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					end
				end
			end
		end
	end
end

-- ✅ EVENTOS DE JUGADORES
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		createTeamBar(player)
	end)

	player:GetAttributeChangedSignal("TeamNumber"):Connect(function()
		updateTeamBar(player)
		-- Actualizar vista para todos
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			updateAllTeamBarsForViewer(otherPlayer)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if playerTeamBars[player] then
		playerTeamBars[player]:Destroy()
		playerTeamBars[player] = nil
	end
end)

-- Inicializar para jugadores ya conectados
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		createTeamBar(player)
	end

	player:GetAttributeChangedSignal("TeamNumber"):Connect(function()
		updateTeamBar(player)
		for _, otherPlayer in pairs(Players:GetPlayers()) do
			updateAllTeamBarsForViewer(otherPlayer)
		end
	end)
end

-- Loop de actualización periódica
RunService.Heartbeat:Connect(function()
	if tick() % 1 < 0.016 then  -- Cada ~1 segundo
		for _, player in pairs(Players:GetPlayers()) do
			updateAllTeamBarsForViewer(player)
		end
	end
end)

print("✅ Sistema de barras de equipo iniciado (sin cuadrado blanco)")

-- =====================================================
-- 🏷️ SISTEMA DE OBJETOS Y BASES
-- =====================================================

local function setObjectTeam(object, teamNumber)
	object:SetAttribute("CurrentTeam", teamNumber)
end

local function getObjectTeam(object)
	return object:GetAttribute("CurrentTeam")
end

-- Detectar bases
local BASES = {}
local baseDeliveries = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, {})
		return rawget(t, k)
	end
})

for _, obj in pairs(workspace:GetChildren()) do
	if obj:IsA("Model") and string.find(string.lower(obj.Name), "baseequipo") then
		if obj.PrimaryPart then
			table.insert(BASES, obj)
			obj:SetAttribute("ObjectCount", 0)
		end
	end
end

local DETECTION_RADIUS = 15
local MAX_ITEMS = 9

-- 🎨 FUNCIONES DE EFECTOS VISUALES
local function disableFloatingGlow(heldItem)
	if not heldItem:GetAttribute("FloatingEnabled") then return end
	local primary = heldItem.PrimaryPart
	if primary then
		if primary:FindFirstChild("FloatingLight") then primary.FloatingLight:Destroy() end
		if primary:FindFirstChild("BodyVelocity") then primary.BodyVelocity:Destroy() end
		if primary:FindFirstChild("FloatVelocity") then primary.FloatVelocity:Destroy() end
		if primary:FindFirstChild("FloatRotation") then primary.FloatRotation:Destroy() end
		if primary:FindFirstChild("BodyAngularVelocity") then primary.BodyAngularVelocity:Destroy() end
		for _, att in pairs(primary:GetChildren()) do
			if att:IsA("Attachment") then
				for _, child in pairs(att:GetChildren()) do
					if child:IsA("ParticleEmitter") then child:Destroy() end
				end
				att:Destroy()
			end
		end
	end
	heldItem:SetAttribute("FloatingEnabled", false)
end

local function disableFloatingEffects(heldItem)
	local primary = heldItem.PrimaryPart
	if not primary then return end
	if primary:FindFirstChild("FloatVelocity") then primary.FloatVelocity:Destroy() end
	if primary:FindFirstChild("FloatRotation") then primary.FloatRotation:Destroy() end
	if primary:FindFirstChild("BodyVelocity") then primary.BodyVelocity:Destroy() end
	if primary:FindFirstChild("BodyAngularVelocity") then primary.BodyAngularVelocity:Destroy() end
	heldItem:SetAttribute("FloatingEnabled", false)
end

local function enableFloatingGlow(heldItem, teamNumber)
	local primary = heldItem.PrimaryPart
	if not primary then return end

	local currentTeam = getObjectTeam(heldItem) or teamNumber
	local teamColor = getTeamColor(currentTeam)

	disableFloatingGlow(heldItem)

	local light = Instance.new("PointLight")
	light.Name = "FloatingLight"
	light.Brightness = 2
	light.Range = 15
	light.Color = teamColor
	light.Parent = primary

	local attachment = Instance.new("Attachment")
	attachment.Parent = primary
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 50
	particles.SpreadAngle = Vector2.new(45, 45)
	particles.Speed = NumberRange.new(2)
	particles.Color = ColorSequence.new(teamColor)
	particles.Parent = attachment

	local anchoredBase = heldItem:GetAttribute("AnchoredToBase")
	if anchoredBase then
		if not primary:FindFirstChild("FloatVelocity") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "FloatVelocity"
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.P = 1000
			bv.Parent = primary
		end
		if not primary:FindFirstChild("FloatRotation") then
			local bav = Instance.new("BodyAngularVelocity")
			bav.Name = "FloatRotation"
			bav.MaxTorque = Vector3.new(0, math.huge, 0)
			bav.AngularVelocity = Vector3.new(0, 2, 0)
			bav.Parent = primary
		end
	end
	heldItem:SetAttribute("FloatingEnabled", true)
end

local function countObjectsInBase(baseName)
	local count = 0
	if baseDeliveries[baseName] then
		for itemName, _ in pairs(baseDeliveries[baseName]) do
			count = count + 1
		end
	end
	return count
end

local function anchorToBase(heldItem, base)
	local primary = heldItem.PrimaryPart
	if not primary then return end

	heldItem:SetAttribute("AnchoredToBase", base.Name)

	local currentPos = primary.Position
	local baseY = base.PrimaryPart.Position.Y

	if currentPos.Y < baseY + 3 then
		primary.CFrame = CFrame.new(currentPos.X, baseY + 5, currentPos.Z)
	end

	primary.Anchored = false
	for _, part in pairs(heldItem:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
		end
	end

	local oldBV = primary:FindFirstChild("BodyVelocity")
	if oldBV then oldBV:Destroy() end

	local bv = Instance.new("BodyVelocity")
	bv.Name = "FloatVelocity"
	bv.MaxForce = Vector3.new(0, math.huge, 0)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.P = 1000
	bv.Parent = primary
end

local function unanchorFromBase(heldItem)
	local currentTeam = getObjectTeam(heldItem)
	heldItem:SetAttribute("AnchoredToBase", nil)

	disableFloatingEffects(heldItem)

	local primary = heldItem.PrimaryPart
	if primary then
		if not primary:FindFirstChild("FloatingLight") and currentTeam then
			local teamColor = getTeamColor(currentTeam)
			local light = Instance.new("PointLight")
			light.Name = "FloatingLight"
			light.Brightness = 2
			light.Range = 15
			light.Color = teamColor
			light.Parent = primary
		end
	end

	for _, part in pairs(heldItem:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Massless = false
			part.CanCollide = true
		end
	end
end

local playerErrorCooldown = {}

-- LOOP DE DETECCIÓN
-- LOOP DE DETECCIÓN
RunService.Heartbeat:Connect(function()
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end

		local heldItem = nil
		for _, child in pairs(char:GetChildren()) do
			if child:IsA("Model") and child.PrimaryPart then
				if child.PrimaryPart:FindFirstChild("ProximityPrompt") then
					heldItem = child
					break
				end
			end
		end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local playerName = player.Name
		local playerTeam = getPlayerTeam(player)
		local nearBase = false
		local currentBase = nil

		for _, base in pairs(BASES) do
			if (hrp.Position - base.PrimaryPart.Position).Magnitude <= DETECTION_RADIUS then
				nearBase = true
				currentBase = base
				break
			end
		end

		if heldItem and nearBase then
			local itemName = heldItem.Name
			local baseName = currentBase.Name
			local baseTeam = tonumber(string.match(currentBase.Name, "%d+"))

			local objectTeam = getObjectTeam(heldItem)
			local isEnemyObject = objectTeam and objectTeam ~= playerTeam
			local isMyBase = playerTeam == baseTeam

			if not playerTeam then continue end

			if isMyBase and not isEnemyObject then
				local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

				if not baseDeliveries[baseName][itemName] then
					local currentCount = countObjectsInBase(baseName)
					if currentCount < MAX_ITEMS then
						baseDeliveries[baseName][itemName] = true

						-- ✅ CAMBIO: Notificar a TODO el equipo
						notifyTeam(playerTeam, itemName, baseName, "DELIVERED")

						anchorToBase(heldItem, currentBase)
						setObjectTeam(heldItem, playerTeam)

						currentBase:SetAttribute("ObjectCount", currentCount + 1)

						enableFloatingGlow(heldItem, playerTeam)
						print("📦", playerName, "entregó", itemName, "a", baseName)
					end
				else
					enableFloatingGlow(heldItem, playerTeam)
				end

			elseif isEnemyObject then
				local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

				if anchoredBase and baseDeliveries[anchoredBase] and baseDeliveries[anchoredBase][itemName] then
					-- ✅ CAMBIO: Notificar al equipo víctima
					local victimTeam = tonumber(string.match(anchoredBase, "%d+"))
					if victimTeam then
						notifyTeam(victimTeam, itemName, anchoredBase, "STOLEN", playerName)
					end

					baseDeliveries[anchoredBase][itemName] = nil

					local originalBase = workspace:FindFirstChild(anchoredBase)
					if originalBase then
						local currentCount = countObjectsInBase(anchoredBase)
						originalBase:SetAttribute("ObjectCount", currentCount)
					end

					unanchorFromBase(heldItem)
					print("🚨", playerName, "robó", itemName, "de", anchoredBase)
				end

			else
				if not playerErrorCooldown[player.UserId] or (tick() - playerErrorCooldown[player.UserId]) > 2 then
					errorRemote:FireClient(player, "⚠️ BASE INCORRECTA", "No puedes entregar objetos enemigos aquí")
					playerErrorCooldown[player.UserId] = tick()
				end
				disableFloatingEffects(heldItem)
			end

		elseif heldItem and not nearBase then
			local objectTeam = getObjectTeam(heldItem)
			local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

			if anchoredBase and baseDeliveries[anchoredBase] and baseDeliveries[anchoredBase][heldItem.Name] then
				-- ✅ CAMBIO: Notificar al equipo víctima
				local victimTeam = tonumber(string.match(anchoredBase, "%d+"))
				if victimTeam then
					notifyTeam(victimTeam, heldItem.Name, anchoredBase, "STOLEN", playerName)
				end

				baseDeliveries[anchoredBase][heldItem.Name] = nil

				local originalBase = workspace:FindFirstChild(anchoredBase)
				if originalBase then
					local currentCount = countObjectsInBase(anchoredBase)
					originalBase:SetAttribute("ObjectCount", currentCount)
				end

				unanchorFromBase(heldItem)
				print("🚨", playerName, "robó", heldItem.Name, "de", anchoredBase)
			end

			if objectTeam then
				local primary = heldItem.PrimaryPart
				if primary then
					if not primary:FindFirstChild("FloatingLight") then
						local teamColor = getTeamColor(objectTeam)
						local light = Instance.new("PointLight")
						light.Name = "FloatingLight"
						light.Brightness = 2
						light.Range = 15
						light.Color = teamColor
						light.Parent = primary
					end

					local hasParticles = false
					for _, att in pairs(primary:GetChildren()) do
						if att:IsA("Attachment") and att:FindFirstChildOfClass("ParticleEmitter") then
							hasParticles = true
							break
						end
					end

					if not hasParticles then
						local attachment = Instance.new("Attachment")
						attachment.Parent = primary
						local particles = Instance.new("ParticleEmitter")
						particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
						particles.Lifetime = NumberRange.new(1, 2)
						particles.Rate = 50
						particles.SpreadAngle = Vector2.new(45, 45)
						particles.Speed = NumberRange.new(2)
						particles.Color = ColorSequence.new(getTeamColor(objectTeam))
						particles.Parent = attachment
					end
				end

				disableFloatingEffects(heldItem)
			else
				disableFloatingGlow(heldItem)
			end
		end
	end
end)
-- === RESTO DE TU CÓDIGO (COUNTDOWN, ETC.) ===
local activeCountdowns = {}

local function baseHasAllComponents(baseName)
	local count = countObjectsInBase(baseName)
	return count >= 9
end

local function createBaseCountdownGui(base)
	local oldGui = base.PrimaryPart:FindFirstChild("BaseCountdownBillboard")
	if oldGui then oldGui:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BaseCountdownBillboard"
	billboard.Adornee = base.PrimaryPart
	billboard.Size = UDim2.new(0, 200, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 30, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = base.PrimaryPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = frame

	local tween = game:GetService("TweenService"):Create(
		frame,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundColor3 = Color3.fromRGB(255, 150, 0)}
	)
	tween:Play()

	local alert = Instance.new("TextLabel")
	alert.Size = UDim2.new(1, 0, 0.4, 0)
	alert.Position = UDim2.new(0, 0, 0, 5)
	alert.BackgroundTransparency = 1
	alert.Text = "⚠️ PROGRAMANDO ROBOT ⚠️"
	alert.TextColor3 = Color3.fromRGB(255, 255, 255)
	alert.Font = Enum.Font.GothamBold
	alert.TextScaled = true
	alert.TextStrokeTransparency = 0
	alert.Parent = frame

	local baseLabel = Instance.new("TextLabel")
	baseLabel.Size = UDim2.new(1, 0, 0.25, 0)
	baseLabel.Position = UDim2.new(0, 0, 0.4, 0)
	baseLabel.BackgroundTransparency = 1
	baseLabel.Text = base.Name
	baseLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	baseLabel.Font = Enum.Font.GothamBold
	baseLabel.TextScaled = true
	baseLabel.TextStrokeTransparency = 0
	baseLabel.Parent = frame

	local timer = Instance.new("TextLabel")
	timer.Name = "TimerLabel"
	timer.Size = UDim2.new(1, 0, 0.35, 0)
	timer.Position = UDim2.new(0, 0, 0.65, 0)
	timer.BackgroundTransparency = 1
	timer.Text = "2:00"
	timer.TextColor3 = Color3.fromRGB(255, 255, 255)
	timer.Font = Enum.Font.GothamBold
	timer.TextScaled = true
	timer.TextStrokeTransparency = 0
	timer.Parent = frame

	return billboard
end

local function createPlayerCountdownGui(player, baseName)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	local oldGui = playerGui:FindFirstChild("TeamCountdownGui")
	if oldGui then oldGui:Destroy() end

	local playerTeam = getPlayerTeam(player)
	local baseTeam = tonumber(string.match(baseName, "%d+"))

	if playerTeam ~= baseTeam then return nil end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TeamCountdownGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local teamColor = getTeamColor(playerTeam)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 450, 0, 130)
	frame.Position = UDim2.new(0.5, -225, 0.02, 0)
	frame.BackgroundColor3 = teamColor
	frame.BorderSizePixel = 0
	frame.ZIndex = 100
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🚀 PROGRAMANDO EL ROBOT"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 101
	title.Parent = frame

	local warning = Instance.new("TextLabel")
	warning.Size = UDim2.new(1, -20, 0, 36)
	warning.Position = UDim2.new(0, 10, 0, 38)
	warning.BackgroundTransparency = 1
	warning.Text = "⚠️ No dejes que roben los componentes electrónicos"
	warning.TextColor3 = Color3.fromRGB(255, 255, 255)
	warning.Font = Enum.Font.Gotham
	warning.TextSize = 16
	warning.TextWrapped = true-- ServerScriptService > BaseDetector (CORREGIDO - SIN CUADRADO BLANCO)
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")

	-- RemoteEvents
	local notifyRemote = ReplicatedStorage:FindFirstChild("NotifyDelivery")
	if not notifyRemote then
		notifyRemote = Instance.new("RemoteEvent")
		notifyRemote.Name = "NotifyDelivery"
		notifyRemote.Parent = ReplicatedStorage
	end

	local errorRemote = ReplicatedStorage:FindFirstChild("ShowError")
	if not errorRemote then
		errorRemote = Instance.new("RemoteEvent")
		errorRemote.Name = "ShowError"
		errorRemote.Parent = ReplicatedStorage
	end

	-- 🎨 COLORES POR EQUIPO (DEFINITIVOS)
	local TEAM_COLORS = {
		[1] = Color3.fromRGB(220, 20, 20),    -- 🔴 Rojo
		[2] = Color3.fromRGB(30, 130, 255),   -- 🔵 Azul
		[3] = Color3.fromRGB(20, 220, 20),    -- 🟢 Verde
		[4] = Color3.fromRGB(255, 165, 0),    -- 🟠 Naranja
		[5] = Color3.fromRGB(147, 51, 234),   -- 🟣 Púrpura
	}

	local GM_COLOR = Color3.fromRGB(20, 20, 20) -- ⚫ Negro para GM

	local function getTeamColor(teamNumber)
		return TEAM_COLORS[teamNumber] or Color3.fromRGB(100, 100, 100)
	end

	local function getPlayerTeam(player)
		return player:GetAttribute("TeamNumber")
	end

	-- ✅ SISTEMA DE BARRAS DE EQUIPO SIMPLIFICADO (SIN DUPLICADOS)
	local playerTeamBars = {}

	-- ⚙️ CONFIGURACIÓN DEL OWNER/GM
	local OWNER_USERID = 9330695994

	local function isGameMaster(player)
		return player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster")
	end

	local function createTeamBar(player)
		local character = player.Character
		if not character or not character:FindFirstChild("Head") then return end

		-- Eliminar barra anterior si existe
		if playerTeamBars[player] then
			playerTeamBars[player]:Destroy()
			playerTeamBars[player] = nil
		end

		local head = character.Head

		-- 🎯 CREAR BILLBOARD GUI
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "TeamBar"
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 150, 0, 35)  -- Tamaño ajustado
		billboard.StudsOffset = Vector3.new(0, 3.2, 0)  -- ✅ MÁS ARRIBA (era 2.5)
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.Parent = head

		-- 📦 FRAME PRINCIPAL (contenedor)
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(1, 0, 1, 0)
		mainFrame.BackgroundTransparency = 1  -- Transparente para no mostrar fondo
		mainFrame.Parent = billboard

		-- 🎨 FRAME DE EQUIPO (la barra de color)
		local teamFrame = Instance.new("Frame")
		teamFrame.Name = "TeamFrame"
		teamFrame.Size = UDim2.new(1, -4, 0.6, 0)
		teamFrame.Position = UDim2.new(0, 2, 0, 0)
		teamFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)  -- Color por defecto
		teamFrame.BorderSizePixel = 0
		teamFrame.Parent = mainFrame

		local teamCorner = Instance.new("UICorner")
		teamCorner.CornerRadius = UDim.new(0, 8)
		teamCorner.Parent = teamFrame

		-- 📝 LABEL DE EQUIPO
		local teamLabel = Instance.new("TextLabel")
		teamLabel.Name = "TeamLabel"
		teamLabel.Size = UDim2.new(1, 0, 1, 0)
		teamLabel.BackgroundTransparency = 1
		teamLabel.Text = "Sin Equipo"
		teamLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		teamLabel.Font = Enum.Font.GothamBold
		teamLabel.TextScaled = true
		teamLabel.TextStrokeTransparency = 0.5
		teamLabel.Parent = teamFrame

		-- 👤 FRAME DE NOMBRE (opcional, debajo del equipo)
		local nameFrame = Instance.new("Frame")
		nameFrame.Name = "NameFrame"
		nameFrame.Size = UDim2.new(1, -4, 0.35, 0)
		nameFrame.Position = UDim2.new(0, 2, 0.65, 0)
		nameFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		nameFrame.BorderSizePixel = 0
		nameFrame.Parent = mainFrame

		local nameCorner = Instance.new("UICorner")
		nameCorner.CornerRadius = UDim.new(0, 6)
		nameCorner.Parent = nameFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextScaled = true
		nameLabel.TextStrokeTransparency = 0.7
		nameLabel.Parent = nameFrame

		playerTeamBars[player] = billboard

		-- Actualizar inmediatamente
		updateTeamBar(player)
	end

	function updateTeamBar(player)
		local bar = playerTeamBars[player]
		if not bar or not bar.Parent then return end

		local teamFrame = bar:FindFirstChild("TeamFrame", true)
		local teamLabel = teamFrame and teamFrame:FindFirstChild("TeamLabel")

		-- ✅ VERIFICAR SI ES GM PRIMERO
		if isGameMaster(player) then
			if teamFrame then
				teamFrame.BackgroundColor3 = GM_COLOR -- ⚫ Negro
			end
			if teamLabel then
				teamLabel.Text = "ARDUNOL"
			end
			return
		end

		local teamNumber = getPlayerTeam(player)

		-- ✅ ASIGNAR COLOR SEGÚN EL EQUIPO
		if teamFrame then
			if teamNumber then
				teamFrame.BackgroundColor3 = TEAM_COLORS[teamNumber] or Color3.fromRGB(100, 100, 100)
			else
				teamFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			end
		end

		if teamLabel then
			if teamNumber then
				teamLabel.Text = "Equipo " .. teamNumber
			else
				teamLabel.Text = "Sin Equipo"
			end
		end
	end

	local function updateAllTeamBarsForViewer(viewerPlayer)
		-- ✅ AHORA TODOS VEN LOS COLORES REALES DE CADA EQUIPO
		for targetPlayer, bar in pairs(playerTeamBars) do
			if bar.Parent then
				local teamFrame = bar:FindFirstChild("TeamFrame", true)

				if teamFrame then
					-- ✅ SI EL OBJETIVO ES GM, MOSTRAR NEGRO
					if isGameMaster(targetPlayer) then
						teamFrame.BackgroundColor3 = GM_COLOR -- ⚫ Negro
					else
						-- ✅ MOSTRAR EL COLOR DEL EQUIPO AL QUE PERTENECE
						local targetTeam = getPlayerTeam(targetPlayer)
						if targetTeam then
							teamFrame.BackgroundColor3 = TEAM_COLORS[targetTeam] or Color3.fromRGB(100, 100, 100)
						else
							teamFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
						end
					end
				end
			end
		end
	end

	-- ✅ EVENTOS DE JUGADORES
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			createTeamBar(player)
		end)

		player:GetAttributeChangedSignal("TeamNumber"):Connect(function()
			updateTeamBar(player)
			-- Actualizar vista para todos
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				updateAllTeamBarsForViewer(otherPlayer)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if playerTeamBars[player] then
			playerTeamBars[player]:Destroy()
			playerTeamBars[player] = nil
		end
	end)

	-- Inicializar para jugadores ya conectados
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			createTeamBar(player)
		end

		player:GetAttributeChangedSignal("TeamNumber"):Connect(function()
			updateTeamBar(player)
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				updateAllTeamBarsForViewer(otherPlayer)
			end
		end)
	end

	-- Loop de actualización periódica
	RunService.Heartbeat:Connect(function()
		if tick() % 1 < 0.016 then  -- Cada ~1 segundo
			for _, player in pairs(Players:GetPlayers()) do
				updateAllTeamBarsForViewer(player)
			end
		end
	end)

	print("✅ Sistema de barras de equipo iniciado (sin cuadrado blanco)")

	-- =====================================================
	-- 🏷️ SISTEMA DE OBJETOS Y BASES
	-- =====================================================

	local function setObjectTeam(object, teamNumber)
		object:SetAttribute("CurrentTeam", teamNumber)
	end

	local function getObjectTeam(object)
		return object:GetAttribute("CurrentTeam")
	end

	-- Detectar bases
	local BASES = {}
	local baseDeliveries = setmetatable({}, {
		__index = function(t, k)
			rawset(t, k, {})
			return rawget(t, k)
		end
	})

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and string.find(string.lower(obj.Name), "baseequipo") then
			if obj.PrimaryPart then
				table.insert(BASES, obj)
				obj:SetAttribute("ObjectCount", 0)
			end
		end
	end

	local DETECTION_RADIUS = 15
	local MAX_ITEMS = 9

	-- 🎨 FUNCIONES DE EFECTOS VISUALES
	local function disableFloatingGlow(heldItem)
		if not heldItem:GetAttribute("FloatingEnabled") then return end
		local primary = heldItem.PrimaryPart
		if primary then
			if primary:FindFirstChild("FloatingLight") then primary.FloatingLight:Destroy() end
			if primary:FindFirstChild("BodyVelocity") then primary.BodyVelocity:Destroy() end
			if primary:FindFirstChild("FloatVelocity") then primary.FloatVelocity:Destroy() end
			if primary:FindFirstChild("FloatRotation") then primary.FloatRotation:Destroy() end
			if primary:FindFirstChild("BodyAngularVelocity") then primary.BodyAngularVelocity:Destroy() end
			for _, att in pairs(primary:GetChildren()) do
				if att:IsA("Attachment") then
					for _, child in pairs(att:GetChildren()) do
						if child:IsA("ParticleEmitter") then child:Destroy() end
					end
					att:Destroy()
				end
			end
		end
		heldItem:SetAttribute("FloatingEnabled", false)
	end

	local function disableFloatingEffects(heldItem)
		local primary = heldItem.PrimaryPart
		if not primary then return end
		if primary:FindFirstChild("FloatVelocity") then primary.FloatVelocity:Destroy() end
		if primary:FindFirstChild("FloatRotation") then primary.FloatRotation:Destroy() end
		if primary:FindFirstChild("BodyVelocity") then primary.BodyVelocity:Destroy() end
		if primary:FindFirstChild("BodyAngularVelocity") then primary.BodyAngularVelocity:Destroy() end
		heldItem:SetAttribute("FloatingEnabled", false)
	end

	local function enableFloatingGlow(heldItem, teamNumber)
		local primary = heldItem.PrimaryPart
		if not primary then return end

		local currentTeam = getObjectTeam(heldItem) or teamNumber
		local teamColor = getTeamColor(currentTeam)

		disableFloatingGlow(heldItem)

		local light = Instance.new("PointLight")
		light.Name = "FloatingLight"
		light.Brightness = 2
		light.Range = 15
		light.Color = teamColor
		light.Parent = primary

		local attachment = Instance.new("Attachment")
		attachment.Parent = primary
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Rate = 50
		particles.SpreadAngle = Vector2.new(45, 45)
		particles.Speed = NumberRange.new(2)
		particles.Color = ColorSequence.new(teamColor)
		particles.Parent = attachment

		local anchoredBase = heldItem:GetAttribute("AnchoredToBase")
		if anchoredBase then
			if not primary:FindFirstChild("FloatVelocity") then
				local bv = Instance.new("BodyVelocity")
				bv.Name = "FloatVelocity"
				bv.MaxForce = Vector3.new(0, math.huge, 0)
				bv.Velocity = Vector3.new(0, 0, 0)
				bv.P = 1000
				bv.Parent = primary
			end
			if not primary:FindFirstChild("FloatRotation") then
				local bav = Instance.new("BodyAngularVelocity")
				bav.Name = "FloatRotation"
				bav.MaxTorque = Vector3.new(0, math.huge, 0)
				bav.AngularVelocity = Vector3.new(0, 2, 0)
				bav.Parent = primary
			end
		end
		heldItem:SetAttribute("FloatingEnabled", true)
	end

	local function countObjectsInBase(baseName)
		local count = 0
		if baseDeliveries[baseName] then
			for itemName, _ in pairs(baseDeliveries[baseName]) do
				count = count + 1
			end
		end
		return count
	end

	local function anchorToBase(heldItem, base)
		local primary = heldItem.PrimaryPart
		if not primary then return end

		heldItem:SetAttribute("AnchoredToBase", base.Name)

		local currentPos = primary.Position
		local baseY = base.PrimaryPart.Position.Y

		if currentPos.Y < baseY + 3 then
			primary.CFrame = CFrame.new(currentPos.X, baseY + 5, currentPos.Z)
		end

		primary.Anchored = false
		for _, part in pairs(heldItem:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Massless = true
			end
		end

		local oldBV = primary:FindFirstChild("BodyVelocity")
		if oldBV then oldBV:Destroy() end

		local bv = Instance.new("BodyVelocity")
		bv.Name = "FloatVelocity"
		bv.MaxForce = Vector3.new(0, math.huge, 0)
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.P = 1000
		bv.Parent = primary
	end

	local function unanchorFromBase(heldItem)
		local currentTeam = getObjectTeam(heldItem)
		heldItem:SetAttribute("AnchoredToBase", nil)

		disableFloatingEffects(heldItem)

		local primary = heldItem.PrimaryPart
		if primary then
			if not primary:FindFirstChild("FloatingLight") and currentTeam then
				local teamColor = getTeamColor(currentTeam)
				local light = Instance.new("PointLight")
				light.Name = "FloatingLight"
				light.Brightness = 2
				light.Range = 15
				light.Color = teamColor
				light.Parent = primary
			end
		end

		for _, part in pairs(heldItem:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Massless = false
				part.CanCollide = true
			end
		end
	end

	local playerErrorCooldown = {}

	-- LOOP DE DETECCIÓN
	RunService.Heartbeat:Connect(function()
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end

			local heldItem = nil
			for _, child in pairs(char:GetChildren()) do
				if child:IsA("Model") and child.PrimaryPart then
					if child.PrimaryPart:FindFirstChild("ProximityPrompt") then
						heldItem = child
						break
					end
				end
			end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local playerName = player.Name
			local playerTeam = getPlayerTeam(player)
			local nearBase = false
			local currentBase = nil

			for _, base in pairs(BASES) do
				if (hrp.Position - base.PrimaryPart.Position).Magnitude <= DETECTION_RADIUS then
					nearBase = true
					currentBase = base
					break
				end
			end

			if heldItem and nearBase then
				local itemName = heldItem.Name
				local baseName = currentBase.Name
				local baseTeam = tonumber(string.match(currentBase.Name, "%d+"))

				local objectTeam = getObjectTeam(heldItem)
				local isEnemyObject = objectTeam and objectTeam ~= playerTeam
				local isMyBase = playerTeam == baseTeam

				if not playerTeam then continue end

				if isMyBase and not isEnemyObject then
					local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

					if not baseDeliveries[baseName][itemName] then
						local currentCount = countObjectsInBase(baseName)
						if currentCount < MAX_ITEMS then
							baseDeliveries[baseName][itemName] = true
							notifyRemote:FireClient(player, itemName, baseName, "DELIVERED")

							anchorToBase(heldItem, currentBase)
							setObjectTeam(heldItem, playerTeam)

							currentBase:SetAttribute("ObjectCount", currentCount + 1)

							enableFloatingGlow(heldItem, playerTeam)
							print("📦", playerName, "entregó", itemName, "a", baseName)
						end
					else
						enableFloatingGlow(heldItem, playerTeam)
					end

				elseif isEnemyObject then
					local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

					if anchoredBase and baseDeliveries[anchoredBase] and baseDeliveries[anchoredBase][itemName] then
						notifyRemote:FireClient(player, itemName, anchoredBase, "STOLEN", playerName)
						baseDeliveries[anchoredBase][itemName] = nil

						local originalBase = workspace:FindFirstChild(anchoredBase)
						if originalBase then
							local currentCount = countObjectsInBase(anchoredBase)
							originalBase:SetAttribute("ObjectCount", currentCount)
						end

						unanchorFromBase(heldItem)
						print("🚨", playerName, "robó", itemName, "de", anchoredBase)
					end

				else
					if not playerErrorCooldown[player.UserId] or (tick() - playerErrorCooldown[player.UserId]) > 2 then
						errorRemote:FireClient(player, "⚠️ BASE INCORRECTA", "No puedes entregar objetos enemigos aquí")
						playerErrorCooldown[player.UserId] = tick()
					end
					disableFloatingEffects(heldItem)
				end

			elseif heldItem and not nearBase then
				local objectTeam = getObjectTeam(heldItem)
				local anchoredBase = heldItem:GetAttribute("AnchoredToBase")

				if anchoredBase and baseDeliveries[anchoredBase] and baseDeliveries[anchoredBase][heldItem.Name] then
					notifyRemote:FireClient(player, heldItem.Name, anchoredBase, "STOLEN", playerName)
					baseDeliveries[anchoredBase][heldItem.Name] = nil

					local originalBase = workspace:FindFirstChild(anchoredBase)
					if originalBase then
						local currentCount = countObjectsInBase(anchoredBase)
						originalBase:SetAttribute("ObjectCount", currentCount)
					end

					unanchorFromBase(heldItem)
					print("🚨", playerName, "robó", heldItem.Name, "de", anchoredBase)
				end

				if objectTeam then
					local primary = heldItem.PrimaryPart
					if primary then
						if not primary:FindFirstChild("FloatingLight") then
							local teamColor = getTeamColor(objectTeam)
							local light = Instance.new("PointLight")
							light.Name = "FloatingLight"
							light.Brightness = 2
							light.Range = 15
							light.Color = teamColor
							light.Parent = primary
						end

						local hasParticles = false
						for _, att in pairs(primary:GetChildren()) do
							if att:IsA("Attachment") and att:FindFirstChildOfClass("ParticleEmitter") then
								hasParticles = true
								break
							end
						end

						if not hasParticles then
							local attachment = Instance.new("Attachment")
							attachment.Parent = primary
							local particles = Instance.new("ParticleEmitter")
							particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
							particles.Lifetime = NumberRange.new(1, 2)
							particles.Rate = 50
							particles.SpreadAngle = Vector2.new(45, 45)
							particles.Speed = NumberRange.new(2)
							particles.Color = ColorSequence.new(getTeamColor(objectTeam))
							particles.Parent = attachment
						end
					end

					disableFloatingEffects(heldItem)
				else
					disableFloatingGlow(heldItem)
				end
			end
		end
	end)

	-- === RESTO DE TU CÓDIGO (COUNTDOWN, ETC.) ===
	local activeCountdowns = {}

	local function baseHasAllComponents(baseName)
		local count = countObjectsInBase(baseName)
		return count >= 9
	end

	local function createBaseCountdownGui(base)
		local oldGui = base.PrimaryPart:FindFirstChild("BaseCountdownBillboard")
		if oldGui then oldGui:Destroy() end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "BaseCountdownBillboard"
		billboard.Adornee = base.PrimaryPart
		billboard.Size = UDim2.new(0, 200, 0, 100)
		billboard.StudsOffset = Vector3.new(0, 30, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = base.PrimaryPart

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		frame.BorderSizePixel = 0
		frame.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 20)
		corner.Parent = frame

		local tween = game:GetService("TweenService"):Create(
			frame,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{BackgroundColor3 = Color3.fromRGB(255, 150, 0)}
		)
		tween:Play()

		local alert = Instance.new("TextLabel")
		alert.Size = UDim2.new(1, 0, 0.4, 0)
		alert.Position = UDim2.new(0, 0, 0, 5)
		alert.BackgroundTransparency = 1
		alert.Text = "⚠️ PROGRAMANDO ROBOT ⚠️"
		alert.TextColor3 = Color3.fromRGB(255, 255, 255)
		alert.Font = Enum.Font.GothamBold
		alert.TextScaled = true
		alert.TextStrokeTransparency = 0
		alert.Parent = frame

		local baseLabel = Instance.new("TextLabel")
		baseLabel.Size = UDim2.new(1, 0, 0.25, 0)
		baseLabel.Position = UDim2.new(0, 0, 0.4, 0)
		baseLabel.BackgroundTransparency = 1
		baseLabel.Text = base.Name
		baseLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		baseLabel.Font = Enum.Font.GothamBold
		baseLabel.TextScaled = true
		baseLabel.TextStrokeTransparency = 0
		baseLabel.Parent = frame

		local timer = Instance.new("TextLabel")
		timer.Name = "TimerLabel"
		timer.Size = UDim2.new(1, 0, 0.35, 0)
		timer.Position = UDim2.new(0, 0, 0.65, 0)
		timer.BackgroundTransparency = 1
		timer.Text = "2:00"
		timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		timer.Font = Enum.Font.GothamBold
		timer.TextScaled = true
		timer.TextStrokeTransparency = 0
		timer.Parent = frame

		return billboard
	end

	local function createPlayerCountdownGui(player, baseName)
		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then return nil end

		local oldGui = playerGui:FindFirstChild("TeamCountdownGui")
		if oldGui then oldGui:Destroy() end

		local playerTeam = getPlayerTeam(player)
		local baseTeam = tonumber(string.match(baseName, "%d+"))

		if playerTeam ~= baseTeam then return nil end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "TeamCountdownGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui

		local teamColor = getTeamColor(playerTeam)

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 450, 0, 130)
		frame.Position = UDim2.new(0.5, -225, 0.02, 0)
		frame.BackgroundColor3 = teamColor
		frame.BorderSizePixel = 0
		frame.ZIndex = 100
		frame.Parent = screenGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 15)
		corner.Parent = frame

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, 28)
		title.Position = UDim2.new(0, 10, 0, 8)
		title.BackgroundTransparency = 1
		title.Text = "🚀 PROGRAMANDO EL ROBOT"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 22
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 101
		title.Parent = frame

		local warning = Instance.new("TextLabel")
		warning.Size = UDim2.new(1, -20, 0, 36)
		warning.Position = UDim2.new(0, 10, 0, 38)
		warning.BackgroundTransparency = 1
		warning.Text = "⚠️ No dejes que roben los componentes electrónicos"
		warning.TextColor3 = Color3.fromRGB(255, 255, 255)
		warning.Font = Enum.Font.Gotham
		warning.TextSize = 16
		warning.TextWrapped = true
		warning.TextXAlignment = Enum.TextXAlignment.Left
		warning.ZIndex = 101
		warning.Parent = frame

		local timer = Instance.new("TextLabel")
		timer.Name = "TimerLabel"
		timer.Size = UDim2.new(1, -20, 0, 48)
		timer.Position = UDim2.new(0, 10, 0, 76)
		timer.BackgroundTransparency = 1
		timer.Text = "2:00"
		timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		timer.Font = Enum.Font.GothamBold
		timer.TextSize = 42
		timer.TextXAlignment = Enum.TextXAlignment.Center
		timer.ZIndex = 101
		timer.Parent = frame

		return screenGui
	end

	warning.TextXAlignment = Enum.TextXAlignment.Left
	warning.ZIndex = 101
	warning.Parent = frame

	local timer = Instance.new("TextLabel")
	timer.Name = "TimerLabel"
	timer.Size = UDim2.new(1, -20, 0, 48)
	timer.Position = UDim2.new(0, 10, 0, 76)
	timer.BackgroundTransparency = 1
	timer.Text = "2:00"
	timer.TextColor3 = Color3.fromRGB(255, 255, 255)
	timer.Font = Enum.Font.GothamBold
	timer.TextSize = 42
	timer.TextXAlignment = Enum.TextXAlignment.Center
	timer.ZIndex = 101
	timer.Parent = frame

	return screenGui
end

-- [RESTO DEL CÓDIGO DE COUNTDOWN... mantén todo lo demás igual]

-- [RESTO DEL CÓDIGO DE COUNTDOWN... mantén todo lo demás igual]

local function startCountdown(base)
	local baseName = base.Name
	if activeCountdowns[baseName] then return end

	print("🚀 Iniciando countdown para", baseName)

	local baseGui = createBaseCountdownGui(base)
	local baseTimerLabel = baseGui:FindFirstChild("TimerLabel", true)

	local playerGuis = {}
	for _, player in pairs(Players:GetPlayers()) do
		local gui = createPlayerCountdownGui(player, baseName)
		if gui then
			playerGuis[player.UserId] = gui
		end
	end

	local countdownData = {
		timeLeft = 120,
		baseGui = baseGui,
		playerGuis = playerGuis,
		base = base,
		lastCheck = tick(),
		lastUpdate = tick()
	}

	activeCountdowns[baseName] = countdownData

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not activeCountdowns[baseName] then
			connection:Disconnect()
			return
		end

		local now = tick()
		if now - countdownData.lastCheck >= 0.5 then
			countdownData.lastCheck = now

			if not baseHasAllComponents(baseName) then
				stopCountdown(baseName, "Falta componente - Robaron uno!")
				return
			end

			for _, player in pairs(Players:GetPlayers()) do
				if not countdownData.playerGuis[player.UserId] then
					local gui = createPlayerCountdownGui(player, baseName)
					if gui then
						countdownData.playerGuis[player.UserId] = gui
					end
				end
			end
		end

		countdownData.timeLeft = countdownData.timeLeft - dt

		if now - countdownData.lastUpdate >= 0.1 then
			countdownData.lastUpdate = now

			local minutes = math.floor(countdownData.timeLeft / 60)
			local seconds = math.floor(countdownData.timeLeft % 60)
			local timeText = string.format("%d:%02d", minutes, seconds)

			if baseTimerLabel then
				baseTimerLabel.Text = timeText
			end

			for userId, gui in pairs(countdownData.playerGuis) do
				if gui and gui.Parent then
					local timerLabel = gui:FindFirstChild("TimerLabel", true)
					if timerLabel then
						timerLabel.Text = timeText
					end
				end
			end

			if countdownData.timeLeft <= 30 then
				if baseTimerLabel then
					baseTimerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				end
				for _, gui in pairs(countdownData.playerGuis) do
					if gui and gui.Parent then
						local timerLabel = gui:FindFirstChild("TimerLabel", true)
						if timerLabel then
							timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
						end
					end
				end
			elseif countdownData.timeLeft <= 60 then
				if baseTimerLabel then
					baseTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				end
				for _, gui in pairs(countdownData.playerGuis) do
					if gui and gui.Parent then
						local timerLabel = gui:FindFirstChild("TimerLabel", true)
						if timerLabel then
							timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
						end
					end
				end
			end
		end

		if countdownData.timeLeft <= 0 then
			print("🎉", baseName, "¡COMPLETÓ EL ROBOT!")

			if baseTimerLabel then
				baseTimerLabel.Text = "¡COMPLETO!"
				baseTimerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			end

			if baseGui and baseGui.Parent then
				local frame = baseGui:FindFirstChild("Frame")
				if frame then
					frame.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
				end
			end

			for _, gui in pairs(countdownData.playerGuis) do
				if gui and gui.Parent then
					local timerLabel = gui:FindFirstChild("TimerLabel", true)
					if timerLabel then
						timerLabel.Text = "¡COMPLETO!"
						timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
					end
					local frame = gui:FindFirstChild("Frame")
					if frame then
						frame.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
					end
				end
			end

			task.wait(3)
			stopCountdown(baseName, "Completado exitosamente")
		end
	end)

	countdownData.connection = connection
end

task.spawn(function()
	while true do
		task.wait(1)

		for _, base in pairs(BASES) do
			local baseName = base.Name
			local count = countObjectsInBase(baseName)

			if math.random(1, 5) == 1 then
				print("▶ DEBUG:", baseName, "tiene", count .. "/9", "objetos")
			end

			if count >= 9 and not activeCountdowns[baseName] then
				startCountdown(base)
			end
		end
	end
end)


Players.PlayerRemoving:Connect(function(player)
	local playerId = player.UserId
	if respawnTimes[playerId] then
		respawnTimes[playerId] = nil
	end
	if respawnGuis[playerId] then
		respawnGuis[playerId]:Destroy()
		respawnGuis[playerId] = nil
	end

	-- También limpiar countdown
	for baseName, countdownData in pairs(activeCountdowns) do
		if countdownData.playerGuis[playerId] then
			countdownData.playerGuis[playerId] = nil
		end
	end
end)