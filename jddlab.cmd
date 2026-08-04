@echo off
setlocal enabledelayedexpansion
rem jddlab - thin launcher.
rem
rem Its only job: make sure the REAL launcher (shipped inside the Docker image) is
rem present under %USERPROFILE%\.jddlab\mcp\current, then hand over to it. Download this
rem once - it rarely changes. All real functionality lives in the image and updates with
rem it via `jddlab update`.
set "jddlab_image=stanislavpovolotsky/jddlab:latest"
if "%JDDLAB_MCP_HOME%"=="" (
  set "jddlab_home=%USERPROFILE%\.jddlab\mcp"
) else (
  set "jddlab_home=%JDDLAB_MCP_HOME%"
)
set "jddlab_real=%jddlab_home%\current\jddlab.cmd"

if "%~1"=="update" if "%~2"=="" goto update

if not exist "%jddlab_real%" (
  call :extract 0
  if not exist "%jddlab_real%" (
    echo jddlab: could not fetch the launcher from the image. Is Docker running? Try "jddlab update".
    exit /b 1
  )
)

call "%jddlab_real%" %*
exit /b !ERRORLEVEL!

:update
echo Updating jddlab...
docker pull "%jddlab_image%"
set "jddlab_update_rc=!ERRORLEVEL!"
call :extract 1
exit /b !jddlab_update_rc!

rem Copy /usr/local/jddlab/host out of the image into %jddlab_home%\current via
rem `docker cp` (files owned by the host user; docker create auto-pulls if missing).
rem %1=1 forces re-extraction.
:extract
if not "%~1"=="1" if exist "%jddlab_real%" goto :eof
echo Fetching jddlab from the image...
set "jddlab_cid="
for /f "delims=" %%i in ('docker create "%jddlab_image%"') do set "jddlab_cid=%%i"
if not defined jddlab_cid goto :eof
set "jddlab_tmp=%jddlab_home%\current.new"
if exist "%jddlab_tmp%" rmdir /s /q "%jddlab_tmp%"
mkdir "%jddlab_tmp%" 2>nul
docker cp "%jddlab_cid%:/usr/local/jddlab/host/." "%jddlab_tmp%"
set "jddlab_cp_rc=%ERRORLEVEL%"
docker rm "%jddlab_cid%" >nul 2>nul
if not "%jddlab_cp_rc%"=="0" (
  if exist "%jddlab_tmp%" rmdir /s /q "%jddlab_tmp%"
  goto :eof
)
if exist "%jddlab_home%\current" rmdir /s /q "%jddlab_home%\current"
move /y "%jddlab_tmp%" "%jddlab_home%\current" >nul
goto :eof
