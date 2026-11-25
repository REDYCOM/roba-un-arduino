-- ServerScriptService > TeamSystem (CORREGIDO - JUGADORES TARDÍOS)
local Players = game:GetService("Players")
local OWNER_USERID = 9330695994

-- 🛡️ Si en Studio quedó una copia vieja con el mismo nombre, la apagamos
-- (dos TeamSystem = doble aparición y ventana de equipo duplicada)
for _, otro in ipairs(script.Parent:GetChildren()) do
	if otro ~= script and otro.Name == script.Name and otro:IsA("BaseScript") then
		otro.Enabled = false
		warn("⚠️ Había un '" .. script.Name .. "' duplicado: lo desactivé (el bueno lo maneja Rojo)")
	end
end
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
-- 🏫 MODO CLASE: el lobby NO cuenta hasta que entra el profe.
--    Los alumnos que llegan antes eligen equipo y esperan en su base.
--    (Pon false para que empiece solo, como antes; útil para probar en Studio con
--     "Servidor + jugadores", donde nadie es el profe)
local MODO_CLASE = true
local SEGUNDOS_EMPEZAR_YA = 5 -- tecla [N] del profe: arranca en estos segundos

-- ✅ VARIABLE GLOBAL
local gameStarted = false

-- Equipos
local teams = {}
for i = 1, TEAM_COUNT do
	teams[i] = {}
end
local playerTeam = {}
local equipoRecordado = {} -- [UserId] = equipo (si se sale y vuelve, regresa a su equipo)

-- equipo con MENOS jugadores (si empatan, uno al azar): así los que llegan tarde equilibran
local function equipoMasChico()
	local menor, opciones = math.huge, {}
	for i = 1, TEAM_COUNT do
		local n = #teams[i]
		if n < MAX_TEAM_SIZE then
			if n < menor then
				menor, opciones = n, { i }
			elseif n == menor then
				table.insert(opciones, i)
			end
		end
	end
	if #opciones == 0 then return nil end
	return opciones[math.random(#opciones)]
end

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
			local eq = equipoMasChico()
			if eq then
				assignTeam(player, eq)
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
	-- (si volvió a entrar, CharacterAdded lo regresa a su equipo con equipoRecordado)

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
		elseif equipoRecordado[player.UserId] then
			-- 🔄 VOLVIÓ A ENTRAR: regresa a SU equipo (aunque sea durante el lobby)
			local eq = equipoRecordado[player.UserId]
			print("🔄", player.Name, "volvió - regresa al Equipo", eq)
			task.wait(0.5)
			if not assignTeam(player, eq) and not player:GetAttribute("TeamNumber") then
				local otro = equipoMasChico() -- su equipo se llenó mientras no estaba
				if otro then assignTeam(player, otro) else freezePlayer(player, false) end
			end
		else
			-- ✅ SI EL JUEGO YA EMPEZÓ, AUTO-ASIGNAR AL EQUIPO CON MENOS JUGADORES
			if gameStarted then
				print("⚡ Juego en curso - Auto-asignando a", player.Name)
				task.wait(0.5)

				local eq = equipoMasChico()
				if eq then
					assignTeam(player, eq)
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

	-- 🔧 FIX (doble spawn): Roblox ya genera el personaje automáticamente al entrar
	-- (CharacterAutoLoads = true por defecto). Llamar LoadCharacter aquí lo generaba
	-- una SEGUNDA vez → causaba los "(x2)" del Output y la ventana de equipo duplicada.
	-- El conector CharacterAdded de arriba ya captura el spawn automático.
	-- player:LoadCharacter()  -- ← desactivado a propósito

	-- ✅ NOTIFICAR ESTADO DEL JUEGO
	task.wait(0.5)
	if gameStarted then
		updateTimeEvent:FireClient(player, 0)
	end
end)

-- 🚪 AL SALIRSE DEL JUEGO
Players.PlayerRemoving:Connect(function(player)
	-- 1) Si llevaba un componente en la mano, se queda en el mapa
	--    (antes desaparecía para siempre junto con su personaje)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if char then
		for _, item in ipairs(char:GetChildren()) do
			local prim = item:IsA("Model") and item.PrimaryPart
			local prompt = prim and prim:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				local weld = prim:FindFirstChild("HandWeld")
				if weld then weld:Destroy() end
				item.Parent = workspace
				if not item:GetAttribute("AnchoredToBase") then
					if hrp then prim.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0)) end
					for _, p in ipairs(item:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = true end
					end
					prim.Anchored = false
					prompt.Enabled = true
				end
				print("📦", player.Name, "se fue con", item.Name, "- se quedó en el mapa")
			end
		end
	end

	-- 2) Liberar su lugar en el equipo (antes quedaba ocupado por un "fantasma")
	--    y recordar su equipo por si vuelve a entrar
	local eq = playerTeam[player.UserId] or player:GetAttribute("TeamNumber")
	if eq and teams[eq] then
		for i = #teams[eq], 1, -1 do
			if teams[eq][i] == player then table.remove(teams[eq], i) end
		end
		equipoRecordado[player.UserId] = eq
	end
	playerTeam[player.UserId] = nil
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

-- === MODO CLASE: ¿está el profe? ===
local function esProfe(plr)
	return plr.UserId == OWNER_USERID or plr:GetAttribute("IsGameMaster") == true
end

local function hayProfe()
	for _, plr in ipairs(Players:GetPlayers()) do
		if esProfe(plr) then return true end
	end
	return false
end

-- [N] del profe = "empezar ya" (llega por el mismo control de robots)
local empezarYa = false
task.spawn(function()
	local control = ReplicatedStorage:WaitForChild("ControlRobots", 30)
	if not control then return end
	control.OnServerEvent:Connect(function(plr, accion)
		-- en Studio cualquier jugador de prueba puede (Player1/Player2 no son el profe)
		local permitido = esProfe(plr) or game:GetService("RunService"):IsStudio()
		if accion == "empezar" and permitido and not gameStarted then
			empezarYa = true
		end
	end)
end)

-- === TEMPORIZADOR ===
task.spawn(function()
	-- 1) Esperar al profe (los alumnos ven "⏳ Esperando al profe…")
	if MODO_CLASE then
		workspace:SetAttribute("EstadoLobby", "esperando")
		while not hayProfe() and not empezarYa do
			task.wait(1)
		end
		print("👑 Llegó el profe: empieza la cuenta del lobby")
	end

	-- 2) Cuenta regresiva normal (el profe puede adelantarla con [N])
	workspace:SetAttribute("EstadoLobby", "cuenta")
	local timeLeft = GAME_START_TIME
	workspace:SetAttribute("LobbyRestante", timeLeft)

	while timeLeft > 0 do
		task.wait(1)
		timeLeft -= 1
		if empezarYa and timeLeft > SEGUNDOS_EMPEZAR_YA then
			timeLeft = SEGUNDOS_EMPEZAR_YA
		end
		workspace:SetAttribute("LobbyRestante", timeLeft)
		for _, plr in ipairs(Players:GetPlayers()) do
			updateTimeEvent:FireClient(plr, timeLeft)
		end
	end

	-- ✅ MARCAR INICIO
	gameStarted = true
	workspace:SetAttribute("EstadoLobby", "jugando")
	workspace:SetAttribute("JuegoIniciado", true)  -- aviso para otros sistemas (oleadas de robots)
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