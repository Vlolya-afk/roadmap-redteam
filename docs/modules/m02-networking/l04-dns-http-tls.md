# 2.4 — DNS, HTTP, TLS

> **M02 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m02-networking/l04-protocols/`

## Цель

Разобрать три протокола, на которых держится веб, и увидеть, где именно в них прячутся атаки.

## Результат

- Читаете DNS-ответы и понимаете разницу рекурсивного и авторитетного сервера.
- Разбираете HTTP-запрос/ответ по заголовкам.
- Объясняете TLS handshake и проверяете сертификат через `openssl`.

## Теория

- DNS — распределённая база: root → TLD → авторитетный сервер. Типы: A, AAAA, CNAME, MX, TXT, NS, PTR.
- Рекурсивный резолвер кэширует ответы; TTL определяет, как долго.
- DNS по умолчанию не аутентифицирован (DNSSEC решает, но внедрён не везде).
- HTTP: метод + путь + версия, заголовки, тело. Статусы `2xx/3xx/4xx/5xx`.
- Cookie передаётся автоматически; `HttpOnly`, `Secure`, `SameSite` — защиты.
- TLS: ClientHello → ServerHello + сертификат → проверка цепочки → ключи → шифрованный канал.
- SNI передаётся открытым текстом (если не ECH) — по нему можно понять, куда вы идёте.

## Лаборатория

### 1. DNS

```bash
dig example.com A
dig example.com MX
dig example.com TXT
dig +short example.com
dig +trace example.com | head -30
```

Ожидаемо: A-запись, MX-серверы, TXT (SPF и т.п.), цепочка от root до авторитетного сервера в `+trace`.

Проверка кэша и локальных записей:

```bash
resolvectl query example.com
cat /etc/hosts
```

### 2. Подмена через hosts (демо)

```bash
echo "127.0.0.1 lab.local" | sudo tee -a /etc/hosts
getent hosts lab.local
curl -v http://lab.local:8000/ 2>&1 | head
```

Ожидаемо: `lab.local` резолвится в `127.0.0.1`. Это модель DNS-спуфинга на уровне хоста: приложение верит локальному резолверу.

Уберите строку после лабы.

### 3. HTTP

На LNX01: `python3 -m http.server 8000`.

На attacker:

```bash
curl -v http://10.10.10.30:8000/
curl -s -D - -o /dev/null http://10.10.10.30:8000/
```

Ожидаемо: request line, `Host`, `User-Agent`, ответ `HTTP/1.0 200 OK`, `Content-type`, `Content-Length`.

### 4. TLS

Сгенерируйте самоподписанный сертификат и поднимите HTTPS:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -keyout key.pem -out cert.pem -subj "/CN=lab.local"
openssl s_server -accept 8443 -cert cert.pem -key key.pem -www
```

На attacker:

```bash
openssl s_client -connect 10.10.10.30:8443 -servername lab.local
```

Ожидаемо: вывод handshake, `verify error: self-signed certificate`, затем `---` и возможность ввести HTTP-запрос. Внутри `s_client`:

```
GET / HTTP/1.0
Host: lab.local

```

Посмотрите сертификат:

```bash
openssl s_client -connect 10.10.10.30:8443 -showcerts </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

Ожидаемо: `subject=CN = lab.local`, `issuer=CN = lab.local`, срок 1 день.

## Атака и защита

- **Атака:** DNS-спуфинг/poisoning, подмена hosts, TLS stripping (SSLstrip), self-signed MITM, перехват SNI.
- **Детект:** аномальные DNS-ответы, сертификаты не от ожидаемого CA, HSTS-нарушения, смена A-записи.
- **Фикс:** DNSSEC, DoH/DoT, HSTS, certificate pinning, мониторинг CT-логов, запрет самоподписанных сертификатов в проде.

## Самопроверка

- [ ] Чем рекурсивный резолвер отличается от авторитетного сервера?
- [ ] Что проверяет клиент в сертификате TLS?
- [ ] Почему `HttpOnly` не спасает от XSS, но спасает cookie?
- [ ] Как `dig +trace` помогает найти проблему delegation?

## Дальше

[2.5 — Захват и разбор трафика](l05-packet-capture.md)
