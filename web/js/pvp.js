// =====================================================================
//  PELEA ENTRE JUGADORES (PvP)
//  - Durante la partida: puedes derribar a los alumnos de OTROS equipos.
//    A los de tu equipo no les pasa nada. El profe no recibe ni hace daño.
//  - En la gran final (final.js): todos contra todos, incluso tu equipo.
//  Cómo viaja el daño (el servidor solo deja hablar alumno ↔ profe):
//    el alumno que dispara ve el golpe en su pantalla → se lo avisa al
//    profe (ev 'pvp') → la computadora del profe revisa que valga y se lo
//    pasa al herido (ev 'herido') → si cae, el herido avisa (ev 'baja').
// =====================================================================
const PVP = {
  DANO: 0.6,          // a un jugador le haces el 60 % del daño que le harías a un robot
  PUNTOS_BAJA: 25,    // derribar a un rival da puntos a tu equipo (en la gran final no)

  // ¿puedo hacerle daño a este jugador de la sala?
  atacable(j) {
    if (!j || !j.listo || j.muerto || j.profe || G.profe) return false;
    if (Final.todosContraTodos()) return Final.combate;
    if (Final.estado) return false;   // cayó el jefe: hasta que empiece la gran final no se pelea
    return j.equipo !== MI_EQUIPO;
  },
  objetivos() { return Red.activa ? Red.proxies().filter((j) => this.atacable(j)) : []; },
  mallas() { return this.objetivos().map((j) => j.av.raiz); }, // para los rayos de las armas

  // tú le haces daño al jugador j (se ve al instante; el daño real lo pasa el profe)
  danar(j, cant, punto, critico) {
    if (!this.atacable(j)) return;
    cant = Math.max(1, Math.round(cant * this.DANO * G.mods.dano));
    HUD.numero(punto || j.centro(), cant, critico); Sfx.play('golpeRobot'); HUD.hit(false);
    const o = Jugador.pos;
    Red.ev({ a: 'pvp', id: j.id, c: cant, x: +o.x.toFixed(1), y: +o.y.toFixed(1), z: +o.z.toFixed(1) }, 'host');
  },
  // bazuca y granada
  explosion(pos, a) {
    for (const j of this.objetivos()) {
      const d = j.centro().distanceTo(pos) - 0.3;
      if (d < a.radio) this.danar(j, a.dano * (1 - 0.5 * clamp(d / a.radio, 0, 1)), j.centro(), false);
    }
  },
  // ¿un cohete o una granada chocó con un jugador?
  toca(pos, r) { return this.objetivos().some((j) => j.centro().distanceTo(pos) < r); },

  // ---------- en la computadora del profe ----------
  // el alumno "de" le pegó al alumno e.id: se revisa y se le pasa al herido
  reenviar(e, de) {
    const atacante = Red.remotos.get(de), victima = Red.remotos.get(e.id);
    if (!atacante || !victima || atacante === victima || atacante.profe || victima.profe) return;
    const vale = Final.todosContraTodos() ? Final.combate : !Final.estado && atacante.equipo !== victima.equipo;
    if (!vale) return;
    Red.ev({ a: 'herido', c: clamp(+e.c || 0, 0, 150), x: +e.x || 0, y: +e.y || 0, z: +e.z || 0, tp: 'jugador', de, q: atacante.nombre }, victima.id);
  },
  // el alumno "de" cayó (e.por = quién lo derribó, 0 si fue otra cosa)
  baja(e, de) {
    const caido = Red.remotos.get(de), autor = Red.remotos.get(e.por);
    if (!caido) return;
    const nom = (j) => '<b style="color:' + EQUIPOS[j.equipo].color + '">' + j.nombre + '</b>';
    let txt = '💀 ' + nom(caido) + ' cayó';
    if (autor && autor !== caido) {
      txt = '⚔️ ' + nom(autor) + ' derribó a ' + nom(caido);
      if (!Final.todosContraTodos() && autor.equipo !== caido.equipo) {
        G.puntosEq[autor.equipo] += this.PUNTOS_BAJA;
        if (autor.equipo === MI_EQUIPO) { G.puntos += this.PUNTOS_BAJA; HUD.puntos(); }
        Red.ev({ a: 'ganaste', n: this.PUNTOS_BAJA, q: caido.nombre }, autor.id);
      }
    }
    HUD.feed(txt); Red.ev({ a: 'feed', txt });
    Final.alCaer(caido); // en la gran final queda eliminado
  },
};
