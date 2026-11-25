--=====================================================================
--  TIENDA (cliente) — se abre con [T] en el robot de tu base
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Catalogo = require(sistema:WaitForChild("Catalogo"))
local abrirEvent = ReplicatedStorage:WaitForChild("AbrirTienda")
local comprar = ReplicatedStorage:WaitForChild("ComprarItem")

local RGB = Color3.fromRGB
local function esquina(p, r)
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, r or 8); uc.Parent = p
end

local function misPuntos()
	local ls = player:FindFirstChild("leaderstats")
	local p = ls and ls:FindFirstChild("Puntos")
	return p and p.Value or 0, p
end

local function laTengo(it)
	if it.tipo == "arma" then
		for id in string.gmatch(player:GetAttribute("ArmasCompradas") or "", "[^,]+") do
			if id == it.id then return true end
		end
	elseif it.tipo == "mejora" then
		return (player:GetAttribute(it.id) or 0) >= (it.max or 1)
	end
	return false
end

local abierta = nil

local function abrir()
	if abierta then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "Tienda"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30
	gui.Parent = playerGui
	abierta = gui

	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.new(1, 0, 1, 0)
	fondo.BackgroundColor3 = RGB(0, 0, 0)
	fondo.BackgroundTransparency = 0.5
	fondo.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0, 780, 0, 540)
	panel.BackgroundColor3 = RGB(24, 30, 42)
	panel.Parent = fondo
	esquina(panel, 20)
	local trazo = Instance.new("UIStroke"); trazo.Color = RGB(255, 210, 90); trazo.Thickness = 2; trazo.Parent = panel
	local escala = Instance.new("UIScale"); escala.Scale = 0.8; escala.Parent = panel
	TweenService:Create(escala, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local titulo = Instance.new("TextLabel")
	titulo.Position = UDim2.new(0, 24, 0, 14)
	titulo.Size = UDim2.new(0, 500, 0, 40)
	titulo.BackgroundTransparency = 1
	titulo.Font = Enum.Font.FredokaOne
	titulo.TextSize = 30
	titulo.TextXAlignment = Enum.TextXAlignment.Left
	titulo.TextColor3 = RGB(255, 220, 90)
	titulo.Text = "🛒 TIENDA DEL ROBOT"
	titulo.Parent = panel

	local saldo = Instance.new("TextLabel")
	saldo.AnchorPoint = Vector2.new(1, 0)
	saldo.Position = UDim2.new(1, -76, 0, 18)
	saldo.Size = UDim2.new(0, 220, 0, 34)
	saldo.BackgroundColor3 = RGB(40, 50, 30)
	saldo.Font = Enum.Font.FredokaOne
	saldo.TextSize = 20
	saldo.TextColor3 = RGB(255, 230, 120)
	saldo.Parent = panel
	esquina(saldo, 10)

	local cerrarBtn = Instance.new("TextButton")
	cerrarBtn.AnchorPoint = Vector2.new(1, 0)
	cerrarBtn.Position = UDim2.new(1, -16, 0, 14)
	cerrarBtn.Size = UDim2.new(0, 44, 0, 44)
	cerrarBtn.BackgroundColor3 = RGB(200, 60, 60)
	cerrarBtn.Text = "✕"
	cerrarBtn.TextColor3 = RGB(255, 255, 255)
	cerrarBtn.Font = Enum.Font.GothamBold
	cerrarBtn.TextSize = 22
	cerrarBtn.Modal = true  -- libera el mouse aunque tengas un arma
	cerrarBtn.Parent = panel
	esquina(cerrarBtn, 10)

	local aviso = Instance.new("TextLabel")
	aviso.Position = UDim2.new(0, 24, 1, -42)
	aviso.Size = UDim2.new(1, -48, 0, 30)
	aviso.BackgroundTransparency = 1
	aviso.Font = Enum.Font.GothamBold
	aviso.TextSize = 16
	aviso.TextColor3 = RGB(200, 210, 225)
	aviso.Text = "Gastar puntos no baja el puntaje de tu equipo."
	aviso.Parent = panel

	local grilla = Instance.new("ScrollingFrame")
	grilla.Position = UDim2.new(0, 20, 0, 66)
	grilla.Size = UDim2.new(1, -40, 1, -116)
	grilla.BackgroundTransparency = 1
	grilla.BorderSizePixel = 0
	grilla.ScrollBarThickness = 6
	grilla.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grilla.CanvasSize = UDim2.new(0, 0, 0, 0)
	grilla.Parent = panel
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.new(0, 236, 0, 150)
	gl.CellPadding = UDim2.new(0, 10, 0, 10)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grilla

	local tarjetas = {}
	local ocupado = false

	local function refrescar()
		local puntos = misPuntos()
		saldo.Text = "💰 " .. puntos .. " puntos"
		for _, tj in ipairs(tarjetas) do
			local it = tj.item
			if laTengo(it) then
				tj.boton.Text = (it.tipo == "mejora") and "MÁXIMO" or "✅ YA LA TIENES"
				tj.boton.BackgroundColor3 = RGB(70, 80, 95)
			else
				local extra = ""
				if it.tipo == "mejora" then
					extra = string.format("  (%d/%d)", player:GetAttribute(it.id) or 0, it.max or 1)
				end
				tj.boton.Text = "💰 " .. it.precio .. extra
				tj.boton.BackgroundColor3 = (puntos >= it.precio) and RGB(46, 170, 100) or RGB(110, 60, 60)
			end
		end
	end

	for i, it in ipairs(Catalogo) do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = RGB(34, 42, 58)
		card.LayoutOrder = i
		card.Parent = grilla
		esquina(card, 14)

		local icono = Instance.new("TextLabel")
		icono.Size = UDim2.new(0, 50, 0, 50)
		icono.Position = UDim2.new(0, 10, 0, 8)
		icono.BackgroundTransparency = 1
		icono.Text = it.icono
		icono.TextSize = 38
		icono.Parent = card

		local nombre = Instance.new("TextLabel")
		nombre.Position = UDim2.new(0, 64, 0, 10)
		nombre.Size = UDim2.new(1, -72, 0, 44)
		nombre.BackgroundTransparency = 1
		nombre.Font = Enum.Font.FredokaOne
		nombre.TextSize = 18
		nombre.TextWrapped = true
		nombre.TextXAlignment = Enum.TextXAlignment.Left
		nombre.TextColor3 = RGB(255, 255, 255)
		nombre.Text = it.nombre
		nombre.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.new(0, 12, 0, 58)
		desc.Size = UDim2.new(1, -24, 0, 44)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 13
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextColor3 = RGB(190, 200, 215)
		desc.Text = it.desc
		desc.Parent = card

		local boton = Instance.new("TextButton")
		boton.AnchorPoint = Vector2.new(0.5, 1)
		boton.Position = UDim2.new(0.5, 0, 1, -8)
		boton.Size = UDim2.new(1, -20, 0, 34)
		boton.Font = Enum.Font.FredokaOne
		boton.TextSize = 17
		boton.TextColor3 = RGB(255, 255, 255)
		boton.Modal = true
		boton.Parent = card
		esquina(boton, 10)

		boton.MouseButton1Click:Connect(function()
			if ocupado or laTengo(it) then return end
			ocupado = true
			local ok, msg = comprar:InvokeServer(it.id)
			ocupado = false
			if not gui.Parent then return end
			aviso.Text = msg or ""
			aviso.TextColor3 = ok and RGB(120, 255, 150) or RGB(255, 130, 110)
			if ok then
				card.BackgroundColor3 = RGB(60, 110, 70)
				TweenService:Create(card, TweenInfo.new(0.5), { BackgroundColor3 = RGB(34, 42, 58) }):Play()
			end
			refrescar()
		end)

		table.insert(tarjetas, { item = it, boton = boton })
	end
	refrescar()

	local _, valor = misPuntos()
	local conns = {}
	if valor then table.insert(conns, valor.Changed:Connect(refrescar)) end

	local function cerrar()
		for _, c in ipairs(conns) do c:Disconnect() end
		abierta = nil
		gui:Destroy()
	end
	cerrarBtn.MouseButton1Click:Connect(cerrar)

	-- se cierra sola si te alejas del robot
	local function posEstacion()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local mejor, mejorD = nil, math.huge
		for i = 1, 5 do
			local base = workspace:FindFirstChild("BaseEquipo" .. i)
			local est = base and base:FindFirstChild("EstacionArduino")
			if est and est.PrimaryPart then
				local d = (est.PrimaryPart.Position - hrp.Position).Magnitude
				if d < mejorD then mejor, mejorD = est.PrimaryPart.Position, d end
			end
		end
		return mejor
	end
	local estPos = posEstacion()
	task.spawn(function()
		while gui.Parent do
			task.wait(0.5)
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not gui.Parent then break end
			if estPos and hrp and (hrp.Position - estPos).Magnitude > 22 then
				cerrar()
				break
			end
		end
	end)
end

abrirEvent.OnClientEvent:Connect(abrir)

print("✅ Tienda (cliente) lista")
