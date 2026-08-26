@echo off
title Boom 2D - Dedicated Server (Port 7777)
echo ========================================================
echo        BOOM 2D - DEDICATED SERVER IS RUNNING
echo ========================================================
echo Port: 7777 (UDP)
echo Max Players: 8
echo.

set GODOT_BIN=""
if exist "%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" (
    set GODOT_BIN="%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
) else if exist "%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe" (
    set GODOT_BIN="%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
) else if exist "%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe" (
    set GODOT_BIN="%USERPROFILE%\Downloads\Godot_v4.7.1-stable_win64.exe"
)

if not %GODOT_BIN%=="" (
    %GODOT_BIN% --headless --path "%~dp0." -- --server
    goto end
)

REM Fallback search in Downloads
for /r "%USERPROFILE%\Downloads" %%i in (Godot*.exe) do (
    if exist "%%i" (
        "%%i" --headless --path "%~dp0." -- --server
        goto end
    )
)

echo [ERROR] Could not find Godot executable.
pause

:end
