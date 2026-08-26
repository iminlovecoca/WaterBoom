@echo off
title BOOM ONLINE - REAL-TIME WEB ADMIN
echo ============================================================
echo   DANG KHOI DONG TRANG QUAN TRI GAME REAL-TIME...
echo ============================================================
cd /d "%~dp0"
start http://localhost:8080/admin.html
python admin_server.py
pause
