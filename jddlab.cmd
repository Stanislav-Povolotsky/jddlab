@echo off
setlocal enabledelayedexpansion
set folder_to_serve="%CD%"
set jddlab_docker_image=stanislavpovolotsky/jddlab:latest

if "%~1"=="update" (
  echo Updating jddlab...
  docker pull "%jddlab_docker_image%"
  exit /b %ERRORLEVEL%
)

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
