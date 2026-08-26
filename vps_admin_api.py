import sqlite3
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

DB_PATH = "/home/coca/.local/share/godot/app_userdata/Boom/boom_water_accounts.db"

class AdminHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)

    def do_GET(self):
        if self.path == "/api/players":
            try:
                conn = sqlite3.connect(DB_PATH)
                conn.row_factory = sqlite3.Row
                cur = conn.cursor()
                cur.execute("SELECT id, username, nickname, cokecy, level, experience, selected_character_id FROM users ORDER BY id ASC")
                rows = [dict(r) for r in cur.fetchall()]
                conn.close()
                self._set_headers(200)
                self.wfile.write(json.dumps({"ok": True, "players": rows}).encode())
            except Exception as e:
                self._set_headers(500)
                self.wfile.write(json.dumps({"ok": False, "error": str(e)}).encode())
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({"ok": False, "error": "Not Found"}).encode())

    def do_POST(self):
        content_len = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_len)
        data = json.loads(post_data.decode('utf-8')) if post_data else {}

        if self.path == "/api/topup":
            username = data.get("username")
            amount = int(data.get("amount", 0))
            if not username or amount <= 0:
                self._set_headers(400)
                self.wfile.write(json.dumps({"ok": False, "error": "Invalid params"}).encode())
                return
            
            try:
                conn = sqlite3.connect(DB_PATH)
                cur = conn.cursor()
                cur.execute("UPDATE users SET cokecy = cokecy + ? WHERE username = ?", (amount, username))
                conn.commit()
                cur.execute("SELECT cokecy FROM users WHERE username = ?", (username,))
                res = cur.fetchone()
                conn.close()

                new_balance = res[0] if res else 0
                self._set_headers(200)
                self.wfile.write(json.dumps({"ok": True, "username": username, "new_balance": new_balance}).encode())
            except Exception as e:
                self._set_headers(500)
                self.wfile.write(json.dumps({"ok": False, "error": str(e)}).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), AdminHandler)
    print("Real-time VPS Admin API running on port 8080...")
    server.serve_forever()
