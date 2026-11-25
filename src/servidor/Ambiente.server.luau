--=====================================================================
--  AMBIENTE / CLIMA (servidor)
--  Cambia la iluminación según lo que pase en la partida:
--    descanso / lobby  -> día normal (la iluminación original de tu mapa)
--    oleada normal     -> NOCHE
--    llega el jefe     -> TORMENTA roja (el cliente agrega lluvia y rayos)
--    enjambre de drones-> NIEBLA verdosa con llovizna
--  Para desactivarlo: pon ACTIVO = false.
--=====================================================================

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ACTIVO = true
local TRANSICION = 4  -- segundos que tarda en cambiar el clima

local estado = ReplicatedStorage:WaitForChild("EstadoRobots")
local RGB = Color3.fromRGB

-- Guardar la iluminación original del mapa
local original = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Ambient = Lighting.Ambient,
}
local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if not atm then
	atm = Instance.new("Atmosphere")
	atm.Density = 0; atm.Haze = 0; atm.Glare = 0
	atm.Parent = Lighting
end
local atmOriginal = { Density = atm.Density, Haze = atm.Haze, Color = atm.Color, Decay = atm.Decay }

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "ColorClimaRobots"
cc.Parent = Lighting

local CLIMAS = {
	despejado = {
		luz = original,
		atm = atmOriginal,
		cc = { TintColor = RGB(255, 255, 255), Saturation = 0, Contrast = 0, Brightness = 0 },
	},
	noche = {
		luz = { ClockTime = 20.6, Brightness = 1.2, OutdoorAmbient = RGB(80, 80, 120), Ambient = RGB(40, 40, 60) },
		atm = { Density = 0.35, Haze = 1.5, Color = RGB(120, 130, 190), Decay = RGB(60, 60, 110) },
		cc = { TintColor = RGB(215, 220, 255), Saturation = -0.1, Contrast = 0.05, Brightness = 0 },
	},
	tormenta = {
		luz = { ClockTime = 23.5, Brightness = 0.8, OutdoorAmbient = RGB(110, 55, 55), Ambient = RGB(60, 30, 30) },
		atm = { Density = 0.45, Haze = 2.5, Color = RGB(190, 95, 80), Decay = RGB(90, 30, 30) },
		cc = { TintColor = RGB(255, 205, 200), Saturation = 0.05, Contrast = 0.15, Brightness = -0.02 },
	},
	niebla = {
		luz = { ClockTime = 18.3, Brightness = 1.4, OutdoorAmbient = RGB(110, 130, 120), Ambient = RGB(50, 60, 55) },
		atm = { Density = 0.6, Haze = 3, Color = RGB(160, 180, 170), Decay = RGB(90, 110, 100) },
		cc = { TintColor = RGB(225, 255, 235), Saturation = -0.15, Contrast = 0.05, Brightness = 0 },
	},
}

local actual = nil
local function aplicar(nombre)
	if nombre == actual then return end
	actual = nombre
	estado:SetAttribute("Clima", nombre)  -- el cliente lo lee para lluvia y rayos
	local c = CLIMAS[nombre]
	local info = TweenInfo.new(TRANSICION, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, c.luz):Play()
	TweenService:Create(atm, info, c.atm):Play()
	TweenService:Create(cc, info, c.cc):Play()
end

local function evaluar()
	if not ACTIVO then return end
	local fase = estado:GetAttribute("Fase")
	if (estado:GetAttribute("JefeNombre") or "") ~= "" or fase == "final" then
		aplicar("tormenta")
	elseif fase == "oleada" and estado:GetAttribute("TipoOleada") == "drones" then
		aplicar("niebla")
	elseif fase == "oleada" then
		aplicar("noche")
	else
		aplicar("despejado")
	end
end

for _, k in ipairs({ "Fase", "TipoOleada", "JefeNombre" }) do
	estado:GetAttributeChangedSignal(k):Connect(evaluar)
end
evaluar()

print("✅ Clima dinámico listo")
