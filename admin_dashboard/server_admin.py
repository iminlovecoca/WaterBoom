#!/usr/bin/env python3
"""
Boom Water — Server + Admin Terminal
Chạy Godot dedicated server và quản lý admin (COKE) trong CÙNG MỘT terminal.
Khi cập nhật tiền, game đang mở sẽ tự đồng bộ ngay lập tức.

Cách dùng:
    python admin_dashboard/server_admin.py

Lệnh admin:
    help                     Xem danh sách lệnh
    users [từ khóa]          Liệt kê tài khoản (có thể lọc theo tên)
    topup <user> <số tiền>   Cộng thêm COKE
    set <user> <số tiền>     Đặt đúng số COKE
    server                   Xem trạng thái server
    quit / exit              Dừng server và thoát
"""
import os, sqlite3, subprocess, sys, threading, time, shutil

if sys.stdout and sys.stdout.encoding and sys.stdout.encoding.lower().startswith("gbk"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

GAME_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(
    os.environ.get("APPDATA", ""),
    "Godot", "app_userdata", "Boom", "boom_water_accounts.db"
)
SERVER_PORT = 7777
MAX_PLAYERS = 8


# ── Godot binary detection ────────────────────────────────────────────
def find_godot_binary():
    candidates = [
        os.path.join(os.environ["USERPROFILE"], "Downloads",
                     "Godot_v4.7.1-stable_win64.exe",
                     "Godot_v4.7.1-stable_win64_console.exe"),
        os.path.join(os.environ["USERPROFILE"], "Downloads",
                     "Godot_v4.7.1-stable_win64.exe",
                     "Godot_v4.7.1-stable_win64.exe"),
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    # Fallback: tìm Godot*.exe trong Downloads
    downloads = os.path.join(os.environ["USERPROFILE"], "Downloads")
    if os.path.isdir(downloads):
        for root, _, files in os.walk(downloads):
            for name in files:
                if name.startswith("Godot") and name.endswith(".exe"):
                    return os.path.join(root, name)
    return None


# ── Database helpers ──────────────────────────────────────────────────
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def list_users(query=""):
    conn = get_db()
    params = []
    sql = ("SELECT u.id, u.username, u.nickname, u.cokecy, "
           "u.selected_character_id, u.last_login_at, "
           "(SELECT COUNT(*) FROM user_balloon_skins s WHERE s.user_id = u.id) AS skin_count "
           "FROM users u")
    if query:
        like = f"%{query}%"
        sql += " WHERE u.username LIKE ? OR u.nickname LIKE ?"
        params = [like, like]
    sql += " ORDER BY u.id"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return rows


def update_coke(username, amount, mode="set"):
    """mode='set' đặt đúng số tiền; mode='topup' cộng thêm."""
    conn = get_db()
    row = conn.execute(
        "SELECT id, cokecy FROM users WHERE username = ? COLLATE NOCASE",
        (username,)
    ).fetchone()
    if not row:
        conn.close()
        return {"ok": False, "message": f"Không tìm thấy tài khoản '{username}'."}
    if mode == "topup":
        new_balance = int(row["cokecy"]) + amount
    else:
        new_balance = amount
    if new_balance < 0:
        conn.close()
        return {"ok": False, "message": "Số dư không thể âm."}
    conn.execute("UPDATE users SET cokecy = ? WHERE id = ?", (new_balance, row["id"]))
    conn.commit()
    conn.close()
    return {"ok": True, "message": f"'{username}' COKE = {new_balance:,}", "balance": new_balance}


# ── Server subprocess ─────────────────────────────────────────────────
class ServerProcess:
    def __init__(self):
        self.proc = None
        self.godot_bin = find_godot_binary()
        self._stop = threading.Event()

    def is_running(self):
        return self.proc is not None and self.proc.poll() is None

    def start(self):
        if not self.godot_bin:
            print("[ERROR] Không tìm thấy Godot executable trong Downloads.")
            return False
        if self.is_running():
            print("[SERVER] Server đã đang chạy.")
            return True
        print(f"[SERVER] Đang khởi động Godot server (port {SERVER_PORT})...")
        self._stop.clear()
        self.proc = subprocess.Popen(
            [self.godot_bin, "--headless", "--path", GAME_ROOT, "--", "--server"],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace",
        )
        t = threading.Thread(target=self._forward_output, daemon=True)
        t.start()
        return True

    def _forward_output(self):
        for line in self.proc.stdout:
            if self._stop.is_set():
                break
            print(f"[SERVER] {line.rstrip()}")

    def stop(self):
        if self.is_running():
            print("[SERVER] Đang dừng server...")
            self._stop.set()
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
            self.proc = None
            print("[SERVER] Server đã dừng.")


# ── Terminal UI ───────────────────────────────────────────────────────
def print_users(rows):
    if not rows:
        print("  (Không có tài khoản nào)")
        return
    print(f"  {'ID':<4} {'USERNAME':<20} {'COKE':>8} {'SKINS':>6}  LAST LOGIN")
    print("  " + "-" * 60)
    for r in rows:
        last = time.strftime("%m-%d %H:%M", time.localtime(r["last_login_at"])) if r["last_login_at"] else "-"
        print(f"  {r['id']:<4} {r['username']:<20} {r['cokecy']:>8,} {r['skin_count']:>6}  {last}")


def print_help():
    print("""
  LỆNH QUẢN LÝ:
    users [từ khóa]         Liệt kê tài khoản
    topup <user> <số tiền>  Cộng thêm COKE cho tài khoản
    set <user> <số tiền>    Đặt đúng số COKE cho tài khoản
    server start/stop        Khởi động / dừng Godot server
    help                     Xem trợ giúp
    quit / exit              Dừng server và thoát
""")


def main():
    server = ServerProcess()
    print("=" * 66)
    print("  BOOM WATER — SERVER + ADMIN TERMINAL")
    print("  Server: Godot dedicated | Admin: COKE management")
    print(f"  Database: {DB_PATH}")
    print("=" * 66)

    if not os.path.exists(DB_PATH):
        print("[WARN] Chưa có database — game cần chạy ít nhất 1 lần để tạo tài khoản.")
    else:
        print(f"[DB] Database tồn tại — {os.path.getsize(DB_PATH):,} bytes")

    server.start()
    print_help()

    while True:
        try:
            raw = input("admin> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n[EXIT] Tạm biệt!")
            break
        if not raw:
            continue

        parts = raw.split()
        cmd = parts[0].lower()
        args = parts[1:]

        if cmd in ("quit", "exit", "q"):
            server.stop()
            break
        elif cmd in ("help", "?"):
            print_help()
        elif cmd in ("server",):
            sub = args[0].lower() if args else ""
            if sub == "start":
                server.start()
            elif sub == "stop":
                server.stop()
            else:
                print(f"  Server: {'ĐANG CHẠY' if server.is_running() else 'ĐÃ DỪNG'}")
        elif cmd in ("users", "list", "ls"):
            print_users(list_users(" ".join(args) if args else ""))
        elif cmd in ("topup", "set"):
            if len(args) < 2:
                print(f"  Cách dùng: {cmd} <username> <số tiền>")
                continue
            username = args[0]
            try:
                amount = int(args[1])
            except ValueError:
                print("  Số tiền phải là số nguyên.")
                continue
            result = update_coke(username, amount, mode=cmd)
            print(f"  {'[OK]' if result['ok'] else '[!]'} {result['message']}")
            if result["ok"]:
                print("  -> Game đang mở sẽ tự cập nhật số COKE ngay.")
        else:
            print(f"  Không hiểu lệnh '{cmd}'. Gõ 'help' để xem trợ giúp.")

    server.stop()


if __name__ == "__main__":
    main()
