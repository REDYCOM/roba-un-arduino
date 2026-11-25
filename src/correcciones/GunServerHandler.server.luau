-- ServerScriptService > GunServerHandler
-- Sistema de armas integrado con tu sistema de equipos
-- (gestionado por Rojo: robots, gran final, runa Sobrecarga y daño del panel GM)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🛡️ Si en Studio quedó una copia vieja con el mismo nombre, la apagamos
-- (dos copias = cada disparo haría el doble de daño)
for _, otro in ipairs(script.Parent:GetChildren()) do
	if otro ~= script and otro.Name == script.Name and otro:IsA("BaseScript") then
		otro.Enabled = false
		warn("⚠️ Había un '" .. script.Name .. "' duplicado: lo desactivé (el bueno lo maneja Rojo)")
	end
end

-- Registro de daño a robots (puntos + gran final). Si no está, la pistola funciona igual.
local okRegistro, Registro = pcall(function()
	return require(game:GetService("ServerScriptService"):WaitForChild("SistemaEducativo"):WaitForChild("RegistroDano", 10))
end)
if not okRegistro then Registro = nil end

-- Crear RemoteEvent para disparos
local shootEvent = ReplicatedStorage:FindFirstChild("ShootEvent")
if not shootEvent then
	shootEvent = Instance.new("RemoteEvent")
	shootEvent.Name = "ShootEvent"
	shootEvent.Parent = ReplicatedStorage
	print("✅ RemoteEvent 'ShootEvent' creado")
end

-- ⚙️ CONFIGURACIÓN DEL ARMA ⚙️
local CONFIG = {
	-- Daño
	DAMAGE = 15,                    -- Daño base por disparo
	HEADSHOT_MULTIPLIER = 2,        -- x2 daño en headshots
	LIMB_DAMAGE_MULTIPLIER = 0.8,   -- 80% daño en brazos/piernas

	-- Sistema
	MAX_DISTANCE = 500,             -- Distancia máxima del disparo
	COOLDOWN = 0.1,                 -- Tiempo entre disparos (segundos)

	-- Daño entre aliados (USA TU SISTEMA DE EQUIPOS)
	FRIENDLY_FIRE = false,          -- true = daño entre aliados, false = sin daño

	-- Owner/GameMaster
	OWNER_USERID = 9330695994,      -- El owner de tu otro script
	GM_INVULNERABLE = false,         -- Game Master es invulnerable
}

local playerCooldowns = {}

-- ✅ FUNCIÓN PARA VERIFICAR SI SON DEL MISMO EQUIPO (USA TU ATRIBUTO)
local function areSameTeam(player1, player2)
	local team1 = player1:GetAttribute("TeamNumber")
	local team2 = player2:GetAttribute("TeamNumber")

	-- Si alguno no tiene equipo, pueden dañarse
	if not team1 or not team2 then
		return false
	end

	-- Comparar números de equipo
	return team1 == team2
end

-- ✅ FUNCIÓN PARA VERIFICAR SI ES GM/OWNER
local function isGameMaster(player)
	return player.UserId == CONFIG.OWNER_USERID or player:GetAttribute("IsGameMaster")
end

-- Función para calcular el multiplicador de daño según la parte del cuerpo
local function getDamageMultiplier(partName)
	if partName == "Head" then
		return CONFIG.HEADSHOT_MULTIPLIER
	elseif partName:match("Arm") or partName:match("Leg") then
		return CONFIG.LIMB_DAMAGE_MULTIPLIER
	else
		return 1 -- Torso = daño normal
	end
end

-- Validación anti-cheat
local function validateShot(player, startPos, endPos)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	-- Verificar que tiene el arma equipada
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or tool.Name ~= "BasicGun" then return false end

	-- Verificar cooldown
	local now = tick()
	if playerCooldowns[player.UserId] and (now - playerCooldowns[player.UserId]) < CONFIG.COOLDOWN then
		return false
	end
	playerCooldowns[player.UserId] = now

	-- Verificar distancia
	local distance = (endPos - startPos).Magnitude
	if distance > CONFIG.MAX_DISTANCE then return false end

	return true
end

-- ✅ CUANDO UN JUGADOR DISPARA
shootEvent.OnServerEvent:Connect(function(player, startPos, endPos, clientRayResult)
	if not validateShot(player, startPos, endPos) then
		warn("⚠️ Disparo inválido de", player.Name)
		return
	end

	local character = player.Character
	if not character then return end

	-- Raycast en el servidor (autoridad)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local direction = (endPos - startPos).Unit
	local rayResult = workspace:Raycast(startPos, direction * CONFIG.MAX_DISTANCE, raycastParams)

	local hitSomething = false

	-- Aplicar daño
	if rayResult and rayResult.Instance then
		hitSomething = true
		local hitPart = rayResult.Instance
		local hitCharacter = hitPart.Parent
		local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")

		if hitHumanoid and hitHumanoid ~= character:FindFirstChildOfClass("Humanoid") then
			local victimPlayer = game.Players:GetPlayerFromCharacter(hitCharacter)

			if victimPlayer then
				-- ✅ VERIFICAR SI ES GAME MASTER / OWNER (INVULNERABLE)
				if CONFIG.GM_INVULNERABLE and isGameMaster(victimPlayer) then
					print("👑 Game Master es invulnerable:", victimPlayer.Name)
					-- Replicar efectos visuales pero SIN daño
					for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
						if otherPlayer ~= player then
							shootEvent:FireClient(otherPlayer, player, startPos, endPos, hitSomething)
						end
					end
					return
				end

				-- ✅ VERIFICAR FRIENDLY FIRE (USA TU SISTEMA DE EQUIPOS)
				if not CONFIG.FRIENDLY_FIRE and areSameTeam(player, victimPlayer) then
					local team = player:GetAttribute("TeamNumber")
					print("🛡️ Friendly fire bloqueado - Equipo", team, ":", player.Name, "→", victimPlayer.Name)
					-- Replicar efectos visuales pero SIN daño
					for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
						if otherPlayer ~= player then
							shootEvent:FireClient(otherPlayer, player, startPos, endPos, hitSomething)
						end
					end
					return
				end
			end

			-- ✅ CALCULAR Y APLICAR DAÑO
			-- base: el daño del panel GM si lo cambiaste, si no CONFIG.DAMAGE
			local multiplier = getDamageMultiplier(hitPart.Name)
			local baseDamage = player:GetAttribute("GMWeaponDamage") or CONFIG.DAMAGE
			local finalDamage = baseDamage * multiplier * (player:GetAttribute("MultDano") or 1)  -- runa Sobrecarga

			local permitido = true
			if not victimPlayer and Registro then
				-- es un robot: en la final solo los finalistas dañan al jefe
				permitido = Registro.puedeDanar(player, hitCharacter)
				if permitido then Registro.registrar(player, hitCharacter, finalDamage) end
			end
			if permitido then
				if victimPlayer and Registro then Registro.marcarJugador(player, hitHumanoid) end -- puntos por eliminación
				hitHumanoid:TakeDamage(finalDamage)
			end

			-- Mensajes de feedback con información del equipo
			local attackerTeam = player:GetAttribute("TeamNumber") or "Sin equipo"
			local victimTeam = victimPlayer and victimPlayer:GetAttribute("TeamNumber") or "Sin equipo"

			if multiplier == CONFIG.HEADSHOT_MULTIPLIER then
				print("🎯 HEADSHOT! [Equipo "..attackerTeam.."]", player.Name, "→ [Equipo "..victimTeam.."]", hitCharacter.Name, "(-"..finalDamage.." HP)")
			elseif multiplier == CONFIG.LIMB_DAMAGE_MULTIPLIER then
				print("💥 [Equipo "..attackerTeam.."]", player.Name, "→ [Equipo "..victimTeam.."]", hitCharacter.Name, "(-"..finalDamage.." HP) [Limb]")
			else
				print("💥 [Equipo "..attackerTeam.."]", player.Name, "→ [Equipo "..victimTeam.."]", hitCharacter.Name, "(-"..finalDamage.." HP)")
			end
		end
	end

	-- ✅ REPLICAR EFECTOS A TODOS LOS JUGADORES
	for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
		if otherPlayer ~= player then
			shootEvent:FireClient(otherPlayer, player, startPos, endPos, hitSomething)
		end
	end
end)

-- Limpiar cooldowns cuando un jugador se va
game.Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

print("✅ Sistema de armas iniciado e integrado con TeamSystem")
print("📊 Configuración:")
print("   Daño base:", CONFIG.DAMAGE)
print("   Headshot:", CONFIG.DAMAGE * CONFIG.HEADSHOT_MULTIPLIER)
print("   Friendly Fire:", CONFIG.FRIENDLY_FIRE and "ACTIVADO ⚠️" or "DESACTIVADO 🛡️")
print("   GM Invulnerable:", CONFIG.GM_INVULNERABLE and "SÍ 👑" or "NO")