#!/bin/bash
# ==============================================================================
# Script cài đặt môi trường phát triển cho Ubuntu 22.04 LTS trở lên (22.04, 24.04+)
# Sử dụng pyenv để quản lý các phiên bản Python
# ==============================================================================

set -e # Dừng ngay khi có lệnh gặp lỗi

# 1. Kiểm tra tham số phiên bản Python
if [ -z "$1" ]; then
    echo "Usage: $0 <python_version>"
    echo "Example: $0 3.10.13"
    exit 1
fi

version_python=$1
export DEBIAN_FRONTEND=noninteractive

echo ">>> Bắt đầu cấu hình môi trường cho Ubuntu $(lsb_release -rs)..."

# 2. Cập nhật hệ thống và cài đặt các công cụ cơ bản
echo ">>> Cập nhật hệ thống & cài đặt tiện ích cơ bản..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release

# Đảm bảo thư mục lưu keyring chuẩn của Ubuntu 22.04+ đã tồn tại
sudo install -m 0755 -d /etc/apt/keyrings

# ==============================================================================
# 3. CÀI ĐẶT CÁC GÓI PHỤ THUỘC ĐỂ BUILD PYTHON CHO PYENV
# ==============================================================================
echo ">>> [1/9] Cài đặt dependencies để build Python (chuẩn Ubuntu 22.04+)..."
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncurses-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    libgdbm-dev \
    libexpat1-dev

# ==============================================================================
# 4. CÀI ĐẶT PYENV VÀ CẤU HÌNH SHELL
# ==============================================================================
echo ">>> [2/9] Cài đặt pyenv..."
export PYENV_ROOT="$HOME/.pyenv"

if [ ! -d "$PYENV_ROOT" ]; then
    curl -fsSL https://pyenv.run | bash
else
    echo ">>> pyenv đã được cài đặt tại $PYENV_ROOT."
fi

# Cấu hình biến môi trường cho phiên chạy script hiện tại
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$("$PYENV_ROOT/bin/pyenv" init -)"
if [ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
    eval "$("$PYENV_ROOT/bin/pyenv" virtualenv-init -)"
fi

# Thêm cấu hình vào ~/.bashrc nếu chưa có
if ! grep -q 'export PYENV_ROOT="$HOME/.pyenv"' "$HOME/.bashrc"; then
    echo ">>> Cấu hình pyenv vào ~/.bashrc..."
    cat << 'EOF' >> "$HOME/.bashrc"

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
if which pyenv-virtualenv-init > /dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
fi
EOF
fi

# Cài đặt Python chỉ định và đặt làm global
echo ">>> Cài đặt Python ${version_python} qua pyenv..."
pyenv install -s "${version_python}"
pyenv global "${version_python}"

echo ">>> Phiên bản Python hiện tại: $(python --version)"
python -m pip install --upgrade pip

# ==============================================================================
# 5. REDIS SERVER
# ==============================================================================
echo ">>> [3/9] Cài đặt Redis Server..."
sudo apt-get install -y redis-server
sudo systemctl enable --now redis-server || true
echo ">>> Đã cài đặt Redis."

# ==============================================================================
# 6. POSTGRESQL (Official PGDG Repo)
# ==============================================================================
echo ">>> [4/9] Cài đặt PostgreSQL..."
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/postgresql.gpg
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql || true
echo ">>> Đã cài đặt PostgreSQL."

# ==============================================================================
# 7. PGADMIN 4
# ==============================================================================
echo ">>> [5/9] Cài đặt pgAdmin 4..."
curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages-pgadmin-org.gpg
echo "deb [signed-by=/etc/apt/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" | sudo tee /etc/apt/sources.list.d/pgadmin4.list > /dev/null

sudo apt-get update
sudo apt-get install -y pgadmin4-desktop || echo "Bỏ qua pgadmin4-desktop nếu chạy trên môi trường không có GUI/WSL"
echo ">>> Đã cài đặt pgAdmin 4."

# ==============================================================================
# 8. MICROSOFT VSCODE & MICROSOFT EDGE (Dùng chung keyring Microsoft)
# ==============================================================================
echo ">>> [6/9] Cài đặt Visual Studio Code & Microsoft Edge..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg

echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null

sudo apt-get update
sudo apt-get install -y code microsoft-edge-stable
echo ">>> Đã cài đặt VS Code và Microsoft Edge."

# ==============================================================================
# 9. GOOGLE CHROME
# ==============================================================================
echo ">>> [7/9] Cài đặt Google Chrome..."
CHROME_TMP=$(mktemp)
wget -O "${CHROME_TMP}" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y "${CHROME_TMP}"
rm -f "${CHROME_TMP}"
echo ">>> Đã cài đặt Google Chrome."

# ==============================================================================
# 10. POSTMAN & TELEGRAM (Snap)
# ==============================================================================
echo ">>> [8/9] Cài đặt Postman & Telegram qua Snap..."
if command -v snap >/dev/null 2>&1; then
    sudo snap install postman || true
    sudo snap install telegram-desktop || true
    echo ">>> Đã cài đặt Postman & Telegram."
else
    echo ">>> Cảnh báo: Snap chưa được hỗ trợ hoặc chưa khởi động trên máy này, bỏ qua Postman và Telegram."
fi

# ==============================================================================
# 11. NODEJS (NVM + LTS) & ANGULAR CLI
# ==============================================================================
echo ">>> [9/9] Cài đặt NVM, Node.js (LTS) & Angular CLI..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo ">>> Lấy phiên bản NVM mới nhất từ GitHub..."
    # Lấy tag mới nhất qua git để không phụ thuộc API rate limit và không bị hardcode phiên bản
    LATEST_NVM_TAG=$(git ls-remote --tags --sort="v:refname" https://github.com/nvm-sh/nvm.git "v[0-9]*" | tail -n1 | awk -F/ '{print $3}')
    if [ -z "$LATEST_NVM_TAG" ]; then
        LATEST_NVM_TAG="v0.40.1" # Fallback dự phòng
    fi
    echo ">>> Phiên bản NVM: ${LATEST_NVM_TAG}"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_TAG}/install.sh" | bash
fi

# Nạp nvm vào session hiện tại
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command -v nvm >/dev/null 2>&1; then
    nvm install --lts
    nvm use --lts
    npm install -g @angular/cli
    echo ">>> Đã cài đặt Node.js $(node -v), npm $(npm -v), Angular CLI."
else
    echo ">>> NVM đã được tải. Hãy mở lại terminal mới để dùng lệnh nvm / node."
fi

# ==============================================================================
# HOÀN THÀNH
# ==============================================================================
echo "=============================================================================="
echo ">>> CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!"
echo ">>> Chạy 'source ~/.bashrc' để nạp pyenv, nvm và node vào terminal hiện tại."
echo "=============================================================================="
