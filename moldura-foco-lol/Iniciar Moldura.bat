@echo off
rem Abre a Moldura de Foco sem deixar uma janela preta aberta.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0MolduraFoco.ps1"
