--=====================================================================
--  RETOS DE PROGRAMACIÓN (estilo ArduinoBlocks)
--  Cada reto tiene DOS secciones, como en ArduinoBlocks:
--    inicializar = bloques de configuración (se muestran fijos, de contexto)
--    bucle       = bloques del bucle principal (ESTOS son los que se ACOMODAN)
--
--  bucle: lista EN ORDEN CORRECTO (el juego los baraja).
--  patronCorrecto: secuencia de "simbolo" correcta (símbolos iguales = intercambiables).
--
--  Colores estilo ArduinoBlocks:
--    DIG=azul (E/S), TIME=naranja (tiempo), SER=verde agua (serial),
--    CON=morado (control/condicional), VAR=rojo (variables), SET=gris (configuración)
--=====================================================================

local DIG  = {52, 152, 219}
local TIME = {230, 126, 34}
local SER  = {26, 188, 156}
local CON  = {155, 89, 182}
local VAR  = {231, 76, 60}
local SET  = {120, 130, 140}

local mapa = {}

mapa["blink"] = {
	titulo = "Parpadear el LED (Blink)",
	descripcion = "En el bucle: enciende el LED, espera, apágalo y espera.",
	puntos = 10, poder = 1,
	inicializar = {
		{ texto="configurar pin 13 como SALIDA", color=SET },
	},
	bucle = {
		{ id="on",  texto="escribir pin digital 13 → HIGH", simbolo="ON13",  color=DIG },
		{ id="w1",  texto="esperar 1000 milisegundos",       simbolo="WAIT",  color=TIME },
		{ id="off", texto="escribir pin digital 13 → LOW",  simbolo="OFF13", color=DIG },
		{ id="w2",  texto="esperar 1000 milisegundos",       simbolo="WAIT",  color=TIME },
	},
	patronCorrecto = { "ON13", "WAIT", "OFF13", "WAIT" },
}

mapa["serial_led"] = {
	titulo = "LED con consola serial",
	descripcion = "En el bucle: envía un aviso por serial, enciende el LED y espera.",
	puntos = 15, poder = 2,
	inicializar = {
		{ texto="configurar pin 13 como SALIDA", color=SET },
		{ texto="Puerto serie: iniciar (9600)",  color=SER },
	},
	bucle = {
		{ id="prt", texto='Puerto serie: enviar "Encendiendo LED"', simbolo="SPRINT", color=SER },
		{ id="on",  texto="escribir pin digital 13 → HIGH",         simbolo="ON13",   color=DIG },
		{ id="w",   texto="esperar 1000 milisegundos",              simbolo="WAIT",   color=TIME },
	},
	patronCorrecto = { "SPRINT", "ON13", "WAIT" },
}

mapa["alternar"] = {
	titulo = "Dos LEDs alternando",
	descripcion = "Enciende y apaga el LED 13, luego el LED 12 (efecto alternado).",
	puntos = 20, poder = 3,
	inicializar = {
		{ texto="configurar pin 13 como SALIDA", color=SET },
		{ texto="configurar pin 12 como SALIDA", color=SET },
	},
	bucle = {
		{ id="on13", texto="escribir pin digital 13 → HIGH", simbolo="ON13",  color=DIG },
		{ id="w1",   texto="esperar 500 milisegundos",        simbolo="WAIT",  color=TIME },
		{ id="of13", texto="escribir pin digital 13 → LOW",  simbolo="OFF13", color=DIG },
		{ id="on12", texto="escribir pin digital 12 → HIGH", simbolo="ON12",  color=DIG },
		{ id="w2",   texto="esperar 500 milisegundos",        simbolo="WAIT",  color=TIME },
		{ id="of12", texto="escribir pin digital 12 → LOW",  simbolo="OFF12", color=DIG },
	},
	patronCorrecto = { "ON13", "WAIT", "OFF13", "ON12", "WAIT", "OFF12" },
}

mapa["secuencia3"] = {
	titulo = "Secuencia de 3 LEDs",
	descripcion = "Enciende los LEDs 11, 12 y 13 uno tras otro (efecto barrido).",
	puntos = 25, poder = 4,
	inicializar = {
		{ texto="configurar pines 11, 12 y 13 como SALIDA", color=SET },
	},
	bucle = {
		{ id="on11", texto="escribir pin digital 11 → HIGH", simbolo="ON11", color=DIG },
		{ id="w1",   texto="esperar 300 milisegundos",        simbolo="WAIT", color=TIME },
		{ id="on12", texto="escribir pin digital 12 → HIGH", simbolo="ON12", color=DIG },
		{ id="w2",   texto="esperar 300 milisegundos",        simbolo="WAIT", color=TIME },
		{ id="on13", texto="escribir pin digital 13 → HIGH", simbolo="ON13", color=DIG },
		{ id="w3",   texto="esperar 300 milisegundos",        simbolo="WAIT", color=TIME },
	},
	patronCorrecto = { "ON11", "WAIT", "ON12", "WAIT", "ON13", "WAIT" },
}

mapa["semaforo_corto"] = {
	titulo = "Semáforo corto (verde/rojo)",
	descripcion = "Verde: enciende, espera, apaga. Luego rojo: enciende, espera, apaga.",
	puntos = 30, poder = 5,
	inicializar = {
		{ texto="configurar LED VERDE y LED ROJO como SALIDA", color=SET },
	},
	bucle = {
		{ id="onv", texto="LED VERDE → HIGH",         simbolo="ONV",  color=DIG },
		{ id="w1",  texto="esperar 2000 milisegundos", simbolo="WAIT", color=TIME },
		{ id="ofv", texto="LED VERDE → LOW",          simbolo="OFFV", color=DIG },
		{ id="onr", texto="LED ROJO → HIGH",          simbolo="ONR",  color=DIG },
		{ id="w2",  texto="esperar 2000 milisegundos", simbolo="WAIT", color=TIME },
		{ id="ofr", texto="LED ROJO → LOW",           simbolo="OFFR", color=DIG },
	},
	patronCorrecto = { "ONV", "WAIT", "OFFV", "ONR", "WAIT", "OFFR" },
}

mapa["led_pulsador"] = {
	titulo = "LED con pulsador (condicional SI)",
	descripcion = "Lee el pulsador. SI está presionado, enciende el LED; SINO, apágalo.",
	puntos = 35, poder = 6,
	inicializar = {
		{ texto="configurar pin 13 como SALIDA",           color=SET },
		{ texto="configurar pin 2 como ENTRADA (pulsador)", color=SET },
	},
	bucle = {
		{ id="rd",  texto="leer pin digital 2 (pulsador)",  simbolo="READ",  color=DIG },
		{ id="if",  texto="si <pulsador = HIGH> hacer",     simbolo="IF",    color=CON },
		{ id="on",  texto="   escribir pin 13 → HIGH",      simbolo="ON13",  color=DIG },
		{ id="els", texto="si no (sino)",                   simbolo="ELSE",  color=CON },
		{ id="off", texto="   escribir pin 13 → LOW",       simbolo="OFF13", color=DIG },
	},
	patronCorrecto = { "READ", "IF", "ON13", "ELSE", "OFF13" },
}

mapa["semaforo_completo"] = {
	titulo = "Semáforo completo",
	descripcion = "Verde → Amarillo → Rojo. Cada uno: encender, esperar y apagar.",
	puntos = 40, poder = 7,
	inicializar = {
		{ texto="configurar VERDE, AMARILLO y ROJO como SALIDA", color=SET },
	},
	bucle = {
		{ id="onv", texto="LED VERDE → HIGH",         simbolo="ONV",  color=DIG },
		{ id="w1",  texto="esperar 2000 milisegundos", simbolo="WAIT", color=TIME },
		{ id="ofv", texto="LED VERDE → LOW",          simbolo="OFFV", color=DIG },
		{ id="ona", texto="LED AMARILLO → HIGH",      simbolo="ONA",  color=DIG },
		{ id="w2",  texto="esperar 1000 milisegundos", simbolo="WAIT", color=TIME },
		{ id="ofa", texto="LED AMARILLO → LOW",       simbolo="OFFA", color=DIG },
		{ id="onr", texto="LED ROJO → HIGH",          simbolo="ONR",  color=DIG },
		{ id="w3",  texto="esperar 2000 milisegundos", simbolo="WAIT", color=TIME },
		{ id="ofr", texto="LED ROJO → LOW",           simbolo="OFFR", color=DIG },
	},
	patronCorrecto = { "ONV","WAIT","OFFV","ONA","WAIT","OFFA","ONR","WAIT","OFFR" },
}

mapa["semaforo_peatonal"] = {
	titulo = "Semáforo peatonal",
	descripcion = "SI el peatón pulsa: pon rojo a los autos, deja pasar al peatón y regresa.",
	puntos = 45, poder = 8,
	inicializar = {
		{ texto="configurar LEDs (autos y peatón) como SALIDA", color=SET },
		{ texto="configurar pulsador como ENTRADA",             color=SET },
	},
	bucle = {
		{ id="rd",  texto="leer pulsador del peatón",       simbolo="READ",  color=DIG },
		{ id="if",  texto="si <peatón presionó> hacer",     simbolo="IF",    color=CON },
		{ id="onr", texto="   ROJO (autos) → HIGH",         simbolo="ONR",   color=DIG },
		{ id="w1",  texto="   esperar 1000 ms",             simbolo="WAIT",  color=TIME },
		{ id="onp", texto="   VERDE (peatón) → HIGH",       simbolo="ONVP",  color=DIG },
		{ id="w2",  texto="   esperar 3000 ms",             simbolo="WAIT",  color=TIME },
		{ id="ofp", texto="   VERDE (peatón) → LOW",        simbolo="OFFVP", color=DIG },
		{ id="ofr", texto="   ROJO (autos) → LOW",          simbolo="OFFR",  color=DIG },
	},
	patronCorrecto = { "READ","IF","ONR","WAIT","ONVP","WAIT","OFFVP","OFFR" },
}

mapa["variable_led"] = {
	titulo = "LED con variable",
	descripcion = "Ya creamos la variable 'led'. En el bucle úsala para parpadear.",
	puntos = 50, poder = 9,
	inicializar = {
		{ texto="número entero  led = 13",           color=VAR },
		{ texto="configurar pin (led) como SALIDA",  color=SET },
	},
	bucle = {
		{ id="on",  texto="escribir pin (led) → HIGH", simbolo="ONVAR",  color=DIG },
		{ id="w1",  texto="esperar 1000 milisegundos",  simbolo="WAIT",   color=TIME },
		{ id="off", texto="escribir pin (led) → LOW",  simbolo="OFFVAR", color=DIG },
		{ id="w2",  texto="esperar 1000 milisegundos",  simbolo="WAIT",   color=TIME },
	},
	patronCorrecto = { "ONVAR", "WAIT", "OFFVAR", "WAIT" },
}

mapa["semaforo_inteligente"] = {
	titulo = "Semáforo inteligente",
	descripcion = "En el bucle: lee el sensor en un booleano. SI hay auto, pon verde; SINO, rojo.",
	puntos = 60, poder = 10,
	inicializar = {
		{ texto="configurar VERDE y ROJO como SALIDA", color=SET },
		{ texto="configurar sensor como ENTRADA",      color=SET },
	},
	bucle = {
		{ id="var", texto="booleano hayAuto = leer sensor", simbolo="VARBOOL", color=VAR },
		{ id="if",  texto="si <hayAuto = verdadero> hacer",  simbolo="IF",      color=CON },
		{ id="onv", texto="   LED VERDE → HIGH",             simbolo="ONV",     color=DIG },
		{ id="els", texto="si no (sino)",                    simbolo="ELSE",    color=CON },
		{ id="onr", texto="   LED ROJO → HIGH",              simbolo="ONR",     color=DIG },
		{ id="w",   texto="esperar 1000 milisegundos",       simbolo="WAIT",    color=TIME },
	},
	patronCorrecto = { "VARBOOL", "IF", "ONV", "ELSE", "ONR", "WAIT" },
}

local orden = {
	"blink", "serial_led", "alternar", "secuencia3", "semaforo_corto",
	"led_pulsador", "semaforo_completo", "semaforo_peatonal", "variable_led", "semaforo_inteligente",
}

return { mapa = mapa, orden = orden }
