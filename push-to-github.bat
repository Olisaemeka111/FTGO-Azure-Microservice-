@echo off
echo =========================================
echo Git Push to GitHub
echo =========================================
echo.

cd /d "C:\Users\olisa\OneDrive\Desktop\Azure AKS architecture"

REM Find Git executable
set "GIT_EXE="
if exist "C:\Program Files\Git\cmd\git.exe" set "GIT_EXE=C:\Program Files\Git\cmd\git.exe"
if exist "C:\Program Files\Git\bin\git.exe" set "GIT_EXE=C:\Program Files\Git\bin\git.exe"
if exist "C:\Program Files (x86)\Git\cmd\git.exe" set "GIT_EXE=C:\Program Files (x86)\Git\cmd\git.exe"

if "%GIT_EXE%"=="" (
    echo ERROR: Git not found!
    echo Please install Git from: https://git-scm.com/download/win
    echo Or add Git to your PATH
    pause
    exit /b 1
)

echo Using Git: %GIT_EXE%
echo.

echo Step 1: Initializing git...
"%GIT_EXE%" init
echo.

echo Step 2: Adding files...
"%GIT_EXE%" add .
echo.

echo Step 3: Committing...
"%GIT_EXE%" commit -m "first commit"
echo.

echo Step 4: Setting branch to main...
"%GIT_EXE%" branch -M main
echo.

echo Step 5: Configuring remote...
"%GIT_EXE%" remote remove origin 2>nul
REM Replace YOUR_TOKEN with your GitHub Personal Access Token
"%GIT_EXE%" remote add origin https://Olisaemeka111:YOUR_TOKEN@github.com/Olisaemeka111/FTGO-Azure-Microservice-.git
echo.

echo Step 6: Pushing to GitHub...
echo Repository: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-.git
echo.
"%GIT_EXE%" push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================
    echo Successfully pushed to GitHub!
    echo =========================================
    echo.
    echo Repository URL: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-
    echo.
) else (
    echo.
    echo =========================================
    echo Push failed. Check the error above.
    echo =========================================
    echo.
)

pause

