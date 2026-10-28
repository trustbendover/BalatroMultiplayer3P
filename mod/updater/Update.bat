@echo off
rem Balatro High Stakes - check for and install the latest release from GitHub
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
