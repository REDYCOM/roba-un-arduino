--=====================================================================
--  BIENVENIDA (cliente): HISTORIA + CÓMO SE JUEGA
--  1) Historia en 4 escenas (texto que se escribe solo) del hechicero
--     ARDUNOL que robó el ARDUINO SUPREMO.
--  2) Guía clara: objetivo, equipos, tabla de puntos, retos, peligros,
--     gran final y controles.
--  Se puede volver a abrir con la tecla [I] o el botón "❓ Cómo jugar".
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RGB = Color3.fromRGB

local MOSTRAR_AL_ENTRAR = true

local TEAL, ORO, MORADO = RGB(0, 200, 190), RGB(255, 210, 80), RGB(170, 90, 255)

local ESCENAS = {
	{ icono = "🏰", color = TEAL, titulo = "EL REINO DE LOS CIRCUITOS",
	  texto = "Hace mucho tiempo, todos los robots del reino funcionaban gracias al ARDUINO SUPREMO, la placa más poderosa jamás programada." },
	{ icono = "🧙", color = MORADO, titulo = "EL HECHICERO ARDUNOL",
	  texto = "Pero el malvado hechicero ARDUNOL lo robó con su magia oscura... y con su poder creó un ejército de robots malvados." },
	{ icono = "🤖", color = RGB(255, 90, 80), titulo = "EL MEGA-ARDUINO",
	  texto = "Su creación más temible es el MEGA-ARDUINO: un robot gigante con un puño de energía que protege el ARDUINO SUPREMO." },
	{ icono = "⚡", color = ORO, titulo = "TU MISIÓN",
	  texto = "Con tu equipo: junta componentes electrónicos, programa en las estaciones, sobrevive a las oleadas... ¡y en la GRAN FINAL derrota al robot de Ardunol para recuperar el ARDUINO SUPREMO!" },
}

-- ===== utilidades de UI =====
local function nuevo(clase, props, padre)
	local o = Instance.new(clase)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = padre
	return o
end
local function esquinas(o, r) nuevo("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o) end
local function boton(texto, color, padre)
	local b = nuevo("TextButton", {
		Size = UDim2.new(0, 200, 0, 46), BackgroundColor3 = color, Text = texto,
		Font = Enum.Font.FredokaOne, TextSize = 22, TextColor3 = RGB(255, 255, 255),
		AutoButtonColor = true, Modal = true, -- Modal: suelta el mouse (estás en 1ª persona)
	}, padre)
	esquinas(b, 14)
	nuevo("UIStroke", { Color = RGB(255, 255, 255), Transparency = 0.6, Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	return b
end

local gui = nuevo("ScreenGui", { Name = "Bienvenida", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- fondo oscuro con estrellas que titilan
local fondo = nuevo("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = RGB(6, 8, 22) }, gui)
nuevo("UIGradient", { Color = ColorSequence.new(RGB(30, 12, 60), RGB(4, 10, 24)), Rotation = 90 }, fondo)
local estrellas = {}
for _ = 1, 70 do
	local s = math.random(2, 4)
	local e = nuevo("Frame", { Size = UDim2.new(0, s, 0, s), Position = UDim2.new(math.random(), 0, math.random(), 0),
		BackgroundColor3 = RGB(255, 255, 255), BackgroundTransparency = math.random() * 0.6, BorderSizePixel = 0 }, fondo)
	esquinas(e, 4)
	table.insert(estrellas, e)
end

-- ===== PARTE 1: HISTORIA =====
local historia = nuevo("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, gui)
local icono = nuevo("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.3, 0),
	Size = UDim2.new(0, 180, 0, 180), BackgroundTransparency = 1, Text = "", TextScaled = true,
	Font = Enum.Font.FredokaOne }, historia)
local escalaIcono = nuevo("UIScale", { Scale = 1 }, icono)
local tituloH = nuevo("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0.9, 0, 0, 54), BackgroundTransparency = 1, Text = "", TextScaled = true,
	Font = Enum.Font.FredokaOne, TextColor3 = TEAL, TextStrokeTransparency = 0.3 }, historia)
local textoH = nuevo("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.57, 0),
	Size = UDim2.new(0, 760, 0, 130), BackgroundTransparency = 1, Text = "", TextWrapped = true,
	TextSize = 26, Font = Enum.Font.GothamMedium, TextColor3 = RGB(235, 240, 255),
	TextYAlignment = Enum.TextYAlignment.Top }, historia)
nuevo("UISizeConstraint", { MaxSize = Vector2.new(760, 130) }, textoH)
local puntos = nuevo("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -100),
	Size = UDim2.new(0, 200, 0, 20), BackgroundTransparency = 1, Text = "", TextSize = 22,
	Font = Enum.Font.GothamBold, TextColor3 = RGB(180, 180, 200) }, historia)
local filaBotones = nuevo("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -36),
	Size = UDim2.new(0, 420, 0, 46), BackgroundTransparency = 1 }, historia)
nuevo("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20),
	HorizontalAlignment = Enum.HorizontalAlignment.Center }, filaBotones)
local btnSaltar = boton("Saltar historia", RGB(60, 60, 80), filaBotones)
local btnSiguiente = boton("Siguiente ▶", TEAL, filaBotones)

-- ===== PARTE 2: CÓMO SE JUEGA =====
local guia = nuevo("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, gui)
nuevo("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18),
	Size = UDim2.new(0.9, 0, 0, 50), BackgroundTransparency = 1, Text = "⚡ ROBA UN ARDUINO · CÓMO SE JUEGA ⚡",
	TextScaled = true, Font = Enum.Font.FredokaOne, TextColor3 = ORO, TextStrokeTransparency = 0.3 }, guia)

local scroll = nuevo("ScrollingFrame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 78),
	Size = UDim2.new(0.94, 0, 1, -150), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, guia)
nuevo("UISizeConstraint", { MaxSize = Vector2.new(1100, 2000) }, scroll)
local grid = nuevo("UIGridLayout", { CellSize = UDim2.new(0.5, -10, 0, 210), CellPadding = UDim2.new(0, 14, 0, 14),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local function tarjeta(orden, titulo, color, lineas)
	local t = nuevo("Frame", { LayoutOrder = orden, BackgroundColor3 = RGB(16, 18, 36), BackgroundTransparency = 0.1 }, scroll)
	esquinas(t, 16)
	nuevo("UIStroke", { Color = color, Thickness = 2, Transparency = 0.2 }, t)
	nuevo("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, t)
	nuevo("TextLabel", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = titulo,
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.FredokaOne, TextSize = 26,
		TextColor3 = color }, t)
	nuevo("TextLabel", { Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 1, -38),
		BackgroundTransparency = 1, Text = table.concat(lineas, "\n"), RichText = true, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.GothamMedium, TextSize = 17, TextColor3 = RGB(225, 230, 245), LineHeight = 1.15 }, t)
	return t
end

local function armarGuia()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local pe = ReplicatedStorage:FindFirstChild("PuntajeEquipos")
	local pComp = pe and pe:GetAttribute("PorComponente") or 100
	local pElim = pe and pe:GetAttribute("PorEliminacion") or 8
	local Y = '<font color="#ffe066">'
	local F = "</font>"

	tarjeta(1, "🎯 OBJETIVO", ORO, {
		"Que <b>tu EQUIPO</b> tenga el puntaje más alto.",
		"Los <b>2 mejores equipos</b> pasan a la <b>GRAN FINAL</b> contra el robot gigante de Ardunol.",
		"El que más daño le haga, <b>¡recupera el ARDUINO SUPREMO!</b> 🏆",
	})
	tarjeta(2, "👥 EQUIPOS", RGB(90, 170, 255), {
		"Hay <b>5 equipos</b> (🔴 🔵 🟢 🟠 🟣), cada uno con su <b>BASE</b>.",
		"Todo lo que ganas <b>suma para tu equipo</b>. Mantén <b>[Tab]</b> para ver la tabla.",
		"No puedes dañar a tu propio equipo. ¡Trabajen juntos!",
	})
	tarjeta(3, "⭐ TABLA DE PUNTOS", RGB(90, 255, 200), {
		"🔌 Llevar un componente a tu base: " .. Y .. "+" .. pComp .. F .. "  <i>(¡lo que más vale!)</i>",
		"🤖 Destruir robots: " .. Y .. "+10 a +80" .. F .. "   👑 Jefe: " .. Y .. "+150" .. F,
		"🧩 Resolver un reto de programación: " .. Y .. "+10 a +60" .. F .. " y un PODER",
		"⚔️ Eliminar a un jugador enemigo: " .. Y .. "+" .. pElim .. F,
		"🚨 Si te roban un componente, tu equipo " .. '<font color="#ff6b6b">lo pierde</font>.',
	})
	tarjeta(4, "🔌 COMPONENTES", TEAL, {
		"Los componentes electrónicos (Arduino, L298N, sensor, baterías, motores...) <b>flotan y brillan</b> por el mapa.",
		"Acércate y presiona <b>[E]</b> para recogerlo, y llévalo a tu base.",
		"¡Cuidado! Si mueres lo sueltas, y otros equipos pueden <b>robarlo de tu base</b>.",
	})
	tarjeta(5, "🧩 RETOS DE PROGRAMACIÓN", MORADO, {
		"En tu base está el <b>robot-estación</b>: presiona <b>[E]</b> para resolver retos tipo bloques de Arduino.",
		"Cada reto te da puntos y desbloquea un <b>PODER</b> (armas, armadura, volar...).",
		"Presiona <b>[T]</b> en la estación para abrir la <b>TIENDA</b> y gastar tus puntos.",
	})
	tarjeta(6, "☠️ PELIGROS", RGB(255, 100, 90), {
		"Llegan <b>oleadas de robots</b>: los gigantes (Coloso, Jefe) <b>te matan si te tocan</b>.",
		"Las <b>runas</b> de colores te dan poderes temporales: ¡tómalas!",
		"Los jugadores de otros equipos también pueden atacarte.",
	})
	tarjeta(7, "🏆 GRAN FINAL", ORO, {
		"Tras varias oleadas, los 2 mejores equipos viajan a la <b>arena del cielo</b>.",
		"El jefe caza al que más daño le hace (🎯 <b>CAZADO</b>): ¡protejan a su compañero!",
		"El equipo con <b>más daño al jefe</b> gana el <b>ARDUINO SUPREMO</b>.",
	})
	tarjeta(8, "🎮 CONTROLES", RGB(200, 200, 220), {
		"<b>[E]</b> recoger / estación   <b>[T]</b> tienda   <b>[Tab]</b> puntajes",
		"<b>[1-9]</b> armas   <b>[Clic]</b> disparar   <b>[F]</b> volar (con el poder)",
		"Mantén <b>[Alt]</b> = mouse libre   <b>[I]</b> ver esta guía otra vez",
	})
end

local btnJugar = boton("¡A JUGAR! ⚔️", RGB(40, 170, 90), guia)
btnJugar.AnchorPoint = Vector2.new(0.5, 1)
btnJugar.Position = UDim2.new(0.5, 0, 1, -14)
btnJugar.Size = UDim2.new(0, 260, 0, 52)

-- ===== lógica =====
local escena = 0
local escribiendo = nil

local function mostrarEscena(i)
	escena = i
	local e = ESCENAS[i]
	icono.Text = e.icono
	tituloH.Text = e.titulo
	tituloH.TextColor3 = e.color
	textoH.Text = e.texto
	textoH.MaxVisibleGraphemes = 0
	puntos.Text = string.rep("● ", i) .. string.rep("○ ", #ESCENAS - i)
	btnSiguiente.Text = (i == #ESCENAS) and "¿Cómo se juega? ▶" or "Siguiente ▶"
	-- el icono aparece con rebote
	escalaIcono.Scale = 0.2
	TweenService:Create(escalaIcono, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	tituloH.TextTransparency = 1
	TweenService:Create(tituloH, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
	-- texto que se escribe solo
	local id = {}
	escribiendo = id
	task.spawn(function()
		local total = utf8.len(e.texto) or #e.texto
		for n = 1, total do
			if escribiendo ~= id then return end
			textoH.MaxVisibleGraphemes = n
			task.wait(0.022)
		end
		textoH.MaxVisibleGraphemes = -1
	end)
end

local function abrirGuia()
	escribiendo = nil
	historia.Visible = false
	armarGuia()
	guia.Visible = true
	scroll.CanvasPosition = Vector2.new(0, 0)
end

local function cerrar()
	escribiendo = nil
	TweenService:Create(fondo, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	task.wait(0.3)
	gui.Enabled = false
	fondo.BackgroundTransparency = 0
end

local function abrir(conHistoria)
	gui.Enabled = true
	if conHistoria then
		guia.Visible = false
		historia.Visible = true
		mostrarEscena(1)
	else
		abrirGuia()
	end
end

btnSiguiente.MouseButton1Click:Connect(function()
	-- si el texto aún se está escribiendo, primero lo completa
	if textoH.MaxVisibleGraphemes ~= -1 then
		escribiendo = nil
		textoH.MaxVisibleGraphemes = -1
		return
	end
	if escena < #ESCENAS then mostrarEscena(escena + 1) else abrirGuia() end
end)
btnSaltar.MouseButton1Click:Connect(abrirGuia)
btnJugar.MouseButton1Click:Connect(cerrar)

-- estrellas que titilan
task.spawn(function()
	while true do
		if gui.Enabled then
			local e = estrellas[math.random(#estrellas)]
			TweenService:Create(e, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
				{ BackgroundTransparency = 0.95 }):Play()
		end
		task.wait(0.08)
	end
end)

-- botón para volver a ver la guía + tecla [I]
local botonGuiaGui = nuevo("ScreenGui", { Name = "BotonComoJugar", ResetOnSpawn = false }, playerGui)
local botonGuia = nuevo("TextButton", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.new(0, 150, 0, 34), BackgroundColor3 = RGB(16, 18, 36), BackgroundTransparency = 0.25,
	Text = "❓ Cómo jugar [I]", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = ORO }, botonGuiaGui)
esquinas(botonGuia, 10)
botonGuia.MouseButton1Click:Connect(function() abrir(false) end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then return end
	if input.KeyCode == Enum.KeyCode.I then
		if gui.Enabled then cerrar() else abrir(false) end
	end
end)

if MOSTRAR_AL_ENTRAR then
	task.wait(1.5) -- que cargue el mundo primero
	abrir(true)
end

print("✅ Bienvenida e historia listas ([I] = cómo jugar)")
