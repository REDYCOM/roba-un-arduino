@echo off
REM Abre el juego: levanta el servidor local y abre el navegador
cd /d "%~dp0"
start "Servidor del juego (cierra esta ventana para apagarlo)" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor.ps1"
timeout /t 2 >nul
start "" http://localhost:8080
