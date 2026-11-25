--=====================================================================
--  REGISTRO DE DAÑO (ModuleScript)
--  Todas las armas lo usan antes de dañar a un robot:
--    puedeDanar(plr, modelo) -> en la gran final, solo los 2 equipos
--                               finalistas (y el profe) pueden dañar al jefe
--    registrar(plr, modelo, dano) -> anota quién le pegó (para los puntos)
--                               y suma el daño de cada equipo al jefe final
--=====================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OWNER_USERID = 9330695994

local M = {}

local function esGM(plr)
	return plr.UserId == OWNER_USERID or plr:GetAttribute("IsGameMaster") == true
end

local function estado()
	return ReplicatedStorage:FindFirstChild("EstadoRobots")
end

-- "A" o "B" si el jugador es de un equipo finalista; nil si no
function M.ladoFinal(plr)
	local est = estado()
	local eq = plr:GetAttribute("TeamNumber")
	if not (est and eq) then return nil end
	if eq == est:GetAttribute("FinalA") then return "A" end
	if eq == est:GetAttribute("FinalB") then return "B" end
	return nil
end

function M.puedeDanar(plr, modelo)
	if modelo and modelo:GetAttribute("JefeFinal") then
		return esGM(plr) or M.ladoFinal(plr) ~= nil
	end
	return true
end

-- ===== ELIMINACIONES (jugador contra jugador) =====
-- Las armas llaman a esto antes de dañar a un JUGADOR. Si muere en los
-- siguientes segundos, el script Eliminaciones le da los puntos al atacante.
function M.marcarJugador(atacante, humVictima)
	if not (atacante and humVictima) then return end
	humVictima:SetAttribute("UltimoAtacanteJugador", atacante.UserId)
	humVictima:SetAttribute("UltimoAtacanteT", os.clock())
end

-- ===== AMENAZA (para la IA de los jefes) =====
-- Cada jefe recuerda cuánto daño le hizo cada jugador. La memoria se va
-- "enfriando": el daño de hace 8 s vale la mitad. Así el jefe persigue a
-- quien le está pegando MÁS y AHORA, no a quien le pegó hace un minuto.
local VIDA_MEDIA = 8
local amenazas = setmetatable({}, { __mode = "k" }) -- [modelo] = { [plr] = { v, t } }

local function enfriar(e, ahora)
	e.v *= 0.5 ^ ((ahora - e.t) / VIDA_MEDIA)
	e.t = ahora
end

-- devuelve { [plr] = amenaza actual } de ese jefe
function M.amenazas(modelo)
	local res = {}
	local t = amenazas[modelo]
	if not t then return res end
	local ahora = os.clock()
	for plr, e in pairs(t) do
		if plr.Parent then
			enfriar(e, ahora)
			res[plr] = e.v
		else
			t[plr] = nil -- se fue del juego
		end
	end
	return res
end

function M.registrar(plr, modelo, dano)
	if not modelo then return end
	modelo:SetAttribute("UltimoAtacante", plr.UserId)
	if modelo:GetAttribute("EsJefe") then
		local t = amenazas[modelo]
		if not t then t = {}; amenazas[modelo] = t end
		local ahora = os.clock()
		local e = t[plr]
		if not e then e = { v = 0, t = ahora }; t[plr] = e end
		enfriar(e, ahora)
		e.v += dano
	end
	if modelo:GetAttribute("JefeFinal") then
		local lado = M.ladoFinal(plr)
		local est = estado()
		if lado and est then
			local k = "Dano" .. lado
			est:SetAttribute(k, (est:GetAttribute(k) or 0) + math.floor(dano + 0.5))
		end
	end
end

return M
