--=====================================================================
--  ESTACIÓN ARDUINO (cliente)
--  Ventana estilo ArduinoBlocks con dos secciones:
--    🔧 Inicializar (bloques fijos, de contexto)
--    🔁 Bucle principal (bloques que se ARRASTRAN para ordenar, con scroll)
--  + LED virtual + consola serial.
--  Al ordenar bien: el LED parpadea, ganas puntos y aparece "SIGUIENTE RETO".
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sistema = ReplicatedStorage:WaitForChild("SistemaEducativo")
local Retos = require(sistema:WaitForChild("Retos"))

local abrirEvent     = ReplicatedStorage:WaitForChild("AbrirEstacionArduino")
local enviarEvent    = ReplicatedStorage:WaitForChild("EnviarSolucionArduino")
local siguienteEvent = ReplicatedStorage:WaitForChild("SiguienteRetoEvent")

-- medidas de los bloques del bucle
local H, GAP, TOP, PADX = 44, 8, 6, 6
local SLOT = H + GAP

-- ---------- utilidades ----------
local function c3(t) return Color3.fromRGB(t[1], t[2], t[3]) end
local function aclarar(t, amt)
	return Color3.fromRGB(math.min(t[1] + amt, 255), math.min(t[2] + amt, 255), math.min(t[3] + amt, 255))
end

local function barajar(lista)
	local t = table.clone(lista)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function patronDe(orden)
	local p = {}
	for _, b in ipairs(orden) do table.insert(p, b.simbolo) end
	return p
end

local function iguales(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do if a[i] ~= b[i] then return false end end
	return true
end

local function esquina(padre, radio)
	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0, radio or 8)
	uc.Parent = padre
end

local function mensajeCorto(texto)
	local g = Instance.new("ScreenGui")
	g.Name = "AvisoArduino"
	g.ResetOnSpawn = false
	g.Parent = playerGui
	local f = Instance.new("TextLabel")
	f.Size = UDim2.new(0, 460, 0, 60)
	f.Position = UDim2.new(0.5, -230, 0.25, 0)
	f.BackgroundColor3 = Color3.fromRGB(30, 90, 55)
	f.Text = texto
	f.TextColor3 = Color3.fromRGB(255, 255, 255)
	f.Font = Enum.Font.FredokaOne
	f.TextSize = 22
	f.Parent = g
	esquina(f, 12)
	task.delay(3, function() g:Destroy() end)
end

-- ---------- estado ----------
local abierto = false

local function abrirReto(retoId)
	if abierto then return end
	if retoId == "__completo__" then
		mensajeCorto("🎉 ¡Completaste todos los retos!")
		return
	end
	local reto = Retos.mapa[retoId]
	if not reto then return end
	abierto = true

	-- El mouse se libera con "Modal" en los botones (más abajo) SIN desequipar el
	-- arma: así al cerrar la ventana vuelves a tu arma tal como estaba.

	local orden = barajar(reto.bucle)
	if iguales(patronDe(orden), reto.patronCorrecto) then
		orden = barajar(reto.bucle)
	end
	local resuelto = false
	local conns = {}

	-- ===== GUI =====
	local gui = Instance.new("ScreenGui")
	gui.Name = "EstacionArduino"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.new(1, 0, 1, 0)
	fondo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	fondo.BackgroundTransparency = 1
	fondo.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Size = UDim2.new(0, 820, 0, 600)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 37, 51)
	panel.Parent = fondo
	esquina(panel, 20)

	local pgrad = Instance.new("UIGradient")
	pgrad.Color = ColorSequence.new(Color3.fromRGB(37, 46, 64), Color3.fromRGB(23, 28, 40))
	pgrad.Rotation = 90
	pgrad.Parent = panel

	local pstroke = Instance.new("UIStroke")
	pstroke.Color = Color3.fromRGB(90, 170, 235)
	pstroke.Thickness = 2
	pstroke.Transparency = 0.3
	pstroke.Parent = panel

	-- entrada animada (rebote + aparición del fondo)
	local panelEscala = Instance.new("UIScale")
	panelEscala.Scale = 0.7
	panelEscala.Parent = panel
	TweenService:Create(fondo, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(panelEscala, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local titulo = Instance.new("TextLabel")
	titulo.Size = UDim2.new(0, 700, 0, 44)
	titulo.Position = UDim2.new(0, 20, 0, 14)
	titulo.BackgroundTransparency = 1
	titulo.Text = "💡 " .. reto.titulo
	titulo.TextXAlignment = Enum.TextXAlignment.Left
	titulo.TextColor3 = Color3.fromRGB(255, 235, 130)
	titulo.Font = Enum.Font.FredokaOne
	titulo.TextSize = 28
	titulo.Parent = panel

	local btnCerrar = Instance.new("TextButton")
	btnCerrar.Size = UDim2.new(0, 44, 0, 44)
	btnCerrar.Position = UDim2.new(1, -56, 0, 14)
	btnCerrar.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	btnCerrar.Text = "✕"
	btnCerrar.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnCerrar.Font = Enum.Font.GothamBold
	btnCerrar.TextSize = 22
	btnCerrar.Parent = panel
	esquina(btnCerrar, 10)

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0, 780, 0, 36)
	desc.Position = UDim2.new(0, 20, 0, 58)
	desc.BackgroundTransparency = 1
	desc.Text = reto.descripcion
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.TextColor3 = Color3.fromRGB(200, 210, 225)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 15
	desc.Parent = panel

	-- ===== Sección INICIALIZAR (fija) =====
	local iniLbl = Instance.new("TextLabel")
	iniLbl.Size = UDim2.new(0, 380, 0, 22)
	iniLbl.Position = UDim2.new(0, 20, 0, 104)
	iniLbl.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
	iniLbl.Text = "🔧 INICIALIZAR (se ejecuta una vez)"
	iniLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	iniLbl.Font = Enum.Font.GothamBold
	iniLbl.TextSize = 13
	iniLbl.Parent = panel
	esquina(iniLbl, 6)

	local iniFrame = Instance.new("Frame")
	iniFrame.Size = UDim2.new(0, 380, 0, 66)
	iniFrame.Position = UDim2.new(0, 20, 0, 130)
	iniFrame.BackgroundTransparency = 1
	iniFrame.Parent = panel
	local iniLayout = Instance.new("UIListLayout")
	iniLayout.Padding = UDim.new(0, 5)
	iniLayout.Parent = iniFrame

	for _, b in ipairs(reto.inicializar or {}) do
		local blk = Instance.new("Frame")
		blk.Size = UDim2.new(1, 0, 0, 27)
		blk.BackgroundColor3 = c3(b.color)
		blk.BackgroundTransparency = 0.35
		blk.Parent = iniFrame
		esquina(blk, 7)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -16, 1, 0)
		t.Position = UDim2.new(0, 10, 0, 0)
		t.BackgroundTransparency = 1
		t.Text = "⚙ " .. b.texto
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.Font = Enum.Font.Gotham
		t.TextSize = 13
		t.TextTruncate = Enum.TextTruncate.AtEnd
		t.Parent = blk
	end

	-- ===== Sección BUCLE PRINCIPAL (arrastrar para ordenar, con scroll) =====
	local bucleLbl = Instance.new("TextLabel")
	bucleLbl.Size = UDim2.new(0, 380, 0, 22)
	bucleLbl.Position = UDim2.new(0, 20, 0, 204)
	bucleLbl.BackgroundColor3 = Color3.fromRGB(60, 90, 120)
	bucleLbl.Text = "🔁 BUCLE PRINCIPAL — arrastra ⠿ para ordenar"
	bucleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	bucleLbl.Font = Enum.Font.GothamBold
	bucleLbl.TextSize = 13
	bucleLbl.Parent = panel
	esquina(bucleLbl, 6)

	local lista = Instance.new("ScrollingFrame")
	lista.Size = UDim2.new(0, 380, 0, 300)
	lista.Position = UDim2.new(0, 20, 0, 230)
	lista.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	lista.BackgroundTransparency = 0.4
	lista.BorderSizePixel = 0
	lista.ScrollBarThickness = 6
	lista.CanvasSize = UDim2.new(0, 0, 0, 0)
	lista.Parent = panel
	esquina(lista, 10)

	-- ===== Panel derecho: Arduino virtual + consola =====
	local ledTitulo = Instance.new("TextLabel")
	ledTitulo.Size = UDim2.new(0, 380, 0, 22)
	ledTitulo.Position = UDim2.new(0, 420, 0, 104)
	ledTitulo.BackgroundTransparency = 1
	ledTitulo.Text = "🔌 Arduino virtual"
	ledTitulo.TextXAlignment = Enum.TextXAlignment.Left
	ledTitulo.TextColor3 = Color3.fromRGB(200, 210, 225)
	ledTitulo.Font = Enum.Font.GothamBold
	ledTitulo.TextSize = 15
	ledTitulo.Parent = panel

	local placa = Instance.new("Frame")
	placa.Size = UDim2.new(0, 380, 0, 120)
	placa.Position = UDim2.new(0, 420, 0, 130)
	placa.BackgroundColor3 = Color3.fromRGB(15, 90, 80)
	placa.Parent = panel
	esquina(placa, 12)

	local led = Instance.new("Frame")
	led.Size = UDim2.new(0, 64, 0, 64)
	led.Position = UDim2.new(0, 32, 0.5, -32)
	led.BackgroundColor3 = Color3.fromRGB(70, 60, 30)
	led.Parent = placa
	esquina(led, 32)

	local ledLbl = Instance.new("TextLabel")
	ledLbl.Size = UDim2.new(0, 240, 0, 40)
	ledLbl.Position = UDim2.new(0, 120, 0.5, -20)
	ledLbl.BackgroundTransparency = 1
	ledLbl.Text = "LED (pin 13)"
	ledLbl.TextXAlignment = Enum.TextXAlignment.Left
	ledLbl.TextColor3 = Color3.fromRGB(230, 240, 245)
	ledLbl.Font = Enum.Font.Gotham
	ledLbl.TextSize = 16
	ledLbl.Parent = placa

	local serialLbl = Instance.new("TextLabel")
	serialLbl.Size = UDim2.new(0, 380, 0, 22)
	serialLbl.Position = UDim2.new(0, 420, 0, 260)
	serialLbl.BackgroundTransparency = 1
	serialLbl.Text = "🖥️ Consola serial"
	serialLbl.TextXAlignment = Enum.TextXAlignment.Left
	serialLbl.TextColor3 = Color3.fromRGB(200, 210, 225)
	serialLbl.Font = Enum.Font.GothamBold
	serialLbl.TextSize = 15
	serialLbl.Parent = panel

	local consola = Instance.new("Frame")
	consola.Size = UDim2.new(0, 380, 0, 160)
	consola.Position = UDim2.new(0, 420, 0, 286)
	consola.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	consola.ClipsDescendants = true
	consola.Parent = panel
	esquina(consola, 10)

	local serialTexto = Instance.new("TextLabel")
	serialTexto.Size = UDim2.new(1, -16, 1, -12)
	serialTexto.Position = UDim2.new(0, 8, 0, 6)
	serialTexto.BackgroundTransparency = 1
	serialTexto.Text = ""
	serialTexto.TextXAlignment = Enum.TextXAlignment.Left
	serialTexto.TextYAlignment = Enum.TextYAlignment.Top
	serialTexto.TextColor3 = Color3.fromRGB(120, 255, 140)
	serialTexto.Font = Enum.Font.Code
	serialTexto.TextSize = 15
	serialTexto.TextWrapped = true
	serialTexto.Parent = consola

	local lineas = {}
	local function agregarSerial(txt)
		table.insert(lineas, "> " .. txt)
		while #lineas > 8 do table.remove(lineas, 1) end
		serialTexto.Text = table.concat(lineas, "\n")
	end
	local function encenderLED(on)
		led.BackgroundColor3 = on and Color3.fromRGB(255, 230, 60) or Color3.fromRGB(70, 60, 30)
	end

	local resultado = Instance.new("TextLabel")
	resultado.Size = UDim2.new(0, 540, 0, 40)
	resultado.Position = UDim2.new(0, 260, 1, -60)
	resultado.BackgroundTransparency = 1
	resultado.Text = "Arrastra los bloques del bucle y pulsa EJECUTAR ▶"
	resultado.TextXAlignment = Enum.TextXAlignment.Left
	resultado.TextColor3 = Color3.fromRGB(200, 210, 225)
	resultado.Font = Enum.Font.GothamBold
	resultado.TextSize = 15
	resultado.TextWrapped = true
	resultado.Parent = panel

	local btnEjecutar = Instance.new("TextButton")
	btnEjecutar.Size = UDim2.new(0, 220, 0, 52)
	btnEjecutar.Position = UDim2.new(0, 20, 1, -66)
	btnEjecutar.BackgroundColor3 = Color3.fromRGB(46, 190, 110)
	btnEjecutar.Text = "▶ EJECUTAR"
	btnEjecutar.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnEjecutar.Font = Enum.Font.FredokaOne
	btnEjecutar.TextSize = 22
	btnEjecutar.Parent = panel
	esquina(btnEjecutar, 12)

	-- Modal libera el puntero del mouse aunque tengas un arma equipada
	btnCerrar.Modal = true
	btnEjecutar.Modal = true

	-- ===== Bloques del bucle con ARRASTRE =====
	local bloques = {}
	local dragging = nil
	local dragStartMouseY = 0
	local dragStartBlockY = 0

	local function slotY(i) return TOP + (i - 1) * SLOT end
	local function actualizarCanvas()
		lista.CanvasSize = UDim2.new(0, 0, 0, TOP + #orden * SLOT + TOP)
	end
	local function renumerar()
		for j, bf in ipairs(bloques) do
			local num = bf:FindFirstChild("Num")
			if num then num.Text = tostring(j) end
			if j ~= dragging then
				bf.Position = UDim2.new(0, PADX, 0, slotY(j))
			end
		end
	end

	local function iniciarDrag(bloque)
		if resuelto then return end
		local idx = table.find(bloques, bloque)
		if not idx then return end
		dragging = idx
		dragStartBlockY = slotY(idx)
		dragStartMouseY = UserInputService:GetMouseLocation().Y
		bloque.ZIndex = 10
		for _, ch in ipairs(bloque:GetChildren()) do
			if ch:IsA("GuiObject") then ch.ZIndex = 11 end
		end
		lista.ScrollingEnabled = false
	end

	local function render()
		for _, h in ipairs(lista:GetChildren()) do
			if h:IsA("Frame") then h:Destroy() end
		end
		bloques = {}
		for i, b in ipairs(orden) do
			local bloque = Instance.new("Frame")
			bloque.Size = UDim2.new(1, -18, 0, H)
			bloque.Position = UDim2.new(0, PADX, 0, slotY(i))
			bloque.BackgroundColor3 = c3(b.color)
			bloque.Active = true  -- necesario para capturar el arrastre
			bloque.Parent = lista
			esquina(bloque, 9)

			local grip = Instance.new("TextLabel")
			grip.Size = UDim2.new(0, 22, 1, 0)
			grip.BackgroundTransparency = 1
			grip.Text = "⠿"
			grip.TextColor3 = Color3.fromRGB(255, 255, 255)
			grip.TextSize = 20
			grip.Parent = bloque

			local num = Instance.new("TextLabel")
			num.Name = "Num"
			num.Size = UDim2.new(0, 24, 1, 0)
			num.Position = UDim2.new(0, 22, 0, 0)
			num.BackgroundTransparency = 1
			num.Text = tostring(i)
			num.TextColor3 = Color3.fromRGB(255, 255, 255)
			num.Font = Enum.Font.FredokaOne
			num.TextSize = 18
			num.Parent = bloque

			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, -60, 1, 0)
			txt.Position = UDim2.new(0, 50, 0, 0)
			txt.BackgroundTransparency = 1
			txt.Text = b.texto
			txt.TextXAlignment = Enum.TextXAlignment.Left
			txt.TextWrapped = true
			txt.TextColor3 = Color3.fromRGB(255, 255, 255)
			txt.Font = Enum.Font.GothamBold
			txt.TextSize = 14
			txt.Parent = bloque

			bloque.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					iniciarDrag(bloque)
				end
			end)

			bloque.MouseEnter:Connect(function()
				if not dragging then
					TweenService:Create(bloque, TweenInfo.new(0.12), { BackgroundColor3 = aclarar(b.color, 30) }):Play()
				end
			end)
			bloque.MouseLeave:Connect(function()
				if not dragging then
					TweenService:Create(bloque, TweenInfo.new(0.12), { BackgroundColor3 = c3(b.color) }):Play()
				end
			end)

			bloques[i] = bloque
		end
		actualizarCanvas()
	end
	render()

	-- movimiento y soltar (globales, se limpian al cerrar)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			-- posición absoluta del mouse (input.Delta vale 0 con el mouse libre)
			local my = UserInputService:GetMouseLocation().Y
			local newY = dragStartBlockY + (my - dragStartMouseY)
			local db = bloques[dragging]
			if db then db.Position = UDim2.new(0, PADX, 0, newY) end
			local target = math.clamp(math.floor(newY / SLOT + 0.5) + 1, 1, #orden)
			if target ~= dragging then
				local it = table.remove(orden, dragging); table.insert(orden, target, it)
				local bf = table.remove(bloques, dragging); table.insert(bloques, target, bf)
				dragging = target
				renumerar()
			end
		end
	end))

	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			local db = bloques[dragging]
			local slot = slotY(dragging)
			if db then
				db.ZIndex = 1
				for _, ch in ipairs(db:GetChildren()) do
					if ch:IsA("GuiObject") then ch.ZIndex = 2 end
				end
				-- rebote al soltar en su lugar
				TweenService:Create(db, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Position = UDim2.new(0, PADX, 0, slot) }):Play()
			end
			dragging = nil
			lista.ScrollingEnabled = true
		end
	end))

	-- ===== Cerrar =====
	local function cerrar()
		for _, c in ipairs(conns) do c:Disconnect() end
		abierto = false
		gui:Destroy()
	end
	btnCerrar.MouseButton1Click:Connect(cerrar)

	-- Cerrar la ventana automáticamente si te alejas de la estación (sales de la base)
	local estPos
	do
		local ch = player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local mejorD = math.huge
			for _, m in ipairs(workspace:GetDescendants()) do
				if m:IsA("Model") and m.Name == "EstacionArduino" and m.PrimaryPart then
					local d = (m.PrimaryPart.Position - hrp.Position).Magnitude
					if d < mejorD then mejorD = d; estPos = m.PrimaryPart.Position end
				end
			end
		end
	end
	task.spawn(function()
		while gui.Parent do
			task.wait(0.5)
			if not gui.Parent then break end
			local ch = player.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if estPos and hrp and (hrp.Position - estPos).Magnitude > 22 then
				cerrar()
				break
			end
		end
	end)

	-- ===== Botón EJECUTAR / SIGUIENTE =====
	btnEjecutar.MouseButton1Click:Connect(function()
		if resuelto then
			-- avanzar al siguiente reto automáticamente
			cerrar()
			siguienteEvent:FireServer()
			return
		end

		local patron = patronDe(orden)
		if iguales(patron, reto.patronCorrecto) then
			resuelto = true
			lista.ScrollingEnabled = true
			resultado.Text = "✅ ¡Orden correcto! Ejecutando..."
			resultado.TextColor3 = Color3.fromRGB(120, 255, 140)

			task.spawn(function()
				lineas = {}
				serialTexto.Text = ""
				for _ = 1, 3 do
					encenderLED(true);  agregarSerial("LED encendido (HIGH)")
					task.wait(0.5)
					encenderLED(false); agregarSerial("LED apagado (LOW)")
					task.wait(0.5)
				end
				resultado.Text = "🎉 ¡Funciona! +" .. (reto.puntos or 10) .. " puntos"
			end)

			enviarEvent:FireServer(retoId, patron)

			btnEjecutar.Text = "▶ SIGUIENTE RETO"
			btnEjecutar.BackgroundColor3 = Color3.fromRGB(70, 140, 235)
		else
			resultado.Text = "❌ El orden aún no es correcto. Revisa la secuencia."
			resultado.TextColor3 = Color3.fromRGB(255, 130, 110)
		end
	end)
end

abrirEvent.OnClientEvent:Connect(abrirReto)

print("✅ EstacionArduino (cliente) lista")
