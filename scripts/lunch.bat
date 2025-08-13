@echo off
setlocal

rem args
set "TYPE=%~1"
shift
set "VALUE=%~1"
shift


setlocal EnableDelayedExpansion
set "OPTIONS="


:arg_loop
if "%~1"=="" goto :end_loop

:: 特定のキーに対して次の引数をクォート付きで追加
if /I "%~1"=="-mode" (
  set "OPTIONS=!OPTIONS! -mode=%~2"
  shift
  shift
  goto :arg_loop
)

if /I "%~1"=="-project" (
  set "OPTIONS=!OPTIONS! -project="%~2""
  shift
  shift
  goto :arg_loop
)

if /I "%~1"=="-OutputDir" (
  set "OPTIONS=!OPTIONS! -OutputDir="%~2""
  shift
  shift
  goto :arg_loop
)

if /I "%~1"=="-StaticAnalyzer" (
  set "OPTIONS=!OPTIONS! -StaticAnalyzer=%~2"
  shift
  shift
  goto :arg_loop
)

:: その他の引数はそのまま追加
set "OPTIONS=!OPTIONS! %~1"
shift
goto :arg_loop

:end_loop

REM echo Final OPTIONS: !OPTIONS!

set ENGINEPATH=
if /I "%TYPE%"=="guid" (
    for /f "usebackq tokens=3*" %%A in (`reg query "HKCU\Software\Epic Games\Unreal Engine\Builds" /v "{"%VALUE%"}" 2^>nul`) do set ENGINEPATH=%%A
) else if /I "%TYPE%"=="version" (
    set LOC_VALUE=%VALUE:"=%
    for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\EpicGames\Unreal Engine\!LOC_VALUE!" /v InstalledDirectory 2^>nul') do (
        set ENGINEPATH=%%A %%B
        echo [DEBUG] Retrieved ENGINEPATH from version: !ENGINEPATH!
    )

) else if /I "%TYPE%"=="row" (
    set ENGINEPATH=!VALUE!
) else (
    echo [ERROR] Unknown type: %TYPE%
    exit /b 1
)

if "%ENGINEPATH%"=="" (
    echo [ERROR] Engine path not found
    exit /b 2
)


set UBTDLL=%ENGINEPATH%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll
if not exist "%UBTDLL%" (
    echo [ERROR] UnrealBuildTool.exe not found at: "%UBTDLL%"
    exit /b 3
)

rem run
dotnet "%UBTDLL%" %OPTIONS%
set EXITCODE=%ERRORLEVEL%

endlocal & exit /b %EXITCODE%
