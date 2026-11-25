--=====================================================================
--  PODERES (metadatos: nombre, ícono, descripción)
--  El efecto real de cada uno se aplica en el servidor (Poderes.server).
--  "estado" indica si su efecto ya está implementado o viene después.
--=====================================================================

return {
	[1]  = { nombre = "Pistola",              icono = "🔫", desc = "Desbloqueas el arma básica.",           estado = "activo" },
	[2]  = { nombre = "Armadura +100",        icono = "🛡️", desc = "+100 de vida máxima.",                  estado = "activo" },
	[3]  = { nombre = "Correr",               icono = "🏃", desc = "Te mueves más rápido.",                 estado = "activo" },
	[4]  = { nombre = "Bazuca",               icono = "🚀", desc = "Lanzacohetes con explosión en área.",   estado = "activo" },
	[5]  = { nombre = "Punto de regeneración",icono = "♻️", desc = "Cura a tu equipo en tu base.",           estado = "activo" },
	[6]  = { nombre = "Láser",                icono = "🔦", desc = "Rayo instantáneo de alto daño.",         estado = "activo" },
	[7]  = { nombre = "Punto de armadura",    icono = "🛡️", desc = "+150 de vida máxima.",                  estado = "activo" },
	[8]  = { nombre = "Armadura +200",        icono = "🛡️", desc = "+200 de vida máxima.",                  estado = "activo" },
	[9]  = { nombre = "Volar",                icono = "🕊️", desc = "Puedes volar.",                          estado = "proximamente" },
	[10] = { nombre = "Doble daño",           icono = "⚔️", desc = "Tus armas hacen el doble de daño.",     estado = "proximamente" },
}
