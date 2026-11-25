--=====================================================================
--  SISTEMA DE PODERES (servidor)
--  - Resolver un reto (en orden) desbloquea el poder correspondiente.
--  - Aplica los efectos y los RE-APLICA al reaparecer (respawn).
--  - Poderes activos ahora: 1 (arma), 2 (armadura+100), 3 (correr), 8 (armadura+200).
--    Los demás se desbloquean en el HUD; su efecto llega en las próximas tandas.
--=====================================================================

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage  = game:GetService("ServerStorage")
local StarterPack    = game:GetService("StarterPack")

local OWNER_USERID = 9330695994

-- === Remotes ===
local function getRemote(nombre)
	local r = ReplicatedStorage:FindFirstChild(nombre)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = nombre
		r.Parent = ReplicatedStorage
	end
	return r
end
local enviarEvent = getRemote("EnviarSolucionArduino")  -- cliente → servidor (resolvió un reto)
local poderEvent  = getRemote("PoderDesbloqueado")      -- servidor → cliente (popup)
local syncEvent   = getRemote("SincronizarPoderes")     -- servidor → cliente (estado al entrar)

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Retos   = require(sistema:WaitForChild("Retos"))
local Puntaje = require(script.Parent:WaitForChild("Puntaje"))

-- === Guardar el arma base fuera del alcance (para que se DESBLOQUEE) ===
local armaTemplate = ServerStorage:FindFirstChild("BasicGun")
if not armaTemplate then
	local g = StarterPack:FindFirstChild("BasicGun")
	if g then
		armaTemplate = g:Clone()
		armaTemplate.Parent = ServerStorage
		g:Destroy()  -- ya nadie nace con el arma; se gana con el poder 1
		print("[Poderes] Arma movida a ServerStorage (ahora se desbloquea)")
	else
		warn("[Poderes] No encontré 'BasicGun' en StarterPack")
	end
end

-- === Estado por jugador ===
local desbloqueados = {}  -- [player] = { [n]=true }

local function esGM(plr)
	return plr.UserId == OWNER_USERID or plr:GetAttribute("IsGameMaster")
end

local function darLeaderstats(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr end
	if not ls:FindFirstChild("Puntos") then
		local p = Instance.new("IntValue"); p.Name = "Puntos"; p.Value = 0; p.Parent = ls
	end
end

-- === Manejo del arma ===
local function tieneArma(plr)
	local bp = plr:FindFirstChildOfClass("Backpack")
	local char = plr.Character
	return (bp and bp:FindFirstChild("BasicGun")) or (char and char:FindFirstChild("BasicGun"))
end

local function darArma(plr)
	if not armaTemplate then return end
	local bp = plr:FindFirstChildOfClass("Backpack")
	if bp and not tieneArma(plr) then
		armaTemplate:Clone().Parent = bp
	end
end

local function quitarArma(plr)
	local bp = plr:FindFirstChildOfClass("Backpack")
	local char = plr.Character
	if bp then local g = bp:FindFirstChild("BasicGun"); if g then g:Destroy() end end
	if char then local g = char:FindFirstChild("BasicGun"); if g then g:Destroy() end end
end

-- Entregar un arma especial (Bazuca / Laser) desde ServerStorage
local function darArmaEspecial(plr, nombre)
	local tpl = ServerStorage:FindFirstChild(nombre)
	if not tpl then return end
	local bp = plr:FindFirstChildOfClass("Backpack")
	local char = plr.Character
	local yaTiene = (bp and bp:FindFirstChild(nombre)) or (char and char:FindFirstChild(nombre))
	if bp and not yaTiene then
		tpl:Clone().Parent = bp
	end
end

-- Crear el punto de regeneración en la base del jugador (una sola vez por base)
local function crearRegen(plr)
	local teamNum = plr:GetAttribute("TeamNumber")
	if not teamNum then return end
	local base = workspace:FindFirstChild("BaseEquipo" .. teamNum)
	if not base or not base.PrimaryPart then return end
	if base:FindFirstChild("PuntoRegen") then return end

	local pad = Instance.new("Part")
	pad.Name = "PuntoRegen"
	pad.Size = Vector3.new(8, 0.4, 8)
	pad.Anchored = true; pad.CanCollide = false
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(80, 255, 140)
	pad.CFrame = base.PrimaryPart.CFrame * CFrame.new(0, 0.6, 6)
	pad.Parent = base

	local luz = Instance.new("PointLight")
	luz.Color = pad.Color; luz.Range = 16; luz.Brightness = 2; luz.Parent = pad

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 40); bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true; bb.Parent = pad
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
	lbl.Text = "♻️ Regeneración"; lbl.TextColor3 = Color3.fromRGB(200, 255, 210)
	lbl.TextStrokeTransparency = 0.4; lbl.Font = Enum.Font.FredokaOne; lbl.TextScaled = true
	lbl.Parent = bb

	-- Cura a los del MISMO equipo que estén encima del punto
	task.spawn(function()
		while pad.Parent do
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("TeamNumber") == teamNum then
					local ch = p.Character
					local hum = ch and ch:FindFirstChildOfClass("Humanoid")
					local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
					if hum and hrp and hum.Health > 0 and hum.Health < hum.MaxHealth then
						local rel = hrp.Position - pad.Position
						if math.abs(rel.X) < 5 and math.abs(rel.Z) < 5 and math.abs(rel.Y) < 6 then
							hum.Health = math.min(hum.MaxHealth, hum.Health + 5)
						end
					end
				end
			end
			task.wait(0.4)
		end
	end)
end

-- Vida máxima = 100 + poderes de armadura + blindaje comprado en la tienda
local function recalcularVida(plr, curar)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local u = desbloqueados[plr] or {}
	local bono = (plr:GetAttribute("Blindaje") or 0) * 50
	if u[2] then bono += 100 end
	if u[7] then bono += 150 end
	if u[8] then bono += 200 end
	local nueva = 100 + bono
	local subio = math.max(0, nueva - hum.MaxHealth)
	hum.MaxHealth = nueva
	hum.Health = curar and nueva or math.min(nueva, hum.Health + subio)
end

-- === Aplicar el efecto de un poder (idempotente) ===
local function aplicarEfecto(plr, n)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if n == 1 then
		darArma(plr)

	elseif n == 2 or n == 7 or n == 8 then
		recalcularVida(plr, true)

	elseif n == 3 then
		-- correr (normal es 16); MultVel lo usa la runa Turbo
		if hum then hum.WalkSpeed = 26 * (plr:GetAttribute("MultVel") or 1) end

	elseif n == 4 then
		darArmaEspecial(plr, "Bazuca")

	elseif n == 5 then
		crearRegen(plr)

	elseif n == 6 then
		darArmaEspecial(plr, "Laser")

	else
		-- 9 (volar) lo maneja Volar.client; 10 (doble daño): próxima tanda
	end
end

-- Re-aplicar todos los poderes del jugador (al reaparecer)
local function aplicarTodos(plr)
	local u = desbloqueados[plr]
	if not u then return end
	for n in pairs(u) do aplicarEfecto(plr, n) end
end

-- === Otorgar un poder nuevo ===
local function otorgar(plr, n)
	desbloqueados[plr] = desbloqueados[plr] or {}
	if desbloqueados[plr][n] then return false end
	desbloqueados[plr][n] = true
	aplicarEfecto(plr, n)
	poderEvent:FireClient(plr, n)
	print("⭐", plr.Name, "desbloqueó el poder", n)
	return true
end

-- Lista de poderes desbloqueados (para sincronizar el HUD)
local function listaDesbloqueados(plr)
	local t = {}
	for n in pairs(desbloqueados[plr] or {}) do table.insert(t, n) end
	return t
end

-- === Cuando el cliente resuelve un reto ===
enviarEvent.OnServerEvent:Connect(function(plr, retoId, patron)
	local reto = Retos.mapa[retoId]
	if not reto then return end
	if type(patron) ~= "table" or #patron ~= #reto.patronCorrecto then return end
	for i = 1, #patron do
		if patron[i] ~= reto.patronCorrecto[i] then return end  -- orden incorrecto
	end

	-- Marcar el reto como resuelto (una sola vez)
	local folder = plr:FindFirstChild("RetosResueltos")
	if folder and not folder:FindFirstChild(retoId) then
		local b = Instance.new("BoolValue"); b.Name = retoId; b.Value = true; b.Parent = folder
		-- Puntos (personales + para el equipo)
		Puntaje.sumar(plr, reto.puntos or 10)
		-- Poder
		if reto.poder then otorgar(plr, reto.poder) end
	end
end)

-- === MEMORIA DE LA SESIÓN ===
-- Si un alumno se sale (se le cae el internet, cierra sin querer...) y vuelve a
-- entrar al MISMO servidor, recupera: retos resueltos, poderes, puntos
-- personales, armas compradas y blindaje. (Dura mientras el servidor esté abierto.)
local memoria = {} -- [UserId] = { poderes, retos, puntos, armas, blindaje }

local function guardarMemoria(plr)
	local m = { poderes = {}, retos = {} }
	for n, v in pairs(desbloqueados[plr] or {}) do m.poderes[n] = v end
	local f = plr:FindFirstChild("RetosResueltos")
	if f then for _, b in ipairs(f:GetChildren()) do table.insert(m.retos, b.Name) end end
	local ls = plr:FindFirstChild("leaderstats")
	local p = ls and ls:FindFirstChild("Puntos")
	m.puntos = p and p.Value or 0
	m.armas = plr:GetAttribute("ArmasCompradas")
	m.blindaje = plr:GetAttribute("Blindaje")
	memoria[plr.UserId] = m
end

local function restaurarMemoria(plr)
	local m = memoria[plr.UserId]
	if not m then return false end
	for n, v in pairs(m.poderes) do desbloqueados[plr][n] = v end
	local f = plr:FindFirstChild("RetosResueltos")
	for _, id in ipairs(m.retos) do
		if f and not f:FindFirstChild(id) then
			local b = Instance.new("BoolValue"); b.Name = id; b.Value = true; b.Parent = f
		end
	end
	local p = plr.leaderstats:FindFirstChild("Puntos")
	if p then p.Value = m.puntos end -- (solo personales: el equipo nunca los perdió)
	if m.armas then plr:SetAttribute("ArmasCompradas", m.armas) end
	if m.blindaje then plr:SetAttribute("Blindaje", m.blindaje) end
	return true
end

-- === Al entrar / reaparecer ===
Players.PlayerAdded:Connect(function(plr)
	desbloqueados[plr] = {}
	darLeaderstats(plr)
	if not plr:FindFirstChild("RetosResueltos") then
		local f = Instance.new("Folder"); f.Name = "RetosResueltos"; f.Parent = plr
	end
	if restaurarMemoria(plr) then
		task.delay(4, function()
			local ev = ReplicatedStorage:FindFirstChild("AnuncioRobots")
			if ev and plr.Parent then
				ev:FireClient(plr, "🔄 ¡Bienvenido de vuelta! Recuperaste tus retos, poderes y puntos",
					Color3.fromRGB(120, 255, 180), 4)
			end
		end)
	end

	-- El blindaje se compra en la tienda: al cambiar, se recalcula la vida
	plr:GetAttributeChangedSignal("Blindaje"):Connect(function()
		recalcularVida(plr, false)
	end)

	plr.CharacterAdded:Connect(function()
		task.wait(0.4)  -- esperar a que cargue el personaje/mochila
		recalcularVida(plr, true)

		if esGM(plr) then
			-- El profe/GM tiene TODAS las armas para poder verificarlas
			darArma(plr)
			for _, nombre in ipairs({ "Bazuca", "Laser", "Escopeta", "Tesla", "Granada" }) do
				darArmaEspecial(plr, nombre)
			end
			aplicarTodos(plr)
			return
		end

		-- Alumno: candado del arma si aún no la desbloqueó
		if desbloqueados[plr][1] then
			darArma(plr)
		else
			quitarArma(plr)  -- por si StarterPack alcanzó a dársela
		end
		aplicarTodos(plr)
	end)

	task.wait(0.6)
	syncEvent:FireClient(plr, listaDesbloqueados(plr))
end)

Players.PlayerRemoving:Connect(function(plr)
	guardarMemoria(plr) -- por si vuelve a entrar
	desbloqueados[plr] = nil
end)

print("✅ Sistema de Poderes (servidor) iniciado")
