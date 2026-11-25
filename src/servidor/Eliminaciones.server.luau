--=====================================================================
--  ELIMINACIONES (servidor)
--  Si eliminas a un jugador de OTRO equipo ganas pocos puntos (8): vale
--  menos que destruir un robot o llevar un componente a tu base.
--  Avisa a todos en la lista de eliminaciones (arriba a la izquierda).
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Puntaje = require(script.Parent:WaitForChild("Puntaje"))

local VENTANA = 10 -- segundos: si murió hasta 10 s después de tu golpe, la eliminación es tuya

local feed = ReplicatedStorage:FindFirstChild("Eliminacion")
if not feed then
	feed = Instance.new("RemoteEvent"); feed.Name = "Eliminacion"; feed.Parent = ReplicatedStorage
end

local function enganchar(plr)
	local function alPersonaje(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		hum.Died:Connect(function()
			local id = hum:GetAttribute("UltimoAtacanteJugador")
			local t = hum:GetAttribute("UltimoAtacanteT")
			if not (id and t) or os.clock() - t > VENTANA then return end
			local asesino = Players:GetPlayerByUserId(id)
			if not asesino or asesino == plr then return end
			local eqA, eqV = asesino:GetAttribute("TeamNumber"), plr:GetAttribute("TeamNumber")
			if eqA and eqV and eqA == eqV then return end -- mismo equipo: no cuenta
			Puntaje.sumar(asesino, Puntaje.PUNTOS_ELIMINACION)
			feed:FireAllClients(asesino.Name, eqA or 0, plr.Name, eqV or 0, Puntaje.PUNTOS_ELIMINACION)
		end)
	end
	if plr.Character then task.spawn(alPersonaje, plr.Character) end
	plr.CharacterAdded:Connect(alPersonaje)
end

for _, plr in ipairs(Players:GetPlayers()) do enganchar(plr) end
Players.PlayerAdded:Connect(enganchar)

print("✅ Eliminaciones: +" .. Puntaje.PUNTOS_ELIMINACION .. " pts por jugador enemigo")
