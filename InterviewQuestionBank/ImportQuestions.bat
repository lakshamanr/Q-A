@echo off
echo ========================================
echo   Interview Question Bank Import Tool
echo ========================================
echo.
echo This script will import all questions from markdown files.
echo Please close Visual Studio before proceeding.
echo.
pause

cd /d "%~dp0"

echo.
echo [1/3] Building project...
dotnet build --configuration Release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed! Please close Visual Studio and try again.
    pause
    exit /b 1
)

echo.
echo [2/3] Importing questions...
dotnet run --configuration Release --no-build -- --import-questions
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Import encountered errors!
    pause
    exit /b 1
)

echo.
echo [3/3] Verifying import...
dotnet run --configuration Release --no-build -- --verify-import

echo.
echo ========================================
echo   Import Complete!
echo ========================================
echo.
pause
