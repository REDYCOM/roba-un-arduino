--=====================================================================
--  TIENDA (servidor) — canjear puntos en el robot de la base [T]
--  Valida todo aquí (precio, distancia a la estación, máximos), así nadie
--  puede comprar haciendo trampa desde el cliente.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Catalogo = require(sistema:WaitForChild("Catalogo"))
local Puntaje = require(script.Parent:WaitForChild("Puntaje"))
local Registro = require(script.Parent:WaitForChild("RegistroDano"))

local comprar = ReplicatedStorage:FindFirstChild("ComprarItem")
if not comprar then
	comprar = Instance.new("RemoteFunction")
	comprar.Name = "ComprarItem"
	comprar.Parent = ReplicatedStorage
end

local porId = {}
for _, it in ipairs(Catalogo) do porId[it.id] = it end

local RGB = Color3.fromRGB

-- ===== Utilidades =====
local function cuerpo(plr)
	local ch = plr.Character
	return ch, ch and ch:FindFirstChildOfClass("Humanoid"), ch and ch:FindFirstChild("HumanoidRootPart")
end

local function cercaDeEstacion(plr)
	local _, _, hrp = cuerpo(plr)
	if not hrp then return false end
	for i = 1, 5 do
		local base = workspace:FindFirstChild("BaseEquipo" .. i)
		local est = base and base:FindFirstChild("EstacionArduino")
		if est and est.PrimaryPart and (est.PrimaryPart.Position - hrp.Position).Magnitude < 25 then
			return true
		end
	end
	return false
end

local function listaArmas(plr)
	local t = {}
	for id in string.gmatch(plr:GetAttribute("ArmasCompradas") or "", "[^,]+") do t[id] = true end
	return t
end

local function darTool(plr, id)
	local tpl = ServerStorage:FindFirstChild(id)
	local bp = plr:FindFirstChildOfClass("Backpack")
	if not (tpl and bp) then return end
	local ch = plr.Character
	if bp:FindFirstChild(id) or (ch and ch:FindFirstChild(id)) then return end
	tpl:Clone().Parent = bp
end

-- Las armas compradas vuelven al reaparecer
local function prepararJugador(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.7)
		for id in pairs(listaArmas(plr)) do darTool(plr, id) end
	end)
end
Players.PlayerAdded:Connect(prepararJugador)
for _, plr in ipairs(Players:GetPlayers()) do prepararJugador(plr) end

-- ===== Torreta Arduino =====
local function efecto()
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	return p
end

local function trazador(a, b, color)
	local dist = (b - a).Magnitude
	if dist < 0.1 then return end
	local p = efecto()
	p.Material = Enum.Material.Neon; p.Color = color
	p.Size = Vector3.new(0.15, 0.15, dist)
	p.CFrame = CFrame.new(a:Lerp(b, 0.5), b)
	p.Parent = workspace
	Debris:AddItem(p, 0.06)
end

local function crearTorreta(plr)
	local _, _, hrp = cuerpo(plr)
	if not hrp then return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { plr.Character }
	local frente = (hrp.CFrame * CFrame.new(0, 0, -5)).Position
	local res = workspace:Raycast(frente + Vector3.new(0, 5, 0), Vector3.new(0, -40, 0), rp)
	local suelo = res and res.Position or (hrp.Position - Vector3.new(0, 3, 0))

	local modelo = Instance.new("Model")
	modelo.Name = "Torreta_" .. plr.Name
	local function pieza(nombre, size, color, mat, cf, forma)
		local p = Instance.new("Part")
		p.Name = nombre; p.Anchored = true; p.CanCollide = false
		p.Size = size; p.Color = color; p.Material = mat
		if forma then p.Shape = forma end
		p.CFrame = cf
		p.Parent = modelo
		return p
	end
	local MET, PLA, NEO = Enum.Material.Metal, Enum.Material.SmoothPlastic, Enum.Material.Neon
	-- trípode
	for k = 0, 2 do
		local a = math.rad(k * 120)
		local pie = suelo + Vector3.new(math.cos(a) * 1.3, 0, math.sin(a) * 1.3)
		local arriba = suelo + Vector3.new(0, 2.4, 0)
		pieza("Pata" .. k, Vector3.new(0.18, 0.18, (arriba - pie).Magnitude), RGB(40, 40, 45), MET,
			CFrame.new(pie:Lerp(arriba, 0.5), arriba))
	end
	pieza("Caja", Vector3.new(1.6, 1.1, 1.6), RGB(40, 115, 205), MET, CFrame.new(suelo + Vector3.new(0, 2.9, 0)))
	pieza("Placa", Vector3.new(1.2, 0.08, 1.2), RGB(0, 129, 132), PLA, CFrame.new(suelo + Vector3.new(0, 3.49, 0)))

	local centroCabeza = suelo + Vector3.new(0, 4.1, 0)
	local cabeza = pieza("Cabeza", Vector3.new(1.2, 0.8, 1.2), RGB(30, 30, 35), MET, CFrame.new(centroCabeza))
	local canon = pieza("Canon", Vector3.new(0.35, 0.35, 2.0), RGB(25, 25, 28), MET, CFrame.new(centroCabeza))
	local ojo = pieza("Ojo", Vector3.new(0.35, 0.35, 0.35), RGB(80, 255, 120), NEO, CFrame.new(centroCabeza), Enum.PartType.Ball)
	local luz = Instance.new("PointLight"); luz.Color = RGB(80, 255, 120); luz.Range = 10; luz.Parent = ojo

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 170, 0, 30); bb.StudsOffset = Vector3.new(0, 2, 0); bb.AlwaysOnTop = true
	bb.Parent = cabeza
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1
	t.Text = "🗼 Torreta de " .. plr.DisplayName
	t.TextColor3 = RGB(140, 255, 160); t.TextStrokeTransparency = 0.3
	t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.Parent = bb

	modelo.Parent = workspace

	local function apuntar(objetivo)
		local cf = CFrame.lookAt(centroCabeza, objetivo)
		cabeza.CFrame = cf
		canon.CFrame = cf * CFrame.new(0, 0, -1.1)
		ojo.CFrame = cf * CFrame.new(0, 0.3, -0.62)
	end

	task.spawn(function()
		local fin = os.clock() + 45
		local giro = 0
		while modelo.Parent and os.clock() < fin do
			-- buscar el robot más cercano con línea de vista
			local mejor, mejorD = nil, 70
			local robots = workspace:FindFirstChild("RobotsEnemigos")
			if robots then
				local excl = { modelo, robots }
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character then table.insert(excl, p.Character) end
				end
				local vista = RaycastParams.new()
				vista.FilterType = Enum.RaycastFilterType.Exclude
				vista.FilterDescendantsInstances = excl
				for _, m in ipairs(robots:GetChildren()) do
					local hum = m:FindFirstChildOfClass("Humanoid")
					local r = m.PrimaryPart
					if hum and r and hum.Health > 0 then
						local d = (r.Position - centroCabeza).Magnitude
						if d < mejorD and not workspace:Raycast(centroCabeza, r.Position - centroCabeza, vista) then
							mejor, mejorD = m, d
						end
					end
				end
			end
			if mejor then
				local r = mejor.PrimaryPart
				apuntar(r.Position)
				local boca = (canon.CFrame * CFrame.new(0, 0, -1.05)).Position
				trazador(boca, r.Position, RGB(140, 255, 160))
				if Registro.puedeDanar(plr, mejor) then
					Registro.registrar(plr, mejor, 15)
					mejor:FindFirstChildOfClass("Humanoid"):TakeDamage(15)
				end
				task.wait(0.35)
			else
				giro += 0.15  -- vigila girando
				apuntar(centroCabeza + Vector3.new(math.cos(giro), 0, math.sin(giro)))
				task.wait(0.1)
			end
		end
		if modelo.Parent then
			local p = efecto(); p.Transparency = 1; p.CFrame = CFrame.new(centroCabeza); p.Parent = workspace
			local l = Instance.new("PointLight"); l.Color = RGB(255, 200, 120); l.Brightness = 6; l.Range = 14; l.Parent = p
			Debris:AddItem(p, 0.3)
			modelo:Destroy()
		end
	end)
end

-- ===== Comprar =====
comprar.OnServerInvoke = function(plr, id)
	local it = porId[id]
	if not it then return false, "Ese objeto no existe." end
	if not cercaDeEstacion(plr) then return false, "Acércate al robot de tu base." end
	local ch, hum = cuerpo(plr)
	if not (ch and hum and hum.Health > 0) then return false, "Primero reaparece." end

	if it.tipo == "arma" then
		if listaArmas(plr)[id] then return false, "Ya la tienes." end
	elseif it.tipo == "mejora" then
		if (plr:GetAttribute(id) or 0) >= (it.max or 1) then return false, "Ya tienes el máximo." end
	end

	if not Puntaje.gastar(plr, it.precio) then
		return false, "No te alcanzan los puntos."
	end

	if it.tipo == "arma" then
		local actuales = plr:GetAttribute("ArmasCompradas") or ""
		plr:SetAttribute("ArmasCompradas", (actuales == "" and id) or (actuales .. "," .. id))
		darTool(plr, id)
	elseif it.tipo == "mejora" then
		plr:SetAttribute(id, (plr:GetAttribute(id) or 0) + 1)  -- "Blindaje" lo lee Poderes.server
	elseif id == "Botiquin" then
		hum.Health = hum.MaxHealth
	elseif id == "Escudo" then
		local ff = Instance.new("ForceField")
		ff.Name = "EscudoTienda"
		ff.Parent = ch
		Debris:AddItem(ff, 15)
	elseif id == "Torreta" then
		crearTorreta(plr)
	end
	print("🛒", plr.Name, "compró", id, "por", it.precio)
	return true, "¡Conseguiste " .. it.nombre .. "!"
end

print("✅ Tienda lista")
