#!/usr/bin/env python3
"""Small SQLite-backed API for the Cakrawala landing page."""

from __future__ import annotations

import json
import os
import hmac
import hashlib
import secrets
import re
import sqlite3
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse
from uuid import uuid4

ROOT = Path(__file__).resolve().parent
CATALOG_PATH = ROOT / "catalog.json"
DATABASE_PATH = Path(os.environ.get("DATABASE_PATH", ROOT / "data" / "cakrawala.sqlite3"))
MAX_BODY_BYTES = 16_384
LEAD_RATE_WINDOW_SECONDS = 600
LEAD_RATE_LIMIT = 6
lead_requests: dict[str, list[float]] = {}
auth_requests: dict[str, list[float]] = {}
AUTH_RATE_WINDOW_SECONDS = 600
AUTH_RATE_LIMIT = 12
SESSION_TOKEN_TTL_HOURS = 12
PASSWORD_ITERATIONS = 240_000

DEMO_ACCOUNTS = [
    {
        "id": "student-farhan",
        "email": "farhan.arya@gmail.com",
        "password": "cakrawala2026",
        "role": "student",
        "profile": {
            "name": "Farhan Arya Nugraha",
            "grade": "Kelas 12 SMA - IPA (Target SNBT)",
            "school": "SMAN Unggulan 1",
            "targetPtn": "STEI Institut Teknologi Bandung (Pilihan 1) & FK UI (Pilihan 2)",
            "activePackage": "Intensif Supercamp SNBT + Privat Fisika 1-on-1",
            "totalSessions": 24,
            "email": "farhan.arya@gmail.com",
        },
    },
    {
        "id": "parent-rina",
        "email": "rina.kusuma@gmail.com",
        "password": "cakrawala2026",
        "role": "parent",
        "profile": {
            "name": "Ibu Rina Kusuma Dewi",
            "childId": "student-farhan",
            "childName": "Farhan Arya Nugraha",
            "childGrade": "Kelas 12 SMA",
            "phone": "0812-9876-5432",
            "subscriptionStatus": "Aktif (Paket Semester Ganjil)",
            "email": "rina.kusuma@gmail.com",
        },
    },
    {
        "id": "tutor-dimas",
        "email": "dimas.prasetyo@cakrawalaeducentre.com",
        "password": "cakrawala2026",
        "role": "tutor",
        "profile": {
            "name": "Kak Dimas Prasetyo, S.Si.",
            "specialization": "Master Tutor Fisika & Penalaran Matematika (Alumnus ITB)",
            "rating": 4.95,
            "totalReviews": 148,
            "email": "dimas.prasetyo@cakrawalaeducentre.com",
        },
    },
]

SAMPLE_TRYOUT_QUESTION = {
    "id": "sample-archimedes-01",
    "subtest": "Penalaran Matematika & TPS Kuantitatif (UTBK-SNBT)",
    "question": "Sebuah balok es terapung di permukaan air laut. Jika diketahui massa jenis es adalah 0,9 g/cm³ dan massa jenis air laut adalah 1,03 g/cm³, berapakah persentase volume es yang tercelup di dalam air laut?",
    "options": ["A. 87,4%", "B. 82,5%", "C. 90,0%", "D. 75,2%", "E. 92,6%"],
    "correctIndex": 0,
    "explanation": "Berdasarkan Hukum Archimedes, benda terapung memenuhi ρ_cairan × V_tercelup = ρ_benda × V_total. Jadi, V_tercelup/V_total = 0,9/1,03 ≈ 0,8738 atau 87,4%.",
}


def connect_database() -> sqlite3.Connection:
    database_path = Path(DATABASE_PATH)
    database_path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(database_path, timeout=10)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA journal_mode=WAL")
    connection.execute(
        """CREATE TABLE IF NOT EXISTS programs (
               id TEXT PRIMARY KEY,
               grade_level TEXT NOT NULL,
               grades_json TEXT NOT NULL,
               data_json TEXT NOT NULL,
               active INTEGER NOT NULL DEFAULT 1
           )"""
    )
    connection.executescript(
        """
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
        """
    )
    connection.execute(
        """CREATE TABLE IF NOT EXISTS leads (
               id TEXT PRIMARY KEY,
               name TEXT NOT NULL,
               phone TEXT NOT NULL,
               email TEXT,
               grade TEXT NOT NULL,
               program_id TEXT,
               source TEXT NOT NULL,
               message TEXT NOT NULL DEFAULT '',
               consent INTEGER NOT NULL DEFAULT 0,
               consent_at TEXT,
               created_at TEXT NOT NULL,
               status TEXT NOT NULL DEFAULT 'new'
           )"""
    )
    connection.commit()
    question_columns = {row["name"] for row in connection.execute("PRAGMA table_info(student_questions)").fetchall()}
    if "tutor_reply" not in question_columns:
        connection.execute("ALTER TABLE student_questions ADD COLUMN tutor_reply TEXT NOT NULL DEFAULT ''")
        connection.commit()
    lead_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(leads)").fetchall()
    }
    if "consent" not in lead_columns:
        connection.execute("ALTER TABLE leads ADD COLUMN consent INTEGER NOT NULL DEFAULT 0")
    if "consent_at" not in lead_columns:
        connection.execute("ALTER TABLE leads ADD COLUMN consent_at TEXT")
    connection.commit()
    seed_programs(connection)
    seed_portal(connection)
    return connection


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _hash_password(password: str, salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, PASSWORD_ITERATIONS)


def seed_portal(connection: sqlite3.Connection) -> None:
    admin_email = os.environ.get("ADMIN_LOGIN_EMAIL", "admin@cakrawalaeducentre.com").strip().lower()
    admin_password = os.environ.get("ADMIN_LOGIN_PASSWORD", "cakrawala2026")
    accounts = [*DEMO_ACCOUNTS, {
        "id": "admin-cakrawala",
        "email": admin_email,
        "password": admin_password,
        "role": "admin",
        "profile": {"name": "Administrator Cakrawala", "email": admin_email},
    }]
    for account in accounts:
        if connection.execute("SELECT 1 FROM users WHERE id = ?", (account["id"],)).fetchone():
            continue
        salt = secrets.token_bytes(16)
        connection.execute(
            "INSERT INTO users VALUES (?, ?, ?, ?, ?, ?, 1)",
            (account["id"], account["email"], salt.hex(), _hash_password(account["password"], salt).hex(), account["role"], json.dumps(account["profile"], ensure_ascii=False)),
        )
    stamp = _now()
    if not connection.execute("SELECT 1 FROM sessions LIMIT 1").fetchone():
        connection.execute(
            "INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("ses-01", "student-farhan", "tutor-dimas", "Bedah Dinamika Rotasi & Momen Inersia", "Fisika SMA", stamp.replace(hour=16, minute=0, second=0, microsecond=0).isoformat(), "16.00 - 17.30 WIB", "Privat 1-on-1 (Online)", "Mendatang", "https://meet.google.com/ckr-fsk-12b", "Hukum Kekekalan Momentum Sudut"),
        )
        connection.execute(
            "INSERT INTO tutor_notes VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("note-01", "ses-01", "student-farhan", "tutor-dimas", "Fisika SMA", "Torsi dan momen gaya", "Baik", "Latihan 5 soal dinamika rotasi", "Farhan memahami konsep dasar dengan baik.", stamp.isoformat()),
        )
    connection.commit()


def _public_user(row: sqlite3.Row) -> dict:
    return {"id": row["id"], "email": row["email"], "role": row["role"], **json.loads(row["profile_json"])}


def _session_json(row: sqlite3.Row, student_name: str = "") -> dict:
    scheduled = datetime.fromisoformat(row["scheduled_at"])
    return {"id": row["id"], "title": row["title"], "subject": row["subject"], "tutorName": "Kak Dimas Prasetyo, S.Si.", "tutorTitle": "Master Tutor Fisika", "dateTimeFormatted": scheduled.astimezone().strftime("%d %B %Y"), "timeRange": row["time_range"], "type": row["session_type"], "status": row["status"], "meetLink": row["meet_link"], "topic": row["topic"], "studentName": student_name}


def _note_json(row: sqlite3.Row) -> dict:
    return {"id": row["id"], "dateFormatted": datetime.fromisoformat(row["created_at"]).astimezone().strftime("%d %B %Y"), "subject": row["subject"], "tutorName": "Kak Dimas Prasetyo, S.Si.", "topicCovered": row["topic_covered"], "studentComprehension": row["comprehension"], "homeworkAssigned": row["homework"], "notesForParents": row["parent_note"]}


def _require_user(handler: "ApiHandler", roles: set[str] | None = None):
    token = handler.headers.get("Authorization", "").removeprefix("Bearer ").strip()
    if not token:
        return None
    with connect_database() as connection:
        row = connection.execute("SELECT u.* FROM auth_tokens t JOIN users u ON u.id=t.user_id WHERE t.token_hash=? AND t.expires_at>? AND u.active=1", (hashlib.sha256(token.encode()).hexdigest(), _now().isoformat())).fetchone()
    if not row or (roles and row["role"] not in roles):
        return None
    return _public_user(row)


def seed_programs(connection: sqlite3.Connection) -> None:
    count = connection.execute("SELECT COUNT(*) FROM programs").fetchone()[0]
    if count:
        return
    programs = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    connection.executemany(
        "INSERT INTO programs (id, grade_level, grades_json, data_json) VALUES (?, ?, ?, ?)",
        [
            (
                program["id"],
                program["gradeLevel"],
                json.dumps(program["grades"], ensure_ascii=False),
                json.dumps(program, ensure_ascii=False),
            )
            for program in programs
        ],
    )
    connection.commit()


def list_programs(grade: str = "") -> list[dict]:
    with connect_database() as connection:
        rows = connection.execute(
            "SELECT data_json, grades_json FROM programs WHERE active = 1 ORDER BY rowid"
        ).fetchall()
    result = []
    for row in rows:
        if grade and grade != "Semua Jenjang" and grade not in json.loads(row["grades_json"]):
            continue
        result.append(json.loads(row["data_json"]))
    return result


def create_lead(payload: object) -> tuple[dict | None, dict | None]:
    if not isinstance(payload, dict):
        return None, {"error": "Body harus berupa JSON object."}

    name = str(payload.get("name", "")).strip()
    phone = str(payload.get("phone", "")).strip()
    email = str(payload.get("email", "")).strip().lower()
    grade = str(payload.get("grade", "")).strip()
    program_id = str(payload.get("programId", "")).strip() or None
    source = str(payload.get("source", "landing")).strip()
    message = str(payload.get("message", "")).strip()
    consent = payload.get("consent") is True

    errors = {}
    if not 2 <= len(name) <= 100:
        errors["name"] = "Nama wajib diisi (2–100 karakter)."
    digits = re.sub(r"\D", "", phone)
    if not 8 <= len(digits) <= 15:
        errors["phone"] = "Nomor WhatsApp harus berisi 8–15 digit."
    if email and (len(email) > 254 or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email)):
        errors["email"] = "Format email tidak valid."
    if not 1 <= len(grade) <= 80:
        errors["grade"] = "Jenjang belajar wajib dipilih."
    if not consent:
        errors["consent"] = "Persetujuan untuk dihubungi wajib diberikan."
    if source not in {"landing_consultation", "hero_consultation", "package_interest"}:
        errors["source"] = "Sumber permintaan tidak valid."
    if len(message) > 2000:
        errors["message"] = "Pesan maksimal 2.000 karakter."
    if errors:
        return None, {"error": "Periksa kembali data yang dikirim.", "fields": errors}

    lead = {
        "id": str(uuid4()),
        "name": name,
        "phone": phone,
        "email": email or None,
        "grade": grade,
        "programId": program_id,
        "source": source,
        "message": message,
        "consent": True,
        "consentAt": datetime.now(timezone.utc).isoformat(),
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "status": "new",
    }
    with connect_database() as connection:
        if program_id:
            exists = connection.execute(
                "SELECT 1 FROM programs WHERE id = ? AND active = 1", (program_id,)
            ).fetchone()
            if not exists:
                return None, {"error": "Program yang dipilih tidak ditemukan."}
        connection.execute(
            """INSERT INTO leads
               (id, name, phone, email, grade, program_id, source, message, consent, consent_at, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                lead["id"], lead["name"], lead["phone"], lead["email"], lead["grade"],
                lead["programId"], lead["source"], lead["message"], 1,
                lead["consentAt"], lead["createdAt"],
            ),
        )
    return lead, None


class ApiHandler(BaseHTTPRequestHandler):
    server_version = "CakrawalaLandingAPI/1.0"

    def log_message(self, format: str, *args) -> None:
        print(f"[{self.log_date_time_string()}] {self.address_string()} {format % args}")

    def _cors(self) -> None:
        origin = self.headers.get("Origin", "")
        allowed = [item.strip() for item in os.environ.get("CORS_ORIGINS", "*").split(",")]
        if "*" in allowed:
            self.send_header("Access-Control-Allow-Origin", "*")
        elif origin in allowed:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PATCH, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Max-Age", "86400")

    def _send(self, status: int, body: dict | list, content_type: str = "application/json") -> None:
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/health":
            return self._send(200, {"ok": True, "service": "cakrawala-landing"})
        if parsed.path == "/api/programs":
            grade = parse_qs(parsed.query).get("grade", [""])[0].strip()
            return self._send(200, {"items": list_programs(grade)})
        if parsed.path in {"/api/me", "/api/student/dashboard", "/api/parent/dashboard", "/api/tutor/dashboard", "/api/admin/dashboard"}:
            user = _require_user(self)
            if not user:
                return self._send(401, {"error": "Sesi tidak valid atau sudah berakhir."})
            if parsed.path == "/api/me":
                return self._send(200, {"user": user})
            expected_role = parsed.path.split("/")[2]
            if user["role"] != expected_role:
                return self._send(403, {"error": "Akun tidak memiliki akses ke dashboard ini."})
            with connect_database() as connection:
                if expected_role == "admin":
                    rows = connection.execute("SELECT * FROM leads ORDER BY created_at DESC LIMIT 500").fetchall()
                    leads = [dict(row) for row in rows]
                    return self._send(200, {"profile": user, "leads": leads, "summary": {"totalLeads": len(leads), "newLeads": sum(lead["status"] == "new" for lead in leads)}})
                student_id = user["id"] if expected_role == "student" else user.get("childId", "") if expected_role == "parent" else ""
                if expected_role == "tutor":
                    rows = connection.execute("SELECT s.*, u.profile_json FROM sessions s JOIN users u ON u.id=s.student_id WHERE s.tutor_id=? ORDER BY s.scheduled_at", (user["id"],)).fetchall()
                    sessions = [_session_json(row, json.loads(row["profile_json"])["name"]) for row in rows]
                    notes_rows = connection.execute("SELECT n.*,u.profile_json FROM tutor_notes n JOIN users u ON u.id=n.student_id WHERE n.tutor_id=? ORDER BY n.created_at DESC", (user["id"],)).fetchall()
                    notes = [{**_note_json(row), "studentName": json.loads(row["profile_json"])["name"], "studentId": row["student_id"]} for row in notes_rows]
                    question_rows = connection.execute("SELECT q.*,u.profile_json FROM student_questions q JOIN users u ON u.id=q.student_id WHERE EXISTS (SELECT 1 FROM sessions s WHERE s.student_id=q.student_id AND s.tutor_id=?) ORDER BY q.created_at DESC", (user["id"],)).fetchall()
                    questions = [{"id":r["id"],"studentId":r["student_id"],"studentName":json.loads(r["profile_json"])["name"],"question":r["question"],"status":r["status"],"createdAt":r["created_at"],"reply":r["tutor_reply"]} for r in question_rows]
                    return self._send(200, {"profile": user, "sessions": sessions, "notes": notes, "questions": questions, "summary": {"totalSessions": len(sessions), "upcomingSessions": sum(s["status"] == "Mendatang" for s in sessions), "totalStudents": len({s["studentName"] for s in sessions})}})
                sessions_rows = connection.execute("SELECT * FROM sessions WHERE student_id=? ORDER BY scheduled_at", (student_id,)).fetchall()
                notes_rows = connection.execute("SELECT * FROM tutor_notes WHERE student_id=? ORDER BY created_at DESC", (student_id,)).fetchall()
                attempts = connection.execute("SELECT COUNT(*) count, SUM(is_correct) correct FROM tryout_attempts WHERE student_id=?", (student_id,)).fetchone()
                questions = connection.execute("SELECT COUNT(*) FROM student_questions WHERE student_id=?", (student_id,)).fetchone()[0]
            profile = user
            if expected_role == "parent":
                with connect_database() as connection:
                    child = connection.execute("SELECT profile_json FROM users WHERE id=?", (student_id,)).fetchone()
                profile = {**user, "child": json.loads(child["profile_json"]) if child else {}}
            with connect_database() as connection:
                question_rows = connection.execute("SELECT * FROM student_questions WHERE student_id=? ORDER BY created_at DESC", (student_id,)).fetchall()
            student_questions = [{"id":r["id"],"question":r["question"],"status":r["status"],"createdAt":r["created_at"],"reply":r["tutor_reply"]} for r in question_rows]
            return self._send(200, {"profile": profile, "sessions": [_session_json(row) for row in sessions_rows], "notes": [_note_json(row) for row in notes_rows], "questions":student_questions, "tryouts": [{"id":"sample-tryout", "title":"Drill Penalaran Kuantitatif", "category":"UTBK-SNBT", "totalQuestions":1, "durationMinutes":10, "score": int(attempts["correct"] or 0) * 100 if attempts["count"] else None, "rank":None, "totalParticipants":None, "status":"Selesai" if attempts["count"] else "Tersedia", "deadlineFormatted":"Latihan interaktif"}], "summary": {"questionsAsked": questions, "attempts": attempts["count"], "correctAnswers": attempts["correct"] or 0}})
        if parsed.path == "/api/tryouts/sample/question":
            user = _require_user(self, {"student"})
            if not user: return self._send(401, {"error":"Login siswa diperlukan."})
            return self._send(200, {"question": {k:v for k,v in SAMPLE_TRYOUT_QUESTION.items() if k not in {"correctIndex","explanation"}}})
        if parsed.path == "/api/admin/leads":
            expected = os.environ.get("ADMIN_API_TOKEN", "")
            authorization = self.headers.get("Authorization", "")
            supplied = authorization.removeprefix("Bearer ")
            if not expected:
                return self._send(503, {"error": "ADMIN_API_TOKEN belum dikonfigurasi."})
            if not hmac.compare_digest(supplied, expected):
                return self._send(401, {"error": "Token admin tidak valid."})
            try:
                requested_limit = int(parse_qs(parsed.query).get("limit", ["100"])[0])
            except ValueError:
                requested_limit = 100
            limit = min(max(requested_limit, 1), 500)
            with connect_database() as connection:
                rows = connection.execute(
                    "SELECT * FROM leads ORDER BY created_at DESC LIMIT ?", (limit,)
                ).fetchall()
            items = [dict(row) for row in rows]
            return self._send(200, {"items": items})
        return self._send(404, {"error": "Endpoint tidak ditemukan."})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        if path not in {"/api/leads", "/api/auth/login", "/api/auth/logout", "/api/student/questions", "/api/tryouts/sample/answer", "/api/tutor/notes"} and not re.fullmatch(r"/api/tutor/questions/[^/]+/reply",path):
            return self._send(404, {"error": "Endpoint tidak ditemukan."})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self._send(400, {"error": "Content-Length tidak valid."})
        if length <= 0 or length > MAX_BODY_BYTES:
            return self._send(413, {"error": "Ukuran permintaan tidak valid."})
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return self._send(400, {"error": "Body harus berupa JSON yang valid."})
        if not isinstance(payload, dict): return self._send(400, {"error":"Body JSON harus object."})
        if path == "/api/auth/login":
            ip = self.client_address[0]; now = time.time()
            recent = [stamp for stamp in auth_requests.get(ip, []) if now-stamp<AUTH_RATE_WINDOW_SECONDS]
            if len(recent) >= AUTH_RATE_LIMIT: return self._send(429, {"error":"Terlalu banyak percobaan masuk. Coba lagi nanti."})
            email = str(payload.get("email", "")).strip().lower(); password = str(payload.get("password", ""))
            with connect_database() as connection:
                row = connection.execute("SELECT * FROM users WHERE email=? AND active=1", (email,)).fetchone()
                valid = bool(row and hmac.compare_digest(_hash_password(password, bytes.fromhex(row["password_salt"])).hex(), row["password_hash"]))
                if valid:
                    token = secrets.token_urlsafe(32)
                    connection.execute("INSERT INTO auth_tokens VALUES (?, ?, ?, ?)", (hashlib.sha256(token.encode()).hexdigest(), row["id"], (_now()+__import__('datetime').timedelta(hours=SESSION_TOKEN_TTL_HOURS)).isoformat(), _now().isoformat()))
            auth_requests[ip] = recent + [now]
            if not valid: return self._send(401, {"error":"Email atau kata sandi belum sesuai."})
            return self._send(200, {"token":token, "user":_public_user(row)})
        if path == "/api/auth/logout":
            token=self.headers.get("Authorization","").removeprefix("Bearer ").strip()
            if token:
                with connect_database() as connection: connection.execute("DELETE FROM auth_tokens WHERE token_hash=?", (hashlib.sha256(token.encode()).hexdigest(),))
            return self._send(200, {"ok":True})
        if path == "/api/leads":
            now = time.time(); ip = self.client_address[0]
            recent = [stamp for stamp in lead_requests.get(ip, []) if now-stamp<LEAD_RATE_WINDOW_SECONDS]
            if len(recent) >= LEAD_RATE_LIMIT:
                lead_requests[ip] = recent
                return self._send(429, {"error":"Terlalu banyak permintaan. Coba lagi beberapa menit."})
            lead, error = create_lead(payload)
            if error: return self._send(422,error)
            lead_requests[ip]=recent+[now]
            return self._send(201,{"item":lead})
        user = _require_user(self)
        if not user: return self._send(401, {"error":"Sesi tidak valid atau sudah berakhir."})
        reply_match = re.fullmatch(r"/api/tutor/questions/([^/]+)/reply", path)
        if reply_match:
            if user["role"] != "tutor": return self._send(403,{"error":"Hanya tutor dapat membalas pertanyaan."})
            reply=str(payload.get("reply","")).strip()
            if not 2 <= len(reply) <= 2000: return self._send(422,{"error":"Balasan harus berisi 2–2.000 karakter."})
            with connect_database() as connection:
                cursor=connection.execute("UPDATE student_questions SET tutor_reply=?,status='Dijawab' WHERE id=? AND EXISTS (SELECT 1 FROM sessions s WHERE s.student_id=student_questions.student_id AND s.tutor_id=?)",(reply,reply_match.group(1),user["id"]))
                if not cursor.rowcount: return self._send(404,{"error":"Pertanyaan tidak ditemukan untuk siswa bimbingan tutor ini."})
            return self._send(200,{"ok":True,"status":"Dijawab"})
        if path == "/api/student/questions":
            if user["role"] != "student": return self._send(403, {"error":"Hanya siswa dapat mengirim pertanyaan."})
            question=str(payload.get("question","")).strip()
            if not 5 <= len(question) <= 2000: return self._send(422, {"error":"Pertanyaan harus berisi 5–2.000 karakter."})
            item={"id":str(uuid4()),"question":question,"status":"Menunggu tutor","createdAt":_now().isoformat()}
            with connect_database() as connection: connection.execute("INSERT INTO student_questions (id,student_id,question,status,created_at,tutor_reply) VALUES (?, ?, ?, ?, ?, '')",(item["id"],user["id"],question,item["status"],item["createdAt"]))
            return self._send(201,{"item":item})
        if path == "/api/tryouts/sample/answer":
            if user["role"] != "student": return self._send(403,{"error":"Hanya siswa dapat mengerjakan tryout."})
            try: selected=int(payload.get("selectedIndex"))
            except (ValueError,TypeError): return self._send(422,{"error":"Pilihan jawaban tidak valid."})
            if not 0 <= selected < len(SAMPLE_TRYOUT_QUESTION["options"]): return self._send(422,{"error":"Pilihan jawaban tidak tersedia."})
            correct=selected==SAMPLE_TRYOUT_QUESTION["correctIndex"]
            with connect_database() as connection: connection.execute("INSERT INTO tryout_attempts VALUES (?, ?, ?, ?, ?, ?)",(str(uuid4()),user["id"],SAMPLE_TRYOUT_QUESTION["id"],selected,int(correct),_now().isoformat()))
            return self._send(200,{"isCorrect":correct,"correctIndex":SAMPLE_TRYOUT_QUESTION["correctIndex"],"explanation":SAMPLE_TRYOUT_QUESTION["explanation"]})
        if path == "/api/tutor/notes":
            if user["role"] != "tutor": return self._send(403,{"error":"Hanya tutor dapat menulis catatan."})
            fields={"studentId":str(payload.get("studentId","")),"subject":str(payload.get("subject","Fisika" )).strip(),"topicCovered":str(payload.get("topicCovered","")).strip(),"comprehension":str(payload.get("comprehension","Baik")).strip(),"homework":str(payload.get("homework","")).strip(),"parentNote":str(payload.get("parentNote","")).strip()}
            if not fields["topicCovered"]: return self._send(422,{"error":"Topik pembelajaran wajib diisi."})
            with connect_database() as connection:
                owned=connection.execute("SELECT 1 FROM sessions WHERE tutor_id=? AND student_id=?",(user["id"],fields["studentId"])).fetchone()
                if not owned: return self._send(403,{"error":"Siswa tidak ditugaskan kepada tutor ini."})
                note={"id":str(uuid4()),"session_id":payload.get("sessionId"),"student_id":fields["studentId"],"tutor_id":user["id"],"subject":fields["subject"],"topic_covered":fields["topicCovered"],"comprehension":fields["comprehension"],"homework":fields["homework"],"parent_note":fields["parentNote"],"created_at":_now().isoformat()}
                connection.execute("INSERT INTO tutor_notes VALUES (:id,:session_id,:student_id,:tutor_id,:subject,:topic_covered,:comprehension,:homework,:parent_note,:created_at)",note)
            return self._send(201,{"item":{"id":note["id"],"dateFormatted":_now().astimezone().strftime("%d %B %Y"),"subject":note["subject"],"tutorName":user["name"],"topicCovered":note["topic_covered"],"studentComprehension":note["comprehension"],"homeworkAssigned":note["homework"],"notesForParents":note["parent_note"]}})

    def do_PATCH(self) -> None:
        match = re.fullmatch(r"/api/tutor/sessions/([^/]+)", urlparse(self.path).path)
        if not match: return self._send(404,{"error":"Endpoint tidak ditemukan."})
        tutor = _require_user(self,{"tutor"})
        if not tutor: return self._send(401,{"error":"Login tutor diperlukan."})
        try:
            length=int(self.headers.get("Content-Length","0")); payload=json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError,UnicodeDecodeError,json.JSONDecodeError): return self._send(400,{"error":"Body JSON tidak valid."})
        status=str(payload.get("status",""))
        if status not in {"Selesai","Dibatalkan"}: return self._send(422,{"error":"Status sesi tidak valid."})
        with connect_database() as connection:
            cursor=connection.execute("UPDATE sessions SET status=? WHERE id=? AND tutor_id=?",(status,match.group(1),tutor["id"]))
            if cursor.rowcount == 0: return self._send(404,{"error":"Sesi tidak ditemukan untuk tutor ini."})
        return self._send(200,{"ok":True,"status":status})


def main() -> None:
    connect_database().close()
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8000"))
    server = ThreadingHTTPServer((host, port), ApiHandler)
    print(f"Cakrawala landing API aktif: http://{host}:{port}/api")
    print(f"SQLite: {DATABASE_PATH}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nAPI dihentikan.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
