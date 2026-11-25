-- ServerScriptService > TeamSystem (CORREGIDO - JUGADORES TARDÍOS)
local Players = game:GetService("Players")
local OWNER_USERID = 9330695994
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- RemoteEvents
local updateTimeEvent = ReplicatedStorage:FindFirstChild("UpdateTimeRemaining")
if not updateTimeEvent then
	updateTimeEvent = Instance.new("RemoteEvent")
	updateTimeEvent.Name = "UpdateTimeRemaining"
	updateTimeEvent.Parent = ReplicatedStorage
end

local chooseTeamEvent = ReplicatedStorage:FindFirstChild("ChooseTeam")
if not chooseTeamEvent then
	chooseTeamEvent = Instance.new("RemoteEvent")
	chooseTeamEvent.Name = "ChooseTeam"
	chooseTeamEvent.Parent = ReplicatedStorage
end

local closeGuiEvent = ReplicatedStorage:FindFirstChild("CloseTeamSelector")
if not closeGuiEvent then
	closeGuiEvent = Instance.new("RemoteEvent")
	closeGuiEvent.Name = "CloseTeamSelector"
	closeGuiEvent.Parent = ReplicatedStorage
end

-- ✅ CONFIGURACIÓN
local GAME_START_TIME = 180
local MAX_TEAM_SIZE = 5
local TEAM_COUNT = 5

-- ✅ VARIABLE GLOBAL
local gameStarted = false

-- Equipos
local teams = {}
for i = 1, TEAM_COUNT do
	teams[i] = {}
end
local playerTeam = {}

local function freezePlayer(player, freeze)
	if player.UserId == OWNER_USERID then 
		return 
	end

	local char = player.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = freeze and 0 or 16
			humanoid.JumpPower = freeze and 0 or 50
		end
	end
end

local function teleportToBase(player, teamNum)
	local base = workspace:FindFirstChild("BaseEquipo" .. teamNum)
	if not base or not base.PrimaryPart then
		warn("BaseEquipo" .. teamNum .. " no válida")
		return
	end
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = base.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
		freezePlayer(player, false)
	end
end

-- ✅ ASIGNAR EQUIPO (MEJORADO - SIEMPRE CIERRA GUI)
local function assignTeam(player, teamNum)
	if player.UserId == OWNER_USERID then
		print("👑 Owner: asignación ignorada")
		return false
	end

	-- ✅ VERIFICAR SI YA TIENE EQUIPO
	if playerTeam[player.UserId] or player:GetAttribute("TeamNumber") then
		print("🔒", player.Name, "ya tiene equipo")
		-- ✅ CERRAR GUI POR SI ACASO
		closeGuiEvent:FireClient(player)
		return false
	end

	-- ✅ BUSCAR EQUIPO CON ESPACIO
	if #teams[teamNum] >= MAX_TEAM_SIZE then
		warn("❌ Equipo", teamNum, "lleno - Buscando alternativa...")

		-- Buscar equipo disponible
		local foundTeam = nil
		for i = 1, TEAM_COUNT do
			if #teams[i] < MAX_TEAM_SIZE then
				foundTeam = i
				break
			end
		end

		if foundTeam then
			teamNum = foundTeam
			print("✅ Asignado a Equipo", teamNum, "en su lugar")
		else
			warn("❌ TODOS LOS EQUIPOS LLENOS")
			closeGuiEvent:FireClient(player)
			freezePlayer(player, false)
			return false
		end
	end

	-- ✅ ASIGNAR
	table.insert(teams[teamNum], player)
	playerTeam[player.UserId] = teamNum
	player:SetAttribute("TeamNumber", teamNum)

	-- ✅ CERRAR GUI
	closeGuiEvent:FireClient(player)

	teleportToBase(player, teamNum)
	print("🎯", player.Name, "→ Equipo", teamNum)
	return true
end

local function autoAssignRemainingPlayers()
	print("🤖 AUTO-ASIGNANDO jugadores sin equipo...")
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster") then
			continue
		end

		if not playerTeam[player.UserId] and not player:GetAttribute("TeamNumber") then
			local available = {}
			for i = 1, TEAM_COUNT do
				if #teams[i] < MAX_TEAM_SIZE then
					table.insert(available, i)
				end
			end
			if #available > 0 then
				local randomTeam = available[math.random(#available)]
				assignTeam(player, randomTeam)
			else
				freezePlayer(player, false)
			end
		end
	end
end

local function removeAllRejas()
	print("⏰ Quitando rejas...")
	for i = 1, TEAM_COUNT do
		local base = workspace:FindFirstChild("BaseEquipo" .. i)
		if base then
			for _, child in ipairs(base:GetChildren()) do
				if child.Name == "Rejas" then
					child:Destroy()
					print("▶ Rejas eliminadas de BaseEquipo" .. i)
				end
			end
		end
	end
end

local function setupRagdoll(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	humanoid.BreakJointsOnDeath = false
	humanoid.Died:Connect(function()
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		if player.UserId == OWNER_USERID then
			return
		end

		local teamNum = player:GetAttribute("TeamNumber")
		if not teamNum then return end

		print("💀", player.Name, "murió - ragdoll")

		for _, descendant in pairs(character:GetDescendants()) do
			if descendant:IsA("Motor6D") then
				descendant:Destroy()
			end
		end
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
				part.AssemblyLinearVelocity = Vector3.new(
					math.random(-50, 50),
					math.random(0, 30),
					math.random(-50, 50)
				)
			end
		end

		for i = 3, 1, -1 do
			local playerGui = player:FindFirstChild("PlayerGui")
			if playerGui then
				local oldGui = playerGui:FindFirstChild("RespawnCountdown")
				if oldGui then oldGui:Destroy() end

				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "RespawnCountdown"
				screenGui.ResetOnSpawn = false
				screenGui.Parent = playerGui

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(0, 300, 0, 100)
				label.Position = UDim2.new(0.5, -150, 0.5, -50)
				label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				label.BackgroundTransparency = 0.5
				label.Text = "Reapareciendo en " .. i .. "..."
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Font = Enum.Font.GothamBold
				label.TextSize = 36
				label.Parent = screenGui

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 15)
				corner.Parent = label
			end
			task.wait(1)
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local gui = playerGui:FindFirstChild("RespawnCountdown")
			if gui then gui:Destroy() end
		end

		player:LoadCharacter()
		local newChar = player.CharacterAdded:Wait()
		task.wait(0.1)

		local base = workspace:FindFirstChild("BaseEquipo" .. teamNum)
		if base and base.PrimaryPart then
			local hrp = newChar:WaitForChild("HumanoidRootPart", 3)
			if hrp then
				hrp.CFrame = base.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end)
end

-- === API ===
local api = Instance.new("Folder")
api.Name = "TeamSystemAPI"
api.Parent = ServerStorage

local getTeamMembers = Instance.new("RemoteFunction")
getTeamMembers.Name = "GetTeamMembers"
getTeamMembers.OnServerInvoke = function(_, teamNum)
	if type(teamNum) == "number" and teams[teamNum] then
		local ids = {}
		for _, plr in ipairs(teams[teamNum]) do
			table.insert(ids, plr.UserId)
		end
		return ids
	end
	return {}
end
getTeamMembers.Parent = api

-- === EVENTOS ===
Players.PlayerAdded:Connect(function(player)
	playerTeam[player.UserId] = nil

	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)

		if player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster") then
			print("👑 GM detectado - TeamSystem ignorado")
			return
		end

		setupRagdoll(char)

		local team = player:GetAttribute("TeamNumber")
		if team and team > 0 then
			teleportToBase(player, team)
		else
			-- ✅ SI EL JUEGO YA EMPEZÓ, AUTO-ASIGNAR INMEDIATAMENTE
			if gameStarted then
				print("⚡ Juego en curso - Auto-asignando a", player.Name)
				task.wait(0.5)

				local available = {}
				for i = 1, TEAM_COUNT do
					if #teams[i] < MAX_TEAM_SIZE then
						table.insert(available, i)
					end
				end

				if #available > 0 then
					assignTeam(player, available[math.random(#available)])
				else
					freezePlayer(player, false)
					warn("⚠️ Todos los equipos llenos - liberado sin equipo")
				end
			else
				-- Lobby normal - congelar y esperar elección
				freezePlayer(player, true)
			end
		end
	end)

	player:LoadCharacter()

	-- ✅ NOTIFICAR ESTADO DEL JUEGO
	task.wait(0.5)
	if gameStarted then
		updateTimeEvent:FireClient(player, 0)
	end
end)

-- ✅ RECIBIR ELECCIÓN DE EQUIPO (SIN RESTRICCIÓN DE TIEMPO)
chooseTeamEvent.OnServerEvent:Connect(function(player, teamNum)
	if player.UserId == OWNER_USERID then
		warn("👑 Owner bloqueado")
		return
	end

	if type(teamNum) == "number" and teamNum >= 1 and teamNum <= TEAM_COUNT then
		assignTeam(player, teamNum)
	end
end)

-- === TEMPORIZADOR ===
task.spawn(function()
	local timeLeft = GAME_START_TIME

	while timeLeft > 0 do
		task.wait(1)
		timeLeft -= 1
		for _, plr in ipairs(Players:GetPlayers()) do
			updateTimeEvent:FireClient(plr, timeLeft)
		end
	end

	-- ✅ MARCAR INICIO
	gameStarted = true
	print("🚀 JUEGO INICIADO")

	-- ✅ NOTIFICAR A TODOS
	for _, plr in ipairs(Players:GetPlayers()) do
		updateTimeEvent:FireClient(plr, 0)
	end

	-- ✅ AUTO-ASIGNAR Y ABRIR REJAS
	autoAssignRemainingPlayers()
	removeAllRejas()
end)

print("✅ TeamSystem cargado (con soporte para jugadores tardíos)")