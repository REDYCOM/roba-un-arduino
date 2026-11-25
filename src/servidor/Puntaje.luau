--=====================================================================
--  PUNTAJE (ModuleScript) — puntos personales + puntos por EQUIPO
--  Todo lo que da puntos (retos, robots) debe llamar a Puntaje.sumar().
--  El puntaje total de un equipo =
--      puntos ganados por sus jugadores + componentes en su base × PUNTOS_POR_COMPONENTE
--  Los totales viven como atributos en ReplicatedStorage > PuntajeEquipos.
--
--  TABLA DE PUNTOS DEL JUEGO (de más a menos valioso):
--    🔌 Llevar un componente a tu base ....... 100  (si te lo roban, tu equipo lo pierde)
--    🤖 Destruir robots ........................ 10 a 80  (jefe 150)
--    🧩 Resolver retos de programación ......... 10 a 60  (+ un poder)
--    ⚔️ Eliminar a un jugador de otro equipo ...  8
--=====================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NUM_EQUIPOS = 5
local PUNTOS_POR_COMPONENTE = 100 -- cada componente en tu base (¡lo que más vale!)
local PUNTOS_ELIMINACION = 8      -- eliminar a un jugador enemigo (menos que un robot)

local M = {}
M.PUNTOS_POR_COMPONENTE = PUNTOS_POR_COMPONENTE
M.PUNTOS_ELIMINACION = PUNTOS_ELIMINACION

local carpeta = ReplicatedStorage:FindFirstChild("PuntajeEquipos")
if not carpeta then
	carpeta = Instance.new("Folder")
	carpeta.Name = "PuntajeEquipos"
	carpeta.Parent = ReplicatedStorage
end
carpeta:SetAttribute("PorComponente", PUNTOS_POR_COMPONENTE)
carpeta:SetAttribute("PorEliminacion", PUNTOS_ELIMINACION)
carpeta:SetAttribute("NumEquipos", NUM_EQUIPOS)
for i = 1, NUM_EQUIPOS do
	if carpeta:GetAttribute("Puntos" .. i) == nil then carpeta:SetAttribute("Puntos" .. i, 0) end
	if carpeta:GetAttribute("Componentes" .. i) == nil then carpeta:SetAttribute("Componentes" .. i, 0) end
end

local function statsDe(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	end
	local p = ls:FindFirstChild("Puntos")
	if not p then
		p = Instance.new("IntValue"); p.Name = "Puntos"; p.Value = 0; p.Parent = ls
	end
	return p
end

-- Suma puntos al jugador y a su equipo (si tiene)
function M.sumar(plr, n)
	if not plr or not plr.Parent or n == 0 then return end
	local p = statsDe(plr)
	p.Value += n
	local eq = plr:GetAttribute("TeamNumber")
	if type(eq) == "number" and eq >= 1 and eq <= NUM_EQUIPOS then
		carpeta:SetAttribute("Puntos" .. eq, (carpeta:GetAttribute("Puntos" .. eq) or 0) + n)
	end
end

-- Solo puntos personales (para gastar en la tienda). El equipo ya los cuenta por otro lado.
function M.sumarPersonal(plr, n)
	if not plr or not plr.Parent or n == 0 then return end
	statsDe(plr).Value += n
end

-- Gasta puntos personales en la tienda (NO baja el puntaje del equipo).
-- Devuelve true si le alcanzaba.
function M.gastar(plr, n)
	local p = statsDe(plr)
	if p.Value < n then return false end
	p.Value -= n
	return true
end

local function avisar(plr, texto, color)
	local ev = ReplicatedStorage:FindFirstChild("AnuncioRobots")
	if ev and plr then ev:FireClient(plr, texto, color, 2.5) end
end

-- quien entregó: el jugador del equipo más cerca de su base
local function entregadorDe(eq)
	local base = workspace:FindFirstChild("BaseEquipo" .. eq)
	local centro = base and base.PrimaryPart and base.PrimaryPart.Position
	if not centro then return nil end
	local mejor, mejorD = nil, 35
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr:GetAttribute("TeamNumber") == eq and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - centro).Magnitude < mejorD then
				mejor, mejorD = plr, (hrp.Position - centro).Magnitude
			end
		end
	end
	return mejor
end

-- Copia cuántos componentes tiene cada base (lo lleva tu BaseDetector)
-- y premia/avisa cuando sube o baja
task.spawn(function()
	while true do
		for i = 1, NUM_EQUIPOS do
			local base = workspace:FindFirstChild("BaseEquipo" .. i)
			local c = (base and base:GetAttribute("ObjectCount")) or 0
			local antes = carpeta:GetAttribute("Componentes" .. i) or 0
			if antes ~= c then
				carpeta:SetAttribute("Componentes" .. i, c)
				if c > antes then
					-- ¡entrega! el que lo trajo gana también puntos para la tienda
					local quien = entregadorDe(i)
					if quien then
						M.sumarPersonal(quien, PUNTOS_POR_COMPONENTE * (c - antes))
						avisar(quien, "🔌 ¡COMPONENTE ENTREGADO! +" .. PUNTOS_POR_COMPONENTE * (c - antes) .. " para tu equipo",
							Color3.fromRGB(90, 255, 200))
					end
				else
					-- les robaron: avisar a todo el equipo
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr:GetAttribute("TeamNumber") == i then
							avisar(plr, "🚨 ¡TE ROBARON UN COMPONENTE! −" .. PUNTOS_POR_COMPONENTE * (antes - c) .. " ¡Defiende tu base!",
								Color3.fromRGB(255, 90, 80))
						end
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

return M
