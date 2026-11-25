--=====================================================================
--  LISTA DE ELIMINACIONES (cliente) — arriba a la izquierda
--  "🔴 Juan ⚔️ 🔵 Ana  +8"   (se borra sola a los 6 s)
--=====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local feed = ReplicatedStorage:WaitForChild("Eliminacion", 60)
if not feed then return end

local COLORES = {
	[1] = Color3.fromRGB(255, 80, 80), [2] = Color3.fromRGB(80, 150, 255), [3] = Color3.fromRGB(80, 230, 90),
	[4] = Color3.fromRGB(255, 190, 60), [5] = Color3.fromRGB(200, 100, 255),
}
local GRIS = Color3.fromRGB(220, 220, 220)

local gui = Instance.new("ScreenGui")
gui.Name = "ListaEliminaciones"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local lista = Instance.new("Frame")
lista.Position = UDim2.new(0, 12, 0, 110)
lista.Size = UDim2.new(0, 330, 0, 200)
lista.BackgroundTransparency = 1
lista.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = lista

local orden = 0
feed.OnClientEvent:Connect(function(asesino, eqA, victima, eqV, puntos)
	orden += 1
	local fila = Instance.new("TextLabel")
	fila.LayoutOrder = orden
	fila.Size = UDim2.new(1, 0, 0, 26)
	fila.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
	fila.BackgroundTransparency = 0.35
	fila.RichText = true
	fila.Font = Enum.Font.GothamBold
	fila.TextSize = 15
	fila.TextXAlignment = Enum.TextXAlignment.Left
	fila.TextColor3 = Color3.fromRGB(255, 255, 255)
	local function c(eq) return (COLORES[eq] or GRIS):ToHex() end
	fila.Text = string.format('  <font color="#%s">%s</font>  ⚔️  <font color="#%s">%s</font>   <font color="#ffe066">+%d</font>',
		c(eqA), asesino, c(eqV), victima, puntos)
	fila.Parent = lista
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 8); uc.Parent = fila
	if asesino == player.Name then -- tu eliminación resalta
		local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(255, 224, 102); st.Thickness = 1.5; st.Parent = fila
	end
	-- máximo 6 filas
	local filas = {}
	for _, f in ipairs(lista:GetChildren()) do if f:IsA("TextLabel") then table.insert(filas, f) end end
	table.sort(filas, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	for i = 1, #filas - 6 do filas[i]:Destroy() end

	task.delay(6, function()
		if not fila.Parent then return end
		TweenService:Create(fila, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.5)
		fila:Destroy()
	end)
end)
