# Roba un Arduino — guía para Claude

Juego educativo de Arduino: un shooter por equipos en 3D en el navegador (Three.js).
El profe lo usa en clase con hasta 30 alumnos (6 equipos de 5).
Empezó como juego de Roblox (`src/`); se pasó a la web por las restricciones de edad de Roblox.

## Reglas para trabajar en este proyecto
- **Responder SIEMPRE en español**: mensajes, explicaciones, preguntas y botones. El usuario es profe, no programador.
- **Comentarios y nombres del código en español** (como todo el código existente).
- **No copiar personajes ni modelos de otros juegos o franquicias** (Fortnite, LEGO, Plants vs. Zombies/Zombot/Dr. Zomboss, mapas de Roblox, etc.), aunque estén "gratis" en Sketchfab. Solo modelos con diseño propio del autor y licencia CC0 o CC BY. Los CC BY van en la pantalla de Créditos (`index.html`, `#creditos`).
- **Commits:** el correo de git del repo es el privado de GitHub (`…@users.noreply.github.com`). No usar otro correo.
- **Clave del profe:** nunca escribirla en el código ni en el chat. Se cambia con `node herramientas/clave-profe.mjs "clave"`, que guarda solo su huella SHA-256 en `web/js/profe.js` y `servidor/clave.json`.

## Dónde está publicado
- **Juego:** https://redycom.github.io/roba-un-arduino/ (GitHub Pages). `.github/workflows/publicar.yml` publica la carpeta `web/` en cada push a `main`. Si falla con "No artifacts named github-pages", es una falla pasajera de GitHub: volver a correr el workflow.
- **Servidor multijugador:** https://roba-un-arduino.onrender.com (Render, plan gratis, `render.yaml`). Se actualiza solo con cada push. Se duerme tras 15 min sin uso y tarda ~1 min en despertar.
- **Repositorio:** https://github.com/REDYCOM/roba-un-arduino (público).

## Probar en local
- Juego: `web/JUGAR.bat` (o `web/servidor.ps1`), que abre un servidor en http://localhost:8080. También existe `.claude/launch.json` (config "juego-web").
- Servidor de salas: `cd servidor && npm install && node servidor.mjs` (puerto 8090). En localhost el juego se conecta a `ws://localhost:8090`; publicado usa Render (constante `SERVIDOR` en `web/js/red.js`).

## Estructura
- `web/index.html`: menús, HUD y ventanas. Carga Three.js r160 por CDN (importmap) y luego los scripts **clásicos en orden**, que comparten el espacio global (`window.THREE`, `window.ADD` con los addons).
- `web/js/` (en el orden de carga):
  - `core.js`: estado `G`, utilidades, entrada, colisiones y la tabla `PUNTOS`.
  - `audio.js`, `world.js`, `fx.js`, `player.js`, `weapons.js`, `torretas.js`: mundo, efectos, jugador, armas y ametralladora fija.
  - `modelos-robots.js`, `terror.js`, `jefe-mech.js`, `robots.js`: robots, IA, `Oleadas` y el jefe final.
  - `componentes.js`, `final.js`, `avatar.js`, `profe.js`, `info.js`, `red.js`: piezas, gran final, cuerpos de jugadores, modo profe, información y multijugador.
  - `runas.js`, `poderes.js`, `preguntas.js`, `retos.js`, `tienda.js`, `hud.js`, `main.js`: runas, poderes, preguntas, Estación Arduino, Tienda, HUD y arranque con el bucle principal.
- `web/datos/`: datos generados (no editar a mano). `base-equipo.js` sale del .rbxl con `herramientas/rbxl/` y `componentes.js` de los modelos de Tinkercad con `herramientas/modelos/convertir.mjs`.
- `web/modelos/jefe-final.glb`: Mech Robot "KW-II" de nick_bragg (CC BY 4.0), comprimido con gltf-transform (meshopt + webp).
- `servidor/`: servidor de salas (Node + `ws`).
- `src/`: versión Roblox original (Luau + Rojo), solo como referencia de datos: retos, poderes, catálogo, robots.

## Cómo es el juego
- **Historia:** el mago ARDUNOL creó un robot malvado con el arma ARDUINO SUPREMO para destruir el último bastión del Reino Tecnológico.
- **Partida:** 8 oleadas (3 MEGA-ARDUINO, 4 drones, 5 robot morado, 8 ARDUNOL DESATADO). Mientras vive el jefe final, manda refuerzos. Cuando cae, sus robots explotan y sale el Arduino como trofeo; se roba con E y se gana.
- **Cada base tiene:**
  - Adentro: la Estación Arduino (pared derecha), con 10 retos de bloques que dan poderes y preguntas que dan puntos.
  - Adentro: la Tienda (pared izquierda), donde se canjea `G.canje`; gastar no baja el puntaje del equipo.
  - Afuera: el anillo de entrega de las 9 piezas del robot seguidor y la ametralladora fija.
- **Puntos:** `G.puntos` es el puntaje del equipo, `G.canje` lo personal para canjear y `G.puntosEq[6]` el puntaje por equipo. Se empieza con 300 de regalo para canjear.
- **Modo profe:** se entra con "👑 Soy profe" y la clave. El profe juega y no puede caer. Con F1 abre su panel: dificultad en tiempo real, abrir rejas, pausar a todos, pregunta, curar, +50, ir a una base, volar, sacar alumno y lista de alumnos.
- **Tecla I:** abre el menú de información (`info.js`, armado con los datos reales).

## Multijugador (`red.js` + `servidor/`)
- **Salas:** el profe crea la sala (el servidor revisa la clave) y recibe un código de 4 números. Los alumnos entran con ese código.
- **Quién manda:** la pestaña del profe es la **anfitriona**. Mueve robots y oleadas y manda una foto (`snap`) 10 veces por segundo. Los alumnos dibujan esos robots (`r.remoto`) y les mandan su daño al profe (`ev dano`). Los robots del profe persiguen al jugador más cercano (`OBJ`, `jugadoresVivos()` en `robots.js`).
- **Esc en línea:** abre un menú pero no pausa. Solo el profe pausa a todos.
- **Pendientes posibles:**
  - Reconexión con progreso guardado: hoy, si un alumno sale y vuelve, pierde puntos para canjear, poderes y retos, y recibe otra vez el regalo.
  - Compartir piezas y runas entre la sala: hoy son locales de cada jugador.
  - Efectos de disparo como los del bláster para las demás armas.
