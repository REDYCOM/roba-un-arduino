--=====================================================================
--  ESTADO DEL LOBBY (cliente) - "modo clase"
--  - Alumnos: mientras el profe no entra, cartel "⏳ Esperando al profe…"
--    (y se oculta el viejo "Tiempo restante: 180s", que estaría congelado).
--  - Profe: durante la cuenta, cartel con los segundos y la tecla [N].
--  Lo controla TeamSystem con workspace:GetAttribute("EstadoLobby"):
--    "esperando" → falta el profe · "cuenta" → corre el reloj · "jugando"
--=====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local OWNER_USERID = 9330695994

local function esGM()
	return player.UserId == OWNER_USERID or player:GetAttribute("IsGameMaster") == true
end

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyEstado"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local caja = Instance.new("Frame")
caja.AnchorPoint = Vector2.new(0.5, 0)
caja.Position = UDim2.new(0.5, 0, 0, 70)
caja.Size = UDim2.new(0, 460, 0, 78)
caja.BackgroundColor3 = Color3.fromRGB(18, 16, 34)
caja.BackgroundTransparency = 0.15
caja.Visible = false
caja.Parent = gui
Instance.new("UICorner", caja).CornerRadius = UDim.new(0, 14)
local borde = Instance.new("UIStroke")
borde.Thickness = 2
borde.Color = Color3.fromRGB(255, 200, 90)
borde.Parent = caja

local titulo = Instance.new("TextLabel")
titulo.BackgroundTransparency = 1
titulo.Position = UDim2.new(0, 12, 0, 6)
titulo.Size = UDim2.new(1, -24, 0, 36)
titulo.Font = Enum.Font.FredokaOne
titulo.TextScaled = true
titulo.TextColor3 = Color3.fromRGB(255, 220, 120)
titulo.Parent = caja

local sub = Instance.new("TextLabel")
sub.BackgroundTransparency = 1
sub.Position = UDim2.new(0, 12, 0, 44)
sub.Size = UDim2.new(1, -24, 0, 24)
sub.Font = Enum.Font.GothamBold
sub.TextScaled = true
sub.TextColor3 = Color3.fromRGB(225, 225, 240)
sub.Parent = caja

-- latido suave del borde para que se note que está "vivo"
local latido = TweenService:Create(
	borde,
	TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Transparency = 0.7 }
)
latido:Play()

local puntos = 0
local function actualizar()
	local estado = workspace:GetAttribute("EstadoLobby")
	local viejo = player.PlayerGui:FindFirstChild("GameStartNotification")

	if estado == "esperando" and not esGM() then
		puntos = puntos % 3 + 1
		caja.Visible = true
		titulo.Text = "⏳ Esperando al profe" .. string.rep(".", puntos)
		sub.Text = player:GetAttribute("TeamNumber") and "¡Ya tienes equipo! Prepárate en tu base 🛡️"
			or "Elige tu equipo mientras tanto"
		if game:GetService("RunService"):IsStudio() then
			sub.Text = "🧪 Prueba en Studio: pulsa [N] para empezar"
		end
		if viejo and viejo:IsA("ScreenGui") then viejo.Enabled = false end
	elseif estado == "cuenta" and esGM() then
		local s = workspace:GetAttribute("LobbyRestante") or 0
		caja.Visible = true
		titulo.Text = string.format("👑 Lobby: %d:%02d para abrir las rejas", s // 60, s % 60)
		sub.Text = "Pulsa [N] para empezar YA (en 5 segundos)"
	else
		caja.Visible = false
		if viejo and viejo:IsA("ScreenGui") then viejo.Enabled = true end
		if estado == "jugando" then
			latido:Cancel()
			gui:Destroy()
			return false
		end
	end
	return true
end

task.spawn(function()
	while actualizar() do
		task.wait(0.5)
	end
end)
