--=====================================================================
--  PODERES (cliente): HUD lateral con los 10 poderes (🔒/✅)
--  + popup "¡Poder desbloqueado!" cuando ganas uno.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Poderes = require(sistema:WaitForChild("Poderes"))

local poderEvent = ReplicatedStorage:WaitForChild("PoderDesbloqueado")
local syncEvent  = ReplicatedStorage:WaitForChild("SincronizarPoderes")

local function esquina(p, r)
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, r or 8); uc.Parent = p
end

-- ===== HUD lateral =====
local gui = Instance.new("ScreenGui")
gui.Name = "HUDPoderes"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 1)
panel.Size = UDim2.new(0, 210, 0, 30 + 10 * 30)
panel.Position = UDim2.new(1, -10, 1, -10)  -- esquina inferior derecha
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
panel.BackgroundTransparency = 0.15
panel.Parent = gui
esquina(panel, 12)

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 28)
titulo.BackgroundTransparency = 1
titulo.Text = "⚡ PODERES"
titulo.TextColor3 = Color3.fromRGB(255, 235, 130)
titulo.Font = Enum.Font.FredokaOne
titulo.TextSize = 18
titulo.Parent = panel

local filas = {}  -- [n] = {frame, label}

for n = 1, 10 do
	local reto = Poderes[n]
	local fila = Instance.new("Frame")
	fila.Size = UDim2.new(1, -12, 0, 26)
	fila.Position = UDim2.new(0, 6, 0, 30 + (n - 1) * 30)
	fila.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
	fila.BackgroundTransparency = 0.3
	fila.Parent = panel
	esquina(fila, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = "🔒 " .. reto.icono .. " " .. reto.nombre
	lbl.TextColor3 = Color3.fromRGB(140, 145, 155)  -- gris = bloqueado
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14
	lbl.Parent = fila

	filas[n] = { frame = fila, label = lbl }
end

local function desbloquearFila(n)
	local f = filas[n]
	if not f then return end
	local p = Poderes[n]
	f.label.Text = "✅ " .. p.icono .. " " .. p.nombre
	f.label.TextColor3 = Color3.fromRGB(120, 255, 160)
	f.frame.BackgroundColor3 = Color3.fromRGB(30, 60, 45)
end

-- ===== Popup llamativo =====
local function mostrarPopup(n)
	local p = Poderes[n]

	-- capa propia SIEMPRE al frente (encima de la ventana de programación)
	local capa = Instance.new("ScreenGui")
	capa.Name = "PopupPoder"
	capa.ResetOnSpawn = false
	capa.IgnoreGuiInset = true
	capa.DisplayOrder = 100
	capa.Parent = playerGui

	-- destello de pantalla
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.35
	flash.ZIndex = 40
	flash.Parent = capa
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.delay(0.6, function() flash:Destroy() end)

	local pop = Instance.new("Frame")
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Size = UDim2.new(0, 520, 0, 210)
	pop.Position = UDim2.new(0.5, 0, 0.4, 0)
	pop.BackgroundColor3 = Color3.fromRGB(24, 70, 48)
	pop.ZIndex = 41
	pop.Parent = capa
	esquina(pop, 20)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(30, 100, 70), Color3.fromRGB(16, 42, 58))
	grad.Rotation = 90
	grad.Parent = pop

	local borde = Instance.new("UIStroke")
	borde.Color = Color3.fromRGB(255, 220, 90)
	borde.Thickness = 4
	borde.Parent = pop

	local escala = Instance.new("UIScale")
	escala.Scale = 0
	escala.Parent = pop

	local icono = Instance.new("TextLabel")
	icono.Size = UDim2.new(0, 120, 0, 120)
	icono.Position = UDim2.new(0, 15, 0.5, -60)
	icono.BackgroundTransparency = 1
	icono.Text = p.icono
	icono.TextSize = 92
	icono.ZIndex = 42
	icono.Parent = pop

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, -150, 0, 34)
	t1.Position = UDim2.new(0, 140, 0, 26)
	t1.BackgroundTransparency = 1
	t1.Text = "⭐ ¡PODER DESBLOQUEADO! ⭐"
	t1.TextXAlignment = Enum.TextXAlignment.Left
	t1.TextColor3 = Color3.fromRGB(255, 235, 130)
	t1.Font = Enum.Font.FredokaOne
	t1.TextSize = 22
	t1.ZIndex = 42
	t1.Parent = pop

	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, -150, 0, 44)
	t2.Position = UDim2.new(0, 140, 0, 66)
	t2.BackgroundTransparency = 1
	t2.Text = p.nombre
	t2.TextXAlignment = Enum.TextXAlignment.Left
	t2.TextColor3 = Color3.fromRGB(255, 255, 255)
	t2.Font = Enum.Font.FredokaOne
	t2.TextSize = 34
	t2.ZIndex = 42
	t2.Parent = pop

	local t3 = Instance.new("TextLabel")
	t3.Size = UDim2.new(1, -150, 0, 50)
	t3.Position = UDim2.new(0, 140, 0, 120)
	t3.BackgroundTransparency = 1
	t3.Text = p.desc
	t3.TextXAlignment = Enum.TextXAlignment.Left
	t3.TextYAlignment = Enum.TextYAlignment.Top
	t3.TextWrapped = true
	t3.TextColor3 = Color3.fromRGB(215, 235, 225)
	t3.Font = Enum.Font.GothamBold
	t3.TextSize = 16
	t3.ZIndex = 42
	t3.Parent = pop

	-- pop-in con rebote + borde pulsante
	TweenService:Create(escala, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local pulso = TweenService:Create(
		borde,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Thickness = 9 }
	)
	pulso:Play()

	task.delay(3.5, function()
		pulso:Cancel()
		local salir = TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		salir:Play()
		salir.Completed:Wait()
		capa:Destroy()
	end)
end

poderEvent.OnClientEvent:Connect(function(n)
	desbloquearFila(n)
	mostrarPopup(n)
end)

syncEvent.OnClientEvent:Connect(function(lista)
	for _, n in ipairs(lista) do
		desbloquearFila(n)
	end
end)

print("✅ HUD de Poderes listo")
