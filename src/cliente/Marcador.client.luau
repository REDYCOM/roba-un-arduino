--=====================================================================
--  MARCADOR POR EQUIPOS (cliente)
--  Mantén presionado [Tab]: aparece una tabla grande y transparente con
--  el puntaje de cada equipo (ordenado). Al soltar, desaparece.
--  Reemplaza la lista de jugadores normal de Roblox.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local puntaje = ReplicatedStorage:WaitForChild("PuntajeEquipos")

local RGB = Color3.fromRGB
local EQUIPOS = {
	{ nombre = "Rojo",    color = RGB(220, 40, 40) },
	{ nombre = "Azul",    color = RGB(30, 130, 255) },
	{ nombre = "Verde",   color = RGB(30, 200, 60) },
	{ nombre = "Naranja", color = RGB(255, 160, 0) },
	{ nombre = "Morado",  color = RGB(150, 60, 235) },
}
local MEDALLAS = { "🥇", "🥈", "🥉", "4°", "5°" }

-- Ocultar la lista de jugadores normal (la reemplaza esta tabla)
task.spawn(function()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		if ok then break end
		task.wait(0.5)
	end
end)

local function esquina(p, r)
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, r or 8); uc.Parent = p
end

local gui = Instance.new("ScreenGui")
gui.Name = "MarcadorEquipos"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui

-- Pista permanente
local pista = Instance.new("TextLabel")
pista.Position = UDim2.new(0, 12, 0, 60)
pista.Size = UDim2.new(0, 220, 0, 24)
pista.BackgroundColor3 = RGB(20, 24, 32)
pista.BackgroundTransparency = 0.35
pista.Font = Enum.Font.GothamBold
pista.TextSize = 13
pista.TextColor3 = RGB(220, 230, 255)
pista.Text = "📊 Mantén [Tab]: puntuación"
pista.Parent = gui
esquina(pista, 6)

-- Panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 720, 0, 480)
panel.BackgroundColor3 = RGB(10, 14, 22)
panel.BackgroundTransparency = 0.35
panel.Visible = false
panel.Parent = gui
esquina(panel, 18)
local trazo = Instance.new("UIStroke"); trazo.Color = RGB(255, 210, 90); trazo.Thickness = 2; trazo.Transparency = 0.3; trazo.Parent = panel
local escala = Instance.new("UIScale"); escala.Parent = panel

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 50)
titulo.Position = UDim2.new(0, 0, 0, 8)
titulo.BackgroundTransparency = 1
titulo.Font = Enum.Font.FredokaOne
titulo.TextSize = 30
titulo.TextColor3 = RGB(255, 220, 90)
titulo.TextStrokeTransparency = 0.4
titulo.Text = "🏆 PUNTUACIÓN POR EQUIPOS"
titulo.Parent = panel

local lista = Instance.new("Frame")
lista.Position = UDim2.new(0, 20, 0, 64)
lista.Size = UDim2.new(1, -40, 0, 370)
lista.BackgroundTransparency = 1
lista.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = lista

local pie = Instance.new("TextLabel")
pie.Position = UDim2.new(0, 0, 1, -40)
pie.Size = UDim2.new(1, 0, 0, 30)
pie.BackgroundTransparency = 1
pie.Font = Enum.Font.GothamBold
pie.TextSize = 16
pie.TextColor3 = RGB(220, 230, 255)
pie.Parent = panel

-- Filas (una por equipo)
local filas = {}
for i, eq in ipairs(EQUIPOS) do
	local fila = Instance.new("Frame")
	fila.Size = UDim2.new(1, 0, 0, 66)
	fila.BackgroundColor3 = RGB(25, 30, 42)
	fila.BackgroundTransparency = 0.3
	fila.Parent = lista
	esquina(fila, 12)
	local marco = Instance.new("UIStroke"); marco.Color = eq.color; marco.Thickness = 0; marco.Parent = fila

	local medalla = Instance.new("TextLabel")
	medalla.Size = UDim2.new(0, 56, 1, 0)
	medalla.BackgroundTransparency = 1
	medalla.Font = Enum.Font.FredokaOne
	medalla.TextSize = 30
	medalla.TextColor3 = RGB(255, 255, 255)
	medalla.Parent = fila

	local barra = Instance.new("Frame")
	barra.Position = UDim2.new(0, 56, 0, 10)
	barra.Size = UDim2.new(0, 8, 1, -20)
	barra.BackgroundColor3 = eq.color
	barra.Parent = fila
	esquina(barra, 4)

	local nombre = Instance.new("TextLabel")
	nombre.Position = UDim2.new(0, 76, 0, 6)
	nombre.Size = UDim2.new(0, 380, 0, 30)
	nombre.BackgroundTransparency = 1
	nombre.Font = Enum.Font.FredokaOne
	nombre.TextSize = 24
	nombre.TextXAlignment = Enum.TextXAlignment.Left
	nombre.TextColor3 = eq.color
	nombre.Text = "Equipo " .. eq.nombre
	nombre.Parent = fila

	local miembros = Instance.new("TextLabel")
	miembros.Position = UDim2.new(0, 76, 0, 36)
	miembros.Size = UDim2.new(0, 400, 0, 22)
	miembros.BackgroundTransparency = 1
	miembros.Font = Enum.Font.Gotham
	miembros.TextSize = 13
	miembros.TextXAlignment = Enum.TextXAlignment.Left
	miembros.TextTruncate = Enum.TextTruncate.AtEnd
	miembros.TextColor3 = RGB(200, 210, 225)
	miembros.Parent = fila

	local total = Instance.new("TextLabel")
	total.AnchorPoint = Vector2.new(1, 0)
	total.Position = UDim2.new(1, -16, 0, 4)
	total.Size = UDim2.new(0, 180, 0, 36)
	total.BackgroundTransparency = 1
	total.Font = Enum.Font.FredokaOne
	total.TextSize = 32
	total.TextXAlignment = Enum.TextXAlignment.Right
	total.TextColor3 = RGB(255, 255, 255)
	total.Parent = fila

	local detalle = Instance.new("TextLabel")
	detalle.AnchorPoint = Vector2.new(1, 0)
	detalle.Position = UDim2.new(1, -16, 0, 40)
	detalle.Size = UDim2.new(0, 220, 0, 20)
	detalle.BackgroundTransparency = 1
	detalle.Font = Enum.Font.Gotham
	detalle.TextSize = 13
	detalle.TextXAlignment = Enum.TextXAlignment.Right
	detalle.TextColor3 = RGB(200, 210, 225)
	detalle.Parent = fila

	filas[i] = { fila = fila, marco = marco, medalla = medalla, miembros = miembros, total = total, detalle = detalle }
end

local function puntosDe(plr)
	local ls = plr:FindFirstChild("leaderstats")
	local p = ls and ls:FindFirstChild("Puntos")
	return p and p.Value or 0
end

local function actualizar()
	local porComp = puntaje:GetAttribute("PorComponente") or 20
	local datos = {}
	for i = 1, #EQUIPOS do
		local pts = puntaje:GetAttribute("Puntos" .. i) or 0
		local comp = puntaje:GetAttribute("Componentes" .. i) or 0
		table.insert(datos, { i = i, pts = pts, comp = comp, total = pts + comp * porComp })
	end
	table.sort(datos, function(a, b)
		if a.total == b.total then return a.i < b.i end
		return a.total > b.total
	end)

	local miEquipo = player:GetAttribute("TeamNumber")
	for rango, d in ipairs(datos) do
		local f = filas[d.i]
		f.fila.LayoutOrder = rango
		f.medalla.Text = MEDALLAS[rango]
		f.total.Text = tostring(d.total)
		f.detalle.Text = string.format("⚔️ %d pts  ·  📦 %d × %d", d.pts, d.comp, porComp)

		local nombres = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr:GetAttribute("TeamNumber") == d.i then
				table.insert(nombres, { n = plr.DisplayName, p = puntosDe(plr) })
			end
		end
		table.sort(nombres, function(a, b) return a.p > b.p end)
		local partes = {}
		for _, x in ipairs(nombres) do table.insert(partes, x.n .. " " .. x.p) end
		f.miembros.Text = #partes > 0 and table.concat(partes, "  ·  ") or "(sin jugadores)"

		f.marco.Thickness = (miEquipo == d.i) and 3 or 0  -- resalta TU equipo
	end

	local eqTxt = (type(miEquipo) == "number" and EQUIPOS[miEquipo]) and ("Equipo " .. EQUIPOS[miEquipo].nombre) or "sin equipo"
	pie.Text = string.format("Tus puntos: %d   ·   %s", puntosDe(player), eqTxt)
end

for i = 1, #EQUIPOS do
	puntaje:GetAttributeChangedSignal("Puntos" .. i):Connect(function() if panel.Visible then actualizar() end end)
	puntaje:GetAttributeChangedSignal("Componentes" .. i):Connect(function() if panel.Visible then actualizar() end end)
end

local function mostrar(si)
	if si then
		actualizar()
		panel.Visible = true
		escala.Scale = 0.92
		TweenService:Create(escala, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		panel.Visible = false
	end
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab and not UserInputService:GetFocusedTextBox() then
		mostrar(true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then mostrar(false) end
end)

-- refresco mientras está abierto (por los puntos individuales)
task.spawn(function()
	while true do
		task.wait(1)
		if panel.Visible then actualizar() end
	end
end)

print("✅ Marcador por equipos listo ([Tab])")
