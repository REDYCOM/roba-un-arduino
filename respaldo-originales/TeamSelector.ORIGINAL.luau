-- StarterPlayerScripts > TeamSelector (LocalScript) - CORREGIDO
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local OWNER_USERID = 9330695994

task.wait(0.5)

-- ✅ PROTECCIÓN GM
if player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster") then
	print("👑 GM detectado: TeamSelector omitido")
	return
end

local chooseTeamEvent = ReplicatedStorage:WaitForChild("ChooseTeam", 10)
local closeGuiEvent = ReplicatedStorage:WaitForChild("CloseTeamSelector", 10)

if not chooseTeamEvent or not closeGuiEvent then
	warn("❌ RemoteEvents no encontrados")
	return
end

-- ✅ PROTECCIÓN: Ya tiene equipo
if player:GetAttribute("TeamNumber") then
	print("✅ Ya tiene equipo - GUI omitida")
	return
end

-- ✅ CREAR GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeamSelector"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 600, 0, 400)
frame.Position = UDim2.new(0.5, -300, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.ZIndex = 5
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 60)
title.Position = UDim2.new(0, 20, 0, 20)
title.BackgroundTransparency = 1
title.Text = "SELECCIONA TU EQUIPO"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 200)
title.TextSize = 28
title.ZIndex = 6
title.Parent = frame

local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(1, -40, 1, -120)
buttonsFrame.Position = UDim2.new(0, 20, 0, 90)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.ZIndex = 5
buttonsFrame.Parent = frame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 110, 0, 110)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.Parent = buttonsFrame

local teamColors = {
	Color3.fromRGB(255, 80, 80),
	Color3.fromRGB(80, 150, 255),
	Color3.fromRGB(80, 255, 80),
	Color3.fromRGB(255, 200, 80),
	Color3.fromRGB(200, 80, 255)
}

-- ✅ VARIABLE PARA EVITAR MÚLTIPLES CLICKS
local teamSelected = false

for i = 1, 5 do
	local button = Instance.new("TextButton")
	button.Name = "Team" .. i
	button.BackgroundColor3 = teamColors[i]
	button.BorderSizePixel = 0
	button.Text = "EQUIPO " .. i
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.ZIndex = 7
	button.Parent = buttonsFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 15)
	btnCorner.Parent = button

	button.MouseEnter:Connect(function()
		if not teamSelected then
			button.BackgroundColor3 = Color3.fromRGB(
				math.min(teamColors[i].R * 255 + 30, 255),
				math.min(teamColors[i].G * 255 + 30, 255),
				math.min(teamColors[i].B * 255 + 30, 255)
			)
		end
	end)

	button.MouseLeave:Connect(function()
		if not teamSelected then
			button.BackgroundColor3 = teamColors[i]
		end
	end)

	-- ✅ MEJORADO: Evitar múltiples clicks
	button.MouseButton1Click:Connect(function()
		if teamSelected then
			print("⚠️ Ya seleccionaste un equipo")
			return
		end

		teamSelected = true
		button.Text = "UNIENDO..."
		print("🎯 Solicitando unirse a Equipo", i)
		chooseTeamEvent:FireServer(i)

		-- ✅ TIMEOUT: Si el servidor no responde en 3 segundos, permitir reintentar
		task.delay(3, function()
			if screenGui and screenGui.Parent then
				teamSelected = false
				button.Text = "EQUIPO " .. i
				warn("⚠️ Timeout - intenta de nuevo")
			end
		end)
	end)
end

-- ✅ CERRAR GUI CUANDO EL SERVIDOR CONFIRMA
closeGuiEvent.OnClientEvent:Connect(function()
	if screenGui and screenGui.Parent then
		screenGui:Destroy()
		print("🔒 GUI cerrada - Equipo asignado")
	end
end)

-- ✅ CERRAR GUI SI DETECTA QUE YA TIENE EQUIPO (BACKUP)
local teamCheckConnection
teamCheckConnection = player:GetAttributeChangedSignal("TeamNumber"):Connect(function()
	local teamNum = player:GetAttribute("TeamNumber")
	if teamNum and screenGui and screenGui.Parent then
		print("✅ Equipo detectado:", teamNum, "- Cerrando GUI")
		screenGui:Destroy()
		teamCheckConnection:Disconnect()
	end
end)

-- ✅ AUTO-CERRAR SI EL JUEGO YA EMPEZÓ (JUGADORES TARDÍOS)
task.delay(2, function()
	if not screenGui or not screenGui.Parent then return end

	-- Si después de 2 segundos sigue sin equipo pero GUI abierta, mantenerla
	-- El servidor lo auto-asignará y cerrará la GUI
	print("⏳ Esperando asignación del servidor...")
end)

print("✅ TeamSelector GUI creada")