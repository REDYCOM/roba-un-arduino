--=====================================================================
--  ANIMACIÓN DE ROBOTS (cliente)
--  Mueve las articulaciones (Motor6D) de los robots humanoides:
--  caminar, balancear brazos, inclinarse y levantar las garras al atacar.
--  Se hace en el cliente para que se vea fluido (no carga al servidor).
--=====================================================================

local RunService = game:GetService("RunService")

local carpeta = workspace:WaitForChild("RobotsEnemigos")
local cache = setmetatable({}, { __mode = "k" })

local function obtener(modelo)
	local c = cache[modelo]
	if c ~= nil then return c end
	if modelo:GetAttribute("Animado") ~= true then
		cache[modelo] = false
		return false
	end
	local root = modelo.PrimaryPart
	if not root then return nil end

	-- Dron: 4 hélices
	if modelo:GetAttribute("Anim") == "dron" then
		local helices = {}
		for i = 1, 4 do
			local j = modelo:FindFirstChild("J_Helice" .. i, true)
			if not j then return nil end
			table.insert(helices, j)
		end
		c = { tipo = "dron", root = root, hum = modelo:FindFirstChildOfClass("Humanoid"), helices = helices,
			fase = 0, freq = 1, ataque = 0 }
		cache[modelo] = c
		return c
	end

	-- Araña: 4 patas
	if modelo:GetAttribute("Anim") == "arana" then
		local patas = {}
		for i = 1, 4 do
			local j = modelo:FindFirstChild("J_Pata" .. i, true)
			if not j then return nil end  -- aún cargando
			local dx, dz = j:GetAttribute("DirX") or 1, j:GetAttribute("DirZ") or 0
			table.insert(patas, { j = j, eje = Vector3.new(-dz, 0, dx), frontal = dz < 0, desfase = (i % 2 == 0) and math.pi or 0 })
		end
		c = {
			tipo = "arana", root = root, hum = modelo:FindFirstChildOfClass("Humanoid"), patas = patas,
			fase = math.random() * 6, freq = modelo:GetAttribute("PasoFreq") or 9, ataque = 0,
		}
		cache[modelo] = c
		return c
	end

	local torso = modelo:FindFirstChild("J_Torso", true)
	if not torso then return nil end  -- aún cargando, reintenta después
	c = {
		root = root,
		hum = modelo:FindFirstChildOfClass("Humanoid"),
		torso = torso,
		cabeza = modelo:FindFirstChild("J_Cabeza", true),
		bi = modelo:FindFirstChild("J_BrazoIzq", true),
		bd = modelo:FindFirstChild("J_BrazoDer", true),
		pi = modelo:FindFirstChild("J_PiernaIzq", true),
		pd = modelo:FindFirstChild("J_PiernaDer", true),
		fase = math.random() * 6,
		freq = modelo:GetAttribute("PasoFreq") or 5,
		escala = modelo:GetAttribute("Escala") or 1,
		ataque = 0,  -- 0 = brazos abajo, 1 = garras arriba (suavizado)
	}
	cache[modelo] = c
	return c
end

local function poner(j, cf)
	if j and j.Parent then j.Transform = cf end
end

RunService.Stepped:Connect(function(_, dt)
	local ahora = workspace:GetServerTimeNow()
	local t = os.clock()
	for _, m in ipairs(carpeta:GetChildren()) do
		local c = obtener(m)
		if c and c.root.Parent and c.hum and c.hum.Health > 0 then
			local v = c.root.AssemblyLinearVelocity
			local andar = math.clamp(Vector3.new(v.X, 0, v.Z).Magnitude / 8, 0, 1)
			c.fase += dt * c.freq * (0.35 + andar)
			local f = c.fase
			local sw = math.sin(f)

			-- ¿atacando? (el servidor marca el momento del ataque)
			local atq = m:GetAttribute("Ataque")
			local objetivo = (atq and ahora - atq < 0.7) and 1 or 0
			c.ataque += (objetivo - c.ataque) * math.min(1, dt * 10)
			local a = c.ataque

			if c.tipo == "dron" then
				for i, j in ipairs(c.helices) do
					local sentido = (i % 2 == 0) and 1 or -1
					poner(j, CFrame.Angles(0, t * 45 * sentido, 0))  -- hélices girando
				end
				continue
			end

			if c.tipo == "arana" then
				-- patas en pares diagonales: giran adelante/atrás y se levantan al avanzar;
				-- al atacar levanta las patas delanteras
				for _, p in ipairs(c.patas) do
					local ph = f + p.desfase
					local giro = math.sin(ph) * 0.4 * andar
					local alza = math.max(0, math.cos(ph)) * 0.5 * andar + (p.frontal and a * 0.9 or 0)
					poner(p.j, CFrame.Angles(0, giro, 0) * CFrame.fromAxisAngle(p.eje, alza))
				end
				continue
			end

			-- piernas: pasos alternados
			poner(c.pi, CFrame.Angles(sw * 0.55 * andar, 0, 0))
			poner(c.pd, CFrame.Angles(-sw * 0.55 * andar, 0, 0))

			-- brazos: balanceo al caminar, garras al frente al atacar
			local base = 0.25 + a * 1.3
			local amp = (0.5 * andar + 0.06) * (1 - a * 0.6)
			local sacudida = a * math.sin(t * 18) * 0.15
			poner(c.bi, CFrame.Angles(base - sw * amp + sacudida, 0, -0.14))
			poner(c.bd, CFrame.Angles(base + sw * amp - sacudida, 0, 0.14))

			-- torso: rebote al pisar + inclinado hacia adelante (agresivo)
			local rebote = -math.abs(sw) * 0.12 * c.escala * andar + math.sin(t * 2) * 0.04 * c.escala
			poner(c.torso, CFrame.new(0, rebote, 0) * CFrame.Angles(-(0.08 * andar + a * 0.18), sw * 0.1 * andar, 0))

			-- cabeza: mirada amenazante y embestida al atacar
			poner(c.cabeza, CFrame.Angles(math.sin(f * 2) * 0.06 - a * 0.25, math.sin(t * 1.3) * 0.18 * (1 - a), 0))
		end
	end
end)

print("✅ Animación de robots lista")
