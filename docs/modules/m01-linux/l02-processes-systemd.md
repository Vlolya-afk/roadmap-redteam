# 1.2 — Процессы, systemd, логи

> **M01 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m01-linux/l02-processes/`

## Цель

Научиться видеть, что происходит в системе: какие процессы запущены, кто их запустил, какие службы включены и что они пишут в логи.

## Результат

- Читаете `/proc/<pid>/` и объясняете, что там лежит.
- Создаёте systemd-службу и таймер, управляете ими.
- Находите подозрительный процесс и его источник по логам.

## Теория

- Процесс = PID, родитель (PPID), пользователь, командная строка, окружение, открытые файлы.
- `/proc/<pid>/cmdline`, `environ`, `fd/`, `maps` — источник правды о процессе.
- Сигналы: `SIGTERM` (15) — вежливо, `SIGKILL` (9) — без шансов, `SIGHUP` (1) — перечитать конфиг.
- systemd: юнит-файлы в `/etc/systemd/system/`, `systemctl enable` создаёт symlink, `daemon-reload` перечитывает.
- Таймеры заменяют cron и логируются в journal.
- Логи: `journalctl`, `/var/log/` (на Arch многое уходит в journal, а не в syslog).

## Лаборатория

### 1. Процессы

```bash
ps aux --sort=-%cpu | head
pgrep -a sshd
PID=$(pgrep -n sshd)
sudo ls -l /proc/$PID/fd
sudo tr '\0' '\n' < /proc/$PID/environ | head
cat /proc/$PID/cmdline | tr '\0' ' '
```

Ожидаемо: видите открытые сокеты/файлы, переменные окружения (осторожно с секретами), полную командную строку.

### 2. Создать службу

```bash
sudo tee /etc/systemd/system/labbeat.service >/dev/null <<'EOF'
[Unit]
Description=Lab heartbeat
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/logger -t labbeat "heartbeat"
EOF

sudo systemctl daemon-reload
sudo systemctl start labbeat
journalctl -t labbeat -n 5 --no-pager
```

Ожидаемо: запись `heartbeat` в journal.

### 3. Таймер

```bash
sudo tee /etc/systemd/system/labbeat.timer >/dev/null <<'EOF'
[Unit]
Description=Run labbeat every minute

[Timer]
OnCalendar=*:0/1
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now labbeat.timer
systemctl list-timers --all | grep labbeat
```

Ожидаемо: таймер активен, `NEXT` через минуту. Через 2 минуты `journalctl -t labbeat` покажет несколько записей.

### 4. Найти «подозрительное»

```bash
systemctl list-units --type=service --state=running
systemctl list-timers --all
crontab -l; sudo crontab -l
ss -tulpn
```

Ожидаемо: вы можете назвать каждый процесс и порт. Если что-то не узнаёте — разбирайтесь, это и есть навык.

## Атака и защита

- **Атака:** persistence через `systemd`-юнит с именем `systemd-helper`, таймер каждые 5 минут, cron `@reboot`, подмена `ExecStart`.
- **Детект:** новые юниты вне пакетов, `systemctl cat` с путями в `/tmp`, таймеры с частым интервалом, `logger`-записи без источника.
- **Фикс:** мониторинг `/etc/systemd/system` и `/etc/cron*`, whitelist юнитов, `auditd` на создание файлов, immutable-режим для критичных юнитов.

## Самопроверка

- [ ] Чем `systemctl enable` отличается от `start`?
- [ ] Где найти переменные окружения процесса?
- [ ] Как посмотреть логи только одной службы?
- [ ] Почему таймер лучше cron в systemd-системе?

## Дальше

[1.3 — Пакеты и сборка](l03-packages.md)
