@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: Script cai dat moi truong phat trien cho Windows (Windows 10 / 11)
:: Su dung pyenv-win, nvm-windows va winget
:: ==============================================================================
:: HƯỚNG DẪN CHẠY:
::   Bước 1: Mở Command Prompt (CMD) hoặc PowerShell với quyền Administrator
::           (Chuột phải vào CMD -> chọn "Run as administrator")
::   Bước 2: Di chuyển đến thư mục chứa file:
::           cd C:\Users\das03\Downloads
::   Bước 3: Chạy script kèm phiên bản Python bạn muốn cài đặt:
::           init_windows.bat <python_version>
::           Ví dụ:
::           init_windows.bat 3.10.13
::           init_windows.bat 3.11.8
::   Bước 4: Sau khi cài xong, mở một cửa sổ CMD/PowerShell mới để nạp PATH.
:: ==============================================================================

:: 1. Kiem tra quyen Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Ban phai chay file batch nay voi quyen Administrator!
    echo Chuot phai vao CMD va chon "Run as administrator".
    pause
    exit /b 1
)

:: 2. Kiem tra tham so phien ban Python
if "%~1"=="" (
    echo [ERROR] Thieu tham so phien ban Python!
    echo ==============================================================================
    echo HUONG DAN SU DUNG:
    echo   %~nx0 ^<python_version^>
    echo   Vi du: %~nx0 3.10.13
    echo ==============================================================================
    pause
    exit /b 1
)

set "PYTHON_VERSION=%~1"

:: 3. Kiem tra winget
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Khong tim thay 'winget'. Vui long cap nhat Windows 10/11 hoac cai App Installer tu Microsoft Store!
    pause
    exit /b 1
)

echo ==============================================================================
echo [BAT DAU] Cai dat moi truong phat trien Windows (Python: %PYTHON_VERSION%)
echo ==============================================================================

:: ==============================================================================
:: 4. GIT
:: ==============================================================================
echo [1/9] Dang kiem tra va cai dat Git...
where git >nul 2>&1
if %errorlevel% neq 0 (
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
    set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
) else (
    echo [OK] Git da duoc cai dat.
)

:: ==============================================================================
:: 5. PYENV-WIN VA PYTHON (%PYTHON_VERSION%)
:: ==============================================================================
echo [2/9] Dang cai dat pyenv-win va Python %PYTHON_VERSION%...
set "PYENV_DIR=%USERPROFILE%\.pyenv\pyenv-win"

if not exist "%PYENV_DIR%" (
    echo Dang tai va cai dat pyenv-win...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1' -OutFile '$env:TEMP\install-pyenv-win.ps1'; & '$env:TEMP\install-pyenv-win.ps1'"
) else (
    echo [OK] pyenv-win da ton tai tai %PYENV_DIR%.
)

:: Nap tam thoi bien moi truong pyenv vao session hien tai
set "PYENV=%USERPROFILE%\.pyenv\pyenv-win"
set "PYENV_ROOT=%USERPROFILE%\.pyenv\pyenv-win"
set "PYENV_HOME=%USERPROFILE%\.pyenv\pyenv-win"
set "PATH=%PYENV_DIR%\bin;%PYENV_DIR%\shims;%PATH%"

echo Dang cai dat Python %PYTHON_VERSION% qua pyenv-win...
call "%PYENV_DIR%\bin\pyenv.bat" update
call "%PYENV_DIR%\bin\pyenv.bat" install -s %PYTHON_VERSION%
call "%PYENV_DIR%\bin\pyenv.bat" global %PYTHON_VERSION%
call "%PYENV_DIR%\bin\pyenv.bat" rehash

:: Upgrade pip
call python -m pip install --upgrade pip

:: ==============================================================================
:: 6. REDIS SERVER (Port cho Windows)
:: ==============================================================================
echo [3/9] Dang kiem tra va cai dat Redis cho Windows...
where redis-server >nul 2>&1
if %errorlevel% neq 0 (
    winget install --id tporadowski.redis -e --source winget --accept-source-agreements --accept-package-agreements
) else (
    echo [OK] Redis da duoc cai dat.
)

:: ==============================================================================
:: 7. POSTGRESQL & PGADMIN 4
:: ==============================================================================
echo [4/9] Dang cai dat PostgreSQL va pgAdmin 4...
where psql >nul 2>&1
if %errorlevel% neq 0 (
    winget install --id PostgreSQL.PostgreSQL.15 -e --source winget --accept-source-agreements --accept-package-agreements
) else (
    echo [OK] PostgreSQL da duoc cai dat.
)

winget install --id PostgreSQL.pgAdmin -e --source winget --accept-source-agreements --accept-package-agreements

:: ==============================================================================
:: 8. VISUAL STUDIO CODE
:: ==============================================================================
echo [5/9] Dang cai dat Visual Studio Code...
winget install --id Microsoft.VisualStudioCode -e --source winget --accept-source-agreements --accept-package-agreements

:: ==============================================================================
:: 9. GOOGLE CHROME & MICROSOFT EDGE
:: ==============================================================================
echo [6/9] Dang cai dat Google Chrome & Microsoft Edge...
winget install --id Google.Chrome -e --source winget --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.Edge -e --source winget --accept-source-agreements --accept-package-agreements

:: ==============================================================================
:: 10. POSTMAN & TELEGRAM
:: ==============================================================================
echo [7/9] Dang cai dat Postman & Telegram...
winget install --id Postman.Postman -e --source winget --accept-source-agreements --accept-package-agreements
winget install --id Telegram.TelegramDesktop -e --source winget --accept-source-agreements --accept-package-agreements

:: ==============================================================================
:: 11. NVM-WINDOWS (Node Version Manager) & ANGULAR CLI
:: ==============================================================================
echo [8/9] Dang cai dat nvm-windows, Node.js (LTS) & Angular CLI...
where nvm >nul 2>&1
if %errorlevel% neq 0 (
    winget install --id CoreyButler.NVMforWindows -e --source winget --accept-source-agreements --accept-package-agreements
    echo [CHU Y] Vui long mo lai CMD moi de su dung nvm cai Node.js LTS!
) else (
    echo [OK] NVM-Windows da duoc cai dat.
    call nvm install lts
    call nvm use lts
    call npm install -g @angular/cli
)

:: ==============================================================================
:: HOAN TAT
:: ==============================================================================
echo ==============================================================================
echo [HOAN TAT] Cai dat moi truong phat trien Windows thanh cong!
echo Luu y:
echo   1. Hay mo mot cua so CMD hoac PowerShell moi de he thong nhan dien PATH moi.
echo   2. Kiem tra lai cac lenh: python --version, git --version, nvm version.
echo ==============================================================================
pause
