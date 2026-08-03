@echo off
setlocal enabledelayedexpansion
set "folder_to_serve=%CD%"
set jddlab_docker_image=stanislavpovolotsky/jddlab:latest
set jddlab_launcher_version=1.0

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
set "skills_first=%~1"
set "skills_args="
:skills_args_loop
  if "%~1"=="" goto skills_execute
  set skills_args=!skills_args! "%~1"
  shift
goto skills_args_loop

:skills_execute
call :resolve_python
rem `jddlab skills update` refreshes the extracted copy from the image.
if /i "%skills_first%"=="update" (
  call :extract_bundle 1
  if "!jddlab_extract_rc!"=="0" echo jddlab MCP/skills refreshed from the image.
  exit /b !jddlab_extract_rc!
)
rem Repo checkout: install the local skills directly (dev-friendly).
if exist "%~dp0skills\install.py" (
  %jddlab_python% "%~dp0skills\install.py" %skills_args%
  exit /b !ERRORLEVEL!
)
rem Standalone: run the installer copied out of the image.
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_mcp_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_mcp_home=%JDDLAB_MCP_HOME%"
)
if not exist "%jddlab_mcp_home%\current\skills\install.py" (
  call :extract_bundle
  if not "!jddlab_extract_rc!"=="0" (
    echo Failed to extract skills from the image. Is Docker running and the image pulled? Try "jddlab update".
    exit /b 1
  )
)
%jddlab_python% "%jddlab_mcp_home%\current\skills\install.py" %skills_args%
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
rem `jddlab mcp update` refreshes the extracted copy from the image.
if /i "%mcp_first%"=="update" (
  call :extract_bundle 1
  if "!jddlab_extract_rc!"=="0" echo jddlab MCP/skills refreshed from the image.
  exit /b !jddlab_extract_rc!
)
rem Repo checkout: run the local installer directly (dev-friendly).
if exist "%~dp0mcp\install.py" (
  %jddlab_python% "%~dp0mcp\install.py" %mcp_args%
  exit /b !ERRORLEVEL!
)
rem Standalone: run the installer copied out of the image.
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_mcp_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_mcp_home=%JDDLAB_MCP_HOME%"
)
if not exist "%jddlab_mcp_home%\current\mcp\install.py" (
  call :extract_bundle
  if not "!jddlab_extract_rc!"=="0" (
    echo Failed to extract MCP files from the image. Is Docker running and the image pulled? Try "jddlab update".
    exit /b 1
  )
)
%jddlab_python% "%jddlab_mcp_home%\current\mcp\install.py" %mcp_args%
exit /b !ERRORLEVEL!

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
echo   jddlab update                 Pull the latest image (and refresh installed MCP/skills)
echo   jddlab mcp ^<args...^>          Manage MCP connectors (add/remove/status/doctor/update)
echo   jddlab skills ^<args...^>       Manage AI skills (add/remove/list/update)
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

:resolve_python
set "jddlab_python=python"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=python3"
where %jddlab_python% >nul 2>nul
if errorlevel 1 set "jddlab_python=py -3"
goto :eof

rem Copy /usr/local/jddlab/host out of the image into %jddlab_mcp_home%\current via
rem `docker cp` (files owned by the host user). Arg %1 = 1 to force re-extraction.
rem Sets jddlab_extract_rc to 0 on success, 1 on failure.
:extract_bundle
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_mcp_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_mcp_home=%JDDLAB_MCP_HOME%"
)
if not "%~1"=="1" if exist "%jddlab_mcp_home%\current\mcp\server.py" (
  set "jddlab_extract_rc=0"
  goto :eof
)
echo Extracting jddlab MCP/skills from the image...
set "jddlab_cid="
for /f "delims=" %%i in ('docker create "%jddlab_docker_image%"') do set "jddlab_cid=%%i"
if not defined jddlab_cid (
  set "jddlab_extract_rc=1"
  goto :eof
)
set "jddlab_tmp=%jddlab_mcp_home%\current.new"
if exist "%jddlab_tmp%" rmdir /s /q "%jddlab_tmp%"
mkdir "%jddlab_tmp%" 2>nul
docker cp "%jddlab_cid%:/usr/local/jddlab/host/." "%jddlab_tmp%"
set "jddlab_cp_rc=%ERRORLEVEL%"
docker rm "%jddlab_cid%" >nul 2>nul
if not "%jddlab_cp_rc%"=="0" (
  if exist "%jddlab_tmp%" rmdir /s /q "%jddlab_tmp%"
  set "jddlab_extract_rc=1"
  goto :eof
)
if exist "%jddlab_mcp_home%\current" rmdir /s /q "%jddlab_mcp_home%\current"
move /y "%jddlab_tmp%" "%jddlab_mcp_home%\current" >nul
set "jddlab_extract_rc=0"
goto :eof

:update
echo Updating jddlab...
docker pull "%jddlab_docker_image%"
set "jddlab_update_rc=%ERRORLEVEL%"
rem Refresh the extracted MCP/skills if they were installed under %USERPROFILE%\.jddlab.
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_mcp_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_mcp_home=%JDDLAB_MCP_HOME%"
)
if exist "%jddlab_mcp_home%\current" (
  echo Refreshing installed jddlab MCP/skills from the image...
  call :extract_bundle 1
)
exit /b %jddlab_update_rc%
