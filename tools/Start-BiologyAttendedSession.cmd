@echo off
setlocal
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-BiologyAttendedSession.ps1" %*
exit /b %ERRORLEVEL%
