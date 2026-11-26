// =====================================================================
//  SERVIDOR DE SALAS — Roba un Arduino (multijugador)
//  - El profe crea una sala con su clave (se revisa aquí, no en el navegador)
//    y recibe un código de 4 números; los alumnos entran con ese código.
//  - La computadora del profe es la "anfitriona": mueve los robots y las
//    oleadas y manda una foto del estado 10 veces por segundo.
//  - El servidor solo administra las salas y reenvía mensajes:
//      · "yo"   (cada jugador, ~10/s) → se juntan y se mandan en un paquete cada 100 ms
//      · "snap" (solo el profe)       → a todos los alumnos
//      · "ev"   (eventos)             → alumno → profe · profe → un alumno o todos
//  Local:  node servidor.mjs   (puerto 8090)    En Render: usa la variable PORT
// =====================================================================
import { createServer } from 'node:http';
import { createHash, randomInt } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { WebSocketServer } from 'ws';

const PUERTO = process.env.PORT || 8090;
const MAX_JUGADORES = 31; // 30 alumnos + el profe
const huella = () => JSON.parse(readFileSync(new URL('./clave.json', import.meta.url), 'utf8')).huella;

const salas = new Map(); // código → { codigo, host, jugadores: Map(id → ws), ultimos: Map(id → datos) }
let sigId = 1;

const http = createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'text/plain; charset=utf-8', 'access-control-allow-origin': '*' });
  res.end('Servidor de Roba un Arduino funcionando ✔  ·  salas abiertas: ' + salas.size);
});
const wss = new WebSocketServer({ server: http, maxPayload: 64 * 1024 });

const limpiarNombre = (s) => String(s || '').replace(/[^\p{L}\p{N} _.-]/gu, '').replace(/\s+/g, ' ').trim().slice(0, 14) || 'Jugador';
const limpiarColor = (c) => (/^#[0-9a-f]{6}$/i.test(c) ? c : '#36c5ff');
const limpiarEquipo = (e) => Math.min(5, Math.max(0, Math.floor(Number(e) || 0)));
const enviar = (ws, m) => { if (ws.readyState === 1) ws.send(typeof m === 'string' ? m : JSON.stringify(m)); };
const aTodos = (sala, m, excepto) => { const s = JSON.stringify(m); for (const ws of sala.jugadores.values()) if (ws !== excepto) enviar(ws, s); };
const nuevoCodigo = () => { let c; do { c = String(randomInt(1000, 10000)); } while (salas.has(c)); return c; };
const datosDe = (ws) => ({ id: ws.id, nombre: ws.nombre, color: ws.color, equipo: ws.equipo, profe: !!ws.profe });

function entrar(ws, sala, m, profe) {
  ws.sala = sala; ws.nombre = limpiarNombre(m.nombre); ws.color = limpiarColor(m.color); ws.equipo = limpiarEquipo(m.equipo); ws.profe = profe;
  const otros = [...sala.jugadores.values()].map(datosDe);
  sala.jugadores.set(ws.id, ws);
  enviar(ws, { t: 'sala', codigo: sala.codigo, id: ws.id, host: profe, jugadores: otros });
  aTodos(sala, { t: 'entra', j: datosDe(ws) }, ws);
}

function salir(ws) {
  const sala = ws.sala; if (!sala) return;
  ws.sala = null;
  sala.jugadores.delete(ws.id); sala.ultimos.delete(ws.id);
  if (sala.host === ws) {
    // se fue el profe: se cierra la sala
    for (const o of sala.jugadores.values()) { enviar(o, { t: 'cerrada' }); o.sala = null; }
    salas.delete(sala.codigo);
    console.log('sala cerrada', sala.codigo);
  } else aTodos(sala, { t: 'sale', id: ws.id });
}

wss.on('connection', (ws) => {
  ws.id = sigId++; ws.vivo = true; ws.cuota = 0;
  ws.on('pong', () => { ws.vivo = true; });
  ws.on('close', () => salir(ws));
  ws.on('message', (crudo) => {
    if (++ws.cuota > 150) return; // máximo ~150 mensajes por segundo por jugador
    let m; try { m = JSON.parse(crudo); } catch { return; }
    if (!m || typeof m.t !== 'string') return;
    const sala = ws.sala;
    switch (m.t) {
      case 'crear': {
        if (sala) return;
        const h = createHash('sha256').update('roba-un-arduino:' + String(m.clave || '').trim()).digest('hex');
        if (h !== huella()) { enviar(ws, { t: 'error', e: 'clave' }); return; }
        const nueva = { codigo: nuevoCodigo(), host: ws, jugadores: new Map(), ultimos: new Map() };
        salas.set(nueva.codigo, nueva);
        entrar(ws, nueva, m, true);
        console.log('sala creada', nueva.codigo);
        return;
      }
      case 'unirse': {
        if (sala) return;
        const s = salas.get(String(m.codigo || '').trim());
        if (!s) { enviar(ws, { t: 'error', e: 'nosala' }); return; }
        if (s.jugadores.size >= MAX_JUGADORES) { enviar(ws, { t: 'error', e: 'llena' }); return; }
        entrar(ws, s, m, false);
        return;
      }
      case 'yo': if (sala && Array.isArray(m.d)) sala.ultimos.set(ws.id, m.d.slice(0, 20)); return;
      case 'snap': if (sala && sala.host === ws) for (const o of sala.jugadores.values()) if (o !== ws) enviar(o, crudo.toString()); return;
      case 'ev': {
        if (!sala || !m.e || typeof m.e !== 'object') return;
        const msg = { t: 'ev', de: ws.id, e: m.e };
        if (sala.host !== ws) { enviar(sala.host, msg); return; }   // un alumno solo le habla al profe
        if (m.para) { const o = sala.jugadores.get(m.para); if (o) enviar(o, msg); }
        else aTodos(sala, msg, ws);
        return;
      }
      case 'sacar': {
        if (!sala || sala.host !== ws) return;
        const o = sala.jugadores.get(m.id);
        if (o && o !== ws) { enviar(o, { t: 'expulsado' }); salir(o); setTimeout(() => o.close(), 200); }
        return;
      }
    }
  });
});

// cada 100 ms: paquete con la posición de todos los jugadores de cada sala
setInterval(() => {
  for (const sala of salas.values()) {
    if (!sala.ultimos.size) continue;
    const msg = JSON.stringify({ t: 'js', l: [...sala.ultimos.entries()] });
    sala.ultimos.clear();
    for (const ws of sala.jugadores.values()) enviar(ws, msg);
  }
}, 100);
setInterval(() => { for (const ws of wss.clients) ws.cuota = 0; }, 1000);
// latido: corta conexiones muertas
setInterval(() => {
  for (const ws of wss.clients) { if (!ws.vivo) { ws.terminate(); continue; } ws.vivo = false; ws.ping(); }
}, 25000);

http.listen(PUERTO, () => console.log('Servidor de Roba un Arduino en el puerto ' + PUERTO));
