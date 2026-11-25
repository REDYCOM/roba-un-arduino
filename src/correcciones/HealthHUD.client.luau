-- === SCRIPT 1: StarterGui > ScreenGui > HealthHUD (LocalScript) ===
-- Barra de vida que aparece cuando equipas el arma

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local screenGui = script.Parent
local isWeaponEquipped = false

-- Crear contenedor de la barra de vida
local healthFrame = Instance.new("Frame")
healthFrame.Name = "HealthFrame"
healthFrame.Size = UDim2.new(0, 250, 0, 50)
healthFrame.Position = UDim2.new(0, 20, 1, -70) -- Esquina inferior izquierda
healthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
healthFrame.BackgroundTransparency = 0.1
healthFrame.BorderSizePixel = 0
healthFrame.Visible = false
healthFrame.ZIndex = 10
healthFrame.Parent = screenGui

print("✅ [HealthHUD] Barra creada")

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = healthFrame

-- Título "VIDA"
local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "Label"
healthLabel.Size = UDim2.new(1, 0, 0, 15)
healthLabel.Position = UDim2.new(0, 0, 0, 2)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "VIDA"
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextSize = 14
healthLabel.ZIndex = 11
healthLabel.Parent = healthFrame

-- Contenedor de la barra
local barContainer = Instance.new("Frame")
barContainer.Name = "BarContainer"
barContainer.Size = UDim2.new(0.9, 0, 0, 20)
barContainer.Position = UDim2.new(0.05, 0, 0, 20)
barContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
barContainer.BorderSizePixel = 0
barContainer.ZIndex = 11
barContainer.Parent = healthFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = barContainer

-- Barra de vida
local healthBar = Instance.new("Frame")
healthBar.Name = "Bar"
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
healthBar.BorderSizePixel = 0
healthBar.ZIndex = 12
healthBar.Parent = barContainer

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 6)
healthBarCorner.Parent = healthBar

-- Texto de vida
local healthText = Instance.new("TextLabel")
healthText.Name = "HealthText"
healthText.Size = UDim2.new(1, 0, 0, 15)
healthText.Position = UDim2.new(0, 0, 0, 42)
healthText.BackgroundTransparency = 1
healthText.Text = "100 / 100"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.Font = Enum.Font.Gotham
healthText.TextSize = 12
healthText.ZIndex = 11
healthText.Parent = healthFrame

-- Función para actualizar la barra
local function updateHealthBar()
	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth
	local percentage = health / maxHealth

	game:GetService("TweenService"):Create(
		healthBar,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{Size = UDim2.new(percentage, 0, 1, 0)}
	):Play()

	healthText.Text = math.floor(health) .. " / " .. math.floor(maxHealth)

	if percentage >= 0.5 then
		healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	elseif percentage >= 0.2 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end

-- Función para verificar si el arma está equipada
local function checkWeaponEquipped()
	-- Buscar en el Humanoid (cuando está equipada)
	local weaponInHumanoid = humanoid:FindFirstChildOfClass("Tool")
	-- Buscar en el Character (también puede estar aquí)
	local weaponInCharacter = character:FindFirstChildOfClass("Tool")

	return weaponInHumanoid ~= nil or weaponInCharacter ~= nil
end

-- Función para mostrar/ocultar barra
local function updateBarVisibility()
	local equipped = checkWeaponEquipped()
	healthFrame.Visible = equipped

	if equipped then
		print("⚔️ [HealthHUD] BARRA VISIBLE - Arma equipada")
	else
		print("🚫 [HealthHUD] BARRA OCULTA - Arma desequipada")
	end
end

-- Detectar cuando se agrega algo al Humanoid (arma equipada)
humanoid.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		print("🔧 [HealthHUD] Arma detectada en Humanoid")
		task.wait(0.05)
		updateBarVisibility()
	end
end)

-- Detectar cuando se quita algo del Humanoid (arma desequipada)
humanoid.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		print("🔧 [HealthHUD] Arma removida de Humanoid")
		task.wait(0.05)
		updateBarVisibility()
	end
end)

-- También detectar en Character (por si acaso)
character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		print("🔧 [HealthHUD] Arma detectada en Character")
		task.wait(0.05)
		updateBarVisibility()
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		print("🔧 [HealthHUD] Arma removida de Character")
		task.wait(0.05)
		updateBarVisibility()
	end
end)

-- Actualizar cuando cambie la vida
humanoid.HealthChanged:Connect(updateHealthBar)

-- Actualizar al inicio
updateHealthBar()
updateBarVisibility()

-- Si el personaje muere y reaparece
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")

	humanoid.HealthChanged:Connect(updateHealthBar)

	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.05)
			updateBarVisibility()
		end
	end)

	humanoid.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.05)
			updateBarVisibility()
		end
	end)

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.05)
			updateBarVisibility()
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.05)
			updateBarVisibility()
		end
	end)

	updateHealthBar()
	updateBarVisibility()
end)

