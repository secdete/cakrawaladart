#!/usr/bin/env python3
"""Small SQLite-backed API for the Cakrawala landing page."""

from __future__ import annotations

import json
import os
import hmac
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
    lead_columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(leads)").fetchall()
    }
    if "consent" not in lead_columns:
        connection.execute("ALTER TABLE leads ADD COLUMN consent INTEGER NOT NULL DEFAULT 0")
    if "consent_at" not in lead_columns:
        connection.execute("ALTER TABLE leads ADD COLUMN consent_at TEXT")
    connection.commit()
    seed_programs(connection)
    return connection


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
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
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
        if urlparse(self.path).path != "/api/leads":
            return self._send(404, {"error": "Endpoint tidak ditemukan."})
        now = time.time()
        ip = self.client_address[0]
        recent = [stamp for stamp in lead_requests.get(ip, []) if now - stamp < LEAD_RATE_WINDOW_SECONDS]
        if len(recent) >= LEAD_RATE_LIMIT:
            lead_requests[ip] = recent
            return self._send(429, {"error": "Terlalu banyak permintaan. Coba lagi beberapa menit."})
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
        lead, error = create_lead(payload)
        if error:
            return self._send(422, error)
        lead_requests[ip] = recent + [now]
        return self._send(201, {"item": lead})


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
