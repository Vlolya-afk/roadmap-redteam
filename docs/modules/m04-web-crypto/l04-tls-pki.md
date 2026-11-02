# 4.4 — TLS и PKI

> **M04 · Этап 0 · 4 ч · 🟡 · артефакт:** `labs/m04-web-crypto/l04-tls/`

## Цель

Понять, как TLS защищает канал, кому доверяет клиент и почему корпоративный MITM-прокси — это одновременно инструмент и угроза.

## Результат

- Создаёте свой CA, выпускаете сертификат и проверяете цепочку.
- Объясняете handshake TLS 1.3 по шагам.
- Настраиваете mitmproxy и перехватываете HTTPS в своей лабе.

## Теория

- TLS 1.3: ClientHello (key share) → ServerHello + EncryptedExtensions + Certificate + Finished → проверка → прикладные данные. Меньше round-trip, чем в 1.2.
- Сертификат: subject, SAN, issuer, срок, публичный ключ, подпись CA.
- Клиент проверяет цепочку до доверенного корня, срок, SAN (не CN!), отзыв (OCSP/CRL).
- Certificate Transparency (CT) — публичные логи выданных сертификатов.
- Pinning — приложение доверяет только конкретному ключу/сертификату.
- mTLS — клиент тоже предъявляет сертификат.
- MITM возможен, если в хранилище клиента добавлен чужой корневой CA.

## Лаборатория

### 1. Свой CA и сертификат

```bash
mkdir -p ~/lab-pki && cd ~/lab-pki

openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout ca.key -out ca.crt -subj "/CN=Lab Root CA"

openssl req -newkey rsa:2048 -nodes \
  -keyout srv.key -out srv.csr -subj "/CN=lab.local"

printf "subjectAltName=DNS:lab.local,IP:10.10.10.30\n" > san.ext

openssl x509 -req -in srv.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out srv.crt -days 30 -extfile san.ext

openssl verify -CAfile ca.crt srv.crt
```

Ожидаемо: `srv.crt: OK`.

### 2. Поднять HTTPS и проверить

```bash
openssl s_server -accept 8443 -cert srv.crt -key srv.key -www
```

На attacker:

```bash
curl --cacert ca.crt --resolve lab.local:8443:10.10.10.30 https://lab.local:8443/
openssl s_client -connect 10.10.10.30:8443 -servername lab.local -CAfile ca.crt </dev/null
```

Ожидаемо: `Verify return code: 0 (ok)`. Без `--cacert` — ошибка самоподписанного сертификата. Это и есть проверка цепочки.

### 3. Посмотреть цепочку

```bash
openssl s_client -connect 10.10.10.30:8443 -showcerts </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -ext subjectAltName -dates
```

Ожидаемо: `subject=CN=lab.local`, `issuer=CN=Lab Root CA`, SAN с DNS и IP.

### 4. MITM-прокси

```bash
mitmproxy --listen-port 8080
```

В другом терминале:

```bash
curl -x http://127.0.0.1:8080 --cacert ~/.mitmproxy/mitmproxy-ca-cert.pem \
  https://example.com -I
```

Ожидаемо: в mitmproxy виден запрос в открытом виде. Клиент доверяет CA mitmproxy, потому что вы его добавили. В реальной системе такой CA без ведома пользователя — признак компрометации.

### 5. Проверить конфигурацию

```bash
nmap --script ssl-enum-ciphers -p 8443 10.10.10.30
```

Ожидаемо: список протоколов и шифров. TLS 1.0/1.1 и RC4 — находки.

## Атака и защита

- **Атака:** MITM с установленным CA, подмена сертификата, просроченный/неверный SAN, downgrade, SSL stripping.
- **Детект:** CT-мониторинг, pinning, алерты на смену сертификата, HSTS, проверка chain в приложении.
- **Фикс:** TLS 1.2+, HSTS, OCSP stapling, pinning для мобильных, запрет пользовательских CA в проде, мониторинг CT.

## Самопроверка

- [ ] Почему CN недостаточно и нужен SAN?
- [ ] Что проверяет клиент, кроме подписи?
- [ ] Почему mitmproxy работает только после установки его CA?
- [ ] Чем pinning ломает корпоративный MITM и почему это иногда проблема?

## Дальше

[4.5 — OWASP Top 10 вживую](l05-owasp-lab.md)
