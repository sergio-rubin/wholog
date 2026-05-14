/**
 * WHOlog - Servidor API
 * Ejecuta consultas Prolog (SWI-Prolog) y expone endpoints REST.
 *
 * Requisitos: Node.js >= 18, swipl en el PATH
 * Arrancar: node server.js
 */

const http = require('http');
const { execFile } = require('child_process');
const path = require('path');
const { URL } = require('url');

const PORT = 3001;
const BASE_PL = path.join(__dirname, 'base.pl');

// ----------------------------------------------------------
// Ejecuta una consulta Prolog y devuelve el stdout como texto
// ----------------------------------------------------------
function runProlog(goal) {
  return new Promise((resolve, reject) => {
    const args = [
      '-g', `use_module(library(lists))`,
      '-g', goal,
      '-g', 'halt',
      BASE_PL,
    ];
    execFile('swipl', args, { timeout: 8000 }, (err, stdout, stderr) => {
      if (err && err.code !== 0 && !stdout) {
        return reject(new Error(stderr || err.message));
      }
      resolve(stdout.trim());
    });
  });
}

// ----------------------------------------------------------
// Convierte las restricciones recibidas del cliente
// a una lista Prolog: [attr(Pos,Val), ...]
// restricciones: [{atributo, valor}]
// ----------------------------------------------------------
function buildPrologRestrictions(restricciones) {
  const posMap = {
    universo: 2, mascara: 3, capa: 4, armas: 5,
    vuela: 6, humano: 7, genero: 8, equipo: 9,
    poder: 10, habitat: 11,
  };

  const terminos = (restricciones || []).map(r => {
    const pos = posMap[r.atributo];
    if (!pos) return null;
    // Valores booleanos deben ir sin comillas en Prolog
    const val = (r.valor === 'true' || r.valor === 'false')
      ? r.valor
      : r.valor;
    return `attr(${pos},${val})`;
  }).filter(Boolean);

  return `[${terminos.join(',')}]`;
}

// ----------------------------------------------------------
// Parsea el JSON que imprime estado_json/1 desde Prolog
// El predicado ya genera JSON válido directamente.
// ----------------------------------------------------------
function parsePrologJson(raw) {
  return JSON.parse(raw);
}

// ----------------------------------------------------------
// CORS helper
// ----------------------------------------------------------
function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

// ----------------------------------------------------------
// Lee el body de la request como JSON
// ----------------------------------------------------------
function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => { data += chunk; });
    req.on('end', () => {
      try { resolve(data ? JSON.parse(data) : {}); }
      catch (e) { reject(e); }
    });
    req.on('error', reject);
  });
}

// ----------------------------------------------------------
// Servidor HTTP
// ----------------------------------------------------------
const server = http.createServer(async (req, res) => {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsed = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = parsed.pathname;

  // ---- GET /personajes ----
  // Devuelve todos los personajes disponibles en la BD
  if (req.method === 'GET' && pathname === '/personajes') {
    try {
      const raw = await runProlog(
        'todos_los_personajes(L),lista_json(L)'
      );
      const lista = JSON.parse(raw);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ personajes: lista }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }

  // ---- GET /atributos ----
  // Devuelve los atributos disponibles con sus opciones
  if (req.method === 'GET' && pathname === '/atributos') {
    try {
      const raw = await runProlog(
        'findall(at(A,T,O),(atributo(A,_,T,O)),L),format("~w~n",[L])'
      );
      // Parsear lista de términos Prolog a JSON
      // Formato: [at(universo,enum,[dc,marvel]),...]
      const atributos = parsePrologAtributos(raw);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ atributos }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }

  // ---- POST /estado ----
  // Body: { restricciones: [{atributo, valor}] }
  // Devuelve: activos, descartados, mejor_pregunta, prolog_query
  if (req.method === 'POST' && pathname === '/estado') {
    try {
      const body = await readBody(req);
      const prologList = buildPrologRestrictions(body.restricciones);
      const goal = `estado_json(${prologList})`;
      const raw = await runProlog(goal);
      const resultado = parsePrologJson(raw);
      resultado.prolog_query = `?- estado_json(${prologList}).`;
      resultado.prolog_raw = raw;
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(resultado));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }

  // ---- 404 ----
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint no encontrado' }));
});

// ----------------------------------------------------------
// Parser manual de atributos Prolog -> JSON
// Entrada: "[at(universo,enum,[dc,marvel]),at(mascara,booleano,[true,false]),...]"
// ----------------------------------------------------------
function parsePrologAtributos(raw) {
  // Usamos regex para extraer cada at(...)
  const atributos = [];
  const re = /at\((\w+),(\w+),\[([^\]]*)\]\)/g;
  let m;
  while ((m = re.exec(raw)) !== null) {
    const nombre = m[1];
    const tipo = m[2];
    const opciones = m[3].split(',').map(s => s.trim().replace(/'/g, ''));
    atributos.push({ nombre, tipo, opciones });
  }
  return atributos;
}

server.listen(PORT, () => {
  console.log(`WHOlog API escuchando en http://localhost:${PORT}`);
  console.log('Endpoints:');
  console.log('  GET  /personajes  - Lista todos los personajes');
  console.log('  GET  /atributos   - Lista atributos disponibles');
  console.log('  POST /estado      - Estado del juego con restricciones');
});
