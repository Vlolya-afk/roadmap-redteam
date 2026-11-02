# 4.5 — OWASP Top 10 вживую (DVWA)

> **M04 · Этап 0 · 4 ч · 🟡 · артефакт:** `labs/m04-web-crypto/l05-dvwa/`

## Цель

Пройти основные классы веб-уязвимостей руками, на локальном DVWA, и для каждой ответить: как работает, как доказать, как чинить.

## Результат

- 6 уязвимостей на low с доказательствами.
- Понимание, чем medium-фильтры отличаются и почему их обходят.
- Заполненная таблица «уязвимость → payload → причина → фикс».

## Теория

- SQLi: данные пользователя попадают в SQL без параметризации.
- XSS: данные попадают в HTML/JS без экранирования; stored опаснее reflected.
- CSRF: действие выполняется без подтверждения намерения (нет токена/`SameSite`).
- File upload: сервер принимает исполняемый файл и отдаёт его из web-каталога.
- Command injection: ввод попадает в shell.
- LFI: путь к файлу управляется пользователем.
- Все они — варианты одной проблемы: **недоверенные данные смешаны с кодом/командой/путём**.

## Лаборатория

Стенд: `docker run -d --name dvwa -p 8080:80 vulnerables/web-dvwa`, вход `admin/password`, Setup → Create/Reset Database, Security = `low`.

### 1. SQL-инъекция

Страница **SQL Injection**, поле `id`:

```
1' OR '1'='1
```

Ожидаемо: вывод всех пользователей, а не одного.

```
1' UNION SELECT user, password FROM users#
```

Ожидаемо: две колонки — логин и MD5-хэш пароля. Проверьте, что `5f4dcc3b5aa765d61d8327deb882cf99` — это MD5 от `password`.

**Причина:** `SELECT first_name, last_name FROM users WHERE user_id = '$id'` — конкатенация.
**Фикс:** prepared statements, валидация типа, минимальные права БД.

### 2. XSS

**Reflected** (страница XSS Reflected), поле `name`:

```html
<script>alert(document.cookie)</script>
```

Ожидаемо: alert с cookie. **Stored** (XSS Stored, guestbook): тот же payload сохраняется и срабатывает у каждого, кто откроет страницу.

**Причина:** вывод без `htmlspecialchars`.
**Фикс:** контекстное экранирование, CSP, `HttpOnly`.

### 3. CSRF

Страница **CSRF**, смените пароль и посмотрите запрос в Burp: параметры `password_new`, `password_conf`, `Change` — без токена.

Создайте `csrf.html`:

```html
<form action="http://127.0.0.1:8080/vulnerabilities/csrf/" method="GET">
  <input name="password_new" value="hacked123">
  <input name="password_conf" value="hacked123">
  <input type="submit" value="Go">
</form>
```

Откройте файл в браузере, залогиненном в DVWA, нажмите Go. Ожидаемо: пароль изменился без знания старого.

**Фикс:** CSRF-токен, `SameSite=Lax`, проверка `Origin`.

### 4. File upload

Страница **File Upload**, загрузите `probe.php`:

```php
<?php echo "upload-ok"; ?>
```

Ожидаемо: файл доступен по `/hackable/uploads/probe.php` и выполняется. **Фикс:** allowlist расширений, проверка MIME и магии, хранение вне webroot, `noexec`.

### 5. Command injection

Страница **Command Injection**, поле `ip`:

```
127.0.0.1; id
```

Ожидаемо: вывод `uid=...` вместе с ping. **Причина:** `shell_exec("ping -c 4 $ip")`. **Фикс:** `escapeshellarg`, allowlist IP, отказ от shell.

### 6. LFI

Страница **File Inclusion**, параметр `page`:

```
../../../../etc/passwd
```

Ожидаемо: содержимое `/etc/passwd`. **Фикс:** allowlist файлов, `realpath` + проверка префикса, отказ от пользовательских путей.

### 7. Medium

Переключите Security на `medium` и повторите. Часть payload'ов перестанет работать: кавычки экранируются, `<script>` фильтруется, расширения проверяются. Задача — понять, **что именно** фильтруется, и почему фильтр недостаточен (например, `1 OR 1=1` без кавычек, другой тег, обход регистра).

Заполните таблицу:

| Уязвимость | Low payload | Medium обход | Причина | Фикс |
|---|---|---|---|---|
| SQLi | | | | |
| XSS | | | | |
| CSRF | | | | |
| Upload | | | | |
| CMDi | | | | |
| LFI | | | | |

## Атака и защита

- **В реальной операции:** web — точка входа, дальше privesc и pivot. Одна SQLi может дать RCE через `INTO OUTFILE` или upload.
- **Детект:** WAF-сигнатуры, аномальные параметры, ошибки БД, новые файлы в webroot.
- **Фикс:** параметризация, экранирование, CSP, токены, allowlist, минимальные привилегии, WAF как дополнение.

## Самопроверка

- [ ] Почему `mysql_real_escape_string` не спасает от всех SQLi?
- [ ] Чем stored XSS опаснее reflected?
- [ ] Почему `HttpOnly` не мешает CSRF?
- [ ] Как LFI превращается в RCE?

## Дальше

[Контрольная M04](exam.md)
