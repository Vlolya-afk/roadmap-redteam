# 1.5 — Bash-скрипты и охота на бэкдоры

> **M01 · Этап 0 · 4 ч · 🟡 · артефакт:** `labs/m01-linux/l05-hunt/`

## Цель

Написать bash-скрипт, который находит типовые закладки в Linux, и применить его к системе, которую вы сами «сломали».

## Результат

- Уверенно пишете скрипты с `set -euo pipefail`, функциями и обработкой аргументов.
- Знаете 8+ мест, где живёт persistence.
- Ваш `hunt.sh` находит 5 закладок и пишет отчёт.

## Теория

- `set -euo pipefail` — падать на ошибках, не использовать пустые переменные, ловить ошибки в пайпах.
- Кавычки: `"$var"` почти всегда; `$(...)` вместо backticks; `[[ ]]` вместо `[ ]`.
- `find` + `-exec` мощнее циклов по `ls`.
- Persistence в Linux: cron, systemd, `.bashrc`/`.profile`, `authorized_keys`, SUID, `LD_PRELOAD`, `rc.local`, `~/.config/autostart`, git hooks.
- Хороший hunt-скрипт не «ищет магическую строку», а собирает аномалии и ранжирует их.
- Отчёт должен быть воспроизводимым: команда, вывод, интерпретация.

## Лаборатория

### 1. Оставить 5 закладок (в своей ВМ!)

```bash
# 1) cron
(crontab -l 2>/dev/null; echo '* * * * * /bin/bash -c "echo beacon >> /tmp/.cache/beacon"') | crontab -

# 2) systemd
sudo tee /etc/systemd/system/systemd-helper.service >/dev/null <<'EOF'
[Unit]
Description=System Helper
[Service]
ExecStart=/bin/bash -c 'while true; do echo x >> /tmp/.cache/svc; sleep 60; done'
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable --now systemd-helper.service

# 3) authorized_keys
mkdir -p ~/.ssh && ssh-keygen -t ed25519 -N '' -f /tmp/evil_key -q
cat /tmp/evil_key.pub >> ~/.ssh/authorized_keys

# 4) SUID
sudo cp /bin/bash /usr/local/bin/.bs && sudo chmod +s /usr/local/bin/.bs

# 5) bashrc
echo 'export LD_PRELOAD=/tmp/.cache/lib.so' >> ~/.bashrc
```

Ожидаемо: система «заражена», но выглядит почти обычно.

### 2. Написать hunt.sh

Скелет:

```bash
#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-hunt-report.md}"
section() { printf '\n## %s\n\n' "$1" >>"$OUT"; }
run() { printf '```\n$ %s\n' "$*"; "$@" 2>&1 || true; printf '```\n'; }

: >"$OUT"
echo "# Hunt report — $(hostname) — $(date -Is)" >>"$OUT"

section "UID 0"
run awk -F: '$3==0 {print $1}' /etc/passwd

section "SUID"
run find / -xdev -perm -4000 -type f

section "Cron"
run bash -c 'crontab -l 2>/dev/null; ls -la /etc/cron* /var/spool/cron 2>/dev/null'

section "Systemd units"
run bash -c "grep -RlE 'ExecStart=.*(/tmp|/dev/shm|/home)' /etc/systemd/system 2>/dev/null"

section "Authorized keys"
run bash -c 'find /root /home -name authorized_keys -exec ls -l {} \; -exec cat {} \; 2>/dev/null'

section "Recent files"
run find / -xdev -mtime -1 -type f -not -path '/proc/*' -not -path '/sys/*'

section "Listening"
run ss -tulpn
```

```bash
chmod +x hunt.sh && sudo ./hunt.sh report.md
```

Ожидаемо: в отчёте видны все 5 закладок: cron-строка, юнит с `/bin/bash`, ключ, `.bs` с SUID, `LD_PRELOAD` (через grep по `.bashrc` — добавьте секцию).

### 3. Убрать и оформить

Удалите всё, что оставили, и напишите `incident.md`: что нашли, как, что бы это дало атакующему, как чинить.

```bash
crontab -r
sudo systemctl disable --now systemd-helper.service
sudo rm /etc/systemd/system/systemd-helper.service
sed -i '/evil_key/d' ~/.ssh/authorized_keys
sudo rm /usr/local/bin/.bs
sed -i '/LD_PRELOAD/d' ~/.bashrc
```

## Атака и защита

- **Атака:** persistence через легитимные механизмы (systemd, cron, ключи) — сложно отличить от админской работы.
- **Детект:** baseline юнитов и cron, аудит `authorized_keys`, `auditd` на `execve` из `/tmp`, сверка SUID с эталоном.
- **Фикс:** file integrity monitoring (AIDE), централизованный сбор логов, запрет `noexec` не поможет от systemd — нужен контроль изменений.

## Самопроверка

- [ ] Почему `set -e` не спасает от ошибки в пайпе?
- [ ] Назовите 5 мест persistence и как каждое проверить.
- [ ] Чем опасен SUID-бинарник вне пакетного менеджера?
- [ ] Что добавить в скрипт, чтобы он не зависел от локали?

## Дальше

[Контрольная M01](exam.md)
