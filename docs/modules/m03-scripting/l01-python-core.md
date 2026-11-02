# 3.1 — Python: ядро языка

> **M03 · Этап 0 · 4 ч · 🟢 · артефакт:** `labs/m03-scripting/l01-logparse/`

## Цель

Освоить минимум Python, которого хватает для реальных задач: типы, функции, файлы, исключения, аргументы командной строки.

## Результат

- Пишете скрипт, который читает лог, считает статистику и пишет CSV.
- Понимаете, почему `list` и `dict` устроены по-разному.
- Обрабатываете ошибки, а не падаете с traceback.

## Теория

- Python — интерпретируемый, динамически типизированный; типы проверяются в рантайме.
- Изменяемые (`list`, `dict`, `set`) и неизменяемые (`str`, `tuple`) типы.
- Срезы, comprehensions, распаковка — идиомы, которые делают код короче.
- Функции: позиционные/именованные аргументы, `*args`, `**kwargs`, значения по умолчанию (не мутируемые!).
- Исключения: `try/except/else/finally`, `raise`, свои классы исключений.
- Файлы: `with open(...) as f` закрывает файл даже при ошибке.
- `argparse` — стандартный способ сделать CLI.

## Лаборатория

### 1. Базовые типы

```python
python
```
```python
>>> ips = ["10.10.10.10", "10.10.10.20", "10.10.10.10"]
>>> set(ips)
{'10.10.10.10', '10.10.10.20'}
>>> {ip: ips.count(ip) for ip in set(ips)}
{'10.10.10.10': 2, '10.10.10.20': 1}
>>> "10.10.10.30".split(".")[-1]
'30'
```

Ожидаемо: понимаете, почему `set` убирает дубли, а `dict` хранит счётчики.

### 2. Парсер лога

Создайте `logparse.py`:

```python
#!/usr/bin/env python3
import argparse
import re
from collections import Counter
from pathlib import Path

LINE = re.compile(r"(?P<ip>\d+\.\d+\.\d+\.\d+).*?(?P<status>Failed|Accepted)")

def parse(path: Path) -> Counter:
    counts = Counter()
    with path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            m = LINE.search(line)
            if m:
                counts[(m["ip"], m["status"])] += 1
    return counts

def main() -> None:
    ap = argparse.ArgumentParser(description="Count auth events by IP")
    ap.add_argument("logfile", type=Path)
    ap.add_argument("--top", type=int, default=10)
    args = ap.parse_args()

    if not args.logfile.is_file():
        raise SystemExit(f"no such file: {args.logfile}")

    for (ip, status), n in parse(args.logfile).most_common(args.top):
        print(f"{n:5d}  {status:8s}  {ip}")

if __name__ == "__main__":
    main()
```

Проверка на тестовом логе:

```bash
cat > /tmp/auth.log <<'EOF'
Nov  2 10:00:01 host sshd[1]: Failed password for root from 10.10.10.66 port 22
Nov  2 10:00:02 host sshd[1]: Failed password for root from 10.10.10.66 port 22
Nov  2 10:00:03 host sshd[1]: Accepted password for alice from 10.10.10.50 port 22
EOF
python logparse.py /tmp/auth.log
```

Ожидаемо:

```
    2  Failed    10.10.10.66
    1  Accepted  10.10.10.50
```

### 3. Ошибки и CSV

Добавьте `--csv out.csv`, запись через `csv.DictWriter`, и обработку битого файла. Проверьте:

```bash
python logparse.py /nonexistent
python logparse.py /tmp/auth.log --top 1 --csv /tmp/out.csv
cat /tmp/out.csv
```

Ожидаемо: понятная ошибка без traceback; CSV с заголовком.

## Атака и защита

- **Атака:** парсер логов — основа детекта brute force; атакующий может «размазать» попытки по IP/времени, чтобы не превысить порог.
- **Детект:** порог по IP, по пользователю, по ASN; корреляция «много Failed → Accepted».
- **Фикс:** fail2ban, ключи вместо паролей, MFA, централизованные логи.

## Самопроверка

- [ ] Почему `def f(x=[])` — плохая идея?
- [ ] Чем `except Exception` хуже конкретного исключения?
- [ ] Что делает `with` при исключении внутри блока?
- [ ] Как `argparse` помогает документации?

## Дальше

[3.2 — Python для сетей и безопасности](l02-python-security.md)
