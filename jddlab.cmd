@echo off
setlocal enabledelayedexpansion
set folder_to_serve="%CD%"
set jddlab_docker_image=jddlab

set "args="
:loop
  if "%~1"=="" ( if "%~2"=="" ( if "%~3"=="" ( goto execute ) ) )
  set args=!args! "%~1"
  shift
goto loop

:execute
docker run -it --rm -v "%folder_to_serve%:/work" "%jddlab_docker_image%" %args%