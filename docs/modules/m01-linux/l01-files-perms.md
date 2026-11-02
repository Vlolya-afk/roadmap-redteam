# 1.1 — Файлы, права, пользователи, sudo

> **M01 · Этап 0 · 3 ч · 🟢 · артефакт:** `labs/m01-linux/l01-files-perms/`

## Цель

Понять модель прав Linux настолько, чтобы находить слабые места конфигурации и не удивляться, почему `sudo` работает не так, как ожидалось.

## Результат

- Создаёте пользователей, группы и разделяемые каталоги с корректными правами.
- Читаете `stat`, `getfacl`, `sudo -l` и объясняете вывод.
- Находите SUID/world-writable файлы и понимаете риск.

## Теория

- Всё в Linux — файл, включая устройства (`/dev`), процессы (`/proc`) и сокеты.
- Права: `rwx` для владельца, группы, остальных. Для каталога `x` = вход, `w` = создание/удаление, `r` = список.
- `umask` вычитает права из новых файлов: `022` → файлы `644`, каталоги `755`.
- SUID/SGID повышают привилегии при запуске; sticky bit (`/tmp`) запрещает удалять чужие файлы.
- `sudo` — не «быть root», а политика в `/etc/sudoers` и `/etc/sudoers.d/`.
- ACL даёт точечные права сверх модели `ugo`.

## Лаборатория

### 1. Пользователи и группы

```bash
sudo useradd -m -s /bin/bash alice
sudo useradd -m -s /bin/bash bob
sudo groupadd analysts
sudo usermod -aG analysts alice
id alice
cat /etc/passwd | tail -3
sudo passwd alice
```

Ожидаемо: `uid=1001(alice) gid=1001(alice) groups=1001(alice),1002(analysts)`. Пароли в `/etc/shadow`, не в `passwd`.

### 2. Разделяемый каталог

```bash
sudo mkdir -p /srv/reports
sudo chown root:analysts /srv/reports
sudo chmod 2770 /srv/reports
ls -ld /srv/reports
```

Ожидаемо: `drwxrws--- root analysts`. `s` = SGID: новые файлы наследуют группу `analysts`.

Проверка: `sudo -u alice touch /srv/reports/a.txt; sudo -u bob ls /srv/reports` — bob не в группе, получит `Permission denied`.

### 3. SUID и поиск опасного

```bash
find / -xdev -perm -4000 -type f 2>/dev/null
```

Ожидаемо: список (`/usr/bin/passwd`, `sudo`, `mount`, ...). Найдите те, что не входят в базовый набор, — это кандидаты на priv esc.

Демонстрация (только в своей ВМ):

```bash
cp /bin/bash /tmp/rootbash
sudo chown root:root /tmp/rootbash
sudo chmod +s /tmp/rootbash
/tmp/rootbash -p -c 'id'
```

Ожидаемо: `euid=0(root)` — оболочка сохраняет привилегии. Удалите: `sudo rm /tmp/rootbash`.

### 4. sudo и ACL

```bash
sudo -l
sudo visudo -f /etc/sudoers.d/lab
# alice ALL=(ALL) NOPASSWD: /usr/bin/less
sudo -u alice sudo -l
```

Ожидаемо: alice может `less` без пароля. Это классическая дыра: `less` умеет `!sh`.

ACL:

```bash
setfacl -m u:bob:r /srv/reports/a.txt
getfacl /srv/reports/a.txt
```

## Атака и защита

- **Атака:** SUID-копия `bash`, `NOPASSWD` на `less`/`vim`/`find`, world-writable каталог в `PATH`, слабые права на `/etc/shadow`.
- **Детект:** `auditd` на `execve` от нестандартных путей, мониторинг SUID (`find` по расписанию), алерты на изменение `sudoers`.
- **Фикс:** минимальные права, `sudo` только на конкретные команды без shell-возможностей, регулярный аудит SUID, `noexec` на `/tmp`.

## Самопроверка

- [ ] Чем `chmod 2770` отличается от `chmod 770`?
- [ ] Почему `NOPASSWD: /usr/bin/less` опасен?
- [ ] Как найти файлы, доступные на запись всем?
- [ ] Где хранятся хэши паролей и почему не в `/etc/passwd`?

## Дальше

[1.2 — Процессы, systemd, логи](l02-processes-systemd.md)
