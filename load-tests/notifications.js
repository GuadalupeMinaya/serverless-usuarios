import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';

// ---------- Configuracion (todo se controla por variables de entorno) ----------
const BASE_URL = __ENV.BASE_URL || 'https://okgp3w2mvf.execute-api.us-east-1.amazonaws.com';
const EMAIL = __ENV.LOAD_EMAIL;
const PASSWORD = __ENV.LOAD_PASSWORD;
const VUS = parseInt(__ENV.VUS || '1');        // usuarios virtuales concurrentes
const RAMP = parseInt(__ENV.RAMP || '0');      // segundos de subida hasta VUS
const HOLD = parseInt(__ENV.HOLD || '10');     // segundos sosteniendo VUS
const THINK = parseFloat(__ENV.THINK || '1');  // pausa de cada usuario entre peticiones (s)
const LABEL = __ENV.LABEL || `u${VUS}`;        // nombre del archivo de resultados
const ABORT = __ENV.ABORT === '1';             // cortar la prueba si se superan los umbrales

// Solo HTTP 202 cuenta como exito; cualquier otro codigo cuenta en http_req_failed
http.setResponseCallback(http.expectedStatuses(202));

const resp2xx = new Counter('resp_2xx');
const resp429 = new Counter('resp_429');
const resp5xx = new Counter('resp_5xx');
const respOtro = new Counter('resp_otro'); // otros 4xx y errores de red / timeout

const stages = RAMP > 0
  ? [{ duration: `${RAMP}s`, target: VUS }, { duration: `${HOLD}s`, target: VUS }]
  : [{ duration: `${HOLD}s`, target: VUS }];

export const options = {
  scenarios: {
    carga: {
      executor: 'ramping-vus',
      startVUs: RAMP > 0 ? 0 : VUS,
      stages: stages,
      gracefulRampDown: '5s',
      gracefulStop: '35s',
    },
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  // Criterios de degradacion de la actividad: >5% de errores o latencia (p95) > 5 s
  thresholds: {
    http_req_failed: ABORT
      ? [{ threshold: 'rate<0.05', abortOnFail: true, delayAbortEval: '15s' }]
      : ['rate<0.05'],
    http_req_duration: ABORT
      ? [{ threshold: 'p(95)<5000', abortOnFail: true, delayAbortEval: '15s' }]
      : ['p(95)<5000'],
  },
};

const BODY = JSON.stringify({
  email: 'test@test.com',
  subject: 'Prueba',
  message: 'Mensaje de carga',
});

// Se ejecuta una sola vez: inicia sesion y comparte el token con todos los usuarios virtuales
export function setup() {
  if (!EMAIL || !PASSWORD) {
    throw new Error('Define $env:LOAD_EMAIL y $env:LOAD_PASSWORD antes de ejecutar k6');
  }
  const res = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({ email: EMAIL, password: PASSWORD }),
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: '60s',
      responseCallback: http.expectedStatuses(200),
    }
  );
  if (res.status !== 200) {
    throw new Error(`Login fallo: HTTP ${res.status}`);
  }
  return { token: res.json('token') };
}

export default function (data) {
  const res = http.post(`${BASE_URL}/notifications/send`, BODY, {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${data.token}`,
    },
    timeout: '35s',
  });

  if (res.status === 202) resp2xx.add(1);
  else if (res.status === 429) resp429.add(1);
  else if (res.status >= 500) resp5xx.add(1);
  else respOtro.add(1);

  check(res, { 'status 202': (r) => r.status === 202 });
  sleep(THINK);
}

// Resumen en consola + archivo results/<LABEL>.json con las metricas pedidas
export function handleSummary(data) {
  const v = (name, key) => {
    const m = data.metrics[name];
    if (!m) return 0;
    const x = m.values ? m.values : m;
    return x[key] === undefined ? 0 : x[key];
  };
  const dur = 'http_req_duration';
  const resumen = {
    label: LABEL,
    usuarios: VUS,
    ramp_s: RAMP,
    hold_s: HOLD,
    think_s: THINK,
    duracion_s: data.state ? Math.round(data.state.testRunDurationMs / 1000) : 0,
    requests: v('http_reqs', 'count'),
    rps: v('http_reqs', 'rate'),
    avg_ms: v(dur, 'avg'),
    min_ms: v(dur, 'min'),
    med_ms: v(dur, 'med'),
    p90_ms: v(dur, 'p(90)'),
    p95_ms: v(dur, 'p(95)'),
    p99_ms: v(dur, 'p(99)'),
    max_ms: v(dur, 'max'),
    error_rate: v('http_req_failed', 'rate'),
    resp_202: v('resp_2xx', 'count'),
    resp_429: v('resp_429', 'count'),
    resp_5xx: v('resp_5xx', 'count'),
    resp_otro: v('resp_otro', 'count'),
  };
  const out = { stdout: textSummary(data, { indent: ' ', enableColors: false }) };
  out[`results/${LABEL}.json`] = JSON.stringify(resumen, null, 2);
  return out;
}