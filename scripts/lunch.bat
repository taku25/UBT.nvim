@echo off
setlocal

rem --- Args ---
rem 1: Engine Path (Absolute)
set "ENGINE_PATH=%~1"
shift

rem --- Assemble dotnet options ---
setlocal EnableDelayedExpansion
set "OPTIONS="

:arg_loop
if "%~1"=="" goto :end_loop

rem Handle arguments that require an equals sign, like -mode=Build
if /I "%~1"=="-mode" (
  set "OPTIONS=!OPTIONS! -mode=%~2"
  shift
  shift
  goto :arg_loop
)

rem Handle arguments that require quoted paths
if /I "%~1"=="-project" (
  set "OPTIONS=!OPTIONS! -project="%~2""
  shift
  shift
  goto :arg_loop
)

rem Add all other arguments as-is
set "OPTIONS=!OPTIONS! %~1"
shift
goto :arg_loop

:end_loop

rem --- Validate UBT ---
set "UBT_DLL=%ENGINE_PATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll"
if not exist "%UBT_DLL%" (
    echo [ERROR] UnrealBuildTool.dll not found at: "%UBT_DLL%"
    exit /b 1
)

rem --- Run ---
dotnet "%UBT_DLL%" !OPTIONS!
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%
