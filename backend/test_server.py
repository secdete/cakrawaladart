import json
import os
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import server


class LandingApiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.TemporaryDirectory()
        server.DATABASE_PATH = os.path.join(cls.temp_dir.name, "test.sqlite3")
        cls.httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.ApiHandler)
        cls.base_url = f"http://127.0.0.1:{cls.httpd.server_port}"
        cls.thread = threading.Thread(target=cls.httpd.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.httpd.server_close()
        cls.thread.join(timeout=2)
        cls.temp_dir.cleanup()

    def setUp(self):
        server.lead_requests.clear()

    def request_json(self, path, payload=None, headers=None):
        data = None if payload is None else json.dumps(payload).encode("utf-8")
        request = Request(
            self.base_url + path,
            data=data,
            headers={"Content-Type": "application/json", **(headers or {})},
            method="GET" if payload is None else "POST",
        )
        try:
            with urlopen(request, timeout=3) as response:
                return response.status, json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            return error.code, json.loads(error.read().decode("utf-8"))

    def test_health_and_catalog_filter(self):
        status, health = self.request_json("/api/health")
        self.assertEqual(status, 200)
        self.assertTrue(health["ok"])

        status, catalog = self.request_json("/api/programs?grade=SMA%20-%20Kelas%2012")
        self.assertEqual(status, 200)
        self.assertEqual(len(catalog["items"]), 5)

        status, catalog = self.request_json("/api/programs?grade=Kedinasan")
        self.assertEqual(status, 200)
        self.assertEqual([item["id"] for item in catalog["items"]], ["prog-privat-2", "prog-kedinasan-5"])

    def test_lead_submission_is_validated_and_persisted(self):
        payload = {
            "name": "Alya Putri",
            "phone": "+62 812-3456-7890",
            "email": "alya@example.com",
            "grade": "SMA - Kelas 12",
            "programId": "prog-snbt-1",
            "source": "package_interest",
            "message": "Minta info jadwal",
            "consent": True,
        }
        status, body = self.request_json("/api/leads", payload)
        self.assertEqual(status, 201)
        self.assertEqual(body["item"]["programId"], "prog-snbt-1")

        with server.connect_database() as connection:
            row = connection.execute("SELECT * FROM leads WHERE id = ?", (body["item"]["id"],)).fetchone()
        self.assertIsNotNone(row)
        self.assertEqual(row["name"], "Alya Putri")
        self.assertEqual(row["consent"], 1)

    def test_invalid_lead_is_rejected(self):
        status, body = self.request_json(
            "/api/leads",
            {"name": "A", "phone": "123", "grade": "", "source": "landing_consultation"},
        )
        self.assertEqual(status, 422)
        self.assertIn("fields", body)

    def test_public_endpoint_cannot_read_leads(self):
        status, body = self.request_json("/api/admin/leads")
        self.assertEqual(status, 503)
        self.assertIn("ADMIN_API_TOKEN", body["error"])

    def test_lead_rate_limit(self):
        payload = {
            "name": "Alya Putri",
            "phone": "081234567890",
            "grade": "SMA - Kelas 12",
            "source": "landing_consultation",
            "consent": True,
        }
        for _ in range(server.LEAD_RATE_LIMIT):
            self.assertEqual(self.request_json("/api/leads", payload)[0], 201)
        status, _ = self.request_json("/api/leads", payload)
        self.assertEqual(status, 429)


if __name__ == "__main__":
    unittest.main()
