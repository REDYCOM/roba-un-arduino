--=====================================================================
--  VOLAR (poder 9) — cliente
--  Al desbloquear, muestra en pantalla cómo volar. Vuelo estilo Superman
--  (estable, sin caerse). Tecla F para volar/aterrizar.
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local poderEvent = ReplicatedStorage:WaitForChild("PoderDesbloqueado")
local syncEvent  = ReplicatedStorage:WaitForChild("SincronizarPoderes")

local PODER_VOLAR = 9
local VELOCIDAD = 80

local puedeVolar = false
local volando = false
local bv, bg, loopConn
local character, humanoid, hrp

-- ===== GUI: hint permanente + instrucciones =====
local gui = Instance.new("ScreenGui")
gui.Name = "VolarUI"; gui.ResetOnSpawn = false; gui.Enabled = false; gui.Parent = playerGui

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 12, 1, -12)
hint.Size = UDim2.new(0, 150, 0, 30)
hint.BackgroundColor3 = Color3.fromRGB(20, 24, 32); hint.BackgroundTransparency = 0.25
hint.Text = "🕊️ [F] Volar"
hint.TextColor3 = Color3.fromRGB(180, 230, 255); hint.Font = Enum.Font.GothamBold; hint.TextSize = 15
hint.Parent = gui
local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 8); uc.Parent = hint

local function instrucciones()
	local g = Instance.new("ScreenGui")
	g.Name = "InstruccionesVolar"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.Parent = playerGui
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0.12, 0)
	f.Size = UDim2.new(0, 460, 0, 150)
	f.BackgroundColor3 = Color3.fromRGB(20, 40, 60); f.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = f
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(120, 200, 255); s.Thickness = 2; s.Parent = f
	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0, 40); t1.Position = UDim2.new(0, 0, 0, 12); t1.BackgroundTransparency = 1
	t1.Text = "🕊️ ¡DESBLOQUEASTE VOLAR!"; t1.TextColor3 = Color3.fromRGB(255, 235, 130)
	t1.Font = Enum.Font.FredokaOne; t1.TextSize = 24; t1.Parent = f
	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, -30, 0, 90); t2.Position = UDim2.new(0, 15, 0, 52); t2.BackgroundTransparency = 1
	t2.Text = "Presiona [F] para volar o aterrizar.\n[W][A][S][D] te mueven  •  [Espacio] sube  •  [Shift] baja"
	t2.TextColor3 = Color3.fromRGB(230, 245, 255); t2.Font = Enum.Font.GothamBold; t2.TextSize = 16
	t2.TextWrapped = true; t2.Parent = f
	task.delay(9, function() g:Destroy() end)
end

-- ===== Vuelo =====
local function stopFly()
	volando = false
	if loopConn then loopConn:Disconnect(); loopConn = nil end
	if bv then bv:Destroy(); bv = nil end
	if bg then bg:Destroy(); bg = nil end
	if humanoid then humanoid.PlatformStand = false end
end

local function startFly()
	if not (humanoid and hrp and humanoid.Health > 0) then return end
	volando = true
	humanoid.PlatformStand = true

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * 1e5; bv.P = 1250; bv.Velocity = Vector3.zero; bv.Parent = hrp
	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1, 1, 1) * 1e5; bg.P = 3000; bg.D = 500; bg.CFrame = hrp.CFrame; bg.Parent = hrp

	loopConn = RunService.RenderStepped:Connect(function()
		if not (humanoid and hrp and humanoid.Health > 0) then stopFly(); return end
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0 then dir = dir.Unit end
		bv.Velocity = dir * VELOCIDAD
		local horiz = Vector3.new(dir.X, 0, dir.Z)
		if horiz.Magnitude > 0.1 then
			-- mira hacia donde vuela + leve inclinación (efecto Superman)
			bg.CFrame = CFrame.lookAt(Vector3.new(), horiz) * CFrame.Angles(math.rad(-18), 0, 0)
		end
	end)
end

local function toggleFly()
	if not puedeVolar then return end
	if volando then stopFly() else startFly() end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F then toggleFly() end
end)

-- ===== Personaje =====
local function onChar(char)
	stopFly()
	character = char
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
end
if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

-- ===== Desbloqueo =====
local function habilitar()
	if puedeVolar then return end
	puedeVolar = true
	gui.Enabled = true
end

poderEvent.OnClientEvent:Connect(function(n)
	if n == PODER_VOLAR then
		habilitar()
		instrucciones()
	end
end)
syncEvent.OnClientEvent:Connect(function(lista)
	for _, n in ipairs(lista) do
		if n == PODER_VOLAR then habilitar() end
	end
end)

print("✅ Poder volar listo")
