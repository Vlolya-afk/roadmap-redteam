# 10.1 — Linux enumeration

> **M10 · Этап 1 · 4 ч · 🟢 · артефакт:** `labs/m10-privesc/l01-linux-enum/`

## Цель

Собрать полную картину Linux-хоста за 15 минут: кто я, что могу, что запущено, где лежат секреты.

## Результат

- Чек-лист из 15 команд, который вы выполняете по памяти.
- `linpeas` как ускоритель, а не замена.
- Список кандидатов на privesc с обоснованием.

## Теория

- Сначала контекст: `id`, `sudo -l`, `uname -a`, `/etc/os-release`.
- Потом поверхность: порты, процессы, cron, systemd, SUID, capabilities.
- Потом данные: домашние каталоги, конфиги, БД, SSH-ключи, history.
- `linpeas` автоматизирует, но выдаёт много шума; читайте секции `[+]`.
- Каждая находка должна иметь гипотезу: «это даст root, потому что...».

## Лаборатория

### 1. Контекст

```bash
id
sudo -l
uname -a
cat /etc/os-release
hostname
ip -brief addr
```

Ожидаемо: пользователь, группы, возможный sudo, версия ядра. Запишите всё в `enum.md`.

### 2. Процессы и службы

```bash
ps aux --sort=-%cpu | head -20
ss -tulpn
systemctl list-units --type=service --state=running
systemctl list-timers --all
```

Ожидаемо: сервисы, слушающие порты, таймеры. Ищите процессы от root с путями в `/home`/`/tmp`.

### 3. SUID, capabilities, cron

```bash
find / -xdev -perm -4000 -type f 2>/dev/null
getcap -r / 2>/dev/null
crontab -l 2>/dev/null; ls -la /etc/cron* /var/spool/cron 2>/dev/null
```

Ожидаемо: список SUID, capabilities, задачи. Сверьте SUID с GTFOBins.

### 4. Данные

```bash
ls -la /home/*
find /home /var/www /opt -type f \( -name '*.conf' -o -name '*.env' -o -name '*.bak' \) 2>/dev/null
grep -RInE 'password|passwd|api[_-]?key' /var/www /opt 2>/dev/null | head
cat ~/.bash_history 2>/dev/null | tail
```

Ожидаемо: конфиги с паролями, бэкапы, история команд. Не публикуйте найденное.

### 5. linpeas

```bash
curl -L -o /tmp/linpeas.sh https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh
less /tmp/linpeas.sh | head -50     # посмотреть, что запускаете
chmod +x /tmp/linpeas.sh && /tmp/linpeas.sh -a | tee enum-linpeas.txt
```

Ожидаемо: отчёт с цветными секциями. Сравните с вашим ручным списком: что вы пропустили?

## Атака и защита

- **Атака:** enumeration — первый шаг после foothold; шумный, но легитимный.
- **Детект:** массовые `find`/`cat`, чтение `/etc/shadow`, запуск linpeas, аномальные команды.
- **Фикс:** минимальные права, запрет лишних SUID, аудит, AppArmor/SELinux, мониторинг.

## Самопроверка

- [ ] Почему `sudo -l` — первая команда после `id`?
- [ ] Чем `getcap` полезнее `find -perm`?
- [ ] Что в linpeas чаще всего даёт false positive?
- [ ] Какую находку вы бы проверили первой и почему?

## Дальше

[10.2 — Linux privesc](l02-linux-privesc.md)
