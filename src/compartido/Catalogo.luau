--=====================================================================
--  CATÁLOGO DE LA TIENDA (se canjea con los puntos personales)
--  Gastar puntos NO baja el puntaje del equipo.
--  tipo:  "arma"        -> es tuya para siempre (no se pierde al morir)
--         "mejora"      -> permanente, se puede comprar hasta "max" veces
--         "consumible"  -> se usa al momento
--  Para cambiar precios o quitar algo, edita esta lista.
--=====================================================================

return {
	{ id = "Botiquin", tipo = "consumible", icono = "🩹", nombre = "Botiquín",
	  precio = 60, desc = "Recupera toda tu vida al instante." },
	{ id = "Escudo", tipo = "consumible", icono = "🛡️", nombre = "Escudo de energía",
	  precio = 150, desc = "15 segundos sin recibir daño." },
	{ id = "Torreta", tipo = "consumible", icono = "🗼", nombre = "Torreta Arduino",
	  precio = 400, desc = "Una torreta con sensor ultrasónico que dispara a los robots por 45 s." },
	{ id = "Blindaje", tipo = "mejora", icono = "🦺", nombre = "Blindaje +50",
	  precio = 200, max = 4, desc = "+50 de vida máxima para siempre (hasta 4 veces)." },
	{ id = "Escopeta", tipo = "arma", icono = "🔫", nombre = "Escopeta de chispas",
	  precio = 300, desc = "7 perdigones. Tuya para siempre." },
	{ id = "Granada", tipo = "arma", icono = "💣", nombre = "Granada condensador",
	  precio = 350, desc = "Rebota y explota. Tuya para siempre." },
	{ id = "Tesla", tipo = "arma", icono = "⚡", nombre = "Pistola Tesla",
	  precio = 450, desc = "Rayo que salta entre robots. Tuya para siempre." },
	{ id = "Laser", tipo = "arma", icono = "🔦", nombre = "Láser",
	  precio = 800, desc = "Sin tener que resolver el reto 6." },
	{ id = "Bazuca", tipo = "arma", icono = "🚀", nombre = "Bazuca M1",
	  precio = 900, desc = "Sin tener que resolver el reto 4." },
}
