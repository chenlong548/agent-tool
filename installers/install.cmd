@echo off
setlocal enabledelayedexpansion

set "COMMAND_NAME=agent"
set "TOOL_HOME=%USERPROFILE%\agent-tool"
set "INSTALL_DIR=%USERPROFILE%\bin"
set "SOURCE_ROOT=%~dp0.."

if "%1"=="install" goto install
if "%1"=="help" goto help
if "%1"=="-h" goto help
if "%1"=="--help" goto help

:help
echo Agent Tool v4.0 - AI Engineering Workflow Engine
echo.
echo Usage:
echo   installers\install.cmd install
echo.
echo After installation:
echo   agent init
echo   agent help
exit /b 0

:install
echo Installing Agent Tool v4.0...

if not exist "%TOOL_HOME%" mkdir "%TOOL_HOME%"
if not exist "%TOOL_HOME%\core" mkdir "%TOOL_HOME%\core"
if not exist "%TOOL_HOME%\.agents" mkdir "%TOOL_HOME%\.agents"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

xcopy /E /I /Y "%SOURCE_ROOT%\core" "%TOOL_HOME%\core" >nul
xcopy /E /I /Y "%SOURCE_ROOT%\.agents" "%TOOL_HOME%\.agents" >nul
copy /Y "%SOURCE_ROOT%\AGENTS.md" "%TOOL_HOME%\AGENTS.md" >nul

(
  echo @echo off
  echo powershell -NoProfile -ExecutionPolicy Bypass -File "%%USERPROFILE%%\agent-tool\core\agent.ps1" %%*
) > "%INSTALL_DIR%\%COMMAND_NAME%.cmd"

echo Agent Tool v4.0 installed successfully.
echo.
echo Add "%INSTALL_DIR%" to PATH if it is not already there.
echo Usage: %COMMAND_NAME% init
exit /b 0
