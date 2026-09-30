import dotenv from 'dotenv';
import SQLite from 'better-sqlite3';
import { Pool } from 'pg';
import { DEFAULT_DATABASE_PATH, initializeDatabase } from './database';
import path from 'node:path';

dotenv.config({ path: path.join(__dirname, '.env') });

const TABLES: Array<{name: string; key: string}> = [
  { name: 'programs', key: 'id' },
  { name: 'users', key: 'id' },
  { name: 'sessions', key: 'id' },
  { name: 'tutor_notes', key: 'id' },
  { name: 'student_questions', key: 'id' },
  { name: 'tryout_attempts', key: 'id' },
  { name: 'leads', key: 'id' },
  { name: 'auth_tokens', key: 'token_hash' },
];

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL?.trim();
  if (!connectionString) throw new Error('Isi DATABASE_URL di backend/.env terlebih dahulu.');

  const sourcePath = process.env.DATABASE_PATH || DEFAULT_DATABASE_PATH;
  const source = new SQLite(sourcePath, { readonly: true, fileMustExist: true });
  const schema = await initializeDatabase();
  await schema.close();
  const target = new Pool({ connectionString, ssl: { rejectUnauthorized: false }, max: 1 });
  const client = await target.connect();

  try {
    await client.query('BEGIN');
    for (const table of TABLES) {
      const rows = source.prepare(`SELECT * FROM "${table.name}"`).all() as Array<Record<string, unknown>>;
      if (!rows.length) continue;
      const columns = Object.keys(rows[0]);
      const insert = `INSERT INTO "${table.name}" (${columns.map(column => `"${column}"`).join(',')})
        VALUES (${columns.map((_, index) => `$${index + 1}`).join(',')})
        ON CONFLICT ("${table.key}") DO UPDATE SET ${columns.filter(column => column !== table.key).map(column => `"${column}"=EXCLUDED."${column}"`).join(',')}`;
      for (const row of rows) await client.query(insert, columns.map(column => row[column]));
      console.log(`Migrated ${rows.length} row(s) from ${table.name}`);
    }
    await client.query('COMMIT');
    console.log(`SQLite data copied from ${sourcePath} to the configured PostgreSQL database.`);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await target.end();
    source.close();
  }
}

main().catch(error => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
