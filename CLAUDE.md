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
  - `componentes.js`, `final.js`, `avatar.js`, `profe.js`, `info.js`, `red.js`, `pvp.js`: piezas, gran final, cuerpos de jugadores, modo profe, información, multijugador y pelea entre jugadores.
  - `runas.js`, `poderes.js`, `preguntas.js`, `retos.js`, `tienda.js`, `hud.js`, `main.js`: runas, poderes, preguntas, Estación Arduino, Tienda, HUD y arranque con el bucle principal.
- `web/datos/`: datos generados (no editar a mano). `base-equipo.js` sale del .rbxl con `herramientas/rbxl/` y `componentes.js` de los modelos de Tinkercad con `herramientas/modelos/convertir.mjs`.
- `web/modelos/jefe-final.glb`: Mech Robot "KW-II" de nick_bragg (CC BY 4.0), comprimido con gltf-transform (meshopt + webp).
- `servidor/`: servidor de salas (Node + `ws`).
- `src/`: versión Roblox original (Luau + Rojo), solo como referencia de datos: retos, poderes, catálogo, robots.

## Cómo es el juego
- **Historia:** el mago ARDUNOL creó un robot malvado con el arma ARDUINO SUPREMO para destruir el último bastión del Reino Tecnológico.
- **Partida:** 8 oleadas (3 MEGA-ARDUINO, 4 drones, 5 robot morado, 8 ARDUNOL DESATADO). Mientras vive el jefe final, manda refuerzos.
- **Tiempo libre entre oleadas:** 1 minuto (`Oleadas.DESCANSO = 60`) para pelear contra otros equipos y resolver retos. Se anuncia al empezar ("⏱ 1 MINUTO DE TIEMPO LIBRE"), arriba se ve la cuenta y avisa cuando quedan 10 s (`Oleadas.hudDescanso`).
- **Final (`final.js`):** cuando cae ARDUNOL DESATADO sus robots explotan → se anuncia el **equipo ganador** (el de más puntos entre los equipos con alumnos) → **gran final**: los alumnos aparecen repartidos en un círculo alrededor de la plaza (alternando equipos), cuenta de 5 s y **todos contra todos, incluso el mismo equipo**. Quien cae queda eliminado y mira desde arriba (WASD). El último en pie se lleva el ARDUINO SUPREMO (flota sobre el pedestal de la plaza). Pantalla final: equipo ganador + jugador que tomó el Arduino. El profe mira volando y tiene en F1 "🏁 Terminar la gran final ya" (gana el de más vida). Con 0 o 1 alumno no hay pelea.
- **Pelea entre jugadores (`pvp.js`):** durante la partida se puede derribar a alumnos de **otros equipos** (no al propio). El profe no recibe ni hace daño. A un jugador se le hace el 60 % del daño de un robot (`PVP.DANO`); derribar a un rival da +25 al equipo (`PVP.PUNTOS_BAJA`).
- **Cada base tiene:**
  - Adentro: la Estación Arduino (pared derecha), con 10 retos de bloques que dan poderes y preguntas que dan puntos.
  - Adentro: la Tienda (pared izquierda), donde se canjea `G.canje`; gastar no baja el puntaje del equipo.
  - Afuera: el anillo de entrega de las 9 piezas del robot seguidor y la ametralladora fija.
- **Puntos:** `G.puntos` es el puntaje del equipo, `G.canje` lo personal para canjear y `G.puntosEq[6]` el puntaje por equipo. Se empieza con 300 de regalo para canjear.
- **Modo profe:** se entra con "👑 Soy profe" y la clave. El profe juega y no puede caer. Con F1 abre su panel: dificultad en tiempo real, **nivel de retos y preguntas**, abrir rejas, pausar a todos, pregunta, curar, +50, ir a una base, volar, sacar alumno, terminar la gran final y lista de alumnos.
- **Nivel de retos y preguntas (`Profe.nivelRetos`, se manda en el `snap`):** 🟢 Fácil (por defecto: `RETOS_FACILES`, 3 bloques con los pasos en orden; preguntas `n: 0`) · 🟡 Difícil (retos completos + `PISTAS_RETOS` + marca ✅/❌ por bloque al probar; preguntas `n` ≤ 1) · 🔴 Complicado (retos originales sin ayuda; todas las preguntas originales). Las preguntas con `extra: true` son las sencillas agregadas para Fácil.
- **Tecla I:** abre el menú de información (`info.js`, armado con los datos reales).

## Multijugador (`red.js` + `servidor/`)
- **Salas:** el profe crea la sala (el servidor revisa la clave) y recibe un código de 4 números. Los alumnos entran con ese código.
- **Quién manda:** la pestaña del profe es la **anfitriona**. Mueve robots y oleadas y manda una foto (`snap`) 10 veces por segundo. Los alumnos dibujan esos robots (`r.remoto`) y les mandan su daño al profe (`ev dano`). Los robots del profe persiguen al jugador más cercano (`OBJ`, `jugadoresVivos()` en `robots.js`).
- **Daño entre jugadores:** el servidor solo deja hablar alumno ↔ profe, así que va por el profe: el que dispara manda `ev pvp` → el profe lo revisa (`PVP.reenviar`) y le manda `herido` al otro → si cae, el herido manda `baja` (`PVP.baja`: feed, puntos y eliminación en la gran final). Eventos del final: `finGanador`, `arena` (lugares de cada uno), `campeon`.
- **Esc en línea:** abre un menú pero no pausa. Solo el profe pausa a todos.
- **Pendientes posibles:**
  - Reconexión con progreso guardado: hoy, si un alumno sale y vuelve, pierde puntos para canjear, poderes y retos, y recibe otra vez el regalo.
  - Compartir piezas y runas entre la sala: hoy son locales de cada jugador.
  - Efectos de disparo como los del bláster para las demás armas.
