import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { AddressInfo } from 'node:net';
import { Server } from 'node:http';
import { createApiServer } from '../server';

let tempPath = '';
let server: Server;
let baseUrl = '';

before(async () => {
  tempPath = mkdtempSync(path.join(tmpdir(), 'cakrawala-node-'));
  process.env.ADMIN_API_TOKEN = '';
  server = await createApiServer(path.join(tempPath, 'test.sqlite3'));
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  rmSync(tempPath, { recursive: true, force: true });
});

async function request(route: string, body?: unknown, token?: string): Promise<{status: number; data: any}> {
  const result = await fetch(`${baseUrl}${route}`, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { ...(body === undefined ? {} : { 'Content-Type': 'application/json' }), ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: result.status, data: await result.json() };
}

test('health and catalog filtering', async () => {
  assert.deepEqual((await request('/api/health')).data, { ok: true, service: 'cakrawala-landing' });
  const catalog = await request('/api/programs?grade=SMA%20-%20Kelas%2012');
  assert.equal(catalog.status, 200);
  assert.equal(catalog.data.items.length, 5);
});

test('lead validation and persistence', async () => {
  const created = await request('/api/leads', {
    name: 'Alya Putri', phone: '+62 812-3456-7890', email: 'alya@example.com',
    grade: 'SMA - Kelas 12', programId: 'prog-snbt-1', source: 'package_interest',
    message: 'Minta info jadwal', consent: true,
  });
  assert.equal(created.status, 201);
  assert.equal(created.data.item.programId, 'prog-snbt-1');
  const invalid = await request('/api/leads', { name: 'A', phone: '123', grade: '', source: 'landing_consultation' });
  assert.equal(invalid.status, 422);
  assert.ok(invalid.data.fields);
});

test('login roles and dashboard access', async () => {
  for (const [email, role] of [
    ['farhan.arya@gmail.com', 'student'], ['rina.kusuma@gmail.com', 'parent'],
    ['dimas.prasetyo@cakrawalaeducentre.com', 'tutor'], ['admin@cakrawalaeducentre.com', 'admin'],
  ]) {
    const login = await request('/api/auth/login', { email, password: 'cakrawala2026' });
    assert.equal(login.status, 200);
    assert.equal(login.data.user.role, role);
    const dashboard = await request(`/api/${role}/dashboard`, undefined, login.data.token);
    assert.equal(dashboard.status, 200);
  }
});

test('student question reaches tutor dashboard and can be answered', async () => {
  const student = await request('/api/auth/login', { email: 'farhan.arya@gmail.com', password: 'cakrawala2026' });
  const tutor = await request('/api/auth/login', { email: 'dimas.prasetyo@cakrawalaeducentre.com', password: 'cakrawala2026' });
  const question = await request('/api/student/questions', { question: 'Bagaimana menghitung momen inersia?' }, student.data.token);
  assert.equal(question.status, 201);
  const reply = await request(`/api/tutor/questions/${question.data.item.id}/reply`, { reply: 'Gunakan rumus I = jumlah m r kuadrat.' }, tutor.data.token);
  assert.equal(reply.status, 200);
  const dashboard = await request('/api/student/dashboard', undefined, student.data.token);
  assert.equal(dashboard.data.questions[0].status, 'Dijawab');
});
