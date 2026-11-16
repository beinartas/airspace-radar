@echo off
title SYS.AIRSPACE // LOCAL ADS-B PROXY
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
