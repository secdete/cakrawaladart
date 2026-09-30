import { createHash, pbkdf2Sync, randomUUID, randomBytes as randomTokenBytes, timingSafeEqual } from 'node:crypto';
import { createServer, IncomingMessage, Server, ServerResponse } from 'node:http';
import { DatabaseAdapter, DEFAULT_DATABASE_PATH, initializeDatabase, Row } from './database';

export const DATABASE_PATH = DEFAULT_DATABASE_PATH;
const MAX_BODY_BYTES = 16_384;
const LEAD_RATE_WINDOW_MS = 600_000;
const LEAD_RATE_LIMIT = 6;
const AUTH_RATE_WINDOW_MS = 600_000;
const AUTH_RATE_LIMIT = 12;
const SESSION_TOKEN_TTL_HOURS = 12;
const PASSWORD_ITERATIONS = 240_000;

type Role = 'student' | 'parent' | 'tutor' | 'admin';
type Profile = Record<string, unknown> & { id: string; email: string; role: Role };
type RequestData = Record<string, unknown>;
type LeadInput = {
  name: string; phone: string; email: string | null; grade: string;
  programId: string | null; source: string; message: string; consent: true;
  consentAt: string; createdAt: string; status: string; id: string;
};

const SAMPLE_TRYOUT_QUESTION = {
  id: 'sample-archimedes-01', subtest: 'Penalaran Matematika & TPS Kuantitatif (UTBK-SNBT)',
  question: 'Sebuah balok es terapung di permukaan air laut. Jika diketahui massa jenis es adalah 0,9 g/cm³ dan massa jenis air laut adalah 1,03 g/cm³, berapakah persentase volume es yang tercelup di dalam air laut?',
  options: ['A. 87,4%', 'B. 82,5%', 'C. 90,0%', 'D. 75,2%', 'E. 92,6%'], correctIndex: 0,
  explanation: 'Berdasarkan Hukum Archimedes, benda terapung memenuhi ρ_cairan × V_tercelup = ρ_benda × V_total. Jadi, V_tercelup/V_total = 0,9/1,03 ≈ 0,8738 atau 87,4%.',
};

const leadRequests = new Map<string, number[]>();
const authRequests = new Map<string, number[]>();

function nowIso(): string { return new Date().toISOString(); }
function hashPassword(password: string, salt: Buffer): string {
  return pbkdf2Sync(password, salt, PASSWORD_ITERATIONS, 32, 'sha256').toString('hex');
}
function hashToken(token: string): string { return createHash('sha256').update(token).digest('hex'); }
function safeEqual(left: string, right: string): boolean {
  const a = Buffer.from(left); const b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

function publicUser(row: Record<string, unknown>): Profile {
  return { id: String(row.id), email: String(row.email), role: row.role as Role,
    ...JSON.parse(String(row.profile_json)) as Record<string, unknown> };
}
function sessionJson(row: Record<string, unknown>, studentName = ''): Record<string, unknown> {
  const date = new Date(String(row.scheduled_at));
  return {
    id: row.id, title: row.title, subject: row.subject, tutorName: 'Kak Dimas Prasetyo, S.Si.',
    tutorTitle: 'Master Tutor Fisika',
    dateTimeFormatted: new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', day: '2-digit', month: 'long', year: 'numeric' }).format(date),
    timeRange: row.time_range, type: row.session_type, status: row.status,
    meetLink: row.meet_link, topic: row.topic, studentName,
  };
}
function noteJson(row: Record<string, unknown>): Record<string, unknown> {
  return {
    id: row.id,
    dateFormatted: new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(String(row.created_at))),
    subject: row.subject, tutorName: 'Kak Dimas Prasetyo, S.Si.', topicCovered: row.topic_covered,
    studentComprehension: row.comprehension, homeworkAssigned: row.homework, notesForParents: row.parent_note,
  };
}
function bearer(req: IncomingMessage): string {
  const value = String(req.headers.authorization || '');
  return value.startsWith('Bearer ') ? value.slice(7).trim() : '';
}
async function requireUser(db: DatabaseAdapter, req: IncomingMessage, roles?: Role[]): Promise<Profile | null> {
  const token = bearer(req);
  if (!token) return null;
  const row = await db.prepare(`SELECT u.* FROM auth_tokens t JOIN users u ON u.id=t.user_id
    WHERE t.token_hash=? AND t.expires_at>? AND u.active=1`).get(hashToken(token), nowIso());
  if (!row || (roles && !roles.includes(row.role as Role))) return null;
  return publicUser(row);
}
function response(res: ServerResponse, status: number, body: unknown): void {
  const payload = Buffer.from(JSON.stringify(body), 'utf8');
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Content-Length', String(payload.length));
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.end(payload);
}
function cors(req: IncomingMessage, res: ServerResponse): void {
  const origin = String(req.headers.origin || '');
  const allowed = (process.env.CORS_ORIGINS || '*').split(',').map(value => value.trim());
  if (allowed.includes('*')) res.setHeader('Access-Control-Allow-Origin', '*');
  else if (allowed.includes(origin)) { res.setHeader('Access-Control-Allow-Origin', origin); res.setHeader('Vary', 'Origin'); }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}
async function readJson(req: IncomingMessage): Promise<RequestData | null> {
  const chunks: Buffer[] = []; let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > MAX_BODY_BYTES) throw new Error('BODY_TOO_LARGE');
    chunks.push(buffer);
  }
  if (total === 0) return null;
  try {
    const value: unknown = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    return typeof value === 'object' && value !== null && !Array.isArray(value) ? value as RequestData : null;
  } catch { return null; }
}
function checkRateLimit(map: Map<string, number[]>, ip: string, limit: number, windowMs: number): boolean {
  const now = Date.now();
  const recent = (map.get(ip) || []).filter(stamp => now - stamp < windowMs);
  if (recent.length >= limit) { map.set(ip, recent); return false; }
  recent.push(now); map.set(ip, recent); return true;
}

async function createLead(db: DatabaseAdapter, payload: RequestData): Promise<{ item?: LeadInput; error?: Record<string, unknown> }> {
  const name = String(payload.name ?? '').trim();
  const phone = String(payload.phone ?? '').trim();
  const emailValue = String(payload.email ?? '').trim().toLowerCase();
  const grade = String(payload.grade ?? '').trim();
  const programId = String(payload.programId ?? '').trim() || null;
  const source = String(payload.source ?? 'landing').trim();
  const message = String(payload.message ?? '').trim();
  const consent = payload.consent === true;
  const errors: Record<string, string> = {};
  if (name.length < 2 || name.length > 100) errors.name = 'Nama wajib diisi (2–100 karakter).';
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 8 || digits.length > 15) errors.phone = 'Nomor WhatsApp harus berisi 8–15 digit.';
  if (emailValue && (emailValue.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailValue))) errors.email = 'Format email tidak valid.';
  if (grade.length < 1 || grade.length > 80) errors.grade = 'Jenjang belajar wajib dipilih.';
  if (!consent) errors.consent = 'Persetujuan untuk dihubungi wajib diberikan.';
  if (!['landing_consultation', 'hero_consultation', 'package_interest'].includes(source)) errors.source = 'Sumber permintaan tidak valid.';
  if (message.length > 2000) errors.message = 'Pesan maksimal 2.000 karakter.';
  if (Object.keys(errors).length) return { error: { error: 'Periksa kembali data yang dikirim.', fields: errors } };
  if (programId && !await db.prepare('SELECT 1 FROM programs WHERE id=? AND active=1').get(programId)) return { error: { error: 'Program yang dipilih tidak ditemukan.' } };
  const timestamp = nowIso();
  const item: LeadInput = { id: randomUUID(), name, phone, email: emailValue || null, grade, programId, source, message, consent: true, consentAt: timestamp, createdAt: timestamp, status: 'new' };
  await db.prepare(`INSERT INTO leads (id,name,phone,email,grade,program_id,source,message,consent,consent_at,created_at)
    VALUES (?,?,?,?,?,?,?,?,1,?,?)`).run(item.id, item.name, item.phone, item.email, item.grade, item.programId, item.source, item.message, item.consentAt, item.createdAt);
  return { item };
}

async function getDashboard(db: DatabaseAdapter, role: Role, user: Profile, res: ServerResponse): Promise<void> {
  if (role === 'admin') {
    const leads = await db.prepare('SELECT * FROM leads ORDER BY created_at DESC LIMIT 500').all();
    response(res, 200, { profile: user, leads, summary: { totalLeads: leads.length, newLeads: leads.filter(lead => lead.status === 'new').length } });
    return;
  }
  if (role === 'tutor') {
    const rows = await db.prepare(`SELECT s.*,u.profile_json FROM sessions s JOIN users u ON u.id=s.student_id
      WHERE s.tutor_id=? ORDER BY s.scheduled_at`).all(user.id);
    const sessions = rows.map(row => sessionJson(row, String((JSON.parse(String(row.profile_json)) as Record<string, unknown>).name)));
    const notesRows = await db.prepare(`SELECT n.*,u.profile_json FROM tutor_notes n JOIN users u ON u.id=n.student_id
      WHERE n.tutor_id=? ORDER BY n.created_at DESC`).all(user.id);
    const notes = notesRows.map(row => ({ ...noteJson(row), studentName: (JSON.parse(String(row.profile_json)) as Record<string, unknown>).name, studentId: row.student_id }));
    const qRows = await db.prepare(`SELECT q.*,u.profile_json FROM student_questions q JOIN users u ON u.id=q.student_id
      WHERE EXISTS (SELECT 1 FROM sessions s WHERE s.student_id=q.student_id AND s.tutor_id=?) ORDER BY q.created_at DESC`).all(user.id);
    const questions = qRows.map(row => ({ id: row.id, studentId: row.student_id, studentName: (JSON.parse(String(row.profile_json)) as Record<string, unknown>).name, question: row.question, status: row.status, createdAt: row.created_at, reply: row.tutor_reply }));
    response(res, 200, { profile: user, sessions, notes, questions, summary: { totalSessions: sessions.length, upcomingSessions: sessions.filter(s => s.status === 'Mendatang').length, totalStudents: new Set(sessions.map(s => s.studentName)).size } });
    return;
  }
  const studentId = role === 'student' ? user.id : String(user.childId || '');
  const sessionsRows = await db.prepare('SELECT * FROM sessions WHERE student_id=? ORDER BY scheduled_at').all(studentId);
  const notesRows = await db.prepare('SELECT * FROM tutor_notes WHERE student_id=? ORDER BY created_at DESC').all(studentId);
  const attempts = await db.prepare('SELECT COUNT(*) AS count, SUM(is_correct) AS correct FROM tryout_attempts WHERE student_id=?').get(studentId) as {count: number | string; correct: number | string | null};
  const questionCount = Number((await db.prepare('SELECT COUNT(*) AS count FROM student_questions WHERE student_id=?').get(studentId))?.count ?? 0);
  let profile: Record<string, unknown> = user;
  if (role === 'parent') {
    const child = await db.prepare('SELECT profile_json FROM users WHERE id=?').get(studentId) as {profile_json: string} | undefined;
    profile = { ...user, child: child ? JSON.parse(child.profile_json) : {} };
  }
  const questionRows = await db.prepare('SELECT * FROM student_questions WHERE student_id=? ORDER BY created_at DESC').all(studentId);
  const questions = questionRows.map(row => ({ id: row.id, question: row.question, status: row.status, createdAt: row.created_at, reply: row.tutor_reply }));
  response(res, 200, {
    profile, sessions: sessionsRows.map(row => sessionJson(row)), notes: notesRows.map(row => noteJson(row)), questions,
    tryouts: [{ id: 'sample-tryout', title: 'Drill Penalaran Kuantitatif', category: 'UTBK-SNBT', totalQuestions: 1, durationMinutes: 10, score: Number(attempts.count) ? Number(attempts.correct || 0) * 100 : null, rank: null, totalParticipants: null, status: Number(attempts.count) ? 'Selesai' : 'Tersedia', deadlineFormatted: 'Latihan interaktif' }],
    summary: { questionsAsked: questionCount, attempts: Number(attempts.count), correctAnswers: Number(attempts.correct || 0) },
  });
}

export async function createApiServer(databasePath = DATABASE_PATH): Promise<Server> {
  const db = await initializeDatabase(databasePath);
  const server = createServer(async (req, res) => {
    cors(req, res);
    if (req.method === 'OPTIONS') { res.statusCode = 204; res.end(); return; }
    const url = new URL(req.url || '/', 'http://localhost');
    const route = url.pathname;
    try {
      if (req.method === 'GET' && route === '/api/health') { response(res, 200, { ok: true, service: 'cakrawala-landing' }); return; }
      if (req.method === 'GET' && route === '/api/programs') {
        const grade = (url.searchParams.get('grade') || '').trim();
        const rows = await db.prepare('SELECT data_json,grades_json FROM programs WHERE active=1 ORDER BY id').all() as Array<{data_json: string; grades_json: string}>;
        const items = rows.filter(row => !grade || grade === 'Semua Jenjang' || (JSON.parse(row.grades_json) as string[]).includes(grade)).map(row => JSON.parse(row.data_json));
        response(res, 200, { items }); return;
      }
      if (req.method === 'GET' && ['/api/me','/api/student/dashboard','/api/parent/dashboard','/api/tutor/dashboard','/api/admin/dashboard'].includes(route)) {
        const user = await requireUser(db, req);
        if (!user) { response(res, 401, { error: 'Sesi tidak valid atau sudah berakhir.' }); return; }
        if (route === '/api/me') { response(res, 200, { user }); return; }
        const role = route.split('/')[2] as Role;
        if (user.role !== role) { response(res, 403, { error: 'Akun tidak memiliki akses ke dashboard ini.' }); return; }
        await getDashboard(db, role, user, res); return;
      }
      if (req.method === 'GET' && route === '/api/tryouts/sample/question') {
        if (!await requireUser(db, req, ['student'])) { response(res, 401, { error: 'Login siswa diperlukan.' }); return; }
        const { correctIndex: _answer, explanation: _explanation, ...question } = SAMPLE_TRYOUT_QUESTION;
        response(res, 200, { question }); return;
      }
      if (req.method === 'GET' && route === '/api/admin/leads') {
        const expected = process.env.ADMIN_API_TOKEN || '';
        if (!expected) { response(res, 503, { error: 'ADMIN_API_TOKEN belum dikonfigurasi.' }); return; }
        if (!safeEqual(bearer(req), expected)) { response(res, 401, { error: 'Token admin tidak valid.' }); return; }
        const requested = Number.parseInt(url.searchParams.get('limit') || '100', 10);
        const limit = Math.min(Math.max(Number.isNaN(requested) ? 100 : requested, 1), 500);
        response(res, 200, { items: await db.prepare('SELECT * FROM leads ORDER BY created_at DESC LIMIT ?').all(limit) }); return;
      }
      if (req.method === 'POST') {
        const supported = ['/api/leads','/api/auth/login','/api/auth/logout','/api/student/questions','/api/tryouts/sample/answer','/api/tutor/notes','/api/admin/users'];
        const replyMatch = route.match(/^\/api\/tutor\/questions\/([^/]+)\/reply$/);
        if (!supported.includes(route) && !replyMatch) { response(res, 404, { error: 'Endpoint tidak ditemukan.' }); return; }
        let payload: RequestData | null;
        try { payload = await readJson(req); }
        catch (error) { response(res, 413, { error: error instanceof Error && error.message === 'BODY_TOO_LARGE' ? 'Ukuran permintaan tidak valid.' : 'Body JSON tidak valid.' }); return; }
        if (!payload) { response(res, 400, { error: 'Body JSON harus object.' }); return; }
        const ip = req.socket.remoteAddress || 'unknown';
        if (route === '/api/auth/login') {
          if (!checkRateLimit(authRequests, ip, AUTH_RATE_LIMIT, AUTH_RATE_WINDOW_MS)) { response(res, 429, { error: 'Terlalu banyak percobaan masuk. Coba lagi nanti.' }); return; }
          const email = String(payload.email ?? '').trim().toLowerCase(); const password = String(payload.password ?? '');
          const row = await db.prepare('SELECT * FROM users WHERE email=? AND active=1').get(email) as Row | undefined;
          let valid = false;
          if (row) {
            const actual = hashPassword(password, Buffer.from(String(row.password_salt), 'hex'));
            valid = safeEqual(actual, String(row.password_hash));
          }
          if (!valid || !row) { response(res, 401, { error: 'Email atau kata sandi belum sesuai.' }); return; }
          const token = randomTokenBytes(32).toString('base64url'); const createdAt = nowIso();
          const expiresAt = new Date(Date.now() + SESSION_TOKEN_TTL_HOURS * 3_600_000).toISOString();
          await db.prepare('INSERT INTO auth_tokens VALUES (?,?,?,?)').run(hashToken(token), row.id, expiresAt, createdAt);
          response(res, 200, { token, user: publicUser(row) }); return;
        }
        if (route === '/api/auth/logout') {
          const token = bearer(req); if (token) await db.prepare('DELETE FROM auth_tokens WHERE token_hash=?').run(hashToken(token));
          response(res, 200, { ok: true }); return;
        }
        if (route === '/api/leads') {
          if (!checkRateLimit(leadRequests, ip, LEAD_RATE_LIMIT, LEAD_RATE_WINDOW_MS)) { response(res, 429, { error: 'Terlalu banyak permintaan. Coba lagi beberapa menit.' }); return; }
          const result = await createLead(db, payload);
          if (result.error) { response(res, 422, result.error); return; }
          response(res, 201, { item: result.item }); return;
        }
        const user = await requireUser(db, req);
        if (!user) { response(res, 401, { error: 'Sesi tidak valid atau sudah berakhir.' }); return; }
        if (route === '/api/admin/users') {
          if (user.role !== 'admin') { response(res, 403, { error: 'Hanya admin dapat membuat akun.' }); return; }
          const email = String(payload.email ?? '').trim().toLowerCase();
          const password = String(payload.password ?? '');
          const role = String(payload.role ?? '');
          const name = String(payload.name ?? '').trim();
          if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { response(res, 422, { error: 'Format email tidak valid.' }); return; }
          if (password.length < 8 || password.length > 200) { response(res, 422, { error: 'Kata sandi harus berisi 8–200 karakter.' }); return; }
          if (!['student', 'parent', 'tutor', 'admin'].includes(role)) { response(res, 422, { error: 'Role akun tidak valid.' }); return; }
          if (name.length < 2 || name.length > 100) { response(res, 422, { error: 'Nama wajib diisi (2–100 karakter).' }); return; }
          if (await db.prepare('SELECT 1 FROM users WHERE email=?').get(email)) { response(res, 409, { error: 'Email sudah terdaftar.' }); return; }
          const id = randomUUID(); const salt = randomTokenBytes(16);
          const extraProfile = typeof payload.profile === 'object' && payload.profile !== null && !Array.isArray(payload.profile)
            ? payload.profile as Record<string, unknown> : {};
          const profile = { ...extraProfile, name, email };
          await db.prepare('INSERT INTO users (id,email,password_salt,password_hash,role,profile_json,active) VALUES (?,?,?,?,?,?,1)')
            .run(id, email, salt.toString('hex'), hashPassword(password, salt), role, JSON.stringify(profile));
          response(res, 201, { user: { id, role, ...profile } }); return;
        }
        if (replyMatch) {
          if (user.role !== 'tutor') { response(res, 403, { error: 'Hanya tutor dapat membalas pertanyaan.' }); return; }
          const reply = String(payload.reply ?? '').trim();
          if (reply.length < 2 || reply.length > 2000) { response(res, 422, { error: 'Balasan harus berisi 2–2.000 karakter.' }); return; }
          const result = await db.prepare(`UPDATE student_questions SET tutor_reply=?,status='Dijawab' WHERE id=? AND EXISTS
            (SELECT 1 FROM sessions s WHERE s.student_id=student_questions.student_id AND s.tutor_id=?)`).run(reply, replyMatch[1], user.id);
          if (!result.changes) { response(res, 404, { error: 'Pertanyaan tidak ditemukan untuk siswa bimbingan tutor ini.' }); return; }
          response(res, 200, { ok: true, status: 'Dijawab' }); return;
        }
        if (route === '/api/student/questions') {
          if (user.role !== 'student') { response(res, 403, { error: 'Hanya siswa dapat mengirim pertanyaan.' }); return; }
          const question = String(payload.question ?? '').trim();
          if (question.length < 5 || question.length > 2000) { response(res, 422, { error: 'Pertanyaan harus berisi 5–2.000 karakter.' }); return; }
          const item = { id: randomUUID(), question, status: 'Menunggu tutor', createdAt: nowIso() };
          await db.prepare("INSERT INTO student_questions (id,student_id,question,status,created_at,tutor_reply) VALUES (?,?,? ,? ,?,'')").run(item.id, user.id, question, item.status, item.createdAt);
          response(res, 201, { item }); return;
        }
        if (route === '/api/tryouts/sample/answer') {
          if (user.role !== 'student') { response(res, 403, { error: 'Hanya siswa dapat mengerjakan tryout.' }); return; }
          const selected = Number(payload.selectedIndex);
          if (!Number.isInteger(selected)) { response(res, 422, { error: 'Pilihan jawaban tidak valid.' }); return; }
          if (selected < 0 || selected >= SAMPLE_TRYOUT_QUESTION.options.length) { response(res, 422, { error: 'Pilihan jawaban tidak tersedia.' }); return; }
          const correct = selected === SAMPLE_TRYOUT_QUESTION.correctIndex;
          await db.prepare('INSERT INTO tryout_attempts VALUES (?,?,?,?,?,?)').run(randomUUID(), user.id, SAMPLE_TRYOUT_QUESTION.id, selected, Number(correct), nowIso());
          response(res, 200, { isCorrect: correct, correctIndex: SAMPLE_TRYOUT_QUESTION.correctIndex, explanation: SAMPLE_TRYOUT_QUESTION.explanation }); return;
        }
        if (route === '/api/tutor/notes') {
          if (user.role !== 'tutor') { response(res, 403, { error: 'Hanya tutor dapat menulis catatan.' }); return; }
          const fields = {
            studentId: String(payload.studentId ?? ''), subject: String(payload.subject ?? 'Fisika').trim(),
            topicCovered: String(payload.topicCovered ?? '').trim(), comprehension: String(payload.comprehension ?? 'Baik').trim(),
            homework: String(payload.homework ?? '').trim(), parentNote: String(payload.parentNote ?? '').trim(),
          };
          if (!fields.topicCovered) { response(res, 422, { error: 'Topik pembelajaran wajib diisi.' }); return; }
          const owned = await db.prepare('SELECT 1 FROM sessions WHERE tutor_id=? AND student_id=?').get(user.id, fields.studentId);
          if (!owned) { response(res, 403, { error: 'Siswa tidak ditugaskan kepada tutor ini.' }); return; }
          const item = { id: randomUUID(), sessionId: payload.sessionId ?? null, student_id: fields.studentId, tutor_id: user.id, subject: fields.subject, topic_covered: fields.topicCovered, comprehension: fields.comprehension, homework: fields.homework, parent_note: fields.parentNote, created_at: nowIso() };
          await db.prepare('INSERT INTO tutor_notes VALUES (?,?,?,?,?,?,?,?,?,?)').run(item.id, item.sessionId, item.student_id, item.tutor_id, item.subject, item.topic_covered, item.comprehension, item.homework, item.parent_note, item.created_at);
          response(res, 201, { item: { id: item.id, dateFormatted: new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(item.created_at)), subject: item.subject, tutorName: user.name, topicCovered: item.topic_covered, studentComprehension: item.comprehension, homeworkAssigned: item.homework, notesForParents: item.parent_note } }); return;
        }
      }
      if (req.method === 'PATCH') {
        const match = route.match(/^\/api\/tutor\/sessions\/([^/]+)$/);
        if (!match) { response(res, 404, { error: 'Endpoint tidak ditemukan.' }); return; }
        const tutor = await requireUser(db, req, ['tutor']);
        if (!tutor) { response(res, 401, { error: 'Login tutor diperlukan.' }); return; }
        let payload: RequestData | null;
        try { payload = await readJson(req); } catch { response(res, 400, { error: 'Body JSON tidak valid.' }); return; }
        const status = String(payload?.status ?? '');
        if (!['Selesai', 'Dibatalkan'].includes(status)) { response(res, 422, { error: 'Status sesi tidak valid.' }); return; }
        const result = await db.prepare('UPDATE sessions SET status=? WHERE id=? AND tutor_id=?').run(status, match[1], tutor.id);
        if (!result.changes) { response(res, 404, { error: 'Sesi tidak ditemukan untuk tutor ini.' }); return; }
        response(res, 200, { ok: true, status }); return;
      }
      response(res, 404, { error: 'Endpoint tidak ditemukan.' });
    } catch (error) {
      console.error('Request API gagal:', error);
      if (!res.headersSent) response(res, 500, { error: 'Terjadi kesalahan pada server.' });
      else res.destroy();
    }
  });
  server.on('close', () => db.close());
  return server;
}

if (require.main === module) {
  const host = process.env.HOST || '127.0.0.1';
  const port = Number(process.env.PORT || 8000);
  void createApiServer().then(server => server.listen(port, host, () => {
    console.log(`Cakrawala API aktif: http://${host}:${port}/api`);
    console.log(`Database: ${process.env.DATABASE_URL ? 'PostgreSQL terpusat' : `SQLite (${DATABASE_PATH})`}`);
  })).catch(error => { console.error('Gagal menyiapkan database:', error); process.exitCode = 1; });
}
