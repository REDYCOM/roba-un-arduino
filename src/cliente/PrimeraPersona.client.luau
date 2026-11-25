--=====================================================================
--  PRIMERA PERSONA SIEMPRE + MANOS VISIBLES (cliente)
--  - La cámara queda SIEMPRE en 1ª persona (ya no cambia al sacar/guardar
--    el arma, que era lo que causaba el bug del cursor).
--  - Sin arma: se ven tus dos manos en guardia (estilo boxeador) y un
--    puntito de mira en el centro.
--  - El cursor del mouse aparece solo cuando hace falta: ventana de la
--    estación, tienda, selector de equipo... (cualquier botón "Modal").
--  - MANTENER [Alt izquierdo] = mouse suelto mientras lo tengas apretado
--    (por ejemplo para usar el panel del profe).
--=====================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
	MOSTRAR_MANOS = true,
	TECLA_SOLTAR_MOUSE = Enum.KeyCode.LeftAlt,
	-- ventanas SIN botones Modal que también necesitan el mouse libre
	VENTANAS_CON_MOUSE = { TeamSelector = true },
}

-- ===== 1) Cámara fija en primera persona =====
local function forzarCamara()
	if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
	if player.CameraMaxZoomDistance > 0.5 then player.CameraMaxZoomDistance = 0.5 end
	if player.CameraMinZoomDistance > 0.5 then player.CameraMinZoomDistance = 0.5 end
end
forzarCamara()
-- los scripts de las armas intentan volver a "Classic" al guardar el arma: lo impedimos
player:GetPropertyChangedSignal("CameraMode"):Connect(forzarCamara)
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(forzarCamara)

-- ===== 2) Mouse libre / atrapado =====
local gui = Instance.new("ScreenGui")
gui.Name = "ControlMousePrimeraPersona"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

-- botón invisible de 1 píxel: si está visible, Roblox suelta el mouse
local liberador = Instance.new("TextButton")
liberador.Name = "LiberadorMouse"
liberador.Size = UDim2.new(0, 1, 0, 1)
liberador.Position = UDim2.new(0, 0, 0, 0)
liberador.BackgroundTransparency = 1
liberador.Text = ""
liberador.Modal = true
liberador.Visible = false
liberador.Parent = gui

-- puntito de mira cuando no tienes arma
local punto = Instance.new("Frame")
punto.AnchorPoint = Vector2.new(0.5, 0.5)
punto.Position = UDim2.new(0.5, 0, 0.5, 0)
punto.Size = UDim2.new(0, 6, 0, 6)
punto.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
punto.BackgroundTransparency = 0.25
punto.BorderSizePixel = 0
punto.Visible = false
punto.Parent = gui
local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1, 0); uc.Parent = punto
local borde = Instance.new("UIStroke"); borde.Thickness = 1; borde.Transparency = 0.4; borde.Parent = punto

-- MANTENER [Alt] = mouse suelto; al soltar Alt vuelve a la mira.
-- (antes era un interruptor y con Alt+Tab o un aviso de Windows quedaba suelto)
local soltadoAMano = false
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == CONFIG.TECLA_SOLTAR_MOUSE then soltadoAMano = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == CONFIG.TECLA_SOLTAR_MOUSE then soltadoAMano = false end
end)
-- si la ventana de Roblox pierde o recupera el foco (otra ventana, mensaje de la PC...), reiniciar
UserInputService.WindowFocusReleased:Connect(function() soltadoAMano = false end)
UserInputService.WindowFocused:Connect(function()
	soltadoAMano = false
	forzarCamara()
end)

local function estaVisible(obj)
	local o = obj
	while o and o ~= playerGui do
		if o:IsA("GuiObject") and not o.Visible then return false end
		if o:IsA("LayerCollector") and not o.Enabled then return false end
		o = o.Parent
	end
	return o == playerGui
end

-- ¿hay alguna ventana abierta que necesite el mouse?
local hayVentana = false
task.spawn(function()
	while true do
		local encontrado = false
		for _, sg in ipairs(playerGui:GetChildren()) do
			if sg ~= gui and sg:IsA("LayerCollector") and sg.Enabled then
				if CONFIG.VENTANAS_CON_MOUSE[sg.Name] then
					encontrado = true
				else
					for _, d in ipairs(sg:GetDescendants()) do
						if d:IsA("GuiButton") and d.Modal and estaVisible(d) then
							encontrado = true
							break
						end
					end
				end
			end
			if encontrado then break end
		end
		hayVentana = encontrado
		task.wait(0.15)
	end
end)

local function herramientaEquipada()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Tool")
end

-- se ejecuta al final de cada cuadro: gana sobre lo que pongan las armas
RunService:BindToRenderStep("ControlMouse1raPersona", Enum.RenderPriority.Last.Value, function()
	local libre = hayVentana or soltadoAMano
	liberador.Visible = libre
	UserInputService.MouseIconEnabled = libre
	punto.Visible = (not libre) and herramientaEquipada() == nil
end)

-- ===== 3) Manos visibles =====
local PARTES_BRAZO = {
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"Right Arm", "Left Arm", -- (por si el personaje es R6)
}

local juntas = nil -- { hombroD, hombroI, codoD, codoI }

local function prepararPersonaje(char)
	juntas = nil
	local function buscar()
		local rUA = char:WaitForChild("RightUpperArm", 5)
		local lUA = char:WaitForChild("LeftUpperArm", 5)
		local rLA = char:WaitForChild("RightLowerArm", 5)
		local lLA = char:WaitForChild("LeftLowerArm", 5)
		if not (rUA and lUA and rLA and lLA) then return end -- R6: solo se muestran, sin pose
		juntas = {
			hombroD = rUA:WaitForChild("RightShoulder", 5),
			hombroI = lUA:WaitForChild("LeftShoulder", 5),
			codoD = rLA:WaitForChild("RightElbow", 5),
			codoI = lLA:WaitForChild("LeftElbow", 5),
		}
	end
	task.spawn(buscar)
end
if player.Character then prepararPersonaje(player.Character) end
player.CharacterAdded:Connect(prepararPersonaje)

-- 3a) que los brazos NO se escondan (la cámara de 1ª persona los oculta)
RunService:BindToRenderStep("MostrarManos", Enum.RenderPriority.Camera.Value + 1, function()
	if not CONFIG.MOSTRAR_MANOS then return end
	local char = player.Character
	if not char then return end
	for _, n in ipairs(PARTES_BRAZO) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
	end
end)

-- 3b) pose de guardia cuando NO tienes arma (después de las animaciones)
RunService.Stepped:Connect(function()
	if not CONFIG.MOSTRAR_MANOS or not juntas then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if herramientaEquipada() then return end -- con arma manda la animación del arma
	local j = juntas
	if not (j.hombroD and j.hombroI and j.codoD and j.codoI) then return end
	if not (j.hombroD.Parent and j.hombroI.Parent) then return end

	local cam = workspace.CurrentCamera
	local mirar = cam and math.deg(math.asin(math.clamp(cam.CFrame.LookVector.Y, -1, 1))) or 0
	mirar = math.clamp(mirar, -60, 60)

	local t = os.clock()
	local andar = hum.MoveDirection.Magnitude
	local paso = math.sin(t * 9) * 5 * andar     -- los brazos se mueven al caminar
	local respirar = math.sin(t * 2) * 1.5       -- leve balanceo en quieto

	local function hombro(lado)
		local sube = 85 + mirar + respirar + paso * lado
		local adentro = 22 * lado
		return CFrame.Angles(0, math.rad(adentro), 0) * CFrame.Angles(math.rad(sube), 0, 0)
	end
	j.hombroD.Transform = hombro(1)
	j.hombroI.Transform = hombro(-1)
	j.codoD.Transform = CFrame.Angles(math.rad(65), 0, 0)
	j.codoI.Transform = CFrame.Angles(math.rad(65), 0, 0)
end)

print("✅ Primera persona fija + manos visibles (mantén Alt = soltar mouse)")
