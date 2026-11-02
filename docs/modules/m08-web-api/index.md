# M08 — Web/API-эксплуатация

> **Этап 1 · 6 занятий · ~28 часов · артефакты в `labs/m08-web-api/`**

## Зачем этот модуль

Это самый частый путь входа в реальных вторжениях и самый проверяемый навык на собеседовании. Здесь вы переходите от «знаю про OWASP» к «нахожу и доказываю».

## Чему научитесь

- Эксплуатировать SQLi, XSS, CSRF, SSRF, XXE, LFI, upload, SSTI, десериализацию.
- Обходить простые фильтры и WAF.
- Ломать JWT и OAuth-потоки.
- Находить BOLA/BFLA и mass assignment в API.
- Писать PoC и remediation, а не «скрин с alert».

## Занятия

| # | Тема | Время | Артефакт |
|---|---|---|---|
| [8.1](l01-sqli.md) | SQL-инъекции | 5 ч | `sqli/` |
| [8.2](l02-xss-csrf.md) | XSS и CSRF | 4 ч | `xss/` |
| [8.3](l03-ssrf-xxe-lfi.md) | SSRF, XXE, LFI, upload | 5 ч | `ssrf/` |
| [8.4](l04-deserialization-ssti.md) | Десериализация, SSTI, RCE | 5 ч | `rce/` |
| [8.5](l05-auth-jwt-oauth.md) | JWT, OAuth, сессии | 5 ч | `auth/` |
| [8.6](l06-api.md) | API: BOLA, mass assignment, GraphQL | 4 ч | `api/` |

## Критерии выхода

- [ ] SQLi вручную, без sqlmap, с объяснением UNION.
- [ ] Stored XSS, который реально сохраняется.
- [ ] SSRF, читающий внутренний сервис.
- [ ] JWT с подделанной ролью.
- [ ] BOLA в API с двумя пользователями.
- [ ] Отчёт, который поймёт разработчик.

## Контрольная

[exam.md](exam.md): DVWA, JWT+BOLA, полный API-отчёт.

## Стенд

DVWA, Juice Shop, WebGoat, crAPI. Все — локально, в Docker. Никаких реальных сайтов.
