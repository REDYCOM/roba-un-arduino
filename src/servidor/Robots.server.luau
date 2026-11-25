--=====================================================================
--  ROBOTS ENEMIGOS — OLEADAS Y JEFE (servidor)
--  Oleada 1: Seguidores (pequeños).
--  Oleada 2: + Tanques y CHATARRA (zombi oxidado, más grande).
--  Oleada 3+: + COLOSOS (gigantes humanoides: si te tocan, mueres).
--  Cada 3 oleadas: JEFE MEGA-ARDUINO (orbes, pisotón, furia al 50%).
--  El profe (GM) controla: [K] iniciar oleadas, [J] invocar jefe, [L] limpiar.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local ServerStorage = game:GetService("ServerStorage")

local Modelos = require(script.Parent:WaitForChild("RobotsModelos"))
local Puntaje = require(script.Parent:WaitForChild("Puntaje"))
local Registro = require(script.Parent:WaitForChild("RegistroDano"))
local Escena = require(script.Parent:WaitForChild("FinalEscena")) -- Ardunol + trofeo

local OWNER_USERID = 9330695994

--====================== CONFIGURACIÓN (edítala) ======================
local CONFIG = {
	INICIO_AUTOMATICO = true, -- las oleadas empiezan solas al arrancar la partida
	ESPERA_INICIAL = 15,      -- segundos después del inicio antes de la oleada 1
	ATACAR_GM = true,         -- ¿los robots atacan al profe? (pon false en clase)
	DESCANSO = 12,            -- segundos de descanso entre oleadas
	JEFE_CADA = 3,            -- el jefe aparece cada 3 oleadas
	DRONES_CADA = 4,          -- cada 4 oleadas: enjambre de drones (oleada extra)
	MAX_VIVOS = 18,           -- robots vivos al mismo tiempo (con pocos jugadores)

	-- MUCHOS JUGADORES: para que con 20 alumnos no sea un paseo
	VIVOS_POR_JUGADOR = 1,    -- +1 robot vivo permitido por cada jugador extra...
	MAX_VIVOS_TOPE = 30,      -- ...hasta este tope (más robots = más lag)
	VIDA_POR_JUGADOR = 0.03,  -- +3% de vida de los robots por cada jugador extra

	-- IA DE LOS JEFES
	JEFE_CAZA_AL_QUE_MAS_DANA = true, -- persigue al que más daño le está haciendo
	JEFE_RAYOS_CADA = 11,     -- segundos entre tormentas eléctricas del jefe
	JEFE_MISIL_DISTANCIA = 70, -- si su presa se aleja más que esto, le lanza un misil teledirigido

	-- GRAN FINAL (los 2 mejores equipos contra el robot gigante, en una arena especial)
	OLEADAS_PARA_FINAL = 6,   -- al superar esta oleada empieza la final (0 = solo con la tecla [G] del profe)
	FINAL_TIEMPO = 300,       -- segundos para derrotar al jefe final

	-- vida, velocidad, daño al tocar (mata = muerte instantánea), alcance del toque,
	-- puntos al destruirlo, fx = tamaño de efectos
	-- caja = probabilidad (0 a 1) de soltar una caja de armas al morir
	TIPOS = {
		Seguidor = { vida = 120, velocidad = 18, dano = 20, mata = false, alcance = 3.6, alto = 5,
		             puntos = 15, fx = 1 },
		Arana    = { vida = 70, velocidad = 22, dano = 15, mata = false, alcance = 3.4, alto = 4,
		             puntos = 10, fx = 0.8 },
		Soldado  = { vida = 180, velocidad = 15, dano = 25, mata = false, alcance = 3.8, alto = 6,
		             puntos = 20, fx = 1.4, caja = 0.08 },
		-- Dron: vuela, te rodea y dispara rayos (esquivables). No hace daño al tocar.
		Dron     = { vida = 90, velocidad = 20, dano = 0, mata = false, alcance = 0, alto = 0,
		             puntos = 20, fx = 1, salta = false, vuela = true, caja = 0.05,
		             disparo = { dano = 12, cadencia = 2.4, alcance = 75 } },
		Tanque   = { vida = 600, velocidad = 10, dano = 0, mata = true, alcance = 5.8, alto = 7,
		             puntos = 40, fx = 2, caja = 0.15 },
		Chatarra = { vida = 320, velocidad = 14, dano = 35, mata = false, alcance = 4.6, alto = 8,
		             puntos = 25, fx = 2, caja = 0.25 },
		Coloso   = { vida = 1000, vidaPorJugador = 150, velocidad = 11, dano = 0, mata = true,
		             alcance = 9, alto = 18, puntos = 80, fx = 3.5, salta = false, pasos = true, contorno = true,
		             caja = 1 },
		Jefe     = { vida = 1500, vidaPorJugador = 800, velocidad = 9, dano = 0, mata = true,
		             alcance = 11.5, alto = 22, puntos = 150, bonusTodos = 50, nombre = "MEGA-ARDUINO",
		             fx = 4, salta = false, pasos = true, contorno = true, esJefe = true },
		-- Jefe de la GRAN FINAL: su vida crece con la cantidad de finalistas
		JefeFinal = { vida = 8000, vidaPorJugador = 1500, velocidad = 8, dano = 0, mata = true,
		             alcance = 16, alto = 34, puntos = 0, bonusTodos = 0, nombre = "MEGA-ARDUINO DE ARDUNOL",
		             fx = 6, salta = false, pasos = true, contorno = true, esJefe = true, final = true },
	},
}
--=====================================================================

-- ===== Remotes y estado compartido =====
local function getRemote(nombre)
	local r = ReplicatedStorage:FindFirstChild(nombre)
	if not r then
		r = Instance.new("RemoteEvent"); r.Name = nombre; r.Parent = ReplicatedStorage
	end
	return r
end
local anuncioEvent = getRemote("AnuncioRobots")   -- servidor → todos (texto grande)
local sacudirEvent = getRemote("SacudirCamara")   -- servidor → jugador (temblor)
local controlEvent = getRemote("ControlRobots")   -- profe → servidor
local relampagoEvent = getRemote("RelampagoRobots") -- servidor → todos (destello del rayo del jefe)

local estado = ReplicatedStorage:FindFirstChild("EstadoRobots")
if not estado then
	estado = Instance.new("Folder"); estado.Name = "EstadoRobots"; estado.Parent = ReplicatedStorage
end
local function setEstado(k, v) estado:SetAttribute(k, v) end
setEstado("Fase", "espera")
setEstado("Oleada", 0)
setEstado("Restantes", 0)
setEstado("Cuenta", 0)
setEstado("JefeNombre", "")
setEstado("JefeVida", 0)
setEstado("JefeVidaMax", 1)
setEstado("TipoOleada", "normal")  -- normal | jefe | drones (lo usa el clima)

local carpeta = workspace:FindFirstChild("RobotsEnemigos")
if not carpeta then
	carpeta = Instance.new("Folder"); carpeta.Name = "RobotsEnemigos"; carpeta.Parent = workspace
end

local vivos = {}        -- [modelo] = true
local porGenerar = 0
local cicloId = 0
local centroMapa, radioMapa = Vector3.new(0, 0, 0), 120
local yaAnunciado = {}  -- primera aparición de cada tipo grande

-- Estado de la gran final
local finalActiva = false
local finalA, finalB = 0, 0   -- números de los 2 equipos finalistas
local numFinalistas = 0
local arenaCentro = nil
local terminarFinal           -- se define más abajo
local generarRobot            -- se define más abajo (el jefe final lo usa para pedir refuerzos)

-- ===== Utilidades de jugadores =====
local function esGM(plr)
	return plr.UserId == OWNER_USERID or plr:GetAttribute("IsGameMaster") == true
end
local function cuerpoDe(plr)
	local ch = plr.Character
	if not ch then return nil, nil end
	return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end
local function esObjetivo(plr)
	if finalActiva then
		-- en la final solo se ataca a los finalistas (los de la tribuna están a salvo)
		if finalA == 0 and finalB == 0 then return CONFIG.ATACAR_GM and esGM(plr) end  -- modo prueba
		local eq = plr:GetAttribute("TeamNumber")
		return eq ~= nil and eq ~= 0 and (eq == finalA or eq == finalB)
	end
	return CONFIG.ATACAR_GM or not esGM(plr)
end
local function darPuntos(plr, n)
	Puntaje.sumar(plr, n)  -- personal + equipo
end
local function anunciar(texto, color, duracion)
	anuncioEvent:FireAllClients(texto, color, duracion or 3)
end
local function sacudir(pos, radio, intensidad, duracion)
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = cuerpoDe(plr)
		if hrp then
			local d = (hrp.Position - pos).Magnitude
			if d <= radio then
				sacudirEvent:FireClient(plr, intensidad * (1 - (d / radio) * 0.7), duracion)
			end
		end
	end
end
-- Empujón (BodyVelocity: funciona aunque el personaje lo controle el cliente)
local function impulso(hrp, vel)
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.P = 1e4
	bv.Velocity = vel
	bv.Parent = hrp
	Debris:AddItem(bv, 0.2)
end
-- Avisa al cliente que el robot ataca (levanta las garras)
local function marcarAtaque(modelo)
	if modelo and modelo.Parent then
		modelo:SetAttribute("Ataque", workspace:GetServerTimeNow())
	end
end

local function contarVivos()
	local n = 0
	for _ in pairs(vivos) do n += 1 end
	return n
end
-- cuántos robots pueden estar vivos a la vez (crece con la cantidad de jugadores)
local function maxVivos()
	local extra = math.max(0, #Players:GetPlayers() - 1) * CONFIG.VIVOS_POR_JUGADOR
	return math.min(CONFIG.MAX_VIVOS_TOPE, CONFIG.MAX_VIVOS + extra)
end
local function multVidaJugadores()
	return 1 + CONFIG.VIDA_POR_JUGADOR * math.max(0, #Players:GetPlayers() - 1)
end
local function actualizarRestantes()
	setEstado("Restantes", porGenerar + contarVivos())
end

-- ===== Efectos visuales =====
local function destello(pos, color, rango, tiempo)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(pos); p.Parent = workspace
	local l = Instance.new("PointLight")
	l.Color = color; l.Brightness = 8; l.Range = rango; l.Parent = p
	Debris:AddItem(p, tiempo or 0.3)
	return p
end

local function chispas(pos, color, cantidad, velocidad)
	local base = destello(pos, color, 6, 0.8)
	local att = Instance.new("Attachment"); att.Parent = base
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Lifetime = NumberRange.new(0.3, 0.8)
	sp.Speed = NumberRange.new(velocidad or 20, (velocidad or 20) * 2.2)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Rate = 0
	sp.Color = ColorSequence.new(color)
	sp.Parent = att
	sp:Emit(cantidad or 30)
end

local function disco(pos, color, desde, hasta, tiempo, transpInicial)
	local d = Instance.new("Part")
	d.Shape = Enum.PartType.Cylinder; d.Anchored = true; d.CanCollide = false; d.CanQuery = false
	d.Material = Enum.Material.Neon; d.Color = color
	d.Transparency = transpInicial or 0
	d.Size = Vector3.new(0.3, desde, desde)
	d.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	d.Parent = workspace
	TweenService:Create(d, TweenInfo.new(tiempo, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.3, hasta, hasta), Transparency = 1 }):Play()
	Debris:AddItem(d, tiempo + 0.1)
	return d
end

local function explosion(pos, radio, color)
	color = color or Color3.fromRGB(255, 150, 50)
	destello(pos, color, radio * 2.2, 0.35)
	local bola = Instance.new("Part")
	bola.Shape = Enum.PartType.Ball; bola.Anchored = true; bola.CanCollide = false; bola.CanQuery = false
	bola.Material = Enum.Material.Neon; bola.Color = color
	bola.Size = Vector3.new(2, 2, 2); bola.CFrame = CFrame.new(pos); bola.Parent = workspace
	TweenService:Create(bola, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(radio * 1.6, radio * 1.6, radio * 1.6), Transparency = 1 }):Play()
	Debris:AddItem(bola, 0.5)
	disco(pos, Color3.fromRGB(255, 220, 120), 3, radio * 2.6, 0.4)
	chispas(pos, color, 40, 22)
end

local function popup(pos, texto, color)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(pos); p.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 50); bb.AlwaysOnTop = true; bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = texto; t.TextColor3 = color; t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.Parent = bb
	TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) }):Play()
	TweenService:Create(t, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(p, 1.3)
end

local function aparicion(pos, escala)
	escala = escala or 1
	local pilar = Instance.new("Part")
	pilar.Shape = Enum.PartType.Cylinder; pilar.Anchored = true; pilar.CanCollide = false; pilar.CanQuery = false
	pilar.Material = Enum.Material.Neon; pilar.Color = Color3.fromRGB(255, 60, 60)
	pilar.Size = Vector3.new(60, 4 * escala, 4 * escala)
	pilar.CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pilar.Transparency = 0.2
	pilar.Parent = workspace
	TweenService:Create(pilar, TweenInfo.new(0.6), { Transparency = 1, Size = Vector3.new(60, 0.3, 0.3) }):Play()
	Debris:AddItem(pilar, 0.7)
	chispas(pos + Vector3.new(0, 1, 0), Color3.fromRGB(255, 90, 90), math.floor(20 * escala), 15)
end

-- ===== Mapa y puntos de aparición =====
local function calcularMapa()
	local suma, n, bases = Vector3.new(0, 0, 0), 0, {}
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:match("^BaseEquipo%d+$") and obj.PrimaryPart then
			suma += obj.PrimaryPart.Position; n += 1; table.insert(bases, obj.PrimaryPart.Position)
		end
	end
	if n == 0 then return end
	centroMapa = suma / n
	local maxD = 0
	for _, p in ipairs(bases) do
		maxD = math.max(maxD, (Vector3.new(p.X, 0, p.Z) - Vector3.new(centroMapa.X, 0, centroMapa.Z)).Magnitude)
	end
	radioMapa = math.max(60, maxD + 15)
end

local function sueloEn(x, z, yRef)
	local excl = { carpeta }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(excl, plr.Character) end
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = excl
	local res = workspace:Raycast(Vector3.new(x, yRef + 250, z), Vector3.new(0, -800, 0), rp)
	return res and res.Position
end

local function lejosDeJugadores(pos, dist)
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = cuerpoDe(plr)
		if hrp and (hrp.Position - pos).Magnitude < dist then return false end
	end
	return true
end

local function puntoAparicion(grande)
	-- Si el profe crea una carpeta "PuntosRobots" con partes, se usan esas
	local f = workspace:FindFirstChild("PuntosRobots")
	if f and #f:GetChildren() > 0 then
		local hijos = f:GetChildren()
		local p = hijos[math.random(#hijos)]
		if p:IsA("BasePart") then
			return sueloEn(p.Position.X, p.Position.Z, p.Position.Y) or p.Position
		end
	end
	local ultimo
	for _ = 1, 12 do
		local ang = math.random() * math.pi * 2
		local r = radioMapa * (grande and 0.7 or (0.35 + math.random() * 0.65))
		local s = sueloEn(centroMapa.X + math.cos(ang) * r, centroMapa.Z + math.sin(ang) * r, centroMapa.Y)
		if s then
			ultimo = s
			if lejosDeJugadores(s, grande and 45 or 25) then return s end
		end
	end
	return ultimo
end

local function puntoCerca(pos, dist)
	for _ = 1, 8 do
		local ang = math.random() * math.pi * 2
		local s = sueloEn(pos.X + math.cos(ang) * dist, pos.Z + math.sin(ang) * dist, pos.Y)
		if s then return s end
	end
	return nil
end

-- ===== Daño a jugadores =====
local function objetivoMasCercano(pos)
	local mejorPlr, mejorHrp, mejorD = nil, nil, 600
	for _, plr in ipairs(Players:GetPlayers()) do
		if esObjetivo(plr) then
			local hrp, hum = cuerpoDe(plr)
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - pos).Magnitude
				if d < mejorD then mejorPlr, mejorHrp, mejorD = plr, hrp, d end
			end
		end
	end
	return mejorPlr, mejorHrp, mejorHrp and mejorD or nil
end

-- ===== IA de jefes: "AMENAZA" =====
-- El jefe caza a quien más daño le está haciendo (no solo al más cercano).
-- A esa presa se le pone una marca 🎯 sobre la cabeza que TODOS ven:
-- así el equipo sabe a quién proteger, y la presa sabe que debe moverse.
local objetivoDe = {}     -- [modeloJefe] = jugador cazado
local ultimoAvisoCaza = {} -- [plr] = tick() (para no repetir el aviso)

local function quitarMarca(plr)
	local ch = plr and plr.Character
	local head = ch and ch:FindFirstChild("Head")
	local m = head and head:FindFirstChild("MarcaJefe")
	if m then m:Destroy() end
end

local function ponerMarca(plr)
	local ch = plr.Character
	local head = ch and ch:FindFirstChild("Head")
	if not head or head:FindFirstChild("MarcaJefe") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "MarcaJefe"
	bb.Size = UDim2.new(0, 110, 0, 46)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = "🎯 CAZADO"
	t.TextColor3 = Color3.fromRGB(255, 70, 60); t.TextStrokeTransparency = 0.1
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true
	t.Parent = bb
	-- parpadea para llamar la atención
	TweenService:Create(t, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ TextTransparency = 0.5 }):Play()
end

-- elige a quién caza el jefe. Puntaje = amenaza (daño reciente) − distancia.
-- Sin daño reciente, gana el más cercano (como antes).
local function elegirObjetivoJefe(modelo, pos)
	local tabla = CONFIG.JEFE_CAZA_AL_QUE_MAS_DANA and Registro.amenazas(modelo) or {}
	local actual = objetivoDe[modelo]
	local mejorPlr, mejorHrp, mejorD, mejorP = nil, nil, nil, -math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if esObjetivo(plr) then
			local hrp, hum = cuerpoDe(plr)
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - pos).Magnitude
				if d < 600 then
					local a = tabla[plr] or 0
					local p = a - d * 0.6
					-- "terquedad": no cambia de presa por poquito (evita que gire como loco)
					if plr == actual then p += 60 + a * 0.25 end
					if p > mejorP then mejorPlr, mejorHrp, mejorD, mejorP = plr, hrp, d, p end
				end
			end
		end
	end

	if mejorPlr ~= actual then
		if actual then quitarMarca(actual) end
		objetivoDe[modelo] = mejorPlr
		if mejorPlr and (tabla[mejorPlr] or 0) > 40 then
			local ahora = tick()
			if not ultimoAvisoCaza[mejorPlr] or ahora - ultimoAvisoCaza[mejorPlr] > 12 then
				ultimoAvisoCaza[mejorPlr] = ahora
				anuncioEvent:FireClient(mejorPlr, "🎯 ¡EL JEFE TE ESTÁ CAZANDO! Le hiciste mucho daño: ¡muévete!",
					Color3.fromRGB(255, 80, 60), 2.5)
			end
		end
	end
	if mejorPlr then ponerMarca(mejorPlr) end -- (vuelve a ponerla si reapareció)
	return mejorPlr, mejorHrp, mejorD, tabla
end

-- los jugadores con más amenaza, de mayor a menor (para repartir ataques)
local function masPeligrosos(tabla, cantidad)
	local lista = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if esObjetivo(plr) then
			local hrp, hum = cuerpoDe(plr)
			if hrp and hum and hum.Health > 0 then
				table.insert(lista, { plr = plr, hrp = hrp, a = (tabla[plr] or 0) + math.random() })
			end
		end
	end
	table.sort(lista, function(x, y) return x.a > y.a end)
	local res = {}
	for i = 1, math.min(cantidad, #lista) do res[i] = lista[i] end
	return res
end

-- apunta a donde VA a estar el jugador (no a donde está): esquivar requiere cambiar de dirección
local function predecir(hrp, segundos)
	local v = hrp.AssemblyLinearVelocity
	return hrp.Position + Vector3.new(v.X, 0, v.Z) * segundos
end

local function danarArea(pos, radio, dano, empuje)
	for _, plr in ipairs(Players:GetPlayers()) do
		if esObjetivo(plr) then
			local hrp, hum = cuerpoDe(plr)
			if hrp and hum and hum.Health > 0 then
				local delta = hrp.Position - pos
				local d = delta.Magnitude
				if d <= radio then
					local f = 1 - d / radio
					hum:TakeDamage(dano * (0.4 + 0.6 * f))
					if empuje and empuje > 0 then
						local plano = Vector3.new(delta.X, 0, delta.Z)
						local dir = plano.Magnitude > 0.1 and plano.Unit or Vector3.new(1, 0, 0)
						impulso(hrp, dir * empuje * (0.4 + 0.6 * f) + Vector3.new(0, empuje * 0.6, 0))
					end
				end
			end
		end
	end
end

local function tocarJugador(plr, hum, hrp, tipo, posRobot, modelo)
	marcarAtaque(modelo)
	-- Con escudo de energía (runa o tienda) no te pueden hacer nada
	if plr.Character and plr.Character:FindFirstChildOfClass("ForceField") then
		chispas(hrp.Position, Color3.fromRGB(120, 200, 255), 10, 12)
		return
	end
	if tipo.mata then
		hum.Health = 0
		destello(hrp.Position, Color3.fromRGB(255, 60, 60), 14, 0.25)
		chispas(hrp.Position, Color3.fromRGB(255, 80, 80), 30, 25)
		sacudirEvent:FireClient(plr, 2.2, 0.4)
	else
		hum:TakeDamage(tipo.dano)
		local plano = Vector3.new(hrp.Position.X - posRobot.X, 0, hrp.Position.Z - posRobot.Z)
		local dir = plano.Magnitude > 0.1 and plano.Unit or Vector3.new(1, 0, 0)
		impulso(hrp, dir * 45 + Vector3.new(0, 25, 0))
		chispas(hrp.Position, Color3.fromRGB(255, 200, 80), 12, 15)
		sacudirEvent:FireClient(plr, 0.8, 0.25)
	end
end

-- Número de daño flotante (para que cada golpe "se sienta")
local function numeroDano(pos, cantidad)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	local inicio = pos + Vector3.new(math.random(-20, 20) / 10, math.random(0, 20) / 10, math.random(-20, 20) / 10)
	p.CFrame = CFrame.new(inicio)
	p.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 90, 0, 32); bb.AlwaysOnTop = true; bb.Parent = p
	local fuerte = cantidad >= 60
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = "-" .. cantidad
	t.TextColor3 = fuerte and Color3.fromRGB(255, 110, 40) or Color3.fromRGB(255, 240, 150)
	t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.Parent = bb
	TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.new(inicio + Vector3.new(0, 3.5, 0)) }):Play()
	TweenService:Create(t, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(p, 0.65)
end

-- Rayo de un dron: viaja hasta donde estabas al disparar (se puede esquivar)
local function dispararRayoDron(modelo, origen, objetivo, dano)
	local dir = objetivo - origen
	local dist = dir.Magnitude
	if dist < 2 then return end
	-- si hay una pared en medio, no dispara
	local excl = { carpeta }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(excl, plr.Character) end
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = excl
	if workspace:Raycast(origen, dir, rp) then return end

	marcarAtaque(modelo)
	local rayo = Instance.new("Part")
	rayo.Anchored = true; rayo.CanCollide = false; rayo.CanQuery = false
	rayo.Material = Enum.Material.Neon; rayo.Color = Color3.fromRGB(255, 50, 50)
	rayo.Size = Vector3.new(0.3, 0.3, 3.5)
	rayo.CFrame = CFrame.new(origen, objetivo)
	rayo.Parent = workspace
	local luz = Instance.new("PointLight"); luz.Color = rayo.Color; luz.Brightness = 3; luz.Range = 8; luz.Parent = rayo
	local tiempo = math.clamp(dist / 95, 0.08, 2)
	local tw = TweenService:Create(rayo, TweenInfo.new(tiempo, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(objetivo, objetivo + dir.Unit) })
	tw:Play()
	tw.Completed:Connect(function()
		rayo:Destroy()
		chispas(objetivo, Color3.fromRGB(255, 80, 60), 12, 14)
		danarArea(objetivo, 4.5, dano, 0)
	end)
	Debris:AddItem(rayo, tiempo + 0.5)
end

-- ===== Ataques del jefe =====
local function dispararOrbe(origen, objetivo)
	local dir = objetivo - origen
	if dir.Magnitude < 1 then return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { carpeta }
	local res = workspace:Raycast(origen, dir.Unit * 400, rp)
	local impacto = res and res.Position or (origen + dir.Unit * 400)

	local orbe = Instance.new("Part")
	orbe.Shape = Enum.PartType.Ball; orbe.Anchored = true; orbe.CanCollide = false; orbe.CanQuery = false
	orbe.Material = Enum.Material.Neon; orbe.Color = Color3.fromRGB(120, 255, 90)
	orbe.Size = Vector3.new(2.4, 2.4, 2.4); orbe.CFrame = CFrame.new(origen); orbe.Parent = workspace
	local luz = Instance.new("PointLight"); luz.Color = orbe.Color; luz.Brightness = 4; luz.Range = 14; luz.Parent = orbe
	local att = Instance.new("Attachment"); att.Parent = orbe
	local fuego = Instance.new("ParticleEmitter")
	fuego.Texture = "rbxasset://textures/particles/fire_main.dds"
	fuego.Lifetime = NumberRange.new(0.2, 0.4); fuego.Rate = 80
	fuego.Speed = NumberRange.new(0); fuego.Size = NumberSequence.new(1.8, 0)
	fuego.Color = ColorSequence.new(Color3.fromRGB(160, 255, 90), Color3.fromRGB(40, 160, 40))
	fuego.Parent = att

	local tiempo = math.clamp((impacto - origen).Magnitude / 75, 0.1, 4)
	local tw = TweenService:Create(orbe, TweenInfo.new(tiempo, Enum.EasingStyle.Linear), { CFrame = CFrame.new(impacto) })
	tw:Play()
	tw.Completed:Connect(function()
		orbe:Destroy()
		explosion(impacto, 8, Color3.fromRGB(120, 255, 90))
		danarArea(impacto, 9, 30, 40)
		sacudir(impacto, 45, 0.9, 0.3)
	end)
	Debris:AddItem(orbe, tiempo + 1)
end

local function colorOjos(ojos, furioso)
	for _, o in ipairs(ojos) do
		if o.Parent then
			o.Color = furioso and Color3.fromRGB(255, 90, 20) or (o:GetAttribute("ColorBase") or o.Color)
		end
	end
end

local function pisoton(modelo, root, hum, ojos, furioso, factor)
	local alturaRoot = hum.HipHeight + root.Size.Y / 2
	local suelo = root.Position - Vector3.new(0, alturaRoot - 0.2, 0)
	local radio = (furioso and 34 or 28) * (factor or 1)
	local velAntes = hum.WalkSpeed

	-- AVISO: círculo rojo que crece en el suelo (para poder esquivar)
	marcarAtaque(modelo)
	hum.WalkSpeed = 0
	for _, o in ipairs(ojos) do o.Color = Color3.fromRGB(255, 255, 255) end
	local aviso = Instance.new("Part")
	aviso.Shape = Enum.PartType.Cylinder; aviso.Anchored = true; aviso.CanCollide = false; aviso.CanQuery = false
	aviso.Material = Enum.Material.Neon; aviso.Color = Color3.fromRGB(255, 40, 40); aviso.Transparency = 0.55
	aviso.Size = Vector3.new(0.2, 4, 4)
	aviso.CFrame = CFrame.new(suelo) * CFrame.Angles(0, 0, math.rad(90))
	aviso.Parent = workspace
	TweenService:Create(aviso, TweenInfo.new(0.85, Enum.EasingStyle.Linear), { Size = Vector3.new(0.2, radio * 2, radio * 2) }):Play()
	task.wait(0.9)
	aviso:Destroy()
	if hum.Health <= 0 then return end

	-- IMPACTO
	colorOjos(ojos, furioso)
	explosion(suelo + Vector3.new(0, 1, 0), 10, Color3.fromRGB(255, 170, 70))
	disco(suelo + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 200, 120), 6, radio * 2, 0.5)
	disco(suelo + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 90, 40), 4, radio * 1.6, 0.65, 0.3)
	danarArea(suelo, radio, furioso and 45 or 35, 75)
	sacudir(suelo, 120, 2.5, 0.6)
	hum.WalkSpeed = velAntes
end

-- ===== Ataques exclusivos del JEFE FINAL =====
local function distSegmento(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

-- Láser de barrido: un rayo gira alrededor del jefe. Aviso de 1 s; se esquiva saltando o alejándose.
local function laserBarrido(modelo, root, hum, partes, presaHrp)
	marcarAtaque(modelo)
	local cabeza = partes.Cabeza or root
	local sueloY = root.Position.Y - (hum.HipHeight + root.Size.Y / 2)
	local largo = 90
	local sentido = (math.random() < 0.5) and 1 or -1
	local recorrido = math.rad(220)
	local inicio = math.random() * math.pi * 2
	if presaHrp and presaHrp.Parent then
		-- empieza a un lado de su presa: el rayo le pasa por encima a mitad del barrido
		local hacia = presaHrp.Position - root.Position
		inicio = math.atan2(hacia.Z, hacia.X) - sentido * recorrido / 2
	end

	local rayo = Instance.new("Part")
	rayo.Anchored = true; rayo.CanCollide = false; rayo.CanQuery = false; rayo.CanTouch = false
	rayo.Material = Enum.Material.Neon; rayo.Color = Color3.fromRGB(255, 40, 40)
	rayo.Transparency = 0.6
	rayo.Parent = workspace
	local function dibujar(a, grosor)
		local o = cabeza.Position
		local f = Vector3.new(root.Position.X + math.cos(a) * largo, sueloY + 2.5, root.Position.Z + math.sin(a) * largo)
		rayo.Size = Vector3.new(grosor, grosor, (f - o).Magnitude)
		rayo.CFrame = CFrame.new(o:Lerp(f, 0.5), f)
		return o, f
	end

	dibujar(inicio, 0.4)  -- aviso
	task.wait(1)
	rayo.Transparency = 0
	local luz = Instance.new("PointLight"); luz.Color = rayo.Color; luz.Brightness = 4; luz.Range = 22; luz.Parent = rayo
	local golpeados = {}
	local pasos = 50
	for i = 0, pasos do
		if hum.Health <= 0 or not modelo.Parent then break end
		local o, f = dibujar(inicio + sentido * recorrido * (i / pasos), 2.2)
		for _, plr in ipairs(Players:GetPlayers()) do
			if not golpeados[plr] and esObjetivo(plr) then
				local hrp, h = cuerpoDe(plr)
				if hrp and h and h.Health > 0 and distSegmento(hrp.Position, o, f) < 3.5 then
					golpeados[plr] = true
					h:TakeDamage(40)
					chispas(hrp.Position, Color3.fromRGB(255, 60, 60), 15, 15)
					sacudirEvent:FireClient(plr, 1.2, 0.3)
				end
			end
		end
		task.wait(0.05)
	end
	rayo:Destroy()
end

-- Lluvia de componentes: resistencias y capacitores gigantes caen del cielo
local function lluviaComponentes(centro, radio, cantidad)
	for k = 1, cantidad do
		task.spawn(function()
			task.wait(k * 0.12)
			local ang = math.random() * math.pi * 2
			local r = math.random() * radio
			local suelo = sueloEn(centro.X + math.cos(ang) * r, centro.Z + math.sin(ang) * r, centro.Y)
			if not suelo then return end

			local aviso = Instance.new("Part")
			aviso.Shape = Enum.PartType.Cylinder; aviso.Anchored = true; aviso.CanCollide = false; aviso.CanQuery = false
			aviso.Material = Enum.Material.Neon; aviso.Color = Color3.fromRGB(255, 40, 40); aviso.Transparency = 0.5
			aviso.Size = Vector3.new(0.2, 10, 10)
			aviso.CFrame = CFrame.new(suelo + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			aviso.Parent = workspace

			local esCapacitor = math.random() < 0.5
			local obj = Instance.new("Part")
			obj.Shape = Enum.PartType.Cylinder; obj.Anchored = true; obj.CanCollide = false; obj.CanQuery = false
			obj.Material = Enum.Material.SmoothPlastic
			obj.Color = esCapacitor and Color3.fromRGB(30, 90, 200) or Color3.fromRGB(225, 195, 145)
			obj.Size = esCapacitor and Vector3.new(4, 3, 3) or Vector3.new(6, 1.6, 1.6)
			obj.CFrame = CFrame.new(suelo + Vector3.new(0, 70, 0)) * CFrame.Angles(0, 0, math.rad(90))
			obj.Parent = workspace
			if not esCapacitor then  -- bandas de colores de la resistencia
				for b, color in ipairs({ Color3.fromRGB(150, 80, 30), Color3.fromRGB(20, 20, 20), Color3.fromRGB(230, 50, 40) }) do
					local banda = Instance.new("Part")
					banda.Shape = Enum.PartType.Cylinder; banda.CanCollide = false; banda.CanQuery = false; banda.Massless = true
					banda.Color = color; banda.Size = Vector3.new(0.5, 1.7, 1.7)
					banda.CFrame = obj.CFrame * CFrame.new(-1.6 + b * 0.9, 0, 0)
					banda.Parent = obj
					local w = Instance.new("WeldConstraint"); w.Part0 = obj; w.Part1 = banda; w.Parent = banda
				end
			end

			task.wait(0.7)
			local tw = TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ CFrame = CFrame.new(suelo + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
			tw:Play()
			tw.Completed:Wait()
			obj:Destroy()
			aviso:Destroy()
			explosion(suelo + Vector3.new(0, 1, 0), 7)
			danarArea(suelo, 8, 30, 40)
			sacudir(suelo, 50, 0.7, 0.25)
		end)
	end
end

-- Refuerzos: arañas y drones aparecen alrededor del jefe
local function refuerzos(root)
	anunciar("🤖 ¡EL JEFE LLAMA REFUERZOS!", Color3.fromRGB(255, 120, 60), 2.5)
	Escena.hablar("¡Mis robots! ¡Ayuden a mi MEGA-ARDUINO!", 3.5)
	for k = 1, 6 do
		local ang = k * math.pi / 3
		local s = sueloEn(root.Position.X + math.cos(ang) * 24, root.Position.Z + math.sin(ang) * 24, root.Position.Y)
		if s then generarRobot((k % 3 == 0) and "Dron" or "Arana", s, 1.5) end
		task.wait(0.2)
	end
end

-- Rayo de tormenta: círculo amarillo de aviso (1.1 s) y luego cae un rayo del cielo
local function rayoTormenta(suelo)
	local aviso = Instance.new("Part")
	aviso.Shape = Enum.PartType.Cylinder; aviso.Anchored = true; aviso.CanCollide = false; aviso.CanQuery = false
	aviso.Material = Enum.Material.Neon; aviso.Color = Color3.fromRGB(255, 230, 60); aviso.Transparency = 0.45
	aviso.Size = Vector3.new(0.2, 3, 3)
	aviso.CFrame = CFrame.new(suelo + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
	aviso.Parent = workspace
	TweenService:Create(aviso, TweenInfo.new(1.1, Enum.EasingStyle.Linear), { Size = Vector3.new(0.2, 15, 15) }):Play()
	-- chispas que "cargan" el suelo
	chispas(suelo + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 240, 120), 8, 6)
	task.wait(1.1)
	aviso:Destroy()

	-- el rayo: zigzag desde el cielo + una rama
	local function zigzag(desde, hasta, grosor, tramos)
		local punto = desde
		for i = 1, tramos do
			local k = i / tramos
			local siguiente = desde:Lerp(hasta, k)
			if i < tramos then
				siguiente += Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10)
			end
			local seg = Instance.new("Part")
			seg.Anchored = true; seg.CanCollide = false; seg.CanQuery = false; seg.CanTouch = false
			seg.Material = Enum.Material.Neon; seg.Color = Color3.fromRGB(210, 230, 255)
			seg.Size = Vector3.new(grosor, grosor, (siguiente - punto).Magnitude)
			seg.CFrame = CFrame.new(punto:Lerp(siguiente, 0.5), siguiente)
			seg.Parent = workspace
			TweenService:Create(seg, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			Debris:AddItem(seg, 0.32)
			punto = siguiente
		end
	end
	local cielo = suelo + Vector3.new(math.random(-8, 8), 110, math.random(-8, 8))
	zigzag(cielo, suelo, 1.3, 10)
	zigzag(cielo:Lerp(suelo, 0.4), suelo + Vector3.new(math.random(-14, 14), 6, math.random(-14, 14)), 0.5, 5)

	destello(suelo + Vector3.new(0, 4, 0), Color3.fromRGB(180, 210, 255), 70, 0.3)
	explosion(suelo + Vector3.new(0, 1, 0), 6, Color3.fromRGB(150, 200, 255))
	danarArea(suelo, 7.5, 28, 35)
	sacudir(suelo, 80, 1.3, 0.3)
	relampagoEvent:FireAllClients(suelo)
end

-- Tormenta eléctrica: rayos sobre los jugadores más peligrosos (y alguno al azar)
local function tormentaElectrica(modelo, tabla, furioso)
	marcarAtaque(modelo)
	anunciar("⚡ ¡TORMENTA ELÉCTRICA! Sal de los círculos amarillos", Color3.fromRGB(255, 230, 80), 2)
	local objetivos = masPeligrosos(tabla, furioso and 5 or 3)
	for i, o in ipairs(objetivos) do
		task.spawn(function()
			task.wait((i - 1) * 0.35)
			if not o.hrp.Parent then return end
			local p = predecir(o.hrp, 1.1)
			local s = sueloEn(p.X, p.Z, o.hrp.Position.Y) or (o.hrp.Position - Vector3.new(0, 3, 0))
			rayoTormenta(s)
			if furioso then -- furioso: un segundo rayo justo después, por si esquivó hacia el lado
				local p2 = predecir(o.hrp, 1.1)
				local s2 = sueloEn(p2.X, p2.Z, o.hrp.Position.Y)
				if s2 then rayoTormenta(s2) end
			end
		end)
	end
end

-- Misil teledirigido: si su presa huye lejos, la persigue. Gira lento: se esquiva
-- con un giro brusco o escondiéndose detrás de una pared (choca y explota).
local function misilTeledirigido(origen, plr)
	local misil = Instance.new("Part")
	misil.Anchored = true; misil.CanCollide = false; misil.CanQuery = false; misil.CanTouch = false
	misil.Material = Enum.Material.Neon; misil.Color = Color3.fromRGB(255, 70, 40)
	misil.Size = Vector3.new(1.3, 1.3, 3.2)
	misil.CFrame = CFrame.new(origen)
	misil.Parent = workspace
	local luz = Instance.new("PointLight"); luz.Color = misil.Color; luz.Brightness = 5; luz.Range = 16; luz.Parent = misil
	local att = Instance.new("Attachment"); att.Position = Vector3.new(0, 0, 1.6); att.Parent = misil
	local fuego = Instance.new("ParticleEmitter")
	fuego.Texture = "rbxasset://textures/particles/fire_main.dds"
	fuego.Lifetime = NumberRange.new(0.3, 0.6); fuego.Rate = 90
	fuego.Speed = NumberRange.new(2, 4); fuego.Size = NumberSequence.new(1.6, 0)
	fuego.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 60, 20))
	fuego.Parent = att
	anuncioEvent:FireClient(plr, "🚀 ¡MISIL TELEDIRIGIDO! Escóndete detrás de algo", Color3.fromRGB(255, 110, 60), 2.5)

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { carpeta, misil }

	local pos, dir = origen, Vector3.new(0, 1, 0) -- sale hacia arriba
	local velocidad, t0 = 42, tick()
	local fin = nil
	while tick() - t0 < 7 do
		local dt = task.wait()
		local hrp, h = cuerpoDe(plr)
		if hrp and h and h.Health > 0 then
			local hacia = hrp.Position - pos
			if hacia.Magnitude < 3.5 then fin = pos; break end
			local nueva = dir:Lerp(hacia.Unit, math.clamp(dt * 1.6, 0, 1))
			if nueva.Magnitude > 0.05 then dir = nueva.Unit end
		end
		local paso = dir * velocidad * dt
		local choque = workspace:Raycast(pos, paso, rp)
		if choque then fin = choque.Position; break end
		pos += paso
		misil.CFrame = CFrame.lookAt(pos, pos + dir)
	end
	misil:Destroy()
	fin = fin or pos
	explosion(fin, 9, Color3.fromRGB(255, 120, 40))
	danarArea(fin, 10, 40, 60)
	sacudir(fin, 60, 1.4, 0.35)
end

-- PUÑETAZO DE ENERGÍA (jefe final): carga el puño gigante y golpea el suelo;
-- una onda eléctrica sale en línea recta hacia su presa. Aviso: franja cian en el suelo.
local function punetazoEnergia(modelo, root, hum, partes, presaHrp)
	if not (presaHrp and presaHrp.Parent) then return end
	local CIAN = Color3.fromRGB(90, 220, 255)
	marcarAtaque(modelo)
	local puno = partes.BocaDer
	local sueloY = root.Position.Y - (hum.HipHeight + root.Size.Y / 2)
	local origen = Vector3.new(root.Position.X, sueloY + 0.3, root.Position.Z)
	local dir = Vector3.new(presaHrp.Position.X - origen.X, 0, presaHrp.Position.Z - origen.Z)
	if dir.Magnitude < 1 then return end
	dir = dir.Unit
	local largo, ancho = 95, 10
	local velAntes = hum.WalkSpeed
	hum.WalkSpeed = 0
	anunciar("👊 ¡PUÑETAZO DE ENERGÍA! Sal de la franja azul", CIAN, 1.8)

	-- carga: el puño crece y brilla
	local tamPuno = puno and puno.Size
	if puno then
		TweenService:Create(puno, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = tamPuno * 1.45, Transparency = 0 }):Play()
	end
	local aviso = Instance.new("Part")
	aviso.Anchored = true; aviso.CanCollide = false; aviso.CanQuery = false; aviso.CanTouch = false
	aviso.Material = Enum.Material.Neon; aviso.Color = CIAN; aviso.Transparency = 0.6
	aviso.Size = Vector3.new(ancho, 0.2, 1)
	aviso.CFrame = CFrame.lookAt(origen + dir * 0.5, origen + dir * 2)
	aviso.Parent = workspace
	TweenService:Create(aviso, TweenInfo.new(1.1, Enum.EasingStyle.Linear), {
		Size = Vector3.new(ancho, 0.2, largo),
		CFrame = CFrame.lookAt(origen + dir * (largo / 2), origen + dir * (largo / 2 + 1)),
	}):Play()
	task.wait(1.2)
	aviso:Destroy()
	if puno and puno.Parent then puno.Size = tamPuno end
	if hum.Health <= 0 or not modelo.Parent then return end

	-- ¡GOLPE! la onda recorre la franja
	destello(origen + Vector3.new(0, 6, 0), CIAN, 90, 0.35)
	sacudir(origen, 140, 2.6, 0.6)
	relampagoEvent:FireAllClients(origen)
	local golpeados = {}
	local pasos = 14
	for i = 1, pasos do
		local punto = origen + dir * (i * largo / pasos)
		explosion(punto + Vector3.new(0, 1, 0), 5, CIAN)
		for _, plr in ipairs(Players:GetPlayers()) do
			if not golpeados[plr] and esObjetivo(plr) then
				local hrp, h = cuerpoDe(plr)
				if hrp and h and h.Health > 0 and (hrp.Position.Y - origen.Y) < 9
					and distSegmento(Vector3.new(hrp.Position.X, origen.Y, hrp.Position.Z), origen, punto) < ancho / 2 + 1.5 then
					golpeados[plr] = true
					h:TakeDamage(45)
					impulso(hrp, dir * 70 + Vector3.new(0, 45, 0))
					chispas(hrp.Position, CIAN, 18, 18)
					sacudirEvent:FireClient(plr, 1.8, 0.4)
				end
			end
		end
		task.wait(0.045)
	end
	hum.WalkSpeed = velAntes
end

local function iaJefe(modelo, root, hum, tipo, partes, ojos)
	local furioso = false
	local tOrbe, tPiso = tick() + 3, tick() + 6
	local tLaser, tLluvia = tick() + 8, tick() + 12
	local tRayos, tMisil = tick() + 9, tick() + 5
	local tPuno = tick() + 5
	local lejosDesde = nil -- desde cuándo su presa está lejos (para el misil)
	local fase2, fase3 = false, false
	local bocaIzq = partes.BocaIzq or root
	local bocaDer = partes.BocaDer or root
	while modelo.Parent and hum.Health > 0 do
		local ahora = tick()
		if not furioso and hum.Health <= hum.MaxHealth * 0.5 then
			furioso = true
			hum.WalkSpeed = tipo.velocidad * 1.5
			colorOjos(ojos, true)
			anunciar("😡 ¡EL JEFE ESTÁ FURIOSO!", Color3.fromRGB(255, 90, 50), 2.5)
			if tipo.final then Escena.hablar("¡Grrr! ¡MEGA-ARDUINO... ENFURÉCETE!", 3.5) end
			local att = Instance.new("Attachment"); att.Parent = partes.Pecho or root
			local fuego = Instance.new("ParticleEmitter")
			fuego.Texture = "rbxasset://textures/particles/fire_main.dds"
			fuego.Lifetime = NumberRange.new(0.5, 1); fuego.Rate = 60
			fuego.Speed = NumberRange.new(4, 8); fuego.Size = NumberSequence.new(5, 0)
			fuego.SpreadAngle = Vector2.new(60, 60)
			fuego.Parent = att
		end

		if tipo.final then
			if not fase2 and hum.Health <= hum.MaxHealth * 0.66 then
				fase2 = true
				task.spawn(refuerzos, root)
			end
			if not fase3 and hum.Health <= hum.MaxHealth * 0.33 then
				fase3 = true
				task.spawn(refuerzos, root)
			end
		end

		-- ¿a quién caza? (al que más daño le hace; si nadie, al más cercano)
		local presa, hrp, d, tabla = elegirObjetivoJefe(modelo, root.Position)
		if hrp then
			-- ORBES: el 1º va a donde VA a estar su presa; los demás, a los otros peligrosos
			if ahora >= tOrbe then
				tOrbe = ahora + (furioso and 2.2 or 3.5)
				marcarAtaque(modelo)
				local cantidad = furioso and 5 or 3
				local otros = masPeligrosos(tabla, cantidad)
				for i = 1, cantidad do
					if hum.Health <= 0 or not hrp.Parent then break end
					local boca = (i % 2 == 0) and bocaIzq or bocaDer
					local blanco = hrp
					if i > 1 and otros[i] and otros[i].hrp.Parent then blanco = otros[i].hrp end
					local vuelo = (blanco.Position - boca.Position).Magnitude / 75
					local apunte = predecir(blanco, vuelo * 0.85)
					if i > 1 and blanco == hrp then
						apunte += Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
					end
					dispararOrbe(boca.Position, apunte)
					task.wait(0.15)
				end
			end

			-- PISOTÓN: si hay alguien cerca. Más ganas si hay un grupo amontonado.
			if ahora >= tPiso then
				local cerca = 0
				local radioPiso = tipo.final and 60 or 45
				for _, plr in ipairs(Players:GetPlayers()) do
					if esObjetivo(plr) then
						local h2 = cuerpoDe(plr)
						if h2 and (h2.Position - root.Position).Magnitude < radioPiso * 0.6 then cerca += 1 end
					end
				end
				if (d and d < radioPiso) or cerca >= 2 then
					tPiso = ahora + ((cerca >= 3) and 3.5 or (furioso and 5 or 7.5))
					pisoton(modelo, root, hum, ojos, furioso, tipo.final and 1.5 or 1)
				end
			end

			-- MISIL: si su presa huye o dispara desde lejos mucho rato
			if d and d > CONFIG.JEFE_MISIL_DISTANCIA then
				lejosDesde = lejosDesde or ahora
				if ahora - lejosDesde > 4 and ahora >= tMisil then
					tMisil = ahora + (furioso and 6 or 9)
					marcarAtaque(modelo)
					local cabeza = partes.Cabeza or root
					task.spawn(misilTeledirigido, cabeza.Position + Vector3.new(0, 4, 0), presa)
				end
			else
				lejosDesde = nil
			end

			-- TORMENTA ELÉCTRICA: rayos sobre los más peligrosos
			if ahora >= tRayos then
				tRayos = ahora + CONFIG.JEFE_RAYOS_CADA * (furioso and 0.65 or 1) * (tipo.final and 0.8 or 1)
				tormentaElectrica(modelo, tabla, furioso)
			end

			if tipo.final and ahora >= tPuno and d and d < 90 then
				tPuno = ahora + (furioso and 6 or 8.5)
				punetazoEnergia(modelo, root, hum, partes, hrp)
			end
			if tipo.final and ahora >= tLaser then
				tLaser = ahora + (furioso and 7 or 10)
				-- el láser empieza a un lado de su presa y pasa justo por ella a mitad del barrido
				laserBarrido(modelo, root, hum, partes, hrp)
			end
			if tipo.final and ahora >= tLluvia then
				tLluvia = ahora + (furioso and 9 or 13)
				-- la mitad de los componentes caen sobre los jugadores
				local cant = furioso and 14 or 9
				lluviaComponentes(arenaCentro or root.Position, 75, math.ceil(cant / 2))
				for _, o in ipairs(masPeligrosos(tabla, math.floor(cant / 2))) do
					lluviaComponentes(predecir(o.hrp, 1.2), 6, 1)
				end
			end
		end
		task.wait(0.2)
	end

	-- se acabó el jefe: quitar la marca de su presa
	local presa = objetivoDe[modelo]
	if presa then quitarMarca(presa) end
	objetivoDe[modelo] = nil
end

-- ===== Cajas de armas (las sueltan los robots grandes) =====
local ARMAS_CAJA = { "Escopeta", "Tesla", "Granada" }
local NOMBRE_ARMA = {
	Escopeta = "🔫 ESCOPETA DE CHISPAS",
	Tesla = "⚡ PISTOLA TESLA",
	Granada = "💣 GRANADA CONDENSADOR",
}

local function soltarCaja(pos)
	local suelo = sueloEn(pos.X, pos.Z, pos.Y) or pos
	local caja = Instance.new("Part")
	caja.Name = "CajaArmas"
	caja.Size = Vector3.new(2.6, 2.6, 2.6)
	caja.Anchored = true
	caja.CanCollide = false
	caja.Material = Enum.Material.SmoothPlastic
	caja.Color = Color3.fromRGB(0, 129, 132)
	caja.CFrame = CFrame.new(suelo + Vector3.new(0, 2, 0))
	caja.Parent = workspace

	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.fromRGB(255, 220, 80)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = caja
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 220, 80); luz.Brightness = 3; luz.Range = 14; luz.Parent = caja
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 140, 0, 36); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = caja
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = "🎁 ¡ARMA!"; t.TextColor3 = Color3.fromRGB(255, 225, 90); t.TextStrokeTransparency = 0.2
	t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.Parent = bb

	-- flota y gira
	task.spawn(function()
		local t0 = os.clock()
		local base = caja.Position
		while caja.Parent do
			local tt = os.clock() - t0
			caja.CFrame = CFrame.new(base + Vector3.new(0, math.sin(tt * 3) * 0.4, 0)) * CFrame.Angles(0, tt * 2, 0)
			task.wait(0.03)
		end
	end)

	local tomada = false
	caja.Touched:Connect(function(hit)
		if tomada then return end
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then return end
		local _, hum = cuerpoDe(plr)
		local bp = plr:FindFirstChildOfClass("Backpack")
		if not (hum and hum.Health > 0 and bp) then return end
		local opciones = {}
		for _, n in ipairs(ARMAS_CAJA) do
			local yaTiene = bp:FindFirstChild(n) or (plr.Character and plr.Character:FindFirstChild(n))
			if ServerStorage:FindFirstChild(n) and not yaTiene then table.insert(opciones, n) end
		end
		if #opciones == 0 then return end  -- ya las tiene todas: la caja queda para otro
		tomada = true
		local nombre = opciones[math.random(#opciones)]
		ServerStorage:FindFirstChild(nombre):Clone().Parent = bp
		anuncioEvent:FireClient(plr, "🎁 ¡Conseguiste " .. NOMBRE_ARMA[nombre] .. "!", Color3.fromRGB(255, 220, 80), 2.5)
		chispas(caja.Position, Color3.fromRGB(255, 220, 80), 30, 18)
		caja:Destroy()
	end)
	Debris:AddItem(caja, 40)
end

-- ===== Muerte de un robot =====
local function morirRobot(modelo, root, tipo, tipoNombre)
	if not vivos[modelo] then return end
	vivos[modelo] = nil
	local pos = root.Position

	-- Recompensa: al último que le pegó (bazuca/láser), o al jugador más cercano
	local id = modelo:GetAttribute("UltimoAtacante")
	local quien = id and Players:GetPlayerByUserId(id)
	if not quien then
		local mejor = 150
		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = cuerpoDe(plr)
			if hrp and (hrp.Position - pos).Magnitude < mejor then
				mejor = (hrp.Position - pos).Magnitude; quien = plr
			end
		end
	end
	if quien then
		darPuntos(quien, tipo.puntos)
		popup(pos + Vector3.new(0, 4 + tipo.fx * 2, 0), "+" .. tipo.puntos .. " 🏆", Color3.fromRGB(255, 225, 90))
	end

	-- Caja de armas (el jefe suelta 2)
	local nCajas = (tipoNombre == "Jefe") and 2 or ((math.random() < (tipo.caja or 0)) and 1 or 0)
	for _ = 1, nCajas do
		soltarCaja(pos + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
	end

	if tipo.esJefe then
		setEstado("JefeNombre", "")
		if tipo.final then
			task.spawn(terminarFinal, true)
		else
			for _, plr in ipairs(Players:GetPlayers()) do darPuntos(plr, tipo.bonusTodos) end
			anunciar("🏆 ¡JEFE DERROTADO! +" .. tipo.bonusTodos .. " para todos", Color3.fromRGB(255, 225, 90), 4)
		end
		local veces = tipo.final and 12 or 7
		local tam = tipo.final and 1.6 or 1
		task.spawn(function()
			for _ = 1, veces do
				explosion(pos + Vector3.new(math.random(-14, 14), math.random(-4, 18), math.random(-14, 14)) * tam, 10 * tam)
				sacudir(pos, 150, 1.4, 0.25)
				task.wait(0.22)
			end
			explosion(pos, 26 * tam, Color3.fromRGB(255, 230, 150))
			sacudir(pos, 220, 3, 0.8)
		end)
	elseif tipoNombre == "Coloso" then
		task.spawn(function()
			for _ = 1, 3 do
				explosion(pos + Vector3.new(math.random(-8, 8), math.random(0, 12), math.random(-8, 8)), 9)
				task.wait(0.18)
			end
			explosion(pos, 16)
			sacudir(pos, 120, 1.8, 0.5)
		end)
	else
		explosion(pos, 3 + tipo.fx * 3.5)
		sacudir(pos, 30 + tipo.fx * 15, 0.4 + tipo.fx * 0.2, 0.2)
	end

	-- Se despedaza
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("Motor6D") or d:IsA("BodyMover") then d:Destroy() end
	end
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Massless = false
			p.CanCollide = p.Transparency < 1
			p.AssemblyLinearVelocity = Vector3.new(math.random(-35, 35), math.random(25, 55), math.random(-35, 35))
		end
	end
	Debris:AddItem(modelo, 4)
	actualizarRestantes()
end

-- ===== IA general (perseguir y tocar) =====
local function ia(modelo, root, hum, tipo, tipoNombre)
	local cooldowns = {}
	local ultimaPos, atascado, tCheck = root.Position, 0, tick()
	local ultimoPaso = 0
	while modelo.Parent and root.Parent and hum.Health > 0 do
		if root.Position.Y < -400 then break end

		local plr, hrp, d
		if tipo.esJefe then
			-- el jefe camina hacia su PRESA (la elige iaJefe según el daño recibido)
			local presa = objetivoDe[modelo]
			if presa and esObjetivo(presa) then
				local h1, hh1 = cuerpoDe(presa)
				if h1 and hh1 and hh1.Health > 0 then
					plr, hrp, d = presa, h1, (h1.Position - root.Position).Magnitude
				end
			end
		end
		if not hrp then plr, hrp, d = objetivoMasCercano(root.Position) end

		if hrp then
			hum:MoveTo(hrp.Position)
			local horiz = Vector3.new(hrp.Position.X - root.Position.X, 0, hrp.Position.Z - root.Position.Z).Magnitude
			local vert = math.abs(hrp.Position.Y - root.Position.Y)
			-- el jefe aplasta a CUALQUIERA que se le acerque, no solo a su presa
			local tocables = tipo.esJefe and Players:GetPlayers() or { plr }
			for _, otro in ipairs(tocables) do
				if otro == plr or esObjetivo(otro) then
					local ohrp, ohum = cuerpoDe(otro)
					if ohrp and ohum and ohum.Health > 0 then
						local oh = Vector3.new(ohrp.Position.X - root.Position.X, 0, ohrp.Position.Z - root.Position.Z).Magnitude
						local ov = math.abs(ohrp.Position.Y - root.Position.Y)
						if oh <= tipo.alcance and ov <= tipo.alto then
							local ahora = tick()
							if not cooldowns[otro] or ahora - cooldowns[otro] > 1 then
								cooldowns[otro] = ahora
								tocarJugador(otro, ohum, ohrp, tipo, root.Position, modelo)
							end
						end
					end
				end
			end
			if horiz > tipo.alcance and horiz <= tipo.alcance * 2.2 then
				marcarAtaque(modelo)  -- se prepara: levanta las garras al acercarse
			end
		else
			hum:MoveTo(centroMapa)
		end

		-- Pasos de gigante: la cámara tiembla cerca
		if tipo.pasos then
			local v = root.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude > 3 and tick() - ultimoPaso > 0.7 then
				ultimoPaso = tick()
				sacudir(root.Position, 80, 0.4, 0.15)
			end
		end

		-- ¿Atascado? Salta y, si sigue, reaparece cerca del objetivo
		if tick() - tCheck > 2 then
			tCheck = tick()
			if hrp and d and d > tipo.alcance + 4 and (root.Position - ultimaPos).Magnitude < 2 then
				atascado += 1
				hum.Jump = true
				if atascado >= 4 then
					local p = puntoCerca(hrp.Position, 35 + tipo.fx * 5)
					if p then
						modelo:PivotTo(CFrame.new(p + Vector3.new(0, hum.HipHeight + root.Size.Y / 2, 0)))
						aparicion(p, tipo.fx)
					end
					atascado = 0
				end
			else
				atascado = math.max(0, atascado - 1)
			end
			ultimaPos = root.Position
		end
		task.wait(0.15)
	end

	-- Si salió del bucle sin morir (cayó al vacío, etc.), se retira sin premio
	if vivos[modelo] and hum.Health > 0 then
		vivos[modelo] = nil
		if tipo.esJefe then setEstado("JefeNombre", "") end
		modelo:Destroy()
		actualizarRestantes()
	end
end

-- ===== IA del dron: vuela en círculos sobre su objetivo y dispara =====
local function iaDron(modelo, root, hum, tipo)
	local bp = Instance.new("BodyPosition")
	bp.MaxForce = Vector3.new(1e6, 1e6, 1e6); bp.P = 4000; bp.D = 600
	bp.Position = root.Position
	bp.Parent = root
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6); bg.P = 5000; bg.D = 400
	bg.CFrame = root.CFrame
	bg.Parent = root

	local angulo = math.random() * math.pi * 2
	local sentido = (math.random() < 0.5) and 1 or -1
	local radio = 14 + math.random() * 10
	local altura = 9 + math.random() * 6
	local proximoTiro = tick() + 1.5 + math.random() * 1.5
	while modelo.Parent and root.Parent and hum.Health > 0 do
		local _, hrp = objetivoMasCercano(root.Position)
		local centro = hrp and hrp.Position or (centroMapa + Vector3.new(0, 10, 0))
		angulo += 0.12 * sentido
		bp.Position = centro + Vector3.new(math.cos(angulo) * radio, altura, math.sin(angulo) * radio)

		-- mira a su objetivo con la nariz inclinada hacia abajo
		local mira = hrp and hrp.Position or bp.Position
		local plano = Vector3.new(mira.X, root.Position.Y, mira.Z)
		if (plano - root.Position).Magnitude > 0.5 then
			bg.CFrame = CFrame.lookAt(root.Position, plano) * CFrame.Angles(math.rad(-12), 0, 0)
		end

		if hrp and tick() >= proximoTiro then
			proximoTiro = tick() + tipo.disparo.cadencia * (0.8 + math.random() * 0.4)
			if (hrp.Position - root.Position).Magnitude <= tipo.disparo.alcance then
				local lente = modelo:FindFirstChild("Lente")
				dispararRayoDron(modelo, (lente or root).Position, hrp.Position, tipo.disparo.dano)
			end
		end
		task.wait(0.15)
	end
	if vivos[modelo] and hum.Health > 0 then
		vivos[modelo] = nil
		modelo:Destroy()
		actualizarRestantes()
	end
end

-- ===== Extras de aspecto por tipo =====
local function adornar(tipoNombre, partes, root)
	if tipoNombre == "Chatarra" then
		local att = Instance.new("Attachment"); att.Parent = partes.Pecho or root
		att.Position = Vector3.new(0, 1, 1)
		local humo = Instance.new("ParticleEmitter")
		humo.Texture = "rbxasset://textures/particles/smoke_main.dds"
		humo.Lifetime = NumberRange.new(1, 2); humo.Rate = 6
		humo.Speed = NumberRange.new(2, 4); humo.Size = NumberSequence.new(1, 3)
		humo.Transparency = NumberSequence.new(0.4, 1)
		humo.Color = ColorSequence.new(Color3.fromRGB(60, 55, 50))
		humo.Parent = att
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 130, 20); luz.Brightness = 2; luz.Range = 10
		luz.Parent = partes.OjoIzq or root
	elseif tipoNombre == "Coloso" then
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 130, 20); luz.Brightness = 3; luz.Range = 28
		luz.Parent = partes.Craneo or root
		local att = Instance.new("Attachment"); att.Parent = partes.Nucleo or root
		local brasas = Instance.new("ParticleEmitter")
		brasas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brasas.Lifetime = NumberRange.new(0.5, 1); brasas.Rate = 12
		brasas.Speed = NumberRange.new(2, 5); brasas.SpreadAngle = Vector2.new(70, 70)
		brasas.Color = ColorSequence.new(Color3.fromRGB(255, 140, 30))
		brasas.Parent = att
	elseif tipoNombre == "JefeFinal" then
		local CIAN = Color3.fromRGB(90, 220, 255)
		local luz = Instance.new("PointLight")
		luz.Color = CIAN; luz.Brightness = 4; luz.Range = 45; luz.Parent = partes.Nucleo or root
		local luzPuno = Instance.new("PointLight")
		luzPuno.Color = CIAN; luzPuno.Brightness = 6; luzPuno.Range = 35; luzPuno.Parent = partes.BocaDer or root
		-- chispas eléctricas en el puño y el núcleo
		for _, nombre in ipairs({ "BocaDer", "EnergiaAnt", "Nucleo" }) do
			local pt = partes[nombre]
			if pt then
				local att = Instance.new("Attachment"); att.Parent = pt
				local ch = Instance.new("ParticleEmitter")
				ch.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				ch.Lifetime = NumberRange.new(0.2, 0.5); ch.Rate = 40
				ch.Speed = NumberRange.new(6, 14); ch.SpreadAngle = Vector2.new(180, 180)
				ch.Size = NumberSequence.new(1.2, 0)
				ch.Color = ColorSequence.new(Color3.fromRGB(200, 245, 255), CIAN)
				ch.LightEmission = 1
				ch.Parent = att
			end
		end
		-- fuego en propulsores (piernas y mochila)
		for _, nombre in ipairs({ "PropulsorIzq", "PropulsorDer", "ToberaIzq", "ToberaDer" }) do
			local pt = partes[nombre]
			if pt then
				local att = Instance.new("Attachment"); att.Parent = pt
				local f = Instance.new("ParticleEmitter")
				f.Texture = "rbxasset://textures/particles/fire_main.dds"
				f.Lifetime = NumberRange.new(0.3, 0.6); f.Rate = 30
				f.Speed = NumberRange.new(4, 8); f.Size = NumberSequence.new(2.5, 0)
				f.SpreadAngle = Vector2.new(15, 15)
				f.EmissionDirection = Enum.NormalId.Back
				f.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 80, 20))
				f.Parent = att
			end
		end
		-- mini rayos que recorren el brazo de energía
		task.spawn(function()
			local tramos = { partes.EnergiaSup, partes.CodoDer, partes.EnergiaAnt, partes.BocaDer }
			while root.Parent do
				local a = tramos[math.random(#tramos)]
				local b = tramos[math.random(#tramos)]
				if a and b and a ~= b and a.Parent and b.Parent then
					local p0 = a.Position + Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)) / 10
					local p1 = b.Position + Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)) / 10
					local medio = p0:Lerp(p1, 0.5) + Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15)) / 10
					for _, par in ipairs({ { p0, medio }, { medio, p1 } }) do
						local s = Instance.new("Part")
						s.Anchored = true; s.CanCollide = false; s.CanQuery = false; s.CanTouch = false
						s.Material = Enum.Material.Neon; s.Color = Color3.fromRGB(210, 245, 255)
						s.Size = Vector3.new(0.3, 0.3, (par[2] - par[1]).Magnitude)
						s.CFrame = CFrame.new(par[1]:Lerp(par[2], 0.5), par[2])
						s.Parent = workspace
						Debris:AddItem(s, 0.1)
					end
				end
				task.wait(0.15)
			end
		end)
	elseif tipoNombre == "Jefe" then
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 230, 70); luz.Brightness = 3; luz.Range = 35
		luz.Parent = partes.Cabeza or root
		local att = Instance.new("Attachment"); att.Parent = partes.Nucleo or root
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Lifetime = NumberRange.new(0.6, 1.2); aura.Rate = 25
		aura.Speed = NumberRange.new(3, 7); aura.SpreadAngle = Vector2.new(180, 180)
		aura.Color = ColorSequence.new(Color3.fromRGB(255, 160, 60))
		aura.Parent = att
	end
end

-- ===== Crear un robot =====
generarRobot = function(tipoNombre, posSuelo, vidaMult)
	local tipo = CONFIG.TIPOS[tipoNombre]
	local modelo, root, hum, partes, ojos = Modelos.construir(tipoNombre, posSuelo)

	-- el jefe final cuenta solo a los finalistas para calcular su vida
	local nJug = tipo.final and math.max(1, numFinalistas) or #Players:GetPlayers()
	local vida = (tipo.vida + (tipo.vidaPorJugador or 0) * nJug) * (vidaMult or 1)
	vida = math.floor(vida)
	hum.MaxHealth = vida
	hum.Health = vida
	hum.WalkSpeed = tipo.velocidad
	if tipo.salta == false then hum.JumpPower = 0 end
	if tipo.vuela then
		hum.PlatformStand = true   -- lo mueve su propio motor de vuelo, no el Humanoid
		root.CanCollide = false
	end

	-- Destello blanco al recibir daño (+ contorno rojo en los gigantes)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.fromRGB(255, 40, 40)
	hl.OutlineTransparency = tipo.contorno and 0 or 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = modelo

	modelo:SetAttribute("Tipo", tipoNombre)
	if tipo.final then modelo:SetAttribute("JefeFinal", true) end
	if tipo.esJefe then modelo:SetAttribute("EsJefe", true) end -- RegistroDano anota la "amenaza"
	adornar(tipoNombre, partes, root)

	-- Barra de vida sobre los robots (el jefe usa la barra grande de arriba)
	local fill
	if not tipo.esJefe then
		local alturaTotal = modelo:GetExtentsSize().Y
		local alturaRoot = hum.HipHeight + root.Size.Y / 2
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 60 + tipo.fx * 25, 0, 8 + tipo.fx * 1.5)
		bb.StudsOffset = Vector3.new(0, tipo.vuela and 2.5 or (alturaTotal - alturaRoot + 1.5), 0)
		bb.Adornee = root; bb.Parent = root
		local fondo = Instance.new("Frame")
		fondo.Size = UDim2.new(1, 0, 1, 0); fondo.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		fondo.BorderSizePixel = 0; fondo.Parent = bb
		fill = Instance.new("Frame")
		fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		fill.BorderSizePixel = 0; fill.Parent = fondo
	else
		setEstado("JefeNombre", tipo.nombre)
		setEstado("JefeVidaMax", vida)
		setEstado("JefeVida", vida)
	end

	modelo.Parent = carpeta
	pcall(function() root:SetNetworkOwner(nil) end)
	vivos[modelo] = true

	local vidaPrevia = hum.Health
	hum.HealthChanged:Connect(function(h)
		if h < vidaPrevia then
			local golpe = math.floor(vidaPrevia - h + 0.5)
			if golpe >= 1 and root.Parent then
				numeroDano(root.Position + Vector3.new(0, 2 + tipo.fx, 0), golpe)
			end
			hl.FillTransparency = 0.35
			task.delay(0.08, function() if hl.Parent then hl.FillTransparency = 1 end end)
		end
		vidaPrevia = h
		if fill then fill.Size = UDim2.new(math.clamp(h / hum.MaxHealth, 0, 1), 0, 1, 0) end
		if tipo.esJefe then setEstado("JefeVida", math.max(0, math.floor(h))) end
	end)

	hum.Died:Connect(function() morirRobot(modelo, root, tipo, tipoNombre) end)

	aparicion(posSuelo, tipo.fx)
	if tipo.vuela then
		task.spawn(iaDron, modelo, root, hum, tipo)
	else
		task.spawn(ia, modelo, root, hum, tipo, tipoNombre)
	end
	if tipo.esJefe or tipoNombre == "Coloso" then
		sacudir(posSuelo, 200, tipo.esJefe and 2 or 1.2, 0.6)
	end
	if tipo.esJefe then
		task.spawn(iaJefe, modelo, root, hum, tipo, partes, ojos)
	end
	actualizarRestantes()
	return modelo
end

-- ===== Oleadas =====
local function mezclar(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

local GRANDES = { Coloso = true, Jefe = true }

local function generarOleada(n, miId)
	local jugadores = math.max(1, #Players:GetPlayers())
	local f = 1 + 0.12 * (jugadores - 1)
	-- (Coloso y Jefe ya suben su vida por jugador con "vidaPorJugador": no se cuenta doble)
	local vidaBase = 1 + 0.12 * (n - 1)
	local vidaMult = vidaBase * multVidaJugadores()
	local esJefe = (n % CONFIG.JEFE_CADA == 0)
	setEstado("TipoOleada", esJefe and "jefe" or "normal")

	local cant = {
		Seguidor = math.min(30, math.floor((2 + 1.5 * n) * f)),
		Arana    = math.min(20, math.floor((2 + n) * f)),
		Soldado  = (n >= 2) and math.min(10, math.floor((1 + n * 0.8) * f)) or 0,
		Tanque   = (n >= 2) and math.min(8, math.floor((n / 2) * f)) or 0,
		Chatarra = (n >= 2) and math.min(10, math.floor((1 + n * 0.7) * f)) or 0,
		Coloso   = (n >= 3) and math.min(4, math.max(1, math.floor(((n - 1) / 2) * f))) or 0,
	}
	if esJefe then
		for _, k in ipairs({ "Seguidor", "Arana", "Soldado", "Tanque", "Chatarra" }) do
			cant[k] = math.floor(cant[k] * 0.5)
		end
	end

	local lista = {}
	for tipoNombre, c in pairs(cant) do
		for _ = 1, c do table.insert(lista, tipoNombre) end
	end
	mezclar(lista)

	porGenerar = #lista + (esJefe and 1 or 0)
	actualizarRestantes()

	-- Avisos de los tipos nuevos (solo la primera vez)
	if cant.Chatarra > 0 and not yaAnunciado.Chatarra then
		yaAnunciado.Chatarra = true
		task.delay(2.6, function()
			anunciar("⚠️ ¡LLEGAN ROBOTS MÁS GRANDES!", Color3.fromRGB(255, 150, 60), 2.5)
		end)
	end
	if cant.Coloso > 0 and not yaAnunciado.Coloso then
		yaAnunciado.Coloso = true
		task.delay(2.6, function()
			anunciar("☠️ ¡COLOSOS A LA VISTA! Si te tocan, mueres", Color3.fromRGB(255, 120, 20), 3)
		end)
	end

	if esJefe then
		anunciar("⚠️ ¡SE ACERCA EL JEFE: " .. CONFIG.TIPOS.Jefe.nombre .. "!", Color3.fromRGB(255, 60, 60), 3.5)
		task.wait(2.5)
		if miId ~= cicloId then return end
		local p = puntoAparicion(true)
		porGenerar -= 1
		if p then generarRobot("Jefe", p, vidaBase) end
		actualizarRestantes()
	end

	for _, tipoNombre in ipairs(lista) do
		if miId ~= cicloId then return end
		while contarVivos() >= maxVivos() do
			task.wait(0.5)
			if miId ~= cicloId then return end
		end
		local p = puntoAparicion(GRANDES[tipoNombre] == true)
		porGenerar -= 1
		if p then generarRobot(tipoNombre, p, CONFIG.TIPOS[tipoNombre].vidaPorJugador and vidaBase or vidaMult) end
		actualizarRestantes()
		task.wait(0.45)
	end
end

-- Oleada extra: enjambre de drones
local function generarEnjambre(n, miId)
	local jugadores = math.max(1, #Players:GetPlayers())
	local total = math.min(16, math.floor((4 + n) * (1 + 0.12 * (jugadores - 1))))
	setEstado("TipoOleada", "drones")
	setEstado("Fase", "oleada")
	anunciar("🛸 ¡OLEADA EXTRA: ENJAMBRE DE DRONES!", Color3.fromRGB(120, 255, 200), 3)
	porGenerar = total
	actualizarRestantes()
	task.wait(2)
	for _ = 1, total do
		if miId ~= cicloId then return end
		while contarVivos() >= maxVivos() do
			task.wait(0.5)
			if miId ~= cicloId then return end
		end
		local p = puntoAparicion(false)
		porGenerar -= 1
		if p then generarRobot("Dron", p, (1 + 0.1 * (n - 1)) * multVidaJugadores()) end
		actualizarRestantes()
		task.wait(0.35)
	end
end

-- =====================================================================
--  GRAN FINAL: los 2 mejores equipos contra el MEGA-ARDUINO gigante
--  en una arena especial (placa Arduino flotando en el cielo).
--  Gana el equipo que le haga MÁS DAÑO. Los demás miran desde la tribuna.
-- =====================================================================
local EQUIPOS = {
	{ nombre = "Rojo",    color = Color3.fromRGB(220, 40, 40) },
	{ nombre = "Azul",    color = Color3.fromRGB(30, 130, 255) },
	{ nombre = "Verde",   color = Color3.fromRGB(30, 200, 60) },
	{ nombre = "Naranja", color = Color3.fromRGB(255, 160, 0) },
	{ nombre = "Morado",  color = Color3.fromRGB(150, 60, 235) },
}
local function nombreEquipo(i)
	return EQUIPOS[i] and ("Equipo " .. EQUIPOS[i].nombre) or "—"
end

local function construirArena()
	local existente = workspace:FindFirstChild("ArenaFinal")
	if existente then return existente:GetAttribute("Centro") end
	calcularMapa()
	local C = centroMapa + Vector3.new(0, 450, 0)
	local piso = C.Y + 2
	local arena = Instance.new("Model")
	arena.Name = "ArenaFinal"
	arena:SetAttribute("Centro", C)

	local function bloque(nombre, size, color, mat, cf, forma, transp)
		local p = Instance.new("Part")
		p.Name = nombre; p.Anchored = true
		p.Size = size; p.Color = color; p.Material = mat
		if forma then p.Shape = forma end
		p.Transparency = transp or 0
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf
		p.Parent = arena
		return p
	end
	local function texto(part, cara, txt, color)
		local sg = Instance.new("SurfaceGui")
		sg.Face = cara
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 20
		sg.Parent = part
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
		t.Text = txt; t.TextColor3 = color; t.TextScaled = true; t.Font = Enum.Font.FredokaOne
		t.Parent = sg
	end
	local RGB = Color3.fromRGB
	local SM, MET, NEO = Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Neon

	-- piso: una placa Arduino gigante
	bloque("Piso", Vector3.new(4, 190, 190), RGB(0, 129, 132), SM, CFrame.new(C) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	local techo = bloque("Techo", Vector3.new(1, 200, 200), RGB(255, 255, 255), SM,
		CFrame.new(C.X, piso + 50, C.Z) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 1)
	techo.CanQuery = false  -- invisible: que no "ataje" la lluvia, los refuerzos ni las balas

	-- pistas de circuito brillantes
	for i = -3, 3 do
		local largo = 2 * math.sqrt(90 ^ 2 - (i * 22) ^ 2) - 4
		bloque("PistaX" .. i, Vector3.new(largo, 0.2, 0.8), RGB(255, 200, 80), NEO, CFrame.new(C.X, piso + 0.1, C.Z + i * 22))
		bloque("PistaZ" .. i, Vector3.new(0.8, 0.2, largo), RGB(255, 200, 80), NEO, CFrame.new(C.X + i * 22, piso + 0.1, C.Z))
	end

	-- logo en el piso
	local logo = bloque("Logo", Vector3.new(56, 0.3, 13), RGB(0, 100, 104), SM, CFrame.new(C.X, piso + 0.15, C.Z - 74))
	texto(logo, Enum.NormalId.Top, "ARDUINO", RGB(255, 255, 255))

	-- chips gigantes que sirven de cobertura
	for k = 0, 5 do
		local a = math.rad(k * 60 + 30)
		local cf = CFrame.new(C.X + math.cos(a) * 48, piso + 3, C.Z + math.sin(a) * 48) * CFrame.Angles(0, -a, 0)
		local chip = bloque("Chip" .. k, Vector3.new(16, 6, 9), RGB(25, 25, 28), SM, cf)
		texto(chip, Enum.NormalId.Top, "ATmega328P", RGB(200, 200, 205))
		for j = -3, 3 do
			bloque("Pin" .. k .. "a" .. j, Vector3.new(1, 1.2, 1.6), RGB(190, 192, 198), MET, cf * CFrame.new(j * 2.2, -2.4, 5.1))
			bloque("Pin" .. k .. "b" .. j, Vector3.new(1, 1.2, 1.6), RGB(190, 192, 198), MET, cf * CFrame.new(j * 2.2, -2.4, -5.1))
		end
		local luz = Instance.new("PointLight"); luz.Color = RGB(255, 170, 60); luz.Range = 25; luz.Brightness = 1.5; luz.Parent = chip
	end

	-- torres LED (rojo, verde, azul, amarillo)
	for k, color in ipairs({ RGB(255, 60, 60), RGB(80, 255, 120), RGB(80, 150, 255), RGB(255, 220, 60) }) do
		local a = math.rad(k * 90)
		local base = Vector3.new(C.X + math.cos(a) * 80, piso + 7, C.Z + math.sin(a) * 80)
		bloque("Torre" .. k, Vector3.new(3, 14, 3), RGB(40, 40, 45), MET, CFrame.new(base))
		local led = bloque("LED" .. k, Vector3.new(4, 4, 4), color, NEO, CFrame.new(base + Vector3.new(0, 9, 0)), Enum.PartType.Ball)
		local luz = Instance.new("PointLight"); luz.Color = color; luz.Range = 60; luz.Brightness = 2; luz.Parent = led
	end

	-- muros invisibles, borde de neón y tribuna con vidrio
	for k = 0, 35 do
		local a = math.rad(k * 10)
		local function anillo(r, y) return Vector3.new(C.X + math.cos(a) * r, y, C.Z + math.sin(a) * r) end
		local function haciaCentro(p) return CFrame.lookAt(p, Vector3.new(C.X, p.Y, C.Z)) end
		bloque("Muro" .. k, Vector3.new(17.5, 50, 2), RGB(255, 255, 255), SM, haciaCentro(anillo(95, piso + 25)), nil, 1)
		bloque("Borde" .. k, Vector3.new(17.5, 1, 1.5), RGB(255, 50, 50), NEO, haciaCentro(anillo(93.5, piso + 0.6)))
		bloque("Tribuna" .. k, Vector3.new(20.5, 2, 16), RGB(60, 64, 72), MET, haciaCentro(anillo(112, piso + 27)))
		bloque("Vidrio" .. k, Vector3.new(19, 14, 0.8), RGB(170, 210, 230), Enum.Material.Glass, haciaCentro(anillo(104, piso + 35)), nil, 0.6)
		bloque("Baranda" .. k, Vector3.new(22, 14, 1), RGB(255, 255, 255), SM, haciaCentro(anillo(120.5, piso + 35)), nil, 1)
		if k % 3 == 0 then
			local foco = bloque("Foco" .. k, Vector3.new(2, 0.6, 2), RGB(255, 220, 120), NEO, haciaCentro(anillo(112, piso + 28.3)))
			local luz = Instance.new("PointLight"); luz.Color = foco.Color; luz.Range = 30; luz.Parent = foco
		end
	end

	arena.Parent = workspace
	return C
end

local function posicionFinal(plr)
	local C = arenaCentro
	if not C then return nil end
	local piso = C.Y + 2
	local eq = plr:GetAttribute("TeamNumber")
	if eq and eq ~= 0 and eq == finalA then
		return Vector3.new(C.X - 62, piso + 4, C.Z + math.random(-12, 12))
	elseif eq and eq ~= 0 and eq == finalB then
		return Vector3.new(C.X + 62, piso + 4, C.Z + math.random(-12, 12))
	end
	local a = math.random() * math.pi * 2  -- los demás, a la tribuna
	return Vector3.new(C.X + math.cos(a) * 112, piso + 31, C.Z + math.sin(a) * 112)
end

local function enviarAFinal(plr)
	local hrp = cuerpoDe(plr)
	local p = posicionFinal(plr)
	if hrp and p then
		hrp.CFrame = CFrame.lookAt(p, Vector3.new(arenaCentro.X, p.Y, arenaCentro.Z))
	end
end

local function volverABases()
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = cuerpoDe(plr)
		local eq = plr:GetAttribute("TeamNumber")
		local base = eq and workspace:FindFirstChild("BaseEquipo" .. eq)
		local destino
		if base and base.PrimaryPart then
			destino = base.PrimaryPart.Position + Vector3.new(0, 5, 0)
		else
			local gm = workspace:FindFirstChild("GMSpawnLocation")
			destino = gm and (gm.Position + Vector3.new(0, 5, 0)) or (centroMapa + Vector3.new(0, 10, 0))
		end
		if hrp then hrp.CFrame = CFrame.new(destino) end
	end
end

-- Si un finalista muere, reaparece en la arena; los demás, en la tribuna
local function alAparecer(plr)
	task.wait(0.8)
	if finalActiva then enviarAFinal(plr) end
end
local function engancharJugador(plr)
	plr.CharacterAdded:Connect(function() task.spawn(alAparecer, plr) end)
end
Players.PlayerAdded:Connect(engancharJugador)
for _, plr in ipairs(Players:GetPlayers()) do engancharJugador(plr) end

local function confeti(C)
	if not C then return end
	local colores = {
		Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 255, 120),
		Color3.fromRGB(80, 160, 255), Color3.fromRGB(220, 100, 255),
	}
	for k = 1, 10 do
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.Transparency = 1
		p.Size = Vector3.new(1, 1, 1)
		p.CFrame = CFrame.new(C + Vector3.new(math.random(-60, 60), 35, math.random(-60, 60)))
		p.Parent = workspace
		local att = Instance.new("Attachment"); att.Parent = p
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(colores[(k % #colores) + 1])
		e.Lifetime = NumberRange.new(3, 5); e.Rate = 0
		e.Speed = NumberRange.new(20, 45); e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(0, -18, 0)
		e.Size = NumberSequence.new(0.7); e.RotSpeed = NumberRange.new(-200, 200)
		e.Parent = att
		e:Emit(120)
		Debris:AddItem(p, 6)
		if k % 3 == 0 then explosion(p.Position, 6, colores[(k % #colores) + 1]) end
	end
end

local function totalEquipo(i)
	local pe = ReplicatedStorage:FindFirstChild("PuntajeEquipos")
	if not pe then return 0 end
	return (pe:GetAttribute("Puntos" .. i) or 0)
		+ (pe:GetAttribute("Componentes" .. i) or 0) * (pe:GetAttribute("PorComponente") or 20)
end

local function iniciarFinal()
	if finalActiva then return end
	cicloId += 1  -- detiene las oleadas
	porGenerar = 0
	vivos = {}
	for _, c in ipairs(carpeta:GetChildren()) do c:Destroy() end
	setEstado("JefeNombre", "")

	-- los 2 mejores equipos que tengan jugadores
	local equipos = {}
	for i = 1, #EQUIPOS do
		local hay = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr:GetAttribute("TeamNumber") == i then hay += 1 end
		end
		if hay > 0 then table.insert(equipos, { i = i, total = totalEquipo(i), n = hay }) end
	end
	table.sort(equipos, function(a, b) return a.total > b.total end)
	finalA = equipos[1] and equipos[1].i or 0
	finalB = equipos[2] and equipos[2].i or 0
	numFinalistas = (equipos[1] and equipos[1].n or 0) + (equipos[2] and equipos[2].n or 0)
	setEstado("FinalA", finalA)
	setEstado("FinalB", finalB)
	setEstado("DanoA", 0)
	setEstado("DanoB", 0)
	setEstado("Ganador", 0)

	arenaCentro = construirArena()
	finalActiva = true
	setEstado("Restantes", 0)
	setEstado("Cuenta", CONFIG.FINAL_TIEMPO)
	setEstado("Fase", "final")

	local titulo
	if finalA ~= 0 and finalB ~= 0 then
		titulo = "🏆 ¡GRAN FINAL!  " .. nombreEquipo(finalA) .. "  vs  " .. nombreEquipo(finalB)
	elseif finalA ~= 0 then
		titulo = "🏆 ¡GRAN FINAL!  " .. nombreEquipo(finalA) .. " contra el jefe"
	else
		titulo = "🏆 ¡GRAN FINAL! (prueba sin equipos)"
	end
	anunciar(titulo, Color3.fromRGB(255, 220, 80), 5)
	task.wait(1.5)
	for _, plr in ipairs(Players:GetPlayers()) do enviarAFinal(plr) end

	-- aparece el hechicero ARDUNOL flotando sobre la arena
	local piso = arenaCentro.Y + 2
	Escena.aparecerArdunol(Vector3.new(arenaCentro.X, piso + 26, arenaCentro.Z + 82), arenaCentro)
	task.wait(1.2)
	Escena.hablar("¡JA, JA, JA! ¿Creen que pueden quitarme el ARDUINO SUPREMO?", 4)
	task.wait(3)
	for s = 3, 1, -1 do
		if not finalActiva then return end
		anunciar(tostring(s), Color3.fromRGB(255, 255, 255), 0.8)
		task.wait(1)
	end
	if not finalActiva then return end
	local puntoJefe = Vector3.new(arenaCentro.X, piso, arenaCentro.Z + 20)
	Escena.hablar("¡DESPIERTA, MEGA-ARDUINO! ¡APLÁSTALOS!", 3.5)
	Escena.rayoArdunol(puntoJefe + Vector3.new(0, 4, 0))
	anunciar("⚔️ ¡A PELEAR!  Gana el equipo que haga MÁS DAÑO", Color3.fromRGB(255, 90, 60), 3)
	generarRobot("JefeFinal", puntoJefe, 1)

	-- reloj de la final
	local fin = tick() + CONFIG.FINAL_TIEMPO
	task.spawn(function()
		while finalActiva do
			local resta = math.max(0, math.ceil(fin - tick()))
			setEstado("Cuenta", resta)
			if resta <= 0 then
				terminarFinal(false)
				break
			end
			task.wait(1)
		end
	end)
end

terminarFinal = function(derrotado)
	if not finalActiva then return end
	finalActiva = false
	local dA = estado:GetAttribute("DanoA") or 0
	local dB = estado:GetAttribute("DanoB") or 0
	local ganador = 0
	if finalA ~= 0 and finalB ~= 0 then
		ganador = (dA >= dB) and finalA or finalB
	elseif finalA ~= 0 and derrotado then
		ganador = finalA
	end
	setEstado("Fase", "fin")
	setEstado("Ganador", ganador)

	if not derrotado then
		for _, c in ipairs(carpeta:GetChildren()) do c:Destroy() end
		vivos = {}
		setEstado("JefeNombre", "")
		anunciar("⏰ ¡SE ACABÓ EL TIEMPO!", Color3.fromRGB(255, 200, 120), 3)
	end
	-- en modo prueba (profe solo, sin equipos) también se ve el trofeo si derrota al jefe
	local prueba = (finalA == 0 and derrotado)
	local hayTrofeo = ganador ~= 0 or prueba
	task.spawn(Escena.ardunolHuye, hayTrofeo) -- Ardunol grita y desaparece (o se ríe)
	task.wait(3.8)

	if hayTrofeo then
		local nombre = prueba and "PRUEBA" or EQUIPOS[ganador].nombre -- "Rojo", "Azul"...
		local color = prueba and Color3.fromRGB(255, 200, 60) or EQUIPOS[ganador].color
		anunciar("🏆 ¡EL EQUIPO " .. string.upper(nombre) .. " RECUPERA EL ARDUINO SUPREMO! 🏆", color, 8)
		for _, plr in ipairs(Players:GetPlayers()) do
			local eq = plr:GetAttribute("TeamNumber")
			if ganador ~= 0 and eq == ganador then
				Puntaje.sumar(plr, 300)
			elseif eq ~= nil and eq ~= 0 and (eq == finalA or eq == finalB) then
				Puntaje.sumar(plr, 100)
			end
		end
		-- el ARDUINO SUPREMO aparece frente al equipo ganador (A a la izquierda, B a la derecha)
		local lado = (ganador ~= 0 and ganador == finalB) and 1 or -1
		local piso = arenaCentro.Y + 2
		Escena.crearTrofeo(Vector3.new(arenaCentro.X + lado * 30, piso, arenaCentro.Z),
			Vector3.new(arenaCentro.X + lado * 62, piso, arenaCentro.Z), ganador, nombre, color, true)
		confeti(arenaCentro)
	else
		anunciar("🤖 ¡Ardunol se queda con el ARDUINO SUPREMO... esta vez!", Color3.fromRGB(255, 80, 80), 6)
	end
	task.wait(14)

	-- todos de vuelta a sus bases
	for _, c in ipairs(carpeta:GetChildren()) do c:Destroy() end
	vivos = {}
	setEstado("JefeNombre", "")
	setEstado("Oleada", 0)
	setEstado("Restantes", 0)
	setEstado("FinalA", 0)
	setEstado("FinalB", 0)
	setEstado("Fase", "espera")
	finalA, finalB = 0, 0
	volverABases()

	-- el trofeo se queda frente a la base del equipo campeón (como monumento)
	if ganador ~= 0 then
		local base = workspace:FindFirstChild("BaseEquipo" .. ganador)
		local bp = base and base.PrimaryPart and base.PrimaryPart.Position
		if bp then
			local hacia = Vector3.new(centroMapa.X - bp.X, 0, centroMapa.Z - bp.Z)
			hacia = hacia.Magnitude > 1 and hacia.Unit or Vector3.new(0, 0, -1)
			local p = bp + hacia * 26
			local suelo = sueloEn(p.X, p.Z, bp.Y) or Vector3.new(p.X, bp.Y, p.Z)
			Escena.crearTrofeo(suelo, bp, ganador, EQUIPOS[ganador].nombre, EQUIPOS[ganador].color, true)
		end
	else
		local t = Escena.trofeoActual()
		if t then t:Destroy() end
	end
end

local function iniciarCiclo()
	cicloId += 1
	local miId = cicloId
	yaAnunciado = {}
	calcularMapa()
	task.spawn(function()
		local n = 0
		while miId == cicloId do
			n += 1
			setEstado("Oleada", n)
			setEstado("Fase", "oleada")
			anunciar("🤖 OLEADA " .. n, Color3.fromRGB(120, 220, 255), 2.5)
			generarOleada(n, miId)
			while miId == cicloId and contarVivos() > 0 do task.wait(0.5) end
			if miId ~= cicloId then break end

			anunciar("✅ ¡OLEADA " .. n .. " SUPERADA!", Color3.fromRGB(120, 255, 150), 2.5)

			-- cada X oleadas: oleada extra de drones
			if n % CONFIG.DRONES_CADA == 0 then
				task.wait(3)
				if miId ~= cicloId then break end
				generarEnjambre(n, miId)
				while miId == cicloId and contarVivos() > 0 do task.wait(0.5) end
				if miId ~= cicloId then break end
				anunciar("✅ ¡ENJAMBRE DESTRUIDO!", Color3.fromRGB(120, 255, 150), 2.5)
			end

			-- ¿llegó la hora de la gran final?
			if CONFIG.OLEADAS_PARA_FINAL > 0 and n >= CONFIG.OLEADAS_PARA_FINAL then
				task.wait(3)
				if miId == cicloId then task.spawn(iniciarFinal) end
				break
			end

			setEstado("TipoOleada", "normal")
			setEstado("Fase", "descanso")
			for s = CONFIG.DESCANSO, 1, -1 do
				if miId ~= cicloId then break end
				setEstado("Cuenta", s)
				task.wait(1)
			end
		end
	end)
end

local function limpiar()
	local estabaEnFinal = finalActiva
	finalActiva = false
	finalA, finalB = 0, 0
	setEstado("FinalA", 0)
	setEstado("FinalB", 0)
	cicloId += 1
	porGenerar = 0
	vivos = {}
	for _, c in ipairs(carpeta:GetChildren()) do c:Destroy() end
	setEstado("Fase", "espera")
	setEstado("Oleada", 0)
	setEstado("Restantes", 0)
	setEstado("JefeNombre", "")
	Escena.quitarArdunol()
	if estabaEnFinal then volverABases() end
end

-- ===== Control del profe (GM) =====
controlEvent.OnServerEvent:Connect(function(plr, accion)
	if not esGM(plr) then return end
	if accion == "iniciar" then
		limpiar()
		iniciarCiclo()
	elseif accion == "jefe" then
		calcularMapa()
		local p = puntoAparicion(true)
		if p then
			anunciar("⚠️ ¡EL PROFE INVOCÓ AL JEFE!", Color3.fromRGB(255, 60, 60), 3)
			generarRobot("Jefe", p, 1)
		end
	elseif accion == "limpiar" then
		limpiar()
		anunciar("🧹 Robots eliminados", Color3.fromRGB(200, 200, 200), 2)
	elseif accion == "drones" then
		calcularMapa()
		anunciar("🛸 ¡EL PROFE SOLTÓ DRONES!", Color3.fromRGB(120, 255, 200), 2.5)
		for _ = 1, 6 do
			local p = puntoAparicion(false)
			if p then generarRobot("Dron", p, 1) end
			task.wait(0.25)
		end
	elseif accion == "final" then
		if not finalActiva then
			anunciar("👑 ¡EL PROFE INICIÓ LA GRAN FINAL!", Color3.fromRGB(255, 220, 80), 2.5)
			task.wait(2)
			task.spawn(iniciarFinal)
		end
	elseif accion == "puntos" then
		Puntaje.sumar(plr, 500)  -- para probar la tienda
		anuncioEvent:FireClient(plr, "💰 +500 puntos (prueba del profe)", Color3.fromRGB(255, 220, 80), 2)
	end
end)

-- ===== Inicio automático cuando empieza la partida =====
task.spawn(function()
	if not CONFIG.INICIO_AUTOMATICO then return end
	while not workspace:GetAttribute("JuegoIniciado") do task.wait(1) end
	task.wait(CONFIG.ESPERA_INICIAL)
	if cicloId == 0 then iniciarCiclo() end
end)

print("✅ Robots enemigos listos (oleadas, drones, jefe y gran final)")
