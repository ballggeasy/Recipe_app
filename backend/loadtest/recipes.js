// k6 load test for the public read endpoints plus a login/register mix.
//   k6 run -e BASE_URL=http://localhost:3000 backend/loadtest/recipes.js
// See README.md in this folder before pointing it at anything but your own machine.
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const PEAK_VUS = Number(__ENV.VUS || 50);

export const options = {
  stages: [
    { duration: '10s', target: PEAK_VUS },
    { duration: __ENV.HOLD || '30s', target: PEAK_VUS },
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<800'],
  },
};

export function setup() {
  const res = http.get(`${BASE_URL}/recipes`);
  check(res, { 'catalog is reachable': (r) => r.status === 200 });
  return { ids: res.json().map((recipe) => recipe.id) };
}

export default function (data) {
  const id = data.ids[Math.floor(Math.random() * data.ids.length)];

  const list = http.get(`${BASE_URL}/recipes`);
  check(list, { 'list 200': (r) => r.status === 200 });

  const detail = http.get(`${BASE_URL}/recipes/${id}`);
  check(detail, { 'detail 200': (r) => r.status === 200 });

  // Every tenth iteration also logs in with a throwaway account: bcrypt is CPU-bound, which is
  // exactly what several replicas help with.
  if (__ITER % 10 === 0) {
    const email = `load-${__VU}-${Date.now()}@example.test`;
    const body = JSON.stringify({ name: 'Load Test', email, password: 'Passw0rd-load' });
    const headers = { headers: { 'Content-Type': 'application/json' } };
    const register = http.post(`${BASE_URL}/auth/register`, body, headers);
    check(register, { 'register 2xx': (r) => r.status >= 200 && r.status < 300 });
    const login = http.post(`${BASE_URL}/auth/login`, JSON.stringify({ email, password: 'Passw0rd-load' }), headers);
    check(login, { 'login 2xx': (r) => r.status >= 200 && r.status < 300 });
  }

  sleep(0.2);
}
