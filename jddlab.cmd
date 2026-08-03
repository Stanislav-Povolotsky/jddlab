@echo off
setlocal enabledelayedexpansion
set "folder_to_serve=%CD%"
set jddlab_docker_image=stanislavpovolotsky/jddlab:latest

if "%~1"=="update" (
  echo Updating jddlab...
  docker pull "%jddlab_docker_image%"
  exit /b %ERRORLEVEL%
)

if "%~1"=="mcp" goto mcp

set docker_args=
rem Allow to access host network. It's usefull to forward adb to instance.
rem Just run "adb start-server" on host machine and adb inside the instance 
rem will be able to connect to your device.
rem set docker_args=%docker_args% --network="host"

set "args="
:loop
  if "%~1"=="" ( if "%~2"=="" ( if "%~3"=="" ( goto execute ) ) )
  set args=!args! "%~1"
  shift
goto loop

:execute
docker run -it --rm %docker_args% -v "%folder_to_serve%:/work" "%jddlab_docker_image%" %args%
exit /b %ERRORLEVEL%

:mcp
shift
set "mcp_args="
:mcp_args_loop
  if "%~1"=="" goto mcp_execute
  set mcp_args=!mcp_args! "%~1"
  shift
goto mcp_args_loop

:mcp_execute
set "jddlab_python=python"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=python3"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=py -3"
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_mcp_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_mcp_home=%JDDLAB_MCP_HOME%"
)
if exist "%jddlab_mcp_home%\current\mcp\bootstrap.py" (
  %jddlab_python% "%jddlab_mcp_home%\current\mcp\bootstrap.py" %mcp_args%
  exit /b !ERRORLEVEL!
)
if exist "%~dp0mcp\bootstrap.py" (
  %jddlab_python% "%~dp0mcp\bootstrap.py" %mcp_args%
  exit /b !ERRORLEVEL!
)
if "%JDDLAB_MCP_BOOTSTRAP_URL%"=="" set "JDDLAB_MCP_BOOTSTRAP_URL=https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/mcp/bootstrap.py"
set "jddlab_bootstrap_tmp=%TEMP%\jddlab_bootstrap_%RANDOM%.py"
curl -fsSL "%JDDLAB_MCP_BOOTSTRAP_URL%" -o "%jddlab_bootstrap_tmp%"
if errorlevel 1 (
  echo Failed to download bootstrap.py from %JDDLAB_MCP_BOOTSTRAP_URL%
  del /f /q "%jddlab_bootstrap_tmp%" 2>nul
  exit /b 1
)
%jddlab_python% "%jddlab_bootstrap_tmp%" %mcp_args%
set "jddlab_exit=%ERRORLEVEL%"
del /f /q "%jddlab_bootstrap_tmp%" 2>nul
exit /b !jddlab_exit!
