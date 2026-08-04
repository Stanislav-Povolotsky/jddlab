@echo off
setlocal enabledelayedexpansion
rem jddlab - real launcher (shipped INSIDE the Docker image, extracted to
rem %USERPROFILE%\.jddlab\mcp\current next to mcp\, skills\, tools\ and VERSION).
rem The thin jddlab.cmd launcher runs this and delegates every command here.
rem NOTE: capture %~dp0 up front - `shift` (used below) also shifts %0, after which
rem %~dp0 no longer points at this script.
set "jddlab_dir=%~dp0"
set "folder_to_serve=%CD%"
set jddlab_docker_image=stanislavpovolotsky/jddlab:latest
set "jddlab_launcher_version=unknown"
if exist "%jddlab_dir%VERSION" set /p jddlab_launcher_version=<"%jddlab_dir%VERSION"

if "%~1"=="update" goto update

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
set "skills_first=%~1"
set "skills_args="
:skills_args_loop
  if "%~1"=="" goto skills_execute
  set skills_args=!skills_args! "%~1"
  shift
goto skills_args_loop

:skills_execute
call :resolve_python
if /i "%skills_first%"=="update" (
  echo Skills are refreshed by "jddlab update" ^(re-extracted from the image^).
  exit /b 0
)
%jddlab_python% "%jddlab_dir%skills\install.py" %skills_args%
exit /b !ERRORLEVEL!

:mcp
shift
set "mcp_first=%~1"
set "mcp_args="
:mcp_args_loop
  if "%~1"=="" goto mcp_execute
  set mcp_args=!mcp_args! "%~1"
  shift
goto mcp_args_loop

:mcp_execute
call :resolve_python
if /i "%mcp_first%"=="update" (
  echo MCP is refreshed by "jddlab update" ^(re-extracted from the image^).
  exit /b 0
)
%jddlab_python% "%jddlab_dir%mcp\install.py" %mcp_args%
exit /b !ERRORLEVEL!

:help
echo jddlab - Java Decompilation ^& Deobfuscation Lab (image %jddlab_launcher_version%)
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
echo   jddlab update                 Pull the latest image and refresh launcher/MCP/skills
echo   jddlab mcp ^<args...^>          Manage MCP connectors (add/remove/status/doctor)
echo   jddlab skills ^<args...^>       Manage AI skills (add/remove/list)
exit /b 0

:tools
echo Tools/commands available in %jddlab_docker_image%:
docker run --rm "%jddlab_docker_image%" sh -c "ls /usr/local/bin | sort"
exit /b %ERRORLEVEL%

:version
echo jddlab image launcher: %jddlab_launcher_version%
docker run --rm "%jddlab_docker_image%" cat /usr/local/jddlab/version.txt
exit /b 0

:versions
docker run --rm "%jddlab_docker_image%" cat /usr/local/jddlab/software-list.txt
exit /b %ERRORLEVEL%

:resolve_python
set "jddlab_python=python"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=python3"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=py -3"
goto :eof

:update
echo Run "jddlab update" from your installed jddlab launcher to refresh everything.
exit /b 0
