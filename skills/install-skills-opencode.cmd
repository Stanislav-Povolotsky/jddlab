@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if "%PYTHON%"=="" set "PYTHON=python"
"%PYTHON%" "%SCRIPT_DIR%install.py" add opencode %*
exit /b %ERRORLEVEL%
