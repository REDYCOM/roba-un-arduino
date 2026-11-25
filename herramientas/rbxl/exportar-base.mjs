// Exporta la base de equipo (BaseEquipo2, sin rotación) a web/datos/base-equipo.js
// en coordenadas locales: origen = parte de abajo del TeamSpawn, unidades = studs.
// Uso: node exportar-base.mjs "archivo.rbxl"
import fs from 'node:fs';
import path from 'node:path';
import { leerRbxl } from './leer-rbxl.mjs';

const inst = leerRbxl(process.argv[2]);
const todas = Object.values(inst);
const base = todas.find((i) => i.props.Name === 'BaseEquipo2');
const partes = [];
const rec = (i) => { if (i.props.CFrame && i.props.size) partes.push(i); i.hijos.forEach((h) => rec(inst[h])); };
rec(base);
const spawn = partes.find((p) => p.props.Name === 'TeamSpawn');
const o = spawn.props.CFrame.p, alto = spawn.props.size[1];
const r3 = (v) => Math.round(v * 1000) / 1000;
const salida = partes.filter((p) => p !== spawn && (p.props.Transparency ?? 0) < 1).map((p) => ({
  n: p.props.Name, k: p.clase,
  s: p.props.size.map(r3),
  p: [p.props.CFrame.p[0] - o[0], p.props.CFrame.p[1] - (o[1] - alto / 2), p.props.CFrame.p[2] - o[2]].map(r3),
  r: p.props.CFrame.r.map(r3),
  c: p.props.Color3uint8,
  m: p.props.Material,
  f: p.props.shape ?? 1,
  t: r3(p.props.Transparency ?? 0),
  g: inst[p.padre]?.props.Name === base.props.Name ? undefined : inst[p.padre]?.props.Name,
}));
const destino = path.resolve(import.meta.dirname, '../../web/datos/base-equipo.js');
fs.mkdirSync(path.dirname(destino), { recursive: true });
fs.writeFileSync(destino, '// Generado por herramientas/rbxl/exportar-base.mjs - no editar a mano\n' +
  'window.DATOS_BASE = ' + JSON.stringify({ origen: 'BaseEquipo (ROBA UN ARDUINO 3.rbxl)', partes: salida }) + ';\n');
console.log('Base exportada:', salida.length, 'piezas →', destino);
const ys = salida.map((p) => [p.p[1] - p.s[1] / 2, p.p[1] + p.s[1] / 2]).flat();
console.log('rango Y', Math.min(...ys), Math.max(...ys));
