#echo off
setlocal

rem args
set TYPE=%1
set VALUE=%2
set MODE=%3
set PROJECT=%4
set OUTPUTDIR=%5

rem 5shift
shift
shift
shift
shift
shift

setlocal EnableDelayedExpansion
set OPTIONS=
:loop
set ARG=%1
if "!ARG!"=="" goto after_options
set OPTIONS=!OPTIONS! !ARG!
shift
goto loop
:after_options


rem debug
echo TYPE: %TYPE%
echo VALUE: %VALUE%
echo MODE: %MODE%
echo PROJECT: %PROJECT%
echo OUTPUTDIR: %OUTPUTDIR%
echo OPTIONS: %OPTIONS%

rem get Unreal Engine path 
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
    set ENGINEPATH=%VALUE%
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
dotnet "%UBTDLL%" -mode=%MODE% -Progress -OutputDir=%OUTPUTDIR% -project=%PROJECT% %OPTIONS%
set EXITCODE=%ERRORLEVEL%

endlocal & exit /b %EXITCODE%
