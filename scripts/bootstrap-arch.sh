#!/usr/bin/env bash
# bootstrap-arch.sh — подготовка Arch Linux к треку.
# Запускать НЕ от root. Скрипт идемпотентен: повторный запуск ничего не ломает.
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Не запускайте от root. Используйте обычного пользователя с sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/5] Базовые пакеты"
sudo pacman -Syu --needed --noconfirm \
  base-devel git python python-pip \
  neovim tmux htop btop tree jq ripgrep fd fzf unzip p7zip \
  nmap openbsd-netcat socat tcpdump whois bind traceroute mtr \
  gdb strace ltrace binutils file \
  docker docker-compose podman \
  wireshark-qt firefox keepassxc \
  nftables openssh zram-generator

echo "[2/5] Группы"
sudo usermod -aG docker,wireshark "$USER" || true

echo "[3/5] Docker"
sudo systemctl enable --now docker

echo "[4/5] Python-окружение для сайта"
if [[ ! -d .venv ]]; then
  python -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "[5/5] Рабочие папки"
mkdir -p labs journal assets/pcap

cat <<'EOF'

Готово. Дальше:
  1. Перелогиньтесь (группы docker/wireshark).
  2. mkdocs serve  → http://127.0.0.1:8000
  3. Прочитайте docs/lab/arch-install.md (раздел 6) и настройте zram под 16 ГБ.
  4. Откройте docs/modules/m00-start/index.md.

Если нужен VMware:
  paru -S vmware-workstation && sudo systemctl enable --now vmware-networks
EOF
