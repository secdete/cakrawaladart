import dotenv from 'dotenv';
import { randomBytes, pbkdf2Sync } from 'node:crypto';
import { mkdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import SQLite from 'better-sqlite3';
import { Pool } from 'pg';

export type Row = Record<string, any>;
export type RunResult = { changes: number };
export type Statement = {
  get: (...params: unknown[]) => Promise<Row | undefined>;
  all: (...params: unknown[]) => Promise<Row[]>;
  run: (...params: unknown[]) => Promise<RunResult>;
};
export type DatabaseAdapter = {
  readonly dialect: 'sqlite' | 'postgres';
  exec: (sql: string) => Promise<void>;
  prepare: (sql: string) => Statement;
  close: () => Promise<void>;
};

const ROOT = __dirname;
dotenv.config({ path: path.join(ROOT, '.env') });
export const DEFAULT_DATABASE_PATH = process.env.DATABASE_PATH || path.join(ROOT, 'data', 'cakrawala.sqlite3');
const PASSWORD_ITERATIONS = 240_000;

const DEMO_ACCOUNTS = [
  { id: 'student-farhan', email: 'farhan.arya@gmail.com', password: 'cakrawala2026', role: 'student', profile: {
    name: 'Farhan Arya Nugraha', grade: 'Kelas 12 SMA - IPA (Target SNBT)', school: 'SMAN Unggulan 1',
    targetPtn: 'STEI Institut Teknologi Bandung (Pilihan 1) & FK UI (Pilihan 2)',
    activePackage: 'Intensif Supercamp SNBT + Privat Fisika 1-on-1', totalSessions: 24, email: 'farhan.arya@gmail.com',
  } },
  { id: 'parent-rina', email: 'rina.kusuma@gmail.com', password: 'cakrawala2026', role: 'parent', profile: {
    name: 'Ibu Rina Kusuma Dewi', childId: 'student-farhan', childName: 'Farhan Arya Nugraha',
    childGrade: 'Kelas 12 SMA', phone: '0812-9876-5432', subscriptionStatus: 'Aktif (Paket Semester Ganjil)', email: 'rina.kusuma@gmail.com',
  } },
  { id: 'tutor-dimas', email: 'dimas.prasetyo@cakrawalaeducentre.com', password: 'cakrawala2026', role: 'tutor', profile: {
    name: 'Kak Dimas Prasetyo, S.Si.', specialization: 'Master Tutor Fisika & Penalaran Matematika (Alumnus ITB)',
    rating: 4.95, totalReviews: 148, email: 'dimas.prasetyo@cakrawalaeducentre.com',
  } },
];

function passwordHash(password: string, salt: Buffer): string {
  return pbkdf2Sync(password, salt, PASSWORD_ITERATIONS, 32, 'sha256').toString('hex');
}
function convertPlaceholders(sql: string, params: unknown[]): { sql: string; params: unknown[] } {
  if (params.length === 1 && typeof params[0] === 'object' && params[0] !== null && !Array.isArray(params[0])) {
    const values: unknown[] = [];
    const positions = new Map<string, number>();
    const converted = sql.replace(/@([A-Za-z_][A-Za-z0-9_]*)/g, (_match, name: string) => {
      const namedValues = params[0] as Record<string, unknown>;
      if (!(name in namedValues)) throw new Error(`Missing SQL parameter: ${name}`);
      let position = positions.get(name);
      if (position === undefined) {
        position = values.length;
        positions.set(name, position);
        values.push(namedValues[name]);
      }
      return `$${position + 1}`;
    });
    return { sql: converted, params: values };
  }
  let index = 0;
  return { sql: sql.replace(/\?/g, () => `$${++index}`), params };
}

function sqliteAdapter(databasePath: string): DatabaseAdapter {
  mkdirSync(path.dirname(databasePath), { recursive: true });
  const db = new SQLite(databasePath);
  db.pragma('journal_mode = WAL');
  return {
    dialect: 'sqlite',
    async exec(sql) { db.exec(sql); },
    prepare(sql) {
      const statement = db.prepare(sql);
      return {
        async get(...params) { return statement.get(...params) as Row | undefined; },
        async all(...params) { return statement.all(...params) as Row[]; },
        async run(...params) { const result = statement.run(...params); return { changes: result.changes }; },
      };
    },
    async close() { db.close(); },
  };
}

function postgresAdapter(connectionString: string): DatabaseAdapter {
  const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false }, max: 5 });
  return {
    dialect: 'postgres',
    async exec(sql) { await pool.query(sql); },
    prepare(sql) {
      return {
        async get(...params) {
          const converted = convertPlaceholders(sql, params);
          const result = await pool.query(converted.sql, converted.params);
          return result.rows[0] as Row | undefined;
        },
        async all(...params) {
          const converted = convertPlaceholders(sql, params);
          const result = await pool.query(converted.sql, converted.params);
          return result.rows as Row[];
        },
        async run(...params) {
          let query = sql;
          if (/^\s*INSERT\s+OR\s+IGNORE\s+INTO/i.test(query)) {
            query = query.replace(/^\s*INSERT\s+OR\s+IGNORE\s+INTO/i, 'INSERT INTO');
            query += ' ON CONFLICT DO NOTHING';
          }
          const converted = convertPlaceholders(query, params);
          const result = await pool.query(converted.sql, converted.params);
          return { changes: result.rowCount ?? 0 };
        },
      };
    },
    async close() { await pool.end(); },
  };
}

export async function initializeDatabase(databasePath = DEFAULT_DATABASE_PATH): Promise<DatabaseAdapter> {
  const databaseUrl = databasePath === DEFAULT_DATABASE_PATH ? process.env.DATABASE_URL?.trim() : undefined;
  const db = databaseUrl ? postgresAdapter(databaseUrl) : sqliteAdapter(databasePath);
  await db.exec(`
    CREATE TABLE IF NOT EXISTS programs (
      id TEXT PRIMARY KEY, grade_level TEXT NOT NULL, grades_json TEXT NOT NULL,
      data_json TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1
    );
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY, email TEXT NOT NULL UNIQUE, password_salt TEXT NOT NULL,
      password_hash TEXT NOT NULL, role TEXT NOT NULL, profile_json TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1
    );
    CREATE TABLE IF NOT EXISTS auth_tokens (
      token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
      expires_at TEXT NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY, student_id TEXT NOT NULL, tutor_id TEXT NOT NULL,
      title TEXT NOT NULL, subject TEXT NOT NULL, scheduled_at TEXT NOT NULL,
      time_range TEXT NOT NULL, session_type TEXT NOT NULL, status TEXT NOT NULL,
      meet_link TEXT NOT NULL, topic TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS classes (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, subject TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '', tutor_id TEXT NOT NULL REFERENCES users(id),
      scheduled_at TEXT NOT NULL, duration_minutes INTEGER NOT NULL DEFAULT 60,
      meeting_url TEXT NOT NULL DEFAULT '', active INTEGER NOT NULL DEFAULT 1,
      created_by TEXT NOT NULL REFERENCES users(id), created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_classes_tutor_schedule ON classes(tutor_id, scheduled_at);
    CREATE INDEX IF NOT EXISTS idx_classes_active_schedule ON classes(active, scheduled_at);
    CREATE TABLE IF NOT EXISTS class_enrollments (
      class_id TEXT NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
      student_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      enrolled_at TEXT NOT NULL, PRIMARY KEY(class_id, student_id)
    );
    CREATE INDEX IF NOT EXISTS idx_class_enrollments_student ON class_enrollments(student_id, enrolled_at);
    CREATE TABLE IF NOT EXISTS tutor_notes (
      id TEXT PRIMARY KEY, session_id TEXT, student_id TEXT NOT NULL,
      tutor_id TEXT NOT NULL, subject TEXT NOT NULL, topic_covered TEXT NOT NULL,
      comprehension TEXT NOT NULL, homework TEXT NOT NULL, parent_note TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS student_questions (
      id TEXT PRIMARY KEY, student_id TEXT NOT NULL, question TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'Menunggu tutor', created_at TEXT NOT NULL,
      tutor_reply TEXT NOT NULL DEFAULT ''
    );
    CREATE TABLE IF NOT EXISTS tryout_attempts (
      id TEXT PRIMARY KEY, student_id TEXT NOT NULL, question_id TEXT NOT NULL,
      selected_index INTEGER NOT NULL, is_correct INTEGER NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS leads (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT NOT NULL, email TEXT,
      grade TEXT NOT NULL, program_id TEXT, source TEXT NOT NULL,
      message TEXT NOT NULL DEFAULT '', consent INTEGER NOT NULL DEFAULT 0,
      consent_at TEXT, created_at TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'new'
    );
  `);

  if (db.dialect === 'postgres') {
    await db.exec(`
      ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
      ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;
      DO $$ BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN
          EXECUTE 'REVOKE ALL ON TABLE public.classes, public.class_enrollments FROM anon';
        END IF;
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN
          EXECUTE 'REVOKE ALL ON TABLE public.classes, public.class_enrollments FROM authenticated';
        END IF;
      END $$;
    `);
  }

  if (db.dialect === 'sqlite') {
    const qCols = new Set((await db.prepare('PRAGMA table_info(student_questions)').all()).map(column => column.name));
    if (!qCols.has('tutor_reply')) await db.exec("ALTER TABLE student_questions ADD COLUMN tutor_reply TEXT NOT NULL DEFAULT ''");
    const leadCols = new Set((await db.prepare('PRAGMA table_info(leads)').all()).map(column => column.name));
    if (!leadCols.has('consent')) await db.exec('ALTER TABLE leads ADD COLUMN consent INTEGER NOT NULL DEFAULT 0');
    if (!leadCols.has('consent_at')) await db.exec('ALTER TABLE leads ADD COLUMN consent_at TEXT');
  } else {
    await db.exec("ALTER TABLE student_questions ADD COLUMN IF NOT EXISTS tutor_reply TEXT NOT NULL DEFAULT ''");
    await db.exec('ALTER TABLE leads ADD COLUMN IF NOT EXISTS consent INTEGER NOT NULL DEFAULT 0');
    await db.exec('ALTER TABLE leads ADD COLUMN IF NOT EXISTS consent_at TEXT');
  }

  const programCount = Number((await db.prepare('SELECT COUNT(*) AS count FROM programs').get())?.count ?? 0);
  if (programCount === 0) {
    const catalog = JSON.parse(readFileSync(path.join(ROOT, 'catalog.json'), 'utf8')) as Array<Record<string, unknown>>;
    const insert = db.prepare('INSERT INTO programs (id, grade_level, grades_json, data_json) VALUES (?, ?, ?, ?)');
    for (const program of catalog) await insert.run(program.id, program.gradeLevel, JSON.stringify(program.grades), JSON.stringify(program));
  }

  const adminEmail = (process.env.ADMIN_LOGIN_EMAIL || 'admin@cakrawalaeducentre.com').trim().toLowerCase();
  const accounts = [...DEMO_ACCOUNTS, {
    id: 'admin-cakrawala', email: adminEmail,
    password: process.env.ADMIN_LOGIN_PASSWORD || 'cakrawala2026', role: 'admin',
    profile: { name: 'Administrator Cakrawala', email: adminEmail },
  }];
  for (const account of accounts) {
    const exists = await db.prepare('SELECT 1 FROM users WHERE id=?').get(account.id);
    if (exists) continue;
    const salt = randomBytes(16);
    await db.prepare('INSERT INTO users (id,email,password_salt,password_hash,role,profile_json,active) VALUES (?,?,?,?,?,?,1)')
      .run(account.id, account.email, salt.toString('hex'), passwordHash(account.password, salt), account.role, JSON.stringify(account.profile));
  }

  const hasSessions = await db.prepare('SELECT 1 FROM sessions LIMIT 1').get();
  if (!hasSessions) {
    const stamp = new Date(); stamp.setUTCHours(16, 0, 0, 0);
    await db.prepare('INSERT INTO sessions VALUES (?,?,?,?,?,?,?,?,?,?,?)').run(
      'ses-01', 'student-farhan', 'tutor-dimas', 'Bedah Dinamika Rotasi & Momen Inersia',
      'Fisika SMA', stamp.toISOString(), '16.00 - 17.30 WIB', 'Privat 1-on-1 (Online)', 'Mendatang',
      'https://meet.google.com/ckr-fsk-12b', 'Hukum Kekekalan Momentum Sudut',
    );
    await db.prepare('INSERT INTO tutor_notes VALUES (?,?,?,?,?,?,?,?,?,?)').run(
      'note-01', 'ses-01', 'student-farhan', 'tutor-dimas', 'Fisika SMA', 'Torsi dan momen gaya',
      'Baik', 'Latihan 5 soal dinamika rotasi', 'Farhan memahami konsep dasar dengan baik.', new Date().toISOString(),
    );
  }
  return db;
}
