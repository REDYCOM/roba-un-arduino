--=====================================================================
--  RUNAS (cliente): muestra tus efectos activos con su tiempo
--  (encima de la barra de armas)
--=====================================================================

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RGB = Color3.fromRGB

local RUNAS = {
	{ id = "Turbo",      icono = "⚡", nombre = "Turbo",      color = RGB(255, 220, 60),  dur = 15 },
	{ id = "Sobrecarga", icono = "⚔️", nombre = "Sobrecarga", color = RGB(255, 60, 60),   dur = 15 },
	{ id = "Escudo",     icono = "🛡️", nombre = "Escudo",     color = RGB(80, 170, 255),  dur = 8 },
	{ id = "Furia",      icono = "🔥", nombre = "Furia",      color = RGB(190, 80, 255),  dur = 12 },
}

local gui = Instance.new("ScreenGui")
gui.Name = "RunasActivas"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local fila = Instance.new("Frame")
fila.AnchorPoint = Vector2.new(0.5, 1)
fila.Position = UDim2.new(0.5, 0, 1, -100)
fila.Size = UDim2.new(0, 600, 0, 40)
fila.BackgroundTransparency = 1
fila.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = fila

local fichas = {}
for i, r in ipairs(RUNAS) do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 135, 0, 38)
	f.BackgroundColor3 = RGB(15, 18, 26)
	f.BackgroundTransparency = 0.2
	f.LayoutOrder = i
	f.Visible = false
	f.Parent = fila
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = f
	local s = Instance.new("UIStroke"); s.Color = r.color; s.Thickness = 2; s.Parent = f

	local barra = Instance.new("Frame")
	barra.AnchorPoint = Vector2.new(0, 1)
	barra.Position = UDim2.new(0, 0, 1, 0)
	barra.Size = UDim2.new(1, 0, 0, 4)
	barra.BackgroundColor3 = r.color
	barra.BorderSizePixel = 0
	barra.Parent = f

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, -4)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 15
	t.TextColor3 = r.color
	t.Parent = f

	fichas[r.id] = { frame = f, barra = barra, texto = t, runa = r }
end

task.spawn(function()
	while true do
		local ahora = workspace:GetServerTimeNow()
		for id, ficha in pairs(fichas) do
			local fin = player:GetAttribute("Runa_" .. id)
			local resta = fin and (fin - ahora) or 0
			if resta > 0 then
				ficha.frame.Visible = true
				ficha.texto.Text = string.format("%s %s  %ds", ficha.runa.icono, ficha.runa.nombre, math.ceil(resta))
				ficha.barra.Size = UDim2.new(math.clamp(resta / ficha.runa.dur, 0, 1), 0, 0, 4)
			else
				ficha.frame.Visible = false
			end
		end
		task.wait(0.1)
	end
end)

print("✅ HUD de runas listo")
