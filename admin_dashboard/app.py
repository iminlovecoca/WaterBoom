#!/usr/bin/env python3
"""
Boom Water — Admin Dashboard
Web-based admin panel for managing users and COKE currency.
Run: python admin_dashboard/app.py
Access: http://localhost:5000
"""
import os, sqlite3, hashlib, time
from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)

DB_PATH = os.path.join(
    os.environ.get("APPDATA", ""),
    "Godot", "app_userdata", "Boom", "boom_water_accounts.db"
)

HASH_ROUNDS = 12000

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn

def hash_password(password, salt):
    value = hashlib.sha256((salt + ":" + password).encode()).hexdigest()
    for i in range(HASH_ROUNDS):
        value = hashlib.sha256((value + salt + str(i)).encode()).hexdigest()
    return value

@app.route("/")
def index():
    conn = get_db()
    search = request.args.get("q", "").strip()

    # Stats
    row = conn.execute("SELECT COUNT(*) as cnt, COALESCE(SUM(cokecy),0) as total FROM users").fetchone()
    total_users = row["cnt"]
    total_coke = row["total"]
    yesterday = int(time.time()) - 86400
    online_row = conn.execute("SELECT COUNT(*) as cnt FROM users WHERE last_login_at > ?", (yesterday,)).fetchone()
    online_users = online_row["cnt"]

    # User list
    if search:
        like = f"%{search}%"
        rows = conn.execute(
            "SELECT u.*, (SELECT COUNT(*) FROM user_balloon_skins WHERE user_id = u.id) as skin_count "
            "FROM users u WHERE u.username LIKE ? OR u.nickname LIKE ? ORDER BY u.id",
            (like, like)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT u.*, (SELECT COUNT(*) FROM user_balloon_skins WHERE user_id = u.id) as skin_count "
            "FROM users u ORDER BY u.id"
        ).fetchall()

    users = []
    for r in rows:
        u = dict(r)
        u["created_at_str"] = time.strftime("%Y-%m-%d %H:%M", time.localtime(u["created_at"])) if u["created_at"] else "-"
        u["last_login_str"] = time.strftime("%Y-%m-%d %H:%M", time.localtime(u["last_login_at"])) if u["last_login_at"] else "Never"
        users.append(u)

    conn.close()
    return render_template('index.html', users=users, search=search,
                           total_users=total_users, total_coke=total_coke, online_users=online_users)

@app.route("/topup", methods=["POST"])
def topup():
    username = request.form.get("username", "").strip()
    amount = request.form.get("amount", "0").strip()
    if not username or not amount:
        flash("Missing username or amount.", "error")
        return redirect(url_for("index"))
    try:
        amount = int(amount)
    except ValueError:
        flash("Invalid amount.", "error")
        return redirect(url_for("index"))
    if amount <= 0 or amount > 999999:
        flash("Amount must be 1–999999.", "error")
        return redirect(url_for("index"))

    conn = get_db()
    row = conn.execute("SELECT id, cokecy FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        conn.close()
        flash(f"User '{username}' not found.", "error")
        return redirect(url_for("index"))

    new_balance = row["cokecy"] + amount
    conn.execute("UPDATE users SET cokecy = ? WHERE id = ?", (new_balance, row["id"]))
    conn.commit()
    conn.close()
    flash(f"Added {amount:,} COKE to '{username}'. New balance: {new_balance:,}", "success")
    return redirect(url_for("index"))

@app.route("/set_coke", methods=["POST"])
def set_coke():
    username = request.form.get("username", "").strip()
    amount = request.form.get("amount", "0").strip()
    if not username or not amount:
        flash("Missing username or amount.", "error")
        return redirect(url_for("index"))
    try:
        amount = int(amount)
    except ValueError:
        flash("Invalid amount.", "error")
        return redirect(url_for("index"))
    if amount < 0 or amount > 9999999:
        flash("Amount must be 0–9999999.", "error")
        return redirect(url_for("index"))

    conn = get_db()
    row = conn.execute("SELECT id FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        conn.close()
        flash(f"User '{username}' not found.", "error")
        return redirect(url_for("index"))

    new_balance = amount
    conn.execute("UPDATE users SET cokecy = ? WHERE id = ?", (new_balance, row["id"]))
    conn.commit()
    conn.close()
    flash(f"Set COKE for '{username}' to {new_balance:,}.", "success")
    return redirect(url_for("index"))

@app.route("/delete_user", methods=["POST"])
def delete_user():
    username = request.form.get("username", "").strip()
    if not username:
        flash("Missing username.", "error")
        return redirect(url_for("index"))

    conn = get_db()
    row = conn.execute("SELECT id FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
    if not row:
        conn.close()
        flash(f"User '{username}' not found.", "error")
        return redirect(url_for("index"))

    user_id = row["id"]
    try:
        conn.execute("DELETE FROM user_balloon_skins WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
        flash(f"Successfully deleted user '{username}'.", "success")
    except Exception as e:
        flash(f"Error deleting user: {str(e)}", "error")
    finally:
        conn.close()
        
    return redirect(url_for("index"))

if __name__ == "__main__":
    print(f"Database: {DB_PATH}")
    print(f"Exists: {os.path.exists(DB_PATH)}")
    print("Admin Dashboard: http://localhost:5000")
    app.run(host="127.0.0.1", port=5000, debug=True)
