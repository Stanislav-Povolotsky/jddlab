@echo off
setlocal enabledelayedexpansion
set "folder_to_serve=%CD%"
set jddlab_docker_image=stanislavpovolotsky/jddlab:latest
set jddlab_launcher_version=1.0

if "%~1"=="update" (
  echo Updating jddlab...
  docker pull "%jddlab_docker_image%"
  exit /b %ERRORLEVEL%
)

if "%~2"=="" (
  if "%~1"=="help" goto help
  if "%~1"=="--help" goto help
  if "%~1"=="-h" goto help
  if "%~1"=="tools" goto tools
  if "%~1"=="--tools" goto tools
  if "%~1"=="version" goto version
  if "%~1"=="--version" goto version
  if "%~1"=="versions" goto versions
  if "%~1"=="--versions" goto versions
)

if "%~1"=="mcp" goto mcp
if "%~1"=="skills" goto skills

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

:skills
shift
set "skills_args="
:skills_args_loop
  if "%~1"=="" goto skills_execute
  set skills_args=!skills_args! "%~1"
  shift
goto skills_args_loop

:skills_execute
set "jddlab_python=python"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=python3"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=py -3"
if exist "%~dp0skills\install.py" (
  %jddlab_python% "%~dp0skills\install.py" %skills_args%
  exit /b !ERRORLEVEL!
)
if "%JDDLAB_SKILLS_INSTALL_URL%"=="" set "JDDLAB_SKILLS_INSTALL_URL=https://raw.githubusercontent.com/Stanislav-Povolotsky/jddlab/refs/heads/main/skills/install.py"
set "jddlab_skills_tmp=%TEMP%\jddlab_skills_%RANDOM%.py"
curl -fsSL "%JDDLAB_SKILLS_INSTALL_URL%" -o "%jddlab_skills_tmp%"
if errorlevel 1 (
  echo Failed to download skills/install.py from %JDDLAB_SKILLS_INSTALL_URL%
  del /f /q "%jddlab_skills_tmp%" 2>nul
  exit /b 1
)
%jddlab_python% "%jddlab_skills_tmp%" %skills_args%
set "jddlab_exit=%ERRORLEVEL%"
del /f /q "%jddlab_skills_tmp%" 2>nul
exit /b !jddlab_exit!

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

:help
echo jddlab - Java Decompilation ^& Deobfuscation Lab (launcher %jddlab_launcher_version%)
echo.
echo Usage:
echo   jddlab                       Enter an interactive shell inside the jddlab container
echo   jddlab ^<command^> [args...]    Run a bundled tool (e.g. "jddlab apktool --version")
echo.
echo Launcher sub-commands:
echo   jddlab help ^| --help          Show this help
echo   jddlab tools ^| --tools        List the tools/commands available in the image
echo   jddlab version ^| --version    Show launcher and image build versions
echo   jddlab versions ^| --versions  Show versions of every bundled tool
echo   jddlab update                 Pull the latest jddlab image
echo   jddlab mcp ^<args...^>          Manage MCP connectors (add/remove/status/doctor/update)
echo   jddlab skills ^<args...^>       Manage AI skills (add/remove/list)
exit /b 0

:tools
echo Tools/commands available in %jddlab_docker_image%:
docker run --rm "%jddlab_docker_image%" sh -c "ls /usr/local/bin | sort"
exit /b %ERRORLEVEL%

:version
echo jddlab launcher: %jddlab_launcher_version%
docker run --rm "%jddlab_docker_image%" cat /usr/local/jddlab/version.txt
if errorlevel 1 echo Image not available locally. Run "jddlab update" to pull it.
exit /b 0

:versions
docker run --rm "%jddlab_docker_image%" cat /usr/local/jddlab/software-list.txt
exit /b %ERRORLEVEL%
